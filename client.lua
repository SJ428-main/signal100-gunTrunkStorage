local trunkDistance = 2.0
local drawDistance = 10.0
local playerPed = PlayerPedId()
local trunkData = {} -- stores which trunks have weapons

-- Draw 3D text
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if not onScreen then return end
    SetTextScale(Config.TextScale, Config.TextScale)
    SetTextFont(Config.TextFont)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
    local factor = (string.len(text)) / 370
    DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 0, 0, 0, 120)
end

-- Show notification
function ShowNotification(msg)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    DrawNotification(false, false)
    if Config.ChatNotifications then
        TriggerEvent('chat:addMessage', { args = { '^3[Trunk]', msg } })
    end
end

-- Get trunk position
function GetTrunkPosition(vehicle)
    local bone = GetEntityBoneIndexByName(vehicle, "boot")
    if bone ~= -1 then
        local x, y, z = table.unpack(GetWorldPositionOfEntityBone(vehicle, bone))
        return vector3(x, y, z)
    end
    return GetOffsetFromEntityInWorldCoords(vehicle, 0.0, -3.0, 0.0)
end

-- Get currently selected weapon info
function GetWeaponInfo()
    local ped = PlayerPedId()
    local weapon = GetSelectedPedWeapon(ped)
    if weapon == GetHashKey("WEAPON_UNARMED") then return nil end
    local ammo = GetAmmoInPedWeapon(ped, weapon)
    local label = tostring(weapon)
    return weapon, ammo, label
end

-- Receive weapon from server
RegisterNetEvent('weapontrunk:giveWeaponClient', function(weapon, ammo, label)
    GiveWeaponToPed(PlayerPedId(), weapon, ammo, false, true)
    ShowNotification(("Took %s from trunk."):format(label or "weapon"))
end)

-- Server notifications
RegisterNetEvent('weapontrunk:notify', function(msg)
    ShowNotification(msg)
end)

-- Update local trunk data (called by server if needed)
RegisterNetEvent('weapontrunk:updateTrunkData', function(plate, hasWeapon)
    trunkData[plate] = hasWeapon
end)

-- Main loop
Citizen.CreateThread(function()
    while true do
        local sleep = 500
        local ped = PlayerPedId()
        if not IsPedInAnyVehicle(ped, false) then
            local coords = GetEntityCoords(ped)
            local vehicle = nil
            local minDist = drawDistance

            -- Find closest vehicle
            for _, v in ipairs(GetGamePool('CVehicle')) do
                if DoesEntityExist(v) and not IsEntityDead(v) then
                    local vCoords = GetEntityCoords(v)
                    local dist = #(coords - vCoords)
                    if dist < minDist then
                        vehicle = v
                        minDist = dist
                    end
                end
            end

            if vehicle then
                local trunkPos = GetTrunkPosition(vehicle)
                local distToTrunk = #(coords - trunkPos)

                if distToTrunk < drawDistance then
                    sleep = 5

                    local plate = GetVehicleNumberPlateText(vehicle)
                    local hasWeapon = trunkData[plate] or false

                    local prompt = ""
                    if not hasWeapon then
                        prompt = Config.StorePrompt
                    else
                        prompt = Config.TakePrompt
                    end

                    DrawText3D(trunkPos.x, trunkPos.y, trunkPos.z + 0.2, prompt)
                end

                if distToTrunk < trunkDistance then
                    sleep = 5

                    local plate = GetVehicleNumberPlateText(vehicle)
                    local hasWeapon = trunkData[plate] or false

                    -- Store weapon if trunk empty
                    if IsControlJustReleased(0, Config.StoreKey) then
                        if hasWeapon then
                            ShowNotification("This trunk already has a weapon!")
                        else
                            local weapon, ammo, label = GetWeaponInfo()
                            if not weapon then
                                ShowNotification("You have no weapon equipped.")
                            else
                                RemoveWeaponFromPed(ped, weapon)
                                TriggerServerEvent('weapontrunk:storeWeapon', plate, weapon, ammo, label)
                                trunkData[plate] = true
                            end
                        end
                    end

                    -- Retrieve weapon if trunk has one
                    if IsControlJustReleased(0, Config.TakeKey) then
                        if hasWeapon then
                            TriggerServerEvent('weapontrunk:retrieveWeapon', plate)
                            trunkData[plate] = false
                        else
                            ShowNotification("No weapon stored in this trunk.")
                        end
                    end
                end
            end
        end
        Citizen.Wait(sleep)
    end
end)
