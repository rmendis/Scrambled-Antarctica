-- Antarctica_XP2
-- Author: blkbutterfly74
-- DateCreated: 12/21/2020 8:25:35 AM
-- Creates a Standard map shaped like real-world Greenland 
-- based off Scrambled Africa map scripts
-- Thanks to Firaxis
-----------------------------------------------------------------------------

include "MapEnums"
include "MapUtilities"
include "MountainsCliffs"
include "RiversLakes"
include "FeatureGenerator"
include "TerrainGenerator"
include "NaturalWonderGenerator"
include "ResourceGenerator"
include "CoastalLowlands"
include "AssignStartingPlots"

local g_iW, g_iH;
local g_iFlags = {};
local g_continentsFrac = nil;
local g_iNumTotalLandTiles = 0; 
local g_CenterX = 34;
local g_CenterY = 30;
local featuregen = nil;

--g_FEATURE_LYSEFJORDEN				= GetGameInfoIndex("Features", "FEATURE_LYSEFJORDEN");

-------------------------------------------------------------------------------
function GenerateMap()
	print("Generating Antarctica Map");
	local pPlot;

	-- Set globals
	g_iW, g_iH = Map.GetGridSize();
	g_iFlags = TerrainBuilder.GetFractalFlags();
	local temperature = 0;

	--	local world_age
	local world_age_new = 5;
	local world_age_normal = 3;
	local world_age_old = 2;

	local world_age = MapConfiguration.GetValue("world_age");
	if (world_age == 1) then
		world_age = world_age_new;
	elseif (world_age == 3) then
		world_age = world_age_old;
	else
		world_age = world_age_normal;	-- default
	end
	
	plotTypes = GeneratePlotTypes(world_age);
	terrainTypes = GenerateTerrainTypesArctic(plotTypes, g_iW, g_iH, g_iFlags, true);
	ApplyBaseTerrain(plotTypes, terrainTypes, g_iW, g_iH);

	AreaBuilder.Recalculate();
	--[[ blackbutterfly74 - Why this additional AnalyzeChockepoint()? Commenting out for now:
	TerrainBuilder.AnalyzeChokepoints(); --]]
	TerrainBuilder.StampContinents();

	local iContinentBoundaryPlots = GetContinentBoundaryPlotCount(g_iW, g_iH);
	local biggest_area = Areas.FindBiggestArea(false);
	print("After Adding Hills: ", biggest_area:GetPlotCount());
	AddTerrainFromContinents(plotTypes, terrainTypes, world_age, g_iW, g_iH, iContinentBoundaryPlots);

	AreaBuilder.Recalculate();

	-- Lakes before rivers to allow them to act as sources
	AddLakes();

	-- River generation is affected by plot types, originating from highlands and preferring to traverse lowlands.
	AddRivers();

	AddFeatures();

	TerrainBuilder.AnalyzeChokepoints();
	
	print("Adding cliffs");
	AddCliffs(plotTypes, terrainTypes);
	
	local args = {
		numberToPlace = (GameInfo.Maps[Map.GetMapSize()].NumNaturalWonders - 2),
		--Invalid = {g_FEATURE_DEAD_SEA, g_FEATURE_LYSEFJORDEN},
	};

	local nwGen = NaturalWonderGenerator.Create(args);
	
	AddFeaturesFromContinents();
	MarkCoastalLowlands();
	
	local resourcesConfig = MapConfiguration.GetValue("resources");
	local args = {
		resources = resourcesConfig,
		iWaterLux = 4,
	}
	local resGen = ResourceGenerator.Create(args);

	print("Creating start plot database.");
	-- START_MIN_Y and START_MAX_Y is the percent of the map ignored for major civs' starting positions.
	local startConfig = MapConfiguration.GetValue("start");-- Get the start config
	local args = {
		MIN_MAJOR_CIV_FERTILITY = 175,
		MIN_MINOR_CIV_FERTILITY = 50, 
		MIN_BARBARIAN_FERTILITY = 1,
		START_MIN_Y = 15,
		START_MAX_Y = 15,
		START_CONFIG = startConfig,
		LAND = true,
	};
	local start_plot_database = AssignStartingPlots.Create(args)

	local GoodyGen = AddGoodies(g_iW, g_iH);
end

-- Input a Hash; Export width, height, and wrapX
function GetMapInitData(MapSize)
	local Width = 72;
	local Height = 61;
	local WrapX = false;
	return {Width = Width, Height = Height, WrapX = WrapX,}
end
-------------------------------------------------------------------------------
function GeneratePlotTypes(world_age)
	print("Generating Plot Types");
	local plotTypes = {};

	-- Start with it all as water
	for x = 0, g_iW - 1 do
		for y = 0, g_iH - 1 do
			local i = y * g_iW + x;
			local pPlot = Map.GetPlotByIndex(i);
			plotTypes[i] = g_PLOT_TYPE_OCEAN;
			TerrainBuilder.SetTerrainType(pPlot, g_TERRAIN_TYPE_OCEAN);
		end
	end

	-- Each land strip is defined by: Y, X Start, X End
	local xOffset = 0;
	local yOffset = 1;
	local landStrips = {
		{2, 31, 32},
		{2, 36, 43},
		{3, 30, 44},
		{4, 30, 46},
		{4, 52, 52},
		{5, 30, 52},
		{6, 29, 52},
		{7, 28, 58},
		{8, 28, 60},
		{8, 62, 62},
		{9, 2, 2},
		{9, 28, 63},
		{10, 2, 2},
		{10, 28, 64},
		{11, 2, 2},
		{11, 27, 64},
		{12, 2, 2},
		{12, 26, 63},
		{13, 2, 4},
		{13, 25, 63},
		{14, 2, 4},
		{14, 25, 63},
		{15, 3, 4},
		{15, 25, 64},
		{16, 4, 4},
		{16, 7, 7},
		{16, 25, 64},
		{17, 4, 11},
		{17, 25, 65},
		{18, 6, 13},
		{18, 28, 65},
		{19, 7, 14},
		{19, 27, 64},
		{20, 10, 15},
		{20, 27, 61},
		{21, 12, 16},
		{21, 27, 59},
		{22, 12, 16},
		{22, 27, 63},
		{23, 12, 16},
		{23, 26, 64},
		{24, 12, 16},
		{24, 26, 66},
		{25, 11, 16},
		{25, 18, 18},
		{25, 23, 67},
		{26, 11, 18},
		{26, 22, 67},
		{27, 12, 68},
		{28, 11, 68},
		{29, 11, 69},
		{30, 10, 69},
		{31, 11, 69},
		{32, 11, 69},
		{33, 11, 69},
		{34, 11, 69},
		{35, 11, 12},
		{35, 14, 69},
		{36, 14, 69},
		{37, 15, 69},
		{38, 14, 32},
		{38, 34, 69},
		{39, 15, 32},
		{39, 35, 69},
		{40, 14, 30},
		{40, 33, 33},
		{40, 37, 68},
		{41, 15, 28},
		{41, 38, 67},
		{42, 16, 28},
		{42, 39, 67},
		{43, 17, 27},
		{43, 39, 68},
		{44, 17, 27},
		{44, 40, 67},
		{45, 18, 28},
		{45, 40, 66},
		{46, 19, 28},
		{46, 39, 65},
		{47, 21, 24},
		{47, 27, 28},
		{47, 39, 64},
		{48, 40, 63},
		{49, 41, 63},
		{50, 41, 63},
		{51, 42, 62},
		{52, 41, 61},
		{53, 41, 61},
		{54, 40, 60},
		{55, 39, 59},
		{56, 39, 58},
		{57, 40, 56},
		{58, 45, 50}};  

		
	for i, v in ipairs(landStrips) do
		local y = g_iH - (v[1] + yOffset);		--inverted
		local xStart = v[2] + xOffset;
		local xEnd = v[3] + xOffset; 
		for x = xStart, xEnd do
			local i = y * g_iW + x;
			local pPlot = Map.GetPlotByIndex(i);
			plotTypes[i] = g_PLOT_TYPE_LAND;
			TerrainBuilder.SetTerrainType(pPlot, g_TERRAIN_TYPE_SNOW);  -- temporary setting so can calculate areas
			g_iNumTotalLandTiles = g_iNumTotalLandTiles + 1;
		end
	end
		
	AreaBuilder.Recalculate();
	
	local args = {};
	args.world_age = world_age;
	args.iW = g_iW;
	args.iH = g_iH
	args.iFlags = g_iFlags;
	args.blendRidge = 10;
	args.blendFract = 1;
	args.extra_mountains = 4;
	plotTypes = ApplyTectonics(args, plotTypes);

	return plotTypes;
end

function InitFractal(args)

	if(args == nil) then args = {}; end

	local continent_grain = args.continent_grain or 2;
	local rift_grain = args.rift_grain or -1; -- Default no rifts. Set grain to between 1 and 3 to add rifts. - Bob
	local invert_heights = args.invert_heights or false;
	local polar = args.polar or true;
	local ridge_flags = args.ridge_flags or g_iFlags;

	local fracFlags = {};
	
	if(invert_heights) then
		fracFlags.FRAC_INVERT_HEIGHTS = true;
	end
	
	if(polar) then
		fracFlags.FRAC_POLAR = true;
	end
	
	if(rift_grain > 0 and rift_grain < 4) then
		local riftsFrac = Fractal.Create(g_iW, g_iH, rift_grain, {}, 6, 5);
		g_continentsFrac = Fractal.CreateRifts(g_iW, g_iH, continent_grain, fracFlags, riftsFrac, 6, 5);
	else
		g_continentsFrac = Fractal.Create(g_iW, g_iH, continent_grain, fracFlags, 6, 5);	
	end

	-- Use Brian's tectonics method to weave ridgelines in to the continental fractal.
	-- Without fractal variation, the tectonics come out too regular.
	--
	--[[ "The principle of the RidgeBuilder code is a modified Voronoi diagram. I 
	added some minor randomness and the slope might be a little tricky. It was 
	intended as a 'whole world' modifier to the fractal class. You can modify 
	the number of plates, but that is about it." ]]-- Brian Wade - May 23, 2009
	--
	local MapSizeTypes = {};
	for row in GameInfo.Maps() do
		MapSizeTypes[row.MapSizeType] = row.PlateValue;
	end
	local sizekey = Map.GetMapSize();

	local numPlates = MapSizeTypes[sizekey] or 4

	-- Blend a bit of ridge into the fractal.
	-- This will do things like roughen the coastlines and build inland seas. - Brian

	g_continentsFrac:BuildRidges(numPlates, {}, 1, 2);
end

function AddFeatures()
	print("Adding Features");

	-- Get Rainfall setting input by user.
	local rainfall = MapConfiguration.GetValue("rainfall");
	if rainfall == 4 then
		rainfall = 1 + TerrainBuilder.GetRandomNumber(3, "Random Rainfall - Lua");
	end
	
	local args = {rainfall = rainfall, iReefPercent = 0}
	featuregen = FeatureGenerator.Create(args);

	featuregen:AddFeatures(true, true);  --second parameter is whether or not rivers start inland);

	-- remove inner forest and outer ice
	for iX = 0, g_iW - 1 do
		for iY = 0, g_iH - 1 do
			local index = (iY * g_iW) + iX;
			local plot = Map.GetPlot(iX, iY);
			local iDistanceFromCenter = Map.GetPlotDistance (iX, iY, g_CenterX, g_CenterY);

			if (plot:GetFeatureType() == g_FEATURE_FOREST) then
				-- same as Australia floodplain logic
				if (TerrainBuilder.GetRandomNumber(150, "Resource Placement Score Adjust") >= iDistanceFromCenter) then
					TerrainBuilder.SetFeatureType(plot, -1);
				end
			end
		end
	end
end
------------------------------------------------------------------------------
function GenerateTerrainTypesArctic(plotTypes, iW, iH, iFlags, bNoCoastalMountains)
	print("Generating Terrain Types");
	local terrainTypes = {};

	local fracXExp = -1;
	local fracYExp = -1;
	local grain_amount = 3;

	antarctica = Fractal.Create(iW, iH, 
									grain_amount, iFlags, 
									fracXExp, fracYExp);
									
	for iX = 0, iW - 1 do
		for iY = 0, iH - 1 do
			local index = (iY * iW) + iX;
			if (plotTypes[index] == g_PLOT_TYPE_OCEAN) then
				if (IsAdjacentToLand(plotTypes, iX, iY)) then
					terrainTypes[index] = g_TERRAIN_TYPE_COAST;
				else
					terrainTypes[index] = g_TERRAIN_TYPE_OCEAN;
				end
			end
		end
	end

	if (bNoCoastalMountains == true) then
		plotTypes = RemoveCoastalMountains(plotTypes, terrainTypes);
	end

	local iTundraTop = antarctica:GetHeight(55);

	for iX = 0, iW - 1 do
		for iY = 0, iH - 1 do
			local index = (iY * iW) + iX;

			local iDistanceFromCenter = Map.GetPlotDistance (iX, iY, g_CenterX, g_CenterY);
			local iTundraBottom = antarctica:GetHeight(50 - iDistanceFromCenter/iW * 100);

			local tundraVal = antarctica:GetHeight(iX, iY);

			if (plotTypes[index] == g_PLOT_TYPE_MOUNTAIN) then
				if ((tundraVal >= iTundraBottom) and (tundraVal <= iTundraTop)) then
					terrainTypes[index] = g_TERRAIN_TYPE_TUNDRA_MOUNTAIN;
				else terrainTypes[index] = g_TERRAIN_TYPE_SNOW_MOUNTAIN;
				end
			elseif (plotTypes[index] ~= g_PLOT_TYPE_OCEAN) then
				if ((tundraVal >= iTundraBottom) and (tundraVal <= iTundraTop)) then
					terrainTypes[index] = g_TERRAIN_TYPE_TUNDRA;
				else terrainTypes[index] = g_TERRAIN_TYPE_SNOW;
				end
			end
		end
	end

	local bExpandCoasts = true;

	if bExpandCoasts == false then
		return
	end

	print("Expanding coasts");
	for iI = 0, 2 do
		local shallowWaterPlots = {};
		for iX = 0, iW - 1 do
			for iY = 0, iH - 1 do
				local index = (iY * iW) + iX;
				if (terrainTypes[index] == g_TERRAIN_TYPE_OCEAN) then
					-- Chance for each eligible plot to become an expansion is 1 / iExpansionDiceroll.
					-- Default is two passes at 1/4 chance per eligible plot on each pass.
					if (IsAdjacentToShallowWater(terrainTypes, iX, iY) and TerrainBuilder.GetRandomNumber(4, "add shallows") == 0) then
						table.insert(shallowWaterPlots, index);
					end
				end
			end
		end
		for i, index in ipairs(shallowWaterPlots) do
			terrainTypes[index] = g_TERRAIN_TYPE_COAST;
		end
	end
	
	return terrainTypes; 
end

------------------------------------------------------------------------------
function FeatureGenerator:AddIceToMap()
	local iTargetIceTiles = (self.iGridH * self.iGridW *  (GlobalParameters.ICE_TILES_PERCENT + self.iIceModifiedPercent)) / 100;

	local aPhases = {};
	local iPhases = 0;
	for row in GameInfo.RandomEvents() do
		if (row.EffectOperatorType == "SEA_LEVEL") then
			local kPhaseDetails = {};
			kPhaseDetails.RandomEventEnum = row.Index;
			kPhaseDetails.IceLoss = row.IceLoss;
			table.insert(aPhases, kPhaseDetails);
			iPhases = iPhases + 1;
		end
	end
	
	if (iPhases <= 0) then 
		return;
	end

	------------------------------
	-- PHASE ONE: PERMANENT ICE --
	------------------------------
	local iIceLossThisLevel = aPhases[iPhases].IceLoss;
	local iPermanentIcePercent = 100 - iIceLossThisLevel;
	local iPermanentIceTiles = (iTargetIceTiles * iPermanentIcePercent) / 100;

	print ("Permanent Ice Tiles: " .. tostring(iPermanentIceTiles));

	-- Count top/bottom map tiles
	local iWaterTilesOnEdges = 0;

	--   On bottom
	for x = 0, self.iGridW - 1, 1 do
		y = 0;
		local i = y * self.iGridW + x;
		local plot = Map.GetPlotByIndex(i);
		if (plot ~= nil) then
			if(TerrainBuilder.CanHaveFeature(plot, g_FEATURE_ICE) == true and IsAdjacentToLandPlot(x, y) == false) then
				iWaterTilesOnEdges = iWaterTilesOnEdges + 1;
			end
		end
	end

	--   On top
	for x = 0, self.iGridW - 1, 1 do
		local y = self.iGridH - 1;
		local i = y * self.iGridW + x;
		local plot = Map.GetPlotByIndex(i);
		if (plot ~= nil) then
			if(TerrainBuilder.CanHaveFeature(plot, g_FEATURE_ICE) == true and IsAdjacentToLandPlot(x, y) == false) then
				iWaterTilesOnEdges = iWaterTilesOnEdges + 1;
			end
		end
	end

	if (iWaterTilesOnEdges > 0) then
		local iPercentNeeded = 100 * iPermanentIceTiles / iWaterTilesOnEdges;

		for x = 0, self.iGridW - 1, 1 do
			for y = self.iGridH - 1, 0, -1 do
				local i = y * self.iGridW + x;
				local plot = Map.GetPlotByIndex(i);
				if (plot ~= nil) then
					if(TerrainBuilder.CanHaveFeature(plot, g_FEATURE_ICE) == true and IsAdjacentToLandPlot(x, y) == false) then
						if (TerrainBuilder.GetRandomNumber(100, "Permanent Ice") <= iPercentNeeded) then
							AddIceAtPlot(plot, x, y, -1); 
						end
					end
				end
			end
		end
	end

	---------------------------------------
	-- PHASE TWO: ICE THAT CAN DISAPPEAR --
	---------------------------------------
	if (iPhases > 1) then
		for iPhaseIndex = iPhases, 1, -1 do
			kPhaseDetails = aPhases[iPhaseIndex];
			local iIcePercentToAdd = 0;
			if (iPhaseIndex == 1) then 
				iIcePercentToAdd = kPhaseDetails.IceLoss;			
			else
				iIcePercentToAdd = kPhaseDetails.IceLoss - aPhases[iPhaseIndex - 1].IceLoss;
			end
			local iIceTilesToAdd = (iTargetIceTiles * iIcePercentToAdd) / 100;

			print ("iPhaseIndex: " .. tostring(iPhaseIndex) .. ", iIceTilesToAdd: " .. tostring(iIceTilesToAdd) .. ", RandomEventEnum: " .. tostring(kPhaseDetails.RandomEventEnum));

			-- Find all plots on map adjacent to already-placed ice
			local aTargetPlots = {};
			for y = 0, self.iGridH - 1, 1 do
				for x = 0, self.iGridW - 1, 1 do
					local i = y * self.iGridW + x;
					local plot = Map.GetPlotByIndex(i);
					if (plot ~= nil) then
						local iAdjacent = TerrainBuilder.GetAdjacentFeatureCount(plot, g_FEATURE_ICE);
						if (TerrainBuilder.CanHaveFeature(plot, g_FEATURE_ICE) == true and iAdjacent > 0) then
							local kPlotDetails = {};
							kPlotDetails.PlotIndex = i;
							kPlotDetails.AdjacentIce = iAdjacent;
							kPlotDetails.AdjacentToLand = IsAdjacentToLandPlot(x, y);
							table.insert(aTargetPlots, kPlotDetails);
						end
					end
				end
			end

			-- Roll die to see which of these get ice
			if (#aTargetPlots > 0) then
				local iPercentNeeded = 100 * iIceTilesToAdd / #aTargetPlots;
				for i, targetPlot in ipairs(aTargetPlots) do
					local iFinalPercentNeeded = iPercentNeeded + 10 * targetPlot.AdjacentIce;
					if (targetPlot.AdjacentToLand == true) then
						iFinalPercentNeeded = iFinalPercentNeeded / 5;
					end
					if (TerrainBuilder.GetRandomNumber(100, "Permanent Ice") <= iFinalPercentNeeded) then
					    local plot = Map.GetPlotByIndex(targetPlot.PlotIndex);
						AddIceAtPlot(plot, plot:GetX(), plot:GetY(), kPhaseDetails.RandomEventEnum); 
					end
				end
			end
		end
	end
end

------------------------------------------------------------------------------
function AddIceAtPlot(plot, iX, iY, iE)
	local iDistanceFromCenter = Map.GetPlotDistance(iX, iY, g_CenterX, g_CenterY);	-- radial
	local iScore = TerrainBuilder.GetRandomNumber(350, "Resource Placement Score Adjust");

	iScore = iScore + ((g_iW/2 - iDistanceFromCenter)/(g_iW/2) * 100);

	if(IsAdjacentToLandPlot(iX,iY) == true) then
		iScore = iScore / 3.5;
	end

	local iAdjacent = TerrainBuilder.GetAdjacentFeatureCount(plot, g_FEATURE_ICE);
	iScore = iScore + 10.0 * iAdjacent;

	if(iScore > 100) then
		TerrainBuilder.SetFeatureType(plot, g_FEATURE_ICE);
		TerrainBuilder.AddIce(plot:GetIndex(), iE);
	end
end

------------------------------------------------------------------------------
function AddFeaturesFromContinents()
	print("Adding Features from Continents");

	featuregen:AddFeaturesFromContinents();
end

------------------------------------------------------------------------------

-- bugfix/patch - remember pythagoras?
function __GetPlotDistance(iX1, iY1, iX0, iY0)
	return math.sqrt((iX1-iX0)^2 + (iY1-iY0)^2);
end

----------------------------------------------------------------------------------
-- LATITUDE LOOKUP
----------------------------------------------------------------------------------
function GetRadialLatitudeAtPlot(variationFrac, iX, iY)
	local iZ = __GetPlotDistance(iX, iY, g_CenterX, g_CenterY);		-- radial distance from center

	-- Terrain bands are governed by latitude (in rad).
	local _lat = 1/2 - iZ/(2*g_iE);

	-- Returns a latitude value between 0.0 (tropical) and 1.0 (polar).
	local lat = 2 * _lat;
	
	-- Adjust latitude using variation fractal, to roughen the border between bands:
	-- lessen the variation at edges
	lat = lat + (128 - variationFrac:GetHeight(iX, iY))/(255.0 * 5.0) * iZ/(2*g_iE);

	-- Limit to the range [0, 1]:
	lat = math.clamp(lat, 0, 1);
	
	return lat;
end