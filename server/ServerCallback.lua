local callbackResponses = {}
local currentRequestId = 0

local callbacks = {}

-- register new callback
function Register(name, cb)
	callbacks[name] = cb
end

-- trigger callback
function Trigger(name, playerId, ...)
	return TriggerWithTimeout(name, playerId, 5000, ...)
end

-- trigger callback with custom timeout
function TriggerWithTimeout(name, playerId, timeout, ...)
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
			print("^1[ERROR] ClientCallback \"" .. name .. "\" timed out after " .. tostring(timeout) .. "ms!")
			
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

RegisterServerEvent("KI:sc")
AddEventHandler("KI:sc", function(name, requestId, data)
	local requestName = name .. tostring(requestId)

	if (callbacks[name] ~= nil) then
		-- execute callback function and return its result
		local result = { callbacks[name](source, table.unpack(data)) }
		
		TriggerClientEvent("KI:scResponse", source, requestName, result)
	else
		-- callback does not exist
		print("^1[ERROR] ServerCallback \"" .. name .. "\" does not exist!")
		
		TriggerClientEvent("KI:scDoesNotExist", source, requestName)
	end
end)

RegisterServerEvent("KI:ccResponse")
AddEventHandler("KI:ccResponse", function(requestName, data)
	if (callbackResponses[requestName] ~= nil) then
		-- receive data
		callbackResponses[requestName] = data
	end
end)

RegisterServerEvent("KI:ccDoesNotExist")
AddEventHandler("KI:ccDoesNotExist", function(requestName)
	if (callbackResponses[requestName] ~= nil) then
		callbackResponses[requestName] = "ERROR"
		
		print("^1[ERROR] ClientCallback \"" .. name .. "\" does not exist!")
	end
end)
