--[[
    ai_medic.lua  --  esx_ambulancejob addon for ESX-Legacy-Addons

    When a player dies and NO on-duty ambulance players are online,
    a medic ped spawns near them, walks over and revives them.

    Auto-loaded by the resource's existing
    client_scripts { 'client/*.lua' } block in fxmanifest.lua.
]]

local aiMedic = {
    ped      = nil,
    blip     = nil,
    busy     = false,   -- a medic is already en route for us
    cooldown = 0,       -- earliest time a new medic may be requested
}

-- ============================================================================
--  CONFIG
-- ============================================================================

local Config_AI = {
    enabled         = true,     -- master switch
    spawnDistance   = 12.0,     -- how far from the body the medic appears
    arrivalDistance = 1.8,      -- distance at which the medic starts reviving
    walkSpeed       = 1.0,      -- movement clipset speed
    reviveDelayMs   = 4000,     -- kneeling / "working on you" animation length
    cooldownMs      = 60000,    -- per-player lockout between AI revives
    blipSprite      = 61,       -- 61 = ambulance-ish marker; 310 also works
    blipColor       = 2,        -- 2 = green
    blipScale       = 0.9,
    model           = `s_m_m_paramedic_01`,
}

-- ============================================================================
--  HELPERS
-- ============================================================================

local function isPlayerDead()
    return ESX.PlayerData and ESX.PlayerData.dead
end

-- Server-authoritative check: are there any ambulance players on duty?
local function getOnDutyMedicCount(cb)
    ESX.TriggerServerCallback('ai_medic:getOnDutyMedicCount', function(count)
        cb(count or 0)
    end)
end

-- Ask the server to clear its own death bookkeeping so a client-side revive
-- doesn't leave the player flagged dead in memory or in the `users` table.
local function clearServerDeathState()
    TriggerServerEvent('ai_medic:notifyRevived')
end

-- ============================================================================
--  MEDIC PED
-- ============================================================================

local function removeAIMedic()
    if aiMedic.blip and DoesBlipExist(aiMedic.blip) then
        RemoveBlip(aiMedic.blip)
    end
    aiMedic.blip = nil

    if aiMedic.ped and DoesEntityExist(aiMedic.ped) then
        SetEntityAsMissionEntity(aiMedic.ped, false, true)
        DeleteEntity(aiMedic.ped)
    end
    aiMedic.ped = nil
end

local function createAIMedic()
    local playerPed = PlayerPedId()
    local coords    = GetEntityCoords(playerPed)

    -- Find a spot near the player that is actually on the ground.
    local spawnCoords
    for _ = 1, 10 do
        local angle = math.random() * math.pi * 2
        local x = coords.x + math.cos(angle) * Config_AI.spawnDistance
        local y = coords.y + math.sin(angle) * Config_AI.spawnDistance
        local found, groundZ = GetGroundZFor_3dCoord(x, y, coords.z + 2.0, false)
        if found then
            spawnCoords = vector3(x, y, groundZ)
            break
        end
    end
    spawnCoords = spawnCoords or vector3(coords.x + 2.0, coords.y + 2.0, coords.z)

    local model = Config_AI.model
    RequestModel(model)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do
        Wait(10)
    end

    if not HasModelLoaded(model) then
        return nil
    end

    local ped = CreatePed(4, model, spawnCoords.x, spawnCoords.y, spawnCoords.z, 0.0, true, true)
    SetModelAsNoLongerNeeded(model)

    if not DoesEntityExist(ped) then
        return nil
    end

    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedDiesWhenInjured(ped, false)
    SetPedCanRagdoll(ped, false)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 46, true) -- always flee from combat
    SetEntityInvincible(ped, true)
    SetPedArmour(ped, 100)
    SetPedMaxHealth(ped, 200)
    SetPedCanBeTargetted(ped, false)
    SetPedRelationshipGroupHash(ped, `PLAYER`)

    -- Medic look
    GiveWeaponToPed(ped, `WEAPON_FLASHLIGHT`, 0, false, false)
    SetPedPropIndex(ped, 0, 122, 0, true)

    -- Ambulance blip at the scene
    local blip = AddBlipForCoord(spawnCoords.x, spawnCoords.y, spawnCoords.z)
    SetBlipSprite(blip, Config_AI.blipSprite)
    SetBlipColour(blip, Config_AI.blipColor)
    SetBlipScale(blip, Config_AI.blipScale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('EMS')
    EndTextCommandSetBlipName(blip)

    aiMedic.ped  = ped
    aiMedic.blip = blip

    return ped
end

-- Walk the ped to the player, then revive them.
local function runAIMedic()
    local ped = aiMedic.ped
    if not ped or not DoesEntityExist(ped) then return end

    local playerPed = PlayerPedId()

    -- Walk over
    local walkTimeout = GetGameTimer() + 20000
    while DoesEntityExist(ped) and GetGameTimer() < walkTimeout do
        local coords    = GetEntityCoords(playerPed)
        local pedCoords = GetEntityCoords(ped)
        local dist      = #(coords - pedCoords)

        if not isPlayerDead() then
            removeAIMedic()
            aiMedic.busy = false
            return
        end

        if dist <= Config_AI.arrivalDistance then
            break
        end

        TaskGoToCoordAnyMeans(ped, coords.x, coords.y, coords.z, Config_AI.walkSpeed, 0, false, 786603, 0.0)
        Wait(500)
    end

    if not DoesEntityExist(ped) then return end

    -- Face the player and "work on" them
    TaskTurnPedToFaceEntity(ped, playerPed, 1000)
    Wait(1000)

    local dict = 'amb@medic@standing@kneel@base'
    RequestAnimDict(dict)
    local animTimeout = GetGameTimer() + 3000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < animTimeout do
        Wait(10)
    end

    if HasAnimDictLoaded(dict) then
        TaskPlayAnim(ped, dict, 'base', 4.0, 4.0, -1, 1, 0.0, false, false, false)
    end

    ESX.ShowNotification('~g~EMS~s~ are on their way to you.')

    Wait(Config_AI.reviveDelayMs)

    -- Medic has finished - clear our ped before reviving.
    removeAIMedic()

    if not isPlayerDead() then
        aiMedic.busy = false
        return
    end

    -- Hand off to the resource's own revive handler so screen fade,
    -- isDead reset, timecycles and death cam all behave normally.
    TriggerEvent('esx_ambulancejob:revive')

    -- Tell the server to clear its death bookkeeping.
    clearServerDeathState()

    aiMedic.busy     = false
    aiMedic.cooldown = GetGameTimer() + Config_AI.cooldownMs
end

-- Shared entry point: called when we learn the player just died.
local function requestAIMedic()
    if not Config_AI.enabled then return end
    if aiMedic.busy then return end
    if GetGameTimer() < aiMedic.cooldown then return end

    aiMedic.busy = true

    -- Wait a beat so the death screen / camera settle first.
    Wait(3000)

    if not isPlayerDead() then
        aiMedic.busy = false
        return
    end

    getOnDutyMedicCount(function(count)
        if count > 0 then
            -- Real EMS are online; leave the normal flow alone.
            aiMedic.busy = false
            return
        end

        if not isPlayerDead() then
            aiMedic.busy = false
            return
        end

        removeAIMedic()
        local ped = createAIMedic()
        if not ped then
            aiMedic.busy = false
            return
        end

        CreateThread(runAIMedic)
    end)
end

-- ============================================================================
--  EVENTS
-- ============================================================================

-- Fired by the resource when the local player dies (client/main.lua).
AddEventHandler('esx:onPlayerDeath', function()
    CreateThread(requestAIMedic)
end)

-- Also hook the resource's own restore-death path, which runs on the first
-- spawn after a reconnect and re-applies the death state.
RegisterNetEvent('esx_ambulancejob:restoreDeath', function()
    CreateThread(function()
        Wait(1500)
        if isPlayerDead() then
            requestAIMedic()
        end
    end)
end)

-- Clean up if the player respawns or is revived by a real medic first.
AddEventHandler('esx:onPlayerSpawn', function()
    aiMedic.busy = false
    if aiMedic.ped or aiMedic.blip then
        removeAIMedic()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    removeAIMedic()
end)
