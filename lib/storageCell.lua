local utils = require 'lib/utils'

local StorageCell = {}
StorageCell.__index = StorageCell

function StorageCell.new(container, slot)
  local self = {}
  setmetatable(self, StorageCell)

  self.container = container
  self.slot = slot
  self:loadDetail()

  return self
end

function StorageCell:isFull()
  return self.detail ~= nil
      and self.detail.count == self.detail.maxCount
end

function StorageCell:loadDetail()
  self.detail = self.container.getItemDetail(self.slot)
end

function StorageCell:updateWith(fn)
  local result = fn()
  self:loadDetail()

  return result
end

function StorageCell:export(to, toSlot, limit)
  return self:updateWith(function()
    return self.container.pushItems(
      peripheral.getName(to), self.slot,
      limit, toSlot
    )
  end)
end

function StorageCell:import(from, fromSlot, limit)
  return self:updateWith(function()
    return self.container.pullItems(
      peripheral.getName(from), fromSlot,
      limit, self.slot
    )
  end)
end

function StorageCell.getContainerNames(blacklist)
  local res = {}
  for _, name in ipairs(peripheral.getNames()) do
    if peripheral.hasType(name, 'inventory')
        and not utils.contains(blacklist, name)
    then
      table.insert(res, name)
    end
  end
  return res
end

function StorageCell.cellsFromContainer(containerName)
  local cells = {}
  local container = peripheral.wrap(containerName)
  for slot = 1, container.size() do
    table.insert(
      cells,
      StorageCell.new(container, slot)
    )
  end
  return cells
end

function StorageCell:serialize()
  return {
    containerName = peripheral.getName(self.container),
    slot = self.slot,
    detail = self.detail,
  }
end

function StorageCell.deserialize(data)
  local self = {}
  setmetatable(self, StorageCell)

  self.container = peripheral.wrap(data.containerName)
  self.slot = data.slot
  self.detail = data.detail

  return self
end

return StorageCell
