StorageIndex = require 'storageIndex'
StorageCell = require 'storageCell'
pretty = require 'cc.pretty'

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

