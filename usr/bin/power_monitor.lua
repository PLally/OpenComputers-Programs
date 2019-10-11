local power_monitor = require("power_monitor")
local component = require("component")
local induction_matrix = component.induction_matrix
local gpu = component.gpu
local sides = require("sides")
local redstone = component.redstone
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
    local rateOfChange = monitor:getInput() - monitor:getOutput()
    local percentFull =  monitor:getPercentFull()

    local text = monitor.prettyPrint(energy)
    local changeText = monitor.prettyPrint(rateOfChange).."RF/t"
    local percentText = tostring(math.floor(percentFull)).."%%"
    local onOff = isOn and "on" or "off"

    if percentFull < 15  then
        generatorOn( true )
    elseif percentFull > 90 then
        generatorOn( false )
    end

    gpu.setForeground(0xFFFFFF)
    gpu.set( 1, 1, string.format( "%-15s  %-5s %-5s", text, percentText, onOff ) )

    if rateOfChange > 0 then 
        gpu.setForeground(0x00FF00) 
    elseif rateOfChange < 0 then 
        gpu.setForeground(0xFF0000)
    else 
        gpu.setForeground(0xFFFFFF)
    end
    gpu.set(1,3, changeText)
    os.sleep(0.2)
end