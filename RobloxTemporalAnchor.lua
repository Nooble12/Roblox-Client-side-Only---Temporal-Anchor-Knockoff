--[[
-- A client-side only script that is basically a knockoff of Protea's Temporal Anchor from Warframe.
-- Not optimized at all. Just something I threw together in about an hour for fun.
-- @author Nooble
-- @version 1.0
]]

--Includes
local inputService = game:GetService("UserInputService")
local tweenService = game:GetService("TweenService")

local player = game.Players.LocalPlayer

local abilityIsActive = false

local playerPositionTable = {}

local cloneTable = {}

--[[
-- Gets the position of the player and stores it in a table.
]]
local function CapturePlayerWorldData()
	local playerPosition = player.Character.HumanoidRootPart.CFrame.Position
	table.insert(playerPositionTable, playerPosition)
end

--[[
-- Disables player collision with the clones by changing their collision group.
]]
local function DisablePlayerCollide(inCharacter)
	for _, child in pairs(inCharacter:GetDescendants()) do
		if child:IsA("BasePart") then 
			child.CollisionGroup = "Character" 
		end
	end
end

--[[
-- Adds the character clone into the table.
-- @param inClone The player clone.
]]
local function CaptureCharacterClone(inClone)
	table.insert(cloneTable, inClone)
end

--[[
-- Sets the transparency of clone parts to 0.5
-- @param characterClone The player clone.
]]
local function SetTransparency(characterClone)
	for _, descendant in ipairs(characterClone:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Transparency = 0.5
		end
	end
end

--[[
-- Hides the clone nametags
-- @param characterClone The player clone.
]]
local function HideCloneName(characterClone)
	characterClone.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
end

--[[
-- Clones the player
]]
local function CreatePlayerClone()
	print("Clone Created")
	local character = player.Character
	
	character.Archivable = true
	local playerClone = character:Clone()
	DisablePlayerCollide(character)
	playerClone.Parent = game.Workspace
	playerClone:FindFirstChild("HumanoidRootPart").Anchored = true
	playerClone:SetPrimaryPartCFrame(player.Character.HumanoidRootPart.CFrame)
	CapturePlayerWorldData()
	CaptureCharacterClone(playerClone)
	SetTransparency(playerClone)
	HideCloneName(playerClone)
end

--[[
-- Reverses a table. Used to play back the actions of the player.
-- @param inTable The table to be reversed.
]]
local function ReverseTable(inTable)
	local reversedTable = {}
	
	for i = #inTable, 0, -1 do
		table.insert(reversedTable, inTable[i])
	end
	return reversedTable
end

--[[
-- Resets the table back to nil values.
]]
local function ResetTables()
	cloneTable = {}
	playerPositionTable = {}
end

--[[
-- Handles the tweening of player position to recorded positions from the playerPositionTable.
]]
local function EndAbility()
	player.Character.HumanoidRootPart.Anchored = true
	
	local info = TweenInfo.new( 
		0.02, 
		Enum.EasingStyle.Sine,
		Enum.EasingDirection.In,
		0,
		false 
	) 
	
	local characterHumanoidRootPart = player.Character:WaitForChild("HumanoidRootPart")
	
	local reversedPositionTable = ReverseTable(playerPositionTable)
	characterHumanoidRootPart.Anchored = true
	
	local reversedCharacterTable = ReverseTable(cloneTable)
	
	for _, position in ipairs(reversedPositionTable) do
		local targetCFrame = CFrame.new(position)

		local tween = tweenService:Create(characterHumanoidRootPart, info, {CFrame = targetCFrame})
		tween:Play()
		tween.Completed:Wait()
	end
	
	for _, character in ipairs(reversedCharacterTable) do
		character:Destroy()
	end
	
	ResetTables()
	
	characterHumanoidRootPart.Anchored = false
end

--[[
-- On ability activation, create a clone and begin recording the player position.
]]
local function ActivateAbility()
	local maxPositionSamples = 200
	
	if (abilityIsActive == false) then
		abilityIsActive = true
		
		--Inital
		CreatePlayerClone()
		CapturePlayerWorldData()
		
		local counter = 0
		while (counter < maxPositionSamples) do
			counter = counter + 1
			
			if(counter%9 == 0) then
				CreatePlayerClone()
			end
			
			CapturePlayerWorldData()
			task.wait(0.05)
		end
		EndAbility()
	end
	abilityIsActive = false
end

inputService.InputBegan:Connect(function()
	if inputService:IsKeyDown(Enum.KeyCode.X) then
		ActivateAbility()
	end
end)