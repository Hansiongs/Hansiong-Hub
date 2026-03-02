local Settings = getgenv().Settings
local Owned = {
    ["Rods"] = {},
    ["Baits"] = {},
    ["Items"] = {},
}

local RunService = game:GetService("RunService")
local ScanConfig = {
    Endpoint = "https://hansiong.pythonanywhere.com/api/simpan",  
}
local LastCatchCount = -1
local ItemDatabase = {}
local tierToRarity = { [7]="SECRET" }
local DynamicLocation = ""
local Codes = {
    "NEWYEARLANTERN",
    "FREECRYSTAL",
    "PIRATEMAJA",
    "SCALEREFUND",
    "DIVING",
}

local TargetPotions = {
    [1] = "Luck I Potion",
    [6] = "Luck II Potion",
    [4] = "Mutation I Potion",
    [2] = "Coin I Potion"
}

local FavoriteConfig = {
    WhitelistId = {
        [243] = true,  --Ruby
    },
    WhitelistVariant = {
        ["Gemstone"] = true,
    }
}

local Temporary = {
    ["Running"] = true, ["FishCatch"] = 99999, ["FishingCatch"] = 0, ["BestRod"] = nil, 
    ["BestRodId"] = nil, ["BestBait"] = nil, ["Location"] = nil, ["ScreenGui"] = nil, 
    ["Render"] = nil, ["Timex"] = tick(), ["AFK"] = tick(), ["Logs"] = {}
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
    ["Tropical Grove"] = CFrame.new(-2154.49,7,3670.67),
}

local WeathersData = { ["Wind"]=10000, ["Snow"]=15000, ["Cloudy"]=20000, ["Storm"]=35000, ["Radiant"]=50000, ["Shark Hunt"]=300000 }

local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local RootPart = Character:WaitForChild("HumanoidRootPart")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataReplion = require(ReplicatedStorage.Packages.Replion).Client:WaitReplion("Data")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local PlayerGui = Player:WaitForChild("PlayerGui")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Net = require(Packages.Net)
local FishingController = require(ReplicatedStorage.Controllers.FishingController)
local Camera = workspace.CurrentCamera

-- Database Imports
local DBFish = HttpService:JSONDecode(game:HttpGet('https://raw.githubusercontent.com/Hansiongs/Hansiong-Hub/refs/heads/main/fishlists'))
local DBRod = HttpService:JSONDecode(game:HttpGet('https://raw.githubusercontent.com/Hansiongs/Hansiong-Hub/refs/heads/main/rodlists'))
local DBBait = HttpService:JSONDecode(game:HttpGet('https://raw.githubusercontent.com/Hansiongs/Hansiong-Hub/refs/heads/main/baitlists'))
local DBEnchant = HttpService:JSONDecode(game:HttpGet('https://raw.githubusercontent.com/Hansiongs/Hansiong-Hub/refs/heads/main/enchantlists'))

local EnchantMap = {}
for _, v in pairs(DBEnchant) do EnchantMap[tostring(v.Id)] = v.EnchantName end

-- Remapping Function Berdasarkan Dump Terbaru
function EquipToolFromHotbar(n) return Net:RemoteEvent("EquipToolFromHotbar"):FireServer(n or 1) end
function SellAllItems() return Net:RemoteFunction("SellAllItems"):InvokeServer() end
function FavoriteItem(u) return Net:RemoteEvent("FavoriteItem"):FireServer(u) end
function EquipItem(u, i) return Net:RemoteEvent("EquipItem"):FireServer(u, i) end
function PurchaseFishingRod(id) return Net:RemoteFunction("PurchaseFishingRod"):InvokeServer(id) end
function PurchaseBait(id) return Net:RemoteFunction("PurchaseBait"):InvokeServer(id) end
function EquipBait(id) return Net:RemoteEvent("EquipBait"):FireServer(id) end
function PlaceLeverItem(item) return Net:RemoteEvent("PlaceLeverItem"):FireServer(item) end
function PurchaseWeatherEvent(n) return Net:RemoteFunction("PurchaseWeatherEvent"):InvokeServer(n) end
function PurchaseMarketItem(id) return Net:RemoteFunction("PurchaseMarketItem"):InvokeServer(id) end
function RedeemCode(c) return Net:RemoteFunction("RedeemCode"):InvokeServer(c) end
function ConsumePotion(u, a) return Net:RemoteFunction("ConsumePotion"):InvokeServer(u, a or 1) end

-- [LOGIKA QUEST & HELPER TETAP ASLI]
function ConsumePotions()
    local inventory = DataReplion:Get({"Inventory", "Potions"}) or {}
    for _, item in ipairs(inventory) do
        local itemId = tonumber(item.Id)
        if TargetPotions[itemId] and item.UUID then
            pcall(function() ConsumePotion(item.UUID, 1) end)
            task.wait(0.2)
        end
    end
end

function RedeemAllCodes()
    for _, code in ipairs(Codes) do
        pcall(function() RedeemCode(code) end)
        task.wait(0.2)
    end
end

function PurchaseTotem()
    local purchaseid = Settings["Totem"] == "Mutation" and 8 or 5
    PurchaseMarketItem(purchaseid)
end

function SpawnTotem()
    local items = DataReplion:Get({"Inventory", "Totems"}) or {}
    local totemid = Settings["Totem"] == "Mutation" and 2 or 1
    for _, item in ipairs(items) do
        if tonumber(item.Id) == totemid and item.UUID then
            Net:RemoteEvent("SpawnTotem"):FireServer(item.UUID)
            task.wait(2)
            EquipToolFromHotbar()
            break
        end
    end
end

function GetCoin() return DataReplion:Get("Coins") end

function CheckProgress(progressText)
    if not progressText then return false end
    local cleanText = string.gsub(progressText, ",", "")
    local current, required = string.match(cleanText, "(%d+)%s*/%s*(%d+)")
    if current and required then
        return tonumber(current) >= tonumber(required)
    end
    return string.find(cleanText, "100%%") ~= nil
end

function GetDeepSeaQuest()
    local questList = PlayerGui:FindFirstChild("Quest") and PlayerGui.Quest:FindFirstChild("List") and PlayerGui.Quest.List:FindFirstChild("Inside")
    local results = {"1/1", "1/1", "1/1", "1/1"}
    if questList then
        for _, q in ipairs(questList:GetChildren()) do
            if q:FindFirstChild("Content") then
                local obj1 = q.Content:FindFirstChild("Objective1")
                if obj1 and obj1:FindFirstChild("Prefix", true) and string.find(obj1:FindFirstChild("Prefix", true).Text, "300") then
                    for i = 1, 4 do
                        local progObj = q.Content:FindFirstChild("Objective" .. i):FindFirstChild("Progress", true)
                        results[i] = progObj and progObj.Text or "1/1"
                    end
                    break
                end
            end
        end
    end
    return results
end

function GetJungle2025Quest()
    local questList = PlayerGui:FindFirstChild("Quest") and PlayerGui.Quest:FindFirstChild("List") and PlayerGui.Quest.List:FindFirstChild("Inside")
    local results = {"1/1", "1/1", "1/1", "1/1"}
    if questList then
        for _, q in ipairs(questList:GetChildren()) do
            if q:FindFirstChild("Content") then
                local isTarget = false
                for _, txt in ipairs(q.Content:GetDescendants()) do
                    if txt:IsA("TextLabel") and (string.find(txt.Text, "Create 3") or string.find(txt.Text, "Element")) then
                        isTarget = true; break
                    end
                end
                if isTarget then
                    for i = 1, 4 do
                        local objFrame = q.Content:FindFirstChild("Objective" .. i)
                        local progObj = objFrame and objFrame:FindFirstChild("Progress", true)
                        results[i] = progObj and progObj.Text or "1/1"
                    end
                    break
                end
            end
        end
    end
    return results
end

function GetTempleLevers() return DataReplion:Get("TempleLevers") end
function GetWeather(name) return PlayerGui.Events.Frame.Events[name].Visible end
function GetEquippedUid() return DataReplion:Get("EquippedId") end
function GetEquippedType() return DataReplion:Get("EquippedType") end
function GetEquippedBaitId() return DataReplion:Get("EquippedBaitId") end
function Teleport(location)
    if RootPart.Anchored then
        RootPart.Anchored = false
    end
    RootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    RootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    if Character then
        Character:PivotTo(location)
        task.wait(2.5) 
    end
end

function GetBaits()
    local items = DataReplion:Get({"Inventory", "Baits"}) or {}
    local bestLuck, bestId = -1, nil
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
    local items = DataReplion:Get({"Inventory", "Fishing Rods"}) or {}
    local bestLuck, bestUUID, bestId = -1, nil, nil
    for _, item in ipairs(items) do
        local rodData = DBRod[tostring(item.Id)]
        if rodData and rodData.BaseLuck then
            Owned["Rods"][item.Id] = item.UUID
            if rodData.BaseLuck > bestLuck then
                bestLuck = rodData.BaseLuck
                bestUUID, bestId = item.UUID, item.Id
                Temporary["Enchant1"] = item.Metadata and EnchantMap[tostring(item.Metadata.EnchantId)] or "None"
                Temporary["Enchant2"] = item.Metadata and EnchantMap[tostring(item.Metadata.EnchantId2)] or "None"
            end
        end
    end
    Temporary["BestRod"], Temporary["BestRodId"] = bestUUID, bestId
end

function Set3dRenderingEnabled(status)
    RunService:Set3dRenderingEnabled(status)
    if not status and not Temporary["ScreenGui"] then
        Temporary["ScreenGui"] = Instance.new("ScreenGui", PlayerGui)
        Temporary["ScreenGui"].Name = "BigTextGui"
        local label = Instance.new("TextLabel", Temporary["ScreenGui"])
        label.Size, label.Position, label.BackgroundTransparency = UDim2.new(0.8, 0, 0.3, 0), UDim2.new(0.1, 0, 0.35, 0), 1
        label.Text, label.Font, label.TextScaled = tostring(Player), Enum.Font.GothamBlack, true
    elseif status and Temporary["ScreenGui"] then
        Temporary["ScreenGui"]:Destroy(); Temporary["ScreenGui"] = nil
    end
    Temporary["Render"] = status
end

function contains(tbl, val)
    for _, v in ipairs(tbl) do if v == val then return true end end
    return false
end

local function LoadDB(folder)
    if not folder then return end
    for _, v in ipairs(folder:GetChildren()) do
        local ok, data = pcall(require, v)
        if ok and (data.Data or data) then
            local info = data.Data or data
            local id, name = tostring(info.Id or v.Name), tostring(info.Name or v.Name)
            if DBFish and DBFish[id] then
                info.Tier = DBFish[id].Tier
                if DBFish[id].Rarity then info.Rarity = DBFish[id].Rarity end
            end
            local rarity = info.Rarity and string.upper(tostring(info.Rarity)) or tierToRarity[info.Tier] or "COMMON"
            ItemDatabase[id] = { Name = name, Rarity = rarity, Tier = info.Tier }
            ItemDatabase[name] = ItemDatabase[id]
        end
    end
end

LoadDB(ReplicatedStorage:FindFirstChild("Items"))
LoadDB(ReplicatedStorage:FindFirstChild("Database") and ReplicatedStorage.Database:FindFirstChild("Fish"))
LoadDB(ReplicatedStorage:FindFirstChild("Database") and ReplicatedStorage.Database:FindFirstChild("Items"))

local function ScanSecrets()
    pcall(GetRods)
    local allItems = {}
    for _, v in ipairs(DataReplion:Get({"Inventory", "Fish"}) or {}) do table.insert(allItems, v) end
    for _, v in ipairs(DataReplion:Get({"Inventory", "Items"}) or {}) do table.insert(allItems, v) end
    local secretList, grouped, totalSecretCount = {}, {}, 0
    for _, item in ipairs(allItems) do
        local info = ItemDatabase[tostring(item.Id or item.Name)] or { Name = tostring(item.Id), Rarity = "UNKNOWN" }
        local isTarget = (info.Rarity == "SECRET" or info.Tier == 7)
        local finalName = info.Name
        local variant = item.Metadata and item.Metadata.VariantId
        if not isTarget and variant and FavoriteConfig.WhitelistId[item.Id] and FavoriteConfig.WhitelistVariant[variant] then
            isTarget = true; finalName = variant .. " " .. info.Name
        end
        if isTarget then
            totalSecretCount = totalSecretCount + 1
            if not grouped[finalName] then
                local newEntry = { Name = finalName, Count = 0 }
                table.insert(secretList, newEntry); grouped[finalName] = newEntry
            end
            grouped[finalName].Count = grouped[finalName].Count + 1
        end
    end

    local rodName = Temporary["BestRodId"] and (DBRod[tostring(Temporary["BestRodId"])] and DBRod[tostring(Temporary["BestRodId"])].Name or "Unknown") or "None"
    local payload = {
        Username = Player.Name, UserId = Player.UserId, Status = Temporary["FishingCatch"] > LastCatchCount and "Online" or "Offline",
        TotalSecrets = totalSecretCount, Items = secretList, Rod = rodName, Enchant1 = Temporary["Enchant1"] or "-",
        Enchant2 = Temporary["Enchant2"] or "-", Timestamp = os.time()
    }
    LastCatchCount = Temporary["FishingCatch"]
    local req = (http_request or request)
    if req then req({ Url = ScanConfig.Endpoint, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode(payload)}) end
end

function LowSetting()
    game:GetService("Lighting").GlobalShadows = false
    settings().Rendering.QualityLevel = "Level01"
    for _, v in pairs(game:GetService("Lighting"):GetChildren()) do if v:IsA("PostEffect") then v.Enabled = false end end
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then v.Material, v.Reflectance, v.CastShadow = Enum.Material.SmoothPlastic, 0, false
        elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 1
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then v.Enabled = false end
    end
end

-- Anti-AFK
RunService.Heartbeat:Connect(function()
    if tick() - Temporary["AFK"] > 600 then
        Temporary["AFK"] = tick()
        VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new())
    end
end)

pcall(function()
    game:GetService("GuiService").ErrorMessageChanged:Connect(function()
        task.wait(5)
        TeleportService:Teleport(game.PlaceId, game.Players.LocalPlayer)
    end)
end)

LowSetting()
GetRods()
GetBaits()
RedeemAllCodes()

task.spawn(function()
    task.wait(60)
    while Temporary["Running"] do pcall(ScanSecrets); task.wait(900) end
end)

-- [LOOP UTAMA SAMA PERSIS DENGAN MAIN-V6]
while Temporary["Running"] do
    if Settings["Render"] ~= Temporary["Render"] then Set3dRenderingEnabled(Settings["Render"]) end

    if Settings["AutoFish"] then
        if Temporary["FishCatch"] > Settings["SellCount"] then
            Temporary["FishCatch"] = 0
            SellAllItems()
            task.wait(1)
            if GetEquippedType() ~= "Fishing Rods" then EquipToolFromHotbar() end

            for _, val in pairs(Settings["BuyRods"]) do 
                local rodData = DBRod[tostring(val)]
                if rodData and not Owned["Rods"][tostring(rodData.Id)] and GetCoin() > rodData.Price then 
                    PurchaseFishingRod(rodData.Id) -- Kirim ID, bukan Nama (val)
                    task.wait(1) 
                end 
            end

            for _, val in pairs(Settings["BuyBaits"]) do 
                local baitData = DBBait[tostring(val)]
                if baitData and not Owned["Baits"][tostring(baitData.Id)] and GetCoin() > baitData.Price then 
                    PurchaseBait(baitData.Id) -- Kirim ID, bukan Nama (val)
                    task.wait(1) 
                end 
            end

            for _, val in pairs(Settings["BuyBaits"]) do 
                local baitData = DBBait[tostring(val)]
                if baitData and not Owned["Baits"][tostring(baitData.Id)] and GetCoin() > baitData.Price then 
                    PurchaseBait(baitData.Id) -- Kirim ID, bukan Nama (val)
                    task.wait(1) 
                end 
            end

            GetRods(); GetBaits()
            if Temporary["BestRod"] and GetEquippedUid() ~= Temporary["BestRod"] then EquipItem(Temporary["BestRod"], "Fishing Rods"); task.wait(1) end
            if Temporary["BestBait"] and GetEquippedBaitId() ~= Temporary["BestBait"] then EquipBait(Temporary["BestBait"]); task.wait(0.2) end
            if Temporary["BestRodId"] == 257 and GetCoin() > 1000000 then PurchaseTotem(); task.wait(1) end

            local CanSecret = false
            for k, _ in pairs(Owned["Rods"]) do if DBRod[tostring(k)] and DBRod[tostring(k)].BaseLuck >= 3.8 then CanSecret = true; break end end

            if next(Settings["Quest"]) then
                if contains(Settings["Quest"], "DeepSea") then
                    local q = GetDeepSeaQuest()
                    if not (CheckProgress(q[1]) and CheckProgress(q[2]) and CheckProgress(q[3]) and CheckProgress(q[4])) then
                        DynamicLocation = not CanSecret and "Kohana Volcano" or (not (CheckProgress(q[2]) and CheckProgress(q[3])) and "Sisyphus Statue" or "Treasure Room")
                    else table.remove(Settings["Quest"], 1); DynamicLocation = nil end
                elseif contains(Settings["Quest"], "Jungle2025") then
                    local q = GetJungle2025Quest()
                    if not (CheckProgress(q[1]) and CheckProgress(q[2]) and CheckProgress(q[3])) then
                        local lev = GetTempleLevers()
                        if not lev["Diamond Artifact"] then PlaceLeverItem("Diamond Artifact")
                        elseif not lev["Crescent Artifact"] then PlaceLeverItem("Crescent Artifact")
                        elseif not lev["Hourglass Diamond Artifact"] then PlaceLeverItem("Hourglass Diamond Artifact")
                        elseif not lev["Arrow Artifact"] then PlaceLeverItem("Arrow Artifact") end
                        DynamicLocation = not lev["Diamond Artifact"] and "Diamond Artifact" or (not lev["Crescent Artifact"] and "Crescent Artifact" or "Arrow Artifact")
                    else table.remove(Settings["Quest"], 1); DynamicLocation = nil end
                end
            end

            if not DynamicLocation then DynamicLocation = Settings["DefaultLocation"] end
            if Temporary["Location"] ~= DynamicLocation and DynamicLocation then
                Teleport(Locations[DynamicLocation])        
                Temporary["Location"] = DynamicLocation; task.wait(5)
            end
            ConsumePotions(); SpawnTotem(); task.wait(30)
        end

        if GetEquippedType() ~= "Fishing Rods" then EquipToolFromHotbar() end
        
        if not FishingController:OnCooldown() then
            FishingController:RequestChargeFishingRod(Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2), true)
            
            local guid = nil
            local timeout = tick()
            while not guid and (tick() - timeout < 10) do
                task.wait(0.2)
                guid = FishingController:GetCurrentGUID() 
            end
            
            if guid then
                while FishingController:GetCurrentGUID() == guid do
                    FishingController:RequestFishingMinigameClick()
                    
                    task.wait(0.2 + math.random() * 0.2)
                end
                Temporary["FishingCatch"] = Temporary["FishingCatch"] + 1
                Temporary["FishCatch"] = Temporary["FishCatch"] + 1
                task.wait(0.5)
            end
        end
    else
        Temporary["FishCatch"] = 99999
        task.wait(1)
    end
end
