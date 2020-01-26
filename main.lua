Network  = require("nnlib")
Food     = dofile("food.lua")
World    = dofile("world.lua")
Ray      = dofile("ray.lua")
Creature = dofile("creature.lua")

GAME = {
  world = World.new();
  creatures = {};
  timespeed = 1;
}

local selectedCreature = nil

function love.load()
  math.randomseed(os.time())
  for i = 1, 200 do
    table.insert(GAME.creatures, Creature.new(math.random(10, World.ABSOLUTE_SX), math.random(10, World.ABSOLUTE_SY)))
  end
  selectedCreature = GAME.creatures[1]
end

function love.update(dt)
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

  selectedCreature:DrawBrain()

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
