local EventBus = {}
EventBus.__index = EventBus

function EventBus.new()
  local self = {}
  setmetatable(self, EventBus)

  self.listeners = {}

  return self
end

function EventBus:register(listener)
  table.insert(self.listeners, listener)
end

function EventBus:run()
  while true do
    local event = { os.pullEvent() }
    if event[1] == "modem_message" then
      os.queueEvent(unpack(event))
      goto continue
    end
    for _, listener in ipairs(self.listeners) do
      listener:onEvent(event)
    end
    ::continue::
  end
end

return EventBus
