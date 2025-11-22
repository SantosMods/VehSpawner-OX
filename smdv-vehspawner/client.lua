local lastVehicle = nil

local requestLines = {
	"Let me check what's available.",
	"Give me a second, grabbing the keys.",
	"Hold on, pulling something from the garage.",
	"Alright, let's see what's ready.",
	"Sure thing, one moment.",
	"I'll see if there's one that still runs.",
	"Checking the back for something decent.",
	"Another car? Busy day?",
	"Paperwork never ends. One sec.",
	"Got it — grabbing a unit now.",
}

local confirmLines = {
	"It's parked out front.",
	"All set — keys are inside.",
	"Car’s ready. Don’t scratch it.",
	"You're good to go.",
	"Running smooth now.",
	"Fueled and ready.",
	"Parked by the curb.",
	"It's the clean one, somehow.",
	"You're all set. Good hunting.",
	"Out front. Try not to break it.",
}

local sideComments = {
	"Brakes should work this time.",
	"Topped the tank off myself.",
	"Radio is stuck on dispatch again.",
	"Seat might smell like coffee.",
	"Avoid poles this time.",
	"Engine light always does that.",
	"It’s fast… kind of.",
	"Try not to hit cones again.",
	"Transmission is on its last leg.",
	"Washed yesterday. Probably.",
}

-- Basic Loading / Deletion
local function loadModel(m)
	if not HasModelLoaded(m) then
		RequestModel(m)
		while not HasModelLoaded(m) do
			Wait(10)
		end
	end
end

local function deleteLastVehicle()
	if lastVehicle and DoesEntityExist(lastVehicle) then
		DeleteEntity(lastVehicle)
		lastVehicle = nil
	end
end

-- Check Area
local function isSpotClear(coords)
	local r = 3.5
	for _, veh in ipairs(GetGamePool("CVehicle")) do
		if #(coords - GetEntityCoords(veh)) < r then
			return false
		end
	end
	for _, p in ipairs(GetGamePool("CPed")) do
		if not IsPedAPlayer(p) and #(coords - GetEntityCoords(p)) < r then
			return false
		end
	end
	return true
end

-- Text
local function showPedText(p, txt, time)
	CreateThread(function()
		local untilT = GetGameTimer() + (time or 2500)
		while GetGameTimer() < untilT and DoesEntityExist(p) do
			local c = GetEntityCoords(p)
			local ok, x, y = World3dToScreen2d(c.x, c.y, c.z + 1.05)
			if ok then
				SetTextScale(0.35, 0.35)
				SetTextFont(4)
				SetTextCentre(1)
				SetTextOutline()
				SetTextEntry("STRING")
				AddTextComponentString(txt)
				DrawText(x, y)
			end
			Wait(0)
		end
	end)
end

function table.contains(t, v)
	for _, x in ipairs(t) do
		if x == v then
			return true
		end
	end
	return false
end

-- Create Ped
CreateThread(function()
	print("[VehSpawner-OX] init…")

	for _, station in ipairs(Config.Stations) do
		local pm = station.pedModel or `s_m_y_cop_01`

		if not IsModelInCdimage(pm) or not IsModelValid(pm) then
			print("bad ped model at " .. station.name)
			goto skip
		end

		loadModel(pm)

		local ped = CreatePed(4, pm, station.ped.x, station.ped.y, station.ped.z - 1.0, station.ped.w, false, true)
		if not ped then
			print("failed ped at " .. station.name)
			goto skip
		end

		FreezeEntityPosition(ped, true)
		SetBlockingOfNonTemporaryEvents(ped, true)
		SetEntityInvincible(ped, true)
		SetPedCanBeTargetted(ped, false)

		TaskStartScenarioInPlace(ped, "WORLD_HUMAN_COP_IDLES", 0, true)

		-- ox target handler
		exports.ox_target:addLocalEntity(ped, {
			{
				name = "vehspawner_" .. station.name,
				icon = "fa-solid fa-car",
				label = "Request Vehicle",
				distance = 2.5,

				onSelect = function()
					local pPed = PlayerPedId()
					TaskTurnPedToFaceEntity(ped, pPed, 900)
					Wait(500)

					ClearPedTasks(ped)
					TaskStartScenarioInPlace(ped, "WORLD_HUMAN_STAND_IMPATIENT", 0, true)

					showPedText(ped, requestLines[math.random(#requestLines)], 2200)

					local opts = {}

					for _, v in ipairs(Config.Vehicles) do
						if not v.allowedStations or table.contains(v.allowedStations, station.name) then
							opts[#opts + 1] = {
								title = v.name,
								event = "vehspawner:spawn",
								args = { model = v.vehicle, ped = ped, station = station.name },
							}
						end
					end

					lib.registerContext({
						id = "vehspawner_menu_" .. station.name,
						title = station.name .. " Vehicles",
						options = opts,
					})

					lib.showContext("vehspawner_menu_" .. station.name)

					CreateThread(function()
						Wait(3200)
						ClearPedTasks(ped)
						TaskStartScenarioInPlace(ped, "WORLD_HUMAN_COP_IDLES", 0, true)
					end)
				end,
			},
		})

		::skip::
	end
end)

-- Vehicle Spawning
RegisterNetEvent("vehspawner:spawn", function(data)
	local st
	for _, s in ipairs(Config.Stations) do
		if s.name == data.station then
			st = s
			break
		end
	end
	if not st then
		return
	end

	local ped = data.ped
	local model = data.model
	local hash = GetHashKey(model)

	if not IsModelAVehicle(hash) then
		lib.notify({ title = "Spawner", description = "Vehicle model invalid.", type = "error" })
		return
	end

	RequestModel(hash)
	while not HasModelLoaded(hash) do
		Wait(10)
	end

	deleteLastVehicle()

	DoScreenFadeOut(400)
	Wait(500)

	local spawnPt
	for _, p in ipairs(st.spawns) do
		if isSpotClear(vector3(p.x, p.y, p.z)) then
			spawnPt = p
			break
		end
	end

	if not spawnPt then
		DoScreenFadeIn(400)
		showPedText(ped, "Lot's full. Try later.", 2400)
		return
	end

	local v = CreateVehicle(hash, spawnPt.x, spawnPt.y, spawnPt.z, spawnPt.w, true, false)
	if not v then
		DoScreenFadeIn(400)
		return
	end

	SetVehicleOnGroundProperly(v)
	SetVehicleDirtLevel(v, 0.0)
	lastVehicle = v

	DoScreenFadeIn(700)

	showPedText(ped, confirmLines[math.random(#confirmLines)], 2300)
	Wait(1100)
	showPedText(ped, sideComments[math.random(#sideComments)], 2300)

	lib.notify({
		title = "Vehicle Spawner",
		description = ("Spawned: %s"):format(model),
		type = "success",
	})
end)
