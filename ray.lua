local Ray = {}

function Ray.new(origin, direction)
  
  local magnitude = math.sqrt(math.pow(direction.x, 2) + math.pow(direction.y, 2))
  local unit = {
    x = direction.x/magnitude;
    y = direction.y/magnitude;
  }
  local start = {
    x = origin.x;
    y = origin.y;
  }

  local self = setmetatable({}, {__index = Ray})
  self.origin = start
  self.unit = unit

  return self

end

function Ray:SetOrigin(origin)
  self.origin.x = origin.x
  self.origin.y = origin.y
end

function Ray:GetVoxelsOnRay(voxelDistance) 
 
  local nodes = {}

  for i = 1, math.ceil(voxelDistance) do
    local nodePixel = {
      x = self.origin.x + self.unit.x*i;
      y = self.origin.y + self.unit.y*i;
    }
    local node = GAME.world:ToVoxel(nodePixel)
    if nodes[#nodes].x ~= node.x and nodes[#nodes].y ~= node.y then
      table.insert(nodes, node)
    end
  end

  return nodes

end

return Ray
