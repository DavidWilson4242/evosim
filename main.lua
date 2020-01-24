local Network = require("nnlib")


function love.load()
  
  local network = Network.CreateNetwork(3, 4, {1,10})
  local inputs, outputs, hiddens = network:GetDimensions()
  network:FeedForward({0.20, 0.40, 0.60})


end

function love.draw()
end
