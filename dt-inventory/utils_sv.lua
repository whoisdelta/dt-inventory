_G.loadData = function()
    local file = io.open(GetResourcePath(GetCurrentResourceName()).."/database/inventory.json", "r")
    if file then
        local content = file:read("*all")
        file:close()
        local data = json.decode(content) or {}
        local users = {}
        for _, k in ipairs(data) do
            if k.id then
                users[k.id] = k
            end
        end
        return users
    end
    return {}
end

_G.saveData = function()
    local file = io.open(GetResourcePath(GetCurrentResourceName()).."/database/inventory.json", "w")
    if file then
        local data = {}
        for id, k in pairs(usersData) do
            k.id = id
            table.insert(data, k)
        end
        file:write(json.encode(data))
        file:close()
    end
end

_G.loadIds = function()
    local file = io.open(GetResourcePath(GetCurrentResourceName()).."/database/ids.json", "r")
    if file then
        local content = file:read("*all")
        file:close()
        local data = json.decode(content) or {}
        local users = {}
        for _, k in ipairs(data) do
            if k.identifier then
                users[k.identifier] = k.id
            end
        end
        return users
    end
    return {}
end

_G.saveIds = function()
    local file = io.open(GetResourcePath(GetCurrentResourceName()).."/database/ids.json", "w")
    if file then
        local data = {}
        for identifier, id in pairs(usersIds) do
            table.insert(data, {
                identifier = identifier,
                id = id
            })
        end
        file:write(json.encode(data))
        file:close()
    end
end

_G.loadVaults = function()
    local file = io.open(GetResourcePath(GetCurrentResourceName()).."/database/vaults.json", "r")
    if file then
        local content = file:read("*all")
        file:close()
        
        local data = json.decode(content) or {}
        local vaults = {}
        
        for _, vault in ipairs(data) do
            if vault.name then
                vaults[vault.name] = {}
                
                if vault.users then
                    for userId, userData in pairs(vault.users) do
                        local numId = tonumber(userId)
                        if numId then
                            vaults[vault.name][numId] = {
                                items = {},
                                capacity = tonumber(userData.capacity) or 0
                            }
                            
                            if type(userData.items) == "table" then
                                for itemName, itemData in pairs(userData.items) do
                                    if type(itemData) == "table" then
                                        vaults[vault.name][numId].items[itemName] = {
                                            name = itemData.name,
                                            label = itemData.label,
                                            count = tonumber(itemData.count) or 0,
                                            weight = tonumber(itemData.weight) or 0,
                                            type = itemData.type
                                        }
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        
        return vaults
    end
    return {}
end

_G.saveVaults = function()
    local file = io.open(GetResourcePath(GetCurrentResourceName()).."/database/vaults.json", "w")
    if file then
        local data = {}
        
        for vaultName, vaultUsers in pairs(vaults) do
            local vaultData = {
                name = vaultName,
                users = {}
            }
            
            for userId, userData in pairs(vaultUsers) do
                local cleanItems = {}
                for itemName, itemData in pairs(userData.items) do
                    cleanItems[itemName] = {
                        name = itemData.name,
                        label = itemData.label,
                        count = tonumber(itemData.count) or 0,
                        weight = tonumber(itemData.weight) or 0,
                        type = itemData.type
                    }
                end
                
                vaultData.users[tostring(userId)] = {
                    items = cleanItems,
                    capacity = tonumber(userData.capacity) or 0
                }
            end
            
            table.insert(data, vaultData)
        end
        
        local jsonData = json.encode(data)
        file:write(jsonData)
        file:close()
    end
end

_G.isBlacklisted = function(eventName)
    for _, blacklistedEvent in pairs(Config.blackListedEvents) do
        if blacklistedEvent == eventName then
            return true;
        end
    end

    return false;
end

local function ensureVaultFile()
    local path = GetResourcePath(GetCurrentResourceName()).."/database/vaults.json"
    local file = io.open(path, "r")
    if not file then
        file = io.open(path, "w")
        if file then
            file:write("[]")
            file:close()
            print("Created new vaults.json file")
        end
    else
        file:close()
    end
end

CreateThread(function()
    ensureVaultFile()
end)
