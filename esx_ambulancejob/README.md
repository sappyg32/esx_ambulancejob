# esx_ambulancejob - hospital blip move + doctor NPC

Three changes, two of which touch files shipped in this zip, one of which you
apply to the stock script you already have (see "Manual edits" below).

## 1. Hospital blip moved  (config.lua)

Config.Hospitals.CentralLosSantos.Blip.coords is now:

    vector4(297.66, -586.59, 43.26, 83.61)

AddBlipForCoord only reads x/y/z, so the blip lands on the first three values.
The fourth value is the heading, kept for the doctor ped orientation.

## 2. Doctor NPC  (config.lua + client/doctor.lua + server/doctor.lua)

- client/doctor.lua spawns an invincible, frozen s_m_m_doctor_01 at the blip
  coords and, when you are within 3.0 units (~10 feet), shows
  "[E] Get treated by the doctor".
- Pressing E revives you if you are down, then heals you to 200 HP and clears
  blood damage.
- server/doctor.lua is the server-side hook for the treat event.

Tune the distance / model / heal amount in Config.DoctorNPC.

## 3. G distress signal removed  (manual edits)

There is no single switch for this; the hint text comes from a locale string and
the key is enabled in the death loop. Do all three:

a) client/main.lua, in OnPlayerDeath(), delete the line:

       StartDistressSignal()

b) client/main.lua, delete the whole StartDistressSignal() function.
   SendDistressSignal() may stay - nothing calls it once the loop is gone.

c) client/main.lua, in StartDeathLoop(), delete this line:

       EnableControlAction(0, 47, true) -- G

   LEAVE controls 245 (T) and 38 (E) alone - 38 still drives the respawn hold
   prompt.

d) optionally, locales/en.lua: remove

       ['distress_send'] = 'Press [G] to send distress signal',

   It becomes unreferenced once (b) is done, but leaving it is harmless.

## Install

The two new files are picked up automatically:

- client/doctor.lua matches the existing 'client/*.lua' entry in fxmanifest.lua
- server/doctor.lua matches the existing 'server/*.lua' entry

No fxmanifest.lua change is needed. Drop the folder into your resources, then
restart the resource.

## Caveat

297.66, -586.59, 43.26 is in the Vinewood / Alta St area, roughly 850 units from
the Pillbox Hill coords the rest of CentralLosSantos still uses (ambulance
actions, pharmacy, vehicle and helicopter spawners, respawn points). The blip
and the doctor moved; the rest of the hospital did not. Sanity-check the coords
in game, and if the whole hospital should move, those coords need updating too.
