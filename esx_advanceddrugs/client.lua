-- Advanced Drugs Client Script
-- ESX Legacy + ox_inventory compatible

local ESX = exports['es_extended']:getSharedObject()
local activePlants = {}
local activeProcessing = {}
local playerAddiction = {}
local drugEffectsActive = {}

-- Performance optimization
local updateCounter = 0
local lastUpdateTime = GetGameTimer()

-- ===========================
-- UTILITIES
-- ===========================

local function notify(title, description, notificationType)
    notificationType = notificationType or 'info'
    lib.notify({
        title = title,
        description = description,
        type = notificationType,
        duration = Config.Notifications.defaultDuration,
        position = Config.Notifications.positions.bottom
    })
end

local function getDistance(coords1, coords2)
    return #(coords1 - coords2)
end

local function isPlayerJobRestricted()
    if ESX.PlayerData.job and Config.RestrictedJobs[ESX.PlayerData.job.name] then
        notify('Error', 'Your job prevents you from using drugs', 'error')
        return true
    end
    return false
end

-- ===========================
-- THREAD: Main Loop
-- ===========================

CreateThread(function()
    while true do
        updateCounter = updateCounter + 1
        local currentTime = GetGameTimer()
        
        -- Update plants every 100ms
        if updateCounter % 1 == 0 then
            updatePlantStages()
            updateDrugEffects()
            updateAddictionWithdrawal()
        end
        
        Wait(Config.ResourceLimits.updateTickRate)
    end
end)

-- ===========================
-- PLANT MANAGEMENT SYSTEM
-- ===========================

local function plantWeed(drugType, seedItem)
    if isPlayerJobRestricted() then return end
    
    TriggerServerEvent('esx_advanceddrugs:plantWeed', drugType)
end

local function waterPlant(plantId)
    if isPlayerJobRestricted() then return end
    
    local success = lib.skillCheck({
        duration = 5000,
        difficulty = 3,
        keys = {{ areaSize = 60, key = 'e' }},
        stamina = 50
    })
    
    if success then
        TriggerServerEvent('esx_advanceddrugs:waterPlant', plantId)
        notify('Plant Watered', 'Your plant looks hydrated', 'success')
    else
        notify('Failed', 'You failed to water the plant properly', 'error')
    end
end

local function fertilizePlant(plantId)
    if isPlayerJobRestricted() then return end
    
    local options = {
        {
            title = 'Standard Fertilizer',
            description = 'Costs $50 - +15% growth',
            args = { plantId, 'standard' }
        },
        {
            title = 'Premium Fertilizer',
            description = 'Costs $150 - +30% growth',
            args = { plantId, 'premium' }
        },
        {
            title = 'Organic Fertilizer',
            description = 'Costs $100 - +20% growth + health',
            args = { plantId, 'organic' }
        }
    }
    
    lib.showContext('fertilizer_menu', { values = options })
end

local function harvestPlant(plantId, drugType)
    if isPlayerJobRestricted() then return end
    
    lib.progressBar({
        duration = 8000,
        label = 'Harvesting ' .. Config.Drugs[drugType].label,
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        anim = {
            dict = 'combat@damage@rb_writhe',
            clip = 'rb_writhe_loop'
        }
    })
    
    TriggerServerEvent('esx_advanceddrugs:harvestPlant', plantId, drugType)
end

local function updatePlantStages()
    if not Config.Debug then return end
    
    -- Plant growth updates handled server-side for security
    -- Client only displays visual indicators
end

-- ===========================
-- PROCESSING LOCATIONS
-- ===========================

local function openProcessingMenu(drugType, location)
    if isPlayerJobRestricted() then return end
    
    local playerCoords = GetEntityCoords(PlayerPedId())
    if getDistance(playerCoords, location.coords) > 5.0 then
        notify('Distance', 'You are too far from the processing location', 'error')
        return
    end
    
    local options = {
        {
            title = 'Process ' .. Config.Drugs[drugType].label,
            description = 'Begin processing materials',
            args = { drugType, location },
            icon = 'fa-flask'
        },
        {
            title = 'Check Progress',
            description = 'View processing status',
            args = { drugType },
            icon = 'fa-hourglass'
        }
    }
    
    lib.showContext('processing_menu', { values = options })
end

local function processWeed()
    if isPlayerJobRestricted() then return end
    
    local options = {
        {
            title = 'Dry Weed',
            description = 'Dry fresh weed - 2 minutes',
            args = { 'dry' },
            icon = 'fa-wind'
        },
        {
            title = 'Trim Weed',
            description = 'Trim dried weed - 1 minute',
            args = { 'trim' },
            icon = 'fa-scissors'
        },
        {
            title = 'Package Weed',
            description = 'Package trimmed weed into bags - 1 minute',
            args = { 'package' },
            icon = 'fa-box'
        }
    }
    
    lib.showContext('weed_processing', { values = options })
end

local function processCocaine()
    if isPlayerJobRestricted() then return end
    
    local options = {
        {
            title = 'Process Coca Leaves',
            description = 'Extract cocaine paste - Skill check required',
            args = { 'paste' },
            icon = 'fa-flask'
        },
        {
            title = 'Refine Cocaine',
            description = 'Refine paste into powder - Skill check required',
            args = { 'refine' },
            icon = 'fa-sparkles'
        },
        {
            title = 'Package Cocaine',
            description = 'Package powder into bags',
            args = { 'package' },
            icon = 'fa-box'
        }
    }
    
    lib.showContext('cocaine_processing', { values = options })
end

local function processMeth()
    if isPlayerJobRestricted() then return end
    
    local options = {
        {
            title = 'Cook Meth',
            description = 'Control temperature and cook methamphetamine',
            args = { 'cook' },
            icon = 'fa-flask'
        },
        {
            title = 'Package Meth',
            description = 'Package into bags for sale',
            args = { 'package' },
            icon = 'fa-box'
        }
    }
    
    lib.showContext('meth_processing', { values = options })
end

local function temperatureControlMinigame()
    -- Temperature control minigame for meth cooking
    local difficulty = 0.6
    local success = lib.skillCheck({
        duration = Config.SkillChecks.temperatureControl.duration,
        difficulty = difficulty,
        keys = {{ areaSize = 60, key = 'e' }, { areaSize = 40, key = 'r' }},
        stamina = 80
    })
    
    return success
end

-- ===========================
-- DRUG EFFECTS
-- ===========================

local function applyDrugEffects(drugType, quality)
    if drugEffectsActive[drugType] then return end
    
    local drugConfig = Config.Drugs[drugType]
    local effects = drugConfig.effects
    
    drugEffectsActive[drugType] = {
        startTime = GetGameTimer(),
        duration = effects.duration,
        quality = quality
    }
    
    -- Apply quality multipliers
    local qualityMultiplier = Config.Drugs[drugType].qualityPrices[quality] or 1.0
    
    if drugType == 'weed' then
        applyWeedEffects(effects, qualityMultiplier)
    elseif drugType == 'cocaine' then
        applyCocaineEffects(effects, qualityMultiplier)
    elseif drugType == 'meth' then
        applyMethEffects(effects, qualityMultiplier)
    elseif drugType == 'fentanyl' then
        applyFentanylEffects(effects, qualityMultiplier)
    elseif drugType == 'xanax' then
        applyXanaxEffects(effects, qualityMultiplier)
    end
end

local function applyWeedEffects(effects, multiplier)
    local ped = PlayerPedId()
    SetBlockingOfNonTemporaryEvents(ped, true)
    
    -- Relaxed movement
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_CHILLAX_MALE', 0, true)
    
    -- Slight visual haze
    SetTimecycleModifier('hud_def_blur')
    
    TriggerEvent('esx_advanceddrugs:weedEffectStarted')
end

local function applyCocaineEffects(effects, multiplier)
    local ped = PlayerPedId()
    
    -- Increased confidence animation
    PlayAmbientSpeech1(ped, 'GENERIC_HI', 'SPEECH_PARAMS_DETAIL')
    
    -- Temporary stamina boost
    RestorePlayerStamina(PlayerId(), 100.0)
    
    TriggerEvent('esx_advanceddrugs:cocaineEffectStarted')
end

local function applyMethEffects(effects, multiplier)
    -- High energy state
    RestorePlayerStamina(PlayerId(), 100.0)
    
    -- Speed boost animation
    ApplyDamageToPed(PlayerPedId(), 0, false)
    
    TriggerEvent('esx_advanceddrugs:methEffectStarted')
end

local function applyFentanylEffects(effects, multiplier)
    local ped = PlayerPedId()
    
    -- Heavy visual effects
    SetTimecycleModifier('spectator')
    ShakeGameplayCam('DRUNK_SHAKE', 0.5)
    
    TriggerEvent('esx_advanceddrugs:fentanylEffectStarted')
end

local function applyXanaxEffects(effects, multiplier)
    -- Calming effect
    SetTimecycleModifier('cinema')
    
    TriggerEvent('esx_advanceddrugs:xanaxEffectStarted')
end

local function updateDrugEffects()
    local currentTime = GetGameTimer()
    
    for drugType, effectData in pairs(drugEffectsActive) do
        if currentTime - effectData.startTime > effectData.duration then
            removeDrugEffects(drugType)
        end
    end
end

local function removeDrugEffects(drugType)
    drugEffectsActive[drugType] = nil
    
    -- Clear timecycle modifiers
    ClearTimecycleModifier()
    ClearExtraTimecycleModifier()
    
    TriggerEvent('esx_advanceddrugs:effectsWeared', drugType)
end

-- ===========================
-- ADDICTION SYSTEM
-- ===========================

local function updateAddictionWithdrawal()
    if not Config.Addiction.enabled then return end
    
    TriggerServerEvent('esx_advanceddrugs:checkAddiction')
end

local function applyWithdrawalEffects(drugType, intensity)
    local ped = PlayerPedId()
    
    if Config.Addiction.withdrawalEffects.screenShake.enabled then
        ShakeGameplayCam('DRUNK_SHAKE', intensity * 0.3)
    end
    
    if Config.Addiction.withdrawalEffects.visionBlur.enabled then
        SetTimecycleModifier('hud_def_blur')
    end
    
    if Config.Addiction.withdrawalEffects.staminaLoss.enabled then
        local stamina = GetPlayerSprintStaminaRemaining(PlayerId())
        SetPlayerSprintStaminaRemaining(PlayerId(), stamina * (1 - intensity))
    end
end

-- ===========================
-- DEALER SYSTEM
-- ===========================

local function openDealerMenu(dealerName, dealerStock)
    if isPlayerJobRestricted() then return end
    
    local options = {}
    
    for drugType, stock in pairs(dealerStock) do
        if stock > 0 then
            local drugConfig = Config.Drugs[drugType]
            table.insert(options, {
                title = drugConfig.label,
                description = 'Stock: ' .. stock .. ' grams',
                args = { drugType, dealerName },
                icon = 'fa-bag'
            })
        end
    end
    
    if #options == 0 then
        notify('Dealer', 'This dealer has no stock currently', 'info')
        return
    end
    
    lib.showContext('dealer_menu', { values = options })
end

-- ===========================
-- MONEY LAUNDERING
-- ===========================

local function openLaunderingMenu(location)
    if isPlayerJobRestricted() then return end
    
    local playerCoords = GetEntityCoords(PlayerPedId())
    if getDistance(playerCoords, location.coords) > 5.0 then
        notify('Distance', 'You are too far away', 'error')
        return
    end
    
    local input = lib.inputDialog('Money Laundering', {
        { type = 'number', label = 'Amount', description = 'How much dirty money to launder?', required = true, min = Config.MoneyLaundering.minimumAmount, max = Config.MoneyLaundering.maximumAmount }
    })
    
    if input then
        TriggerServerEvent('esx_advanceddrugs:launderMoney', input[1], location.label)
    end
end

-- ===========================
-- POLICE SEARCH
-- ===========================

local function policeSearchPlayer(targetPlayer)
    if ESX.PlayerData.job.name ~= 'police' then
        notify('Error', 'Only police can search players', 'error')
        return
    end
    
    local options = {
        {
            title = 'Search for Drugs',
            description = 'Search this player for narcotics',
            args = { targetPlayer, 'drugs' },
            icon = 'fa-search'
        },
        {
            title = 'Test for Drug Use',
            description = 'Conduct a drug test',
            args = { targetPlayer, 'test' },
            icon = 'fa-flask'
        },
        {
            title = 'Confiscate All Drugs',
            description = 'Take all drugs from this player',
            args = { targetPlayer, 'confiscate' },
            icon = 'fa-ban'
        }
    }
    
    lib.showContext('police_search', { values = options })
end

-- ===========================
-- CONTEXT MENU HANDLERS
-- ===========================

RegisterNetEvent('esx_advanceddrugs:openWeedProcessing', function()
    processWeed()
end)

RegisterNetEvent('esx_advanceddrugs:openCocaineProcessing', function()
    processCocaine()
end)

RegisterNetEvent('esx_advanceddrugs:openMethProcessing', function()
    processMeth()
end)

RegisterNetEvent('esx_advanceddrugs:applyDrugEffects', function(drugType, quality)
    applyDrugEffects(drugType, quality)
    
    if Config.Addiction.enabled then
        TriggerServerEvent('esx_advanceddrugs:addictPlayer', drugType)
    end
end)

RegisterNetEvent('esx_advanceddrugs:notifyClient', function(title, description, notificationType)
    notify(title, description, notificationType)
end)

RegisterNetEvent('esx_advanceddrugs:applyWithdrawal', function(drugType, intensity)
    applyWithdrawalEffects(drugType, intensity)
end)

-- ===========================
-- MAIN MENU COMMANDS
-- ===========================

-- Command to access main drug menu
TriggerEvent('chat:addSuggestion', '/drugs', 'Open the advanced drugs menu', {})

RegisterCommand('drugs', function()
    if isPlayerJobRestricted() then return end
    
    local options = {
        {
            title = 'Weed Farm',
            description = 'Grow and process weed',
            args = { 'weed' },
            icon = 'fa-leaf'
        },
        {
            title = 'Cocaine Lab',
            description = 'Extract and process cocaine',
            args = { 'cocaine' },
            icon = 'fa-flask'
        },
        {
            title = 'Meth Lab',
            description = 'Cook methamphetamine',
            args = { 'meth' },
            icon = 'fa-flask'
        },
        {
            title = 'Fentanyl Lab',
            description = 'Manufacture fentanyl',
            args = { 'fentanyl' },
            icon = 'fa-syringe'
        },
        {
            title = 'Pill Press',
            description = 'Manufacture Xanax pills',
            args = { 'xanax' },
            icon = 'fa-capsules'
        },
        {
            title = 'Meet Dealer',
            description = 'Contact a drug dealer',
            args = { 'dealer' },
            icon = 'fa-user-secret'
        },
        {
            title = 'Launder Money',
            description = 'Convert dirty money',
            args = { 'launder' },
            icon = 'fa-money-bill'
        }
    }
    
    lib.showContext('main_drugs_menu', { values = options })
end, false)

-- ===========================
-- SCRIPT LOAD EVENT
-- ===========================

RegisterNetEvent('esx:playerLoaded', function()
    TriggerServerEvent('esx_advanceddrugs:loadPlayerAddiction')
end)

print('^2[esx_advanceddrugs]^7 Client script loaded successfully')
