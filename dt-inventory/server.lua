_G.usersData = {};
_G.usersIds = {};
_G.vaults = {};
_G.usersData = loadData();
_G.usersIds = loadIds();
_G.vaults = loadVaults();

Inventory = {
    codeInnit = function(self)
        setmetatable(Inventory, {
            __index = function(table, index)
                return print("[DT-INVENTORY] --> Method " .. index .. " not found.");
            end
        })

        print("[DT-INVENTORY] --> Code init done. For any help contact support.");
    end,

    getIdentifier = function(self, source)
        local identifiers = GetPlayerIdentifiers(source)
        for _, v in pairs(identifiers) do
            if string.find(v, "license:") then
                return string.sub(v, 9) 
            end
        end
        return nil
    end,

    createUser = function(self, source)
        local _src <const> = source;
        local identifier = self:getIdentifier(_src);

        if not identifier then
            TriggerClientEvent("utils:notify", _src, 'Failed to get identifier contact support');
            return;
        end

        if not usersIds[identifier] then
            usersIds[identifier] = #usersIds + 1;
        end

        saveIds();
    end,

    getUserId = function(self, source)
        local _src <const> = source;
        local identifier = self:getIdentifier(_src);

        return usersIds[identifier];
    end,

    Innit = function(self, source)
        local _src <const> = source;

        if not usersIds[self:getIdentifier(_src)] then
            self:createUser(_src);
        end

        usersData[self:getUserId(_src)] = {
            items = {},
            fastSlots = {},
            maxCapacity = Config.MaxDefaultCapacity,
            capacity = 0,
        }
    end,

    refreshInventory = function(self, source)
        local _src <const> = source;
        local userId = self:getUserId(_src);

        TriggerClientEvent("sendNUIMessage", _src, {
            action = "refreshInventory",
            data = usersData[userId]
        })

        Player(_src).state:set("playerInventory", usersData[userId], true)
    end,

    refreshVault = function(self, source, vaultName)
        local _src <const> = source;
        local userId = self:getUserId(_src);

        TriggerClientEvent("sendNUIMessage", _src, {
            action = "refreshVault",
            data = {
                items = vaults[vaultName][userId].items,
                capacity = vaults[vaultName][userId].capacity,
                maxCapacity = Config.vaults[vaultName].maxCapacity,
                currentVaultName = vaultName,
                rightSide = {
                    name = 'Vault ' .. vaultName,
                    desc = Config.descs['vault']
                }
            }
        })
    end,

    giveItem = function(self, source, item, amount, notify)
        local _src <const> = source;
        local userId = self:getUserId(_src);
        local itemData = Config.Items[item];

        if not itemData then
            TriggerClientEvent("utils:notify", _src, 'Item not found in config contact support');
            return;
        end

        local newWeight = itemData[3] * amount;
        if usersData[userId].capacity + newWeight > usersData[userId].maxCapacity then
            TriggerClientEvent("utils:notify", _src, 'You dont have enough capacity in your inventory');
            return;
        end

        if self:hasItem(_src, item) then
            usersData[userId].items[item].count = usersData[userId].items[item].count + amount;
        else
            usersData[userId].items[item] = {
                name = item,
                label = itemData[1],
                count = amount,
                weight = itemData[3],
                type = itemData[4] or 'all',
                usable = itemData[4] ~= 'weapon' and Config.UsableItems[item] and true or false
            }
        end

        if notify then 
            TriggerClientEvent("utils:notify", _src, 'You have received ' .. amount .. 'x ' .. itemData[1]);
        end
        
        usersData[userId].capacity = usersData[userId].capacity + newWeight;

        self:refreshInventory(_src);
        saveData();
    end,

    openInventory = function(self, source)
        local _src <const> = source;
        local playerPed = GetPlayerPed(_src);
        local playerHealth = GetEntityHealth(playerPed);
        local id = self:getUserId(_src);
    
        if playerHealth <= 0 then
            TriggerClientEvent("utils:notify", _src, 'Cant open inventory while dead');
            return;
        end
    
        if not id then 
            self:Innit(_src);

            id = self:getUserId(_src);
        end
    
        TriggerClientEvent("sendNUIMessage", _src, {
            action = "openMenu",
            data = usersData[id]
        })

        Player(_src).state:set("playerInventory", usersData[id], true)

        saveData();
    end,

    hasItem = function(self, source, item)
        local _src <const> = source;
        local userId = self:getUserId(_src);

        return usersData[userId].items[item] ~= nil;
    end,

    getItemAmmount = function(self, source , item)
        local _src <const> = source;
        local userId = self:getUserId(_src);

        if self:hasItem(_src, item) then
            return usersData[userId].items[item].count;
        end

        return 0;
    end,

    isItemInFastSlot = function(self, source, item)
        local _src <const> = source;
        local userId = self:getUserId(_src);

        for slot, itemData in pairs(usersData[userId].fastSlots) do
            if itemData.name == item then
                return slot;
            end
        end

        return false;
    end,

    dropItem = function(self, source, item, amount, animation)
        local _src <const> = source;
        local userId = self:getUserId(_src);

        if amount > usersData[userId].items[item].count then
            TriggerClientEvent("utils:notify", _src, 'You dont have enough ' .. item .. ' in your inventory');
            return false;
        end
        
        local weightReduction = usersData[userId].items[item].weight * amount;
        usersData[userId].capacity = usersData[userId].capacity - weightReduction;
        
        usersData[userId].items[item].count = usersData[userId].items[item].count - amount;
        
        if usersData[userId].items[item].count <= 0 then
            usersData[userId].items[item] = nil;
            if self:isItemInFastSlot(_src, item) then
                usersData[userId].fastSlots[self:isItemInFastSlot(_src, item)] = nil;
            end
        end

        if animation then
            TriggerClientEvent("utils:dropItemAnimation", _src, {
                count = amount,
                label = item
            })
        end

        self:refreshInventory(_src);
        saveData();

        return true;
    end,

    useItem = function(self, source, item)
        local _src <const> = source;
        local userId = self:getUserId(_src);
        local itemData = Config.UsableItems[item];

        if not itemData then
            TriggerClientEvent("utils:notify", _src, 'Item not found in config contact support');
            return;
        end
        
        if not self:hasItem(_src, item) then
            TriggerClientEvent("utils:notify", _src, 'Item not found in inventory');
            return;
        end

        if not usersData[userId].lastItemUse then
            usersData[userId].lastItemUse = 0;
        end

        local currentTime = os.time();

        if currentTime < usersData[userId].lastItemUse then
            TriggerClientEvent("utils:notify", _src, 'You have to wait ' .. usersData[userId].lastItemUse - currentTime .. ' seconds before using this item again');
            return;
        end

        Config.UsableItems[item](_src);
        usersData[userId].lastItemUse = currentTime + Config.usingTime;

        TriggerClientEvent("utils:useItem", _src, usersData[userId].items[item])

        self:refreshInventory(_src);
        saveData();
    end,

    giveItemToPlayer = function(self, source, item, amount)
        local _src <const> = source;
        local playerPed = GetPlayerPed(_src)
        local playerCoords = GetEntityCoords(playerPed)

        if amount > self:getItemAmmount(_src, item.name) then
            TriggerClientEvent("utils:notify", _src, 'You dont have enough ' .. item.name .. ' in your inventory');
            return;
        end
        
        local closestPlayer = nil
        local closestDistance = math.huge
        
        local players = GetPlayers()
        for _, player in ipairs(players) do
            if tonumber(player) ~= _src then
                local targetPed = GetPlayerPed(player)
                local targetCoords = GetEntityCoords(targetPed)
                local distance = #(playerCoords - targetCoords)
                
                if distance < closestDistance then
                    closestPlayer = tonumber(player)
                    closestDistance = distance
                end
            end
        end

        if closestPlayer and closestDistance <= 1.5 then
            if self:dropItem(_src, item.name, amount, false) then
                self:giveItem(closestPlayer, item.name, amount)
                
                self:refreshInventory(closestPlayer)
                self:refreshInventory(_src)
        
                TriggerClientEvent("utils:notify", closestPlayer, 'You have received ' .. amount .. 'x ' .. item.name .. ' from ' .. GetPlayerName(_src))
                TriggerClientEvent("utils:notify", _src, 'You have given ' .. amount .. 'x ' .. item.name .. ' to ' .. GetPlayerName(closestPlayer))
            end
        else
            TriggerClientEvent("utils:notify", _src, 'No player found near you')
        end

        self:refreshInventory(_src);
        saveData();
    end,

    removeItem = function(self, source, item)
        local _src <const> = source;
        local userId = self:getUserId(_src);

        usersData[userId].items[item] = nil;

        self:refreshInventory(_src);
        saveData();
    end,

    removeItemFromFastSlot = function(self, source, slot , item)
        local _src <const> = source;
        local userId = self:getUserId(_src);
    
        if usersData[userId].fastSlots[slot] and usersData[userId].fastSlots[slot].name == item.name then
            if item.type == 'weapon' then
                TriggerClientEvent('inventory:removeWeapon', _src, item.name)
            end

            usersData[userId].fastSlots[slot] = nil;
        end
    
        saveData();
        self:refreshInventory(_src);
    end, 

    useItemFromFastSlot = function(self, source , slot)
        local _src <const> = source;
        local userId = self:getUserId(_src);

        if not usersData[userId].fastSlots[slot] then
            TriggerClientEvent("utils:notify", _src, 'Fast slot ' .. slot .. ' is empty');
            return;
        end
    
        self:useItem(_src, usersData[userId].fastSlots[slot].name);
    
        saveData();
        self:refreshInventory(_src);
    end,

    setFastSlot = function(self, source, slot, item)
        local _src <const> = source;
        local userId = self:getUserId(_src);

        if not self:hasItem(_src, item.name) then
            print('Hacker detected ' .. item.name .. ' not in inventory, name : ' .. GetPlayerName(_src) .. ' source : ' .. _src);
            return;
        end

        if item.type == 'ammo' then
            return TriggerClientEvent("utils:notify", _src, 'You cannot add ammo to fast slot');
        end

        if not self:isItemInFastSlot(_src, item.name) then
            if usersData[userId].items[item.name] then
                usersData[userId].fastSlots[slot] = item;
            end
        
            saveData();
            self:refreshInventory(_src);
        else
            TriggerClientEvent("utils:notify", _src, 'Item already in fast slot');
        end
    end,

    openVault = function(self, source, vaultName)
        local _src <const> = source;
        local userId = self:getUserId(_src);
        local vaultData = Config.vaults[vaultName];

        if not vaultData then
            TriggerClientEvent("utils:notify", _src, 'Vault not found');
            return;
        end

        if not vaults[vaultName] then
            vaults[vaultName] = {}
        end

        if not vaults[vaultName][userId] then 
            vaults[vaultName][userId] = {
                capacity = 0,
                items = {}
            }
        end

        local userVaultData = vaults[vaultName][userId];

        self:openInventory(_src);
        TriggerClientEvent("setFocus", _src, true)
        TriggerClientEvent("sendNUIMessage", _src, {
            action = "openVault",
            data = {
                maxCapacity = vaultData.maxCapacity,
                capacity = userVaultData.capacity,
                items = userVaultData.items,
                currentVaultName = vaultName,
                userData = usersData[userId],
                active = true,
                rightSide = {
                    name = 'Vault ' .. vaultName,
                    desc = Config.descs['vault']
                }
            }
        })
    end,

    giveItemToVault = function(self, source, item, amount, vaultName)
        local _src <const> = source;
        local userId = self:getUserId(_src);
        local vaultData = Config.vaults[vaultName];

        if not vaultData then
            TriggerClientEvent("utils:notify", _src, 'Vault not found');
            return;
        end

        if amount > self:getItemAmmount(_src, item.name) then
            TriggerClientEvent("utils:notify", _src, 'You dont have enough ' .. item.name .. ' in your inventory');
            return;
        end

        if not self:hasItem(_src, item.name) then
            TriggerClientEvent("utils:notify", _src, 'You dont have this item');
            return;
        end

        if not vaults[vaultName] then
            vaults[vaultName] = {}
        end

        if not vaults[vaultName][userId] then 
            vaults[vaultName][userId] = {
                capacity = 0,
                items = {}
            }
        end

        local userVaultData = vaults[vaultName][userId];

        local newWeight = item.weight * amount;
        if userVaultData.capacity + newWeight > vaultData.maxCapacity then
            TriggerClientEvent("utils:notify", _src, 'Vault is full');
            return;
        end

        if not self:dropItem(_src, item.name, amount, false) then
            return;
        end

        if not userVaultData.items[item.name] then
            userVaultData.items[item.name] = {
                name = item.name,
                label = item.label,
                count = amount,
                weight = item.weight,
                type = item.type
            }
        else
            userVaultData.items[item.name].count = userVaultData.items[item.name].count + amount;
        end

        userVaultData.capacity = userVaultData.capacity + newWeight;

        self:refreshInventory(_src);
        self:refreshVault(_src, vaultName);

        saveVaults();
        saveData();
    end,

    moveItemFromVault = function(self, source, item, amount, vaultName)
        local _src <const> = source;
        local userId = self:getUserId(_src);
        local vaultData = Config.vaults[vaultName];

        if not vaultData then
            TriggerClientEvent("utils:notify", _src, 'Vault not found');
            return;
        end

        local userVaultData = vaults[vaultName][userId];

        if not userVaultData.items[item.name] then
            TriggerClientEvent("utils:notify", _src, 'You dont have this item in vault');
            return;
        end

        if amount > userVaultData.items[item.name].count then
            TriggerClientEvent("utils:notify", _src, 'You dont have enough ' .. item.name .. ' in your vault');
            return;
        end

        userVaultData.items[item.name].count = userVaultData.items[item.name].count - amount;

        if userVaultData.items[item.name].count <= 0 then
            userVaultData.items[item.name] = nil;
        end

        userVaultData.capacity = userVaultData.capacity - item.weight * amount;

        self:giveItem(_src, item.name, amount);

        self:refreshInventory(_src);
        self:refreshVault(_src, vaultName);

        saveVaults();
        saveData();
    end,

    removeItemFromVault = function(self, source, item, amount, vaultName)
        local _src <const> = source;
        local userId = self:getUserId(_src);
        local vaultData = Config.vaults[vaultName];

        if not vaultData then
            TriggerClientEvent("utils:notify", _src, 'Vault not found');
            return;
        end

        if not self:hasItem(_src, item.name) then
            TriggerClientEvent("utils:notify", _src, 'You dont have this item in your vault');
            return;
        end

        if amount > self:getItemAmmount(_src, item.name) then
            TriggerClientEvent("utils:notify", _src, 'You dont have enough ' .. item.name .. ' in your inventory');
            return;
        end

        if not vaults[vaultName] then
            vaults[vaultName] = {}
        end

        if not vaults[vaultName][userId] then
            vaults[vaultName][userId] = {
                capacity = 0,
                items = {},
            }
        end

        local userVaultData = vaults[vaultName][userId];

        userVaultData.items[item.name].count = userVaultData.items[item.name].count - amount;

        if userVaultData.items[item.name].count <= 0 then
            userVaultData.items[item.name] = nil;
        end

        userVaultData.capacity = userVaultData.capacity - item.weight * amount;

        self:giveItem(_src, item.name, amount);

        self:refreshInventory(_src);
        self:refreshVault(_src, vaultName);

        saveVaults();
        saveData();
    end,

    useAmmo = function(self, source, ammoType, amount)
        local _src = source
        local userId = self:getUserId(_src)
        
        if not self:hasItem(_src, ammoType) then
            TriggerClientEvent("utils:notify", _src, 'You dont have this ammo type')
            return false
        end

        local ammoCount = self:getItemAmmount(_src, ammoType)
        if ammoCount < amount then
            TriggerClientEvent("utils:notify", _src, 'Not enough ammo')
            return false
        end

        usersData[userId].items[ammoType].count = usersData[userId].items[ammoType].count - amount;
        usersData[userId].capacity = usersData[userId].capacity - Config.Items[ammoType][3] * amount;

        self:refreshInventory(_src)
        saveData();
        return true
    end,

    removeAmmo = function(self, source, ammoType, amount)
        local _src <const> = source;
        local userId = self:getUserId(_src);

        if not self:hasItem(_src, ammoType) then
            TriggerClientEvent("utils:notify", _src, 'You dont have this ammo type')
            return false
        end

        if self:getItemAmmount(_src, ammoType) < amount then
            TriggerClientEvent("utils:notify", _src, 'Not enough ammo')
            return false
        end

        usersData[userId].items[ammoType].count = usersData[userId].items[ammoType].count - amount;
        usersData[userId].capacity = usersData[userId].capacity - Config.Items[ammoType][3] * amount;

        if usersData[userId].items[ammoType].count <= 0 then
            usersData[userId].items[ammoType] = nil;
        end

        self:refreshInventory(_src)
        saveData();
    end,

    addAmmo = function(self, source, ammoType, amount)
        local _src <const> = source;
        local userId = self:getUserId(_src);

        if not usersData[userId].items[ammoType] then
            usersData[userId].items[ammoType] = {
                name = ammoType,
                label = Config.Items[ammoType][1],
                count = amount,
                weight = Config.Items[ammoType][3],
                type = 'ammo',
                usable = true
            }
        else
            usersData[userId].items[ammoType].count = usersData[userId].items[ammoType].count + amount;
            usersData[userId].capacity = usersData[userId].capacity + Config.Items[ammoType][3] * amount;
        end

        self:refreshInventory(_src);
        saveData();
    end,

    isAdmin = function(self, source, licence)
        local _src <const> = source;

        return Config.Admins[licence] or false;
    end,

    getUserLicence = function(self , source)
        local _src <const> = source;
        local userId = self:getUserId(_src);

        for k,v in pairs(usersIds) do 
            if v == userId then
                return k;
            end
        end

        return nil;
    end,

    getUserItems = function(self, source)
        local _src <const> = source;
        local userId = self:getUserId(_src);

        return usersData[userId].items;
    end,

    getPlayersInRadius = function(self, source, radius)
        local _src <const> = source;
        local userId = self:getUserId(_src);

        local players = {};
        
        local sourceCoords = GetEntityCoords(GetPlayerPed(_src));
        
        for _, player in ipairs(GetPlayers()) do
            if tonumber(player) ~= _src then
                local targetCoords = GetEntityCoords(GetPlayerPed(player));
                
                if #(sourceCoords - targetCoords) <= radius then
                    players[player] = self:getUserId(player);
                end
            end
        end

        return players;
    end
}

Inventory:codeInnit();

for eventName, callback in pairs(Inventory) do
    if isBlacklisted(eventName) then
        goto continue;
    end

    RegisterServerEvent("server:" .. eventName, function(...)
        local _src <const> = source;
        callback(Inventory, _src, ...);
    end);

    ::continue::
end

for k,v in pairs(Config.Commands) do
    RegisterCommand(k, function(source, args)
        v(source, args);
    end)
end

AddEventHandler('playerDropped', function()
    local _src = source;
    local userId = Inventory:getUserId(_src);

    TriggerClientEvent('utils:playerDropped', _src);
end)

exports('getInventory', Inventory)