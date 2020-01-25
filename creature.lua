local Creature = {}
Creature.FEELERS = 10
Creature.FEELER_LENGTH = 110
Creature.BRAIN_FRAME_SCALE = {
  x = 0.20;
  y = 0.50;
}

function Creature.new(x, y)
  local self = setmetatable({}, {__index = Creature})
  
  local inputs = 1 + Creature.FEELERS*3
  local outputs = 2
  local hiddens = {6, 6, 6}

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
  
  self.feelers = {}
  for i = 0, Creature.FEELERS - 1 do
    table.insert(self.feelers, Ray.new(self.pos, {
      x = math.cos(2*math.pi*(i/Creature.FEELERS) + math.pi/10);
      y = math.sin(2*math.pi*(i/Creature.FEELERS) + math.pi/10);
    }, Creature.FEELER_LENGTH))
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
  self.inputs[1] = (math.sin(love.timer.getTime()) - 0.50)*2.0

  for i, feeler in ipairs(self.feelers) do
    local nodes = feeler:GetVoxelsOnRay()  
    local foundTile = false
    for _, voxel in ipairs(nodes) do
      local tiles = GAME.world:GetTilesAt(voxel)
      if tiles then
        foundTile = true
        self.inputs[2 + (i*3 - 3)] = tiles[1].color.r
        self.inputs[2 + (i*3 - 2)] = tiles[1].color.g
        self.inputs[2 + (i*3 - 1)] = tiles[1].color.b
        break
      end
    end
    if not foundTile then
      self.inputs[2 + (i*3 - 3)] = 0.00
      self.inputs[2 + (i*3 - 2)] = 0.00
      self.inputs[2 + (i*3 - 1)] = 0.00
    end
  end

end

function Creature:Update(dt)
  local et = love.timer.getTime()
  self:UpdateInputs()
  self:UpdateOutputs()
  self.pos.x = self.pos.x + (self.outputs[1] - 0.50)*dt*3.0
  self.pos.y = self.pos.y + (self.outputs[2] - 0.50)*dt*3.0
  for _, feeler in ipairs(self.feelers) do
    feeler:SetOrigin(self.pos)
  end
end

function Creature:Draw()
  
  for _, feeler in ipairs(self.feelers) do
    --[[
    love.graphics.setColor(0.80, 0.80, 0.80, 0.30)
    for _, voxel in ipairs(feeler:GetVoxelsOnRay()) do
      local ppos = GAME.world:ToPixel(voxel)
      love.graphics.rectangle("fill", ppos.x, ppos.y, World.VOXEL_SIZE, World.VOXEL_SIZE)
    end
    ]]

    love.graphics.setColor(1, 0, 0)
    local start = feeler.origin
    local finish = feeler:GetPixelEndPoint()
    love.graphics.line(start.x, start.y, finish.x, finish.y)
  end

  -- draw creature body
  love.graphics.setColor(0, 0, 1)
  love.graphics.circle("fill", self.pos.x, self.pos.y, 30)

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
