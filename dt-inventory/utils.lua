RegisterNetEvent("sendNUIMessage", function(...)
    SendNUIMessage(...);
end)

RegisterNuiCallback("utils:callServerEvent", function(data)
    TriggerServerEvent(data.eventName, table.unpack(data.args));
end)

RegisterNUICallback('closeInventory', function(data, cb)
    DestroyPedInMenu();
    SetNuiFocus(0,0);
    cb('ok');
end)

RegisterNetEvent("setFocus", function(state)
    SetNuiFocus(state, state);
end)

RegisterNetEvent("utils:notify", function(message)
    print(message); -- TODO: Add notification ui
end)

for i = 1,5 do 
    RegisterCommand("fastSlot" .. i, function()
        TriggerServerEvent("server:useItemFromFastSlot", i);
    end)

    RegisterKeyMapping("fastSlot" .. i, "Fast Slot " .. i, "keyboard", i);
end

local hasItem = function(item)
    local playerInventory = LocalPlayer.state.playerInventory;
    
    for k,v in pairs(playerInventory.items) do
        if v.name == item then
            return true;
        end
    end

    return false;
end

local weapons = {};
local weaponInHand = nil;

RegisterNetEvent('inventory:useWeapon', function(weaponName)
    local ped = PlayerPedId();
    local weaponHash = GetHashKey(weaponName);

    if not hasItem(weaponName) then
        return
    end

    if weapons[weaponName] and weapons[weaponName].equipped then
        local currentAmmo = GetAmmoInPedWeapon(ped, weaponHash);

        RemoveWeaponFromPed(ped, weaponHash);
        SetCurrentPedWeapon(ped, GetHashKey('WEAPON_UNARMED'), true);
        weapons[weaponName] = {
            name = weaponName,
            ammo = currentAmmo,
            ammoType = Config.Weapons[weaponName].ammoType,
            equipped = false
        };
        weaponInHand = nil;
    else
        GiveWeaponToPed(ped, weaponHash, 0, false, true);
        SetCurrentPedWeapon(ped, weaponHash, true);
        weapons[weaponName] = {
            name = weaponName,
            ammo = 0,
            ammoType = Config.Weapons[weaponName].ammoType,
            equipped = true
        };
        weaponInHand = weaponName;
    end
end)

RegisterNetEvent('inventory:useAmmo', function(ammoType)
    if not weaponInHand then
        TriggerEvent('utils:notify', 'You need to equip a weapon first');
        return
    end

    local weaponConfig = Config.Weapons[weaponInHand];
    if not weaponConfig or weaponConfig.ammoType ~= ammoType then
        TriggerEvent('utils:notify', 'This ammo is not compatible with your weapon');
        return
    end

    SendNUIMessage({
        action = 'showAmmoSelect',
        data = {
            ammoType = ammoType,
            weaponName = weaponInHand
        }
    })
end)

RegisterNUICallback('loadAmmo', function(data, cb)
    local ammoType = data.ammoType;
    local amount = data.amount;
    local weaponHash = GetHashKey(weaponInHand);

    if weaponInHand then
        weapons[weaponInHand].ammo = amount;
        AddAmmoToPed(PlayerPedId(), weaponHash, amount);
        TriggerServerEvent('server:removeAmmo', ammoType, amount);
    end

    cb('ok');
end)

RegisterNetEvent('inventory:removeWeapon', function(weaponName)
    local weaponHash = GetHashKey(weaponName);
    local ped = PlayerPedId();
    local currentAmmo = GetAmmoInPedWeapon(ped, weaponHash);
    if currentAmmo > 0 then
        local weaponConfig = Config.Weapons[weaponName];
        TriggerServerEvent('server:addAmmo', weaponConfig.ammoType, currentAmmo);
    end

    RemoveWeaponFromPed(ped, weaponHash);
    SetCurrentPedWeapon(ped, GetHashKey('WEAPON_UNARMED'), true);
    SetPedAmmo(ped, weaponHash, 0);
    weaponInHand = nil;
    weapons[weaponName] = nil;
end)

RegisterNetEvent('utils:playerDropped', function()
    local ped = PlayerPedId();
    
    for weaponName, _ in pairs(weapons) do
        local weaponHash = GetHashKey(weaponName);
        local currentAmmo = GetAmmoInPedWeapon(ped, weaponHash);

        if currentAmmo > 0 then
            local weaponConfig = Config.Weapons[weaponName];
            TriggerServerEvent('server:addAmmo', weaponConfig.ammoType, currentAmmo);
            
            SetPedAmmo(ped, weaponHash, 0);
        end
    end
end)

CreateThread(function()
    while true do
        DisplayAmmoThisFrame(false);
        HudWeaponWheelIgnoreSelection(true);
        DisableControlAction(1, 37);

        if weaponInHand then
            local playerPed = PlayerPedId();
            local weaponHash = GetHashKey(weaponInHand);
            
            if HasPedGotWeapon(playerPed, weaponHash, false) then
                local currentAmmo = GetAmmoInPedWeapon(playerPed, weaponHash);
                if currentAmmo == 0 then
                    SetCurrentPedWeapon(playerPed, weaponHash, true);
                end
            end
        end
        
        Wait(0)
    end
end)

RegisterNetEvent("utils:dropItemAnimation", function(data)
    local ped = PlayerPedId();

    if not IsPedInAnyVehicle(ped, true) then
        RequestAnimDict("pickup_object");
        while not HasAnimDictLoaded("pickup_object") do
            Wait(10);
        end
        
        TaskPlayAnim(ped, "pickup_object", "pickup_low", 8.0, -8.0, -1, 0, 0, false, false, false);
        Wait(1200);
        ClearPedTasks(ped);
    end

    ExecuteCommand("me Drops " .. data.count .. "x " .. data.label);
end)

RegisterNetEvent("utils:useItem", function(data)
    if not hasItem(data.name) then
        return
    end

    ExecuteCommand("me Using " .. data.label);

    if data.type == 'food' then
        local ped = PlayerPedId();
        
        if not IsPedInAnyVehicle(ped, true) then
            RequestAnimDict("mp_player_inteat@burger");
            while not HasAnimDictLoaded("mp_player_inteat@burger") do
                Wait(10);
            end
            
            TaskPlayAnim(ped, "mp_player_inteat@burger", "mp_player_int_eat_burger", 8.0, -8.0, -1, 49, 0, false, false, false);
            Wait(3000);
            ClearPedTasks(ped);
        end
    -- elseif ... you can add more here
    end

end)
