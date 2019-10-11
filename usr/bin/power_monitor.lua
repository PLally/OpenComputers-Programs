local power_monitor = require("power_monitor")
local component = require("component")
local induction_matrix = component.induction_matrix
local gpu = component.gpu
monitor = power_monitor.Monitor:new(induction_matrix)

gpu.setResolution(80, 25)
gpu.fill(0, 0, 80, 25, " ")
local isOn = false
local function generatorOn( on )
    isOn = on
    if on then 
        redstone.setOutput(sides.down, 15)
    else 
        redstone.setOutput(sides.down, 0)
    end
end

while true do
    local energy = monitor:getEnergy()
    local text = monitor.prettyPrint(energy)
    local percentFull =  monitor:getPercentFull()
    local onOff = isOn and "on" or "off"
    if percentFull < 15  then
        generatorOn( true )
    elseif percentFull > 90 then
        generatorOn( false )
    end

    local percentText = tostring(math.floor(percentFull)).."%%"
    gpu.set( 1, 1, string.format( "%-10s  %-10s %-3s", text, percentText, onOff ) )
    os.sleep(0.2)
end