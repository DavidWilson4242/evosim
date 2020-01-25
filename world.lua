local World = {}
World.VOXEL_SIZE = 20
World.VOXEL_SX = 800
World.VOXEL_SY = 800

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

  -- initialize food
  for i = 1, self.voxelSize.x do
    for j = 1, self.voxelSize.y do
      if math.random() < 0.05 then
        self:AddTile(Food.new({x = i; y = j}))
      end
    end
  end

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

function World:ToVoxel(pixelPosition)
  return {
    x = math.floor(pixelPosition.x/World.VOXEL_SIZE);
    y = math.floor(pixelPosition.y/World.VOXEL_SIZE);
  }
end

function World:ToPixel(voxelPosition)
  return {
    x = voxelPosition.x*World.VOXEL_SIZE;
    y = voxelPosition.y*World.VOXEL_SIZE;
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

return World
