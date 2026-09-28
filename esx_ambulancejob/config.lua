Config                            = {}

Config.DrawDistance               = 10.0 -- How close do you need to be in order for the markers to be drawn (in GTA units).
Config.Debug                      = ESX.GetConfig().EnableDebug
Config.Marker                     = {type = 1, x = 1.5, y = 1.5, z = 0.5, r = 102, g = 0, b = 102, a = 100, rotate = false}

Config.ReviveReward               = 700  -- Revive reward, set to 0 if you don't want it enabled
Config.LoadIpl                    = true -- Disable if you're using fivem-ipl or other IPL loaders

Config.Locale = GetConvar('esx:locale', 'en')

-- Prevents desync on dead players by skipping ragdoll.
-- Players are revived instantly and play an animation instead.
-- Note: Natives like "IsPedFatallyInjured" will no longer work reliably.
-- Use Player(src).state.isDead for death checks.
Config.DeathAnim = {
    enabled = true,
    dict = "misslamar1dead_body",
    name = "dead_idle",
	fadeIn = 10.0,
	fadeOut = 10.0,
	flags = 1|2|8,
	playbackRate = 1.0
}

Config.DistressBlip = {
	Sprite = 310,
	Color = 48,
	Scale = 2.0
}

Config.zoom = {
	min = 1,
	max = 6,
	step = 0.5
}

---@class MedalClipOptions
---@field duration integer
---@field captureDelayMs integer
---@field alertType 'Default'|'Disabled'|'SoundOnly'|'OverlayOnly'

---@class MedalConfig
---@field enabled boolean
---@field publicKey string
---@field eventName string
---@field clipOptions MedalClipOptions

---@type MedalConfig
Config.Medal = {
	enabled = true,
	publicKey = 'pub_82qkpMKV77AkpqLSgWsxLlDyfzpPI7Vw',
	eventName = 'Death',
	clipOptions = {
		duration = 30,
		captureDelayMs = 0,
		alertType = 'Default'
	}
}

Config.EarlyRespawnTimer          = 60000 * 1  -- time til respawn is available
Config.BleedoutTimer              = 60000 * 10 -- time til the player bleeds out

Config.EnablePlayerManagement     = false -- Enable society managing (If you are using esx_society).

Config.RemoveWeaponsAfterRPDeath  = true
Config.RemoveCashAfterRPDeath     = true

-- Points the player is teleported to after an RP death (RemoveItemsAfterRPDeath).
-- The nearest entry to the player's death position is used.
Config.RespawnPoints = {
	{ coords = vector3(297.39, -603.67, 43.30), heading = 88.89 }
}

Config.Hospitals = {
	CentralLosSantos = {

		-- Blip moved to vec4(297.66, -586.59, 43.26, 83.61)
		-- NOTE: AddBlipForCoord only consumes x/y/z; w (83.61) is the heading,
		-- kept here for the matching doctor ped / any future teleport or spawn use.
		Blip = {
			coords = vector4(297.66, -586.59, 43.26, 83.61),
			sprite = 61,
			scale  = 1.2,
			color  = 2
		},

		AmbulanceActions = {
			vector4(297.39, -603.67, 43.30, 88.89)
		},

		Pharmacies = {
			vector4(294.64, -610.42, 43.35, 64.65)
		},

		Vehicles = {
			{
				Spawner = vector4(289.79, -611.32, 43.38, 99.34),
				InsideShop = vector4(452.3055, -1360.1731, 43.5538, 319.1165),
				Marker = {type = 36, x = 1.0, y = 1.0, z = 1.0, r = 100, g = 50, b = 200, a = 100, rotate = true},
				SpawnPoints = {
					{coords = vector3(289.79, -611.32, 43.38), heading = 99.34, radius = 4.0},
					{coords = vector3(289.79, -611.32, 43.38), heading = 99.34, radius = 4.0},
					{coords = vector3(289.79, -611.32, 43.38), heading = 99.34, radius = 6.0}
				}
			}
		},

		Helicopters = {
			{
				Spawner = vector4(289.79, -611.32, 43.38, 99.34),
				InsideShop = vector4(452.3055, -1360.1731, 43.5538, 319.1165),
				Marker = {type = 36, x = 1.0, y = 1.0, z = 1.0, r = 100, g = 50, b = 200, a = 100, rotate = true},
				SpawnPoints = {
					{coords = vector3(289.79, -611.32, 43.38), heading = 99.34, radius = 4.0},
					{coords = vector3(289.79, -611.32, 43.38), heading = 99.34, radius = 4.0},
					{coords = vector3(289.79, -611.32, 43.38), heading = 99.34, radius = 6.0}
				}
			}
		},
	}
}

Config.PharmacyItems = {
	{
		title = "Medikit",
		item = "medikit"
	},
	{
		title = "Bandage",
		item = "bandage"
	},
}
Config.MaxPharmacyTake = 5
Config.PharmacyCooldown = 5000

-- Doctor NPC standing at the hospital blip.
-- Walk within Config.DoctorNPC.interactDistance and press [E] to be revived (if
-- downed) and healed. interactDistance 3.0 GTA units is roughly 10 feet.
Config.DoctorNPC = {
	coords = vector4(297.66, -586.59, 43.26, 83.61),
	model = `s_m_m_doctor_01`,
	interactDistance = 3.0,
	healAmount = 200,
	reviveCooldown = 10000
}
