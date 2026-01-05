local utils = require 'lib/utils'

local StorageGui = {}
StorageGui.__index = StorageGui

function StorageGui.new(index, container, containerPos)
  local self = {}
  setmetatable(self, StorageGui)

  self.index = index
  self.container = container
  self.containerPos = containerPos
  self.isLoading = false
  self.isError = false
  self.query = ""
  self.searchResults = {}
  self.chosenResults = {}
  self.scrollPos = 0
  self.ctrlDown = false
  self.chestOpen = false

  return self
end

function StorageGui:draw()
  local w, h = term.getSize()
  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.white)
  term.clear()
  term.setCursorPos(1, 1)
  if self.isLoading then
    term.setBackgroundColor(colors.yellow)
  elseif self.isError then
    term.setBackgroundColor(colors.red)
  else
    term.setBackgroundColor(colors.lightGray)
  end
  term.setTextColor(colors.black)
  term.clearLine()
  term.write(self.query)
  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.white)

  local usageString = " " .. tostring(self.index.usedCellCount) .. "/" .. tostring(self.index.totalCellCount)

  term.setCursorPos(w - string.len(usageString) + 1, 1)
  term.setBackgroundColor(colors.blue)
  term.write(usageString)

  local resultsBoxOffset = 1
  for i, item in ipairs(self.searchResults) do
    -- TODO: don't do unnecessary iterations
    local drawY = resultsBoxOffset + i - self.scrollPos
    if drawY <= resultsBoxOffset then
      goto nextResult
    end
    if drawY > h then
      break
    end
    term.setCursorPos(1, drawY)

    if utils.contains(self.chosenResults, item.key) then
      term.setBackgroundColor(colors.green)
    else
      term.setBackgroundColor(colors.black)
    end
    term.setTextColor(colors.white)
    term.write(item.displayName .. " (" .. tostring(item.count) .. ")")
    
    term.setCursorPos(w - 3 + 1, drawY)
    term.setBackgroundColor(colors.lightBlue)
    term.setTextColor(colors.black)
    term.write("14*")

    ::nextResult::
  end
  term.setBackgroundColor(colors.black)
  term.setCursorPos(1 + string.len(self.query), 1)
  term.setCursorBlink(true)
end

local function matchItem(item, query)
  local q = string.lower(query)
  local isTagQuery = string.sub(q, 1, 1) == "#"
  if isTagQuery then
    q = string.sub(q, 2)
    return utils.any(item.tags, function(tag) return utils.sContains(tag, q) end)
  else
    return utils.sContains(item.name, q)
      or utils.sContains(string.lower(item.displayName), q)
  end
end

function StorageGui:updateQuery()
  self.chosenResults = {}
  self.searchResults = {}
  self.scrollPos = 0
  for _, item in pairs(self.index.metadata) do
    if matchItem(item, self.query) then
      table.insert(self.searchResults, item)
    end
  end
  table.sort(self.searchResults, function(a, b)
    return a.count > b.count
  end)
end

function StorageGui:onEvent(eventData)
  local event = eventData[1]
  if event == "localUpdate" then
    self:updateQuery()
  elseif event == "char" then
    self.query = self.query .. eventData[2]
    self:updateQuery()
  elseif event == "key" then
    local key = eventData[2]
    if self.ctrlDown then
      if key == keys.x or key == keys.backspace or key == keys.capsLock then
        self.query = ""
        self:updateQuery()
      end
    elseif key == keys.leftCtrl then
      self.ctrlDown = true
    elseif key == keys.backspace or key == keys.capsLock then
      self.query = self.query:sub(1, -2)
      self:updateQuery()
    end
  elseif event == "key_up" then
    local key = eventData[2]
    if key == keys.leftCtrl then
      self.ctrlDown = false
    end
  elseif event == "mouse_click" then
    local button = eventData[2]
    if button ~= 1 then
      return
    end
    local x = eventData[3]
    local y = eventData[4]
    if y == 1 then
      return
    end
    local resultIdx = y - 1 + self.scrollPos
    if resultIdx > #self.searchResults then
      return
    end
    local selected = self.searchResults[resultIdx]
    if utils.contains(self.chosenResults, selected.key) then
      return
    end
    self.isLoading = true
    table.insert(self.chosenResults, selected.key)
    self:draw()
    local w, h = term.getSize()
    if x == w - 2 then
      self.index:export(self.container, selected.key, 64 * 1)
    elseif x == w - 1 then
      self.index:export(self.container, selected.key, 64 * 4)
    elseif x == w then
      self.index:export(self.container, selected.key)
    else
      self.index:export(self.container, selected.key, 8)
    end
    self.isLoading = false
  elseif event == "redstone" then
    local newChestOpen = redstone.getInput(self.containerPos)
    if self.chestOpen and not newChestOpen then
      self.isLoading = true
      self:draw()
      self.isError = not pcall(self.index.import, self.index, self.container)
      self.isLoading = false
      self:updateQuery()
    end
    self.chestOpen = newChestOpen
  elseif event == "mouse_scroll" then
    local dir = eventData[2]
    self.scrollPos = self.scrollPos + dir * 2
    if self.scrollPos < 0 then
      self.scrollPos = 0
    elseif self.scrollPos > #self.searchResults - 1 then
      self.scrollPos = #self.searchResults - 1
    end
  end

  self:draw()
end

return StorageGui
