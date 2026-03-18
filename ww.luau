local P = game:GetService("Players").LocalPlayer
local CG = game:GetService("CoreGui")
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local RunS = game:GetService("RunService")
local Stats = game:GetService("Stats")
local VU = game:GetService("VirtualUser")

if CG:FindFirstChild("MacOSFishGUI") then CG.MacOSFishGUI:Destroy() end

local C3, U2 = Color3.fromRGB, UDim2.new
local F_G, F_GM, F_GB = Enum.Font.Gotham, Enum.Font.GothamMedium, Enum.Font.GothamBold

local function C(cls, props)
    local o = Instance.new(cls)
    for k, v in pairs(props or {}) do
        if type(k) == "number" then v.Parent = o
        elseif k == "Click" then o.MouseButton1Click:Connect(v)
        elseif k == "Focus" then o.FocusLost:Connect(v)
        else o[k] = v end
    end
    return o
end

local Dropdown = {}
Dropdown.__index = Dropdown
function Dropdown.new(parent, y, title, items, cb)
    local self = setmetatable({Open=false, Items=items, CB=cb}, Dropdown)
    C("TextLabel", {Parent=parent, Size=U2(0,120,0,20), Position=U2(0,20,0,y), BackgroundTransparency=1, Text=title, TextColor3=C3(80,80,80), Font=F_GM, TextSize=12, TextXAlignment=0})
    self.Btn = C("TextButton", {Parent=parent, Size=U2(1,-40,0,30), Position=U2(0,20,0,y+22), BackgroundColor3=C3(255,255,255), Text="  Select...", TextColor3=C3(50,50,50), Font=F_G, TextSize=13, TextXAlignment=0, ZIndex=2, C("UICorner",{CornerRadius=UDim.new(0,6)}), C("UIStroke",{Color=C3(210,210,210)}), Click=function() self:Toggle() end})
    self.Arrow = C("TextLabel", {Parent=self.Btn, Size=U2(0,20,1,0), Position=U2(1,-25,0,0), BackgroundTransparency=1, Text="▼", TextColor3=C3(150,150,150), Font=F_G, TextSize=10, ZIndex=2})
    self.Scroll = C("ScrollingFrame", {Parent=parent, Size=U2(1,-40,0,100), Position=U2(0,20,0,y+55), BackgroundColor3=C3(255,255,255), BorderSizePixel=0, ScrollBarThickness=4, Visible=false, ZIndex=5, C("UICorner",{CornerRadius=UDim.new(0,6)}), C("UIStroke",{Color=C3(210,210,210)}), C("UIListLayout")})
    self:Render()
    return self
end
function Dropdown:Toggle() self.Open = not self.Open; self.Scroll.Visible = self.Open; self.Arrow.Text = self.Open and "▲" or "▼" end
function Dropdown:Render(nItems)
    if nItems then self.Items = nItems end
    for _, c in pairs(self.Scroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    for _, itm in ipairs(self.Items) do
        C("TextButton", {Parent=self.Scroll, Size=U2(1,0,0,25), BackgroundColor3=C3(255,255,255), BorderSizePixel=0, Text="  "..itm.name, TextColor3=C3(60,60,60), Font=F_G, TextSize=12, TextXAlignment=0, ZIndex=6, Click=function() self.Btn.Text="  "..itm.name; self:Toggle(); if self.CB then self.CB(itm.val) end end})
    end
    self.Scroll.CanvasSize = U2(0,0,0, #self.Items*25)
end
function Dropdown:Reset() self.Btn.Text = "  Select..." end

local UI = { Tabs = {}, Frames = {} }
UI.SG = C("ScreenGui", {Name="MacOSFishGUI", Parent=CG})
UI.MF = C("Frame", {Parent=UI.SG, Size=U2(0,360,0,350), Position=U2(0.5,-180,0.5,-175), BackgroundColor3=C3(245,245,245), Active=true, Draggable=true, ClipsDescendants=true, C("UICorner",{CornerRadius=UDim.new(0,12)}), C("UIStroke",{Color=C3(220,220,220)})})
UI.TB = C("Frame", {Parent=UI.MF, Size=U2(1,0,0,30), BackgroundTransparency=1})
C("TextButton", {Parent=UI.TB, Size=U2(0,12,0,12), Position=U2(0,12,0.5,-6), BackgroundColor3=C3(255,95,86), Text="", C("UICorner",{CornerRadius=UDim.new(1,0)}), Click=function() UI.SG:Destroy() end})
C("TextButton", {Parent=UI.TB, Size=U2(0,12,0,12), Position=U2(0,32,0.5,-6), BackgroundColor3=C3(255,189,46), Text="", C("UICorner",{CornerRadius=UDim.new(1,0)}), Click=function() UI.Min = not UI.Min; UI.CC.Visible = not UI.Min; UI.MF:TweenSize(U2(0,360,0,UI.Min and 30 or 350), "Out", "Quad", 0.3, true) end})
C("Frame", {Parent=UI.TB, Size=U2(0,12,0,12), Position=U2(0,52,0.5,-6), BackgroundColor3=C3(39,201,63), C("UICorner",{CornerRadius=UDim.new(1,0)})})
C("TextLabel", {Parent=UI.TB, Size=U2(1,0,1,0), BackgroundTransparency=1, Text="Fishing Island ~ KemplongXD", TextColor3=C3(100,100,100), Font=F_GM, TextSize=12})
UI.TabC = C("Frame", {Parent=UI.MF, Size=U2(0,320,0,24), Position=U2(0.5,-160,0,35), BackgroundColor3=C3(225,225,225), C("UICorner",{CornerRadius=UDim.new(0,6)})})
UI.CC = C("Frame", {Parent=UI.MF, Size=U2(1,0,1,-70), Position=U2(0,0,0,70), BackgroundTransparency=1})

function UI:AddTab(name, pos, active)
    local btn = C("TextButton", {Parent=self.TabC, Size=U2(0.25,0,1,0), Position=pos, BackgroundTransparency=active and 0 or 1, BackgroundColor3=C3(255,255,255), Text=name, TextColor3=active and C3(50,50,50) or C3(120,120,120), Font=F_GM, TextSize=10, C("UICorner",{CornerRadius=UDim.new(0,6)})})
    local frm = C("Frame", {Parent=self.CC, Size=U2(1,0,1,0), BackgroundTransparency=1, Visible=active})
    table.insert(self.Tabs, btn); table.insert(self.Frames, frm)
    btn.MouseButton1Click:Connect(function()
        for i, t in ipairs(self.Tabs) do t.BackgroundTransparency=1; t.TextColor3=C3(120,120,120); self.Frames[i].Visible=false end
        btn.BackgroundTransparency=0; btn.TextColor3=C3(50,50,50); frm.Visible=true
    end)
    return frm
end

local Leaderboard = { Sort = "Val", Frm = UI:AddTab("Dashboard", U2(0,0,0,0), true) }
C("ImageLabel", {Parent=Leaderboard.Frm, Size=U2(0,45,0,45), Position=U2(0,20,0,5), BackgroundColor3=C3(220,220,220), Image=game.Players:GetUserThumbnailAsync(P.UserId,0,0), C("UICorner",{CornerRadius=UDim.new(1,0)})})
C("TextLabel", {Parent=Leaderboard.Frm, Size=U2(0,150,0,20), Position=U2(0,75,0,8), BackgroundTransparency=1, Text=P.DisplayName, TextColor3=C3(40,40,40), Font=F_GB, TextSize=15, TextXAlignment=0})
Leaderboard.LblCaught = C("TextLabel", {Parent=Leaderboard.Frm, Size=U2(0,150,0,15), Position=U2(0,75,0,30), BackgroundTransparency=1, Text="Total Caught: 0", TextColor3=C3(0,122,255), Font=F_GM, TextSize=12, TextXAlignment=0})
Leaderboard.LblStats = C("TextLabel", {Parent=Leaderboard.Frm, Size=U2(0,100,0,30), Position=U2(1,-120,0,15), BackgroundTransparency=1, Text="Ping: 0ms\nFPS: 0", TextColor3=C3(150,150,150), Font=Enum.Font.Code, TextSize=11, TextXAlignment=1})
C("TextLabel", {Parent=Leaderboard.Frm, Size=U2(0,150,0,20), Position=U2(0,20,0,65), BackgroundTransparency=1, Text="Server Leaderboard", TextColor3=C3(100,100,100), Font=F_GM, TextSize=12, TextXAlignment=0})
Leaderboard.BtnSort = C("TextButton", {Parent=Leaderboard.Frm, Size=U2(0,80,0,18), Position=U2(1,-100,0,65), BackgroundColor3=C3(220,220,220), Text="Sort: Coin", TextColor3=C3(80,80,80), Font=F_G, TextSize=11, C("UICorner",{CornerRadius=UDim.new(0,4)}), Click=function() Leaderboard.Sort = Leaderboard.Sort=="Val" and "Name" or "Val"; Leaderboard.BtnSort.Text = "Sort: "..(Leaderboard.Sort=="Val" and "Coin" or "Name"); Leaderboard:Update() end})
Leaderboard.Scroll = C("ScrollingFrame", {Parent=Leaderboard.Frm, Size=U2(1,-40,1,-95), Position=U2(0,20,0,85), BackgroundColor3=C3(255,255,255), BorderSizePixel=0, ScrollBarThickness=4, C("UICorner",{CornerRadius=UDim.new(0,8)}), C("UIStroke",{Color=C3(220,220,220)}), C("UIListLayout",{Padding=UDim.new(0,2)})})

function Leaderboard:Fmt(n) local x=tonumber(n); if not x then return tostring(n) end return x>=1e9 and string.format("%.1fB",x/1e9):gsub("%.0","") or (x>=1e6 and string.format("%.1fM",x/1e6):gsub("%.0","") or (x>=1e3 and string.format("%.1fk",x/1e3):gsub("%.0","") or tostring(x))) end
function Leaderboard:Update()
    for _,c in pairs(self.Scroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    local pd = {}
    for _, p in ipairs(game.Players:GetPlayers()) do
        local vC, dC, dF = 0, "0", ""
        if p:FindFirstChild("leaderstats") then
            for _, st in ipairs(p.leaderstats:GetChildren()) do
                local n = st.Name:lower()
                if n:find("fish") or n:find("caught") then dF = " | 🐟 "..self:Fmt(st.Value)
                else vC = tonumber(st.Value) or 0; dC = self:Fmt(st.Value) end
            end
        end
        table.insert(pd, {n=p.DisplayName, v=vC, d=dC..dF})
    end
    table.sort(pd, self.Sort=="Val" and function(a,b) return a.v>b.v end or function(a,b) return a.n:lower()<b.n:lower() end)
    for _, d in ipairs(pd) do
        local f = C("Frame", {Parent=self.Scroll, Size=U2(1,0,0,25), BackgroundTransparency=1})
        C("TextLabel", {Parent=f, Size=U2(0.5,0,1,0), Position=U2(0,10,0,0), BackgroundTransparency=1, Text=d.n, TextColor3=C3(60,60,60), Font=F_G, TextSize=12, TextXAlignment=0})
        C("TextLabel", {Parent=f, Size=U2(0.5,-15,1,0), Position=U2(0.5,0,0,0), BackgroundTransparency=1, Text=d.d, TextColor3=C3(0,122,255), Font=F_GM, TextSize=11, TextXAlignment=1})
    end
    self.Scroll.CanvasSize = U2(0,0,0,#pd*27)
end

local FishBot = { Frm = UI:AddTab("Auto Fish", U2(0.25,0,0,0), false), Active = false, Rod = nil, Caught = 0, Delay = 1.8, Dist = 20 }
local function MkInp(frm, y, txt, def, cb) C("TextLabel", {Parent=frm, Size=U2(0,120,0,25), Position=U2(0,20,0,y), BackgroundTransparency=1, Text=txt, TextColor3=C3(80,80,80), Font=F_G, TextSize=13, TextXAlignment=0}); return C("TextBox", {Parent=frm, Size=U2(0,150,0,25), Position=U2(1,-170,0,y), BackgroundColor3=C3(255,255,255), Text=def, TextColor3=C3(50,50,50), Font=F_G, TextSize=13, C("UICorner",{CornerRadius=UDim.new(0,6)}), C("UIStroke",{Color=C3(210,210,210)}), Focus=cb}) end
FishBot.TxtDly = MkInp(FishBot.Frm, 10, "Cast Delay (s):", "1.8", function(b) FishBot.Delay = tonumber(b.Text) or 1.8; b.Text=tostring(FishBot.Delay) end)
C("TextLabel", {Parent=FishBot.Frm, Size=U2(1,-40,0,15), Position=U2(0,20,0,37), BackgroundTransparency=1, Text="Recommended: 1.8s (Safe from Anti-Cheat)", TextColor3=C3(255,149,0), Font=F_G, TextSize=10, TextXAlignment=0})
FishBot.TxtDist = MkInp(FishBot.Frm, 60, "Distance (studs):", "20", function(b) FishBot.Dist = tonumber(b.Text) or 20; b.Text=tostring(FishBot.Dist) end)
C("TextLabel", {Parent=FishBot.Frm, Size=U2(0,120,0,25), Position=U2(0,20,0,100), BackgroundTransparency=1, Text="Equipped Rod:", TextColor3=C3(80,80,80), Font=F_G, TextSize=13, TextXAlignment=0})
FishBot.LblRod = C("TextLabel", {Parent=FishBot.Frm, Size=U2(0,150,0,25), Position=U2(1,-170,0,100), BackgroundColor3=C3(235,235,235), Text="Detecting...", TextColor3=C3(100,100,100), Font=F_GM, TextSize=12, C("UICorner",{CornerRadius=UDim.new(0,6)}), C("UIStroke",{Color=C3(210,210,210)})})
FishBot.Btn = C("TextButton", {Parent=FishBot.Frm, Size=U2(0,320,0,40), Position=U2(0.5,-160,0,145), BackgroundColor3=C3(180,180,180), Text="Lock: Equip Rod", TextColor3=C3(255,255,255), Font=F_GM, TextSize=14, AutoButtonColor=false, C("UICorner",{CornerRadius=UDim.new(0,8)}), Click=function() FishBot:Start() end})
FishBot.Notif = C("TextLabel", {Parent=FishBot.Frm, Size=U2(1,0,0,20), Position=U2(0,0,0,200), BackgroundTransparency=1, Text="", TextColor3=C3(52,199,89), Font=F_GM, TextSize=12, TextTransparency=1})

function FishBot:ShowMsg(msg, col) self.Notif.Text=msg; self.Notif.TextColor3=col or C3(52,199,89); TS:Create(self.Notif,TweenInfo.new(0.2),{TextTransparency=0}):Play(); task.delay(0.7, function() TS:Create(self.Notif,TweenInfo.new(0.5),{TextTransparency=1}):Play() end) end
function FishBot:Start()
    if not self.Rod then return end; self.Active = not self.Active
    self.Btn.Text = self.Active and "Stop Fishing" or "Start Fishing"
    self.Btn.BackgroundColor3 = self.Active and C3(255,59,48) or C3(0,122,255)
    if self.Active then task.spawn(function() while self.Active and self.Rod do self:Loop(); task.wait(self.Delay) end end) end
end
function FishBot:Loop()
    local c = P.Character; local h = c and c:FindFirstChild("HumanoidRootPart")
    if not h then return end
    local tp = h.Position + (h.CFrame.LookVector * self.Dist) - Vector3.new(0,2,0)
    local res = "Success"
    local s = pcall(function()
        RS.FishingSystem.CastReplication:FireServer(tp, h.Position, self.Rod, 95); task.wait(0.2); RS.FishingSystem.CastReplication:FireServer(); task.wait(0.2)
        local d = RS.FishingSystem.RollFishServer:InvokeServer(self.Rod, 1)
        if type(d)=="string" then res = "Caught: "..d elseif type(d)=="table" and d.Name then res = "Caught: "..tostring(d.Name) end
        task.wait(0.2); RS.FishingCatchSuccess:FireServer(); task.wait(0.2); RS.FishingSystem.CleanupCast:FireServer(); task.wait(0.2); RS.FishingSystem.FishGiver:FireServer({hookPosition=tp})
    end)
    if s and self.Active then self.Caught=self.Caught+1; Leaderboard.LblCaught.Text="Total Caught: "..self.Caught; self:ShowMsg(res) end
end

local Teleporter = { Frm = UI:AddTab("Teleport", U2(0.5,0,0,0), false), S_Isl=nil, S_Plr=nil }
function Teleporter:TP(pos) local c=P.Character; local h=c and c:FindFirstChild("HumanoidRootPart"); if h then h.CFrame=CFrame.new(pos)+Vector3.new(0,5,0) end end
function Teleporter:GetPlr() local l={}; for _,p in ipairs(game.Players:GetPlayers()) do if p~=P then table.insert(l,{name=p.DisplayName, val=p}) end end; return l end
Dropdown.new(Teleporter.Frm, 10, "Select Island", {{name="Christmas Island", val=Vector3.new(269,239,40)}, {name="Fisherman Island", val=Vector3.new(-412.2,243.1,-41.2)}, {name="Mythical Island", val=Vector3.new(-590.4,243.0,-1394.1)}, {name="Verdant Isle", val=Vector3.new(519.4,239.9,-1030.2)}}, function(v) Teleporter.S_Isl = v end)
C("TextButton", {Parent=Teleporter.Frm, Size=U2(1,-40,0,30), Position=U2(0,20,0,70), BackgroundColor3=C3(0,122,255), Text="Teleport to Island", TextColor3=C3(255,255,255), Font=F_GM, TextSize=13, ZIndex=1, C("UICorner",{CornerRadius=UDim.new(0,6)}), Click=function() if Teleporter.S_Isl then Teleporter:TP(Teleporter.S_Isl) end end})
Teleporter.PlrDrop = Dropdown.new(Teleporter.Frm, 120, "Select Player", Teleporter:GetPlr(), function(v) Teleporter.S_Plr = v end)
C("TextButton", {Parent=Teleporter.Frm, Size=U2(0,60,0,20), Position=U2(1,-80,0,120), BackgroundColor3=C3(0,122,255), Text="Refresh", TextColor3=C3(255,255,255), Font=F_GM, TextSize=11, C("UICorner",{CornerRadius=UDim.new(0,4)}), Click=function() Teleporter.PlrDrop:Render(Teleporter:GetPlr()); Teleporter.PlrDrop:Reset(); Teleporter.S_Plr=nil end})
C("TextButton", {Parent=Teleporter.Frm, Size=U2(1,-40,0,30), Position=U2(0,20,0,180), BackgroundColor3=C3(0,122,255), Text="Teleport to Player", TextColor3=C3(255,255,255), Font=F_GM, TextSize=13, ZIndex=1, C("UICorner",{CornerRadius=UDim.new(0,6)}), Click=function() if Teleporter.S_Plr and Teleporter.S_Plr.Character and Teleporter.S_Plr.Character:FindFirstChild("HumanoidRootPart") then Teleporter:TP(Teleporter.S_Plr.Character.HumanoidRootPart.Position) end end})

local MiscTools = { Frm = UI:AddTab("Misc", U2(0.75,0,0,0), false), AFK=false, SW=false, SWPart=C("Part",{Parent=workspace,Size=Vector3.new(15,1,15),Anchored=true,Transparency=0.5,CanCollide=false}) }
local function MkTgl(y, txt, cb) local s=false; local b=C("TextButton",{Parent=MiscTools.Frm, Size=U2(1,-40,0,35), Position=U2(0,20,0,y), BackgroundColor3=C3(220,220,220), Text=txt.." [OFF]", TextColor3=C3(80,80,80), Font=F_GM, TextSize=13, C("UICorner",{CornerRadius=UDim.new(0,6)})}); b.MouseButton1Click:Connect(function() s=not s; b.Text=txt..(s and" [ON]"or" [OFF]"); b.BackgroundColor3=s and C3(0,122,255) or C3(220,220,220); b.TextColor3=s and C3(255,255,255) or C3(80,80,80); cb(s) end) end
MkTgl(20, "Anti AFK", function(v) MiscTools.AFK=v end); P.Idled:Connect(function() if MiscTools.AFK then VU:CaptureController(); VU:ClickButton2(Vector2.new()) end end)
MkTgl(65, "Skywalk Platform", function(v) MiscTools.SW=v end)
C("TextButton",{Parent=MiscTools.Frm, Size=U2(1,-40,0,35), Position=U2(0,20,0,110), BackgroundColor3=C3(0,122,255), Text="Boost FPS (Remove Textures)", TextColor3=C3(255,255,255), Font=F_GM, TextSize=13, C("UICorner",{CornerRadius=UDim.new(0,6)}), Click=function() game.Lighting.GlobalShadows=false; for _,v in pairs(workspace:GetDescendants()) do if v:IsA("BasePart") then v.Material=Enum.Material.SmoothPlastic; v.Reflectance=0 elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency=1 end end end})

task.spawn(function()
    while task.wait(0.5) do
        Leaderboard:Update()
        local t = P.Character and P.Character:FindFirstChildOfClass("Tool")
        FishBot.Rod = t and t.Name or nil
        if FishBot.Rod then FishBot.LblRod.Text = FishBot.Rod; FishBot.LblRod.TextColor3 = C3(0,122,255); if not FishBot.Active then FishBot.Btn.BackgroundColor3 = C3(0,122,255); FishBot.Btn.Text = "Start Fishing"; FishBot.Btn.AutoButtonColor = true end
        else FishBot.LblRod.Text = "Not Equipped"; FishBot.LblRod.TextColor3 = C3(255,59,48); FishBot.Btn.BackgroundColor3 = C3(180,180,180); FishBot.Btn.Text = "Lock: Equip Rod"; FishBot.Btn.AutoButtonColor = false end
        if FishBot.Active and not FishBot.Rod then FishBot.Active = false; FishBot:ShowMsg("Rod Unequipped! Stopped.", C3(255,59,48)) end
    end
end)

RunS.RenderStepped:Connect(function(dt)
    local p="0"; pcall(function() p=tostring(math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())) end); Leaderboard.LblStats.Text = "Ping: "..p.."ms\nFPS: "..math.floor(1/dt)
    if MiscTools.SW and P.Character and P.Character:FindFirstChild("HumanoidRootPart") then MiscTools.SWPart.CanCollide=true; MiscTools.SWPart.CFrame=CFrame.new(P.Character.HumanoidRootPart.Position - Vector3.new(0,3.5,0)) else MiscTools.SWPart.CanCollide=false end
end)
