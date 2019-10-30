local key = "super secret key"
local event = require("event")
local component=require("component")

local magDoors = {
  ["magdoor address"] = "door controller address"
}

local openDoors = {
    
}

local function checkOpenDoors() 
  for addr, openedAt in pairs(openDoors) do
    local door = component.proxy(addr)
    local timeOpen = os.time()*1000/60/60/20 - openedAt

    if door and timeOpen > 5 then
      door.close(key)
    end 
  end

end

function start()
  for addr, name in component.list("os_doorcontroller") do
     local door = component.proxy(addr)
     door.setPassword("", key)
  end

  event.listen("magData", function(eventName, uuid, playerName, data)

     local addr = magDoors[uuid]
     
     if not addr then return end
     local door = component.proxy(addr)
     
     if not door or not door.toggle then return end
     local isOpen = door.isOpen()[1]
     
     if isOpen then 
        openDoors[addr] = nil
     else
        openDoors[addr] = os.time()*1000/60/60/20
     end
     
     door.toggle(data)
  
  end)
  
  event.timer(1, checkOpenDoors, math.huge)

end
