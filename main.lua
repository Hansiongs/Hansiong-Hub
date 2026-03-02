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
    }}

local Temporary = {
    ["Running"] = true,
    ["FishCatch"] = 0,
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
    ["Tropical Grove"] = CFrame.new(-2154.49,7,3670.67),
    ["Ocean"] = CFrame.new(43.05, 20, 2327.63),
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
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataReplion = require(ReplicatedStorage.Packages.Replion).Client:WaitReplion("Data")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local PlayerGui = Player:WaitForChild("PlayerGui")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Net = require(Packages.Net)
local Camera = workspace.CurrentCamera

-- Controller Internal untuk Bypass BAC-8215
local FishingController = require(ReplicatedStorage.Controllers.FishingController)

-- Pemetaan Remote Berdasarkan Dump Sesi Terbaru
function EquipToolFromHotbar(num) return Net:RemoteEvent("EquipToolFromHotbar"):FireServer(num or 1) end
function SellAllItems() return Net:RemoteFunction("SellAllItems"):InvokeServer() end
function FavoriteItem(Uid) return Net:RemoteEvent("FavoriteItem"):FireServer(Uid) end
function EquipItem(Uid, Cat) return Net:RemoteEvent("EquipItem"):FireServer(Uid, Cat) end
function PurchaseFishingRod(Id) return Net:RemoteFunction("PurchaseFishingRod"):InvokeServer(Id) end
function PurchaseBait(Id) return Net:RemoteFunction("PurchaseBait"):InvokeServer(Id) end
function EquipBait(Id) return Net:RemoteEvent("EquipBait"):FireServer(Id) end
function PlaceLeverItem(item) return Net:RemoteEvent("PlaceLeverItem"):FireServer(item) end
function PurchaseWeatherEvent(n) return Net:RemoteFunction("PurchaseWeatherEvent"):InvokeServer(n) end
function PurchaseMarketItem(id) return Net:RemoteFunction("PurchaseMarketItem"):InvokeServer(id) end
function RedeemCode(c) return Net:RemoteFunction("RedeemCode"):InvokeServer(c) end
function ConsumePotion(uuid, amt) return Net:RemoteFunction("ConsumePotion"):InvokeServer(uuid, amt or 1) end

-- Database Loaders
local DBFish = HttpService:JSONDecode(game:HttpGet('https://raw.githubusercontent.com/Hansiongs/Hansiong-Hub/refs/heads/main/fishlists'))
local DBRod = HttpService:JSONDecode(game:HttpGet('https://raw.githubusercontent.com/Hansiongs/Hansiong-Hub/refs/heads/main/rodlists'))
local DBBait = HttpService:JSONDecode(game:HttpGet('https://raw.githubusercontent.com/Hansiongs/Hansiong-Hub/refs/heads/main/baitlists'))
local DBEnchant = HttpService:JSONDecode(game:HttpGet('https://raw.githubusercontent.com/Hansiongs/Hansiong-Hub/refs/heads/main/enchantlists'))

local EnchantMap = {}
for _, v in pairs(DBEnchant) do EnchantMap[tostring(v.Id)] = v.EnchantName end

-- Helper Functions (Sama seperti main-v6)
function ConsumePotions()
    local inventory = DataReplion:Get({"Inventory", "Potions"}) or {}
    for _, item in ipairs(inventory) do
        if TargetPotions[tonumber(item.Id)] and item.UUID then
            pcall(function() ConsumePotion(item.UUID, 1) end)
            task.wait(0.1) 
        end
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
            task.wait(1); EquipToolFromHotbar(); break 
        end
    end
end

function CheckProgress(text)
    if not text then return false end
    local c, r = string.match(string.gsub(text, ",", ""), "(%d+)%s*/%s*(%d+)")
    return (c and r and tonumber(c) >= tonumber(r)) or string.find(text, "100%%") ~= nil
end

function GetDeepSeaQuest()
    local qL = PlayerGui:FindFirstChild("Quest") and PlayerGui.Quest.List.Inside
    local res = {"1/1", "1/1", "1/1", "1/1"}
    if qL then
        for _, q in ipairs(qL:GetChildren()) do
            if q:FindFirstChild("Content") and q.Content.Objective1:FindFirstChild("Prefix", true) and string.find(q.Content.Objective1:FindFirstChild("Prefix", true).Text, "300") then
                for i=1,4 do res[i] = q.Content["Objective"..i]:FindFirstChild("Progress", true).Text end
                break
            end
        end
    end
    return res
end

function GetRods()
    local items = DataReplion:Get({"Inventory", "Fishing Rods"}) or {}
    local bestL, bestU, bestI = -1, nil, nil
    for _, item in ipairs(items) do
        local data = DBRod[tostring(item.Id)]
        if data and data.BaseLuck and data.BaseLuck > bestL then
            bestL, bestU, bestI = data.BaseLuck, item.UUID, item.Id
            Temporary["Enchant1"] = item.Metadata and EnchantMap[tostring(item.Metadata.EnchantId)] or "None"
            Temporary["Enchant2"] = item.Metadata and EnchantMap[tostring(item.Metadata.EnchantId2)] or "None"
        end
    end
    Temporary["BestRod"], Temporary["BestRodId"] = bestU, bestI
end

function GetBaits()
    local items = DataReplion:Get({"Inventory", "Baits"}) or {}
    local bestL, bestI = -1, nil
    Owned["Baits"] = {}
    for _, item in ipairs(items) do
        local data = DBBait[tostring(item.Id)]
        if data and data.BaseLuck then
            Owned["Baits"][item.Id] = item.UUID
            if data.BaseLuck > bestL then bestL, bestI = data.BaseLuck, item.Id end
        end
    end
    Temporary["BestBait"] = bestI
end

-- Scan & Webhook (Tetap asli)
local function ScanSecrets()
    GetRods()
    local all = {}
    for _, v in ipairs(DataReplion:Get({"Inventory", "Fish"}) or {}) do table.insert(all, v) end
    for _, v in ipairs(DataReplion:Get({"Inventory", "Items"}) or {}) do table.insert(all, v) end
    local list, total = {}, 0
    for _, item in ipairs(all) do
        local r = item.Metadata and item.Metadata.Rarity or "COMMON"
        if r == "SECRET" or item.Tier == 7 then
            total = total + 1
            local name = item.Id or "Unknown"
            list[name] = (list[name] or 0) + 1
        end
    end
    local payload = { Username = Player.Name, TotalSecrets = total, Rod = Temporary["BestRodId"], Timestamp = os.time() }
    pcall(function() 
        (http_request or request)({ Url = ScanConfig.Endpoint, Method = "POST", Headers = {["Content-Type"]="application/json"}, Body = HttpService:JSONEncode(payload) })
    end)
end

-- Anti-AFK & Low Graphics
RunService.Heartbeat:Connect(function()
    if tick() - Temporary["AFK"] > 600 then
        Temporary["AFK"] = tick()
        VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- Main Loop Logic
task.spawn(function() while Temporary["Running"] do pcall(ScanSecrets); task.wait(900) end end)

while Temporary["Running"] do
    if Settings["AutoFish"] then
        -- 1. Inventory & Shop Management
        if Temporary["FishCatch"] >= Settings["SellCount"] then
            Temporary["FishCatch"] = 0
            SellAllItems()
            task.wait(0.5)
            
            -- Auto Buy Rods/Baits/Weathers
            for _, val in pairs(Settings["BuyRods"]) do if not Owned["Rods"][val] and DataReplion:Get("Coins") > 1000 then PurchaseFishingRod(val) end end
            GetRods(); GetBaits()
            
            if Temporary["BestRod"] and DataReplion:Get("EquippedId") ~= Temporary["BestRod"] then
                EquipItem(Temporary["BestRod"], "Fishing Rods"); task.wait(1)
            end
            if Temporary["BestBait"] and DataReplion:Get("EquippedBaitId") ~= Temporary["BestBait"] then
                EquipBait(Temporary["BestBait"]); task.wait(0.5)
            end
            
            -- Quest & Teleport Logic
            if next(Settings["Quest"]) then
                if contains(Settings["Quest"], "DeepSea") then
                    local q = GetDeepSeaQuest()
                    if CheckProgress(q[1]) and CheckProgress(q[2]) then table.remove(Settings["Quest"], 1) end
                end
            end
            
            local targetLoc = Settings["DefaultLocation"]
            if Temporary["Location"] ~= targetLoc then
                Teleport(Locations[targetLoc]); Temporary["Location"] = targetLoc; task.wait(5)
            end
            ConsumePotions(); SpawnTotem()
        end

        -- 2. Mekanisme Mancing Aman (Internal Controller)
        if DataReplion:Get("EquippedType") ~= "Fishing Rods" then EquipToolFromHotbar() end
        
        if not FishingController:OnCooldown() then
            -- Langkah 1: Charge (Menggunakan flag 'true' untuk bypass baris 478)
            FishingController:RequestChargeFishingRod(Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2), true)
            
            -- Langkah 2: Tunggu Ikan (Mendapatkan GUID Sesi)
            local guid = nil
            local timeout = tick()
            while not guid and (tick() - timeout < 15) and Temporary["Running"] do
                task.wait(0.2)
                guid = FishingController:GetCurrentGUID()
            end
            
            -- Langkah 3: Minigame (Simulasi Klik Manusia untuk bypass BAC-8215)
            if guid then
                print("Sesi valid: "..tostring(guid))
                while FishingController:GetCurrentGUID() == guid and Temporary["Running"] do
                    FishingController:RequestFishingMinigameClick()
                    -- Delay acak agar tidak terbaca bot (sangat penting!)
                    task.wait(0.1 + math.random() * 0.2)
                end
                Temporary["FishingCatch"] = Temporary["FishingCatch"] + 1
                Temporary["FishCatch"] = Temporary["FishCatch"] + 1
                task.wait(1)
            end
        end
    end
    task.wait(0.5)
end
