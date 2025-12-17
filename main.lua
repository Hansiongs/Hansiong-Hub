local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Character = Player.Character or Player.CharacterAdded:Wait()

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Index = Packages:WaitForChild("_Index")
local Net = nil
for _, v in pairs(Index:GetChildren()) do
    if v.Name:match("sleitnick_net") then Net = v:WaitForChild("net"); break end
end
if not Net then return warn("Critical: Net folder not found") end

local Replion = require(Packages:WaitForChild("Replion"))
local DataReplion = Replion.Client:WaitReplion("Data")

local Owned = { ["Rods"] = {}, ["Baits"] = {}, ["Items"] = {} }
local RodDelays = {[1]=0.164, [2]=0.168, [3]=0.172, [4]=0.176, [5]=0.18, [6]=0.184, [7]=0.188}
local Temporary = {
    ["Running"] = true, ["FishCatch"] = 99999, ["FishingCatch"] = 0,
    ["BestRod"] = nil, ["BestRodId"] = nil, ["BestBait"] = nil,
    ["Location"] = nil, ["ScreenGui"] = nil, ["Render"] = nil,
    ["Timex"] = tick(), ["AFK"] = tick(), ["Logs"] = {},
}
local HCfg = {
    FAST = {Id = 257, S = 1.2, Add = 0.05, F = 2, W = 3},
    NORM = {S = 0.6, Add = 0.1, F = 2, W = 3}
}
local HState = {Mode = "NORM", D = 1.0, Lock = false, SStr = 0, FStr = 0, Got = false}

local DBFish = HttpService:JSONDecode(game:HttpGet('https://hrplay.cloud/api/fish_list'))
local DBRod = HttpService:JSONDecode(game:HttpGet('https://hrplay.cloud/api/rod_list'))
local DBBait = HttpService:JSONDecode(game:HttpGet('https://hrplay.cloud/api/bait_list'))

local Locations = {
    ["Sisyphus Statue"] = CFrame.new(-3729,-130,-885),
    ["Esoteric Depths"] = CFrame.new(3253,-1288,1433),
    ["Treasure Room"] = CFrame.new(-3581,-274,-1589),
    ["Underground Cellar"] = CFrame.new(2135,-86,-699),
    ["Sacred Temple"] = CFrame.new(1451,-17,-635),
    ["Kohana Volcano"] = CFrame.new(-551,23,182),
    ["Hourglass Diamond Artifact"] = CFrame.new(1487,3,-843)*CFrame.Angles(0,math.rad(180),0),
    ["Crescent Artifact"] = CFrame.new(1400,3,121)*CFrame.Angles(0,math.rad(180),0),
    ["Diamond Artifact"] = CFrame.new(1837,5,-299)*CFrame.Angles(0,math.rad(270),0),
    ["Arrow Artifact"] = CFrame.new(879,4,-334)*CFrame.Angles(0,math.rad(90),0),
    ["Ancient Ruin"] = CFrame.new(6061,-585,4715),
    ["Crater Island"] = CFrame.new(998,2,5151),
    ["Double Enchant Altar"] = CFrame.new(1480,127,-589),
    ["Enchant Altar"] = CFrame.new(3255,-1301,1371),
    ["Tropical Island"] = CFrame.new(-2152,2,3671),
    ["Coral Reefs"] = CFrame.new(-3181,2,2104),
    ["Ancient Jungle"] = CFrame.new(1275,9,-334),
    ["Kohana"] = CFrame.new(-661,3,714),
    ["Christmast Island"] = CFrame.new(1137,28,1559),
    ["Iron Cavern"] = CFrame.new(-8800,-580,241),
}
local WeathersData = {["Wind"]=10000,["Snow"]=15000,["Cloudy"]=20000,["Storm"]=35000,["Radiant"]=50000,["Shark Hunt"]=300000}

function EquipToolFromHotbar(n) return Net["RE/EquipToolFromHotbar"]:FireServer(n or 1) end
function UnequipToolFromHotbar(n) return Net["RE/UnequipToolFromHotbar"]:FireServer(n or 1) end
function ChargeFishingRod() return Net["RF/ChargeFishingRod"]:InvokeServer(workspace:GetServerTimeNow()) end
function RequestFishingMinigameStarted() return Net["RF/RequestFishingMinigameStarted"]:InvokeServer(-1.233, 0.998+(1.0-0.998)*math.random(), workspace:GetServerTimeNow()) end
function FishingCompleted() return Net["RE/FishingCompleted"]:FireServer() end
function UpdateAutoFishingState(s) return Net["RF/UpdateAutoFishingState"]:InvokeServer(s) end
function CancelFishingInputs() return Net["RF/CancelFishingInputs"]:InvokeServer() end
function SellAllItems() return Net["RF/SellAllItems"]:InvokeServer() end
function FavoriteItem(u) return Net["RE/FavoriteItem"]:FireServer(u) end
function EquipItem(u,i) return Net["RE/EquipItem"]:FireServer(u,i) end
function PurchaseFishingRod(i) return Net["RF/PurchaseFishingRod"]:InvokeServer(i) end
function PurchaseBait(i) return Net["RF/PurchaseBait"]:InvokeServer(i) end
function EquipBait(i) return Net["RE/EquipBait"]:FireServer(i) end
function PlaceLeverItem(i) return Net["RE/PlaceLeverItem"]:FireServer(i) end
function PurchaseWeatherEvent(n) return Net["RF/PurchaseWeatherEvent"]:InvokeServer(n) end

function GetCoin() return DataReplion:Get("Coins") end
function GetCaught() return Player.leaderstats.Caught.Value end
function GetLevel() return DataReplion:Get("Level") end
function GetXP() return DataReplion:Get("XP") end
function GetLocation() return Player.PlayerGui.Events.Frame.Location.Label.Text end
function GetTempleLevers() return DataReplion:Get("TempleLevers") end
function UnlockedTemple() return DataReplion:Get("UnlockedTemple") end
function GetEquippedUid() return DataReplion:Get("EquippedId") end
function GetEquippedType() return DataReplion:Get("EquippedType") end
function GetEquippedBaitId() return DataReplion:Get("EquippedBaitId") end
function GetWeather(n) return Player.PlayerGui.Events.Frame.Events[n].Visible end
function Teleport(loc) if Character and Character:FindFirstChild("HumanoidRootPart") then Character.HumanoidRootPart.CFrame = loc end end

function CheckProgress(txt)
    if not txt then return false end
    local clean = string.gsub(txt, ",", "")
    local cur, req = string.match(clean, "(%d+)%s*/%s*(%d+)")
    if cur and req then return tonumber(cur) >= tonumber(req) end
    return string.find(clean, "100%%") ~= nil
end

function GetDeepSeaQuest()
    local qL = Player.PlayerGui:FindFirstChild("Quest") and Player.PlayerGui.Quest.List.Inside
    local res = {"1/1", "1/1", "1/1", "1/1"}
    if qL then
        for _, q in ipairs(qL:GetChildren()) do
            if q:IsA("Frame") and q:FindFirstChild("Content") and q.Content.Objective1.Prefix.Text:find("300") then
                for i = 1, 4 do res[i] = q.Content["Objective"..i].Progress.Text end
                break
            end
        end
    end
    return res
end

function GetJungle2025Quest()
    local qL = Player.PlayerGui:FindFirstChild("Quest") and Player.PlayerGui.Quest.List.Inside
    local res = {"1/1", "1/1", "1/1", "1/1"}
    if qL then
        for _, q in ipairs(qL:GetChildren()) do
            if q:IsA("Frame") and q:FindFirstChild("Content") then
                local txt = q.Content.Objective1.Prefix.Text or ""
                if txt:find("Create 3") or txt:find("Element") then
                    for i = 1, 4 do res[i] = q.Content["Objective"..i].Progress.Text end
                    break
                end
            end
        end
    end
    return res
end

function GetItems() for _,i in ipairs(DataReplion:Get({"Inventory", "Items"})) do Owned["Items"][i.Id]=true end end
function GetEquippedRodId()
    local u = DataReplion:Get("EquippedId")
    for _,i in ipairs(DataReplion:Get({"Inventory", "Fishing Rods"})) do if i.UUID==u then return i.Id end end
end
function GetBaits()
    local b,l={},{}
    for _,i in ipairs(DataReplion:Get({"Inventory", "Baits"})) do
        if DBBait[tostring(i.Id)] then
            Owned["Baits"][i.Id]=i.UUID
            local lu = DBBait[tostring(i.Id)].BaseLuck
            b[lu]=i.Id; table.insert(l,lu)
        end
    end
    if #l>0 then Temporary["BestBait"]=b[math.max(table.unpack(l))] end
end
function GetRods()
    local r,rid,l={},{},{}
    for _,i in ipairs(DataReplion:Get({"Inventory", "Fishing Rods"})) do
        if DBRod[tostring(i.Id)] then
            Owned["Rods"][i.Id]=i.UUID; rid[i.UUID]=i.Id
            local lu = DBRod[tostring(i.Id)].BaseLuck
            r[lu]=i.UUID; table.insert(l,lu)
        end
    end
    if #l>0 then Temporary["BestRod"]=r[math.max(table.unpack(l))]; Temporary["BestRodId"]=rid[Temporary["BestRod"]] end
end

function Set3dRenderingEnabled(s)
    RunService:Set3dRenderingEnabled(s)
    if not s and not Temporary["ScreenGui"] then
        Temporary["ScreenGui"] = Instance.new("ScreenGui", Player.PlayerGui)
        Temporary["ScreenGui"].Name = "BigTextGui"; Temporary["ScreenGui"].DisplayOrder = 999
        local l = Instance.new("TextLabel", Temporary["ScreenGui"])
        l.Size = UDim2.new(1,0,1,0); l.BackgroundTransparency=1; l.Text="AFK MODE"; l.TextScaled=true
    elseif s and Temporary["ScreenGui"] then Temporary["ScreenGui"]:Destroy(); Temporary["ScreenGui"]=nil end
    Temporary["Render"] = s
end
function contains(t,v) for _,x in ipairs(t) do if x==v then return true end end return false end
function CheckConnection() local s,r=pcall(function() return HttpService:RequestAsync({Url="https://hrplay.cloud/api",Method="GET"}) end) return s and r and r.StatusCode==200 end
function Reconnect() game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, Player) end
function LowSetting()
    local T = workspace:WaitForChild("Terrain")
    T.WaterWaveSize=0; T.WaterWaveSpeed=0; T.WaterReflectance=0; T.WaterTransparency=0
    game:GetService("Lighting").GlobalShadows=false
    pcall(function() settings().Rendering.QualityLevel=1 end)
end

Net["RE/ObtainedNewFishNotification"].OnClientEvent:Connect(function(m1, m2, m3)
    HState.Got = true; HState.FStr = 0
    if not HState.Lock then
        HState.SStr = HState.SStr + 1
        if HState.SStr >= HCfg[HState.Mode].W then
            HState.Lock = true
            local m = (HState.Mode == "FAST") and 0.02 or 0.05
            HState.D = math.floor((HState.D + m) * 1000) / 1000
        end
    end
    Temporary["FishCatch"] = Temporary["FishCatch"] + 1
    if DBFish[tostring(m1)] and (DBFish[tostring(m1)].Tier == 7 or Settings["FavoriteFish"][tostring(m1)]) then
        FavoriteItem(m3.InventoryItem.UUID)
    end
end)

game:GetService("GuiService").ErrorMessageChanged:Connect(function() if Settings["AutoReconnect"] then while CheckConnection() do Reconnect() task.wait(1) end end end)
RunService.Heartbeat:Connect(function() if tick()-Temporary["AFK"]>600 then Temporary["AFK"]=tick(); VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end end)
local function disable(g)
    if g:IsA("ScreenGui") and (g.Name:lower():find("small notification") or g.Name:lower():find("cutscene")) then
        g.Enabled = false
        g:GetPropertyChangedSignal("Enabled"):Connect(function() if g.Enabled then g.Enabled = false end end)
    end
end
for _, v in pairs(PlayerGui:GetChildren()) do disable(v) end
PlayerGui.ChildAdded:Connect(disable)

LowSetting()
GetRods()
GetBaits()

while Temporary["Running"] do
    if Settings["Render"] ~= Temporary["Render"] then Set3dRenderingEnabled(Settings["Render"]) end
    if Settings["AutoFish"] then
        if Temporary["FishCatch"] > Settings["SellCount"] then
            Temporary["FishCatch"] = 0
            SellAllItems(); task.wait(0.2)
            if GetEquippedType() ~= "Fishing Rods" then EquipToolFromHotbar() end
            for _,v in pairs(Settings["BuyRods"]) do
                if DBRod[tostring(v)] and not Owned["Rods"][DBRod[tostring(v)].Id] and GetCoin()>DBRod[tostring(v)].Price then PurchaseFishingRod(DBRod[tostring(v)].Id); task.wait(0.2) end
            end
            for _,v in pairs(Settings["BuyBaits"]) do
                if DBBait[tostring(v)] and not Owned["Baits"][DBBait[tostring(v)].Id] and GetCoin()>DBBait[tostring(v)].Price then PurchaseBait(DBBait[tostring(v)].Id); task.wait(0.2) end
            end
            GetRods(); GetBaits()
            if not Settings["Rod"] and GetEquippedUid()~=Temporary["BestRod"] then EquipItem(Temporary["BestRod"],"Fishing Rods"); task.wait(0.2)
            elseif Settings["Rod"] and DBRod[Settings["Rod"]] and Owned["Rods"][DBRod[Settings["Rod"]].Id] and GetEquippedUid()~=Owned["Rods"][DBRod[Settings["Rod"]].Id] then EquipItem(Owned["Rods"][DBRod[Settings["Rod"]].Id],"Fishing Rods"); task.wait(0.2) end
            if not Settings["Bait"] and GetEquippedBaitId()~=Temporary["BestBait"] then EquipBait(Temporary["BestBait"]); task.wait(0.2) end

            if next(Settings["Quest"]) then
                if contains(Settings["Quest"], "DeepSea") then
                    local q = GetDeepSeaQuest()
                    local d1,d2,d3,d4 = CheckProgress(q[1]), CheckProgress(q[2]), CheckProgress(q[3]), CheckProgress(q[4])
                    if not d1 or not d2 or not d3 or not d4 then
                        if Temporary["BestRod"] and DBRod[tostring(Temporary["BestRodId"])] and DBRod[tostring(Temporary["BestRodId"])].BaseLuck < 3.8 then Settings["Location"] = "Kohana Volcano"
                        elseif not d2 or not d3 then Settings["Location"] = "Sisyphus Statue"
                        elseif not d1 then Settings["Location"] = "Treasure Room" end
                    else table.remove(Settings["Quest"], 1); Settings["Location"] = nil end
                end
                if not contains(Settings["Quest"], "DeepSea") and contains(Settings["Quest"], "Jungle2025") then
                    local q = GetJungle2025Quest()
                    local j1,j2,j3 = CheckProgress(q[1]), CheckProgress(q[2]), CheckProgress(q[3])
                    if not j1 or not j2 or not j3 then
                        local L = GetTempleLevers()
                        if not L["Diamond Artifact"] then PlaceLeverItem("Diamond Artifact"); task.wait(0.2)
                        elseif not L["Crescent Artifact"] then PlaceLeverItem("Crescent Artifact"); task.wait(0.2)
                        elseif not L["Hourglass Diamond Artifact"] then PlaceLeverItem("Hourglass Diamond Artifact"); task.wait(0.2)
                        elseif not L["Arrow Artifact"] then PlaceLeverItem("Arrow Artifact"); task.wait(0.2) end
                        L = GetTempleLevers()
                        if not L["Diamond Artifact"] then Settings["Location"] = "Diamond Artifact"
                        elseif not L["Crescent Artifact"] then Settings["Location"] = "Crescent Artifact"
                        elseif not L["Hourglass Diamond Artifact"] then Settings["Location"] = "Hourglass Diamond Artifact"
                        elseif not L["Arrow Artifact"] then Settings["Location"] = "Arrow Artifact"
                        elseif not j2 then Settings["Location"] = "Arrow Artifact"
                        elseif not j3 then Settings["Location"] = "Sacred Temple" end
                    else table.remove(Settings["Quest"], 1); Settings["Location"] = nil end
                end
            end
            local loc = Settings["Location"] or "Crater Island"
            if Temporary["Location"] ~= loc then Teleport(Locations[loc]); Temporary["Location"] = loc; task.wait(5) end
        end

        local TMode = (Temporary["BestRodId"] == HCfg.FAST.Id) and "FAST" or "NORM"
        if TMode ~= HState.Mode then HState.Mode=TMode; HState.D=HCfg[TMode].S; HState.Lock=false; HState.SStr=0; HState.FStr=0 end

        HState.Got = false
        if HState.Mode == "FAST" then
            task.spawn(function()
                pcall(function() CancelFishingInputs(); task.wait(0.1); ChargeFishingRod(); RequestFishingMinigameStarted() end)
            end)
        else
            pcall(function() CancelFishingInputs() end)
            if pcall(function() ChargeFishingRod() end) then task.wait(0.1); pcall(function() RequestFishingMinigameStarted() end) else continue end
        end

        task.wait(HState.D); FishingCompleted(); task.wait(0.4)

        if not HState.Lock and not HState.Got then
            if HState.SStr > 0 then HState.SStr = 0 end
            HState.FStr = HState.FStr + 1
            if HState.FStr >= HCfg[HState.Mode].F then HState.D = HState.D + HCfg[HState.Mode].Add; HState.FStr = 0 end
        end
    else
        Temporary["FishCatch"] = 99999; task.wait(0.5)
    end
end
