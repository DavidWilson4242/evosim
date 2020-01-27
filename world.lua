local World = {}
World.VOXEL_SIZE = 50
World.VOXEL_SX = 300 --math.ceil(love.graphics.getWidth()/World.VOXEL_SIZE)
World.VOXEL_SY = 300 -- math.ceil(love.graphics.getHeight()/World.VOXEL_SIZE)
World.ABSOLUTE_SX = World.VOXEL_SIZE*World.VOXEL_SX
World.ABSOLUTE_SY = World.VOXEL_SIZE*World.VOXEL_SY
World.FOOD_REFRESH_TIME = 250

function World.new()
  local self = setmetatable({}, {__index = World})
  self.screenSize = {
    x = love.graphics.getWidth();
    y = love.graphics.getHeight();
  }
  self.voxelSize = {
    x = World.VOXEL_SX;
    y = World.VOXEL_SY;
  }
  self.cameraPos = {
    x = 0;
    y = 0;
  }
  self.tiles = {}

  self.foodRecharge = {}

  self.elapsedTime = 0.00

  -- initialize food
  self:GenerateEnvironment()

  return self
end

function World:Draw()
  for _, tileRow in pairs(self.tiles) do
    for _, tileStack in pairs(tileRow) do
      for _, tile in ipairs(tileStack) do
        tile:Draw()
      end
    end
  end
end

function World:Update(dt)
  self.elapsedTime = self.elapsedTime + dt

  -- check for new food items to create
  for i = #self.foodRecharge, 1, -1 do
    local entry = self.foodRecharge[i]
    if self.elapsedTime > entry.targetTime then
      self:CreateFoodAt(entry.voxel)
      table.remove(self.foodRecharge, i)
    end
  end
    
end

function World:UpdateLeaderboard()
  GAME.leaderboard = {}
  for _, creature in ipairs(GAME.creatures) do
    local slot = GAME.leaderboard[creature.colorString]
    if slot then
      slot.amount = slot.amount + 1
    else
      GAME.leaderboard[creature.colorString] = {
        amount = 1;
        seed = math.random();
        r = creature.color.r;
        g = creature.color.g;
        b = creature.color.b;
      }
    end
  end
end

function World:GenerateEnvironment()
  for i = 1, World.VOXEL_SX do
    self:CreateDeathBlockAt({x = i; y = 1})
    self:CreateDeathBlockAt({x = i; y = World.VOXEL_SY})
  end
  for i = 1, World.VOXEL_SY do
    self:CreateDeathBlockAt({x = 1;              y = i})
    self:CreateDeathBlockAt({x = World.VOXEL_SX; y = i})
  end
  for i = 1, self.voxelSize.x do
    for j = 1, self.voxelSize.y do
      local noise = love.math.noise(i/30, j/30)
      if noise >= 0.50 and noise <= 0.70 and math.random() < 0.80 then
        self:CreateFoodAt({x = i; y = j})
      elseif noise >= 0.85  then
        self:CreateDeathBlockAt({x = i; y = j})
      end
    end
  end
end

function World:CreateFoodAt(voxel)
  if self:TileExistsAt(voxel) then
    return
  end
  local food = Food.new(voxel)
  food.color = {
    r = 100/255;
    g = 1.0;
    b = 100/255;
  }
  self:AddTile(food)
end

function World:CreateDeathBlockAt(voxel)
  if self:TileExistsAt(voxel) then
    return
  end
  self:AddTile(DeathBlock.new(voxel))
end

function World:AddFoodRefresh(voxel)
  local entry = {
    targetTime = self.elapsedTime + World.FOOD_REFRESH_TIME + (math.random() - 0.50)*2.0*5.0;
    voxel = voxel;
  }
  table.insert(self.foodRecharge, entry)
end

function World:ToVoxel(pixelPosition)
  return {
    x = math.floor(pixelPosition.x/World.VOXEL_SIZE);
    y = math.floor(pixelPosition.y/World.VOXEL_SIZE);
  }
end

function World:ToPixel(voxelPosition)
  return {
    x = voxelPosition.x*World.VOXEL_SIZE + self.cameraPos.x;
    y = voxelPosition.y*World.VOXEL_SIZE + self.cameraPos.y;
  }
end

function World:ApplyCameraToPixel(pixelPosition)
  return {
    x = pixelPosition.x + self.cameraPos.x;
    y = pixelPosition.y + self.cameraPos.y;
  }
end

function World:ScreenPointToWorldPoint(screenPosition) 
  return {
    x = screenPosition.x - self.cameraPos.x;
    y = screenPosition.y - self.cameraPos.y;
  }
end

function World:ScaleToPixels(scale)
  return {
    x = scale.x*self.screenSize.x;
    y = scale.y*self.screenSize.y;
  }
end

function World:TileExistsAt(voxel)
  if not self.tiles[voxel.x] or not self.tiles[voxel.x][voxel.y] then
    return false
  end
  return true
end

function World:GetTilesAt(voxel)
  if not self:TileExistsAt(voxel) then
    return nil
  end
  return self.tiles[voxel.x][voxel.y]
end

function World:RemoveAllTilesAt(voxel)
  if not self:TileExistsAt(voxel) then
    return
  end
  self.tiles[voxel.x][voxel.y] = nil
end

function World:AddTile(tile)
  local voxel = tile.pos
  if not self.tiles[voxel.x] then
    self.tiles[voxel.x] = {}
  end
  if not self.tiles[voxel.x][voxel.y] then
    self.tiles[voxel.x][voxel.y] = {}
  end

  table.insert(self.tiles[voxel.x][voxel.y], tile)
end

function World:MoveCamera(dx, dy)
  self.cameraPos.x = self.cameraPos.x + dx*World.VOXEL_SIZE*4
  self.cameraPos.y = self.cameraPos.y + dy*World.VOXEL_SIZE*4
end

return World
