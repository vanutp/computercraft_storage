local utils = require 'lib/utils'
local messages = require 'lib/messages'
local StorageCell = require 'server/storageCell'
local LinkedList = require 'lib/linkedList'

local StorageIndex = {}
StorageIndex.__index = StorageIndex

local function getItemKey(item)
  local nbt = item.nbt or ""
  local damage = tostring(item.damage or -1)
  return item.name .. "|" .. nbt .. "|" .. damage
end

local function getItemMeta(item)
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

  self.blacklist = blacklist
  self.cells = {}
  self.itemStorages = {}
  self.initialized = false
  self:loadItems()
  rednet.broadcast(messages.serverInit())
  self.startupTimerId = os.startTimer(1)

  return self
end

function StorageIndex:broadcastIndex()
  rednet.broadcast(messages.serverIndexFull(
    self.usedCellCount,
    self.totalCellCount,
    self.metadata
  ))
end

function StorageIndex:init()
  self.cells = {}

  for _, name in ipairs(peripheral.getNames()) do
    if utils.contains(self.blacklist, name) then
      goto continue
    end
    if peripheral.hasType(name, 'inventory') then
      local container = peripheral.wrap(name)

      for slot = 1, container.size() do
        table.insert(
          self.cells,
          StorageCell.new(container, slot)
        )
      end
    elseif peripheral.hasType(name, 'item_storage') then
      table.insert(self.itemStorages, peripheral.wrap(name))
    end
    ::continue::
  end
  self:loadItems()
  self.initialized = true
  self:broadcastIndex()
  os.queueEvent("localUpdate")
end

function StorageIndex:onEvent(eventData)
  if eventData[1] == "rednet_message" then
    self:onMessage(eventData[3])
  elseif eventData[1] == "timer" then
    if eventData[2] == self.startupTimerId then
      self:init()
    end
  end
end

function StorageIndex:onMessage(message)
  if message.type == "clientInit" then
    for _, name in ipairs(message.blacklist) do
      table.insert(self.blacklist, name)
    end
    if self.initialized then
      self:broadcastIndex()
    end
  elseif message.type == "clientImportRequest" then
    -- TODO: cache peripherals?
    local container = peripheral.wrap(message.fromContainer)
    self:import(container)
  elseif message.type == "clientExportRequest" then
    local container = peripheral.wrap(message.toContainer)
    self:export(container, message.itemKey, message.count)
  end
end

function StorageIndex:updateCellCounts()
  self.usedCellCount = utils.sum(self.fullCells, function(el) return el.length end)
      + utils.sum(self.nonFullCells, function(el) return el.length end)
  self.totalCellCount = #self.cells
end

function StorageIndex:loadItems()
  self.fullCells = {}
  self.nonFullCells = {}
  self.emptyCells = LinkedList.new()
  self.metadata = {}

  local function updateMetadata(key, detail)
    if self.metadata[key] == nil then
      self.metadata[key] = getItemMeta(detail)
    else
      self.metadata[key].count = self.metadata[key].count + detail.count
    end
  end

  for _, cell in ipairs(self.cells) do
    local detail = cell.detail

    if detail == nil then
      self.emptyCells:push(cell)
    else
      local key = getItemKey(detail)
      updateMetadata(key, detail)
      local cells = detail.count == detail.maxCount
          and self.fullCells
          or self.nonFullCells

      if cells[key] == nil then
        cells[key] = LinkedList.new()
      end

      cells[key]:push(cell)
    end
  end

  for _, storage in ipairs(self.itemStorages) do
    for _, detail in ipairs(storage.items()) do
      local key = getItemKey(detail)
      updateMetadata(key, detail)
    end
  end

  self:updateCellCounts()
end

function StorageIndex:import(container)
  local list = container.list()
  if list == nil then
    error("Could not access container")
  end
  for slot, short in pairs(list) do
    if short == nil then
      goto emptyCell
    end
    local detail = container.getItemDetail(slot)
    if detail == nil then
      error("Could not get item detail for slot " .. tostring(slot))
    end

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
            or self.nonFullCells

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

  self:updateCellCounts()
  self:broadcastIndex()
end

function StorageIndex:export(container, key, count)
  local remaining = count or math.huge
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

    remaining = remaining - nMoved
    if remaining <= 0 then
      goto done
    end
  end

  ::nonFull::

  if self.nonFullCells[key] == nil then
    goto readonly
  end

  for node in self.nonFullCells[key]:iter() do
    local cell = node.value

    local nMoved = cell:export(container)
    itemMeta.count = itemMeta.count - nMoved

    if cell.detail == nil then
      node:remove()
      self.emptyCells:push(cell)
    end

    remaining = remaining - nMoved
    if remaining <= 0 then
      goto done
    end
  end

  ::readonly::

  -- TODO: only export from storages containing this
  for _, storage in ipairs(self.itemStorages) do
    local nMoved = storage.pushItem(
      peripheral.getName(container),
      {
        name = itemMeta.name,
        nbt = itemMeta.nbt,
      },
      remaining
    )
    itemMeta.count = itemMeta.count - nMoved
    remaining = remaining - nMoved
    if remaining <= 0 then
      goto done
    end
  end

  ::done::

  self:updateCellCounts()
  self:broadcastIndex()
end

return StorageIndex
