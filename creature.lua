local Creature = {}
Creature.FEELERS = 10
Creature.FEELER_LENGTH = 110

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
  for i = 0, Creature.FEELERS - 1 do
    table.insert(self.feelers, Ray.new(self.pos, {
      x = math.cos(2*math.pi*(i/Creature.FEELERS) + math.pi/10);
      y = math.sin(2*math.pi*(i/Creature.FEELERS) + math.pi/10);
    }, Creature.FEELER_LENGTH))
  end

  -- do an initial feed forward
  self.inputs = {}
  for i = 1, inputs do
    self.inputs[i] = 0.0
  end
  self.outputs = self.brain:FeedForward(self.inputs)
  print(#self.outputs)

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
  self.pos.x = self.pos.x + (self.outputs[1] - 0.50)*dt*3.0
  self.pos.y = self.pos.y + (self.outputs[2] - 0.50)*dt*3.0
  for _, feeler in ipairs(self.feelers) do
    feeler:SetOrigin(self.pos)
  end
end

function Creature:Draw()
  
  for _, feeler in ipairs(self.feelers) do
    love.graphics.setColor(0.80, 0.80, 0.80, 0.30)
    for _, voxel in ipairs(feeler:GetVoxelsOnRay()) do
      local ppos = GAME.world:ToPixel(voxel)
      love.graphics.rectangle("fill", ppos.x, ppos.y, World.VOXEL_SIZE, World.VOXEL_SIZE)
    end

    love.graphics.setColor(1, 0, 0)
    local start = feeler.origin
    local finish = feeler:GetPixelEndPoint()
    love.graphics.line(start.x, start.y, finish.x, finish.y)
  end
  love.graphics.setColor(0, 0, 1)
  love.graphics.circle("fill", self.pos.x, self.pos.y, 30)
end

return Creature
