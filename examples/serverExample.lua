
-- FUNCTIONS

-- Register a new server callback.
--   "CALLBACK_NAME" needs to be a unique string.
--   "source" is the playerServerId of the triggering player. (similar to events)
--   "..." can be any amount of values sent from the client.
--   return any amount of values
exports["kimi_callbacks"]:Register("CALLBACK_NAME", function(source, ...)
	-- do something here

	return ANY, VALUES, SEPARATED_BY_COMMA
end)

-- Trigger a client callback with a timeout of 5000ms.
--   "CALLBACK_NAME" must be the same name as defined when registering the callback on client side.
--   "PLAYER_ID" is the player server id of the player.
--   "..." can be any amount of values to send to the client.
--   Returns any amount of values from the client.
local data1, data2, data3 = exports["kimi_callbacks"]:Trigger("CALLBACK_NAME", PLAYER_ID, ...)

-- Trigger a client callback with a custom timeout.
--   "CALLBACK_NAME" must be the same name as defined when registering the callback on client side.
--   "PLAYER_ID" is the player server id of the player.
--   "TIMEOUT" is the amount of time before the callback is cancelled (in ms).
--   "..." can be any amount of values to send to the client.
--   Returns any amount of values from the client.
local data1, data2, data3 = exports["kimi_callbacks"]:TriggerWithTimeout("CALLBACK_NAME", PLAYER_ID, TIMEOUT, ...)



-- EXAMPLES

-- Return money to client.
exports["kimi_callbacks"]:Register("getMoney", function(source, moneyType)
	-- get money from player with source
	local cash, bank = GetMoneyFromPlayer(source)

	if (moneyType == "cash") then
		return cash
	elseif (moneyType == "bank") then
		return bank
	else
		return cash, bank
	end
end)

-- Get player position from client.
function GetPlayerPosition(playerId)
	local position = exports["kimi_callbacks"]:Trigger("getPlayerPosition", playerId)

	return position
end
-- Get player position and heading from client.
function GetPlayerPositionAndHeading(playerId)
	local position, heading = exports["kimi_callbacks"]:Trigger("getPlayerPositionAndHeading", playerId)

	return position, heading
end
-- Get player distance to a specified position from client with a timeout.
function GetPlayerDistanceToPosition(playerId, position)
	local distance = exports["kimi_callbacks"]:TriggerWithTimeout("getPlayerDistanceToPosition", playerId, position)

	return distance
end
