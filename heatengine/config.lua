Config = {}

Config.speedLimit = 80.0 -- Speed limit in km/h or mph
Config.maxTemperature = 100.0 -- Maximum temperature before the engine stops
Config.temperatureIncreaseRate = 0.1 -- Rate at which temperature increases per frame when over speed limit
Config.temperatureDecreaseRate = 0.05 -- Rate at which temperature decreases per frame when below speed limit
Config.engineWearRate = 0.01 -- Rate at which engine wears down when overheating
Config.cooldownRate = 0.1 -- Rate at which the engine cools down per frame
Config.cooldownDelay = 5000 -- Delay in milliseconds before checking if the engine can restart
Config.safeTemperature = 50 -- Safe temperature below which the engine can restart
Config.speedUnit = "kmh" -- Options: "kmh" or "mph"
Config.blacklistedVehicles = { "POLICE", "AMBULANCE", "FIRETRUK" } -- List of blacklisted vehicle models
Config.cruiseControlEnabled = true -- Enable or disable cruise control
Config.cruiseControlButton = 213 -- Default button for cruise control (Home button)

Config.temperatureThreshold = 80.0 -- Temperature threshold to start reducing speed
Config.maxSpeedReduction = 15.0 -- Max speed reduction (km/h)
Config.speedReductionRate = 0.1 -- Rate at which the speed is reduced (10% of maxSpeedReduction)
Config.engineDamageRate = 0.5 -- Rate at which the engine takes damage
Config.criticalHealthThreshold = -10.0 -- Threshold below which the car won't start again
Config.engineStopDelay = 3000 -- Delay in milliseconds before stopping the engine at max temperature
