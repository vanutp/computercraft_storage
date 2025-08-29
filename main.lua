shell.setPath("disk:" .. shell.path())
StorageIndex = require 'storageIndex'
StorageGui = require 'gui'

term.clear()
term.setCursorPos(1, 1)
print("Indexing...")

local containerName = "minecraft:trapped_chest_1"

index = StorageIndex.new {
  containerName,
  "top",
  "right",
  "left",
  "bottom",
  "back",
  "front",
}
cont = peripheral.wrap(containerName)

gui = StorageGui.new(index, cont)
gui:run()
