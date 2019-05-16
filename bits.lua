require 'sounds'
local moonshine = require 'moonshine'

-- Number of bits on both axes. Can be set from tweet code.
N = 31
X,Y = 1,1
x,y = 1,1
local bits = {}
local timers = {}
local NUM_TIMERS = 9
local startTime = nil
local user = {}
local themesongFilename = '1.mp3'
local gameOverFilename = 'bits_game_over.mp3'
local gameWinFilename = 'bits_game_win.mp3'

local cd=1.3
local colors = {
  {1, 1, 1},              -- 1 = white
  {0, 0, 0},              -- 2 = black
  {0.1, 0.1, 0.1},        -- 3 = dark
  {0.5/cd, 0.5/cd, 0.5/cd},  -- 4 = gray
  {1.0/cd, 0.0, 1.0/cd},    -- 5 = purple
  {0.1, 0.1, 1},            -- 6 = blue
  {0.0, 1.0/cd, 1.0/cd},    -- 7 = cyan
  {0, 1/cd, 0},            -- 8 = green
  {1.0/cd, 1.0/cd, 0.0},    -- 9 = yellow
  {0.9/cd, 0.3/cd, 0},      -- 10 = orange
  {1/cd, 0, 0},            -- 11 = red
}

-- KEY PRESSES
-- when a lower-case value is set to 1,
-- it means the corresponding key was pressed
-- in the previous frame
--
-- when an upper-case value is set to 1,
-- it means the corresponding key is being
-- held down at that moment
--
-- s = spacebar, u = up, d = down, l = left, r = right
s,u,d,l,r,S,U,D,L,R = 0,0,0,0,0,0,0,0,0,0

-- "GAME OVER", and "GAME WON" CONVENIENCE VARIABLES - set with DIE(), WIN()
GO,GW = false,false

-- MATHS
function FLR(a) return math.floor(a) end
function DEG(a) return math.deg(a) end
function RAD(a) return math.rad(a) end
function CEIL(a) return math.ceil(a) end
function FLR(a) return math.floor(a) end
-- TODO: can condense below two RAND funcs
-- Gen integer in range [a,b]
function RN(a, b) return FLR(math.random(a, b)) end
function RC() return RN(1,12) end -- GET RANDOM COLOR INDEX
-- Gen integer is range [1,N] where N = Number of bits
function RNN() return FLR(math.random(1, N)) end
-- Gen nubmer within [0,1)
-- "Maybe" (Gen either integer 0 or 1)
function M() return math.random()>0.5 and 1 or 0 end
-- TODO: combine two below SRAND funcs via optional param?
function SRAND(x) math.randomseed(x) end -- ALLOW SPECIFIC SEEDS
function SRAND() math.randomseed(tonumber(tostring(os.time()):reverse():sub(1,6))) end -- SEED RANDOMLY
function ABS(a, b) return math.abs(a, b) end
function SQRT(a) return math.sqrt(a) end
function LOG(x) return math.log(x) end
function EXP(x) return math.exp(x) end
function POW(x,y) return math.pow(x,y) end
function SIN(x) return math.sin(x) end
function COS(x) return math.cos(x) end
function TAN(x) return math.tan(x) end
function ASIN(x) return math.asin(x) end
function ACOS(x) return math.acos(x) end
function ATAN(x) return math.atan(x) end
function ATAN2(x, y) return math.atan2(y, x) end
function PI() return math.pi end
--function MIN(nums) return math.min(nums) end -- TODO: variable-length arglist (ref: see math.min)
function MAX(a,b) return math.max(a,b) end
function MIN(a,b) return math.min(a,b) end
function CL(min,val,max) return CLAMP(min,val,max) end
function CLAMP(min, val, max)
  if min > max then 
    min, max = max, min
  end
  return math.max(min, math.min(max, val))
end

-- TIMERS
-- TIP: Pass no 'idx', e.g. call 'T()', to access program's total time so far
-- GET TIME OF TIMER # "IDX"
function T(idx)
  if idx == nil then return love.timer.getTime() - startTime
  else return love.timer.getTime() - timers[idx] end
end
-- RESET TIMER BY IDX 
function RT(idx) timers[idx] = love.timer.getTime() end

-- BITS
function B(x,y,c) BIT(x,y,c) end -- SET [B]IT
function H(y,x1,x2,col) for i=x1,x2 do BIT(i,y,col) end end -- [H]ORIZONTAL LINE OF BITS
function V(x,y1,y2,col) for i=y1,y2 do BIT(x,i,col) end end -- [V]ERTICAL LINE OF BITS
function RB(x1,y1,x2,y2,col) for i=y1,y2 do H(i,x1,x2,col) end end -- [R]ECT OF [B]ITS
function BG(col) RB(0,0,N,N,col) end -- DRAW SCREEN's [B]ACK[G]ROUND COLOR

function G(xBit,yBit) return bits[FLR(xBit)][FLR(yBit)] end -- GET BIT - Get color of bit. Returns 0 if no bit.
function GC(col) -- GET COL OF N BITS
  return bits[col]
end 
function GR(row) -- GET ROW OF N BITS
  local bitsToReturn = {}
  for i=1,N do 
    bitsToReturn[1] = i
    bitsToReturn[2] = row
    bitsToReturn[3] = bits[i][row] 
  end
  return bitsToReturn
end

-- AVATAR DRAWING METHODS
function A(x1,y1,c,x2,y2)
  if x2 == nil or y2 == nil then
    if not user.avatarImage then
      B(x1,y1,1)
      return
    else
      x2,y2 = x1,y1
    end
  end
  x1 = FLR(CLAMP(1,x1,N))
  y1 = FLR(CLAMP(1,y1,N))
  x2 = FLR(CLAMP(1,x2,N))
  y2 = FLR(CLAMP(1,y2,N))
  local w = love.graphics.getWidth()
  local h = love.graphics.getHeight()
  xA,xB = (x1-1)*(w/N),(x2)*(w/N)
  yA,yB = (y1-1)*(h/N),(y2)*(h/N)
  if user.avatarImage then
    AVATAR(xA,yA,xB,yB,aspect,c)
  else
    RB(x1,y1,x2-1,y2-1,1)
  end
  bits[x1][y1] = -1
end

-- SOUND
function FX(fname,shouldLoop)
  if shouldLoop == nil then
    shouldLoop = false
  elseif shouldLoop == 1 then
    shouldLoop = true
  end
  PLAYSND(fname,1.0,shouldLoop)
end

function ST(fname)
  STOPSND(fname)
end


-- TODO: based upon pre-processing the file, figure out what input keys are used, 
-- and have this library flash an infographic of those controls at the start of the program
-- so that people know how to interact with it. 

-- TODO: pressing the 'c' key at any time shows a controls overlay? or 'h' for help?

local Imgs = {}

local soundFilenames = {}
local imgFilenames = {}

function preprocess(fname)
  for line in love.filesystem.lines(fname) do
    -- TODO: make it so changing PLAYSND's method name changes gmatch string as well
    for soundFilename in string.gmatch(line, "PLAYSND%('([^']+)") do
      table.insert(soundFilenames, soundFilename)
    end
    for soundFilename in string.gmatch(line, "PL%('([^']+)") do
      table.insert(soundFilenames, soundFilename)
    end
    for soundFilename in string.gmatch(line, "LP%('([^']+)") do
      table.insert(soundFilenames, soundFilename)
    end
    -- TODO: make it so changing IMG's method name changes gmatch string as well
    for imgFilename in string.gmatch(line, "IMG%('([^']+)") do
      table.insert(imgFilenames, imgFilename)
    end
    for imgFilename in string.gmatch(line, "I%('([^']+)") do
      table.insert(imgFilenames, imgFilename)
    end
  end
end

function BIT(x1,y1,c)
  x1 = FLR(CLAMP(1,x1,N))
  y1 = FLR(CLAMP(1,y1,N))
  if c == nil then 
    c = 1
  else
    c = CLAMP(1,c,12)
  end
  local w = love.graphics.getWidth()
  local h = love.graphics.getHeight()
  xA,xB = (x1-1)*(w/N),x1*(w/N)
  yA,yB = (y1-1)*(h/N),y1*(h/N)
  RECTFILL(xA,yA,xB,yB,c,1)
  bits[x1][y1] = c
end

local function loadAssets()
  for k, v in pairs(soundFilenames) do
    Sounds[v] = Sound:new(v, 8) -- TODO: dynamically size the sound channel amount
  end

  for k, v in pairs(imgFilenames) do
    Imgs[v] = love.graphics.newImage(v)
  end
end

-- TODO: get and load all sounds (use pre-fetch API), load em into mem
-- TODO: get all images, pre-fetch 'em by default, load em into mem
function love.load()
  love.keyboard.setKeyRepeat(false)

  SRAND()

  network.async(function()
    user.name = castle.user.getMe().username
    user.avatarImage = love.graphics.newImage(castle.user.getMe().photoUrl)
    Imgs['avatar'] = user.avatarImage
  end)

  love.graphics.setDefaultFilter('linear', 'linear', 1)

  startTime = love.timer.getTime()
  for i=1,NUM_TIMERS do
    timers[i] = startTime
  end

  -- init bits to 0
  for i=1,N do
    bits[i] = {}
    for j=1,N do
      bits[i][j]=0
    end
  end

  if TS ~= nil then
    themesongFilename = TS..".mp3"
    -- TODO: error handling on bad inputs to TS
  end

  for i=1,9 do
    table.insert(soundFilenames, 'fx_'..i..'.mp3')
  end

  table.insert(soundFilenames, themesongFilename)
  table.insert(soundFilenames, gameWinFilename)
  table.insert(soundFilenames, gameOverFilename)

  loadAssets()

  THEME('retro')
  PLAYSND(themesongFilename,1.0,true)

  if _L ~=nil then _L() end
end

local keysJustPressed = {}
local keysHeld = {}
local mouseJustClickedX = nil
local mouseJustClickedY = nil
local mouseHeld = false

-- TODO:
function love.update(dt)
  -- TODO: update sound engine and anything else per update call
  if not GO and not GW then
    if _U ~=nil then _U(dt) end

    -- update [x,y,X,Y] based upon arrow key input
    X = X - L * 16 * dt + R * 16 * dt
    Y = Y - U * 16 * dt + D * 16 * dt
    x = x - l + r
    y = y - u + d
    X = CLAMP(1, X, N)
    Y = CLAMP(1, Y, N)
    x = CLAMP(1, x, N)
    y = CLAMP(1, y, N)

    if l == 1 then X = FLR(X) end
    if r == 1 then X = CEIL(X) end
    if u == 1 then Y = FLR(Y) end
    if d == 1 then Y = CEIL(Y) end
  end

  -- nil any input
  for k, v in pairs(keysJustPressed) do
    keysJustPressed[k] = false
    s,u,d,l,r = 0,0,0,0,0
  end
  mouseJustClicked = false

  -- clear data of bits from prev frame
  for i=1,N do
    for j=1,N do
      bits[i][j] = 0
    end
  end
end

function love.mousepressed(x, y, button, istouch, presses)
  if button == 1 then
    mouseJustClickedX = x
    mouseJustClickedY = y
    mouseButtonHeld = true
  end
end

function love.mousereleased(x, y, button, istouch, presses)
  if button == 1 then
    mouseJustClickedX = nil
    mouseJustClickedY = nil
    mouseButtonHeld = false
  end
end

function love.keypressed(key, scancode, isrepeat)
  if     key == 'space' then s,S = 1,1
  elseif key == 'up'    then u,U = 1,1
  elseif key == 'down'  then d,D = 1,1
  elseif key == 'left'  then l,L = 1,1
  elseif key == 'right' then r,R = 1,1
  end
  keysJustPressed[key] = true
  keysHeld[key] = true

  for i=1,9 do
    if key == tostring(i) then FX(i) end
  end

  if key == 'p' and (GO or GW) then
    POST("Just screenshottin this bits game...")
  end
end

function love.keyreleased(key, scancode)
  if     key == 'space' then S = 0
  elseif key == 'up'    then U = 0
  elseif key == 'down'  then D = 0
  elseif key == 'left'  then L = 0
  elseif key == 'right' then R = 0
  end

  if keysHeld[key] ~= nil then
    keysHeld[key] = false
  else
    -- TODO: ERROR: this case shouldn't happen
  end
end

function BTN(key)
  if key == 'm' then
    -- TODO: throw warning about 'm' being a reserved key
  elseif keysHeld[key] ~= nil then
    return keysHeld[key]
  end
end

function BTNP(key)
  if key == 'm' then
    --TODO: throw warning about 'm' being a reserved key
  elseif keysJustPressed[key] ~= nil then
    val = keysJustPressed[key]
    keysJustPressed[key] = false
    return val
  end
end

function MOUSE()
  return mouseHeld
end

function MOUSEP()
  if mouseJustClickedX then
    xToReturn = mouseJustClickedX
    yToReturn = mouseJustClickedY
    mouseJustClickedX = nil
    mouseJustClickedY = nil
    return xToReturn, yToReturn
  else
    return nil, nil
  end
end

function DIE()
  if not GO then
    PLAYSND(gameOverFilename)
    VOLUME(themesongFilename, 0.36)
    GO = true
  end
end

function WIN()
  if not GW then
    VOLUME(themesongFilename, 0.36)
    PLAYSND(gameWinFilename)
    GW = true
  end
end

local filter_effect = nil

function love.draw()
  local drawFunc = (function()
    if _D ~=nil then _D() end
    if GO or GW then
      local msg = ""
      if GO then msg = "Game Over" end
      if GW then msg = "You Win!" end
      TEXT(msg, 20, 20, 2, 1)
      TEXT("Ctrl or Cmd + R to restart", 20, 60, 2, 1)
      TEXT("Press 'P' to post a screenshot!", 20, 100, 2, 1)
    end
  end)

  if filter_effect then
    filter_effect(drawFunc)
  else
    drawFunc()
  end
end

-- TODO: make this do the thing. make something similarly architected to moonshine,
-- but with more meaningful filters and proper performance across machines

-- TODO: make a simple grayscale filter as a starting example
-- TODO: allow filters per object
-- TODO: assign a filterId to each filter
function ADD_FILTER(type)
  filter_effect = moonshine(moonshine.effects.dmg)
  filter_effect.dmg.palette = 'greyscale'
end

function REMOVE_FILTER(filterId)
  filter_effect = nil -- TODO: remove by filterId
end

function THEME(type)
  theme = type
  if type == 'none' or type == nil then
    filter_effect = nil
  elseif type == 'retro' then
    filter_effect = moonshine(moonshine.effects.glow)
    .chain(moonshine.effects.pixelate)
    .chain(moonshine.effects.crt)
    .chain(moonshine.effects.scanlines)
    filter_effect.glow.strength = 10.0
    filter_effect.glow.min_luma = 0.2
    filter_effect.pixelate.size = {8, 4}
    filter_effect.pixelate.feedback = 0.65
    filter_effect.crt.distortionFactor = {1.05, 1.06}
    filter_effect.scanlines.opacity = 1.0
    filter_effect.scanlines.thickness = 0.2
  end
end

-- Detect if point is in circle
function PIC(px, py, cx, cy, rad)
  local dx, dy = px - cx, py - cy
  return dx * dx + dy * dy <= rad * rad
end

local function setColor(col, alpha)
  alpha = alpha or 1.0

  if col == nil then
    -- TODO: throw some error/warning
    col = {1,1,1}
  end

  if colors[col] then
    col = colors[col]
  else
    -- TODO: throw some error/warning
  end

  love.graphics.setColor(col[1], col[2], col[3], alpha)
end

function POST(message)
  network.async(function()
    castle.post.create {
      message = message,
      media = 'capture',
    }
  end)
end

-- TODO: use size and font
-- TODO: pre-fetch font in load
function TEXT(message, xPos, yPos, scale, color, font)
  if message ~= nil then
    if color == nil then
      color = 1
    end
    setColor(color)
    love.graphics.print(message, xPos, yPos, 0, scale, scale)
  end
end

local function drawRect(type, x1, y1, x2, y2, color, alpha)
  local xRect = x1
  local yRect = y1
  if x2 < x1 then xRect = x2 end
  if y2 < y1 then yRect = y2 end

  local width = math.abs(x1 - x2)
  local height = math.abs(y1 - y2)

  setColor(color, alpha)
  love.graphics.rectangle(type, xRect, yRect, width, height)
end

function RECTFILL(x1, y1, x2, y2, color, alpha)
  drawRect('fill', x1, y1, x2, y2, color, alpha)
end

-- TODO: supplying filename needs to create image at load-time automatically
-- and this function needs to lookup that love2d image in a table
-- and then draw that image according to the below params
-- TODO: define + use types for 'aspect' param
local function IMG(filename, x1, y1, x2, y2, aspect, color)
  aspect = aspect or 'aspect_fill'

  col_r,col_g,col_b,col_a = love.graphics.getColor()

  if Imgs[filename] then

    if color == nil then
      color = {1,1,1}
    end
    
    setColor(color)

    local actualWidth = Imgs[filename]:getWidth()
    local actualHeight = Imgs[filename]:getHeight()

    -- default aspect == 'stretch_to_fill'
    local targetWidth = ABS(x2 - x1)
    local targetHeight = ABS(y2 - y1)
    if aspect == 'stretch_fill' then

    elseif aspect == 'aspect_fill' then
      if actualWidth > targetWidth and actualHeight > targetHeight then
        if targetWidth/targetHeight > actualWidth/actualHeight then
          targetWidth = targetHeight * (actualWidth/actualHeight)
          x1 = x1 + ABS(x2 - x1) / 2 - targetWidth / 2
        else
          targetHeight = targetWidth * (actualHeight/actualWidth)
          y1 = y1 + ABS(y2 - y1) / 2 - targetHeight / 2
        end
      elseif actualWidth > targetWidth then
        targetHeight = targetWidth * (actualHeight/actualWidth)
        y1 = y1 + ABS(y2 - y1) / 2 - targetHeight / 2
      elseif actualHeight > targetHeight then
        targetWidth = targetHeight * (actualWidth/actualHeight)
        x1 = x1 + ABS(x2 - x1) / 2 - targetWidth / 2
      end
    end

    local xScaleFactor = targetWidth / actualWidth
    local yScaleFactor = targetHeight / actualHeight

    love.graphics.draw(Imgs[filename], x1, y1, 0, xScaleFactor, yScaleFactor, 0, 0)
  end

  love.graphics.setColor({col_r,col_g,col_b,col_a})
end

function AVATAR(x1, y1, x2, y2, aspect, color)
  aspect = aspect or 'aspect_fill'
  setColor(color)
  if user.avatarImage then
    IMG('avatar', x1, y1, x2, y2, aspect, color)
  else
    -- TODO: throw warning?
  end
end

function USERNAME()
  if user.name then 
    return user.name
  end
end

-- TODO: pre-fetch all sounds ever played, load them into sound engine
-- with a default volume and other params. if sound is larger than a
-- certain filesize... maybe set it to stream, rather than static?
-- can we intuit this somehow?

-- TODO: play actual sound passed in
-- TODO: volume prob not need to be passed every time...
-- TODO: make volume+looping optional params
-- TODO: allow an onFinishFunc per sound
function PLAYSND(filename, volume, shouldLoop)
  if type(filename) == 'number' then
    filename = 'fx_'..tostring(filename)..'.mp3'
  end
  if volume == nil then
    volume = 1.0
  end
  if shouldLoop == nil then
    shouldLoop = false
  end
  if Sounds[filename] then
    Sounds[filename]:setVolume(volume)
    Sounds[filename]:setLooping(shouldLoop)
    Sounds[filename]:play()
  end
end

function VOLUME(filename, volume)
  -- TODO: throw warning if volume outside of range?
  -- silently just clamp for now
  volume = CLAMP(0.0, volume, 1.0)
  if Sounds[filename] then
    Sounds[filename]:setVolume(volume)
  end
end

function PAUSESND(filename)
  if Sounds[filename] then
    Sounds[filename]:pause()
  end
end

function STOPSND(filename)
  if Sounds[filename] then
    Sounds[filename]:stop()
  end
end
