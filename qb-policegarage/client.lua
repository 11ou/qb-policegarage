-- Variables
local QBCore = exports[Config.CoreScript]:GetCoreObject()

local Vehicle = nil
local VehicleSpawned = false

-- spawn vehicle
RegisterNetEvent('qb-policegarage:client:SpawnVehicle', function(data)
    QBCore.Functions.SpawnVehicle(data.SpawnName, function(veh)
        SetVehicleNumberPlateText(veh, Text.Plate..tostring(math.random(1000, 9999)))
        exports[Config.FuelScript]:SetFuel(veh, 100.0)
        TriggerEvent("vehiclekeys:client:SetOwner", GetVehicleNumberPlateText(veh))
        SetVehicleEngineOn(veh, true, true)
        Vehicle = veh
        VehicleSpawned = true
    end, data.SpawnCoords, true)
end)

RegisterNetEvent('qb-policegarage:client:DeleteVehicle', function()
    if Vehicle ~= nil then
        DeleteVehicle(Vehicle)
        DeleteEntity(Vehicle)
        VehicleSpawned = false
    elseif IsPedInAnyVehicle(PlayerPedId()) then
        DeleteVehicle(GetVehiclePedIsIn(PlayerPedId(), false))
        DeleteEntity(GetVehiclePedIsIn(PlayerPedId(), false))
        VehicleSpawned = false
    end
end)

RegisterNetEvent('qb-policegarage:clientOpenMenu', function(Current)
     local Menu = {
         {
             header = Text.MenuHeader,
             isMenuHeader = true,
             icon = 'fas fa-car',
         },
         {
             header = Text.CloseMenuHeader,
             icon = 'fas fa-close',
             params = {
                 event = ''..Config.MenuScript..'closeMenu',
             },
         },
     }
     for a, i in pairs(Config.PoliceGarage[Current]['Vehicles']) do
         if QBCore.Functions.GetPlayerData().job.grade.level >= tonumber(i['Grade']) then
             Menu[#Menu + 1] = {
                 header = i['VehicleName'],
                 icon = 'fas fa-car',
                 params = {
                     event = 'qb-policegarage:client:SpawnVehicle',
                     args = {
                         SpawnName = i['VehicleSpawnName'],
                         SpawnCoords = Config.PoliceGarage[Current]['SpawnCoords'],
                     },
                 }
             }
         end
     end
     if VehicleSpawned == true then
         Menu[#Menu + 1] = {
             header = Text.StoreMenuHeader,
             icon = 'fas fa-ban',
             params = {
                 event = 'qb-policegarage:client:DeleteVehicle',
             }
         }
     end
    Wait(500)
    exports[Config.MenuScript]:openMenu(Menu)
end)

-- Target export and menu event
CreateThread(function()
    for k ,v in pairs(Config.PoliceGarage) do
        local PedLoc = v.PedCoords
        local Spot = v.SpotName
        RequestModel(GetHashKey(v.PedModel))
        while not HasModelLoaded(GetHashKey(v.PedModel)) do
            Wait(1)
        end
        RentalPed =  CreatePed(4, v.PedModelHash, PedLoc.x, PedLoc.y, PedLoc.z, v.Heading, false, true)
        SetEntityHeading(RentalPed, v.Heading)
        FreezeEntityPosition(RentalPed, true)
        SetEntityInvincible(RentalPed, true)
        SetBlockingOfNonTemporaryEvents(RentalPed, true)
        exports[Config.TargetScript]:AddBoxZone(k.."-garage-"..v['Job'], v['Coords'], 1.8, 1, {
            name = k.."-garage-"..v['Job'],
            heading = v['Heading'],
            debugPoly = false,
        }, {
            options = {
                {
                    type = "Client",
                    action = function()
                        TriggerEvent('qb-policegarage:clientOpenMenu', k)
                    end,
                    label = Text.TargetLabel,
                    job = v['Job'],
                },
            },
            distance = 1.5
        })
    end
end)