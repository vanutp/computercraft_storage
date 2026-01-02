local LinkedList = {}
LinkedList.__index = LinkedList

local Node = {}
Node.__index = Node

local function rootNode(list)
  local self = {}
  setmetatable(self, Node)

  self.isRoot = true
  self.list = list

  return self
end

local function newNode(prev, value)
  local new = {}
  setmetatable(new, Node)

  new.isRoot = false
  new.prevNode = prev
  new.nextNode = prev.nextNode
  new.list = prev.list
  new.list.length = new.list.length + 1
  prev.nextNode = new
  if new.nextNode ~= nil then
    new.nextNode.prevNode = new
  end
  new.value = value

  return new
end

function LinkedList.new()
  local self = {}
  setmetatable(self, LinkedList)

  self.length = 0
  self.root = rootNode(self)

  return self
end

function Node:next()
  return self.nextNode
end

function Node:prev()
  if self.prevNode == nil or self.prevNode.isRoot then
    return nil
  else
    return self.prevNode
  end
end

function Node:remove()
  self.prevNode.nextNode = self.nextNode
  if self.nextNode ~= nil then
    self.nextNode.prevNode = self.prevNode
  end

  self.prevNode = nil
  self.nextNode = nil
  self.value = nil
  self.list.length = self.list.length - 1
  self.list = nil
end

function LinkedList:head()
  return self.root.nextNode
end

function LinkedList:isEmpty()
  return self.root.nextNode == nil
end

function LinkedList:push(value)
  newNode(self.root, value)
end

function LinkedList:iter()
  local node = self:head()

  return function()
    local prevNode = node

    if node ~= nil then
      node = node:next()
    end

    return prevNode
  end
end

return LinkedList
