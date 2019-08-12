-- requires tier a data card
-- TODO support entire png spec, things such as PLTE color type and interlacing
--constants
local PNG_SIGNATURE = {137, 80, 78, 71, 13, 10, 26, 10}

local COLOR_TYPE_SIZES = {[2] = 3, -- RGB
                          --[3] = 1, -- PLTE
                          [6] = 4, -- RGBA
                          [0] = 1, -- GRAY
                          [4] = 2} -- GRAYA

--functions
local data = require("data")
local inflate = data.inflate
local abs = math.abs

local args = {...}
local file = io.open(args[1], "rb")

print("Decoding "..args[1]) 

local function isPng(file) 
    for k, v in pairs(PNG_SIGNATURE) do
        local b = file:read(1)
        if v ~= string.byte(b) then return false end
    end
    return true
end

local function decodePng(file) 
    if not isPng(file) then print("NOT A PNG"); return end
    readChunk(file)
end

function readBytes(stream, n)
    local b = 0
    for i=1, n, 1 do
        b = b * 256 + file:read(1):byte()
    end
    return b
end


local function readChunk(png, file)
    local length = readBytes(file, 4)
    local chunkType = file:read(4)
    if chunkType == "IHDR" then
        png.ihdr  = {
            width =              readBytes(file, 4),
            height =             readBytes(file, 4),
            bit_depth =          readBytes(file, 1),
            color_type =         readBytes(file, 1),
            compression_method = readBytes(file, 1),
            filter_method =      readBytes(file, 1),
            interlace_method =   readBytes(file, 1)
        }
    elseif chunkType == "IDAT" then
        png.idat = (png.idat or "") .. file:read(length)
    else
        file:read(length) -- skip unknown chunk data
    end
    file:read(4) -- skip crc because im lazy
    return chunkType
end


local function getBytesPerPixel(colorType, bitDepth)
    return math.floor(bitDepth/8) * COLOR_TYPE_SIZES[colorType]

end
local function paethPredictor(a, b, c)
    local p = a + b - c
    local pa = abs(p-a)
    local pb = abs(p-b)
    local pc = abs(p-c)

    if pa <= pb and pa <= pc then return a end
    if pb <= pc then return b end
    return c
end

local gpu = require("component").gpu
local function decodePng(file)
    if not isPng(file) then print("ERROR: Invalid png signature"); return end
    local png = {}
    local chunkType
    while chunkType ~= "IEND" do
        chunkType = readChunk(png, file)
    end
    
    local data, err  = inflate(png.idat)
    if err ~= nil then
      print("ERROR inflating data: "..err)
      return
    end

    local bpp = getBytesPerPixel(png.ihdr.color_type, png.ihdr.bit_depth)
    local height = png.ihdr.height
    local width = png.ihdr.width

    local colorType = png.ihdr.color_type
    local bitDepth = png.ihdr.bitDepth

    local i = 1 -- currentByte

    local previousScanline = {}
    local currentScanline = {}

    for y = 1, height do
        
        local filterType = string.byte(data, i)
        i = i + 1
        local pos = 1 -- current byte in scanline
        local pixelBytes = {}
        for x = 1, width do
            if filterType == 0 then
                for j=1, bpp do
                  
                    local byte = string.byte(data, i)
                    
                    currentScanline[pos] = byte
                    pixelBytes[j]  = byte
                    i = i + 1
                    pos = pos + 1
                end
            elseif filterType == 1 then -- Sub(x) + Raw(x-bpp)
                for j=1, bpp do
                    local byte = ( string.byte(data, i) + (currentScanline[pos - bpp] or 0) ) % 256
                    currentScanline[pos] = byte
                    pixelBytes[j]  = byte
                    i = i + 1
                    pos = pos + 1
                end
            elseif filterType == 2 then  -- Up(x) + Prior(x)
                for j=1, bpp do
                    local byte = ( string.byte(data, i) + (previousScanline[pos] or 0)  ) % 256
        
                    currentScanline[pos] = byte
                    pixelBytes[j]  = byte
                    i = i + 1
                    pos = pos + 1
                end
            elseif filterType == 3 then  -- Average(x) + floor((Raw(x-bpp)+Prior(x))/2)
                for j=1, bpp do
                    local left = currentScanline[pos-bpp] or 0
                    local above = previousScanline[pos] or 0

                    local byte = ( string.byte(data, i) + math.floor( (left + above ) / 2 ) ) % 256
                    currentScanline[pos] = byte
                    pixelBytes[j] = byte
                    i = i + 1
                    pos = pos + 1
                end
            elseif filterType == 4 then -- Paeth(x) = Raw(x) - PaethPredictor(Raw(x-bpp), Prior(x), Prior(x-bpp))
                for j=1, bpp do
                    local left = currentScanline[pos-bpp] or 0
                    local above = previousScanline[pos] or 0
                    local aboveLeft = previousScanline[pos-bpp] or 0
                    
                    local byte = ( string.byte(data, i) + paethPredictor(left, above, aboveLeft) ) % 256
              
                    currentScanline[pos] = byte
                    pixelBytes[j] = byte
                    i = i + 1
                    pos = pos + 1
                end
            end
            if bitDepth == 16 then
                for i=2, bpp, 2 do
                    pixelBytes[i/2] = ( (pixelBytes[i-1] <<8) + pixelBytes[i] ) / 0xFF
                end
            end

            local pixel
            if colorType == 2 or colorType == 6 then
                local r = pixelBytes[1] or 0
                local g = pixelBytes[2] or 0
                local b = pixelBytes[3] or 0
                pixel = (r<<16) + (g<<8) + b
            elseif colorType == 0 or colorType == 4 then
                local c = pixelBytes[1]
                pixel = (c<<16)+(c<<8)+c
            end

            gpu.setBackground(pixel)
            gpu.set(x,y+1," ")
        end
        previousScanline = currentScanline
        currentScanline = {}
    end
end
decodePng(file)
os.sleep(30)
