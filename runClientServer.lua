local StorageIndex = require 'server/storageIndex'
local StorageGui = require 'client/gui'
local EventBus = require 'lib/eventBus'

local containerName = "minecraft:trapped_chest_0"
local containerPos = "right"

peripheral.find("modem", rednet.open)
term.clear()
term.setCursorPos(1, 1)
print("Indexing...")

local index = StorageIndex.new {
  containerName,
  "top",
  "right",
  "left",
  "bottom",
  "back",
  "front",
}
local cont = peripheral.wrap(containerName)
local gui = StorageGui.new(index, cont, containerPos)

local bus = EventBus.new()
bus:register(index)
bus:register(gui)
bus:run()
