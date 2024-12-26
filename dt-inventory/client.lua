function CreatePedInMenu(firstTime)
    local menuType = "FE_MENU_VERSION_EMPTY_NO_BACKGROUND"
    ActivateFrontendMenu(GetHashKey(menuType), false, -1)
    Wait(100)
    clonedPed = ClonePed(PlayerPedId(), 0, false, false)
    local x, y, z = table.unpack(GetEntityCoords(clonedPed))
    SetEntityCoords(clonedPed, x, y, z - 10)
    FreezeEntityPosition(clonedPed, true)
    N_0x4668d80430d6c299(clonedPed)
    GivePedToPauseMenu(clonedPed, 1)
    SetPauseMenuPedLighting(true)
    SetPauseMenuPedSleepState(true)
    RequestScaleformMovie("PAUSE_MP_MENU_PLAYER_MODEL")
    ReplaceHudColourWithRgba(117, 0, 0, 0, 0)
    if firstTime then
        SetPauseMenuPedSleepState(false)
        Wait(1000)
        SetPauseMenuPedSleepState(true)
    else
        SetPauseMenuPedSleepState(true)
    end
end

function DestroyPedInMenu()
    if DoesEntityExist(clonedPed) then
        DeleteEntity(clonedPed)
    end
    SetFrontendActive(false)
    ReplaceHudColourWithRgba(117, 0, 0, 0, 186)
end

RegisterCommand('openInventory', function()
    TriggerServerEvent("server:openInventory")
    SetNuiFocus(1,1)
    CreatePedInMenu(true)
end)

CreateThread(function()
    Config.blipCode.code()

    while true do 
        local ticks = 1000;
        local ped = PlayerPedId();
        local pedCoords = GetEntityCoords(ped);

        for k, v in pairs(Config.vaults) do
            DrawMarker(27, v.pos.x, v.pos.y, v.pos.z-1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 0, 0, 100, false, false, 2, 0, false, false, false)

            local distance = #(pedCoords - v.pos)
            if distance < 2.0 then
                ticks = 1;

                if IsControlJustReleased(0, Config.openVaultKey) then
                    TriggerServerEvent("server:openVault", k)
                end

            end
        end

        Wait(ticks)
    end
end)


RegisterKeyMapping('openInventory', 'Open Inventory', 'keyboard', 'I')