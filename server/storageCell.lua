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

return StorageCell
