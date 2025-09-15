local SignManager = {}
SignManager.__index = SignManager

function SignManager:new()
    local self = setmetatable({}, SignManager)
    self.Objects = {}
    self.mapObjects = {}
    self.heldProp = nil
    self.isHolding = false
    self.currentSignId = nil
    return self
end

function SignManager:init()
    for _, d in ipairs(Config.Objects) do
        self.Objects[d.key] = {
            id = d.key, label = d.label, modelName = d.model, modelHash = GetHashKey(d.model),
            propName = d.prop, item = d.item, stealTime = d.stealTime or 6000,
            tradeRolls = d.tradeRolls or {min=2,max=4}
        }
    end
    self:registerTargets()
    TriggerServerEvent('crimson_trombienbao:server:requestSyncedObjects')
    exports.ox_target:addBoxZone({
        coords = Config.ScrapZone.coords,
        size = Config.ScrapZone.size,
        rotation = Config.ScrapZone.rotation,
        debug = false,
        options = {{
            name = 'sign_scrap',
            event = 'crimson_trombienbao:client:openTradeMenu',
            icon = 'fas fa-recycle',
            label = 'Tái chế / Đổi biển'
        }}
    })
end

local function loadModel(modelHash)
    if not HasModelLoaded(modelHash) then
        RequestModel(modelHash)
        local t0 = GetGameTimer()
        while not HasModelLoaded(modelHash) do
            Wait(10)
            if GetGameTimer() - t0 > 10000 then break end
        end
    end
end

local function loadAnim(dict, timeout)
    RequestAnimDict(dict)
    local t0 = GetGameTimer()
    while not HasAnimDictLoaded(dict) do
        Wait(10)
        if GetGameTimer() - t0 > (timeout or 5000) then break end
    end
end

function SignManager:attachProp(propName)
    if self.isHolding then return end
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local propHash = GetHashKey(propName)
    loadModel(propHash)

    self.heldProp = CreateObject(propHash, coords.x, coords.y, coords.z+0.2, true, true, true)
    AttachEntityToEntity(self.heldProp, ped, GetPedBoneIndex(ped,57005),
        0.1,-1.0,0.0,-90.0,-250.0,0.0,true,true,false,true,1,true)
    SetModelAsNoLongerNeeded(propHash)
    loadAnim("amb@world_human_janitor@male@base")
    TaskPlayAnim(ped,"amb@world_human_janitor@male@base","base",4.0,-4.0,-1,49,0,false,false,false)
    self.isHolding = true
end

function SignManager:detachProp()
    if self.heldProp and DoesEntityExist(self.heldProp) then
        DeleteObject(self.heldProp)
        self.heldProp = nil
    end
    ClearPedSecondaryTask(PlayerPedId())
    self.isHolding = false
end

function SignManager:registerTargets()
    for id, obj in pairs(self.Objects) do
        exports.ox_target:addModel(obj.modelHash, {{
            name = "steal_"..id,
            event = "crimson_trombienbao:client:attemptSteal",
            icon = Config.Target.icon,
            label = obj.label,
        }})
    end
end

function SignManager:findObjectByModelHash(hash)
    for _,v in pairs(self.Objects) do
        if v.modelHash == hash then return v end
    end
    return nil
end

function SignManager:steal(ent)
    if IsPedInAnyVehicle(PlayerPedId(), false) then
        return lib.notify({description="Không thể cướp trong xe", type="error"})
    end
    local model = GetEntityModel(ent)
    local obj = self:findObjectByModelHash(model)
    if not obj then
        return lib.notify({description="Không thể cướp vật này", type="error"})
    end
    local INJURY_CHANCE, INJURY_DAMAGE = 30, 15
    lib.callback('crimson_trombienbao:server:canSteal', false, function(can, reason)
        if not can then 
            return lib.notify({description=reason, type="error"}) 
        end
        local success = exports["bd-minigames"]:Chopping(5, 20)
        if not success then
            if math.random(100) <= INJURY_CHANCE then
                local ped = PlayerPedId()
                SetEntityHealth(ped, math.max(0, GetEntityHealth(ped) - INJURY_DAMAGE))
            end
            return
        end
        local coords = GetEntityCoords(ent)
        TriggerServerEvent('crimson_trombienbao:server:alertPolice', coords)
        loadAnim('veh@break_in@0h@p_m_one@')
        local prog = lib.progressCircle({
            duration = obj.stealTime,
            position = 'bottom',
            useWhileDead = false,
            canCancel = false,
            disable = {move = true, car = true},
            anim = {dict = 'veh@break_in@0h@p_m_one@', clip = 'low_force_entry_ds'},
            label = "Đang cướp "..obj.label.."...",
        })

        if not prog then 
            return lib.notify({description="Bạn đã dừng lại", type="error"}) 
        end
        TriggerServerEvent('crimson_trombienbao:server:steal', obj.id, coords)
        self:attachProp(obj.propName)
        self.currentSignId = obj.id
        lib.notify({description="Bạn đang cầm "..obj.label..". Nhấn [E] để phi tang", type="inform"})
    end)
end


function SignManager:dispose()
    if not self.isHolding or not self.currentSignId then
        return lib.notify({title="Phi tang", description="Bạn không cầm biển nào", type="error"})
    end

    if IsPedInAnyVehicle(PlayerPedId(), false) then
        return lib.notify({title="Phi tang", description="Không thể phi tang khi trong xe", type="error"})
    end
    loadAnim("weapons@misc@dynamite@", 5000)
    TaskPlayAnim(PlayerPedId(), "weapons@misc@dynamite@", "throw", 4.0, -4.0, 2000, 48, 0, false, false, false)

    local success = lib.progressCircle({
        duration = 3000,
        position = 'bottom',
        disable = {move=true, car=true},
        canCancel = false,
        label = "Đang phi tang biển..."
    })

    if not success then
        ClearPedTasks(PlayerPedId())
        return lib.notify({title="Phi tang", description="Bạn đã dừng lại", type="error"})
    end
    self:detachProp()
    TriggerServerEvent("crimson_trombienbao:server:receiveSign", self.currentSignId)
    self.currentSignId = nil
end


Sign = SignManager:new()
Sign:init()

RegisterNetEvent('crimson_trombienbao:client:attemptSteal', function(data)
    if data and data.entity then Sign:steal(data.entity) end
end)

RegisterNetEvent('crimson_trombienbao:client:addSyncedObject', function(obj)
    if not obj then return end
    local objs = type(obj)=="table" and (#obj>0 and obj or {obj}) or {obj}
    for _,v in ipairs(objs) do
        if v.coords and v.model then
            v.modelHash = GetHashKey(v.model)
            table.insert(Sign.mapObjects,v)
        end
    end
end)

RegisterNetEvent('crimson_trombienbao:client:deleteObject', function(object)
    if not object or not object.coords or not object.modelHash then return end
    local ent = GetClosestObjectOfType(object.coords.x,object.coords.y,object.coords.z,1.5,object.modelHash,false,false,false)
    if DoesEntityExist(ent) then
        SetEntityAsMissionEntity(ent,true,true)
        DeleteObject(ent)
        SetEntityAsNoLongerNeeded(ent)
    end
end)

RegisterNetEvent('crimson_trombienbao:client:openTradeMenu', function()
    local options = {}
    for _,obj in pairs(Sign.Objects) do
        options[#options+1] = {
            title=obj.label,
            description="Tái chế "..obj.label.." lấy vật liệu",
            event="crimson_trombienbao:server:trade",
            args=obj.id
        }
    end
    options[#options+1] = {title="Đóng",event="crimson_trombienbao:client:closeTradeMenu"}
    lib.registerContext({id="crimson_sign_scrap",title="Tái chế Biển Báo",description="Đổi biển lấy vật liệu",options=options})
    lib.showContext("crimson_sign_scrap")
end)
RegisterNetEvent('crimson_trombienbao:client:closeTradeMenu',function() lib.hideContext(true) end)
RegisterNetEvent('crimson_trombienbao:client:addBlip', function(coords)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 161)
    SetBlipScale(blip, 1.2)
    SetBlipColour(blip, 1)
    SetBlipFlashes(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Trộm biển báo")
    EndTextCommandSetBlipName(blip)
    SetTimeout(60000, function()
        RemoveBlip(blip)
    end)
end)

CreateThread(function()
    local showing = false
    while true do
        Wait(1)
        if Sign.isHolding then
            if not showing then
                lib.showTextUI("[E] Phi tang", { position = "right-center" })
                showing = true
            end
            if IsControlJustPressed(0, 38) then
                Sign:dispose()
            end
        else
            if showing then
                lib.hideTextUI()
                showing = false
            end
            Wait(250)
        end
    end
end)

CreateThread(function()
    while true do
        if #Sign.mapObjects > 0 then
            for i = #Sign.mapObjects, 1, -1 do
                local v = Sign.mapObjects[i]
                if v and v.coords and v.modelHash then
                    if not (Sign.isHolding and Sign.currentSignId and v.id == Sign.currentSignId) then
                        local ent = GetClosestObjectOfType(v.coords.x, v.coords.y, v.coords.z, 0.8, v.modelHash, false, false, false)
                        if DoesEntityExist(ent) and ent ~= Sign.heldProp then
                            SetEntityAsMissionEntity(ent, true, true)
                            DeleteObject(ent)
                            SetEntityAsNoLongerNeeded(ent)
                        end
                        table.remove(Sign.mapObjects, i)
                    end
                else
                    table.remove(Sign.mapObjects, i)
                end
            end
            Wait(1000)
        else
            Wait(2000)
        end
    end
end)

