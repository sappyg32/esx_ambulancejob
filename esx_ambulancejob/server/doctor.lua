-- Server side of the doctor NPC treat action
RegisterNetEvent('esx_ambulancejob:heal')
AddEventHandler('esx_ambulancejob:heal', function(source, healType)
	local xPlayer = ESX.GetPlayerFromId(source)
	if not xPlayer then return end

	TriggerClientEvent('esx:showNotification', source, TranslateCap('healed'))
end)
