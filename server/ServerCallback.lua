local callbackResponses = {}
local currentRequestId = 0

local callbacks = {}

-- register new callback
function Register(name, callback)
	assert(name ~= nil and type(name) == "string", "Parameter \"name\" must be a string!")
	assert(callback ~= nil, "Parameter \"callback\" must be a function!")

	callbacks[name] = callback
end

-- trigger callback
function Trigger(name, playerId, ...)
	assert(name ~= nil and type(name) == "string", "Parameter \"name\" must be a string!")
	assert(playerId ~= nil and type(playerId) == "number", "Parameter \"playerId\" must be a number!")

	return TriggerWithTimeout(name, playerId, 5000, ...)
end

-- trigger callback with custom timeout
function TriggerWithTimeout(name, playerId, timeout, ...)
	assert(name ~= nil and type(name) == "string", "Parameter \"name\" must be a string!")
	assert(playerId ~= nil and type(playerId) == "number", "Parameter \"playerId\" must be a number!")
	assert(timeout ~= nil and type(timeout) == "number", "Parameter \"timeout\" must be a number!")

	-- set id for current request
	local requestId = currentRequestId

	-- advance next request id
	currentRequestId = currentRequestId + 1
	if (currentRequestId >= 65536) then
		currentRequestId = 0
	end

	-- create request name from callback name and request id
	local requestName = name .. tostring(requestId)

	-- initialize callback response
	callbackResponses[requestName] = true

	-- send data to client
	TriggerClientEvent("KI:cc", playerId, name, requestId, { ... })

	-- await cb response
	local timer = GetGameTimer()
	while (callbackResponses[requestName] == true) do
		Citizen.Wait(0)

		if (GetGameTimer() > timer + timeout) then
			-- timed out
			print(
				"^1[ERROR] ClientCallback \"" .. name .. "\" timed out after " .. tostring(timeout) .. "ms!^0\n" .. 
				"    Potential solutions:\n" .. 
				"    - There was an error on client side. Please check the client console!\n" .. 
				"    - Player ping was higher than the specified timeout."
			)

			callbackResponses[requestName] = "ERROR"
		end
	end

	-- return nil if error occurred
	if (callbackResponses[requestName] == "ERROR") then
		return nil
	end

	-- return unpacked data
	local data = callbackResponses[requestName]
	callbackResponses[requestName] = nil
	return table.unpack(data)
end

RegisterNetEvent("KI:sc")
AddEventHandler("KI:sc", function(name, requestId, data)
	local src = source

	local requestName = name .. tostring(requestId)

	if (callbacks[name] ~= nil) then
		-- execute callback function and return its result
		local result = { callbacks[name](src, table.unpack(data)) }

		TriggerClientEvent("KI:scResponse", src, requestName, result)
	else
		-- callback does not exist
		print(
			"^1[ERROR] ServerCallback \"" .. name .. "\" does not exist!^0\n" .. 
			"    Potential solutions:\n" .. 
			"    - \"kimi_callbacks\" needs to be started before the script that is using this export!\n" .. 
			"    - Make sure that there is no typo in the Register or Trigger function!"
		)

		TriggerClientEvent("KI:scDoesNotExist", src, requestName, name)
	end
end)

RegisterNetEvent("KI:ccResponse")
AddEventHandler("KI:ccResponse", function(requestName, data)
	if (callbackResponses[requestName] ~= nil) then
		-- receive data
		callbackResponses[requestName] = data
	end
end)

RegisterNetEvent("KI:ccDoesNotExist")
AddEventHandler("KI:ccDoesNotExist", function(requestName, name)
	if (callbackResponses[requestName] ~= nil) then
		callbackResponses[requestName] = "ERROR"

		print(
			"^1[ERROR] ClientCallback \"" .. name .. "\" does not exist!^0\n" .. 
			"    Potential solutions:\n" .. 
			"    - \"kimi_callbacks\" needs to be started before the script that is using this export!\n" .. 
			"    - Make sure that there is no typo in the Register or Trigger function!"
		)
	end
end)



-- declare exports
exports("Register", Register)
exports("Trigger", Trigger)
exports("TriggerWithTimeout", TriggerWithTimeout)
