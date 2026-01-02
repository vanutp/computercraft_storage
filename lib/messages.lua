-- serverXxx -- messages from server to clients
-- clientXxx -- messages from client to server
return {
  -- sent when the server initializes
  -- all clients must reinitialize and send clientInit upon receiving this message
  serverInit = function ()
    return {
      type = "serverInit",
    }
  end,
  -- clientInit(blacklist: list[str])
  -- sent when the client initializes
  -- the server must send serverIndexFull upon receiving this message
  clientInit = function (blacklist)
    return {
      type = "clientInit",
      blacklist = blacklist,
    }
  end,
  -- serverGetCells(containerNames: list[str])
  serverGetCells = function(containerNames)
    return {
      type = "serverGetCells",
      containerNames = containerNames,
    }
  end,
  -- clientCells(cells: list[StorageCell])
  clientCells = function(cells)
    return {
      type = "clientCells",
      cells = cells,
    }
  end,
  -- ItemMeta(name: string, displayName: str, count: int, tags: list[string], key: str)
  -- serverIndexFull(usedCellCount: int, totalCellCount: int, metadata: map[str, ItemMeta])
  serverIndexFull = function (usedCellCount, totalCellCount, metadata)
    return {
      type = "serverIndexFull",
      usedCellCount = usedCellCount,
      totalCellCount = totalCellCount,
      metadata = metadata,
    }
  end,
  -- serverIndexDelta(usedCellCount: int, totalCellCount: int, metadata: map[str, ItemMeta])
  serverIndexDelta = function (usedCellCount, totalCellCount, metadata)
    return {
      type = "serverIndexDelta",
      usedCellCount = usedCellCount,
      totalCellCount = totalCellCount,
      metadata = metadata,
    }
  end,
  -- clientImportRequest(fromContainer: str)
  clientImportRequest = function (fromContainer)
    return {
      type = "clientImportRequest",
      fromContainer = fromContainer,
    }
  end,
  -- clientExportRequest(toContainer: str, itemKey: str)
  clientExportRequest = function (toContainer, itemKey)
    return {
      type = "clientExportRequest",
      toContainer = toContainer,
      itemKey = itemKey,
    }
  end,
}
