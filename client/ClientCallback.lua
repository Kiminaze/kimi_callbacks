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
function Trigger(name, ...)
	assert(name ~= nil and type(name) == "string", "Parameter \"name\" must be a string!")

	return TriggerWithTimeout(name, 5000, ...)
end

-- trigger callback with custom timeout
function TriggerWithTimeout(name, timeout, ...)
	assert(name ~= nil and type(name) == "string", "Parameter \"name\" must be a string!")
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

	-- send data to server
	TriggerServerEvent("KI:sc", name, requestId, { ... })

	-- await cb response
	local timer = GetGameTimer()
	while (callbackResponses[requestName] == true) do
		Citizen.Wait(0)

		if (GetGameTimer() > timer + timeout) then
			-- timed out
			print(
				"^1[ERROR] ServerCallback \"" .. name .. "\" timed out after " .. tostring(timeout) .. "ms!^0\n" .. 
				"    Potential solutions:\n" .. 
				"    - There was an error on server side. Please check the server console!\n" .. 
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

RegisterNetEvent("KI:cc")
AddEventHandler("KI:cc", function(name, requestId, data)
	local requestName = name .. tostring(requestId)

	if (callbacks[name] ~= nil) then
		-- execute callback function and return its result
		local result = { callbacks[name](table.unpack(data)) }
		
		TriggerServerEvent("KI:ccResponse", requestName, result)
	else
		-- callback does not exist
		print(
			"^1[ERROR] ClientCallback \"" .. name .. "\" does not exist!^0\n" .. 
			"    Potential solutions:\n" .. 
			"    - \"kimi_callbacks\" needs to be started before the script that is using this export!\n" .. 
			"    - Make sure that there is no typo in the Register or Trigger function!"
		)
		
		TriggerServerEvent("KI:ccDoesNotExist", requestName, name)
	end
end)

RegisterNetEvent("KI:scResponse")
AddEventHandler("KI:scResponse", function(requestName, data)
	if (callbackResponses[requestName] ~= nil) then
		-- receive data
		callbackResponses[requestName] = data
	end
end)

RegisterNetEvent("KI:scDoesNotExist")
AddEventHandler("KI:scDoesNotExist", function(requestName, name)
	if (callbackResponses[requestName] ~= nil) then
		callbackResponses[requestName] = "ERROR"

		print(
			"^1[ERROR] ServerCallback \"" .. name .. "\" does not exist!^0\n" .. 
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
