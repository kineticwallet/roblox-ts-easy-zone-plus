--!nocheck
--!optimize 2

local players = game:GetService("Players")
local runService = game:GetService("RunService")
local heartbeat = runService.Heartbeat
local Signal = require(script.Parent.Parent.Signal)
local Janitor = require(script.Parent.Parent.Janitor)

local Tracker = {}
Tracker.__index = Tracker
local trackers = {}
Tracker.trackers = trackers
Tracker.itemAdded = Signal.new()
Tracker.itemRemoved = Signal.new()
Tracker.bodyPartsToIgnore = {

	UpperTorso = true,
	LowerTorso = true,
	Torso = true,
	LeftHand = true,
	RightHand = true,
	LeftFoot = true,
	RightFoot = true,
}

function Tracker.getCombinedTotalVolumes()
	local combinedVolume = 0
	for tracker, _ in pairs(trackers) do
		combinedVolume += tracker.totalVolume
	end
	return combinedVolume
end

function Tracker.getCharacterSize(character)
	local head = character and character:FindFirstChild("Head")
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not (hrp and head) then
		return nil
	end
	if not head:IsA("BasePart") then
		head = hrp
	end
	local headY = head.Size.Y
	local hrpSize = hrp.Size
	local charSize = (hrpSize * Vector3.new(2, 2, 1)) + Vector3.new(0, headY, 0)
	local charCFrame = hrp.CFrame * CFrame.new(0, headY / 2 - hrpSize.Y / 2, 0)
	return charSize, charCFrame
end

function Tracker.new(name)
	local self = {}
	setmetatable(self, Tracker)

	self.name = name
	self.totalVolume = 0
	self.parts = {}
	self.partToItem = {}
	self.items = {}
	self.whitelistParams = nil
	self.characters = {}
	self.baseParts = {}
	self.exitDetections = {}
	self.janitor = Janitor.new()

	if name == "player" then
		local function updatePlayerCharacters()
			local characters = {}
			for _, player in pairs(players:GetPlayers()) do
				local character = player.Character
				if character then
					characters[character] = true
				end
			end
			self.characters = characters
		end

		local function playerAdded(player)
			local function charAdded(character)
				local function trackChar()
					local hrp = character:WaitForChild("HumanoidRootPart", 0.1)
					local humanoid = character:WaitForChild("Humanoid", 0.1)
					local head = character:WaitForChild("Head", 0.1)
					if hrp == nil or humanoid == nil or head == nil then
						return
					end
					updatePlayerCharacters()
					self:update()
					for _, valueInstance in pairs(humanoid:GetChildren()) do
						if valueInstance:IsA("NumberValue") then
							valueInstance.Changed:Connect(function()
								self:update()
							end)
						end
					end
				end
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if hrp then
					task.delay(0.1, trackChar)
				else
					character.ChildAdded:Connect(function(child)
						if child.Name == "HumanoidRootPart" and child:IsA("BasePart") then
							task.delay(0.1, trackChar)
						end
					end)
				end
			end
			if player.Character then
				task.spawn(charAdded, player.Character)
			end
			player.CharacterAdded:Connect(function(char)
				charAdded(char)
			end)
			player.CharacterRemoving:Connect(function(removingCharacter)
				self.exitDetections[removingCharacter] = nil
			end)
		end

		players.PlayerAdded:Connect(playerAdded)
		for _, player in pairs(players:GetPlayers()) do
			playerAdded(player)
		end

		players.PlayerRemoving:Connect(function(player)
			updatePlayerCharacters()
			self:update()
		end)
	elseif name == "item" then
		local function updateItem(itemDetail, newValue)
			if itemDetail.isCharacter then
				self.characters[itemDetail.item] = newValue
			elseif itemDetail.isBasePart then
				self.baseParts[itemDetail.item] = newValue
			end
			self:update()
		end
		Tracker.itemAdded:Connect(function(itemDetail)
			task.spawn(updateItem, itemDetail, true)
		end)
		Tracker.itemRemoved:Connect(function(itemDetail)
			self.exitDetections[itemDetail.item] = nil
			updateItem(itemDetail, nil)
		end)
	end

	trackers[self] = true
	task.defer(self.update, self)
	return self
end

function Tracker:_preventMultiFrameUpdates(methodName, ...)
	self._preventMultiDetails = self._preventMultiDetails or {}
	local detail = self._preventMultiDetails[methodName]
	if not detail then
		detail = {
			calling = false,
			callsThisFrame = 0,
			updatedThisFrame = false,
		}
		self._preventMultiDetails[methodName] = detail
	end

	detail.callsThisFrame += 1
	if detail.callsThisFrame == 1 then
		local args = table.pack(...)
		task.defer(function()
			local newCallsThisFrame = detail.callsThisFrame
			detail.callsThisFrame = 0
			if newCallsThisFrame > 1 then
				self[methodName](self, unpack(args))
			end
		end)
		return false
	end
	return true
end

function Tracker:update()
	if self:_preventMultiFrameUpdates("update") then
		return
	end

	self.totalVolume = 0
	self.parts = {}
	self.partToItem = {}
	self.items = {}

	for character, _ in pairs(self.characters) do
		local charSize = Tracker.getCharacterSize(character)
		if not charSize then
			continue
		end
		local rSize = charSize
		local charVolume = rSize.X * rSize.Y * rSize.Z
		self.totalVolume += charVolume

		local characterJanitor = self.janitor:Add(Janitor.new(), "Destroy", "trackCharacterParts-" .. self.name)
		local function updateTrackerOnParentChanged(instance)
			characterJanitor:Add(
				instance.Destroying:Connect(function()
					if not instance:IsDescendantOf(game) then
						if instance.Parent == nil and characterJanitor ~= nil then
							characterJanitor:Destroy()
							characterJanitor = nil
							task.defer(self.update, self)
						end
					end
				end),
				"Disconnect"
			)
		end

		for _, part in pairs(character:GetChildren()) do
			if part:IsA("BasePart") and not Tracker.bodyPartsToIgnore[part.Name] then
				self.partToItem[part] = character
				table.insert(self.parts, part)
				updateTrackerOnParentChanged(part)
			end
		end
		updateTrackerOnParentChanged(character)
		table.insert(self.items, character)
	end

	for additionalPart, _ in pairs(self.baseParts) do
		local rSize = additionalPart.Size
		local partVolume = rSize.X * rSize.Y * rSize.Z
		self.totalVolume += partVolume
		self.partToItem[additionalPart] = additionalPart
		table.insert(self.parts, additionalPart)
		table.insert(self.items, additionalPart)
	end

	self.whitelistParams = OverlapParams.new()
	self.whitelistParams.FilterType = Enum.RaycastFilterType.Whitelist
	self.whitelistParams.MaxParts = #self.parts
	self.whitelistParams.FilterDescendantsInstances = self.parts
end

return Tracker
