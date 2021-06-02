
-- FUNCTIONS

-- Register a new client callback.
--   "CALLBACK_NAME" needs to be a unique string.
--   "..." can be any amount of values sent from the server.
--   return any amount of values
exports["kimi_callbacks"]:Register("CALLBACK_NAME", function(...)
	-- do something here

	return ANY, VALUES, SEPARATED_BY_COMMA
end)

-- Trigger a server callback with a timeout of 5000ms.
--   "CALLBACK_NAME" must be the same name as defined when registering the callback on server side.
--   "..." can be any amount of values to send to the server.
--   Returns any amount of values from the server.
local data1, data2, data3 = exports["kimi_callbacks"]:Trigger("CALLBACK_NAME", ...)

-- Trigger a server callback with a custom timeout.
--   "CALLBACK_NAME" must be the same name as defined when registering the callback on server side.
--   "timeout" is the amount of time before the callback is cancelled (in ms).
--   "..." can be any amount of values to send to the server.
--   Returns any amount of values from the server.
local data1, data2, data3 = exports["kimi_callbacks"]:TriggerWithTimeout("CALLBACK_NAME", timeout ...)



-- EXAMPLES

--   Return player position to server.
exports["kimi_callbacks"]:Register("getPlayerPosition", function()
	local position = GetEntityCoords(PlayerPedId())

	return position
end)
--   Return player position and heading to server.
exports["kimi_callbacks"]:Register("getPlayerPositionAndHeading", function()
	local playerPos = GetEntityCoords(PlayerPedId())
	local heading = GetEntityHeading(PlayerPedId())

	return playerPos, heading
end)
--   Return distance from a player to a given point to server.
exports["kimi_callbacks"]:Register("getPlayerDistanceToPosition", function(position)
	local playerPos = GetEntityCoords(PlayerPedId())

	local distance = Vdist(playerPos.x, playerPos.y, playerPos.z, position.x, position.y, position.z)

	return distance
end)

--   Get player money from server.
function GetMoney()
    local cash, bank = exports["kimi_callbacks"]:Trigger("getMoney")

    return cash, bank
end

--   Get player cash money from server with a timeout.
function GetCashMoneyTimeout()
    local cashMoney = exports["kimi_callbacks"]:TriggerWithTimeout("getMoney", 500, "cash")

	if (cashMoney ~= nil) then
		return cashMoney
	else
		return 0
	end
end
