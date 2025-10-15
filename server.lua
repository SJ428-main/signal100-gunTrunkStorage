local Trunks = {} -- [plate] = { weapon=hash, ammo=number, label=string }

RegisterNetEvent('weapontrunk:storeWeapon', function(plate, weaponHash, ammo, label)
    local src = source
    if not plate or not weaponHash then return end

    if Trunks[plate] then
        -- Already a weapon stored
        TriggerClientEvent('weapontrunk:notify', src, 'This trunk already has a weapon!')
        return
    end

    Trunks[plate] = { weapon = weaponHash, ammo = ammo, label = label }
    TriggerClientEvent('weapontrunk:notify', src, ('Stored %s in trunk.'):format(label or "weapon"))
end)

RegisterNetEvent('weapontrunk:retrieveWeapon', function(plate)
    local src = source
    local stored = Trunks[plate]
    if not stored then
        TriggerClientEvent('weapontrunk:notify', src, 'No weapon stored in this trunk.')
        return
    end
    TriggerClientEvent('weapontrunk:giveWeaponClient', src, stored.weapon, stored.ammo, stored.label)
    Trunks[plate] = nil
end)
