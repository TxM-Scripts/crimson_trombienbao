local QBCore = exports['qb-core']:GetCoreObject()
local ox_inventory = exports.ox_inventory
local Objects = {}
local syncedObjects = {}

for _, data in ipairs(Config.Objects) do
    Objects[data.key] = table.clone and table.clone(data) or data
end

local function GetCopsOnline()
    local count = 0
    for _, player in pairs(QBCore.Functions.GetQBPlayers()) do
        if player.PlayerData.job.name == "police" then
            count = count + 1
        end
    end
    return count
end

lib.callback.register('crimson_trombienbao:server:canSteal', function(src)
    if GetCopsOnline() < Config.RequiredCops then
        return false, ('Cần ít nhất %d cảnh sát trong thành phố'):format(Config.RequiredCops)
    end
    local item = ox_inventory:GetItem(src, Config.RequiredItem, false)
    if not item or (item and item.count < 1) then
        return false, ('Cần có %s mới có thể cướp'):format(Config.RequiredItem)
    end
    return true
end)

local function safeAddItem(src, item, count, meta, label)
    local ok, res = pcall(function() return ox_inventory:AddItem(src, item, count, meta) end)
    if not ok or res == false then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = ('Không thể thêm vật phẩm %s!'):format(label or item) })
        return false
    end
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = ('Bạn nhận được %dx %s'):format(count, label or item) })
    return true
end

local function safeRemoveItem(src, item, count, label)
    local ok, res = pcall(function() return ox_inventory:RemoveItem(src, item, count) end)
    if not ok or res == false then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = ('Không thể xóa vật phẩm %s!'):format(label or item) })
        return false
    end
    return true
end

-- ✅ Event báo cảnh sát khi minigame thành công
RegisterNetEvent('crimson_trombienbao:server:alertPolice', function(coords)
    for _, player in pairs(QBCore.Functions.GetQBPlayers()) do
        if player.PlayerData.job.name == "police" and player.PlayerData.job.onduty then
            local target = player.PlayerData.source

            -- Notify
            TriggerClientEvent('ox_lib:notify', target, {
                type = 'error',
                description = '🚨 Trộm biển báo'
            })

            -- Blip tạm thời
            TriggerClientEvent('crimson_trombienbao:client:addBlip', target, coords)
        end
    end
end)

RegisterNetEvent('crimson_trombienbao:server:requestSyncedObjects', function()
    local src = source
    TriggerClientEvent('crimson_trombienbao:client:addSyncedObject', src, syncedObjects)
end)

RegisterNetEvent('crimson_trombienbao:server:steal', function(id, coords)
    local src = source
    local obj = Objects[id]
    if not obj then return end

    local record = { coords = coords, model = obj.model }
    syncedObjects[#syncedObjects+1] = record

    TriggerClientEvent('crimson_trombienbao:client:addSyncedObject', -1, record)
    TriggerClientEvent('crimson_trombienbao:client:deleteObject', -1, { coords = coords, modelHash = GetHashKey(obj.model) })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Bạn đã cướp ' .. obj.label })

    -- ❌ bỏ policeAlert ở đây, vì đã báo sau minigame rồi
end)

RegisterNetEvent('crimson_trombienbao:server:receiveSign', function(id)
    local src = source
    local obj = Objects[id]
    if not obj then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Lỗi: loại biển không hợp lệ' })
    end

    safeAddItem(src, obj.item, 1, nil, obj.label)
end)

RegisterNetEvent('crimson_trombienbao:server:trade', function(id)
    local src = source
    local obj = Objects[id]
    if not obj then return end

    if not safeRemoveItem(src, obj.item, 1, obj.label) then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Bạn không có ' .. obj.label })
    end

    local totalRewards = {}
    local rolls = math.random(obj.tradeRolls.min, obj.tradeRolls.max)
    for i = 1, rolls do
        local reward = Config.Rewards[math.random(1, #Config.Rewards)]
        local amount = math.random(reward.min, reward.max)
        if safeAddItem(src, reward.item, amount, nil, reward.label) then
            totalRewards[#totalRewards+1] = ('%dx %s'):format(amount, reward.label)
        end
        Wait(200)
    end

    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Đã tái chế ' .. obj.label .. ' và nhận: ' .. table.concat(totalRewards, ', ') })
end)

exports('AddStealable', function(id, data)
    if not id or not data then return false end
    Objects[id] = data
    syncedObjects = syncedObjects or {}
    return true
end)
