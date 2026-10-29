--!strict
-- State: a value that announces changes, the reactive core of our UI layer (no external library).
--   State.new(v)          a value: :Get(), :Set(v), :Observe(fn) (runs now and on every change; returns a disconnect).
--   State.Computed(fn, {deps})  a read-only value recomputed when any dependency changes.
-- Screens hold their data in States and bind instance properties to them with Create (Core.Create).

export type State<T> = {
	Get: (self: State<T>) -> T,
	Set: (self: State<T>, value: T) -> (),
	Observe: (self: State<T>, fn: (T) -> ()) -> () -> (),
}

local State = {}

local Class = {}
Class.__index = Class

function State.new<T>(initial: T): State<T>
	return (setmetatable({ _value = initial, _listeners = {} }, Class) :: any) :: State<T>
end

function Class.Get(self: any)
	return self._value
end

function Class.Set(self: any, value: any)
	if value == self._value then
		return
	end
	self._value = value
	for _, fn in table.clone(self._listeners) do
		task.spawn(fn, value)
	end
end

function Class.Observe(self: any, fn: (any) -> ()): () -> ()
	table.insert(self._listeners, fn)
	fn(self._value)
	return function()
		local i = table.find(self._listeners, fn)
		if i then
			table.remove(self._listeners, i)
		end
	end
end

function State.Is(value: any): boolean
	return type(value) == "table" and getmetatable(value) == Class
end

-- A read-only State computed from others. Returns the state and a function that stops tracking.
function State.Computed<T>(compute: () -> T, deps: { State<any> }): (State<T>, () -> ())
	local derived = State.new(compute())
	local stops = {}
	for _, dep in deps do
		local first = true
		table.insert(stops, dep:Observe(function()
			if first then
				first = false
				return
			end
			derived:Set(compute())
		end))
	end
	return derived, function()
		for _, stop in stops do
			stop()
		end
	end
end

return State
