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
function Trigger(name, ...)
	assert(name ~= nil and type(name) == "string", "Parameter \"name\" must be a string!")

	return TriggerWithTimeout(name, 5000, ...)
end

-- trigger callback with custom timeout
function TriggerWithTimeout(name, timeout, ...)
	assert(name ~= nil and type(name) == "string", "Parameter \"name\" must be a string!")
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

	-- send data to server
	TriggerServerEvent("KI:sc", name, requestId, { ... })

	-- await cb response and handle timeout
	callbackResponses[requestName] = true

	local timer = GetGameTimer()
	while (callbackResponses[requestName] == true) do
		Citizen.Wait(0)

		if (GetGameTimer() > timer + timeout) then
			callbackResponses[requestName] = "ERROR"

			LogError(
				"ServerCallback \"%s\" timed out after %sms!^0\n" .. 
				"    Potential solutions:\n" .. 
				"    - There was an error on server side. Please check the server console!\n" .. 
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
function TriggerAsync(name, callbackFunction, ...)
	assert(name ~= nil and type(name) == "string", "Parameter \"name\" must be a string!")
	assert(callbackFunction ~= nil and type(callbackFunction) == "table" and getmetatable(callbackFunction) ~= nil, "Parameter \"callbackFunction\" must be a function!")

	local args = {...}
	Citizen.CreateThread(function()
		callbackFunction(Trigger(name, args))
	end)
end

-- trigger callback asynchronously and call a function with custom timeout
function TriggerWithTimeoutAsync(name, timeout, callbackFunction, ...)
	assert(name ~= nil and type(name) == "string", "Parameter \"name\" must be a string!")
	assert(timeout ~= nil and type(timeout) == "number", "Parameter \"timeout\" must be a number!")
	assert(callbackFunction ~= nil and type(callbackFunction) == "table" and getmetatable(callbackFunction) ~= nil, "Parameter \"callbackFunction\" must be a function!")

	local args = {...}
	Citizen.CreateThread(function()
		callbackFunction(TriggerWithTimeout(name, timeout, args))
	end)
end



-- log error to console
function LogError(text, ...)
	print(("^1[ERROR] %s^0"):format(text):format(...))
end



-- execute ClientCallback
RegisterNetEvent("KI:cc", function(name, requestId, data)
	local requestName = name .. tostring(requestId)

	if (callbacks[name] == nil) then
		LogError(
			"ClientCallback \"%s\" does not exist!^0\n" .. 
			"    Potential solutions:\n" .. 
			"    - \"kimi_callbacks\" needs to be started before the script that is using this export!\n" .. 
			"    - Make sure that there is no typo in the Register or Trigger function!",
			name
		)

		TriggerServerEvent("KI:ccDoesNotExist", requestName, name)

		return
	end

	-- execute callback function and return its result
	local returnData = table.pack(pcall(callbacks[name], table.unpack(data)))
	if (not returnData[1]) then
		-- error in callback function
		if (returnData[2] == nil) then
			LogError("ClientCallback \"%s\" ran into an error!", name)
		else
			LogError("ClientCallback \"%s\" ran into the following error:\n%s", name, returnData[2])
		end

		TriggerServerEvent("KI:ccError", requestName, name, returnData[2])

		return
	end

	table.remove(returnData, 1)

	TriggerServerEvent("KI:ccResponse", requestName, returnData)
end)

-- receive data from ServerCallback
RegisterNetEvent("KI:scResponse", function(requestName, data)
	if (callbackResponses[requestName] == nil) then return end

	callbackResponses[requestName] = data
end)

-- ServerCallback does not exist
RegisterNetEvent("KI:scDoesNotExist", function(requestName, name)
	if (callbackResponses[requestName] == nil) then return end

	callbackResponses[requestName] = "ERROR"

	LogError(
		"ServerCallback \"%s\" does not exist!^0\n" .. 
		"    Potential solutions:\n" .. 
		"    - \"kimi_callbacks\" needs to be started before the script that is using this export!\n" .. 
		"    - Make sure that there is no typo in the Register or Trigger function!",
		name
	)
end)

-- error in ServerCallback
RegisterNetEvent("KI:scError", function(requestName, name, errorMessage)
	if (callbackResponses[requestName] == nil) then return end

	callbackResponses[requestName] = "ERROR"

	if (errorMessage == nil) then
		LogError("ServerCallback \"%s\" ran into an error! Check the server console for errors!", name)
	else
		LogError("ServerCallback \"%s\" ran into the following error:\n%s", name, errorMessage)
	end
end)



-- declare exports
exports("Register", Register)
exports("Trigger", Trigger)
exports("TriggerWithTimeout", TriggerWithTimeout)
exports("TriggerAsync", TriggerAsync)
exports("TriggerWithTimeoutAsync", TriggerWithTimeoutAsync)
