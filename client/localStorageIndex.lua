local messages = require 'lib/messages'

local LocalStorageIndex = {}
LocalStorageIndex.__index = LocalStorageIndex


function LocalStorageIndex.new(blacklist)
  local self = {}
  setmetatable(self, LocalStorageIndex)

  self.blacklist = blacklist
  self:init()

  return self
end

function LocalStorageIndex:init()
  self.usedCellCount = 0
  self.totalCellCount = 0
  self.metadata = {}
  rednet.broadcast(messages.clientInit(self.blacklist))
end

function LocalStorageIndex:onEvent(eventData)
  if eventData[1] == "rednet_message" then
    self:onMessage(eventData[3])
  end
end

function LocalStorageIndex:onMessage(message)
  if message.type == "serverInit" then
    self:init()
  elseif message.type == "serverIndexFull" then
    self.usedCellCount = message.usedCellCount
    self.totalCellCount = message.totalCellCount
    self.metadata = message.metadata
    os.queueEvent("localUpdate")
  elseif message.type == "serverIndexDelta" then
    self.usedCellCount = message.usedCellCount
    self.totalCellCount = message.totalCellCount
    for key, itemMeta in pairs(message.metadata) do
      self.metadata[key] = itemMeta
    end
    os.queueEvent("localUpdate")
  end
end

function LocalStorageIndex:import(container)
  local containerName = peripheral.getName(container)
  rednet.broadcast(messages.clientImportRequest(containerName))
end

function LocalStorageIndex:export(container, key, count)
  local containerName = peripheral.getName(container)
  rednet.broadcast(messages.clientExportRequest(containerName, key, count))
end

return LocalStorageIndex
