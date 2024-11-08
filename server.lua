local savedDescriptions = {}

local function loadSavedDescriptions()
    local file = LoadResourceFile(GetCurrentResourceName(), "opisData.json")
    return file and json.decode(file) or {}
end

local function saveDescriptions()
    SaveResourceFile(GetCurrentResourceName(), "opisData.json", json.encode(savedDescriptions), -1)
end

lib.callback.register('snaily-opis:updateDescription', function(source, description)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    TriggerClientEvent('snaily-opis:syncDescription', -1, source, description)
    return true
end)

lib.callback.register('snaily-opis:updateColor', function(source, color)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local identifier = xPlayer.identifier
    if not savedDescriptions[identifier] then
        savedDescriptions[identifier] = {}
    end

    savedDescriptions[identifier].color = color
    saveDescriptions()
    return true
end)

lib.callback.register('snaily-opis:saveDescription', function(source, descriptions)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local identifier = xPlayer.identifier
    if not savedDescriptions[identifier] then
        savedDescriptions[identifier] = {}
    end

    savedDescriptions[identifier].saved = descriptions
    saveDescriptions()
    return true
end)

RegisterNetEvent('snaily-opis:requestData', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local identifier = xPlayer.identifier
    local playerData = savedDescriptions[identifier] or {}

    TriggerClientEvent('snaily-opis:loadData', source, {
        color = playerData.color or Config.DefaultColor,
        saved = playerData.saved or {}
    })
end)

AddEventHandler('esx:playerLoaded', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local identifier = xPlayer.identifier
    local playerData = savedDescriptions[identifier] or {}

    TriggerClientEvent('snaily-opis:loadData', source, {
        color = playerData.color or Config.DefaultColor,
        saved = playerData.saved or {}
    })
end)

CreateThread(function()
    savedDescriptions = loadSavedDescriptions()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    saveDescriptions()
end)
