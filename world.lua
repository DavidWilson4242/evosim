local World = {}
World.VOXEL_SIZE = 20

function World.new()
  local self = setmetatable({}, {__index = World})

  return self
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

return World
