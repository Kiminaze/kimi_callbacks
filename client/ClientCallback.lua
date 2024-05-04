
local SC_TIMEOUT <const> = [[
ServerCallback \"%s\" timed out after %sms!^0
    Potential solutions:
    - There was an error on server side. Please check the server console!
    - Player ping was higher than the specified timeout.
]]
local SC_DOES_NOT_EXIST <const> = [[
ServerCallback \"%s\" does not exist!^0
    Potential solutions:
    - \"kimi_callbacks\" needs to be started before the script that is using this export!
    - Make sure that there is no typo in the Register or Trigger function!
]]
local SC_ERROR <const> = "ServerCallback \"%s\" ran into an error! Check the server console for errors!"
local SC_ERROR_SPECIFIED <const> = "ServerCallback \"%s\" ran into the following error:\n%s"

local CC_DOES_NOT_EXIST <const> = [[
ClientCallback \"%s\" does not exist!^0
    Potential solutions:
    - \"kimi_callbacks\" needs to be started before the script that is using this export!
    - Make sure that there is no typo in the Register or Trigger function!
]]
local CC_ERROR <const> = "ClientCallback \"%s\" ran into an error!"
local CC_ERROR_SPECIFIED <const> = "ClientCallback \"%s\" ran into the following error:\n%s"

local MIN_INT <const> = math.mininteger
local MAX_INT <const> = math.maxinteger

local table_pack = table.pack
local table_unpack = table.unpack
local table_remove = table.remove

local callbackResponses = {}
local currentRequestId = MIN_INT

local callbacks = {}



-- log error to console
local ERROR_PREFIX <const> = "^1[ERROR] %s^0"
local function LogError(text, ...)
	print(ERROR_PREFIX:format(text):format(...))
end

-- check export parameter
local PARAM_ERROR <const> = "Parameter \"%s\" must be a %s!"
local function CheckParameter(paramValue, paramName, paramType)
	if (paramType == "function") then
		assert(paramValue ~= nil and type(paramValue) == "table" and getmetatable(paramValue) ~= nil, PARAM_ERROR:format(paramName, paramType))
	else
		assert(paramValue ~= nil and type(paramValue) == paramType, PARAM_ERROR:format(paramName, paramType))
	end
end



-- register new callback
local function Register(name, callback)
	CheckParameter(name, "name", "string")
	CheckParameter(callback, "callback", "function")

	callbacks[name] = callback
end
exports("Register", Register)

-- remove a callback
local function Remove(name)
	CheckParameter(name, "name", "string")

	callbacks[name] = nil
end
exports("Remove", Remove)



-- trigger callback with custom timeout
local function TriggerWithTimeout(name, timeout, ...)
	CheckParameter(name, "name", "string")
	CheckParameter(timeout, "timeout", "number")

	-- get id for current request and advance for next
	local requestId = currentRequestId
	currentRequestId = currentRequestId + 1
	if (currentRequestId >= MAX_INT) then
		currentRequestId = MIN_INT
	end

	-- send data to server
	TriggerServerEvent("KC:sc", name, requestId, { ... })

	-- await cb response and handle timeout
	local requestName = name .. tostring(requestId)

	callbackResponses[requestName] = true

	local endTime = GetGameTimer() + timeout
	while (callbackResponses[requestName] == true) do
		Wait(0)

		if (GetGameTimer() > endTime) then
			callbackResponses[requestName] = "ERROR"

			LogError(SC_TIMEOUT, name, timeout)

			break
		end
	end

	-- return on error
	if (callbackResponses[requestName] == "ERROR") then return end

	-- return unpacked data
	local data = callbackResponses[requestName]
	callbackResponses[requestName] = nil
	return table_unpack(data)
end
exports("TriggerWithTimeout", TriggerWithTimeout)

-- trigger callback with default timeout (5000ms)
local function Trigger(name, ...)
	return TriggerWithTimeout(name, 5000, ...)
end
exports("Trigger", Trigger)



-- trigger callback asynchronously and call a function with custom timeout
local function TriggerWithTimeoutAsync(name, timeout, callback, ...)
	CheckParameter(callback, "callback", "function")

	local args = { ... }
	CreateThread(function()
		callback(TriggerWithTimeout(name, timeout, args))
	end)
end
exports("TriggerWithTimeoutAsync", TriggerWithTimeoutAsync)

-- trigger callback asynchronously and call a function with default timeout (5000ms)
local function TriggerAsync(name, callback, ...)
	CheckParameter(callback, "callback", "function")

	local args = { ... }
	CreateThread(function()
		callback(Trigger(name, args))
	end)
end
exports("TriggerAsync", TriggerAsync)



-- execute ClientCallback
RegisterNetEvent("KC:cc", function(name, requestId, data)
	if (callbacks[name] == nil) then
		LogError(CC_DOES_NOT_EXIST, name)

		TriggerServerEvent("KC:ccDoesNotExist", name, requestId)

		return
	end

	-- execute callback
	local returnData = table_pack(pcall(callbacks[name], table_unpack(data)))
	if (not returnData[1]) then
		-- error in callback function
		LogError(returnData[2] and CC_ERROR_SPECIFIED or CC_ERROR, name, returnData[2])

		TriggerServerEvent("KC:ccError", name, requestId, returnData[2])

		return
	end

	table_remove(returnData, 1)

	-- send result to server
	TriggerServerEvent("KC:ccResponse", name .. tostring(requestId), returnData)
end)

-- receive data from ServerCallback
RegisterNetEvent("KC:scResponse", function(requestName, data)
	if (callbackResponses[requestName] == nil) then return end

	callbackResponses[requestName] = data
end)

-- ServerCallback does not exist
RegisterNetEvent("KC:scDoesNotExist", function(name, requestId)
	local requestName = name .. tostring(requestId)

	if (callbackResponses[requestName] == nil) then return end

	callbackResponses[requestName] = "ERROR"

	LogError(SC_DOES_NOT_EXIST, name)
end)

-- error in ServerCallback
RegisterNetEvent("KC:scError", function(name, requestId, errorMessage)
	local requestName = name .. tostring(requestId)

	if (callbackResponses[requestName] == nil) then return end

	callbackResponses[requestName] = "ERROR"

	LogError(errorMessage and SC_ERROR_SPECIFIED or SC_ERROR, name, errorMessage)
end)
