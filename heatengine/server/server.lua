RegisterServerEvent('syncVehicleState')
AddEventHandler('syncVehicleState', function(vehicleId, state)
    TriggerClientEvent('updateVehicleState', -1, vehicleId, state)
end)
