--!strict
-- Create: builds instances declaratively and keeps them bound to States, inside a Scope that cleans everything up.
--   local scope = Create.Scope()
--   scope:New("TextLabel", { Text = title, Parent = frame, [Create.Children] = { ... }, [Create.On "Activated"] = fn })
--   scope:Destroy()  -- disconnects bindings and events, destroys the instances it made
-- A State as a property value binds it: the property follows the state.

local State = require(script.Parent.State)

local Create = {}

Create.Children = newproxy(false)

local EVENT_KEYS: { [any]: string } = {}
-- [Create.On "Activated"] = handler connects an event.
function Create.On(event: string): any
	local key = newproxy(false)
	EVENT_KEYS[key] = event
	return key
end

export type Scope = {
	New: (self: Scope, className: string, props: { [any]: any }) -> Instance,
	Add: (self: Scope, item: any) -> (),
	Destroy: (self: Scope) -> (),
}

local ScopeClass = {}
ScopeClass.__index = ScopeClass

function Create.Scope(): Scope
	return (setmetatable({ _items = {} }, ScopeClass) :: any) :: Scope
end

-- Tracks something to clean up: Instance (destroyed), RBXScriptConnection (disconnected), function (called).
function ScopeClass.Add(self: any, item: any)
	table.insert(self._items, item)
end

function ScopeClass.New(self: any, className: string, props: { [any]: any }): Instance
	local instance = Instance.new(className)
	local parent = nil
	for key, value in props do
		if key == Create.Children then
			for _, child in value do
				child.Parent = instance
			end
		elseif EVENT_KEYS[key] then
			table.insert(self._items, (instance :: any)[EVENT_KEYS[key]]:Connect(value))
		elseif key == "Parent" then
			parent = value
		elseif State.Is(value) then
			table.insert(self._items, value:Observe(function(v)
				(instance :: any)[key] = v
			end))
		else
			(instance :: any)[key] = value
		end
	end
	table.insert(self._items, instance)
	if parent then
		instance.Parent = parent
	end
	return instance
end

function ScopeClass.Destroy(self: any)
	for i = #self._items, 1, -1 do
		local item = self._items[i]
		local kind = typeof(item)
		if kind == "Instance" then
			item:Destroy()
		elseif kind == "RBXScriptConnection" then
			item:Disconnect()
		elseif kind == "function" then
			item()
		end
	end
	table.clear(self._items)
end

return Create
