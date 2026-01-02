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
    for _, listener in ipairs(self.listeners) do
      listener:onEvent(event)
    end
  end
end

return EventBus
