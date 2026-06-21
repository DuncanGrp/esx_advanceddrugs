-- Advanced Drugs Configuration
-- ESX Legacy + ox_inventory compatible

Config = {}

-- Enable/Disable Features
Config.Debug = false
Config.EnablePoliceAlerts = true
Config.EnableAddiction = true
Config.EnableDealerSystem = true
Config.EnableMoneyLaundering = true
Config.EnableTerritory = false

-- Performance Settings
Config.MaxPlantsPerPlayer = 5
Config.MaxManufacturingPerPlayer = 3
Config.UpdateInterval = 100 -- Milliseconds for plant updates
Config.DealerSpawnDistance = 250

-- ===========================
-- DRUG CONFIGURATION
-- ===========================

Config.Drugs = {
    weed = {
        label = 'Weed',
        item = 'weed_bag',
        color = '^2',
        harvestItem = 'weed_plant',
        dryItem = 'weed_dried',
        trimmedItem = 'weed_trimmed',
        processedItem = 'weed_bag',
        
        growth = {
            seedStage = { item = 'weed_seed', minTime = 120, maxTime = 180 },
            sproutStage = { minTime = 300, maxTime = 420 },
            growingStage = { minTime = 600, maxTime = 900 },
            matureStage = { minTime = 600, maxTime = 900 },
            harvestStage = { minTime = 300, maxTime = 420 }
        },
        
        basePricePerGram = 8,
        qualityPrices = {
            poor = 0.5,
            common = 0.8,
            good = 1.2,
            premium = 1.5,
            pure = 2.0
        },
        
        processingLocations = {
            {
                label = 'Weed Processing - Pillbox',
                coords = vector3(429.15, -982.45, 29.41),
                heading = 0.0,
                jobRequired = false,
                minigame = 'simple_skillcheck'
            },
            {
                label = 'Weed Processing - Grapeseed',
                coords = vector3(2318.5, 4726.32, 41.52),
                heading = 0.0,
                jobRequired = false,
                minigame = 'simple_skillcheck'
            }
        },
        
        harvestLocations = {
            {
                label = 'Weed Field - Paleto Bay',
                coords = vector3(-237.89, 6237.45, 31.48),
                heading = 0.0,
                blip = 'blip_weed'
            },
            {
                label = 'Weed Field - Grapeseed',
                coords = vector3(2325.45, 4722.32, 38.52),
                heading = 0.0,
                blip = 'blip_weed'
            }
        },
        
        effects = {
            duration = 120000, -- milliseconds
            movementSpeed = 0.95,
            sprintStamina = 0.85,
            stressReduction = 25
        },
        
        addiction = {
            enabled = true,
            addictionRate = 1.5,
            withdrawalDuration = 3600000, -- 1 hour
            withdrawalIntensity = 0.4
        }
    },

    cocaine = {
        label = 'Cocaine',
        item = 'cocaine_bag',
        color = '^3',
        harvestItem = 'coca_leaf',
        processedItem = 'cocaine_paste',
        refinedItem = 'cocaine_powder',
        packagedItem = 'cocaine_bag',
        
        basePricePerGram = 45,
        qualityPrices = {
            poor = 0.5,
            common = 0.7,
            good = 1.1,
            premium = 1.4,
            pure = 2.0
        },
        
        harvestLocations = {
            {
                label = 'Coca Fields - Alamo Sea',
                coords = vector3(3586.32, 3741.23, 40.5),
                heading = 0.0,
                blip = 'blip_coca'
            },
            {
                label = 'Coca Fields - Desert',
                coords = vector3(2325.12, 5173.45, 52.35),
                heading = 0.0,
                blip = 'blip_coca'
            }
        },
        
        processingLocations = {
            {
                label = 'Cocaine Lab - Downtown',
                coords = vector3(1098.35, -796.45, 57.63),
                heading = 0.0,
                jobRequired = false,
                minigame = 'skill_check',
                difficulty = 0.6
            },
            {
                label = 'Cocaine Lab - Industrial',
                coords = vector3(1120.48, -798.35, 57.63),
                heading = 0.0,
                jobRequired = false,
                minigame = 'skill_check',
                difficulty = 0.6
            }
        },
        
        effects = {
            duration = 180000,
            sprintSpeed = 1.3,
            stamina = 1.25,
            confidence = true
        },
        
        addiction = {
            enabled = true,
            addictionRate = 2.5,
            withdrawalDuration = 5400000, -- 1.5 hours
            withdrawalIntensity = 0.6
        }
    },

    meth = {
        label = 'Methamphetamine',
        item = 'meth_bag',
        color = '^4',
        chemicalItem = 'meth_chemical',
        cookingItem = 'meth_cooking',
        finishedItem = 'meth_bag',
        
        basePricePerGram = 65,
        qualityPrices = {
            poor = 0.4,
            common = 0.6,
            good = 1.0,
            premium = 1.3,
            pure = 1.9
        },
        
        chemicalLocations = {
            {
                label = 'Chemical Store - Mission Row',
                coords = vector3(413.25, -982.45, 29.41),
                heading = 0.0,
                blip = 'blip_chemical'
            }
        },
        
        labLocations = {
            {
                label = 'Meth Lab - Desert',
                coords = vector3(1399.95, 1142.95, 114.59),
                heading = 0.0,
                requiresSetup = true,
                explosionRisk = true
            },
            {
                label = 'Meth Lab - Countryside',
                coords = vector3(986.45, -102.35, 74.12),
                heading = 0.0,
                requiresSetup = true,
                explosionRisk = true
            }
        },
        
        effects = {
            duration = 240000,
            sprintSpeed = 1.5,
            stamina = 1.4,
            crashDuration = 60000
        },
        
        addiction = {
            enabled = true,
            addictionRate = 3.0,
            withdrawalDuration = 7200000, -- 2 hours
            withdrawalIntensity = 0.8
        },
        
        cooking = {
            baseTime = 180000, -- 3 minutes
            temperatureCritical = { min = 80, max = 120 },
            temperatureOptimal = { min = 95, max = 105 },
            explosionChance = 0.15 -- 15% chance of failure
        }
    },

    fentanyl = {
        label = 'Fentanyl',
        item = 'fentanyl_dose',
        color = '^1',
        chemicalItem = 'fentanyl_chemical',
        manufacturingItem = 'fentanyl_manufacturing',
        packagedItem = 'fentanyl_dose',
        
        basePricePerDose = 85,
        qualityPrices = {
            poor = 0.3,
            common = 0.5,
            good = 0.9,
            premium = 1.2,
            pure = 1.8
        },
        
        manufacturingLocations = {
            {
                label = 'Fentanyl Lab - Downtown',
                coords = vector3(1098.45, -792.35, 57.63),
                heading = 0.0,
                requiresSecurity = true,
                policeRisk = 0.8
            }
        },
        
        effects = {
            duration = 300000,
            heavyVisuals = true,
            overdoseRisk = 0.1,
            movementSpeed = 0.7
        },
        
        addiction = {
            enabled = true,
            addictionRate = 4.0,
            withdrawalDuration = 10800000, -- 3 hours
            withdrawalIntensity = 1.0
        }
    },

    xanax = {
        label = 'Xanax',
        item = 'xanax_pill',
        color = '^5',
        ingredientItem = 'xanax_ingredient',
        manufacturingItem = 'xanax_manufacturing',
        packagedItem = 'xanax_pill',
        
        basePricePerPill = 15,
        qualityPrices = {
            poor = 0.6,
            common = 0.8,
            good = 1.1,
            premium = 1.4,
            pure = 1.8
        },
        
        manufacturingLocations = {
            {
                label = 'Pill Press - Pillbox',
                coords = vector3(429.25, -980.35, 29.41),
                heading = 0.0,
                requiresPillPress = true,
                pillPressModel = 'prop_printer_01'
            },
            {
                label = 'Pill Press - Industrial',
                coords = vector3(1118.35, -799.45, 57.63),
                heading = 0.0,
                requiresPillPress = true,
                pillPressModel = 'prop_printer_01'
            }
        },
        
        effects = {
            duration = 150000,
            stressReduction = 40,
            calmingEffect = true,
            reactionSpeed = 0.75
        },
        
        addiction = {
            enabled = true,
            addictionRate = 1.2,
            withdrawalDuration = 2700000, -- 45 minutes
            withdrawalIntensity = 0.3
        }
    }
}

-- ===========================
-- DEALER SYSTEM
-- ===========================

Config.Dealers = {
    enabled = true,
    spawnChance = 0.3,
    respawnTime = 1800000, -- 30 minutes
    dealerInventorySize = 10,
    
    dealerNames = {
        'Marcus', 'DeShawn', 'Jerome', 'Andre', 'Carlos',
        'Luis', 'Miguel', 'Diego', 'Tony', 'Ghost',
        'Shadow', 'Smoke', 'Big Boy', 'Lil Jay', 'Trap King'
    },
    
    dealerLocations = {
        {
            label = 'Street Corner - Strawberry',
            coords = vector3(324.35, -987.45, 29.41),
            heading = 0.0
        },
        {
            label = 'Alley - Downtown',
            coords = vector3(410.25, -988.35, 29.41),
            heading = 0.0
        },
        {
            label = 'Park - Mirror Park',
            coords = vector3(-420.35, -328.45, 35.3),
            heading = 0.0
        },
        {
            label = 'Street - Paleto Bay',
            coords = vector3(-230.48, 6231.23, 31.48),
            heading = 0.0
        },
        {
            label = 'Beach - Del Perro',
            coords = vector3(-1273.45, -1376.25, 4.82),
            heading = 0.0
        }
    }
}

-- ===========================
-- POLICE & SECURITY
-- ===========================

Config.Police = {
    alertChance = {
        largeSale = 0.4,
        manufacturing = 0.6,
        explosion = 1.0,
        suspicious = 0.2
    },
    
    alertRadius = 500,
    searchCooldown = 300000, -- 5 minutes
    
    searchCommands = {
        enabled = true,
        canTestDrugs = true,
        canConfiscate = true
    }
}

-- ===========================
-- MONEY LAUNDERING
-- ===========================

Config.MoneyLaundering = {
    enabled = true,
    launderingPercentage = 0.85, -- Keep 85% of dirty money
    minimumAmount = 1000,
    maximumAmount = 50000,
    cooldownTime = 600000, -- 10 minutes
    
    launderingLocations = {
        {
            label = 'Casino Laundry',
            coords = vector3(1109.25, 221.35, 100.0),
            heading = 0.0,
            blip = 'blip_money'
        },
        {
            label = 'Business Office Laundry',
            coords = vector3(-1580.45, -569.25, 108.47),
            heading = 0.0,
            blip = 'blip_money'
        },
        {
            label = 'Car Wash Laundry',
            coords = vector3(24.35, -1394.25, 29.5),
            heading = 0.0,
            blip = 'blip_money'
        }
    }
}

-- ===========================
-- ADDICTION SYSTEM
-- ===========================

Config.Addiction = {
    enabled = true,
    databaseTable = 'player_addiction',
    
    withdrawalEffects = {
        screenShake = {
            enabled = true,
            intensity = 0.3,
            frequency = 200
        },
        staminaLoss = {
            enabled = true,
            reduction = 0.5
        },
        visionBlur = {
            enabled = true,
            intensity = 0.5
        },
        stressIncrease = {
            enabled = true,
            amount = 50
        }
    },
    
    recoveryOptions = {
        useAmbulance = true,
        useDoctor = true,
        useCleaning = true
    }
}

-- ===========================
-- SKILL CHECKS & MINIGAMES
-- ===========================

Config.SkillChecks = {
    simpleSkillCheck = {
        difficulty = 0.5,
        maxErrors = 2,
        duration = 10000
    },
    
    complexSkillCheck = {
        difficulty = 0.7,
        maxErrors = 1,
        duration = 15000
    },
    
    temperatureControl = {
        baseDifficulty = 0.6,
        maxErrors = 3,
        duration = 30000,
        tolerance = 5 -- degrees celsius
    }
}

-- ===========================
-- NOTIFICATIONS & UI
-- ===========================

Config.Notifications = {
    useOxNotify = true,
    defaultDuration = 5000,
    positions = {
        top = 'top',
        middle = 'middle',
        bottom = 'bottom'
    }
}

-- ===========================
-- ITEM WEIGHTS (ox_inventory)
-- ===========================

Config.ItemWeights = {
    weed_seed = 0.1,
    weed_plant = 0.5,
    weed_dried = 0.4,
    weed_trimmed = 0.3,
    weed_bag = 0.25,
    
    coca_leaf = 0.2,
    cocaine_paste = 0.15,
    cocaine_powder = 0.12,
    cocaine_bag = 0.1,
    
    meth_chemical = 0.3,
    meth_cooking = 0.2,
    meth_bag = 0.1,
    
    fentanyl_chemical = 0.1,
    fentanyl_manufacturing = 0.08,
    fentanyl_dose = 0.05,
    
    xanax_ingredient = 0.05,
    xanax_manufacturing = 0.03,
    xanax_pill = 0.01,
    
    dirty_money = 0.001
}

-- ===========================
-- COMMAND RESTRICTIONS
-- ===========================

Config.RestrictedJobs = {
    police = true,
    ambulance = true,
    admin = true
}

-- ===========================
-- RESOURCE LIMITS
-- ===========================

Config.ResourceLimits = {
    maxPlantsPerPlayer = 5,
    maxDealersSpawned = 10,
    maxProcessingPerPlayer = 3,
    updateTickRate = 100 -- milliseconds
}
