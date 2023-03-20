
local callbackResponses = {}
local currentRequestId = 0

local callbacks = {}

-- register new callback
function Register(name, callback)
	assert(name ~= nil and type(name) == "string", "Parameter \"name\" must be a string!")
	assert(callback ~= nil and type(callback) == "table" and getmetatable(callback) ~= nil, "Parameter \"callback\" must be a function!")

	callbacks[name] = callback
end

-- trigger callback with default timeout (5000ms)
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

	-- get id for current request
	local requestId = currentRequestId

	-- advance id for next request
	currentRequestId = currentRequestId + 1
	if (currentRequestId >= 65536) then
		currentRequestId = 0
	end

	-- generate unique request name
	local requestName = name .. tostring(requestId)

	-- send data to client
	TriggerClientEvent("KI:cc", playerId, name, requestId, { ... })

	-- await cb response and handle timeout
	callbackResponses[requestName] = true

	local timer = GetGameTimer()
	while (callbackResponses[requestName] == true) do
		Citizen.Wait(0)

		if (GetGameTimer() > timer + timeout) then
			callbackResponses[requestName] = "ERROR"

			LogError(
				"^1[ERROR] ClientCallback \"%s\" timed out after %sms!^0\n" .. 
				"    Potential solutions:\n" .. 
				"    - There was an error on client side. Please check the client console!\n" .. 
				"    - Player ping was higher than the specified timeout.",
				name, timeout
			)

			break
		end
	end

	-- return on error
	if (callbackResponses[requestName] == "ERROR") then return end

	-- return unpacked data
	local data = callbackResponses[requestName]
	callbackResponses[requestName] = nil
	return table.unpack(data)
end

-- trigger callback asynchronously and call a function with default timeout (5000ms)
function TriggerAsync(name, playerId, callbackFunction, ...)
	assert(name ~= nil and type(name) == "string", "Parameter \"name\" must be a string!")
	assert(playerId ~= nil and type(playerId) == "number", "Parameter \"playerId\" must be a number!")
	assert(callbackFunction ~= nil and type(callbackFunction) == "table" and getmetatable(callbackFunction) ~= nil, "Parameter \"callbackFunction\" must be a function!")

	local args = {...}
	Citizen.CreateThread(function()
		callbackFunction(Trigger(name, playerId, args))
	end)
end

-- trigger callback asynchronously and call a function with custom timeout
function TriggerWithTimeoutAsync(name, playerId, timeout, callbackFunction, ...)
	assert(name ~= nil and type(name) == "string", "Parameter \"name\" must be a string!")
	assert(playerId ~= nil and type(playerId) == "number", "Parameter \"playerId\" must be a number!")
	assert(timeout ~= nil and type(timeout) == "number", "Parameter \"timeout\" must be a number!")
	assert(callbackFunction ~= nil and type(callbackFunction) == "table" and getmetatable(callbackFunction) ~= nil, "Parameter \"callbackFunction\" must be a function!")

	local args = {...}
	Citizen.CreateThread(function()
		callbackFunction(TriggerWithTimeout(name, playerId, timeout, args))
	end)
end

-- execute ServerCallback
RegisterNetEvent("KI:sc", function(name, requestId, data)
	local src = source

	local requestName = name .. tostring(requestId)

	if (callbacks[name] == nil) then
		LogError(
			"ServerCallback \"%s\" does not exist!^0\n" .. 
			"    Potential solutions:\n" .. 
			"    - \"kimi_callbacks\" needs to be started before the script that is using this export!\n" .. 
			"    - Make sure that there is no typo in the Register or Trigger function!",
			name
		)

		TriggerClientEvent("KI:scDoesNotExist", src, requestName, name)

		return
	end

	-- execute callback function and send its result back to client
	local returnData = table.pack(pcall(callbacks[name], src, table.unpack(data)))
	if (not returnData[1]) then
		-- error in callback function
		if (returnData[2] == nil) then
			LogError("ServerCallback \"%s\" ran into an error!", name)
		else
			LogError("ServerCallback \"%s\" ran into the following error:\n%s", name, returnData[2])
		end

		TriggerClientEvent("KI:scError", src, requestName, name, returnData[2])

		return
	end

	table.remove(returnData, 1)

	TriggerClientEvent("KI:scResponse", src, requestName, returnData)
end)

-- receive data from ClientCallback
RegisterNetEvent("KI:ccResponse", function(requestName, data)
	if (callbackResponses[requestName] == nil) then return end

	callbackResponses[requestName] = data
end)

-- ClientCallback does not exist
RegisterNetEvent("KI:ccDoesNotExist", function(requestName, name)
	if (callbackResponses[requestName] == nil) then return end

	callbackResponses[requestName] = "ERROR"

	LogError(
		"ClientCallback \"%s\" does not exist!^0\n" .. 
		"    Potential solutions:\n" .. 
		"    - \"kimi_callbacks\" needs to be started before the script that is using this export!\n" .. 
		"    - Make sure that there is no typo in the Register or Trigger function!",
		name
	)
end)

-- error in ClientCallback
RegisterNetEvent("KI:ccError", function(requestName, name, errorMessage)
	if (callbackResponses[requestName] == nil) then return end

	callbackResponses[requestName] = "ERROR"

	if (errorMessage == nil) then
		LogError("ClientCallback \"%s\" ran into an error! Check the client console for errors!", name)
	else
		LogError("ClientCallback \"%s\" ran into the following error:\n%s", name, errorMessage)
	end
end)



-- log error to console
function LogError(text, ...)
	print(("^1[ERROR] %s^0"):format(text):format(...))
end



-- declare exports
exports("Register", Register)
exports("Trigger", Trigger)
exports("TriggerWithTimeout", TriggerWithTimeout)
exports("TriggerAsync", TriggerAsync)
exports("TriggerWithTimeoutAsync", TriggerWithTimeoutAsync)
