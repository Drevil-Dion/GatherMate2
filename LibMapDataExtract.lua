--[[
A trimmed down version of LibMapData-1.0 including only the parts that Gathermate2 uses
Classic WoW 3.3.5 Compatible Version
]]

local GatherMate = LibStub("AceAddon-3.0"):GetAddon("GatherMate2")

GatherMate.mapData = {}

local nametoid = {}
local idtodxdy = {}
local mapToLocal = {}

-- Classic WoW 3.3.5 compatible map initialization
-- Build list of areaIDs using Classic API
local function InitializeMapData()
	-- Store current map state
	local origContinent = GetCurrentMapContinent()
	local origZone = GetCurrentMapZone()
	
	-- Iterate through all possible map IDs for Classic WoW
	for i=1, 1000 do
		if SetMapByID(i) then
			local mapFileName, textureHeight, textureWidth = GetMapInfo()
			if mapFileName then
				nametoid[mapFileName] = i
				
				-- Get localized zone name
				local zoneName = GetMapNameByID(i)
				if zoneName and zoneName ~= "" then
					mapToLocal[mapFileName] = zoneName
				else
					mapToLocal[mapFileName] = mapFileName
				end
				
				-- Calculate map dimensions (width, height in yards)
				-- Classic maps use textureHeight and textureWidth
				if textureHeight and textureWidth then
					idtodxdy[i] = { [1] = textureWidth or 0, [2] = textureHeight or 0 }
				else
					idtodxdy[i] = { [1] = 0, [2] = 0 }
				end
			end
		end
	end
	
	-- Restore original map state
	if origContinent and origZone then
		SetMapZoom(origContinent, origZone)
	end
end

-- Initialize map data when addon loads
InitializeMapData()

function GatherMate.mapData:MapLocalize(mapfile)
	if mapfile == WORLDMAP_COSMIC_ID then return WORLD_MAP end
	if type(mapfile) == "number" then
		local zoneName = GetMapNameByID(mapfile)
		if zoneName and zoneName ~= "" then
			return zoneName
		else
			-- Fallback: try to get map info
			local origContinent = GetCurrentMapContinent()
			local origZone = GetCurrentMapZone()
			if SetMapByID(mapfile) then
				local mapFileName = GetMapInfo()
				if origContinent and origZone then
					SetMapZoom(origContinent, origZone)
				end
				return mapFileName or tostring(mapfile)
			end
			if origContinent and origZone then
				SetMapZoom(origContinent, origZone)
			end
			return tostring(mapfile)
		end
	end
    return mapToLocal[mapfile] or mapfile
end

function GatherMate.mapData:EncodeLoc(x,y,level)
	local level = level or 0
	if x > 0.9999 then
		x = 0.9999
	end
	if y > 0.9999 then
		y = 0.9999
	end
	return floor( x * 10000 + 0.5 ) * 1000000 + floor( y * 10000  + 0.5 ) * 100 + level
end

function GatherMate.mapData:DecodeLoc(id)
	return floor(id/1000000)/10000, floor(id % 1000000 / 100)/10000, id % 100
end

function GatherMate.mapData:GetAllMapIDs(id)
	return nametoid
end

function GatherMate.mapData:MapAreaId(mapFile)
	return nametoid[mapFile]
end

function GatherMate.mapData:MapArea(id)
	if type(id) == "string" then
		id = nametoid[id]
	end
    if idtodxdy[id] then
    	return idtodxdy[id][1], idtodxdy[id][2]
    else
        return 0, 0
    end
end
