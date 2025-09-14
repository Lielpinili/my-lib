local Event = {}
local Connection = {}

local tAdd = table.insert
local tFind = table.find
local tRem = table.remove

Event.__index = Event
Connection.__index = Connection
function Event.new()
	return setmetatable({_f = {}},Event)
end

function Event:Connect(func:(any)->())
	tAdd(self._f, func)
	return setmetatable({self._f,func},Connection)::typeof(Connection)
end

function Event:Once(func:(any)->())
	local connection:typeof(Connection) = nil
	local function onceFunc(...)
		connection:Disconnect()
		func(...)
	end
	connection = setmetatable({self._f,onceFunc},Connection)
	tAdd(self._f, onceFunc)
	return connection
end

function Event:Wait()
	local c = coroutine.running()
	local function func(...)
		tRem(self._f,tFind(self._f,func))
		coroutine.resume(c,...)
	end
	tAdd(self._f, func)
	return coroutine.yield()
end

function Event:Fire(...)
	for _, v in next, self._f do
		task.defer(v,...)
	end
end

function Event:Destroy()
	setmetatable(self,nil)
	table.clear(self._f)
	self._f = nil
end

function Connection:Disconnect()
	setmetatable(self,nil)
	tRem(self[1],tFind(self[1],self[2]))
	self[1] = nil
	self[2] = nil
end

return Event
