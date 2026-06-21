-- Advanced Drugs Server Script
-- ESX Legacy + ox_inventory compatible
-- Security-focused production code

local ESX = exports['es_extended']:getSharedObject()

-- ===========================
-- LOCAL VARIABLES
-- ===========================

local activePlants = {}
local activeProcessing = {}
local playerAddiction = {}
local playerDirtyMoney = {}
local dealerCooldowns = {}
local processingCooldowns = {}

-- ===========================
-- UTILITIES
-- ===========================

local function getPlayerIdentifier(source)
    for _, identifier in ipairs(GetIdentifiers(source)) do
        if string.match(identifier, 'license:') then
            return identifier
        end
    end
    return nil
end

local function logEvent(eventType, playerName, details)
    if Config.Debug then
        print('^3[esx_advanceddrugs]^7 ' .. eventType .. ' - Player: ' .. playerName .. ' - Details: ' .. json.encode(details))
    end
end

local function executeSecureSQL(query, params)
    local result = MySQL.query.await(query, params or {})
    return result
end

local function getPlayerDrugs(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return {} end
    
    local drugs = {}
    local inventory = xPlayer.getInventory()
    
    for _, item in ipairs(inventory) do
        for drugType, config in pairs(Config.Drugs) do
            if item.name == config.packagedItem or item.name == config.item then
                drugs[drugType] = (drugs[drugType] or 0) + item.count
            end
        end
    end
    
    return drugs
end

-- ===========================
-- PLANT MANAGEMENT
-- ===========================

local function createPlant(source, drugType, coords)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    
    -- Validate drug type
    if not Config.Drugs[drugType] then
        TriggerClientEvent('esx_advanceddrugs:notifyClient', source, 'Error', 'Invalid drug type', 'error')
        return false
    end
    
    -- Count existing plants
    local plantCount = 0
    for _, plant in pairs(activePlants) do
        if plant.owner_id == xPlayer.source then
            plantCount = plantCount + 1
        end
    end
    
    if plantCount >= Config.MaxPlantsPerPlayer then
        TriggerClientEvent('esx_advanceddrugs:notifyClient', source, 'Error', 'You have too many plants', 'error')
        return false
    end
    
    -- Check for seed item
    if xPlayer.getInventoryItem(Config.Drugs[drugType].seedItem).count < 1 then
        TriggerClientEvent('esx_advanceddrugs:notifyClient', source, 'Error', 'You need seeds to plant', 'error')
        return false
    end
    
    -- Create plant
    local plant = {
        id = math.random(10000, 99999),
        owner_id = xPlayer.source,
        owner_name = xPlayer.getName(),
        drug_type = drugType,
        coords = coords,
        stage = 'seed',
        growth_percentage = 0,
        health = 100,
        water_level = 100,
        fertilizer_level = 100,
        created_at = os.time(),
        last_updated = os.time()
    }
    
    activePlants[plant.id] = plant
    
    -- Remove seed from inventory
    xPlayer.removeInventoryItem(Config.Drugs[drugType].seedItem, 1)
    
    -- Save to database
    MySQL.insert.await('INSERT INTO drug_plants (owner_id, owner_name, drug_type, coords_x, coords_y, coords_z, stage, health, water_level, fertilizer_level) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        { xPlayer.source, xPlayer.getName(), drugType, coords.x, coords.y, coords.z, 'seed', 100, 100, 100 })
    
    logEvent('PLANT_CREATED', xPlayer.getName(), { drugType = drugType, plantId = plant.id })
    TriggerClientEvent('esx_advanceddrugs:notifyClient', source, 'Success', 'You planted a ' .. Config.Drugs[drugType].label .. ' seed', 'success')
    
    return true
end

local function updatePlantGrowth()
    local currentTime = os.time()
    
    for plantId, plant in pairs(activePlants) do
        if plant.destroyed then goto continue end
        
        local timeSinceUpdate = currentTime - plant.last_updated
        
        -- Plant growth logic
        if plant.stage == 'seed' then
            plant.growth_percentage = plant.growth_percentage + (timeSinceUpdate / 120) * 100
            if plant.growth_percentage >= 100 then
                plant.stage = 'sprout'
                plant.growth_percentage = 0
            end
        elseif plant.stage == 'sprout' then
            plant.growth_percentage = plant.growth_percentage + (timeSinceUpdate / 300) * 100
            if plant.growth_percentage >= 100 then
                plant.stage = 'growing'
                plant.growth_percentage = 0
            end
        elseif plant.stage == 'growing' then
            plant.growth_percentage = plant.growth_percentage + (timeSinceUpdate / 600) * 100
            if plant.growth_percentage >= 100 then
                plant.stage = 'mature'
                plant.growth_percentage = 0
            end
        elseif plant.stage == 'mature' then
            plant.growth_percentage = plant.growth_percentage + (timeSinceUpdate / 600) * 100
            if plant.growth_percentage >= 100 then
                plant.stage = 'ready_harvest'
                plant.growth_percentage = 0
            end
        end
        
        -- Health and water degradation
        plant.water_level = math.max(0, plant.water_level - (timeSinceUpdate / 600))
        if plant.water_level < 30 then
            plant.health = math.max(0, plant.health - (timeSinceUpdate / 1000))
        end
        
        if plant.fertilizer_level > 0 then
            plant.growth_percentage = plant.growth_percentage + (timeSinceUpdate / 1200) * 10
        end
        
        plant.last_updated = currentTime
        
        ::continue::
    end
end

local function waterPlant(source, plantId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    
    local plant = activePlants[plantId]
    if not plant then
        TriggerClientEvent('esx_advanceddrugs:notifyClient', source, 'Error', 'Plant not found', 'error')
        return false
    end
    
    if plant.owner_id ~= xPlayer.source then
        TriggerClientEvent('esx_advanceddrugs:notifyClient', source, 'Error', 'This is not your plant', 'error')
        return false
    end
    
    plant.water_level = math.min(100, plant.water_level + 50)
    
    TriggerClientEvent('esx_advanceddrugs:notifyClient', source, 'Success', 'Plant watered', 'success')
    return true
end

local function harvestPlant(source, plantId, drugType)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    
    local plant = activePlants[plantId]
    if not plant or plant.owner_id ~= xPlayer.source then
        TriggerClientEvent('esx_advanceddrugs:notifyClient', source, 'Error', 'You cannot harvest this plant', 'error')
        return false
    end
    
    if plant.stage ~= 'ready_harvest' then
        TriggerClientEvent('esx_advanceddrugs:notifyClient', source, 'Error', 'This plant is not ready to harvest', 'error')
        return false
    end
    
    -- Calculate harvest amount based on health
    local harvestAmount = math.floor((plant.health / 100) * 20) -- 0-20 grams
    
    xPlayer.addInventoryItem(Config.Drugs[drugType].harvestItem, harvestAmount)
    activePlants[plantId] = nil
    
    -- Remove from database
    MySQL.query.await('DELETE FROM drug_plants WHERE id = ?', { plantId })
    
    logEvent('PLANT_HARVESTED', xPlayer.getName(), { drugType = drugType, amount = harvestAmount })
    TriggerClientEvent('esx_advanceddrugs:notifyClient', source, 'Success', 'You harvested ' .. harvestAmount .. 'g of ' .. Config.Drugs[drugType].label, 'success')
    
    return true
end

-- ===========================
-- PROCESSING SYSTEM
-- ===========================

local function startProcessing(source, drugType, processingType)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    
    -- Check cooldown
    if processingCooldowns[source] and processingCooldowns[source][drugType] then
        if processingCooldowns[source][drugType] > os.time() then
            TriggerClientEvent('esx_advanceddrugs:notifyClient', source, 'Cooldown', 'You must wait before processing again', 'warning')
            return false
        end
    end
    
    local drugConfig = Config.Drugs[drugType]
    local requiredItem = nil
    local outputItem = nil
    
    if processingType == 'dry' and drugType == 'weed' then
        requiredItem = drugConfig.harvestItem
        outputItem = drugConfig.dryItem
    elseif processingType == 'trim' and drugType == 'weed' then
        requiredItem = drugConfig.dryItem
        outputItem = drugConfig.trimmedItem
    elseif processingType == 'package' and drugType == 'weed' then
        requiredItem = drugConfig.trimmedItem
        outputItem = drugConfig.packagedItem
    end
    
    if not requiredItem or not outputItem then
        TriggerClientEvent('esx_advanceddrugs:notifyClient', source, 'Error', 'Invalid processing type', 'error')
        return false
    end
    
    -- Check inventory
    if xPlayer.getInventoryItem(requiredItem).count < 1 then
        TriggerClientEvent('esx_advanceddrugs:notifyClient', source, 'Error', 'You don\'t have the required materials', 'error')
        return false
    end
    
    -- Perform processing
    local processingTime = 5000 -- 5 seconds per gram
    local inputAmount = xPlayer.getInventoryItem(requiredItem).count
    
    TriggerClientEvent('esx_advanceddrugs:notifyClient', source, 'Processing', 'Started processing...', 'info')
    
    SetTimeout(processingTime, function()
        xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return end
        
        -- Success rate based on skill check (handled client-side)
        local successRate = 0.85
        local outputAmount = math.floor(inputAmount * successRate)
        
        xPlayer.removeInventoryItem(requiredItem, inputAmount)
        xPlayer.addInventoryItem(outputItem, outputAmount)
        
        -- Set cooldown
        if not processingCooldowns[source] then processingCooldowns[source] = {} end
        processingCooldowns[source][drugType] = os.time() + 60
        
        logEvent('PROCESSING_COMPLETE', xPlayer.getName(), { drugType = drugType, processingType = processingType, output = outputAmount })
        TriggerClientEvent('esx_advanceddrugs:notifyClient', source, 'Success', 'Processing complete! You got ' .. outputAmount .. 'g', 'success')
    end)
    
    return true
end

local function cookMeth(source, difficulty)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    
    -- Check for meth chemicals
    if xPlayer.getInventoryItem('meth_chemical').count < 10 then
        TriggerClientEvent('esx_advanceddrugs:notifyClient', source, 'Error', 'You need 10 meth chemicals', 'error')
        return false
    end
    
    -- Start cooking process
    TriggerClientEvent('esx_advanceddrugs:notifyClient', source, 'Cooking', 'Cooking meth... Monitor temperature!', 'info')
    
    -- Temperature control minigame (client-side)
    TriggerClientEvent('esx_advanceddrugs:methTemperatureGame', source)
    
    return true
end

RegisterNetEvent('esx_advanceddrugs:methCookingComplete', function(temperature, success)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then return end
    
    local optimalTemp = Config.Drugs.meth.cooking.temperatureOptimal
    local isOptimal = temperature >= optimalTemp.min and temperature <= optimalTemp.max
    
    if success and isOptimal then
        xPlayer.removeInventoryItem('meth_chemical', 10)
        xPlayer.addInventoryItem('meth_bag', 5)
        TriggerClientEvent('esx_advanceddrugs:notifyClient', source, 'Success', 'Perfect cook! You got 5g of pure meth', 'success')
    elseif success and not isOptimal then
        xPlayer.removeInventoryItem('meth_chemical', 10)
        xPlayer.addInventoryItem('meth_bag', 3)
        TriggerClientEvent('esx_advanceddrugs:notifyClient', source, 'Success', 'Cook complete, but temperature was off. You got 3g', 'success')
    else
        -- Explosion chance
        if math.random() < Config.Drugs.meth.cooking.explosionChance then
            TriggerClientEvent('esx_advanceddrugs:notifyClient', source, 'Error', 'EXPLOSION! The lab exploded!', 'error')
            xPlayer.removeInventoryItem('meth_chemical', 10)
            
            -- Police alert
            TriggerEvent('esx_advanceddrugs:policeAlert', source, 'Meth Lab Explosion', 500)
        else
            TriggerClientEvent('esx_advanceddrugs:notifyClient', source, 'Error', 'Failed to cook meth', 'error')
        end
    end
end)

-- ===========================
-- SELLING SYSTEM
-- ===========================

local function sellDrug(source, drugType, quantity, quality)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    
    -- Validate quantity
    if quantity <= 0 or quantity > 100 then
        TriggerClientEvent('esx_advanceddrugs:notifyClient', source, 'Error', 'Invalid quantity', 'error')
        return false
    end
    
    -- Check inventory
    if xPlayer.getInventoryItem(Config.Drugs[drugType].item).count < quantity then
        TriggerClientEvent('esx_advanceddrugs:notifyClient', source, 'Error', 'You don\'t have enough', 'error')
        return false
    end
    
    local drugConfig = Config.Drugs[drugType]
    local basePrice = drugConfig.basePricePerGram
    local qualityMultiplier = drugConfig.qualityPrices[quality] or 1.0
    local finalPrice = math.floor(basePrice * qualityMultiplier * quantity)
    
    -- Add dirty money
    if not playerDirtyMoney[xPlayer.identifier] then
        playerDirtyMoney[xPlayer.identifier] = 0
    end
    playerDirtyMoney[xPlayer.identifier] = playerDirtyMoney[xPlayer.identifier] + finalPrice
    
    -- Remove drug from inventory
    xPlayer.removeInventoryItem(Config.Drugs[drugType].item, quantity)
    
    -- Log sale
    MySQL.insert.await('INSERT INTO drug_sales_stats (seller_id, seller_name, drug_type, quality_level, quantity_sold, price_per_unit, total_amount) VALUES (?, ?, ?, ?, ?, ?, ?)',
        { xPlayer.source, xPlayer.getName(), drugType, quality, quantity, basePrice, finalPrice })
    
    -- Police alert chance
    if Config.EnablePoliceAlerts and math.random() < Config.Police.alertChance.largeSale then
        TriggerEvent('esx_advanceddrugs:policeAlert', source, 'Large Drug Sale', 300)
    end
    
    logEvent('DRUG_SOLD', xPlayer.getName(), { drugType = drugType, quantity = quantity, price = finalPrice })
    TriggerClientEvent('esx_advanceddrugs:notifyClient', source, 'Success', 'Sold ' .. quantity .. 'g for $' .. finalPrice .. ' (dirty money)', 'success')
    
    return true
end

-- ===========================
-- ADDICTION SYSTEM
-- ===========================

local function loadPlayerAddiction(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    local result = MySQL.query.await('SELECT * FROM player_addiction WHERE identifier = ?', { xPlayer.identifier })
    
    if result and #result > 0 then
        playerAddiction[xPlayer.identifier] = result[1]
    else
        -- Create new addiction record
        MySQL.insert.await('INSERT INTO player_addiction (user_id, identifier) VALUES (?, ?)', { xPlayer.source, xPlayer.identifier })
        playerAddiction[xPlayer.identifier] = {
            user_id = xPlayer.source,
            identifier = xPlayer.identifier,
            weed_addiction = 0,
            cocaine_addiction = 0,
            meth_addiction = 0,
            fentanyl_addiction = 0,
            xanax_addiction = 0,
            total_addiction = 0
        }
    end
end

local function addictPlayer(source, drugType)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not Config.Addiction.enabled then return end
    
    if not playerAddiction[xPlayer.identifier] then
        playerAddiction[xPlayer.identifier] = {}
    end
    
    local addictionKey = drugType .. '_addiction'
    local addictionRate = Config.Drugs[drugType].addiction.addictionRate
    
    playerAddiction[xPlayer.identifier][addictionKey] = (playerAddiction[xPlayer.identifier][addictionKey] or 0) + addictionRate
    playerAddiction[xPlayer.identifier].total_addiction = (playerAddiction[xPlayer.identifier].total_addiction or 0) + addictionRate
    
    -- Update database
    MySQL.update.await('UPDATE player_addiction SET ' .. addictionKey .. ' = ?, total_addiction = ? WHERE identifier = ?',
        { playerAddiction[xPlayer.identifier][addictionKey], playerAddiction[xPlayer.identifier].total_addiction, xPlayer.identifier })
    
    logEvent('ADDICTION_INCREASE', xPlayer.getName(), { drugType = drugType, addictionLevel = playerAddiction[xPlayer.identifier][addictionKey] })
end

local function checkAddictionWithdrawal(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not Config.Addiction.enabled then return end
    
    local addiction = playerAddiction[xPlayer.identifier]
    if not addiction then return end
    
    -- Check each drug for withdrawal
    for drugType, config in pairs(Config.Drugs) do
        local addictionKey = drugType .. '_addiction'
        local addictionLevel = addiction[addictionKey] or 0
        
        if addictionLevel > 30 then
            -- Player is in withdrawal
            local intensity = math.min(addictionLevel / 100, 1.0)
            TriggerClientEvent('esx_advanceddrugs:applyWithdrawal', source, drugType, intensity)
        end
    end
end

-- ===========================
-- MONEY LAUNDERING
-- ===========================

local function launderMoney(source, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    
    if not Config.MoneyLaundering.enabled then
        TriggerClientEvent('esx_advanceddrugs:notifyClient', source, 'Error', 'Money laundering is disabled', 'error')
        return false
    end
    
    local dirtyMoney = playerDirtyMoney[xPlayer.identifier] or 0
    
    if dirtyMoney < amount then
        TriggerClientEvent('esx_advanceddrugs:notifyClient', source, 'Error', 'You don\'t have that much dirty money', 'error')
        return false
    end
    
    if amount < Config.MoneyLaundering.minimumAmount or amount > Config.MoneyLaundering.maximumAmount then
        TriggerClientEvent('esx_advanceddrugs:notifyClient', source, 'Error', 'Amount is outside laundry limits', 'error')
        return false
    end
    
    -- Launder the money
    local cleanMoney = math.floor(amount * Config.MoneyLaundering.launderingPercentage)
    
    playerDirtyMoney[xPlayer.identifier] = dirtyMoney - amount
    xPlayer.addMoney(cleanMoney)
    
    logEvent('MONEY_LAUNDERED', xPlayer.getName(), { dirtyAmount = amount, cleanAmount = cleanMoney })
    TriggerClientEvent('esx_advanceddrugs:notifyClient', source, 'Success', 'Laundered $' .. amount .. ' into $' .. cleanMoney, 'success')
    
    return true
end

-- ===========================
-- POLICE ALERTS
-- ===========================

local function policeAlert(alertType, coords, radius)
    TriggerEvent('esx_advanceddrugs:alertPolice', alertType, coords, radius)
end

-- ===========================
-- EVENT HANDLERS
-- ===========================

RegisterNetEvent('esx_advanceddrugs:plantWeed', function(drugType)
    createPlant(source, drugType, GetEntityCoords(GetPlayerPed(source)))
end)

RegisterNetEvent('esx_advanceddrugs:waterPlant', function(plantId)
    waterPlant(source, plantId)
end)

RegisterNetEvent('esx_advanceddrugs:harvestPlant', function(plantId, drugType)
    harvestPlant(source, plantId, drugType)
end)

RegisterNetEvent('esx_advanceddrugs:startProcessing', function(drugType, processingType)
    startProcessing(source, drugType, processingType)
end)

RegisterNetEvent('esx_advanceddrugs:sellDrug', function(drugType, quantity, quality)
    sellDrug(source, drugType, quantity, quality)
end)

RegisterNetEvent('esx_advanceddrugs:loadPlayerAddiction', function()
    loadPlayerAddiction(source)
end)

RegisterNetEvent('esx_advanceddrugs:addictPlayer', function(drugType)
    addictPlayer(source, drugType)
end)

RegisterNetEvent('esx_advanceddrugs:checkAddiction', function()
    checkAddictionWithdrawal(source)
end)

RegisterNetEvent('esx_advanceddrugs:launderMoney', function(amount)
    launderMoney(source, amount)
end)

-- ===========================
-- PLAYER LOADED EVENT
-- ===========================

RegisterNetEvent('esx:playerLoaded', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        loadPlayerAddiction(source)
    end
end)

-- ===========================
-- PLANT GROWTH LOOP
-- ===========================

CreateThread(function()
    while true do
        Wait(5000) -- Update every 5 seconds
        updatePlantGrowth()
    end
end)

-- ===========================
-- CLEANUP
-- ===========================

RegisterNetEvent('esx:playerDropped', function(playerId, reason)
    -- Clean up player data
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if xPlayer then
        -- Remove active plants from memory (but keep in DB)
        for plantId, plant in pairs(activePlants) do
            if plant.owner_id == playerId then
                activePlants[plantId] = nil
            end
        end
    end
end)

print('^2[esx_advanceddrugs]^7 Server script loaded successfully')
