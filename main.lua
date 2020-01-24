Network  = require("nnlib")
World    = dofile("world.lua")
Ray      = dofile("ray.lua")
Creature = dofile("creature.lua")

GAME = {
  world = World.new();
}

local creatures = {}

function love.load()
  for i = 1, 10 do
    table.insert(creatures, Creature.new(math.random(100, 1100), math.random(100, 800), 1, 2, {16}))
  end
end

function love.update(dt)
  for _, creature in ipairs(creatures) do
    creature:Update(dt)
  end
end

function love.draw(dt)

  love.graphics.clear(82/255, 82/255, 82/255)

  for _, creature in ipairs(creatures) do
    creature:Draw()
  end
end
