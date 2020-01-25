local Food = {}

function Food.new(voxel)

  local self = setmetatable({}, {__index = Food})
  self.pos = {
    x = voxel.x;
    y = voxel.y;
  }
  self.color = {
    r = 100/255;
    g = 1;
    b = 100/255;
  }

  return self

end

function Food:Draw()
  
  local pixelp = GAME.world:ToPixel(self.pos)

  love.graphics.setColor(self.color.r, self.color.g, self.color.b)
  love.graphics.rectangle("fill", pixelp.x, pixelp.y, 
                          World.VOXEL_SIZE, World.VOXEL_SIZE)

end

return Food
