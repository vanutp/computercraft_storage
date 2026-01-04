local IOModule = {}
IOModule.__index = IOModule


function IOModule.new(index, container)
  local self = {}
  setmetatable(self, IOModule)

  self.index = index
  self.container = container
  self.initialized = false
  self.importTimer = os.startTimer(20)

  return self
end

function IOModule:onEvent(eventData)
  if eventData[1] == "rednet_message" then
    self:onMessage(eventData[3])
  elseif eventData[1] == "timer" and eventData[2] == self.importTimer then
    if self.initialized then
      self.index:import(self.container)
    end
    self.importTimer = os.startTimer(20)
  end
end

function IOModule:onMessage(message)
  if message.type == "serverInit" then
    self.initialized = false
    term.clear()
    term.setCursorPos(1, 1)
    print("Received server init, waiting for index...")
  elseif message.type == "serverIndexFull" then
    self.initialized = true
    term.clear()
    term.setCursorPos(1, 1)
    print("Ready")
  end
end

return IOModule
