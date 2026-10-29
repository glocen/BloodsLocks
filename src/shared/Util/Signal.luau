--!strict
-- Signal: a small pure-Luau event. Each handler runs in its own thread, so one failing handler
-- can't stop the others.

export type Connection = {
	Connected: boolean,
	Disconnect: (self: Connection) -> (),
}

export type Signal<T...> = {
	Connect: (self: Signal<T...>, handler: (T...) -> ()) -> Connection,
	Once: (self: Signal<T...>, handler: (T...) -> ()) -> Connection,
	Wait: (self: Signal<T...>) -> T...,
	Fire: (self: Signal<T...>, T...) -> (),
	DisconnectAll: (self: Signal<T...>) -> (),
}

local ConnectionClass = {}
ConnectionClass.__index = ConnectionClass

function ConnectionClass.Disconnect(self: any)
	if not self.Connected then
		return
	end
	self.Connected = false
	local handlers = self._signal._handlers
	local index = table.find(handlers, self)
	if index then
		table.remove(handlers, index)
	end
end

local SignalClass = {}
SignalClass.__index = SignalClass

function SignalClass.Connect(self: any, handler: (...any) -> ()): Connection
	local connection = setmetatable({ Connected = true, _signal = self, _handler = handler }, ConnectionClass)
	table.insert(self._handlers, connection)
	return connection :: any
end

function SignalClass.Once(self: any, handler: (...any) -> ()): Connection
	local connection: any
	connection = self:Connect(function(...)
		connection:Disconnect()
		handler(...)
	end)
	return connection
end

function SignalClass.Wait(self: any): ...any
	local thread = coroutine.running()
	self:Once(function(...)
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

function SignalClass.Fire(self: any, ...: any)
	-- Iterate a copy so handlers that connect or disconnect during Fire don't skip anyone.
	for _, connection in table.clone(self._handlers) do
		if connection.Connected then
			task.spawn(connection._handler, ...)
		end
	end
end

function SignalClass.DisconnectAll(self: any)
	for _, connection in self._handlers do
		connection.Connected = false
	end
	table.clear(self._handlers)
end

local Signal = {}

function Signal.new<T...>(): Signal<T...>
	return (setmetatable({ _handlers = {} }, SignalClass) :: any) :: Signal<T...>
end

return Signal
