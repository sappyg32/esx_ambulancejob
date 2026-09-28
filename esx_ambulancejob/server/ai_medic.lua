--[[
    ai_medic.lua (server) -- supports client/ai_medic.lua

    1. Answers "how many on-duty ambulance players are there?"
    2. Lets the AI revive clear the real death bookkeeping, so the AI
       revive behaves the same as a medic revive.
]]

-- How many ambulance players are on duty right now.
ESX.RegisterServerCallback('ai_medic:getOnDutyMedicCount', function(source, cb)
    local count   = 0
    local players = ESX.GetExtendedPlayers('job', 'ambulance')

    for _, xPlayer in pairs(players) do
        if xPlayer.job.name == 'ambulance' and xPlayer.job.onDuty ~= false then
            count = count + 1
        end
    end

    cb(count)
end)

-- Called by the client right after an AI revive completes.
RegisterNetEvent('ai_medic:notifyRevived', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    -- Mirror the cleanup that the resource's real revive performs so the
    -- player isn't left flagged dead in memory or in the database.
    Player(src).state:set('isDead', false, true)
    MySQL.update('UPDATE users SET is_dead = ? WHERE identifier = ?', { false, xPlayer.identifier })

    if xPlayer.getMeta().deathTime ~= nil then
        xPlayer.clearMeta('deathTime')
    end
end)
