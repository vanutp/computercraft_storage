local utils = require 'utils'
local StorageCell = require 'storageCell'
local LinkedList = require 'linkedList'

local StorageIndex = {}
StorageIndex.__index = StorageIndex

function getItemKey(item)
  local nbt = item.nbt or ""
  local damage = tostring(item.damage or -1)
  return item.name .. "|" .. nbt .. "|" .. damage
end

function getItemMeta(item)
  local res = utils.copyFields(
    item,
    { 'name', 'displayName', 'count' }
  )
  local tags = {}
  for tag, has in pairs(item.tags) do
    if has then
      table.insert(tags, tag)
    end
  end
  res.tags = tags
  res.key = getItemKey(item)
  return res
end

function StorageIndex.new(blacklist)
  local self = {}
  setmetatable(self, StorageIndex)

  self.cells = StorageCell.allExcept(blacklist)
  self:loadItems()

  return self
end

function StorageIndex:loadItems()
  self.fullCells = {}
  self.nonFullCells = {}
  self.emptyCells = LinkedList.new()
  self.metadata = {}

  for _, cell in ipairs(self.cells) do
    local detail = cell.detail

    if detail == nil then
      self.emptyCells:push(cell)
    else
      local key = getItemKey(detail)

      if self.metadata[key] == nil then
        self.metadata[key] = getItemMeta(detail)
      else
        self.metadata[key].count
          = self.metadata[key].count
            + detail.count
      end

      local cells = detail.count == detail.maxCount
        and self.fullCells
        or self.nonFullCells

      if cells[key] == nil then
        cells[key] = LinkedList.new()
      end

      cells[key]:push(cell)
    end
  end
end

function StorageIndex:import(container)
  for slot, short in pairs(container.list()) do
    if short == nil then
      goto emptyCell
    end
    local detail = container.getItemDetail(slot)

    local count = detail.count
    local key = getItemKey(detail)
    if self.metadata[key] == nil then
      self.metadata[key] = getItemMeta(detail)
      self.metadata[key].count = 0
    end
    local itemMeta = self.metadata[key]

    if self.nonFullCells[key] == nil then
      goto newItem
    end

    for node in self.nonFullCells[key]:iter() do
      local cell = node.value

      local nMoved = cell:import(container, slot)
      itemMeta.count = itemMeta.count + nMoved

      if cell:isFull() then
        node:remove()

        if self.fullCells[key] == nil then
          self.fullCells[key] = LinkedList.new()
        end

        self.fullCells[key]:push(cell)
      end

      count = count - nMoved
      if count == 0 then
        goto emptyCell
      end
    end

    ::newItem::

    for node in self.emptyCells:iter() do
      local cell = node.value

      local nMoved = cell:import(container, slot)
      itemMeta.count = itemMeta.count + nMoved
      if nMoved > 0 then
        node:remove()

        local cells = cell:isFull()
          and self.fullCells
          or  self.nonFullCells

        if cells[key] == nil then
          cells[key] = LinkedList.new()
        end
        cells[key]:push(cell)
      end

      count = count - nMoved
      if count == 0 then
        goto emptyCell
      end
    end

    ::emptyCell::
  end
end

function StorageIndex:export(container, key)
  local itemMeta = self.metadata[key]
  if self.fullCells[key] == nil then
    goto nonFull
  end

  for node in self.fullCells[key]:iter() do
    local cell = node.value

    local nMoved = cell:export(container)
    itemMeta.count = itemMeta.count - nMoved

    if cell.detail == nil then
      node:remove()
      self.emptyCells:push(cell)
    elseif not cell:isFull() then
      node:remove()
      self.nonFullCells[key]:push(cell)
    end
  end

  ::nonFull::

  if self.nonFullCells[key] == nil then
    return
  end

  for node in self.nonFullCells[key]:iter() do
    local cell = node.value

    local nMoved = cell:export(container)
    itemMeta.count = itemMeta.count - nMoved

    if cell.detail == nil then
      node:remove()
      self.emptyCells:push(cell)
    end
  end
end

return StorageIndex
