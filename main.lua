Network    = require("nnlib")
Food       = dofile("food.lua")
DeathBlock = dofile("deathblock.lua")
World      = dofile("world.lua")
Ray        = dofile("ray.lua")
Creature   = dofile("creature.lua")

GAME = {
  world = World.new();
  leaderboard = {};
  creatures = {};
  timespeed = 1;
}

local selectedCreature = nil

function love.load()
  math.randomseed(os.time())
  for i = 1, 2500 do
    local creature = Creature.new(math.random(10, World.ABSOLUTE_SX), 
                                  math.random(10, World.ABSOLUTE_SY))
    table.insert(GAME.creatures, creature)
  end
  GAME.world:UpdateLeaderboard()
end

function love.update(dt)
  GAME.world:Update(dt*GAME.timespeed)
  for _, creature in ipairs(GAME.creatures) do
    creature:Update(dt*GAME.timespeed)
  end
end

function love.draw()

  love.graphics.clear(50/255, 204/255, 1)

  GAME.world:Draw() 

  for _, creature in ipairs(GAME.creatures) do
    creature:Draw()
  end
  
  if selectedCreature then
    selectedCreature:DrawBrain()
  end

  love.graphics.setColor(0, 0, 0)
  love.graphics.print("creatures: " .. #GAME.creatures, 10, 10)

  local leaders = {}
  for _, entry in pairs(GAME.leaderboard) do
    table.insert(leaders, entry)
  end
  table.sort(leaders, function(a, b)
    return a.amount > b.amount
  end)

  local px = GAME.world.screenSize.x - 100
  local panelsy = math.min(GAME.world.screenSize.y - 100, #leaders*30)
  love.graphics.setColor(38/255, 38/255, 38/255, 0.90)
  love.graphics.rectangle("fill", px - 10, 40, 90, panelsy)

  for i, entry in ipairs(leaders) do
    local py = 40 + i*30
    if py >= GAME.world.screenSize.y - 100 then
      break
    end
    love.graphics.setColor(entry.r, entry.g, entry.b)
    love.graphics.rectangle("fill", px, py, 30, 30)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(tostring(entry.amount), px + 35, py + 6)
  end

end

function love.keypressed(key)
  if key == "u" then
    GAME.timespeed = math.ceil(GAME.timespeed * 1.20)
  elseif key == "j" then
    GAME.timespeed = math.floor(GAME.timespeed * 0.80)
    if GAME.timespeed < 1 then
      GAME.timespeed = 1
    end
  elseif key == "w" then
    GAME.world:MoveCamera(0, 1)
  elseif key == "s" then
    GAME.world:MoveCamera(0, -1)
  elseif key == "a" then
    GAME.world:MoveCamera(1, 0)
  elseif key == "d" then
    GAME.world:MoveCamera(-1, 0)
  end
end

function love.mousepressed(x, y, button)
  local screenPosition = {x = x; y = y}
  local mousePos = GAME.world:ScreenPointToWorldPoint(screenPosition)

  local foundCreature = false
  for _, creature in ipairs(GAME.creatures) do
    if creature:PositionIsInBounds(mousePos) then
      selectedCreature = creature
      foundCreature = true
      break
    end
  end
  if not foundCreature then
    selectedCreature = nil
  end
end
