local Monitor = {}
local Monitor.__index = Monitor
local export = {}

-- Monitor object
function Monitor:new(component)
    f.component = component
    f.energy = 0 

    setmetatable(f, self) 

    return f
end

function Monitor:getEnergy(units)
    return self.component.getEnergy()
end

function Monitor:getMaxEnergy(units)
    return self.component.getMaxEnergy()
end

function Monitor:registerEvent(identifier, callback) 
    self.events[identifier] = {
        callback = callback
    }
end

function Monitor.prettyPrint(number)
    local millions = number/1e6
    local thousands = number/1e3
    local billions = number/1e9
    local trillions = number/1e12
    ---  quadrillions?
    if trillions >= 1 then
        return string.format("%v trillion", trillions)
    elseif billions >= 1 then
        return string.format("%v billions", billions)
    elseif millions >= 1 then
        return string.format("%v millions", millions)
    elseif thousands >= 1 then
        return string.format("%v thousands", thousands)
    end
end

function Monitor:getPercentFull() 
    return induction_matrix:getEnergy() / induction_matrix.getMaxEnergy()
end
export.Monitor = Monitor
return Export