local nnlib = require("nnlib")

local network = nnlib.CreateNetwork(5, 6, {5, 5})
local outputs = network:FeedForward({1.0, 1.0, 0.33, 0.60, 0.0})
for i, v in ipairs(outputs) do
    print(i, v)
end
