return {
  contains = function(list, value)
    for _, element in ipairs(list) do
      if element == value then
        return true
      end
    end

    return false
  end,

  sContains = function(string, sub)
    return string.find(string, sub, nil, true) ~= nil
  end,

  copyFields = function(tbl, fields)
    local copy = {}

    for _, key in ipairs(fields) do
      copy[key] = tbl[key]
    end

    return copy
  end,

  any = function(list, f)
    for _, el in ipairs(list) do
      if f(el) then
        return true
      end
    end
    return false
  end,

  sum = function(list, f)
    local res = 0
    local f = f or function(el) return el end
    for _, el in pairs(list) do
      res = res + f(el)
    end
    return res
  end,
}
