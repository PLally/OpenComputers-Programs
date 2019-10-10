local power_monitor = require("power_monitor")
local component = require("component")
local induction_matrix = component.induction_matrix
local gpu = component.gpu
monitor = power_monitor.Monitor:new()

while true do
    local energy = monitor:getEnergy()
    local text = Monitor.prettyPrint(energy)
    print(text)
    os.sleep(1)
end