character = {}
---------------------------------------------------------------------------
-- START CHARACTER NUI
---------------------------------------------------------------------------
RegisterServerEvent("DRP_ID:RequestOpenMenu")
AddEventHandler("DRP_ID:RequestOpenMenu", function()
	local src = source
	TriggerEvent("DRP_Core:GetPlayerData", src, function(results)
		exports["externalsql"]:AsyncQueryCallback({
			query = "SELECT * FROM `characters` WHERE `playerid` = :playerid",
			data = {playerid = results.playerid}
		}, function(characters)
			local characters = characters["data"]
			TriggerClientEvent("DRP_ID:OpenMenu", src, characters)
		end)
	end)
end)
---------------------------------------------------------------------------
-- UPDATE NUI EVENT
---------------------------------------------------------------------------
AddEventHandler("DRP_ID:UpdateCharactersInUI", function(player)
	TriggerEvent("DRP_Core:GetPlayerData", player, function(results)
		exports["externalsql"]:AsyncQueryCallback({
			query = "SELECT * FROM `characters` WHERE `playerid` = :playerid",
			data = {playerid = results.playerid}
		}, function(characters)
			local characters = characters["data"]
			TriggerClientEvent("DRP_ID:UpdateMenuCharacters", player, characters)
		end)
	end)
end)
---------------------------------------------------------------------------
-- CREATE CHARACTER EVENT
---------------------------------------------------------------------------
RegisterServerEvent("DRP_ID:CreateCharacter")
AddEventHandler("DRP_ID:CreateCharacter", function(newCharacterData)
	local src = source
	TriggerEvent("DRP_Core:GetPlayerData", src, function(playerData)
		exports["externalsql"]:AsyncQueryCallback({
			query = "SELECT * FROM `characters` WHERE `playerid` = :playerid",
			data = {
				playerid = playerData.playerid
			}
		}, function(characters)
			Wait(500)
			local characterCount = #characters["data"]
			if characterCount < DRPCharacters.MaxCharacters then
				exports["externalsql"]:AsyncQueryCallback({
					query = [[
						INSERT INTO characters
						(`name`, `age`, `dob`, `gender`, `cash`, `bank`, `dirtyCash`, `licenses`, `playerid`)
						VALUES
						(:name, :age, :dob, :gender, :cash, :bank, :dirtycash, :licenses, :playerid)
					]],
					data = {
						name = newCharacterData.name,
						age = newCharacterData.age,
						dob = newCharacterData.dob,
						gender = newCharacterData.gender,
						cash = DRPCharacters.StarterCash,
						bank = DRPCharacters.StarterBank,
						dirtycash = DRPCharacters.StartDirtyCash,				
						licenses = json.encode({}),
						playerid = playerData.playerid
					}
				}, function(createdResults)
					TriggerEvent("DRP_ID:UpdateCharactersInUI", src)
				end)
			else
				TriggerClientEvent("DRP_Core:Error", src, "Characters", "You have ran out of Character spaces, the max is "..DRPCharacters.MaxCharacters.."", 2500, false, "leftCenter")
			end
		end)
	end)
end)
---------------------------------------------------------------------------
-- SELECT CHARACTER EVENT
---------------------------------------------------------------------------
RegisterServerEvent("DRP_ID:SelectCharacter")
AddEventHandler("DRP_ID:SelectCharacter", function(character_id)
	local src = source
	local model = nil
	exports["externalsql"]:AsyncQueryCallback({
		query = "SELECT * FROM `characters` WHERE `id` = :character_id",
		data = {
			character_id = character_id
		}
	}, function(characterInfo)
		TriggerEvent("DRP_Clothing:AddCharacterClothing", character_id)
		Wait(1000)
		exports["externalsql"]:AsyncQueryCallback({
			query = "SELECT * FROM `character_clothing` WHERE `char_id` = :character_id",
			data = {
				character_id = character_id
			}
		}, function(characterModel)
			local lastKnownLocation = json.decode(characterInfo["data"][1].lastLocation)
			table.insert(character, {id = src, charid = character_id, playerid = characterInfo.data[1].playerid, gender = characterInfo.data[1].gender, name = characterInfo.data[1].name, age = characterInfo.data[1].age})
			local spawnInHotel = true
			if json.encode(characterModel["data"]) ~= "[]" then
				if DRPCharacters.SpawnSelection then
					CloseAllCameras(src)
					TriggerClientEvent("DRP_ID:SpawnSelection", src, characterModel["data"][1].model, lastKnownLocation)
				else
					CloseAllCameras(src)
					TriggerClientEvent("DRP_ID:LoadSelectedCharacter", src, characterModel["data"][1].model, lastKnownLocation, spawnInHotel)
				end
			else
				if DRPCharacters.SpawnSelection then
					CloseAllCameras(src)
					TriggerClientEvent("DRP_ID:SpawnSelection", src, "mp_m_freemode_01", lastKnownLocation)
				else
					CloseAllCameras(src)
					TriggerClientEvent("DRP_ID:LoadSelectedCharacter", src, "mp_m_freemode_01", lastKnownLocation, spawnInHotel)
				end
			end
		end)
	end)
end)
---------------------------------------------------------------------------
-- Spawn Character At Last Known Location
---------------------------------------------------------------------------
RegisterServerEvent("DRP_ID:LastKnownPosition")
AddEventHandler("DRP_ID:LastKnownPosition", function(ped)
	local src = source
	local character = GetCharacterData(src)

	exports["externalsql"]:AsyncQueryCallback({
		query = "SELECT * FROM `characters` WHERE `id` = :character_id",
		data = {
			character_id = character.charid
		}
	}, function(characterData)
		local lastKnownLocation = json.decode(characterData["data"][1].lastLocation)
		local spawn = { x = lastKnownLocation[1],  y = lastKnownLocation[2], z = lastKnownLocation[3] }
		TriggerClientEvent("DRP_ID:LoadSelectedCharacter", src, ped, spawn, true)
	end)
end)
---------------------------------------------------------------------------
-- Get Character Vehicles Event
---------------------------------------------------------------------------
RegisterServerEvent("DRP_ID:GetCharacterVehicles")
AddEventHandler("DRP_ID:GetCharacterVehicles", function(character_id)
	local src = source
	exports["externalsql"]:AsyncQueryCallback({
		query = "SELECT * FROM `vehicles` WHERE `char_id` = :character_id",
		data = {
			character_id = character_id
		}
	}, function(charactervehicle)
		local data = charactervehicle["data"]
		TriggerClientEvent('DRP_ID:OpenVehicleList', src, data)
	end)
end)
---------------------------------------------------------------------------
-- Delete Character Event
---------------------------------------------------------------------------
RegisterServerEvent("DRP_ID:DeleteCharacter")
AddEventHandler("DRP_ID:DeleteCharacter", function(character_id)
	local src = source
	exports["externalsql"]:AsyncQueryCallback({
		query = "DELETE FROM `characters` WHERE `id` = :character_id",
		data = {
			character_id = character_id
		}
	}, function(results)
		TriggerEvent("DRP_ID:UpdateCharactersInUI", src)
	end)
end)
---------------------------------------------------------------------------
-- Drop Player Event (Using Disconnect Button)
---------------------------------------------------------------------------
RegisterServerEvent("DRP_ID:Disconnect")
AddEventHandler("DRP_ID:Disconnect", function()
	local src = source
	DropPlayer(src, "Disconnected From Server Using The Disconnect Button!")
end)
---------------------------------------------------------------------------
-- Saving Character Location
---------------------------------------------------------------------------
RegisterServerEvent("DRP_ID:SaveCharacterLocation")
AddEventHandler("DRP_ID:SaveCharacterLocation", function(x,y,z)
	local src = source
	local character = GetCharacterData(src)
	local lastPos = "{"..x..", "..y..", "..z.."}"
	exports["externalsql"]:AsyncQueryCallback({
		query = "UPDATE characters SET `lastLocation` = :lastLocation WHERE `id` = :char_id",
		data = {
			lastLocation = lastPos,
			char_id = character.charid
		}
	}, function(results)
	end)
end)
---------------------------------------------------------------------------
-- Get Character Data Function Usage exports["drp_id"]:GetCharacterData(source)
---------------------------------------------------------------------------
function GetCharacterData(id)
	for a = 1, #character do
		if character[a].id == id then
			return(character[a])
		end
	end
	return false
end
---------------------------------------------------------------------------
-- Get Character Name Function Usage exports["drp_id"]:GetCharacterName(source)
---------------------------------------------------------------------------
function GetCharacterName(id)
	for a = 1, #character do
		if character[a].id == id then
			return(character[a].name)
		end
	end
	return false
end
---------------------------------------------------------------------------
-- Close All Air Cameras Function
---------------------------------------------------------------------------
function CloseAllCameras(src)
	TriggerClientEvent("DRP_ID:StopSkyCamera", src)
	TriggerClientEvent("DRP_ID:StopCreatorCamera", src) -- If you are using this system
end
---------------------------------------------------------------------------
-- Get Character Data Server Handler
---------------------------------------------------------------------------
AddEventHandler("DRP_ID:GetCharacterData", function(id, callback)
		for a = 1, #character do
			if character[a].id == id then
				callback(character[a])
				return
			end
		end
	callback(false)
end)
---------------------------------------------------------------------------
-- Checking for player to leave so it will remove data from table
---------------------------------------------------------------------------
AddEventHandler("playerDropped", function()
    for a = 1, #character do
        if character[a].id == id then
            table.remove(character, a)
            break
        end
    end
end)

print("^1[DRP] ID ^0: ^4ID Loaded Successfully^0")