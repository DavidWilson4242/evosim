local World = {}
World.VOXEL_SIZE = 20
World.VOXEL_SX = 300 --math.ceil(love.graphics.getWidth()/World.VOXEL_SIZE)
World.VOXEL_SY = 300 -- math.ceil(love.graphics.getHeight()/World.VOXEL_SIZE)
World.ABSOLUTE_SX = World.VOXEL_SIZE*World.VOXEL_SX
World.ABSOLUTE_SY = World.VOXEL_SIZE*World.VOXEL_SY

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
  self.tiles = {}

  self.cameraPos = {
    x = 0;
    y = 0;
  }

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

function World:GenerateEnvironment()
  for i = 1, self.voxelSize.x do
    for j = 1, self.voxelSize.y do
      local noise = love.math.noise(i/30, j/30)
      if noise <= 0.20 then
        local food = Food.new({x = i; y = j})
        food.color = {
          r = 100/255;
          g = 1.0;
          b = 100/255;
        }
        self:AddTile(food)
      end
    end
  end
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
