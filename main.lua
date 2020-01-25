Network  = require("nnlib")
Food     = dofile("food.lua")
World    = dofile("world.lua")
Ray      = dofile("ray.lua")
Creature = dofile("creature.lua")

GAME = {
  world = World.new();
  timespeed = 1;
}

local creatures = {}
local selectedCreature = nil

function love.load()
  math.randomseed(os.time())
  for i = 1, 10 do
    table.insert(creatures, Creature.new(math.random(100, 1100), math.random(100, 800)))
  end
  selectedCreature = creatures[1]
end

function love.update(dt)
  for i = 1, GAME.timespeed do
    for _, creature in ipairs(creatures) do
      creature:Update(dt)
    end
  end
end

function love.draw()

  love.graphics.clear(82/255, 82/255, 82/255)

  GAME.world:Draw() 

  for _, creature in ipairs(creatures) do
    creature:Draw()
  end

  selectedCreature:DrawBrain()

end

function love.keypressed(key)
  if key == "w" then
    GAME.timespeed = math.ceil(GAME.timespeed * 1.20)
  elseif key == "s" then
    GAME.timespeed = math.floor(GAME.timespeed * 0.80)
    if GAME.timespeed < 1 then
      GAME.timespeed = 1
    end
  end
end
