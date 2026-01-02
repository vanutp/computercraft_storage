package.path = "/storage/?.lua;" .. package.path

local StorageIndex = require 'server/storageIndex'
local EventBus = require 'lib/eventBus'

peripheral.find("modem", rednet.open)
term.clear()

local index = StorageIndex.new {}

local bus = EventBus.new()
bus:register(index)
bus:run()
