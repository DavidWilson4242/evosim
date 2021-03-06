local Food = {}

function Food.new(voxel)

  local self = setmetatable({}, {__index = Food})
  self.className = "Food"
  self.pos = {
    x = voxel.x;
    y = voxel.y;
  }
  self.color = {
    r = 50/255;
    g = 168/255;
    b = 82/255;
  }

  return self

end

function Food:Draw()
  
  local pixelp = GAME.world:ToPixel(self.pos)

  if pixelp.x + World.VOXEL_SIZE < 0 or pixelp.x > GAME.world.screenSize.x or
     pixelp.y + World.VOXEL_SIZE < 0 or pixelp.y > GAME.world.screenSize.y then
     return
  end

  love.graphics.setColor(self.color.r, self.color.g, self.color.b)
  love.graphics.rectangle("fill", pixelp.x, pixelp.y, 
                          World.VOXEL_SIZE, World.VOXEL_SIZE)

end

return Food
