
if not Config then
    Config = {}
end


local vehicleStates = {} 
local currentVehicle = nil 
local uiVisible = false
local cruiseControlActive = false
local cruiseControlSpeed = 0.0
local engineShutdown = false 


local function isVehicleBlacklisted(vehicle)
    local model = GetEntityModel(vehicle)
    for _, blacklistedModel in ipairs(Config.blacklistedVehicles) do
        if model == GetHashKey(blacklistedModel) then
            return true
        end
    end
    return false
end


local function showNotification(message)
    SendNUIMessage({ action = "showNotification", message = message })
end


local function activateCruiseControl(vehicle)
    if Config.cruiseControlEnabled then
        cruiseControlActive = true
        cruiseControlSpeed = GetEntitySpeed(vehicle)
        SetEntityMaxSpeed(vehicle, cruiseControlSpeed)
        showNotification("Cruise control activated")
    end
end


local function deactivateCruiseControl(vehicle)
    cruiseControlActive = false
    SetEntityMaxSpeed(vehicle, GetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveMaxFlatVel"))
    showNotification("Cruise control deactivated")
end


local function initializeVehicleState(vehicle)
    local vehicleId = NetworkGetNetworkIdFromEntity(vehicle)
    if not vehicleStates[vehicleId] then
        vehicleStates[vehicleId] = {
            engineTemperature = 0.0,
            engineHealth = GetVehicleEngineHealth(vehicle)
        }
        TriggerServerEvent('syncVehicleState', vehicleId, vehicleStates[vehicleId])
    end
    return vehicleStates[vehicleId]
end

-- Networked State Management
RegisterNetEvent('updateVehicleState')
AddEventHandler('updateVehicleState', function(vehicleId, state)
    vehicleStates[vehicleId] = state
end)

local function setVehicleState(vehicle, state)
    local vehicleId = NetworkGetNetworkIdFromEntity(vehicle)
    vehicleStates[vehicleId] = state
    TriggerServerEvent('syncVehicleState', vehicleId, state)
end

local function getVehicleState(vehicle)
    local vehicleId = NetworkGetNetworkIdFromEntity(vehicle)
    return vehicleStates[vehicleId]
end


Citizen.CreateThread(function()
    while true do
        local player = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(player, false)
        if vehicle and IsPedInAnyVehicle(player, false) then
            if currentVehicle ~= vehicle then
                currentVehicle = vehicle
                local state = initializeVehicleState(vehicle)
                engineTemperature = state.engineTemperature
                engineHealth = state.engineHealth
                engineShutdown = false 
            end

            if isVehicleBlacklisted(vehicle) then
                if uiVisible then
                    SendNUIMessage({ action = "hideUI" })
                    uiVisible = false
                end
            else
                if not uiVisible then
                    SendNUIMessage({ action = "showUI" })
                    uiVisible = true
                end

                local speed = GetEntitySpeed(vehicle)
                if Config.speedUnit == "mph" then
                    speed = speed * 2.23694 
                else
                    speed = speed * 3.6 
                end

                if speed > Config.speedLimit then
                    engineTemperature = engineTemperature + Config.temperatureIncreaseRate
                else
                    engineTemperature = engineTemperature - Config.temperatureDecreaseRate
                end

                engineTemperature = math.max(0, math.min(engineTemperature, Config.maxTemperature))

                
                if engineHealth <= 500 and engineHealth > Config.criticalHealthThreshold then
                    local topSpeed = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveMaxFlatVel")
                    local reducedSpeed = math.max(topSpeed - (10 + math.random(5)), 0)
                    SetEntityMaxSpeed(vehicle, reducedSpeed / 3.6) 
                end

                if engineTemperature >= Config.temperatureThreshold then

                    if engineTemperature < 90 then
                        engineHealth = engineHealth - Config.engineDamageRate
                        SetVehicleEngineHealth(vehicle, engineHealth)
                    end
                end

                if engineTemperature >= Config.maxTemperature then
                    engineOverheated = true
                    cooldownActive = true
                    cooldownStartTime = GetGameTimer() 
                    engineHealth = engineHealth - Config.engineWearRate
                    Citizen.Wait(Config.engineStopDelay)
                    SetVehicleEngineOn(vehicle, false, true, true)
                    showNotification("Engine has overheated! Vehicle stopped.")
                    engineShutdown = true 
                end

                if cooldownActive then
                    engineTemperature = engineTemperature - Config.cooldownRate

                    
                    if engineTemperature <= Config.safeTemperature and engineShutdown then
                        cooldownActive = false
                        engineOverheated = false
                        engineShutdown = false
                        SetVehicleEngineOn(vehicle, true, true, true)
                        SetVehicleEngineHealth(vehicle, engineHealth)
                        showNotification("Engine temperature is safe. Vehicle restarted.")
                    elseif engineTemperature > Config.safeTemperature then
                        SetVehicleEngineOn(vehicle, false, true, true)
                    end
                end

                
                if engineHealth < Config.criticalHealthThreshold then
                    SetVehicleEngineOn(vehicle, false, true, true)
                    showNotification("Engine damaged beyond repair! Vehicle won't start.")
                end

               
                SendNUIMessage({
                    action = "updateTemperature",
                    temperature = (engineTemperature / Config.maxTemperature) * 100,
                    engineHealth = engineHealth,
                    overheated = engineOverheated
                })

               
                if Config.cruiseControlEnabled and IsControlJustPressed(1, Config.cruiseControlButton) then
                    if cruiseControlActive then
                        deactivateCruiseControl(vehicle)
                    else
                        activateCruiseControl(vehicle)
                    end
                end

                if cruiseControlActive and not IsPedInAnyVehicle(player, false) then
                    deactivateCruiseControl(vehicle)
                end

            
                local state = getVehicleState(vehicle)
                state.engineTemperature = engineTemperature
                state.engineHealth = engineHealth
                setVehicleState(vehicle, state)
            end
        elseif uiVisible then
            SendNUIMessage({ action = "hideUI" })
            uiVisible = false
            cruiseControlActive = false
            engineShutdown = false 
        end
        Citizen.Wait(0)
    end
end)

-
RegisterNetEvent('baseevents:leftVehicle')
AddEventHandler('baseevents:leftVehicle', function()
    SendNUIMessage({ action = "hideUI" })
    uiVisible = false
    cruiseControlActive = false
    currentVehicle = nil
    engineShutdown = false 
end)

RegisterCommand("engine", function()
    SetNuiFocus(true, true)
    SendNUIMessage({ action = "unlockMouse" })
end, false)

RegisterCommand("setColor", function(source, args, rawCommand)
    local color = args[1] 
    if color then
        if string.sub(color, 1, 1) ~= "#" then
            color = "#" .. color 
        end
        SendNUIMessage({ action = "updateColor", color = color })
    else
        print("Usage: /setColor [color code]")
    end
end, false)

RegisterNUICallback("close_ui", function(data, cb)
    SetNuiFocus(false, false)
    cb("ok")
end)


RegisterNetEvent('updateVehicleState')
AddEventHandler('updateVehicleState', function(vehicleId, state)
    vehicleStates[vehicleId] = state
end)
