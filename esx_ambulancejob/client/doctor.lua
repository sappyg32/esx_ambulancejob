-- Doctor NPC: spawns at the hospital blip and revives/heals the player on [E]
local doctorPed = nil

local function SpawnDoctor()
	local cfg = Config.DoctorNPC

	xLib.streaming.requestModel(cfg.model)
	while not HasModelLoaded(cfg.model) do Wait(10) end

	doctorPed = CreatePed(4, cfg.model, cfg.coords.x, cfg.coords.y, cfg.coords.z - 1.0, cfg.coords.w, false, true)
	SetEntityInvincible(doctorPed, true)
	SetBlockingOfNonTemporaryEvents(doctorPed, true)
	FreezeEntityPosition(doctorPed, true)
	SetPedCanRagdoll(doctorPed, false)
	SetModelAsNoLongerNeeded(cfg.model)
end

CreateThread(function()
	SpawnDoctor()

	while true do
		local sleep = 1000
		local ped = PlayerPedId()
		local dist = #(GetEntityCoords(ped) - vector3(Config.DoctorNPC.coords.x, Config.DoctorNPC.coords.y, Config.DoctorNPC.coords.z))

		if dist <= Config.DoctorNPC.interactDistance then
			sleep = 0
			ESX.TextUI('[E] Get treated by the doctor')

			if IsControlJustReleased(0, 38) then
				ESX.TextUI()
				TriggerEvent('esx_ambulancejob:doctorTreat')
			end
		end

		Wait(sleep)
	end
end)

RegisterNetEvent('esx_ambulancejob:doctorTreat')
AddEventHandler('esx_ambulancejob:doctorTreat', function()
	local ped = PlayerPedId()

	-- Revive first if downed
	if isDead or ESX.PlayerData.dead then
		local coords = GetEntityCoords(ped)
		local formattedCoords = {x = ESX.Math.Round(coords.x, 1), y = ESX.Math.Round(coords.y, 1), z = ESX.Math.Round(coords.z, 1)}

		DoScreenFadeOut(800)
		while not IsScreenFadedOut() do Wait(50) end

		RespawnPed(ped, formattedCoords, 0.0)
		isDead = false
		ESX.SetPlayerData('dead', false)
		ClearTimecycleModifier()
		SetPedMotionBlur(ped, false)
		ClearExtraTimecycleModifier()
		EndDeathCam()
		DoScreenFadeIn(800)
	end

	SetEntityHealth(ped, math.min(GetEntityMaxHealth(ped), 200))
	ClearPedBloodDamage(ped)

	TriggerServerEvent('esx_ambulancejob:heal', 'doctor')
	ESX.ShowNotification(TranslateCap('healed'))
end)
