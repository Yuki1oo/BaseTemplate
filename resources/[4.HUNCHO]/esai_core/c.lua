-------NORAGDOLL + CONTROLES--------
------------------------------------

-- Hot locals
local PlayerId, PlayerPedId = PlayerId, PlayerPedId
local GetVehiclePedIsIn, IsPedInAnyVehicle = GetVehiclePedIsIn, IsPedInAnyVehicle
local GetEntitySpeed = GetEntitySpeed
local DisableControlAction = DisableControlAction
local SetPlayerCanDoDriveBy = SetPlayerCanDoDriveBy
local Wait = Wait

-- =============================================================
-- THREAD PRINCIPAL : Regroupe NoRagdoll + Controles a pied + Vehicule
-- Un seul thread Wait(0) au lieu de deux (economie CPU)
-- =============================================================
local MAX_SPEED = -1.0

Citizen.CreateThread(function()
    local wasFalling = false

    while true do
        Wait(0)
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)

        -- 1. Natives "ThisFrame" obligatoires
        SetWeaponDamageModifierThisFrame(-842959696, 0.0)

        -- 2. Anti pistol whip (a pied, arme en main)
        if IsPedArmed(ped, 6) then
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
        end

        -- 3. Blocage tir en vehicule
        if veh ~= 0 then
            local block = true

            if MAX_SPEED >= 0.0 then
                local speedKmh = GetEntitySpeed(veh) * 3.6
                block = (speedKmh > MAX_SPEED)
            end

            if block then
                SetPlayerCanDoDriveBy(PlayerId(), false)

                DisableControlAction(0, 24,  true)
                DisableControlAction(0, 25,  true)
                DisableControlAction(0, 68,  true)
                DisableControlAction(0, 69,  true)
                DisableControlAction(0, 70,  true)
                DisableControlAction(0, 92,  true)

                DisableControlAction(0, 157, true)
                DisableControlAction(0, 158, true)
                DisableControlAction(0, 159, true)
                DisableControlAction(0, 160, true)

                DisableControlAction(0, 114, true)
                DisableControlAction(0, 257, true)
                DisableControlAction(0, 331, true)
            end
        end

        -- 4. Ragdoll + detection de chute (pas besoin de chaque frame, mais
        --    on profite du thread existant pour eviter un thread supplementaire)
        if not IsEntityDead(ped) then
            local parachuteState = GetPedParachuteState(ped)
            local isInParachute = parachuteState ~= -1
            local hasParaglider = IsPedFalling(ped) and GetSelectedPedWeapon(ped) == `WEAPON_PARACHUTE`
            if isInParachute or hasParaglider then
                SetPedCanRagdoll(ped, true)
            else
                SetPedCanRagdoll(ped, false)
            end

            local parachuteActive = parachuteState ~= -1
            local isFalling = IsPedFalling(ped)
            if wasFalling and not isFalling then
                if not parachuteActive and not IsPedSwimming(ped) and not IsPedClimbing(ped) then
                    ClearPedTasksImmediately(ped)
                end
            end
            wasFalling = isFalling
        end
    end
end)

-- =============================================================
-- Thread lent : Pas de casque sur moto / velo (Wait 750)
-- =============================================================
CreateThread(function()
    local lastIsOnBike = nil

    while true do
        Wait(750)

        local ped = PlayerPedId()
        local isOnBike = false

        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= 0 then
                local model = GetEntityModel(veh)
                isOnBike = IsThisModelABike(model) or IsThisModelABicycle(model)
            end
        end

        if isOnBike ~= lastIsOnBike then
            lastIsOnBike = isOnBike

            if isOnBike then
                SetPedHelmet(ped, false)
                RemovePedHelmet(ped, true)
                ClearPedProp(ped, 0)
            else
                SetPedHelmet(ped, true)
            end
        end
    end
end)

-- =============================================================
-- Suppression des pompes a essence (intervalle augmente a 5s)
-- =============================================================
local Config = {
    deleteRadius = 300.0,
    checkInterval = 5000,
}

local deletedPumpsThisSession = {}

local PUMP_MODELS = {
    `prop_gas_pump_1a`,
    `prop_gas_pump_1b`,
    `prop_gas_pump_1c`,
    `prop_gas_pump_1d`,
    `prop_vintage_pump`,
    `prop_gas_pump_old2`,
    `prop_gas_pump_old3`,
}

local PUMP_SET = {}
for _, m in ipairs(PUMP_MODELS) do PUMP_SET[m] = true end

local function IsPump(entity)
    if not DoesEntityExist(entity) then return false end
    return PUMP_SET[GetEntityModel(entity)] == true
end

local function DeletePump(pump)
    if not DoesEntityExist(pump) then return end
    if deletedPumpsThisSession[pump] then return end

    SetEntityAsMissionEntity(pump, true, true)
    DeleteEntity(pump)

    deletedPumpsThisSession[pump] = true
end

CreateThread(function()
    while true do
        Wait(Config.checkInterval)

        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local objects = GetGamePool('CObject')

        for _, obj in ipairs(objects) do
            if DoesEntityExist(obj) and #(playerCoords - GetEntityCoords(obj)) < Config.deleteRadius then
                if IsPump(obj) then
                    DeletePump(obj)
                end
            end
        end
    end
end)

AddEventHandler('entityCreated', function(entity)
    Wait(100)
    if DoesEntityExist(entity) and IsPump(entity) then
        DeletePump(entity)
    end
end)


-- =============================================================
-- Appliquer les dommages uniquement par balle
-- Appele une fois au spawn + fallback toutes les 10s
-- =============================================================
local function applyOnlyBulletDamage(ped)
    SetEntityProofs(ped,
        false, -- bulletProof
        true,  -- fireProof
        true,  -- explosionProof
        true,  -- collisionProof
        false, -- meleeProof
        true,  -- steamProof
        true,  -- drownProof
        false,
        false
    )
end

-- Application immediate + fallback lent
CreateThread(function()
    -- Attendre que le ped soit charge
    while PlayerPedId() == 0 do Wait(100) end
    applyOnlyBulletDamage(PlayerPedId())

    while true do
        Wait(10000)
        local ped = PlayerPedId()
        if ped ~= 0 then
            applyOnlyBulletDamage(ped)
        end
    end
end)

-- Re-appliquer apres respawn/revive
AddEventHandler('playerSpawned', function()
    Wait(500)
    local ped = PlayerPedId()
    if ped ~= 0 then applyOnlyBulletDamage(ped) end
end)
