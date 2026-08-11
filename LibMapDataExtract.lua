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
	print("GatherMate2: Initializing map data...")
	-- Store current map state
	local origContinent = GetCurrentMapContinent()
	local origZone = GetCurrentMapZone()
	
	local count = 0
	-- Iterate through all possible map IDs for Classic WoW
	for i=1, 1000 do
		if SetMapByID(i) then
			local mapFileName, textureHeight, textureWidth, isMicroDungeon, microDungeonMapName = GetMapInfo()
			if mapFileName and not isMicroDungeon then
				nametoid[mapFileName] = i
				
				-- Get localized zone name using GetRealZoneText after setting the map
				local zoneName = GetRealZoneText()
				if zoneName and zoneName ~= "" then
					mapToLocal[mapFileName] = zoneName
				else
					mapToLocal[mapFileName] = mapFileName
				end
				
				-- For zone dimensions, we need to use texture dimensions directly
				-- In Classic WoW, these represent the actual playable area
				-- Store them in a format Astrolabe can use (width, height in game units)
				if textureHeight and textureWidth and textureHeight > 0 and textureWidth > 0 then
					-- The texture dimensions ARE the zone dimensions in Classic
					-- They represent the size of the playable area
					idtodxdy[i] = { [1] = textureWidth, [2] = textureHeight }
					count = count + 1
				else
					-- Fallback: use reasonable defaults
					idtodxdy[i] = { [1] = 4480, [2] = 3040 }  -- Average zone size
				end
			end -- end if mapFileName
		end -- end if SetMapByID
	end -- end for loop
	
	print(string.format("GatherMate2: Initialized %d zones", count))
	
	-- Restore original map state
	if origContinent and origZone and origContinent > 0 then
		SetMapZoom(origContinent, origZone)
	else
		-- If we can't restore, just set to current zone
		SetMapToCurrentZone()
	end
end -- end function InitializeMapData

-- Initialize map data when addon loads
InitializeMapData()

function GatherMate.mapData:MapLocalize(mapfile)
	if mapfile == WORLDMAP_COSMIC_ID then return WORLD_MAP end
	if type(mapfile) == "number" then
		-- Fallback: try to get map info by setting the map
		local origContinent = GetCurrentMapContinent()
		local origZone = GetCurrentMapZone()
		if SetMapByID(mapfile) then
			local zoneName = GetRealZoneText()
			local mapFileName = GetMapInfo()
			-- Restore original map state
			if origContinent and origZone then
				SetMapZoom(origContinent, origZone)
			end
			if zoneName and zoneName ~= "" then
				return zoneName
			elseif mapFileName then
				return mapFileName
			else
				return tostring(mapfile)
			end
		end
		-- Restore original map state if SetMapByID failed
		if origContinent and origZone then
			SetMapZoom(origContinent, origZone)
		end
		return tostring(mapfile)
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
		local width, height = idtodxdy[id][1], idtodxdy[id][2]
		print(string.format("GatherMate2: MapArea(%s) returning %s, %s", tostring(id), tostring(width), tostring(height)))
		return width, height
	else
		print(string.format("GatherMate2: MapArea(%s) - no data, returning 0, 0", tostring(id)))
		return 0, 0
	end
end
