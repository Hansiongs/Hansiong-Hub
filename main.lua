local Settings = getgenv().Settings

getgenv().AutoDelay = 0.5
getgenv().LastCatch = false
getgenv().FailCount = 0

local Owned = {
    ["Rods"] = {},
    ["Baits"] = {},
    ["Items"] = {},
}

local RunService = game:GetService("RunService")

local RodDelays = {
	[1] = 0.164,
	[2] = 0.168,
	[3] = 0.172,
	[4] = 0.176,
	[5] = 0.18,
	[6] = 0.184,
	[7] = 0.188,
}

local Temporary = {
    ["Running"] = true,
    ["FishCatch"] = 99999,
    ["FishingCatch"] = 0,
    ["BestRod"] = nil,
    ["BestRodId"] = nil,
    ["BestBait"] = nil,
    ["Location"] = nil,
    ["ScreenGui"] = nil,
    ["Render"] = nil,
    ["Timex"] = tick(),
    ["AFK"] = tick(),
    ["Logs"] = {},
}

local Locations = {
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
}

local WeathersData = {
    ["Wind"] = 10000,
    ["Snow"] = 15000,
    ["Cloudy"] = 20000,
    ["Storm"] = 35000,
    ["Radiant"] = 50000,
    ["Shark Hunt"] = 300000,
}

local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local RootPart = Character:WaitForChild("HumanoidRootPart")
local PlaceId = game.PlaceId
local JobId = game.JobId
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataReplion = require(ReplicatedStorage.Packages.Replion).Client:WaitReplion("Data")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local DBFish = HttpService:JSONDecode(game:HttpGet('https://raw.githubusercontent.com/Hansiongs/Hansiong-Hub/refs/heads/main/rodlists'))
local DBRod = HttpService:JSONDecode(game:HttpGet('https://raw.githubusercontent.com/Hansiongs/Hansiong-Hub/refs/heads/main/rodlists'))
local DBBait = HttpService:JSONDecode(game:HttpGet('https://raw.githubusercontent.com/Hansiongs/Hansiong-Hub/refs/heads/main/baitlists'))
local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

local Packages = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index")
local Net = nil
for _, folder in pairs(Packages:GetChildren()) do
    if folder.Name:match("sleitnick_net") then
        Net = folder:WaitForChild("net")
        break
    end
end

local function disable(gui)
    if gui:IsA("ScreenGui") then
        local name = gui.Name:lower()
        if name:find("small notification") or name:find("cutscene") then
            gui.Enabled = false
            gui:GetPropertyChangedSignal("Enabled"):Connect(function()
                if gui.Enabled then gui.Enabled = false end
            end)
        end
    end
end

function EquipToolFromHotbar(number) return Net["RE/EquipToolFromHotbar"]:FireServer(number or 1) end
function UnequipToolFromHotbar(number) return Net["RE/UnequipToolFromHotbar"]:FireServer(number or 1) end
function ChargeFishingRod(t) return Net["RF/ChargeFishingRod"]:InvokeServer(t or workspace:GetServerTimeNow()) end
function RequestFishingMinigameStarted(t) return Net["RF/RequestFishingMinigameStarted"]:InvokeServer(-1.233184814453125, 0.998 + (1.0 - 0.998) * math.random(), t or workspace:GetServerTimeNow()) end
function CancelFishingInputs() return Net["RF/CancelFishingInputs"]:InvokeServer() end
function SellAllItems() return Net["RF/SellAllItems"]:InvokeServer() end
function FavoriteItem(Uid) return Net["RE/FavoriteItem"]:FireServer(Uid) end
function EquipItem(Uid, Item) return Net["RE/EquipItem"]:FireServer(Uid, Item) end
function PurchaseFishingRod(Id) return Net["RF/PurchaseFishingRod"]:InvokeServer(Id) end
function PurchaseBait(Id) return Net["RF/PurchaseBait"]:InvokeServer(Id) end
function EquipBait(Id) return Net["RE/EquipBait"]:FireServer(Id) end
function PlaceLeverItem(item) return Net["RE/PlaceLeverItem"]:FireServer(item) end
function PurchaseWeatherEvent(name) return Net["RF/PurchaseWeatherEvent"]:InvokeServer(name) end

if not Net then 
    return
end

for _, v in pairs(PlayerGui:GetChildren()) do disable(v) end
PlayerGui.ChildAdded:Connect(disable)

function GetCoin()
    return DataReplion:Get("Coins")
end

function CheckProgress(progressText)
    if not progressText then return false end
    local cleanText = string.gsub(progressText, ",", "")
    local current, required = string.match(cleanText, "(%d+)%s*/%s*(%d+)")
    
    if current and required then
        return tonumber(current) >= tonumber(required)
    end
    
    if string.find(cleanText, "100%%") then
        return true
    end
    
    return false
end

function GetDeepSeaQuest()
    local pGui = Player:FindFirstChild("PlayerGui")
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

function GetJungle2025Quest()
    local pGui = Player:FindFirstChild("PlayerGui")
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

function GetTempleLevers()
    return DataReplion:Get("TempleLevers")
end

function GetWeather(name)
    return Player.PlayerGui.Events.Frame.Events[name].Visible
end

function GetEquippedUid()
    return DataReplion:Get("EquippedId")
end

function GetEquippedType()
    return DataReplion:Get("EquippedType")
end

function GetEquippedBaitId()
    return DataReplion:Get("EquippedBaitId")
end

function Teleport(location)
    Character:WaitForChild("HumanoidRootPart").CFrame = location
end

function GetItems()
    local items = DataReplion:Get({"Inventory", "Items"})
    for _, item in ipairs(items) do
        Owned["Items"][item.Id] = true
    end
end

function GetEquippedRodId()
    Uid = DataReplion:Get("EquippedId")
    local items = DataReplion:Get({"Inventory", "Fishing Rods"})
    for _, item in ipairs(items) do
        if item.UUID == Uid then
            return item.Id
        end
    end
end

function GetBaits()
    local items = DataReplion:Get({"Inventory", "Baits"})
    if not items then return end

    local bestLuck = -1
    local bestId = nil

    Owned["Baits"] = {}

    for _, item in ipairs(items) do
        local baitData = DBBait[tostring(item.Id)]
        if baitData and baitData.BaseLuck then
            Owned["Baits"][item.Id] = item.UUID
            
            if baitData.BaseLuck > bestLuck then
                bestLuck = baitData.BaseLuck
                bestId = item.Id
            end
        end
    end

    Temporary["BestBait"] = bestId
end

function GetRods()
    local items = DataReplion:Get({"Inventory", "Fishing Rods"})
    if not items then return end

    local bestLuck = -1
    local bestUUID = nil
    local bestId = nil

    for _, item in ipairs(items) do
        local rodData = DBRod[tostring(item.Id)]
        if rodData and rodData.BaseLuck then
            Owned["Rods"][item.Id] = item.UUID
            
            if rodData.BaseLuck > bestLuck then
                bestLuck = rodData.BaseLuck
                bestUUID = item.UUID
                bestId = item.Id
            end
        end
    end

    Temporary["BestRod"] = bestUUID
    Temporary["BestRodId"] = bestId
end


function Set3dRenderingEnabled(status)
    game:GetService("RunService"):Set3dRenderingEnabled(status)
    if not status and not Temporary["ScreenGui"] then
        Temporary["ScreenGui"] = Instance.new("ScreenGui")
        Temporary["ScreenGui"].Name = "BigTextGui"
        Temporary["ScreenGui"].ResetOnSpawn = false
        Temporary["ScreenGui"].DisplayOrder = 999
        Temporary["ScreenGui"].Parent = Player:WaitForChild("PlayerGui")
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.8, 0, 0.3, 0)
        label.Position = UDim2.new(0.1, 0, 0.35, 0)
        label.BackgroundTransparency = 1
        label.Text = tostring(Player)
        label.TextColor3 = Color3.new(0, 0, 0)
        label.TextStrokeTransparency = 0.2
        label.Font = Enum.Font.GothamBlack
        label.TextScaled = true
        label.Parent = Temporary["ScreenGui"]  
    end
    if status and Temporary["ScreenGui"] then
        Temporary["ScreenGui"]:Destroy()
    end
    Temporary["Render"] = status
end

function contains(tbl, val)
    for _, v in ipairs(tbl) do
        if v == val then
            return true
        end
    end
    return false
end

function CheckConnection()
	local ok, res = pcall(function()
		return HttpService:RequestAsync({
			Url = "https://hrplay.cloud/api",
			Method = "GET",
			Headers = {["Cache-Control"] = "no-cache"}
		})
	end)
	return ok and res and res.Success == true and res.StatusCode >= 200 and res.StatusCode < 500
end

function Reconnect()
	game:GetService("TeleportService"):TeleportToPlaceInstance(PlaceId, JobId, Player)
end

function LowSetting()
    local Lighting = game:GetService("Lighting")
    local Terrain = workspace:WaitForChild("Terrain")
    local Workspace = game:GetService("Workspace")

    Terrain.WaterWaveSize = 0
    Terrain.WaterWaveSpeed = 0
    Terrain.WaterReflectance = 0
    Terrain.WaterTransparency = 0
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    Lighting.Brightness = 0

    pcall(function()
        settings().Rendering.QualityLevel = "Level01"
    end)

    local function optimizeLighting(v)
        if v:IsA("PostEffect") then
            v.Enabled = false
        end
    end

    local function optimizeObject(v)
        if v:IsA("BasePart") and not v:IsA("MeshPart") then
            v.Material = Enum.Material.SmoothPlastic
            v.Reflectance = 0
            v.CastShadow = false
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
            v.Enabled = false
        end
    end

    for i, v in pairs(Lighting:GetDescendants()) do
        optimizeLighting(v)
    end

    for i, v in pairs(Workspace:GetDescendants()) do
        optimizeObject(v)
    end
    Lighting.DescendantAdded:Connect(optimizeLighting)
    Workspace.DescendantAdded:Connect(optimizeObject)
end

Net["RE/ObtainedNewFishNotification"].OnClientEvent:Connect(function(msg1, msg2, msg3)
    getgenv().LastCatch = true
    getgenv().FailCount = 0

    if Settings["FishingMode"] == "Fast" and getgenv().AutoDelay > 0.85 then
        getgenv().AutoDelay = getgenv().AutoDelay - 0.05
    end

    Temporary["FishCatch"] = Temporary["FishCatch"] + 1
    Temporary["FishingCatch"] = Temporary["FishingCatch"] + 1
    
    local fishInfo = DBFish[tostring(msg1)]
    if fishInfo and (fishInfo.Tier == 7 or Settings["FavoriteFish"][tostring(msg1)]) then
        FavoriteItem(msg3.InventoryItem.UUID)
    end
end)

game:GetService("GuiService").ErrorMessageChanged:Connect(function()
	while Settings["AutoReconnect"] do
		if CheckConnection() then
			Reconnect()
			break
		else
			task.wait(1)
		end
	end
end)

game:GetService("RunService").Heartbeat:Connect(function(dt)
    local ts = tick()
    if ts - Temporary["AFK"] > 600 then
        Temporary["AFK"] = tick()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)


LowSetting()
GetRods()
GetBaits()

Teleport(Locations["Sisyphus Statue"])
Temporary["Location"] = "Sisyphus Statue"
task.wait(3)

Teleport(Locations["Ancient Jungle"])
Temporary["Location"] = "Ancient Jungle"
task.wait(3)

Teleport(Locations["Underground Cellar"])
Temporary["Location"] = "Underground Cellar"
task.wait(20)

while Temporary["Running"] do
    if Settings["Render"] ~= Temporary["Render"] then
        Set3dRenderingEnabled(Settings["Render"])
    end

    if Settings["AutoFish"] then
        if Temporary["FishCatch"] > Settings["SellCount"] or (Temporary["FishingCatch"] % 50 == 0) then
            Temporary["FishCatch"] = 0
            SellAllItems()
            task.wait(0.2)
            
            if GetEquippedType() ~= "Fishing Rods" then
                EquipToolFromHotbar()
            end

            for key, value in pairs(Settings["BuyRods"]) do
                if DBRod[tostring(value)] and not Owned["Rods"][DBRod[tostring(value)].Id] and GetCoin() > DBRod[tostring(value)].Price then
                    PurchaseFishingRod(DBRod[tostring(value)].Id)
                    task.wait(0.2)
                end
            end

            for key, value in pairs(Settings["BuyBaits"]) do
                if DBBait[tostring(value)] and not Owned["Baits"][DBBait[tostring(value)].Id] and GetCoin() > DBBait[tostring(value)].Price then
                    PurchaseBait(DBBait[tostring(value)].Id)
                    task.wait(0.2)
                end
            end

            for key, value in pairs(Settings["Weathers"]) do
                if WeathersData[value] and GetCoin() > WeathersData[value] then
                    if not GetWeather(value) then
                        PurchaseWeatherEvent(value)
                        task.wait(0.2)
                    end
                end
            end

            GetRods() 
            GetBaits()
            
            local targetRodUUID = Temporary["BestRod"]    
            if Settings["Rod"] and Settings["Rod"] ~= "" then
                local reqRod = DBRod[Settings["Rod"]]
                if reqRod and Owned["Rods"][reqRod.Id] then
                    targetRodUUID = Owned["Rods"][reqRod.Id]
                end
            end
            
            if targetRodUUID and GetEquippedUid() ~= targetRodUUID then
                EquipItem(targetRodUUID, "Fishing Rods")
                task.wait(1)
            end
                
            local targetBaitId = Temporary["BestBait"]
            if Settings["Bait"] and Settings["Bait"] ~= "" then
                local reqBait = DBBait[Settings["Bait"]]
                if reqBait and Owned["Baits"][reqBait.Id] then
                    targetBaitId = reqBait.Id
                end
            end

            if targetBaitId and GetEquippedBaitId() ~= targetBaitId then
                EquipBait(targetBaitId)
                task.wait(0.2)
            end 

            local CanSecret = nil
            local CanElement = nil
            for key, value in pairs(Owned["Rods"]) do
                if DBRod[tostring(key)] then
                    if DBRod[tostring(key)].BaseLuck >= 6.1 then
                        CanElement = true
                    elseif DBRod[tostring(key)].BaseLuck >= 3.8 then
                        CanSecret = true
                    end
                end
            end

            if next(Settings["Quest"]) then
                if contains(Settings["Quest"], "DeepSea") then
                    DeepSeaQuest = GetDeepSeaQuest()
                    local isObj1Done = CheckProgress(DeepSeaQuest[1])
                    local isObj2Done = CheckProgress(DeepSeaQuest[2])
                    local isObj3Done = CheckProgress(DeepSeaQuest[3])
                    local isObj4Done = CheckProgress(DeepSeaQuest[4])

                    if not isObj1Done or not isObj2Done or not isObj3Done or not isObj4Done then
                        if not CanSecret then
                            Settings["Location"] = "Kohana Volcano" 
                        elseif not isObj2Done or not isObj3Done then
                            Settings["Location"] = "Sisyphus Statue" 
                        elseif not isObj1Done then
                            Settings["Location"] = "Treasure Room" 
                        end
                    else
                        table.remove(Settings["Quest"], 1)
                        Settings["Location"] = nil
                    end
                end

                if not contains(Settings["Quest"], "DeepSea") and contains(Settings["Quest"], "Jungle2025") then
                        local Jungle2025Quest = GetJungle2025Quest()
                        local isJungle1Done = CheckProgress(Jungle2025Quest[1])
                        local isJungle2Done = CheckProgress(Jungle2025Quest[2]) 
                        local isJungle3Done = CheckProgress(Jungle2025Quest[3]) 
                        local isJungle4Done = CheckProgress(Jungle2025Quest[4]) 
                        
                        if not isJungle1Done or not isJungle2Done or not isJungle3Done then
                            local TempleLevers = GetTempleLevers()
                            if not TempleLevers["Diamond Artifact"] then PlaceLeverItem("Diamond Artifact"); task.wait(0.2)
                            elseif not TempleLevers["Crescent Artifact"] then PlaceLeverItem("Crescent Artifact"); task.wait(0.2)
                            elseif not TempleLevers["Hourglass Diamond Artifact"] then PlaceLeverItem("Hourglass Diamond Artifact"); task.wait(0.2)
                            elseif not TempleLevers["Arrow Artifact"] then PlaceLeverItem("Arrow Artifact"); task.wait(0.2)
                            end
                            
                            local TempleLevers = GetTempleLevers()
                            if not TempleLevers["Diamond Artifact"] then Settings["Location"] = "Diamond Artifact"
                            elseif not TempleLevers["Crescent Artifact"] then Settings["Location"] = "Crescent Artifact"
                            elseif not TempleLevers["Hourglass Diamond Artifact"] then Settings["Location"] = "Hourglass Diamond Artifact"
                            elseif not TempleLevers["Arrow Artifact"] then Settings["Location"] = "Arrow Artifact"
                            elseif not isJungle2Done then Settings["Location"] = "Arrow Artifact" 
                            elseif not isJungle3Done then Settings["Location"] = "Sacred Temple"
                            end
                        else
                            table.remove(Settings["Quest"], 1) 
                            Settings["Location"] = nil
                    end
                end                
            end

            if not contains(Settings["Quest"], "DeepSea") and not contains(Settings["Quest"], "Jungle2025") and not Settings["Location"] then
                Settings["Location"] = "Crater Island"
            end

            if Temporary["Location"] ~= Settings["Location"] and Settings["Location"] then
                Teleport(Locations[Settings["Location"]])
                Temporary["Location"] = Settings["Location"]
                task.wait(5)
            end
        end

if Temporary["BestRodId"] == 257 and Settings["FishingMode"] == "Fast" then
            getgenv().LastCatch = false
            local currentCycleDelay = getgenv().AutoDelay

            task.spawn(function()
                pcall(function()
                    local now = workspace:GetServerTimeNow()
                    CancelFishingInputs()
                    task.wait(0.1)
                    ChargeFishingRod(now)
                    RequestFishingMinigameStarted(now)
                    task.wait(currentCycleDelay)
                    Net["RE/FishingCompleted"]:FireServer()
                end)
            end)
            task.wait(0.2)
            if not getgenv().LastCatch then
                getgenv().FailCount = getgenv().FailCount + 1
                if getgenv().FailCount >= 3 then
                    getgenv().AutoDelay = getgenv().AutoDelay + 0.05
                    getgenv().FailCount = 0
                    if getgenv().AutoDelay > 2.0 then getgenv().AutoDelay = 0.5 end
                end
            end

        else
            CancelFishingInputs()
            task.wait(0.2)
            local status, result = ChargeFishingRod()
            
            if status then
                local status, result = RequestFishingMinigameStarted()
                if status then
                    local delay = (1 / result["FishingClickPower"]) * RodDelays[result["FishingRodTier"]]
                    task.wait(delay)
                    Net["RE/FishingCompleted"]:FireServer()
                    task.wait(0.3)
                end
            else
            end
        end
    else
        Temporary["FishCatch"] = 99999
        task.wait(0.3)
    end
end 
