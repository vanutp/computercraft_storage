local StorageIndex = require 'server/storageIndex'
local EventBus = require 'lib/eventBus'

peripheral.find("modem", rednet.open)
term.clear()
term.setCursorPos(1, 1)
print("Indexing...")

local index = StorageIndex.new {
  "top",
  "right",
  "left",
  "bottom",
  "back",
  "front",
}

local bus = EventBus.new()
bus:register(index)
bus:run()
