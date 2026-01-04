package.path = "/storage/?.lua;" .. package.path

local LocalStorageIndex = require 'client/localStorageIndex'
local IOModule = require 'client/ioModule'
local EventBus = require 'lib/eventBus'

local containerName = "minecraft:trapped_chest_1"

peripheral.find("modem", rednet.open)
term.clear()
term.setCursorPos(1, 1)
print("Waiting for server...")

local index = LocalStorageIndex.new { containerName }
local cont = peripheral.wrap(containerName)
local io = IOModule.new(index, cont)

local bus = EventBus.new()
bus:register(index)
bus:register(io)
bus:run()
