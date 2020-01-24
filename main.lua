Network  = require("nnlib")
World    = dofile("world.lua")
Ray      = dofile("ray.lua")
Creature = dofile("creature.lua")

GAME = {
  world = World.new();
}

local creatures = {}

function love.load()
  local creature = Creature.new(100, 100, 1, 5, {16, 16, 16})
  table.insert(creatures, creature)
end

function love.draw(dt)
  for _, creature in ipairs(creatures) do
    creature:Update(dt)
  end

  love.graphics.clear(82/255, 82/255, 82/255)

  for _, creature in ipairs(creatures) do
    creature:Draw()
  end
end
