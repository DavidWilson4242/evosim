local Creature = {}
Creature.FEELERS = 8
Creature.FEELER_LENGTH = 85
Creature.BRAIN_FRAME_SCALE = {
  x = 0.20;
  y = 0.50;
}

local function constrain(n, min, max)
  return n < min and min or n > max and max or n
end

function Creature.new(x, y)
  local self = setmetatable({}, {__index = Creature})
  
  local inputs = 1 + Creature.FEELERS*2
  local outputs = 2
  local hiddens = {8}

  self.brain = Network.CreateNetwork(inputs, outputs, hiddens)
  self.inputs = {}
  self.outputs = {}
  self.inputCount = inputs
  self.outputCount = outputs
  self.hiddens = hiddens
  self.layerCount = #hiddens + 2
  self.pos = {
    x = x;
    y = y;
  }
  self.radius = 20
  self.clockOffset = 2*math.random()*math.pi

  self.color = {
    r = math.random();
    g = math.random();
    b = math.random();
  }
  self.colorString = self:MakeColorString()

  self.health = 1.0
  self.foodEaten = 0
  self.generation = 0

  self.brain:TweakWeights(function(old)
    return (math.random() - 0.50) * 2.0
  end)
  
  self.feelers = {}
  for i = 0, Creature.FEELERS - 1 do
    table.insert(self.feelers, Ray.new(self.pos, {
      x = math.cos(2*math.pi*(i/Creature.FEELERS));
      y = math.sin(2*math.pi*(i/Creature.FEELERS));
    }, Creature.FEELER_LENGTH))
    self.feelers[#self.feelers].touching = false
  end

  -- do an initial feed forward
  self:UpdateInputs()
  self:UpdateOutputs()

  return self
end

function Creature:UpdateOutputs()
  self.outputs = self.brain:FeedForward(self.inputs)
end

function Creature:UpdateInputs()
  self.inputs[1] = (math.sin(GAME.world.elapsedTime + self.clockOffset) + 1.0)*0.50

  for i, feeler in ipairs(self.feelers) do
    local nodes = feeler:GetVoxelsOnRay()  
    feeler.touching = false
    for _, voxel in ipairs(nodes) do
      local tiles = GAME.world:GetTilesAt(voxel)
      if tiles then
        feeler.touching = true
        if tiles[1].className == "DeathBlock" then
          self.inputs[1 + i*2 - 1] = 1.0
          self.inputs[1 + i*2]     = 0.0
        else
          self.inputs[1 + i*2 - 1] = 0.0
          self.inputs[1 + i*2]     = 1.0
        end
        break
      end
    end
    if not feeler.touching then
        self.inputs[1 + i*2 - 1] = 0.0
        self.inputs[1 + i*2]     = 0.0
    end
  end

end

function Creature:Update(dt)
  local et = love.timer.getTime()
  self:UpdateInputs()
  self:UpdateOutputs()
  self.pos.x = self.pos.x + (self.outputs[1] - 0.50)*dt*20.0
  self.pos.y = self.pos.y + (self.outputs[2] - 0.50)*dt*20.0
  for _, feeler in ipairs(self.feelers) do
    feeler:SetOrigin(self.pos)
  end
  self.health = self.health - dt/600.0

  local myVoxel = GAME.world:ToVoxel(self.pos)
  local tiles = GAME.world:GetTilesAt(myVoxel)
  if tiles then
    if tiles[1].className == "Food" then
      GAME.world:RemoveAllTilesAt(myVoxel)
      GAME.world:AddFoodRefresh(myVoxel)
      self.health = 1.0
      self.foodEaten = self.foodEaten + 1
      if self.foodEaten % 8 == 0 then
        self:Reproduce()
      end
    elseif tiles[1].className == "DeathBlock" then
      self:Die()
      return
    end
  end

  if self.health <= 0 then
    self:Die()
  end
end

function Creature:MakeColorString()
  local r = math.floor(self.color.r*255)
  local g = math.floor(self.color.g*255)
  local b = math.floor(self.color.b*255)
  return r .. "|" .. g .. "|" .. b
end

function Creature:Reproduce()
  local creature = Creature.new(self.pos.x, self.pos.y)
  creature.generation = self.generation + 1
  creature.brain = self.brain:Duplicate()
  if math.random() < 0.70 then
    creature.brain:TweakWeights(function(oldWeight)
      if math.random() < 0.80 then
        return oldWeight
      end
      return oldWeight + (math.random() - 0.50)*2.0*0.30
    end)
  end
  creature.color.r = self.color.r
  creature.color.g = self.color.g
  creature.color.b = self.color.b
  creature.colorString = self.colorString
  table.insert(GAME.creatures, creature)

  if math.random() < 0.20 then
    self:Reproduce()
  end

  GAME.world:UpdateLeaderboard()
end

function Creature:Die()
  for i, creature in ipairs(GAME.creatures) do
    if creature == self then
      table.remove(GAME.creatures, i)
      break
    end
  end
end

function Creature:PositionIsInBounds(pixelPosition)
  local squaredDist = math.pow(self.pos.x - pixelPosition.x, 2) +
                      math.pow(self.pos.y - pixelPosition.y, 2)
  return squaredDist < math.pow(self.radius, 2)
end

function Creature:Draw()

  local rootDrawPos = GAME.world:ApplyCameraToPixel(self.pos)
  
  for _, feeler in ipairs(self.feelers) do
    if feeler.touching then
      love.graphics.setColor(1, 1, 1)
    else 
      love.graphics.setColor(1, 0, 0)
    end
    local start = GAME.world:ApplyCameraToPixel(feeler.origin)
    local finish = GAME.world:ApplyCameraToPixel(feeler:GetPixelEndPoint())
    love.graphics.line(start.x, start.y, finish.x, finish.y)
  end

  -- draw creature body
  love.graphics.setColor(self.color.r, self.color.g, self.color.b)
  love.graphics.circle("fill", rootDrawPos.x, rootDrawPos.y, self.radius)

  -- draw generation number
  love.graphics.setColor(1, 1, 1)
  love.graphics.print(tostring(self.generation), rootDrawPos.x - 5, rootDrawPos.y - 8)

end

function Creature:DrawBrain()

  local frameSize = GAME.world:ScaleToPixels(Creature.BRAIN_FRAME_SCALE)     
  local framePos = {x = 10, y = 10}
  local inputs, outputs, layerCounts = self.brain:GetDimensions()
  local layerCount = #layerCounts + 2
  local maxLayer = 0

  -- find the maximum number of neurons in a layer
  table.insert(layerCounts, 1, inputs)
  table.insert(layerCounts, outputs)
  for _, count in ipairs(layerCounts) do
    maxLayer = (count > maxLayer) and count or maxLayer
  end

  local neuronRad = frameSize.x*0.033
  local horizPad = frameSize.x/(layerCount + 0)
  local vertPad = frameSize.y/(maxLayer + 0)

  love.graphics.setColor(38/255, 38/255, 38/255, 0.90)
  love.graphics.rectangle("fill", framePos.x, framePos.y, frameSize.x, frameSize.y)
  
  local neuronPositions = {}
  
  -- find neuron positions
  for i, count in ipairs(layerCounts) do
    local px = framePos.x + neuronRad*2 + (i - 1)*horizPad
    neuronPositions[i] = {}
    for j = 1, count do
      local py = framePos.y + neuronRad*2 + (j - 1)*vertPad
      neuronPositions[i][j] = {x = px, y = py}
    end
  end

  -- draw connections
  love.graphics.setColor(1, 1, 1, 0.40)
  for i = 1, #layerCounts - 1 do
    for j = 1, layerCounts[i] do
      for k = 1, layerCounts[i + 1] do
        local weight = self.brain:GetWeight(i, j, k)
        local scaled = (constrain(weight, -1.0, 1.0) + 1.0)*0.50
        love.graphics.setColor(scaled, scaled, scaled)
        love.graphics.line(neuronPositions[i][j].x,   neuronPositions[i][j].y,
                           neuronPositions[i+1][k].x, neuronPositions[i+1][k].y)
      end
    end
  end

  for i, layer in ipairs(neuronPositions) do
    for j, position in ipairs(layer)  do
      local value = self.brain:GetValue(i, j)
      love.graphics.setColor(100/255, value, 100/255)
      love.graphics.circle("fill", position.x, position.y, neuronRad)
    end
  end

end

return Creature
