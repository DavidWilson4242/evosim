local Creature = {}
local SETTINGS = {
  feelers = 10;
};

function Creature.new(x, y, inputs, outputs, hiddens)
  local self = setmetatable({}, {__index = Creature})

  self.brain = Network.CreateNetwork(inputs, outputs, hiddens)
  self.inputCount = inputs
  self.outputCount = outputs
  self.hiddens = hiddens
  self.layerCount = #hiddens + 2
  self.pos = {
    x = x;
    y = y;
  }
  
  self.feelers = {}
  for i = 0, SETTINGS.feelers - 1 do
    table.insert(self.feelers, Ray.new(GAME.world:ToVoxel(self.pos), {
      x = math.cos(2*math.pi*(i/SETTINGS.feelers));
      y = math.sin(2*math.pi*(i/SETTINGS.feelers));
    }))
  end

  -- do an initial feed forward
  self.inputs = {}
  for i = 1, inputs do
    self.inputs[i] = 0.0
  end
  self.outputs = self.brain:FeedForward(self.inputs)

  return self
end

function Creature:UpdateOutputs()
  self.outputs = self.brain:FeedForward(self.inputs)
end

function Creature:UpdateInputs(inputs)
  self.inputs = inputs
end

function Creature:Update(dt)
  local et = love.timer.getTime()
  self:UpdateInputs({math.sin(et)/2.0 + 0.50})
  self:UpdateOutputs()
  for i, v in ipairs(self.outputs) do
    io.write(v .. " ")
  end
  print()
end

function Creature:Draw()
  love.graphics.circle("fill", self.pos.x, self.pos.y, 30)
end

return Creature
