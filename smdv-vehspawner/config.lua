Config = Config or {}

-- =====================================
-- VEHICLE LIST TEMPLATE
-- =====================================
Config.Vehicles = {

    -- ===== DEPARTMENT NAME =====
    {
        name = "DISPLAY NAME",
        vehicle = "spawncode_here",
        allowedStations = { "Station Name" } -- optional
    },

    -- Add more vehicles following this format:
    -- {
    --     name = "",
    --     vehicle = "",
    --     allowedStations = { "Station Name" }
    -- },
}

-- =====================================
-- STATION TEMPLATE
-- =====================================
Config.Stations = {
    {
        name = "Station Name",
        pedModel = `ped_model_here`,
        ped = { x = 0.0, y = 0.0, z = 0.0, w = 0.0 },

        spawns = {
            { x = 0.0, y = 0.0, z = 0.0, w = 0.0 },
            -- add more spawn points as needed
        }
    },

    -- Add more stations following this format:
    -- {
    --     name = "",
    --     pedModel = ``,
    --     ped = { x = 0.0, y = 0.0, z = 0.0, w = 0.0 },
    --     spawns = {
    --         { x = 0.0, y = 0.0, z = 0.0, w = 0.0 }
    --     }
    -- },
}