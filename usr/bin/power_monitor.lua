local power_monitor = require("power_monitor")
local component = require("component")
local induction_matrix = component.induction_matrix
local gpu = component.gpu
monitor = power_monitor.Monitor:new(induction_matrix)
gpu.setResolution(80, 25)
gpu.fill(0, 0, 80, 25, " ")
while true do
    local energy = monitor:getEnergy()
    local text = monitor.prettyPrint(energy)
    gpu.set(1, 1, string.format("%-10s", text))
    os.sleep(0.2)
end