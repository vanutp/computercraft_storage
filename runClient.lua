package.path = "/storage/?.lua;" .. package.path

local LocalStorageIndex = require 'client/localStorageIndex'
local StorageGui = require 'client/gui'
local EventBus = require 'lib/eventBus'

local containerName = "minecraft:trapped_chest_1"
local containerPos = "right"

peripheral.find("modem", rednet.open)
term.clear()

local index = LocalStorageIndex.new { containerName }
local cont = peripheral.wrap(containerName)
local gui = StorageGui.new(index, cont, containerPos)

local bus = EventBus.new()
bus:register(index)
bus:register(gui)
bus:run()
