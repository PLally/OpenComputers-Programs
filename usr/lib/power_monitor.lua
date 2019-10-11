local Monitor = {}
Monitor.__index = Monitor
local export = {}

-- Monitor object
function Monitor:new(component)
    local f = {}
    f.component = component
    f.energy = 0 

    setmetatable(f, self) 

    return f
end

function Monitor:getEnergy(units)
    local energy = self.component.getEnergy()
    if type(energy) ~= "number" then
        return print(energy)
    end
    return energy or 0
end

function Monitor:getMaxEnergy(units)
    local energy = self.component.getMaxEnergy()
    if type(energy) ~= "number" then
        return print(energy)
    end
    return energy or 0
end

function Monitor:getOutput(energy) 
    local energy = self.component.getOutput()
    if type(energy) ~= "number" then
        return print(energy)
    end
    return energy or 0
end

function Monitor:getInput(energy) 
    local energy = self.component.getInput()
    if type(energy) ~= "number" then
        return print(energy)
    end
    return energy or 0
end
function Monitor:registerEvent(identifier, callback) 
    self.events[identifier] = {
        callback = callback
    }
end

local prettyPrintStrings = {
    long = {
        "%.3f thousand",
        "%.3f million",
        "%.3f billion",
        "%.3f trillion"
   
    },
    short = {
        "%.3fK",
        "%.3fM",
        "%.3fG",
        "%.3fT"
    }
}
function Monitor.prettyPrint(number, mode)
    mode = mode or "long"
    number = number*0.4 -- convert to rf

    local millions = number/1e6
    local thousands = number/1e3
    local billions = number/1e9
    local trillions = number/1e12
    ---  quadrillions?
    local fmtStrings = prettyPrintStrings[mode]
    if trillions >= 1 then
        return string.format(fmtStrings[4], trillions)
    elseif billions >= 1 then
        return string.format(fmtStrings[3], billions)
    elseif millions >= 1 then
        return string.format(fmtStrings[2], millions)
    elseif thousands >= 1 then
        return string.format(fmtStrings[1], thousands)
    end
    return string.format("%.3f")
end

function Monitor:getPercentFull() 
    return ( self.component:getEnergy() / self.component.getMaxEnergy() ) * 100
end
export.Monitor = Monitor
return export