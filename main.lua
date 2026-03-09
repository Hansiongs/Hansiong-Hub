-- Advanced Fishing Constants
local POWER_THRESHOLD = 0.96
local COOLDOWN_POLL = 0.1
local INSTANT_CATCH_DELAY = 4
local FEATURES = getgenv().FEATURES
local MORECOOLDOWN = getgenv().MORECOOLDOWN


local FAVORITE_CONFIG = {
	WhitelistId = {
		[243] = true,  -- Ruby
	},
	WhitelistVariant = {
		["Gemstone"] = true,
	},
	FavoriteTiers = 7
}

-- Teleport Locations
local LOCATIONS = {
	["Sisyphus Statue"] = CFrame.new(-3729.25,-130.07,-885.64),
	["Esoteric Depths"] = CFrame.new(3253.03,-1288.65,1433.85),
	["Treasure Room"] = CFrame.new(-3581.60,-274.07,-1589.65),
	["Underground Cellar"] = CFrame.new(2135.45,-86.20,-699.33),
	["Sacred Temple"] = CFrame.new(1451.41,-17.13,-635.65),
	["Kohana Volcano"] = CFrame.new(-551.98,23.55,182.16),
	["Hourglass Diamond Artifact"] = CFrame.new(1487.58, 3.78,-843.49) * CFrame.Angles(0, math.rad(180), 0),
	["Crescent Artifact"] = CFrame.new(1400.68, 3.34, 121.89) * CFrame.Angles(0, math.rad(180), 0),
	["Diamond Artifact"] = CFrame.new(1837.77, 5.29, -299.71) * CFrame.Angles(0, math.rad(270), 0),
	["Arrow Artifact"] = CFrame.new(879.46, 4.29, -334.11) * CFrame.Angles(0, math.rad(90), 0),
	["Crater Island"] = CFrame.new(998.03, 2.86, 5151.16),
	["Double Enchant Altar"] = CFrame.new(1480.07, 127.62, -589.82),
	["Enchant Altar"] = CFrame.new(3255.68, -1301.53, 1371.82),
	["Tropical Island"] = CFrame.new(-2152.61, 2.32, 3671.71),
	["Coral Reefs"] = CFrame.new(-3181.38, 2.52, 2104.35),
	["Ancient Jungle"] = CFrame.new(1275.10, 9, -334.75),
	["Kohana"] = CFrame.new(-661.67, 3.04, 714.14),
	["Ancient Ruin"] = CFrame.new(6099.12, -580, 4665.00),
	["Christmast Island"] = CFrame.new(1137.03, 28, 1559.69),
	["Iron Cavern"] = CFrame.new(-8800.58, -580, 241.26),
	["Tropical Grove"] = CFrame.new(-2154.49,7,3670.67),
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

-- Wait for game to load
if not game:IsLoaded() then
	game.Loaded:Wait()
end

-- Game Modules
local FishingController = require(ReplicatedStorage.Controllers.FishingController)
local VendorController = require(ReplicatedStorage.Controllers.VendorController)
local PromptController = require(ReplicatedStorage.Controllers.PromptController)
local Replion = require(ReplicatedStorage.Packages.Replion)
local PromiseModule = require(ReplicatedStorage.Packages.Promise)
local Constants = require(ReplicatedStorage.Shared.Constants)
local HttpService = game:GetService("HttpService")
local AFKController = require(ReplicatedStorage.Controllers.AFKController)
local DataReplion = Replion.Client:WaitReplion("Data")
local AreaUtility = require(ReplicatedStorage.Shared.AreaUtility)
local TileInteractionController = require(ReplicatedStorage.Controllers.InventoryController.TileInteraction)
local GuiControl = require(ReplicatedStorage.Modules.GuiControl)
local MerchantController = require(ReplicatedStorage.Controllers.TravelingMerchantController)

print("[AutoFish] Modules loaded")

--================================================
-- STATE VARIABLES
--================================================

local State = {
	ScreenGui = nil,
	StartPosition = nil,
	CatchCount = 0,
	SuccessCount = 9999,
	SellDebounce = false,
	DynamicLocation = nil,
	CanCatchSecret = false,
	OwnedRods = {},
	OwnedBaits = {},
	BestRodUid = nil,
	BestRodId = nil,
	BestBaitId = nil,
	BestEnchant1 = "None",
	BestEnchant2 = "None",
}

--================================================
-- UTILITY FUNCTIONS
--================================================

local function PrintConfig()
	print("[AutoFish] Starting fishing...")
	print(string.format(
		"[AutoFish] Features: LOW_GFX=%s | ERROR=%s | 3D_OFF=%s | NO_NOTIF=%s | AUTO_SELL=%s",
		tostring(FEATURES.LOW_GRAPHICS),
		tostring(FEATURES.ERROR_HANDLER),
		tostring(FEATURES.DISABLE_3D),
		tostring(FEATURES.DISABLE_NOTIFICATIONS),
		tostring(FEATURES.AUTO_SELL)
	))
end

task.spawn(function()
	while true do
		task.wait(60)
		AFKController:RemoveTime("AntiAFK")
	end
end)

local function EquipToolbarSlot(slotNumber)
	slotNumber = slotNumber or 1
	if LocalPlayer:GetAttribute("Loading") ~= false then task.wait(1) end
	
	local backpackGui = LocalPlayer.PlayerGui:FindFirstChild("Backpack")
	if not backpackGui then return false end
	local display = backpackGui:FindFirstChild("Display")
	if not display then return false end
	
	local wasDisabled = not backpackGui.Enabled
	if wasDisabled then backpackGui.Enabled = true task.wait(0.1) end
	
	local targetTile = nil
	for _, child in pairs(display:GetChildren()) do
		if (child:IsA("GuiButton") or child:IsA("ImageButton") or child:IsA("TextButton")) 
		and child.LayoutOrder == slotNumber then
			targetTile = child
			break
		end
	end
	
	local success = false
	if targetTile then
		local ok = pcall(function() if firesignal then firesignal(targetTile.Activated) success = true end end)
		if not success then pcall(function() if fireclick then fireclick(targetTile) success = true end end) end
		if not success then
			pcall(function()
				if firetouchinterest then
					firetouchinterest(targetTile, LocalPlayer:GetMouse(), 0)
					task.wait(0.05)
					firetouchinterest(targetTile, LocalPlayer:GetMouse(), 1)
					success = true
				end
			end)
		end
	end
	
	if wasDisabled then task.wait(0.2) backpackGui.Enabled = false end
	if success then task.wait(0.3) end
	return success
end

-- ==========================================
-- FUNGSI MASTER AUTO-BUY
-- ==========================================
local function PurchaseFromShop(targetShop, targetName)
	GuiControl:Open(targetShop)
	
	local shopUI = PlayerGui:WaitForChild(targetShop, 3)
	if not shopUI then 
		return false 
	end
	
	local scrollingFrame = nil
	if targetShop == "Merchant" then
		scrollingFrame = shopUI:FindFirstChild("Main")
			and shopUI.Main:FindFirstChild("Background")
			and shopUI.Main.Background:FindFirstChild("Items")
			and shopUI.Main.Background.Items:FindFirstChild("ScrollingFrame")
	else
		scrollingFrame = shopUI:FindFirstChild("Main")
			and shopUI.Main:FindFirstChild("Content")
			and shopUI.Main.Content:FindFirstChild("List")
			and shopUI.Main.Content.List:FindFirstChild("ScrollingFrame")
	end
		
	if not scrollingFrame then 
		GuiControl:Close(targetShop) 
		return false 
	end
	
	local waitTime = 0
	while #scrollingFrame:GetChildren() <= 2 and waitTime < 5 do
		task.wait(0.5)
		waitTime = waitTime + 0.5
	end
	
	local isSuccess = false
	
	for _, tile in ipairs(scrollingFrame:GetChildren()) do
		if not tile:IsA("UIComponent") then
			local label = nil
			
			if targetShop == "Merchant" then
				label = tile:FindFirstChild("Frame") and tile.Frame:FindFirstChild("ItemName")
			else
				label = tile:FindFirstChild("Padded") and tile.Padded:FindFirstChild("Top") and tile.Padded.Top:FindFirstChild("Label")
			end
				
			if label and label:IsA("TextLabel") then
				local itemName = tostring(label.Text)
				
				if string.find(string.lower(itemName), string.lower(targetName)) then
					if targetShop == "Merchant" then
						local itemId = tile.LayoutOrder 
						local marketData = MerchantController:GetMarketDataFromId(itemId)
						
						if marketData then
							MerchantController:InitiatePurchase(itemId, marketData)
							isSuccess = true
							break
						end
					else
						local buyButton = tile:FindFirstChild("Padded") and tile.Padded:FindFirstChild("Buy")
						if buyButton and getconnections then
							local clickEvents = {"Activated", "MouseButton1Click", "MouseButton1Down", "MouseButton1Up"}
							for _, eventName in ipairs(clickEvents) do
								local connections = getconnections(buyButton[eventName])
								if connections then
									for _, conn in ipairs(connections) do
										conn:Fire() 
									end
								end
							end
							isSuccess = true
							break
						end
					end
				end
			end
		end
	end
	
	task.wait(1) 
	GuiControl:Close(targetShop)
	
	return isSuccess
end

--================================================
-- QUEST SYSTEM LOGIC
--================================================

local function contains(tbl, val)
	for _, v in ipairs(tbl) do
		if v == val then return true end
	end
	return false
end

local function CheckProgress(progressText)
	if not progressText then return false end
	local cleanText = string.gsub(progressText, ",", "")
	local current, required = string.match(cleanText, "(%d+)%s*/%s*(%d+)")
	if current and required then
		return tonumber(current) >= tonumber(required)
	end
	if string.find(cleanText, "100%%") then return true end
	return false
end

local function GetDeepSeaQuest()
	local pGui = LocalPlayer:FindFirstChild("PlayerGui")
	local questList = pGui and pGui:FindFirstChild("Quest") and pGui.Quest:FindFirstChild("List") and pGui.Quest.List:FindFirstChild("Inside")
	local results = {"1/1", "1/1", "1/1", "1/1"}

	if questList then
		for _, q in ipairs(questList:GetChildren()) do
			if q:FindFirstChild("Content") then
				local obj1 = q.Content:FindFirstChild("Objective1")
				if obj1 and obj1:FindFirstChild("Prefix", true) and string.find(obj1:FindFirstChild("Prefix", true).Text, "300") then
					for i = 1, 4 do
						local progObj = q.Content:FindFirstChild("Objective" .. i):FindFirstChild("Progress", true)
						if progObj then
							results[i] = progObj.Text
						else
							results[i] = "1/1"
						end
					end
					break
				end
			end
		end
	end
	return results
end

local function GetJungle2025Quest()
	local pGui = LocalPlayer:FindFirstChild("PlayerGui")
	local questList = pGui and pGui:FindFirstChild("Quest") and pGui.Quest:FindFirstChild("List") and pGui.Quest.List:FindFirstChild("Inside")
	local results = {"1/1", "1/1", "1/1", "1/1"}

	if questList then
		for _, q in ipairs(questList:GetChildren()) do
			if q:FindFirstChild("Content") then
				local isTarget = false
				for _, txt in ipairs(q.Content:GetDescendants()) do
					if txt:IsA("TextLabel") and (string.find(txt.Text, "Create 3") or string.find(txt.Text, "Element")) then
						isTarget = true
						break
					end
				end

				if isTarget then
					for i = 1, 4 do
						local objFrame = q.Content:FindFirstChild("Objective" .. i)
						local progObj = objFrame and objFrame:FindFirstChild("Progress", true)
						if progObj then
							results[i] = progObj.Text
						else
							results[i] = "1/1"
						end
					end
					break
				end
			end
		end
	end
	return results
end

local function GetTempleLevers()
	return DataReplion:Get("TempleLevers") or {}
end

local function GetCoin()
	return DataReplion:Get("Coins")
end

local function PlaceLever(artifactName)
	local found = false
	for _, leverPart in pairs(CollectionService:GetTagged("Lever")) do
		local leverModel = leverPart.Parent
		if leverModel and leverModel:GetAttribute("Type") == artifactName then
			local prompt = leverPart:FindFirstChildOfClass("ProximityPrompt")
			
			if prompt then
				print("Ditemukan lever untuk: " .. artifactName .. ". Memicu interaksi...")
				if fireproximityprompt then
					fireproximityprompt(prompt)
				else
					prompt:InputBegan(Enum.UserInputType.MouseButton1) 
				end
				
				found = true
				break
			end
		end
	end
	
	if not found then
		warn("Lever dengan tipe '" .. tostring(artifactName) .. "' tidak ditemukan di map!")
	end
end

--================================================
-- DATABASE & INVENTORY (GETRODS, GETBAITS)
--================================================

local DBFish = nil
local DBRod = nil
local DBBait = nil
local DBTotem = nil
local DBEnchant = nil
local EnchantMap = {}

local function LoadDatabases()
	pcall(function()
		DBFish = HttpService:JSONDecode(game:HttpGet('https://raw.githubusercontent.com/Hansiongs/Hansiong-Hub/refs/heads/main/fishlists'))
		DBRod = HttpService:JSONDecode(game:HttpGet('https://raw.githubusercontent.com/Hansiongs/Hansiong-Hub/refs/heads/main/rodlists'))
		DBBait = HttpService:JSONDecode(game:HttpGet('https://raw.githubusercontent.com/Hansiongs/Hansiong-Hub/refs/heads/main/baitlists'))
		DBTotem = HttpService:JSONDecode(game:HttpGet('https://raw.githubusercontent.com/Hansiongs/Hansiong-Hub/refs/heads/main/totemlists'))
		DBEnchant = HttpService:JSONDecode(game:HttpGet('https://raw.githubusercontent.com/Hansiongs/Hansiong-Hub/refs/heads/main/enchantlists'))
		
		for _, v in pairs(DBEnchant) do 
			EnchantMap[tostring(v.Id)] = v.EnchantName 
		end
		
		print("[AutoFish] Databases loaded successfully")
	end)
end

local function GetRods()
	local items = DataReplion:Get({"Inventory", "Fishing Rods"})
	if not items or not DBRod then return end

	local bestLuck = -1
	local bestUUID = nil
	local bestId = nil
	local bestEnchant1 = "None"
	local bestEnchant2 = "None"
	State.OwnedRods = {}
	State.CanCatchSecret = false

	for _, item in ipairs(items) do
		local rodData = DBRod[tostring(item.Id)]
		if rodData and rodData.BaseLuck then
			State.OwnedRods[item.Id] = item.UUID
			
			if rodData.BaseLuck > bestLuck then
				bestLuck = rodData.BaseLuck
				bestUUID = item.UUID
				bestId = item.Id
				
				bestEnchant1 = "None"
				bestEnchant2 = "None"

				if item.Metadata then
					if item.Metadata.EnchantId then
						local id = tostring(item.Metadata.EnchantId)
						bestEnchant1 = EnchantMap[id] or ("ID: " .. id)
					end
					if item.Metadata.EnchantId2 then
						local id = tostring(item.Metadata.EnchantId2)
						bestEnchant2 = EnchantMap[id] or ("ID: " .. id)
					end
				end
			end
			
			if rodData.BaseLuck >= 3.8 then
				State.CanCatchSecret = true
			end
		end
	end

	State.BestRodUid = bestUUID
	State.BestRodId = bestId
	State.BestEnchant1 = bestEnchant1
	State.BestEnchant2 = bestEnchant2
end

local function GetBaits()
	local items = DataReplion:Get({"Inventory", "Baits"})
	if not items or not DBBait then return end

	local bestLuck = -1
	local bestId = nil
	State.OwnedBaits = {}

	for _, item in ipairs(items) do
		local baitData = DBBait[tostring(item.Id)]
		if baitData and baitData.BaseLuck then
			State.OwnedBaits[item.Id] = item.UUID
			
			if baitData.BaseLuck > bestLuck then
				bestLuck = baitData.BaseLuck
				bestId = item.Id
			end
		end
	end

	State.BestBaitId = bestId
end

local function EquipBackpackRod(UUID)
	local targetUUID = (UUID)
	return pcall(function()
		TileInteractionController:EquipRod(targetUUID)
	end)
end

local function EquipBackpackBait(ID)
	local targetId = ID
	return pcall(function()
		TileInteractionController:EquipBait(targetId)
	end)
end

local function SpawnTotem(totemName)
	print("\n[Mulai] Mencoba spawn Totem: '" .. tostring(totemName) .. "'...")

	local targetId
	if DBTotem then
		for _, v in pairs(DBTotem) do
			if string.lower(v.Name or v.name or "") == string.lower(totemName) then
				targetId = tonumber(v.Id or v.id)
				break
			end
		end
	end
	if not targetId then return warn("[AutoSpawn] '" .. totemName .. "' ga ada di DB GitHub.") end

	if not DataReplion then return warn("[Error] Data player belum load.") end
	
	-- Helper fungsi untuk mencari totem di tas
	local function FindTotemInInv()
		local invTotems = DataReplion:Get({"Inventory", "Totems"}) or {}
		for k, v in pairs(invTotems) do
			if type(v) == "table" and tonumber(v.Id) == targetId then
				local foundObj = v
				foundObj.UUID = v.UUID or k
				return foundObj
			end
		end
		return nil
	end

	local itemObj = FindTotemInInv()
	
	-- JIKA HABIS/TIDAK ADA, OTOMATIS BELI DI MERCHANT
	if not itemObj then 
		warn("[AutoSpawn] Lu ga punya stok '" .. totemName .. "' di tas. Mencoba beli otomatis di Merchant...")
		local successBuy = PurchaseFromShop("Merchant", totemName)
		
		if successBuy then
			task.wait(1.5) -- Tunggu sinkronisasi data dari server
			itemObj = FindTotemInInv()
		end
		
		if not itemObj then
			return warn("[AutoSpawn] Gagal beli atau koin lu tidak cukup untuk '" .. totemName .. "'.") 
		end
	end

	local function GetHotbarTile()
		local display = LocalPlayer.PlayerGui:FindFirstChild("Backpack") and LocalPlayer.PlayerGui.Backpack:FindFirstChild("Display")
		if not display then return nil end
		
		local cleanName = string.gsub(string.lower(totemName), "[%s\n]", "")
		for _, child in ipairs(display:GetChildren()) do
			for _, desc in ipairs(child:GetDescendants()) do
				if desc:IsA("TextLabel") and string.find(string.gsub(string.lower(desc.Text), "[%s\n]", ""), cleanName) then
					return child
				end
			end
		end
		return nil
	end

	local fakeData = { Data = { Type = "Totems" } }
	pcall(function() TileInteractionController:HandleInventoryClick(itemObj, fakeData, false, nil) end)
	task.wait(0.5)
	
	local targetTile = GetHotbarTile()
	if not targetTile then 
		pcall(function() TileInteractionController:HandleInventoryClick(itemObj, fakeData, false, nil) end)
		task.wait(0.5)
		targetTile = GetHotbarTile()
	end

	if not targetTile then return warn("[AutoSpawn] Udah dimaksa tapi totem ga masuk Hotbar.") end

	local success = false
	if getconnections then
		pcall(function()
			for _, evt in ipairs({"Activated", "MouseButton1Click", "TouchTap"}) do
				for _, conn in ipairs(getconnections(targetTile[evt]) or {}) do conn:Fire(); success = true end
			end
		end)
	end
	if not success then pcall(function() if firesignal then firesignal(targetTile.Activated) end end) end
	if not success then pcall(function() if fireclick then fireclick(targetTile) end end) end

	task.wait(0.5)

	if getconnections then
		pcall(function()
			for _, conn in ipairs(getconnections(UserInputService.TouchTapInWorld) or {}) do 
				conn:Fire(Vector2.new(0, 0), false) 
			end
		end)
	end

	task.wait(0.5)
	EquipToolbarSlot(1)
end

--================================================
-- TELEPORT SYSTEM
--================================================

local function SafeTeleport(location)
	local success = false
	pcall(function()
		if LocalPlayer:GetAttribute("InCutscene") then
			warn("[Teleport] Cannot teleport during cutscene")
			return
		end
		
		local character = LocalPlayer.Character
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")
		
		if not rootPart then
			warn("[Teleport] Character/RootPart not found")
			return
		end
		
		print("[Teleport] Preparing teleport...")
		LocalPlayer:RequestStreamAroundAsync(location.Position)
		task.wait(0.5)
		rootPart.CFrame = location
		print("[Teleport] Teleport successful")
		success = true
	end)
	return success
end

local function UpdateQuestAndLocation()
	local targetLocation = nil

	-- Update inventory data before checking quest
	GetRods()
	GetBaits()

	-- 1. Evaluasi Quest DeepSea
	if contains(FEATURES.ACTIVE_QUESTS, "DeepSea") then
		local DeepSeaQuest = GetDeepSeaQuest()
		local isObj1Done = CheckProgress(DeepSeaQuest[1])
		local isObj2Done = CheckProgress(DeepSeaQuest[2])
		local isObj3Done = CheckProgress(DeepSeaQuest[3])
		local isObj4Done = CheckProgress(DeepSeaQuest[4])

		if not isObj1Done or not isObj2Done or not isObj3Done or not isObj4Done then
			if not State.CanCatchSecret then
				targetLocation = "Kohana Volcano" 
			elseif not isObj2Done or not isObj3Done then
				targetLocation = "Sisyphus Statue" 
			elseif not isObj1Done then
				targetLocation = "Treasure Room" 
			end
		else
			-- Hapus dari list jika sudah selesai
			for i, q in ipairs(FEATURES.ACTIVE_QUESTS) do
				if q == "DeepSea" then table.remove(FEATURES.ACTIVE_QUESTS, i) break end
			end
		end
	end

	-- 2. Evaluasi Quest Jungle2025
	if not targetLocation and contains(FEATURES.ACTIVE_QUESTS, "Jungle2025") then
		local Jungle2025Quest = GetJungle2025Quest()
		local isJungle1Done = CheckProgress(Jungle2025Quest[1])
		local isJungle2Done = CheckProgress(Jungle2025Quest[2]) 
		local isJungle3Done = CheckProgress(Jungle2025Quest[3]) 
		
		if not isJungle1Done or not isJungle2Done or not isJungle3Done then
			local TempleLevers = GetTempleLevers()
			if not TempleLevers["Diamond Artifact"] then PlaceLever("Diamond Artifact"); task.wait(0.2)
			elseif not TempleLevers["Crescent Artifact"] then PlaceLever("Crescent Artifact"); task.wait(0.2)
			elseif not TempleLevers["Hourglass Diamond Artifact"] then PlaceLever("Hourglass Diamond Artifact"); task.wait(0.2)
			elseif not TempleLevers["Arrow Artifact"] then PlaceLever("Arrow Artifact"); task.wait(0.2)
			end
			
			TempleLevers = GetTempleLevers()
			if not TempleLevers["Diamond Artifact"] then targetLocation = "Diamond Artifact"
			elseif not TempleLevers["Crescent Artifact"] then targetLocation = "Crescent Artifact"
			elseif not TempleLevers["Hourglass Diamond Artifact"] then targetLocation = "Hourglass Diamond Artifact"
			elseif not TempleLevers["Arrow Artifact"] then targetLocation = "Arrow Artifact"
			elseif not isJungle2Done then targetLocation = "Arrow Artifact" 
			elseif not isJungle3Done then targetLocation = "Sacred Temple"
			end
		else
			-- Hapus dari list jika sudah selesai
			for i, q in ipairs(FEATURES.ACTIVE_QUESTS) do
				if q == "Jungle2025" then table.remove(FEATURES.ACTIVE_QUESTS, i) break end
			end
		end
	end                

	-- 3. Fallback ke Default Location
	if not targetLocation then
		targetLocation = FEATURES.DEFAULT_LOCATION
	end

	-- 4. Teleportasi jika lokasi berubah
	if State.DynamicLocation ~= targetLocation and targetLocation then
		print("[QuestSystem] Memindahkan ke lokasi quest: " .. targetLocation)
		local locCFrame = LOCATIONS[targetLocation]
		
		if locCFrame then
			local char = LocalPlayer.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")

			if hrp then hrp.Anchored = false end
			SafeTeleport(locCFrame)

			State.DynamicLocation = targetLocation
			task.wait(5) -- Beri waktu delay setelah teleport agar tidak tersangkut
		end
	end
end


--================================================
-- OPTIONAL FEATURES (Graphics, UI, etc)
--================================================

-- Low Graphics Mode
local function InitLowGraphics()
	if not FEATURES.LOW_GRAPHICS then return end
	
	pcall(function()
		local Lighting = game:GetService("Lighting")
		local Terrain = workspace:FindFirstChildOfClass("Terrain")
		
		Lighting.GlobalShadows = false
		Lighting.FogEnd = 9e9
		Lighting.Brightness = 0
		
		if Terrain then
			Terrain.WaterWaveSize = 0
			Terrain.WaterWaveSpeed = 0
			Terrain.WaterReflectance = 0
			Terrain.WaterTransparency = 0
		end

		pcall(function()
			settings().Rendering.QualityLevel = "Level01"
		end)

		-- Matikan Efek Post-Processing
		for _, v in pairs(Lighting:GetChildren()) do
			if v:IsA("PostEffect") then v.Enabled = false end
		end

		for _, v in pairs(workspace:GetDescendants()) do
			if v:IsA("BasePart") and not v:IsA("MeshPart") then
				v.Material = Enum.Material.SmoothPlastic
				v.Reflectance = 0
				v.CastShadow = false
			elseif v:IsA("Decal") or v:IsA("Texture") then
				v.Transparency = 1
			elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then
				v.Enabled = false
			end
		end

		local function clearSkins(parent)
			for _, v in pairs(parent:GetDescendants()) do
				if v:IsA("MeshPart") then v.TextureID = "" 
				elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 1
				elseif v:IsA("SpecialMesh") then v.TextureId = "" end
			end
		end
		
		if LocalPlayer.Character then clearSkins(LocalPlayer.Character) end
		if LocalPlayer.Backpack then clearSkins(LocalPlayer.Backpack) end

		local Char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
		local Humanoid = Char:WaitForChild("Humanoid")
		local Animator = Humanoid:WaitForChild("Animator")

		for _, track in ipairs(Animator:GetPlayingAnimationTracks()) do
			local name = track.Animation.Name:lower()
			if name:find("fish") or name:find("rod") or name:find("cast") or name:find("throw") then
				track:Stop()
			end
		end

		Animator.AnimationPlayed:Connect(function(track)
			local name = track.Animation.Name:lower()
			if name:find("fish") or name:find("rod") or name:find("cast") or name:find("throw") or name:find("reel") then
				track:Stop()
			end
		end)
	end)
end


-- Error Handler (Auto-Rejoin)
local function InitErrorHandler()
	if not FEATURES.ERROR_HANDLER then return end
	
	pcall(function()
		local GuiService = game:GetService("GuiService")
		local TeleportService = game:GetService("TeleportService")
		
		GuiService.ErrorMessageChanged:Connect(function()
			task.wait(5)
			pcall(function()
				TeleportService:Teleport(game.PlaceId, LocalPlayer)
			end)
		end)
	end)
end

-- Disable Notifications/Cutscenes
local function InitDisableNotifications()
	if not FEATURES.DISABLE_NOTIFICATIONS then return end
	
	pcall(function()
		local playerGui = LocalPlayer:WaitForChild("PlayerGui")
		
		local function disableGui(gui)
			if gui:IsA("ScreenGui") then
				local name = gui.Name:lower()
				if name:find("small notification") then
					gui.Enabled = false
					gui:GetPropertyChangedSignal("Enabled"):Connect(function()
						if gui.Enabled then gui.Enabled = false end
					end)
				end
			end
		end
		
		for _, gui in pairs(playerGui:GetChildren()) do disableGui(gui) end
		playerGui.ChildAdded:Connect(disableGui)
	end)
	
	-- Hook CutsceneController to auto-skip cutscenes
	pcall(function()
		local CutsceneController = require(ReplicatedStorage.Controllers.CutsceneController)
		local originalPlay = CutsceneController.Play
		CutsceneController.Play = function(self, ...)
			task.spawn(function()
				task.wait(0.1)
				pcall(function() CutsceneController:Stop() end)
			end)
			return
		end
	end)
end

-- 3D Rendering Toggle
local function Set3dRenderingEnabled(status)
	pcall(function()
		RunService:Set3dRenderingEnabled(status)
		if not status and not State.ScreenGui then
			State.ScreenGui = Instance.new("ScreenGui")
			State.ScreenGui.Name = "BigTextGui"
			State.ScreenGui.ResetOnSpawn = false
			State.ScreenGui.DisplayOrder = 999
			State.ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
			
			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(0.8, 0, 0.3, 0)
			label.Position = UDim2.new(0.1, 0, 0.35, 0)
			label.BackgroundTransparency = 1
			label.Text = tostring(LocalPlayer)
			label.TextColor3 = Color3.new(0, 0, 0)
			label.TextStrokeTransparency = 0.2
			label.Font = Enum.Font.GothamBlack
			label.TextScaled = true
			label.Parent = State.ScreenGui
		elseif status and State.ScreenGui then
			State.ScreenGui:Destroy()
			State.ScreenGui = nil
		end
	end)
end

local function InitDisable3D()
	if FEATURES.DISABLE_3D then
		Set3dRenderingEnabled(false)
	end
end

--================================================
-- AUTO-EQUIP, SELLING & BUYING
--================================================

local function EnsureRodEquipped()
	-- Pastikan database & data rod terbaru sudah dimuat
	if not DBRod then LoadDatabases() end
	GetRods()
	GetBaits()

	local currentRodEquippedId = DataReplion:Get("EquippedId")
	local currentBaitEquippedId = DataReplion:Get("EquippedBaitId")

	if currentRodEquippedId ~= State.BestRodId then
		EquipBackpackRod(State.BestRodUid)
		task.wait(1)
	end

	if currentBaitEquippedId ~= State.BestBaitId then
		EquipBackpackBait(State.BestBaitId)
		task.wait(1)
	end

	if DataReplion:GetExpect("EquippedType") == "Fishing Rods" then return true end
	if EquipToolbarSlot(1) then
		task.wait(0.5)
		if DataReplion:GetExpect("EquippedType") == "Fishing Rods" then return true else return false end
	else
		return false
	end
end

local function CanSellNow()
	if FishingController:GetCurrentGUID() then return false, "Fishing active" end
	if LocalPlayer:GetAttribute("InCutscene") then return false, "InCutscene" end
	if LocalPlayer:GetAttribute("Loading") then return false, "Loading" end
	if FishingController:OnCooldown() then return false, "OnCooldown" end
	if State.SellDebounce then return false, "Debounce" end
	return true, "OK"
end

local function FindSellPrompt()
	local sellNPCs = CollectionService:GetTagged("SellPrompt")
	for _, npc in ipairs(sellNPCs) do
		local sellAllPrompt = npc:FindFirstChild("SellAllPrompt")
		if sellAllPrompt then
			local prompt = sellAllPrompt:FindFirstChild("SellAllPrompt")
			if prompt and prompt:IsA("ProximityPrompt") then return prompt, npc end
		end
	end
	return nil, nil
end

local function PerformAutoSell()
	local canSell, reason = CanSellNow()
	if not canSell then return false end
	
	State.SellDebounce = true
	task.delay(2, function() State.SellDebounce = false end)
	local success = false
	
	pcall(function()
		local prompt, _ = FindSellPrompt()
		local origFirePrompt = PromptController.FirePrompt
		PromptController.FirePrompt = function()
			PromptController.FirePrompt = origFirePrompt
			return PromiseModule.resolve(true)
		end
		
		if prompt then
			if fireproximityprompt then
				fireproximityprompt(prompt)
			else
				prompt:InputHoldBegin()
				task.wait(math.max(prompt.HoldDuration, 0.1) + 0.1)
				prompt:InputHoldEnd()
			end
			task.wait(1)
			success = true
		else
			local sellPromise = VendorController:SellAllItems()
			if sellPromise and type(sellPromise) == "table" and sellPromise.andThen then
				local _, result = sellPromise:catch(function(err) end):await()
				if result then success = true end
			end
		end
		PromptController.FirePrompt = origFirePrompt
	end)
	
	return success
end

local function PerformAutoBuy()
	GetRods()
	GetBaits()

	-- Buy Rods
	for _, rodName in ipairs(FEATURES.BUY_RODS) do
		local targetId, price, correctName
		if DBRod then
			for _, rodData in pairs(DBRod) do
				local dbName = tostring(rodData.Name or rodData.name or "")
				if string.lower(dbName) == string.lower(tostring(rodName)) then
					targetId = tonumber(rodData.Id or rodData.id)
					price = tonumber(rodData.Price or rodData.price) or math.huge
					correctName = dbName
					break
				end
			end
		end

		if targetId and not State.OwnedRods[targetId] and GetCoin() >= price then
			if PurchaseFromShop("Rod Shop", correctName) then
			end
			task.wait(0.5)
		end
	end

	-- Buy Baits
	for _, baitName in ipairs(FEATURES.BUY_BAITS) do
		local targetId, price, correctName
		if DBBait then
			for _, baitData in pairs(DBBait) do
				local dbName = tostring(baitData.Name or baitData.name or "")
				if string.lower(dbName) == string.lower(tostring(baitName)) then
					targetId = tonumber(baitData.Id or baitData.id)
					price = tonumber(baitData.Price or baitData.price) or math.huge
					correctName = dbName
					break
				end
			end
		end

		if targetId and not State.OwnedBaits[targetId] and GetCoin() >= price then
			if PurchaseFromShop("Bait Shop", correctName) then
			end
			task.wait(0.5)
		end
	end
	EnsureRodEquipped()
end

--================================================
-- AUTO FAVORITE & WEBHOOK SYSTEM
--================================================

local function FavoriteItem(uuid)
	pcall(function() TileInteractionController:ToggleFavorite(uuid) end)
end

local function ShouldBeFavorited(fishId, fishData, variant)
	local matchId = FAVORITE_CONFIG.WhitelistId[fishId]
	local matchVariant = variant and FAVORITE_CONFIG.WhitelistVariant[variant]
	local matchTier = fishData and fishData.Tier and (fishData.Tier >= FAVORITE_CONFIG.FavoriteTiers)
	if matchVariant and matchId then return true elseif matchTier then return true end
	return false
end

local ScanConfig = {
	Endpoint = "https://hansiong.pythonanywhere.com/api/simpan",  
}
local LastCatchCount = -1

local function ScanInventoryFish()
	if not DBFish then LoadDatabases() end 
	if not DBFish then return end

	local allItems = {}
	local invFish = DataReplion:Get({"Inventory", "Fish"}) or {}
	local invItems = DataReplion:Get({"Inventory", "Items"}) or {}
	
	for _, v in pairs(invFish) do table.insert(allItems, v) end
	for _, v in pairs(invItems) do table.insert(allItems, v) end

	local secretList = {}
	local grouped = {}
	local totalSecretCount = 0

	for _, item in ipairs(allItems) do
		local fishId = item.Id or item.ID
		local favorited = item.Favorited or false
		local variant = item.Metadata and item.Metadata.VariantId
		local fishData = DBFish[tostring(fishId)]
		
		local itemName = (fishData and fishData.Name) or item.Name or ("Unknown ID: " .. tostring(fishId))
		local isTarget = false
		local finalName = itemName

		if fishData then
			-- Pengecekan tier rahasia
			if string.upper(tostring(fishData.Rarity or "")) == "SECRET" or fishData.Tier == 7 then
				isTarget = true
			end
			
			-- Tambahan jika whitelist tertentu ada di configurasi Auto Favorite
			if not isTarget then
				if variant and FAVORITE_CONFIG.WhitelistId[tonumber(fishId)] and FAVORITE_CONFIG.WhitelistVariant[variant] then
					isTarget = true
					finalName = variant .. " " .. itemName 
				end
			end

			-- Fitur auto favorite 
			if ShouldBeFavorited(tonumber(fishId), fishData, variant) and not favorited then
				FavoriteItem(item.UUID)
				task.wait(1) 
			end
		end

		if isTarget then
			totalSecretCount = totalSecretCount + 1
			if not grouped[finalName] then
				local newEntry = { Name = finalName, Count = 0 }
				table.insert(secretList, newEntry)
				grouped[finalName] = newEntry
			end
			grouped[finalName].Count = grouped[finalName].Count + 1
		end
	end

	local CurrentTotal = State.CatchCount or 0
	local StatusString = "Offline"
	if CurrentTotal > LastCatchCount then
		StatusString = "Online"
	end
	LastCatchCount = CurrentTotal
	
	local rodName = "None"
	
	if State.BestRodId and DBRod then
		local rodData = DBRod[tostring(State.BestRodId)]
		if rodData then
			rodName = rodData.Name or rodData.name
		else
			rodName = "Unknown ID: " .. tostring(State.BestRodId)
		end
	end
	
	local enc1 = State.BestEnchant1 or "-"
	local enc2 = State.BestEnchant2 or "-"

	local payload = {
		Username = LocalPlayer.Name,
		UserId = LocalPlayer.UserId,
		Status = StatusString,
		TotalSecrets = totalSecretCount,
		Items = secretList,
		Rod = rodName,
		Enchant1 = enc1,
		Enchant2 = enc2,
		Timestamp = os.time()
	}

	local req = (http_request or request or (syn and syn.request) or (fluxus and fluxus.request))
	if req then
		pcall(function()
			req({
				Url = ScanConfig.Endpoint, 
				Method = "POST", 
				Headers = {
					["Content-Type"] = "application/json",
					["User-Agent"] = "Roblox-Client"
				}, 
				Body = HttpService:JSONEncode(payload)
			})
		end)
	else
		warn("⚠️ HTTP Request tidak support.")
	end
end

--================================================
-- CORE FISHING LOGIC (TIDAK ADA PERUBAHAN MEKANISME)
--================================================

local function getClickTiming()
	local locationName = LocalPlayer:GetAttribute("LocationName") or "Fisherman Island"
	local area = AreaUtility:GetArea(locationName)
	if not area then area = { ClickPowerMultiplier = 1 } end
	local rarity = LocalPlayer:GetAttribute("SelectedRarity") or 1
	return Constants:GetClickTiming(rarity, area)
end

local function calcWaitForPower(seed)
	local speed = Random.new(seed):NextInteger(4, 10)
	local elapsedTarget = (math.pi / 2 + math.asin(POWER_THRESHOLD)) / speed
	local targetServerTime = seed + elapsedTarget
	return targetServerTime - workspace:GetServerTimeNow()
end

local function getCenterVector()
	return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

local function instantCatch(data)
	local clickPower = data.FishingClickPower or 0.1
	local totalClicks = math.ceil(1 / clickPower)
	data.Progress = 1 - clickPower
	data.Inputs = totalClicks - 1
	if INSTANT_CATCH_DELAY == 4 then
		INSTANT_CATCH_DELAY = getClickTiming() * (totalClicks - 1) + MORECOOLDOWN
	end
	FishingController:ConfirmClick()
end

local function MainFishingLoop()
	while true do
		while LocalPlayer:GetAttribute("InCutscene") do
			task.wait(COOLDOWN_POLL)
		end
		-- Auto-sell, Auto-Buy & Quest Check block
		if FEATURES.FISH_COUNT > 0 and State.SuccessCount >= FEATURES.FISH_COUNT then					
			if FEATURES.AUTO_SELL then
				print("[AutoFish] Starting auto-favorite process...")
				ScanInventoryFish()

				task.wait(3)
				print("[AutoFish] Starting auto-sell process...")
				if PerformAutoSell() then
					State.SuccessCount = 0
				end
			else
				-- Jika tidak auto-sell, cukup reset counter untuk loop selanjutnya
				State.SuccessCount = 0
			end

			-- CEK AUTO BUY
			if #FEATURES.BUY_RODS > 0 or #FEATURES.BUY_BAITS > 0 then
				print("[AutoFish] Checking Auto-Buy...")
				PerformAutoBuy()
			end
			
			-- CEK PROGRESS QUEST DAN UPDATE LOKASI
			task.wait(2)
			UpdateQuestAndLocation()

			-- AUTO SPAWN TOTEM
			if FEATURES.AUTO_SPAWN_TOTEMS ~= "" and State.BestRodId == 257 and GetCoin() > 1000000 then
				SpawnTotem(FEATURES.AUTO_SPAWN_TOTEMS)
			end
		end

		if FishingController:OnCooldown() then
			task.wait(COOLDOWN_POLL)
		elseif FishingController:GetCurrentGUID() then
			task.wait(INSTANT_CATCH_DELAY)
			instantCatch(data)
		else
			FishingController:RequestChargeFishingRod(getCenterVector())
			local seed = workspace:GetServerTimeNow()
			local waitTime = calcWaitForPower(seed)
			if waitTime > 0 then task.wait(waitTime) end
			
			local power = FishingController:_getPower()
			FishingController:UpdateChargeState(nil)
			local ok, datax = FishingController:SendFishingRequestToServer(getCenterVector(), power)

			if ok then
				FishingController:FishingRodStarted(datax)
				data = datax
				task.wait(COOLDOWN_POLL)
				State.SuccessCount = State.SuccessCount + 1
				State.CatchCount = State.CatchCount + 1
			end

			task.wait(COOLDOWN_POLL)
		end
	end
end

--================================================
-- INITIALIZATION
--================================================

PrintConfig()

InitLowGraphics()
InitErrorHandler()
InitDisableNotifications()
InitDisable3D()

-- Panggil LoadDatabases untuk mengisi DBFish dll.
LoadDatabases()

if not EnsureRodEquipped() then
	warn("[AutoFish] Cannot start without fishing rod. Aborting.")
	return
end

-- Gantikan InitialTeleport static dengan pengecekan Quest pertama kali saat injeksi
print("[QuestSystem] Initializing Quest Locations...")
UpdateQuestAndLocation()

task.spawn(MainFishingLoop)

print("[AutoFish] Script running with Quest System")
