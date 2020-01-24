local Ray = {}

function Ray.new(origin, direction, magnitude)
  
  local dirmag = math.sqrt(math.pow(direction.x, 2) + math.pow(direction.y, 2))
  local unit = {
    x = direction.x/dirmag;
    y = direction.y/dirmag;
  }
  local start = {
    x = origin.x;
    y = origin.y;
  }

  local self = setmetatable({}, {__index = Ray})
  self.origin = start
  self.unit = unit
  self.magnitude = magnitude

  return self

end

function Ray:SetOrigin(origin)
  self.origin.x = origin.x
  self.origin.y = origin.y
end

function Ray:GetVoxelsOnRay() 
 
  local nodes = {}

  for i = 0, math.ceil(self.magnitude) do
    local nodePixel = {
      x = self.origin.x + self.unit.x*i;
      y = self.origin.y + self.unit.y*i;
    }
    local node = GAME.world:ToVoxel(nodePixel)
    if #nodes == 0 or (nodes[#nodes].x ~= node.x or nodes[#nodes].y ~= node.y) then
      table.insert(nodes, node)
    end
  end

  return nodes

end

function Ray:GetPixelEndPoint()
  return {
    x = self.origin.x + self.unit.x*self.magnitude;
    y = self.origin.y + self.unit.y*self.magnitude;
  }
end

return Ray
