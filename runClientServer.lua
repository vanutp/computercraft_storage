package.path = "/storage/?.lua;" .. package.path

local StorageIndex = require 'server/storageIndex'
local StorageGui = require 'client/gui'
local EventBus = require 'lib/eventBus'

local containerName = "minecraft:trapped_chest_0"
local containerPos = "right"

peripheral.find("modem", rednet.open)
term.clear()

local index = StorageIndex.new { containerName }
local cont = peripheral.wrap(containerName)
local gui = StorageGui.new(index, cont, containerPos)

local bus = EventBus.new()
bus:register(index)
bus:register(gui)
bus:run()
