local Descriptions = {
    active = {},
    saved = {},
    color = Config.DefaultColor
}

local function showNotification(title, description, type)
    lib.notify({title = title, description = description, type = type})
end

local function updateDescription(description)
    local myServerId = cache.serverId
    Descriptions.active[myServerId] = description

    lib.callback('snaily-opis:updateDescription', false, function()
    end, description)
end

local function getSavedDescriptionOptions()
    local options = {}
    for i, desc in ipairs(Descriptions.saved) do
        options[#options + 1] = {label = desc, value = desc}
    end
    return options
end

local function openDescriptionMenu()
    local options = {
        {
            type = 'input',
            label = 'Opis postaci',
            description = 'Wprowadź opis swojej postaci',
            default = Descriptions.active[cache.serverId],
            required = false,
            min = 1,
            max = Config.MaxDescriptionLength
        },
        {
            type = 'color',
            label = 'Kolor opisu',
            default = Descriptions.color
        }
    }

    if #Descriptions.saved > 0 then
        options[#options + 1] = {
            type = 'select',
            label = 'Zapisane opisy',
            description = 'Wybierz zapisany opis',
            options = getSavedDescriptionOptions()
        }
    end

    local input = lib.inputDialog('Menu opisu postaci', options)
    if not input then return end

    if input[1] then
        updateDescription(input[1])
    end

    if input[2] and input[2] ~= Descriptions.color then
        Descriptions.color = input[2]
        lib.callback('snaily-opis:updateColor', false, function()
        end, input[2])
    end

    if input[3] then
        updateDescription(input[3])
    end

    showNotification('Sukces', 'Opis został zaktualizowany', 'success')
end

local function saveCurrentDescription()
    local currentDesc = Descriptions.active[cache.serverId]
    if not currentDesc then
        return showNotification('Błąd', 'Nie masz aktywnego opisu do zapisania', 'error')
    end

    for _, desc in ipairs(Descriptions.saved) do
        if desc == currentDesc then
            return showNotification('Błąd', 'Ten opis już jest zapisany', 'error')
        end
    end

    table.insert(Descriptions.saved, currentDesc)
    lib.callback('snaily-opis:saveDescription', false, function()
    end, Descriptions.saved)
    showNotification('Sukces', 'Opis został zapisany', 'success')
end

RegisterCommand('opis', function()
    openDescriptionMenu()
end)

RegisterCommand('zapiszopis', function()
    saveCurrentDescription()
end)

RegisterCommand('usunopis', function()
    if not Descriptions.active[cache.serverId] then
        return showNotification('Błąd', 'Nie masz aktywnego opisu', 'error')
    end

    updateDescription(nil)
    showNotification('Sukces', 'Opis został usunięty', 'success')
end)

RegisterNetEvent('snaily-opis:loadData', function(data)
    if data.saved then Descriptions.saved = data.saved end
    if data.color then Descriptions.color = data.color end
end)

RegisterNetEvent('snaily-opis:syncDescription', function(serverId, description)
    Descriptions.active[serverId] = description
end)

CreateThread(function()
    while true do
        local sleep = 1000
        local players = GetActivePlayers()
        local playerCoords = GetEntityCoords(cache.ped)

        for _, player in ipairs(players) do
            local targetPed = GetPlayerPed(player)
            local targetServerId = GetPlayerServerId(player)
            local description = Descriptions.active[targetServerId]

            if description then
                local targetCoords = GetEntityCoords(targetPed)
                local distance = #(playerCoords - targetCoords)

                if distance < 15.0 then
                    sleep = 0
                    local pos = GetPedBoneCoords(targetPed, 11816, 0.0, 0.0, 0.0)
                    DrawText3D(pos.x, pos.y, pos.z + 0.1, description, Descriptions.color)
                end
            end
        end
        Wait(sleep)
    end
end)

function DrawText3D(x, y, z, text, color)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.28, 0.28)
        SetTextFont(4)
        SetTextProportional(1)

        local r, g, b = HexToRGB(color)
        SetTextColour(r, g, b, 255)

        SetTextDropshadow(1, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()

        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

function HexToRGB(hex)
    hex = hex:gsub("#","")
    return tonumber("0x"..hex:sub(1,2)) or 255, tonumber("0x"..hex:sub(3,4)) or 255, tonumber("0x"..hex:sub(5,6)) or 255
end

CreateThread(function()
    TriggerEvent('chat:addSuggestion', '/opis', 'Otwórz menu opisu postaci')
    TriggerEvent('chat:addSuggestion', '/zapisopis', 'Zapisz aktualny opis')
    TriggerEvent('chat:addSuggestion', '/usunopis', 'Usuń aktualny opis')

    Wait(1000)
    TriggerServerEvent('snaily-opis:requestData')
end)
