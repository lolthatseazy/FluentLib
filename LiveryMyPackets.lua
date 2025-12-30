local PacketLib = {}
PacketLib.__index = PacketLib

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")

function PacketLib.new(communicationChannel)
	local self = setmetatable({}, PacketLib)
	self.PacketPrefix = HttpService:GenerateGUID(false)
	self.Communication = communicationChannel or TextChatService.TextChannels.RBXGeneral
	self.LocalPlayer = Players.LocalPlayer
	self._handlers = {}
	
	self._connection = self.Communication.MessageReceived:Connect(function(message)
		local packetData = message.Metadata
		local textSource = message.TextSource
		if not packetData or not textSource then return end
		if packetData:sub(1, #self.PacketPrefix) ~= self.PacketPrefix then return end
		if textSource.UserId == self.LocalPlayer.UserId then return end
		
		local Player = Players:GetPlayerByUserId(textSource.UserId)
		if not Player then return end
		
		local jsonData = packetData:sub(#self.PacketPrefix + 1)
		local decoded
		pcall(function()
			decoded = HttpService:JSONDecode(jsonData)
		end)
		if not decoded then return end
		
		local packetName = decoded.Packet
		local extra = decoded.Extra
		
		self:_handlePacket(packetName, Player, textSource, message, extra)
	end)

	return self
end

function PacketLib:_handlePacket(packetName, Player, textSource, message, extra)
	local handler = self._handlers[packetName]
	if handler then
		handler(Player, textSource, message, extra)
	end
end

function PacketLib:Listen(serverName)
	self.PacketPrefix = serverName
end

function PacketLib:On(packetName, callback)
	assert(type(callback) == "function", "Callback must be a function")
	self._handlers[packetName] = callback
end

function PacketLib:Send(packetName)
	assert(type(packetName) == "string", "packetName must be string")
	local packetData = self.PacketPrefix .. packetName
	self.Communication:SendAsync("", packetData)
	return packetData
end

function PacketLib:SendAsync(packetName, extra)
	assert(type(packetName) == "string", "packetName must be string")
	local data = {
		Packet = packetName,
		Extra = extra
	}
	local encoded = HttpService:JSONEncode(data)
	local packetData = self.PacketPrefix .. encoded
	self.Communication:SendAsync("", packetData)
	return packetData
end

function PacketLib:DeletePacket(packetName)
	assert(type(packetName) == "string", "packetName must be string")
	if self._handlers[packetName] then
		self._handlers[packetName] = nil
		return true
	end
	return false
end

function PacketLib:Destroy()
	if self._connection then
		self._connection:Disconnect()
		self._connection = nil
	end
	self._handlers = {}
end

return PacketLib