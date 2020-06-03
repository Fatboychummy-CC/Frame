local tFuncs = {}
local expect = require("cc.expect").expect
local tBlit = {
  [colors.white]     = "0",
  [colors.orange]    = "1",
  [colors.magenta]   = "2",
  [colors.lightBlue] = "3",
  [colors.yellow]    = "4",
  [colors.lime]      = "5",
  [colors.pink]      = "6",
  [colors.gray]      = "7",
  [colors.lightGray] = "8",
  [colors.cyan]      = "9",
  [colors.purple]    = "a",
  [colors.blue]      = "b",
  [colors.brown]     = "c",
  [colors.green]     = "d",
  [colors.red]       = "e",
  [colors.black]     = "f"
}
for k, v in pairs(tBlit) do
  tBlit[v] = k
end

--[[
  buffer format:
  {
    Y axis
    [1] = {
      characters
      "a", "b", "c" ...
    },
    [2] = {
      text colors
      "f", "f", "f", ...
    }
    [3] = {
      background colors
      "0", "0", "0", ...
    }
    ...
  }
]]

--[[
  create a new frame with terminal object tRedirect (or nil)
]]
function tFuncs.new(tTerm)
  expect(1, tTerm, "table")
  local tFrame, tBuffer1, tBuffer2 = {}, {}, {}
  local bDirty = false
  local iCX, iCY = 1, 1
  local blitText = "0"
  local blitBackground = "f"
  local iX, iY

  -- initialize a full line with all the same chars/colors
  -- bSwitch: false = buffer 1, true = buffer 2,
  local function initLine(iLine, sText, sTextColor, sBackgroundColor, bSwitch)
    if not bSwitch then
      tBuffer1[iLine] = {dirty = false}
      tBuffer1[iLine][1] = {} -- characters
      tBuffer1[iLine][2] = {} -- text colors
      tBuffer1[iLine][3] = {} -- background colors
      for x = 1, iX do
        tBuffer1[iLine][1][x] = " "
        tBuffer1[iLine][2][x] = "0"
        tBuffer1[iLine][3][x] = "f"
      end
    else
      tBuffer2[iLine] = {}
      tBuffer2[iLine][1] = {} -- characters
      tBuffer2[iLine][2] = {} -- text colors
      tBuffer2[iLine][3] = {} -- background colors
      for x = 1, iX do
        tBuffer2[iLine][1][x] = " "
        tBuffer2[iLine][2][x] = "0"
        tBuffer2[iLine][3][x] = "f"
      end
    end
  end

  -- initialize and clear the display.
  function tFrame.Initialize()
    iX, iY = tTerm.getSize()
    tBuffer1 = {}
    tBuffer2 = {}
    for y = 1, iY do
      initLine(y, ' ', '0', 'f', false)
      initLine(y, ' ', '0', 'f', true)
    end
    tTerm.setTextColor(colors.white)
    tTerm.setBackgroundColor(colors.black)
    tTerm.clear()
  end

  -- push the buffer to the terminal if the buffer is dirty
  function tFrame.PushBuffer()
    if bDirty then
      -- if the buffer is marked dirty
      for y = 1, #tBuffer1 do
        -- check each line
        if tBuffer1[y].dirty then
          for i = 1, iX do
            if tBuffer1[y][1][i] ~= tBuffer2[y][1][i]
              or tBuffer1[y][2][i] ~= tBuffer2[y][2][i]
              or tBuffer1[y][3][i] ~= tBuffer2[y][3][i] then

              -- if the line is marked dirty (and is actually dirty), blit it to the terminal
              tTerm.setCursorPos(1, y)
              tTerm.blit(
                table.concat(tBuffer1[y][1]),
                table.concat(tBuffer1[y][2]),
                table.concat(tBuffer1[y][3])
              )

              -- then copy the data to buffer 2
              tBuffer2[y][1] = table.pack(table.unpack(tBuffer1[y][1]))
              tBuffer2[y][2] = table.pack(table.unpack(tBuffer1[y][2]))
              tBuffer2[y][3] = table.pack(table.unpack(tBuffer1[y][3]))

              -- then set this line's dirty value to false
              tBuffer1[y].dirty = false
              break -- then don't check the rest of the chars
            end
          end
        end
      end
      bDirty = false
      tTerm.setCursorPos(iCX, iCY)
    end
  end

  function tFrame.setCursorPos(_iCX, _iCY)
    expect(1, _iCX, "number")
    expect(2, _iCY, "number")
    iCX, iCY = _iCX, _iCY
    bDirty = true
  end

  function tFrame.setTextColor(iColor)
    expect(1, iColor, "number")
    blitText = tBlit[iColor]
  end
  tFrame.setTextColour = tFrame.setTextColor

  function tFrame.setBackgroundColor(iColor)
    expect(1, iColor, "number")
    blitBackground = tBlit[iColor]
  end
  tFrame.setBackgroundColour = tFrame.setBackgroundColor

  function tFrame.write(sText)
    expect(1, sText, "string", "number")

    if iCY <= iY and iCY >= 1 then
      sText = tostring(sText)
      local i = 0
      for char in sText:gmatch(".") do
        local pos = iCX + i
        if pos <= iX and pos >= 1 then
          tBuffer1[iCY][1][pos] = char
          tBuffer1[iCY][2][pos] = blitText
          tBuffer1[iCY][3][pos] = blitBackground
          i = i + 1
        end
      end

      tBuffer1[iCY].dirty = true
    end
    tFrame.setCursorPos(iCX + #sText, iCY)
  end

  function tFrame.blit(sText, sTextColor, sBackgroundColor)
    expect(1, sText, "string")
    expect(2, sTextColor, "string")
    expect(3, sBackgroundColor, "string")
    if #sText ~= #sTextColor or #sTextColor ~= #sBackgroundColor or #sText ~= # sBackgroundColor then
      error("Bad arguments: Expected strings of equal length.", 2)
    end

    if iCY >= 1 and iCY <= iY then
      local i = 0
      for char in sText:gmatch(".") do
        local pos = iCX + i
        if pos >= 1 and pos <= iX then
          tBuffer1[iCY][1][pos] = char
          i = i + 1
        end
      end
      i = 0
      for char in sTextColor:gmatch(".") do
        local pos = iCX + i
        if pos >= 1 and pos <= iX then
          tBuffer1[iCY][2][pos] = char
          i = i + 1
        end
      end
      i = 0
      for char in sBackgroundColor:gmatch(".") do
        local pos = iCX + i
        if pos >= 1 and pos <= iX then
          tBuffer1[iCY][3][pos] = char
          i = i + 1
        end
      end

      tBuffer1[iCY].dirty = true
    end
    tFrame.setCursorPos(iCX + #sText, iCY)
  end

  function tFrame.scroll(iNum)
    expect(1, iNum, "number")

    for i = 1, iNum do
      table.remove(tBuffer1[1]) -- table.remove should automatically shift
      tBuffer1[iY] = initLine(iY, ' ', sTextColor, sBackgroundColor, false)
    end
    for i = 1, iY do
      tBuffer1[i].dirty = true
    end
  end

  function tFrame.getBackgroundColor()
    return tBlit[sBackgroundColor]
  end
  tFrame.getBackgroundColour = tFrame.getBackgroundColor

  function tFrame.getTextColor()
    return tBlit[sTextColor]
  end
  tFrame.getTextColour = tFrame.getTextColor

  function tFrame.getSize()
    return iX, iY
  end

  function tFrame.getCursorPos()
    return iCX, iCY
  end

  function tFrame.clear()
    for y = 1, iY do
      tFrame.clearLine(y)
    end
  end

  function tFrame.clearLine(iLine)
    initLine(iLine, ' ', blitText, blitBackground, false)
    tBuffer1[iLine].dirty = true
  end

  return tFrame
end

return tFuncs
