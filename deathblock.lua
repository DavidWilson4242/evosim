local DeathBlock = {}

function DeathBlock.new(voxel)

  local self = setmetatable({}, {__index = DeathBlock})
  self.className = "DeathBlock"
  self.pos = {
    x = voxel.x;
    y = voxel.y;
  }
  self.color = {
    r = 0;
    g = 0;
    b = 0;
    a = 0.40;
  }

  return self

end

function DeathBlock:Draw()
  
  local pixelp = GAME.world:ToPixel(self.pos)

  if pixelp.x + World.VOXEL_SIZE < 0 or pixelp.x > GAME.world.screenSize.x or
     pixelp.y + World.VOXEL_SIZE < 0 or pixelp.y > GAME.world.screenSize.y then
     return
  end

  love.graphics.setColor(self.color.r, self.color.g, self.color.b, self.color.a)
  love.graphics.rectangle("fill", pixelp.x, pixelp.y, 
                          World.VOXEL_SIZE, World.VOXEL_SIZE)

end

return DeathBlock
