Config = Config or {}

Config.usingTime = 4; -- seconds [ time between using items ]
Config.MaxDefaultCapacity = 10;
Config.blackListedEvents = {
    'codeInnit',
    'getIdentifier',
    'createUser',
    'getUserId',
    'Innit',
    'giveItem',
}

Config.Weapons = {
    ['weapon_pistol50'] = {
        label = 'Pistol 50',
        ammoType = 'ammo_pistol',
        weight = 1.0,
        type = 'weapon'
    },

    ['weapon_pistol'] = {
        label = 'Pistol',
        ammoType = 'ammo_pistol',
        weight = 1.0,
        type = 'weapon'
    },

    ['weapon_smg_mk2'] = {
        label = 'SMG MK2',
        ammoType = 'ammo_smg',
        weight = 1.0,
        type = 'weapon'
    },
}

Config.Items = {
    ['water'] = {'Apa Borsec' , 'O apa care se gaseste in orasul Borsec' , 1.0, 'food'},
    ['bread'] = {'Paine' , 'O paine care se gaseste in orasul Borsec' , 1.0, 'food'},
    ['burger'] = {'Burger' , 'Un burger care se gaseste in orasul Borsec' , 1.0, 'food'},
    ['cola'] = {'Cola' , 'O cola care se gaseste in orasul Borsec' , 1.0, 'drink'},
    ['beer'] = {'Bere' , 'O bere care se gaseste in orasul Borsec' , 1.0, 'drink'},
    ['weapon_pistol50'] = {'Pistol 50' , 'Un pistol puternic' , 1.0, 'weapon'},
    ['ammo_pistol'] = {'Gloante Pistol' , 'Munitie pentru Pistol' , 0.1, 'ammo'},
    ['weapon_pistol'] = {'Pistol' , 'Un pistol' , 1.0, 'weapon'},
    ['weapon_smg_mk2'] = {'SMG MK2' , 'Un SMG MK2' , 1.0, 'weapon'},
    ['ammo_smg'] = {'Gloante SMG' , 'Munitie pentru SMG' , 0.1, 'ammo'},
}

Config.UsableItems = {
    ['weapon_pistol50'] = function(source)
        local _src = source
        TriggerClientEvent('inventory:useWeapon', _src, 'weapon_pistol50')
    end,

    ['water'] = function(source)
        local _src = source
        TriggerClientEvent('inventory:useItem', _src, 'water')
    end,

    ['weapon_pistol'] = function(source)
        local _src = source
        TriggerClientEvent('inventory:useWeapon', _src, 'weapon_pistol')
    end,

    ['ammo_pistol'] = function(source)
        local _src = source
        TriggerClientEvent('inventory:useAmmo', _src, 'ammo_pistol')
    end,

    ['weapon_smg_mk2'] = function(source)
        local _src = source
        TriggerClientEvent('inventory:useWeapon', _src, 'weapon_smg_mk2')
    end,

    ['ammo_smg'] = function(source)
        local _src = source
        TriggerClientEvent('inventory:useAmmo', _src, 'ammo_smg')
    end,
}

Config.openVaultKey = 38; -- [E]
Config.vaults = {
    ['Groove Street'] = {
        maxCapacity = 100,
        
        pos = vec3(323.38162231445,-703.00427246094,29.234935760498),
    },
}

Config.descs = {
    ['vault'] = 'Here you can store your items',
}

Config.blipCode = {
    ['code'] = function()
        for k,v in pairs(Config.vaults) do
            local blip = AddBlipForCoord(v.pos.x, v.pos.y, v.pos.z)
            SetBlipSprite(blip, 568)
            SetBlipScale(blip, 0.7)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Deposit")
            EndTextCommandSetBlipName(blip)
        end
    end,
}

Config.Admins = {
    ['669062bf6d395c950a5b861119e827cb566220d8'] = true
}

Config.Commands = {
    ['giveItem'] = function(source, args)
        local _src <const> = source;
        local item = args[1];
        local amount = tonumber(args[2]);
        local isAdmin = Inventory:isAdmin(_src, Inventory:getUserLicence(_src));
    
        if not isAdmin then 
            return TriggerClientEvent("utils:notify", _src, 'You are not an admin');
        end
    
        Inventory:giveItem(_src, item, amount);
    end,

    ['getIdentifierFromId' ] = function(source, args)
        local _src <const> = source;
        local id = args[1];
        if not id then return TriggerClientEvent("utils:notify", _src, 'No id provided'); end
    
        local isAdmin = Inventory:isAdmin(_src, Inventory:getUserLicence(_src));
    
        if not isAdmin then 
            return TriggerClientEvent("utils:notify", _src, 'You are not an admin');
        end
    
        for k,v in pairs(usersIds) do
            if v == tonumber(id) then
                identifierFound = true;
                TriggerClientEvent("sendNUIMessage", _src, {
                    action = "copyToClipboard",
                    data = {
                        text = k
                    }
                })
            end
        end
    end
}