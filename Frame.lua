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
  [colors.black]     = "f",
  ["0"] = colors.white,
  ["1"] = colors.orange,
  ["2"] = colors.magenta,
  ["3"] = colors.lightBlue,
  ["4"] = colors.yellow,
  ["5"] = colors.lime,
  ["6"] = colors.pink,
  ["7"] = colors.gray,
  ["8"] = colors.lightGray,
  ["9"] = colors.cyan,
  a     = colors.purple,
  b     = colors.blue,
  c     = colors.brown,
  d     = colors.green,
  e     = colors.red,
  f     = colors.black
}
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
  local bPostRedisplay = false
  local iCX, iCY = 1, 1
  local blitText = "0"
  local blitBackground = "f"
  local iX, iY
  local toCall = {}

  -- register a call to be made upon the next redraw.
  local function regCall(func, ...)
    local args = table.pack(...)

    toCall[#toCall + 1] = function()
      func(table.unpack(args, 1, args.n))
    end
  end

  -- initialize a full line with all the same chars/colors
  -- bSwitch: false = buffer 1, true = buffer 2,
  local function initLine(iLine, sText, sTextColor, sBackgroundColor, bSwitch)
    if not bSwitch then
      tBuffer1[iLine] = {dirty = false}
      tBuffer1[iLine][1] = {} -- characters
      tBuffer1[iLine][2] = {} -- text colors
      tBuffer1[iLine][3] = {} -- background colors
      for x = 1, iX do
        tBuffer1[iLine][1][x] = sText
        tBuffer1[iLine][2][x] = sTextColor
        tBuffer1[iLine][3][x] = sBackgroundColor
      end
    else
      tBuffer2[iLine] = {}
      tBuffer2[iLine][1] = {} -- characters
      tBuffer2[iLine][2] = {} -- text colors
      tBuffer2[iLine][3] = {} -- background colors
      for x = 1, iX do
        tBuffer2[iLine][1][x] = sText
        tBuffer2[iLine][2][x] = sTextColor
        tBuffer2[iLine][3][x] = sBackgroundColor
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

  function tFrame.RedirectFrame(tNewTerm, bNoRedisplay)
    expect(1, tNewTerm, "table")
    expect(2, bNoRedisplay, "boolean", "nil")

    tTerm = tNewTerm
    if not bNoRedisplay then
      tFrame.PostRedisplay()
    end
  end

  -- Force update every line upon next draw
  function tFrame.PostRedisplay()
    bPostRedisplay = true
  end

  -- push the buffer to the terminal if the buffer is dirty
  function tFrame.PushBuffer()
    if bDirty or bPostRedisplay then
      -- if the buffer is marked dirty
      for y = 1, #tBuffer1 do
        -- check each line
        if tBuffer1[y].dirty or bPostRedisplay then
          for i = 1, iX do
            if tBuffer1[y][1][i] ~= tBuffer2[y][1][i]
              or tBuffer1[y][2][i] ~= tBuffer2[y][2][i]
              or tBuffer1[y][3][i] ~= tBuffer2[y][3][i]
              or bPostRedisplay then

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
      bPostRedisplay = false
      tTerm.setCursorPos(iCX, iCY)
    end

    -- call any functions that have been pre registered
    while toCall[1] do
      toCall[1]()
      table.remove(toCall, 1)
    end
  end

  function tFrame.setCursorPos(_iCX, _iCY)
    expect(1, _iCX, "number")
    expect(2, _iCY, "number")

    iCX, iCY = _iCX, _iCY
    bDirty = true
  end

  -- Palette stuff
  function tFrame.setPaletteColor(...)
    regCall(tTerm.setPaletteColor, ...)
  end
  tFrame.setPaletteColour = tFrame.setPaletteColor

  tFrame.getPaletteColor = tTerm.getPaletteColor
  tFrame.getPaletteColour = tTerm.getPaletteColour

  tFrame.nativePaletteColor = tTerm.nativePaletteColor
  tFrame.nativePaletteColour = tTerm.nativePaletteColour

  -- Cursor stuff
  function tFrame.setCursorBlink(...)
    regCall(tTerm.setCursorBlink, ...)
  end
  tFrame.getCursorBlink = tTerm.getCursorBlink

  tFrame.isColor = tTerm.isColor
  tFrame.isColour = tTerm.isColour

  function tFrame.setTextColor(iColor)
    expect(1, iColor, "number")
    if not tBlit[iColor] then error("Bad argument #1: Expected color.", 2) end

    blitText = tBlit[iColor]
  end
  tFrame.setTextColour = tFrame.setTextColor

  function tFrame.setBackgroundColor(iColor)
    expect(1, iColor, "number")
    if not tBlit[iColor] then error("Bad argument #1: Expected color.", 2) end

    blitBackground = tBlit[iColor]
  end
  tFrame.setBackgroundColour = tFrame.setBackgroundColor

  function tFrame.write(sText)
    expect(1, sText, "string", "number")

    -- if we are within the bounds (y direction)
    if iCY <= iY and iCY >= 1 then
      sText = tostring(sText)
      -- for each character, set it.
      local i = 0
      for char in sText:gmatch(".") do
        local pos = iCX + i
        -- if we are within bounds (x direction)
        if pos <= iX and pos >= 1 then
          tBuffer1[iCY][1][pos] = char
          tBuffer1[iCY][2][pos] = blitText
          tBuffer1[iCY][3][pos] = blitBackground
          i = i + 1
        end
      end

      tBuffer1[iCY].dirty = true
      bDirty = true
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
    if sTextColor:match("[^abcdef0123456789]") then
      error("Bad argument #2: Allowed characters: abcdef0123456789", 2)
    end
    if sBackgroundColor:match("[^abcdef0123456789]") then
      error("Bad argument #3: Allowed characters: abcdef0123456789", 2)
    end

    -- if we are within bounds (y direction)
    if iCY >= 1 and iCY <= iY then
      -- for each char
      local i = 0
      for char in sText:gmatch(".") do
        -- write it
        local pos = iCX + i
        -- if we are within bounds (x direction)
        if pos >= 1 and pos <= iX then
          tBuffer1[iCY][1][pos] = char
          i = i + 1
        end
      end
      -- do the same as above but for each text color blit char
      i = 0
      for char in sTextColor:gmatch(".") do
        local pos = iCX + i
        if pos >= 1 and pos <= iX then
          tBuffer1[iCY][2][pos] = char
          i = i + 1
        end
      end
      -- do the same as above but for each background color blit char
      i = 0
      for char in sBackgroundColor:gmatch(".") do
        local pos = iCX + i
        if pos >= 1 and pos <= iX then
          tBuffer1[iCY][3][pos] = char
          i = i + 1
        end
      end

      tBuffer1[iCY].dirty = true
      bDirty = true
    end
    tFrame.setCursorPos(iCX + #sText, iCY)
  end

  function tFrame.scroll(iNum)
    expect(1, iNum, "number")

    -- if our number is greater than 0
    if iNum > 0 then
      -- remove the first line, and append new line however many times is needed
      for i = 1, iNum do
        table.remove(tBuffer1, 1) -- table.remove should automatically shift
        initLine(iY, ' ', blitText, blitBackground, false)
      end
      for i = 1, iY do
        tBuffer1[i].dirty = true
      end
      bDirty = true
    else
      -- remove the last line, and append new line however many times is needed
      for i = -1, iNum, -1 do
        table.remove(tBuffer1)
        table.insert(tBuffer1, 1, {})
        initLine(1, ' ', blitText, blitBackground, false)
      end
      for i = 1, iY do
        tBuffer1[i].dirty = true
      end
      bDirty = true
    end
  end

  function tFrame.getBackgroundColor()
    return tBlit[blitBackground]
  end
  tFrame.getBackgroundColour = tFrame.getBackgroundColor

  function tFrame.getTextColor()
    return tBlit[blitText]
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
    expect(1, iLine, "number")
    if iLine <= 0 then
      error("Bad argument #1: Expected number greater than 0.", 2)
    end

    initLine(iLine, ' ', blitText, blitBackground, false)
    tBuffer1[iLine].dirty = true
    bDirty = true
  end

  return tFrame
end

return tFuncs
