include "MapEnums"
include "MapUtilities"
include "MountainsCliffs"
include "RiversLakes"
include "FeatureGenerator"
include "TerrainGenerator"
include "NaturalWonderGenerator"
include "ResourceGenerator"
include "AssignStartingPlots"

local g_iW, g_iH;
local g_iFlag = {};
local g_continentsFrac = nil;

function ApplyTerrain(plotTypes, terrainTypes)
    for i = 0, (g_iW * g_iH) - 1, 1 do
        pPlot = Map.GetPlotByIndex(i);
        if(plotTypes[i] == g_PLOT_TYPE_HILLS) then
            terrainTypes[i] = terrainTypes[i] + 1;
        end
        TerrainBuilder.SetTerrainType(pPlot, terrainTypes[i]);
    end
end

function GenerateMap()
    print("Generating Mirror Map");
    local pPlot;

    g_iW, g_iH = Map.GetGridSize();
    g_iFlags = TerrainBuilder.GetFractalFlags();
    local temperature = MapConfiguration.GetValue("temperature");
    if temperature == 4 then
        temperature = 1 + TerrainBuilder.GetRandomNumber(3, "Random Tempture- Lua");
    end

    plotTypes = GeneratePlotTypes();
    terrainTypes = GenerateTerrainTypes(plotTypes, g_iW, g_iH, g_iFlags, false, temperature);

    ApplyTerrain(plotTypes, terrainTypes);

    AreaBuilder.Recalculate();
    local biggest_area = Areas.FindBiggestArea(false);

    AddRivers();

    local numLargeLakes = GameInfo.Maps[Map.GetMapSize()].;
    AddLakes(numLargeLakes);

    AddFeatures();

    AddCliffs(plotTypes, terrainTypes);

    local args = {
        numberToPlace = GameInfo.Maps[Map.GetMapSize()].NumNaturalWonders,
    };

    AreaBuilder.Recalculate();
    TerrainBuilder.AnalyzeChokepoints();
    TerrainBuilder.StampContinents();

    resourcesConfig = MapConfiguration.GetValue("resources");
    local args = {
        resources = resourcesConfig;
    };
    local resGen = ResourceGenerator.Create(args);

    local startConfig = MapConfiguration.GetValue("start");

    local args = {
        MIN_MAJOR_CIV_FERTILITY = 150,
        MIN_MINOR_CIV_FERTILITY = 50,
        MIN_BARBARIAN_FERTILITY = 1,
        START_MIN_Y = 15,
        START_MAX_Y = 15,
        START_CONFIG = startConfig,
    };
    local start_plot_database = AssignStartingPlots.Create(args);

    local GoodyGen = AddGoodies(g_iW, g_iH);
end

function GeneratePlotTypes()
    local plotTypes = {};

    local sea_level_low = 57;
    local sea_level_normal = 62;
    local sea_level_high = 66;
    local world_age_old = 2;
    local world_age_normal = 3;
    local world_age_new = 5;

    local extra_mountains = 0;
    local grain_amount = 3;
    local adjust_plates = 1.0;
    local shift_plot_types = true;
    local tectonic_islands = false;
    local hills_ridge_flags = g_iFlags;
    local peaks_ridge_flags = g_iFlags;
    local has_center_rift = true;
    local water_percent;

    local world_age = MapConfiguration.GetValue("world_age");
    if(world_age == 1) then
        world_age = world_age_new;
    elseif(world_age == 2) then
        world_age = world_age_normal;
    elseif(world_age == 3) then
        world_age = world_age_old;
    else
        world_age = 2 + TerrainBuilder.GetRandomNumber(4, "Random World Age - Lua");
    end

    local sea_level = MapConfiguration.GetValue("sea_level");
    if sea_level == 1 then -- Low Sea Level
        water_percent = sea_level_low
    elseif sea_level == 2 then -- Normal Sea Level
        water_percent =sea_level_normal
    elseif sea_level == 3 then -- High Sea Level
        water_percent = sea_level_high
    else
        water_percent = TerrainBuilder.GetRandomNumber(sea_level_high - sea_level_low, "Random Sea Level - Lua") + sea_level_low  + 1;
    end
