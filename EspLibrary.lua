-- ERX player ESP, based on skibidihook's EspLibrary.
-- The embedded font was removed; ERX uses the player renderer.
-- Full credits to: sigma (0v92 on discord) i did not make any of this

local CloneRef = cloneref or function(...) return ... end
local Workspace = CloneRef(game:GetService("Workspace"))
local CurrentCamera = CloneRef(Workspace.CurrentCamera)
local WorldToViewportPoint = CurrentCamera.WorldToViewportPoint

local DrawingNew    = Drawing.new
local Vector2New    = Vector2.new
local Vector3New    = Vector3.new
local Color3New     = Color3.new
local TableRemove   = table.remove
local TableClear    = table.clear
local MathFloor     = math.floor
local MathRound     = math.round
local MathHuge      = math.huge
local MathMax       = math.max
local MathAbs       = math.abs
local CFrameNew     = CFrame.new
local StringLower   = string.lower
local Type          = type
local OsClock       = os.clock

local ColorBlack = Color3New(0, 0, 0)
local ColorWhite = Color3New(1, 1, 1)
local ColorGreen = Color3New(0, 1, 0)
local ColorRed   = Color3New(1, 0, 0)

local VisibleItemsBuffer = {}
local LibraryConnections = {}

LibraryConnections[#LibraryConnections + 1] = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    local NewCamera = Workspace.CurrentCamera
    if NewCamera then CurrentCamera = CloneRef(NewCamera) end
end)

local CreateDrawing = function(DrawingType, Properties, Container)
    local DrawingObject = DrawingNew(DrawingType)
    for Key, Value in next, Properties do
        DrawingObject[Key] = Value
    end
    if Container then
        Container[#Container + 1] = DrawingObject
    end
    return DrawingObject
end

local DisconnectAll = function(Connections)
    for Index = 1, #Connections do
        pcall(Connections[Index].Disconnect, Connections[Index])
    end
    TableClear(Connections)
end

local HideDrawingSet = function(AllDrawings, Drawings)
    for Index = 1, #AllDrawings do
        AllDrawings[Index].Visible = false
    end
    Drawings.BoxState   = "hidden"
    Drawings.FlagsShown = 0
end

local MakeCallbackRegistry = function(Callbacks)
    return function(Callback)
        Callbacks[#Callbacks + 1] = Callback
        local Handle
        Handle = {
            Connected = true,
            Disconnect = function()
                if not Handle.Connected then return end
                Handle.Connected = false
                for Index = 1, #Callbacks do
                    if Callbacks[Index] == Callback then
                        TableRemove(Callbacks, Index)
                        break
                    end
                end
            end,
        }
        return Handle
    end
end


local GlobalFont = (getgenv and getgenv().GLOBAL_FONT) or _G.GLOBAL_FONT or 1
local GlobalSize = (getgenv and getgenv().GLOBAL_SIZE) or _G.GLOBAL_SIZE or 13
local BaseZIndex = 1

local EspLibrary = {}

EspLibrary.Enabled = true

EspLibrary.Config = {
    Font               = GlobalFont,
    TextSize           = GlobalSize,
    FlagSize           = GlobalSize,
    FlagLinePadding    = 2,
    FlagXPadding       = 6,
    BoxCornerWidthScale  = 0.25,
    BoxCornerHeightScale = 0.25,
    PixelSnap          = true,
    NameMode           = "Username",
    BoundsRefreshInterval = 0.05,
    BoundsMode             = "Accurate",
    BoxOutlineThickness    = 3,
    BoxOutlineTransparency = 0.55,
}

do
    local GetCachedBounds = function(Holder, Container)
        local Cfg = EspLibrary.Config

        if Cfg.BoundsMode == "Accurate" and Container:IsA("Model") then
            return Container:GetBoundingBox()
        end

        local Now = OsClock()
        local Anchor = Holder.BoundsAnchor
        if Anchor
            and Holder.BoundsMinOffset
            and (Now - Holder.BoundsStamp) < Cfg.BoundsRefreshInterval
            and Anchor.Parent
        then
            local AnchorPosition = Anchor.Position
            local MinV = AnchorPosition + Holder.BoundsMinOffset
            local MaxV = AnchorPosition + Holder.BoundsMaxOffset
            return CFrameNew((MinV + MaxV) * 0.5), MaxV - MinV
        end

        local MinX, MinY, MinZ =  MathHuge,  MathHuge,  MathHuge
        local MaxX, MaxY, MaxZ = -MathHuge, -MathHuge, -MathHuge
        local Found = false
        local Whitelist = EspLibrary.CharacterWhitelist
        local Parts = Holder.Parts
        local List = Parts or Container:GetChildren()
        for _ = 1, 2 do
            for Index = 1, #List do
                local Part = List[Index]
                if not Parts and not Part:IsA("BasePart") then continue end
                if Whitelist and not Whitelist[Part.Name] then continue end
                local Position = Part.Position
                local Size = Part.Size
                local PX, PY, PZ = Position.X, Position.Y, Position.Z
                local HX, HY, HZ = Size.X * 0.5, Size.Y * 0.5, Size.Z * 0.5
                if PX - HX < MinX then MinX = PX - HX end
                if PY - HY < MinY then MinY = PY - HY end
                if PZ - HZ < MinZ then MinZ = PZ - HZ end
                if PX + HX > MaxX then MaxX = PX + HX end
                if PY + HY > MaxY then MaxY = PY + HY end
                if PZ + HZ > MaxZ then MaxZ = PZ + HZ end
                Found = true
            end
            if Found or not Whitelist then break end
            Whitelist = nil
        end
        if not Found then return nil, nil end

        local MinV = Vector3New(MinX, MinY, MinZ)
        local MaxV = Vector3New(MaxX, MaxY, MaxZ)
        local NewAnchor = Holder.RootPart
        if NewAnchor then
            local AnchorPosition = NewAnchor.Position
            Holder.BoundsAnchor    = NewAnchor
            Holder.BoundsMinOffset = MinV - AnchorPosition
            Holder.BoundsMaxOffset = MaxV - AnchorPosition
            Holder.BoundsStamp     = Now
        else
            Holder.BoundsAnchor    = nil
            Holder.BoundsMinOffset = nil
        end
        return CFrameNew((MinV + MaxV) * 0.5), MaxV - MinV
    end

    local CollectBaseParts = function(Container)
        local Parts = {}
        local Children = Container:GetChildren()
        for Index = 1, #Children do
            local Child = Children[Index]
            if Child:IsA("BasePart") then Parts[#Parts + 1] = Child end
        end
        return Parts
    end

    local RemoveFromParts = function(Holder, Child)
        local Parts = Holder.Parts
        if not Parts then return end
        for Index = 1, #Parts do
            if Parts[Index] == Child then
                Parts[Index] = Parts[#Parts]
                Parts[#Parts] = nil
                Holder.BoundsStamp = 0
                break
            end
        end
    end

    local GetPlayerName = function(Player)
        if Type(Player) == "table" then
            return Player.Name or "Entity"
        end
        if EspLibrary.Config.NameMode ~= "Username" and Player.ClassName == "Player" then
            return Player.DisplayName or Player.Name
        end
        return Player.Name
    end

    local SetLinePair = function(Outline, Line, FromV, ToV)
        Outline.From, Outline.To = FromV, ToV
        Line.From, Line.To = FromV, ToV
    end

    local RenderCharacterBox = function(Drawings, BoxPos2D, BoxSize2D, BoxSettings, DefaultMode)
        local CornersLines    = Drawings.Corners.Lines
        local CornersOutlines = Drawings.Corners.Outlines
        local FullLines       = Drawings.FullBox.Lines
        local FullOutlines    = Drawings.FullBox.Outlines
        local Enabled, Mode
        if Type(BoxSettings) == "table" then
            Enabled = not not BoxSettings.Enabled
            Mode    = BoxSettings.Mode and StringLower(BoxSettings.Mode) or DefaultMode
        else
            Enabled = not not BoxSettings
            Mode    = DefaultMode
        end

        local State = Enabled and Mode or "hidden"
        if State ~= Drawings.BoxState then
            Drawings.BoxState = State
            local CornerVisible = State == "corner"
            local FullVisible   = State == "full"
            for Index = 1, 8 do
                CornersLines[Index].Visible    = CornerVisible
                CornersOutlines[Index].Visible = CornerVisible
            end
            for Index = 1, 4 do
                FullLines[Index].Visible    = FullVisible
                FullOutlines[Index].Visible = FullVisible
            end
        end
        if State == "hidden" then return end

        local Cfg = EspLibrary.Config
        local OutlineTransparency = Cfg.BoxOutlineTransparency
        local OutlineThickness    = Cfg.BoxOutlineThickness
        if Drawings.OutlineT ~= OutlineTransparency or Drawings.OutlineTh ~= OutlineThickness then
            Drawings.OutlineT  = OutlineTransparency
            Drawings.OutlineTh = OutlineThickness
            for Index = 1, 8 do
                CornersOutlines[Index].Transparency = OutlineTransparency
                CornersOutlines[Index].Thickness    = OutlineThickness
            end
            for Index = 1, 4 do
                FullOutlines[Index].Transparency = OutlineTransparency
                FullOutlines[Index].Thickness    = OutlineThickness
            end
        end

        local Left   = BoxPos2D.X
        local Top    = BoxPos2D.Y
        local Right  = Left + BoxSize2D.X
        local Bottom = Top + BoxSize2D.Y
        if Cfg.PixelSnap then
            Left   = MathFloor(Left + 0.5)
            Top    = MathFloor(Top + 0.5)
            Right  = MathFloor(Right + 0.5)
            Bottom = MathFloor(Bottom + 0.5)
        end
        if Mode == "full" then
            local TopLeft     = Vector2New(Left, Top)
            local TopRight    = Vector2New(Right, Top)
            local BottomRight = Vector2New(Right, Bottom)
            local BottomLeft  = Vector2New(Left, Bottom)
            SetLinePair(FullOutlines[1], FullLines[1], TopLeft, TopRight)
            SetLinePair(FullOutlines[2], FullLines[2], TopRight, BottomRight)
            SetLinePair(FullOutlines[3], FullLines[3], BottomRight, BottomLeft)
            SetLinePair(FullOutlines[4], FullLines[4], BottomLeft, TopLeft)
            return
        end
        local HLen = MathFloor(BoxSize2D.X * Cfg.BoxCornerWidthScale)
        local VLen = MathFloor(BoxSize2D.Y * Cfg.BoxCornerHeightScale)
        SetLinePair(CornersOutlines[1], CornersLines[1], Vector2New(Left, Top),            Vector2New(Left + HLen, Top))
        SetLinePair(CornersOutlines[2], CornersLines[2], Vector2New(Left, Top),            Vector2New(Left, Top + VLen))
        SetLinePair(CornersOutlines[3], CornersLines[3], Vector2New(Right - HLen, Top),    Vector2New(Right, Top))
        SetLinePair(CornersOutlines[4], CornersLines[4], Vector2New(Right, Top),           Vector2New(Right, Top + VLen))
        SetLinePair(CornersOutlines[5], CornersLines[5], Vector2New(Left, Bottom),         Vector2New(Left + HLen, Bottom))
        SetLinePair(CornersOutlines[6], CornersLines[6], Vector2New(Left, Bottom - VLen),  Vector2New(Left, Bottom))
        SetLinePair(CornersOutlines[7], CornersLines[7], Vector2New(Right - HLen, Bottom), Vector2New(Right, Bottom))
        SetLinePair(CornersOutlines[8], CornersLines[8], Vector2New(Right, Bottom - VLen), Vector2New(Right, Bottom))
    end

    local RenderFlagList = function(EspInstance, Drawings, Center2D, Offset, FlagsSettings)
        local FlagTexts = Drawings.FlagTexts
        local Shown = Drawings.FlagsShown or 0
        local Items
        if FlagsSettings and FlagsSettings.Enabled and Type(FlagsSettings.Builder) == "function" then
            local Ok, Result = pcall(FlagsSettings.Builder, EspInstance)
            if Ok and Type(Result) == "table" then Items = Result end
        end
        if not Items then
            for Index = 1, Shown do FlagTexts[Index].Visible = false end
            Drawings.FlagsShown = 0
            return
        end
        TableClear(VisibleItemsBuffer)
        local Always = (FlagsSettings.Mode and StringLower(FlagsSettings.Mode) or "normal") == "always"
        for Index = 1, #Items do
            local Item = Items[Index]
            if Item and (Always or Item.State) then
                VisibleItemsBuffer[#VisibleItemsBuffer + 1] = Item
            end
        end
        local Count = #VisibleItemsBuffer
        if Count > #FlagTexts then Count = #FlagTexts end
        for Index = Count + 1, Shown do
            FlagTexts[Index].Visible = false
        end
        Drawings.FlagsShown = Count
        if Count == 0 then return end
        local Cfg        = EspLibrary.Config
        local FlagSize   = Cfg.FlagSize
        local FlagFont   = Cfg.Font
        local LineHeight = FlagSize + Cfg.FlagLinePadding
        local PixelSnap  = Cfg.PixelSnap
        local LastTexts  = Drawings.FlagLastTexts
        if Drawings.FlagFont ~= FlagFont or Drawings.FlagSize ~= FlagSize then
            Drawings.FlagFont = FlagFont
            Drawings.FlagSize = FlagSize
            for Index = 1, #FlagTexts do
                FlagTexts[Index].Font = FlagFont
                FlagTexts[Index].Size = FlagSize
            end
        end
        local BaseX = Center2D.X + Offset.X + Cfg.FlagXPadding
        local BaseY = Center2D.Y - Offset.Y
        if PixelSnap then BaseX = MathFloor(BaseX + 0.5) end
        for Index = 1, Count do
            local Item    = VisibleItemsBuffer[Index]
            local TextObj = FlagTexts[Index]
            local PosY = BaseY + (Index - 1) * LineHeight
            if PixelSnap then PosY = MathFloor(PosY + 0.5) end
            local NewText = tostring(Item.Text or "")
            if LastTexts[Index] ~= NewText then
                LastTexts[Index] = NewText
                TextObj.Text = NewText
            end
            TextObj.Position = Vector2New(BaseX, PosY)
            if Always then
                TextObj.Color = Item.State and (Item.ColorTrue or ColorGreen) or (Item.ColorFalse or ColorRed)
            else
                TextObj.Color = Item.ColorTrue or ColorGreen
            end
            if Index > Shown then TextObj.Visible = true end
        end
    end

    local RenderHealthbarPair = function(HealthBar, HealthBackground, Center2D, Offset, Pct)
        local BasePos = Center2D - Offset - Vector2New(5, 0)
        local BaseSize = Vector2New(3, Offset.Y * 2)
        local HealthLen = (BaseSize.Y - 2) * Pct
        HealthBar.Visible = true
        HealthBackground.Visible = true
        HealthBackground.Position = BasePos
        HealthBackground.Size = BaseSize
        HealthBar.Position = BasePos + Vector2New(1, 1 + (BaseSize.Y - 2 - HealthLen))
        HealthBar.Size = Vector2New(1, HealthLen)
    end

    local PlayerEsp = {
        PlayerCache = {},
        DrawingCache = {},
        ChildAddedConnections = {},
        ChildRemovedConnections = {},
        DrawingAddedConnections = {},
    }
    PlayerEsp.__index = PlayerEsp

    PlayerEsp.OnChildAdded   = MakeCallbackRegistry(PlayerEsp.ChildAddedConnections)
    PlayerEsp.OnChildRemoved = MakeCallbackRegistry(PlayerEsp.ChildRemovedConnections)
    PlayerEsp.OnDrawingAdded = MakeCallbackRegistry(PlayerEsp.DrawingAddedConnections)

    function PlayerEsp:CreateDrawingCache()
        local AllDrawings = {}
        local Cfg = EspLibrary.Config
        local OutlineThickness    = Cfg.BoxOutlineThickness
        local OutlineTransparency = Cfg.BoxOutlineTransparency
        local Corners = { Lines = {}, Outlines = {} }
        for Index = 1, 8 do
            Corners.Outlines[Index] = CreateDrawing("Line", { Visible = false, Thickness = OutlineThickness, Transparency = OutlineTransparency, Color = ColorBlack, ZIndex = BaseZIndex }, AllDrawings)
            Corners.Lines[Index] = CreateDrawing("Line", { Visible = false, Thickness = 1, Color = ColorWhite, ZIndex = BaseZIndex + 1 }, AllDrawings)
        end
        local FullBox = { Lines = {}, Outlines = {} }
        for Index = 1, 4 do
            FullBox.Outlines[Index] = CreateDrawing("Line", { Visible = false, Thickness = OutlineThickness, Transparency = OutlineTransparency, Color = ColorBlack, ZIndex = BaseZIndex }, AllDrawings)
            FullBox.Lines[Index] = CreateDrawing("Line", { Visible = false, Thickness = 1, Color = ColorWhite, ZIndex = BaseZIndex + 1 }, AllDrawings)
        end
        local FlagTexts = {}
        for Index = 1, 6 do
            FlagTexts[Index] = CreateDrawing("Text", {
                Visible = false,
                Center = false,
                Outline = true,
                OutlineColor = ColorBlack,
                Color = ColorWhite,
                Transparency = 1,
                Size = Cfg.FlagSize,
                Text = "",
                Font = Cfg.Font,
                ZIndex = BaseZIndex + 1,
            }, AllDrawings)
        end
        local Drawings = {
            Corners = Corners,
            FullBox = FullBox,
            Name = CreateDrawing("Text", {
                Visible = false,
                Center = true,
                Outline = true,
                OutlineColor = ColorBlack,
                Color = ColorWhite,
                Transparency = 1,
                Size = Cfg.TextSize,
                Text = self and self.Player and GetPlayerName(self.Player) or "",
                Font = Cfg.Font,
                ZIndex = BaseZIndex + 1,
            }, AllDrawings),
            Weapon = CreateDrawing("Text", {
                Visible = false,
                Center = true,
                Outline = true,
                OutlineColor = ColorBlack,
                Color = ColorWhite,
                Transparency = 1,
                Size = Cfg.TextSize,
                Font = Cfg.Font,
                ZIndex = BaseZIndex + 1,
            }, AllDrawings),
            Distance = CreateDrawing("Text", {
                Visible = false,
                Center = true,
                Outline = true,
                OutlineColor = ColorBlack,
                Color = ColorWhite,
                Transparency = 1,
                Size = Cfg.TextSize,
                Font = Cfg.Font,
                ZIndex = BaseZIndex + 1,
            }, AllDrawings),
            HealthBar = CreateDrawing("Square", {
                Visible = false,
                Thickness = 1,
                Filled = true,
                ZIndex = BaseZIndex + 1,
            }, AllDrawings),
            HealthBackground = CreateDrawing("Square", {
                Visible = false,
                Color = ColorBlack,
                Transparency = 0.55,
                Thickness = 1,
                Filled = true,
                ZIndex = BaseZIndex,
            }, AllDrawings),
            HealthText = CreateDrawing("Text", {
                Visible = false,
                Center = false,
                Outline = true,
                OutlineColor = ColorBlack,
                Color = ColorWhite,
                Transparency = 1,
                Size = Cfg.FlagSize,
                Text = "",
                Font = Cfg.Font,
                ZIndex = BaseZIndex + 1,
            }, AllDrawings),
            HeadDotOutline = CreateDrawing("Circle", {
                Visible = false,
                Filled = false,
                NumSides = 30,
                Thickness = OutlineThickness,
                Transparency = OutlineTransparency,
                Color = ColorBlack,
                ZIndex = BaseZIndex,
            }, AllDrawings),
            HeadDot = CreateDrawing("Circle", {
                Visible = false,
                Filled = false,
                NumSides = 30,
                Thickness = 1,
                Color = ColorWhite,
                ZIndex = BaseZIndex + 1,
            }, AllDrawings),
            FlagTexts = FlagTexts,
        }
        Drawings.All = AllDrawings
        Drawings.BoxState      = "hidden"
        Drawings.FlagsShown    = 0
        Drawings.OutlineT      = OutlineTransparency
        Drawings.OutlineTh     = OutlineThickness
        Drawings.HeadOutlineT  = OutlineTransparency
        Drawings.FlagLastTexts = {}
        Drawings.FlagFont      = Cfg.Font
        Drawings.FlagSize      = Cfg.FlagSize
        Drawings.NameText      = Drawings.Name.Text
        self.Drawings = Drawings
        self.AllDrawings = AllDrawings
    end

    PlayerEsp.New = function(Player)
        local Self = setmetatable({
            Player = Player,
            Connections = {},
            CharacterConnections = {},
            Hidden = false,
            AllDrawings = nil,
            Drawings = nil,
            Current = nil,
        }, PlayerEsp)
        local Cache = PlayerEsp.DrawingCache[1]
        if Cache then
            TableRemove(PlayerEsp.DrawingCache, 1)
            local Name = GetPlayerName(Player)
            Cache.Name.Text = Name
            Cache.NameText  = Name
            Self.AllDrawings = Cache.All
            Self.Drawings = Cache
        else
            Self:CreateDrawingCache()
        end
        Self.CachedName     = Self.Drawings.NameText
        Self.CachedNameMode = EspLibrary.Config.NameMode
        local Conns = PlayerEsp.DrawingAddedConnections
        for Index = 1, #Conns do
            Conns[Index](Self)
        end
        if Type(Player) == "userdata" then
            local IsPlayerInstance = false
            pcall(function() IsPlayerInstance = Player:IsA("Player") end)
            if IsPlayerInstance then
                Self.Connections[#Self.Connections + 1] = Player.CharacterAdded:Connect(function(...) return Self:CharacterAdded(...) end)
                Self.Connections[#Self.Connections + 1] = Player.CharacterRemoving:Connect(function(...) return Self:CharacterRemoved(...) end)
                if Player.Character then
                    Self:CharacterAdded(Player.Character, true)
                end
            else
                Self:CharacterAdded(Player, true)
                Self.Connections[#Self.Connections + 1] = Player.AncestryChanged:Connect(function(_, Parent)
                    if not Parent then Self:CharacterRemoved() end
                end)
            end
        elseif Type(Player) == "table" then
            if Player.CharacterAdded then
                Self.Connections[#Self.Connections + 1] = Player.CharacterAdded:Connect(function(...) return Self:CharacterAdded(...) end)
            end
            if Player.CharacterRemoving then
                Self.Connections[#Self.Connections + 1] = Player.CharacterRemoving:Connect(function(...) return Self:CharacterRemoved(...) end)
            end
            local Character = Player.Character or Player.model or Player.Model
            if Character then
                Self:CharacterAdded(Character, true)
            end
        end
        PlayerEsp.PlayerCache[Player] = Self
        return Self
    end

    PlayerEsp.Remove = function(Player)
        local Cache = PlayerEsp.PlayerCache[Player]
        if Type(Cache) ~= "table" then return end
        PlayerEsp.PlayerCache[Player] = nil
        DisconnectAll(Cache.Connections)
        DisconnectAll(Cache.CharacterConnections)
        if Cache.Drawings then
            HideDrawingSet(Cache.AllDrawings, Cache.Drawings)
            PlayerEsp.DrawingCache[#PlayerEsp.DrawingCache + 1] = Cache.Drawings
        end
    end

    function PlayerEsp:HideDrawings()
        if self.Hidden then return end
        self.Hidden = true
        HideDrawingSet(self.AllDrawings, self.Drawings)
    end

    function PlayerEsp:SetColor(Color)
        self.Color = Color
        local Drawings = self.Drawings
        if not Drawings then return end
        Drawings.Name.Color = Color
        Drawings.Distance.Color = Color
        Drawings.Weapon.Color = Color
        local CornerLines = Drawings.Corners.Lines
        for Index = 1, 8 do CornerLines[Index].Color = Color end
        local FullLines = Drawings.FullBox.Lines
        for Index = 1, 4 do FullLines[Index].Color = Color end
    end

    function PlayerEsp:SetName(Name)
        Name = tostring(Name or "")
        self.CachedName = Name
        self.CachedNameMode = EspLibrary.Config.NameMode
    end

    function PlayerEsp:HumanoidHealthChanged()
        local Humanoid = self.Current and self.Current.Humanoid
        if not Humanoid then return end
        local Health = Humanoid.Health
        local MaxHealth = Humanoid.MaxHealth
        local Pct = (MaxHealth > 0 and (Health / MaxHealth)) or 0
        self.Current.Health = Health
        self.Current.MaxHealth = MaxHealth
        self.Current.HealthPercentage = Pct
        self.Drawings.HealthBar.Color = ColorRed:Lerp(ColorGreen, Pct)
    end

    function PlayerEsp:SetupHumanoid(Humanoid, FirstTime)
        self:HumanoidHealthChanged()
        local CharConns = self.CharacterConnections
        CharConns[#CharConns + 1] = Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            self:HumanoidHealthChanged()
        end)
        if FirstTime then
            local Conns = self.ChildAddedConnections
            local Children = self.Current.Character:GetChildren()
            for Index = 1, #Children do
                for ConnIndex = 1, #Conns do
                    Conns[ConnIndex](self, Children[Index])
                end
            end
        end
    end

    function PlayerEsp:ChildAdded(Child)
        local Current = self.Current
        if not Current then return end
        if Child.ClassName == "Humanoid" then
            Current.Humanoid = Child
            self:SetupHumanoid(Child)
        elseif Child:IsA("BasePart") then
            local Parts = Current.Parts
            Parts[#Parts + 1] = Child
            Current.BoundsStamp = 0
            if not Current.RootPart and Child.Name == "HumanoidRootPart" then
                Current.RootPart = Child
            end
            if not Current.Head and Child.Name == "Head" then
                Current.Head = Child
            end
        end
        local Conns = self.ChildAddedConnections
        for Index = 1, #Conns do
            Conns[Index](self, Child)
        end
    end

    function PlayerEsp:ChildRemoved(Child)
        local Current = self.Current
        if not Current then return end
        if Child == Current.Humanoid then
            Current.Humanoid = nil
        elseif Child == Current.RootPart then
            Current.RootPart = nil
        elseif Child == Current.Head then
            Current.Head = nil
        end
        RemoveFromParts(Current, Child)
        local Conns = self.ChildRemovedConnections
        for Index = 1, #Conns do
            Conns[Index](self, Child)
        end
    end

    function PlayerEsp:PrimaryPartAdded()
        local Character = self.Current and self.Current.Character
        if not Character then return end
        local PrimaryPart = Character.PrimaryPart
        if PrimaryPart then
            self.Current.RootPart = PrimaryPart
        end
    end

    function PlayerEsp:CharacterAdded(Character, FirstTime)
        DisconnectAll(self.CharacterConnections)
        self.Current = {
            Character = Character,
            Humanoid = Character:FindFirstChildOfClass("Humanoid"),
            RootPart = Character:FindFirstChild("HumanoidRootPart") or Character.PrimaryPart,
            Head = Character:FindFirstChild("Head"),
            Parts = CollectBaseParts(Character),
            BoundsStamp = 0,
            Health = 0,
            MaxHealth = 0,
            HealthPercentage = 0,
            Weapon = nil,
            Visible = false,
        }
        local CharConns = self.CharacterConnections
        CharConns[#CharConns + 1] = Character:GetPropertyChangedSignal("PrimaryPart"):Connect(function() self:PrimaryPartAdded() end)
        CharConns[#CharConns + 1] = Character.ChildAdded:Connect(function(...) return self:ChildAdded(...) end)
        CharConns[#CharConns + 1] = Character.ChildRemoved:Connect(function(...) return self:ChildRemoved(...) end)
        if self.Current.Humanoid then
            self:SetupHumanoid(self.Current.Humanoid, FirstTime)
        end
    end

    function PlayerEsp:CharacterRemoved()
        DisconnectAll(self.CharacterConnections)
        self.Current = nil
        self.Hidden = true
        HideDrawingSet(self.AllDrawings, self.Drawings)
    end

    function PlayerEsp:RenderBox(BoxPos2D, BoxSize2D, BoxSettings)
        RenderCharacterBox(self.Drawings, BoxPos2D, BoxSize2D, BoxSettings, "corner")
    end

    function PlayerEsp:RenderName(Center2D, Offset, NameSettings)
        local Drawings = self.Drawings
        local NameText = Drawings.Name
        local Enabled
        if Type(NameSettings) == "table" then
            Enabled = not not NameSettings.Enabled
        else
            Enabled = not not NameSettings
        end
        if not Enabled then
            NameText.Visible = false
            return
        end
        local Cfg = EspLibrary.Config
        local NewName = self.CachedName
        if self.CachedNameMode ~= Cfg.NameMode then
            NewName = GetPlayerName(self.Player)
            self.CachedName     = NewName
            self.CachedNameMode = Cfg.NameMode
        end
        if Drawings.NameText ~= NewName then
            Drawings.NameText = NewName
            NameText.Text = NewName
        end
        NameText.Position = Center2D - Vector2New(0, Offset.Y + Cfg.TextSize)
        NameText.Visible  = true
    end

    function PlayerEsp:RenderWeapon(Center2D, Offset, Enabled, BottomYOffset)
        local WeaponText = self.Drawings.Weapon
        if not Enabled then
            WeaponText.Visible = false
            return 0
        end
        local Drawings = self.Drawings
        local Weapon = self.Current and self.Current.Weapon
        if Drawings.WeaponRef ~= Weapon then
            Drawings.WeaponRef = Weapon
            WeaponText.Text = Weapon and StringLower(Weapon.Name) or "none"
        end
        WeaponText.Position = Center2D + Vector2New(0, Offset.Y + BottomYOffset)
        WeaponText.Visible = true
        return EspLibrary.Config.TextSize + 1
    end

    function PlayerEsp:RenderDistance(Center2D, Offset, Enabled, BottomYOffset, Distance)
        local DistanceText = self.Drawings.Distance
        if not Enabled or not Distance then
            DistanceText.Visible = false
            return 0
        end
        local Cfg = EspLibrary.Config
        local Drawings = self.Drawings
        local Magnitude = MathRound(Distance)
        local PosX = Center2D.X
        local PosY = Center2D.Y + Offset.Y + BottomYOffset
        if Cfg.PixelSnap then
            PosX = MathFloor(PosX + 0.5)
            PosY = MathFloor(PosY + 0.5)
        end
        if Drawings.DistanceValue ~= Magnitude then
            Drawings.DistanceValue = Magnitude
            DistanceText.Text = `[{Magnitude}]`
        end
        DistanceText.Position = Vector2New(PosX, PosY)
        DistanceText.Visible = true
        return Cfg.TextSize + 1
    end

    function PlayerEsp:RenderHealthbar(Center2D, Offset, Enabled)
        if not Enabled or not (self.Current and self.Current.Humanoid) then
            self.Drawings.HealthBar.Visible = false
            self.Drawings.HealthBackground.Visible = false
            return
        end
        RenderHealthbarPair(self.Drawings.HealthBar, self.Drawings.HealthBackground,
            Center2D, Offset, self.Current.HealthPercentage or 0)
    end

    function PlayerEsp:RenderFlags(Center2D, Offset, FlagsSettings)
        RenderFlagList(self, self.Drawings, Center2D, Offset, FlagsSettings)
    end

    function PlayerEsp:RenderHeadDot(Offset, HeadDotSettings)
        local Drawings = self.Drawings
        local HeadDot = Drawings.HeadDot
        local Outline = Drawings.HeadDotOutline
        local Enabled, DotColor
        if Type(HeadDotSettings) == "table" then
            Enabled  = not not HeadDotSettings.Enabled
            DotColor = HeadDotSettings.Color
        else
            Enabled = not not HeadDotSettings
        end
        local Head = Enabled and self.Current and self.Current.Head
        if not Head then
            HeadDot.Visible = false
            Outline.Visible = false
            return
        end
        local ScreenPos, OnScreen = WorldToViewportPoint(CurrentCamera, Head.Position)
        if not OnScreen then
            HeadDot.Visible = false
            Outline.Visible = false
            return
        end
        local Cfg = EspLibrary.Config
        local OutlineTransparency = Cfg.BoxOutlineTransparency
        if Drawings.HeadOutlineT ~= OutlineTransparency then
            Drawings.HeadOutlineT = OutlineTransparency
            Outline.Transparency = OutlineTransparency
        end
        local Position = Vector2New(ScreenPos.X, ScreenPos.Y)
        local Radius = MathMax(2, Offset.X * 0.22)
        Outline.Position = Position
        Outline.Radius = Radius
        Outline.Visible = true
        HeadDot.Position = Position
        HeadDot.Radius = Radius
        HeadDot.Color = DotColor or self.Color or ColorWhite
        HeadDot.Visible = true
    end

    function PlayerEsp:RenderHealthText(Center2D, Offset, Enabled)
        local Drawings = self.Drawings
        local HealthText = Drawings.HealthText
        local Current = self.Current
        if not Enabled or not (Current and Current.Humanoid) then
            HealthText.Visible = false
            return
        end
        local Cfg = EspLibrary.Config
        local Health = MathFloor((Current.Health or 0) + 0.5)
        if Drawings.HealthValue ~= Health then
            Drawings.HealthValue = Health
            HealthText.Text = `{Health}`
            Drawings.HealthTextWidth = HealthText.TextBounds.X
        end
        local BarTopLeft = Center2D - Offset - Vector2New(5, 0)
        local BarHeight = Offset.Y * 2
        local FlagSize = Cfg.FlagSize
        local TextY = 1 + (BarHeight - 2) * (1 - (Current.HealthPercentage or 0)) - FlagSize * 0.5
        if TextY < 0 then TextY = 0 end
        local MaxY = BarHeight - FlagSize
        if TextY > MaxY then TextY = MaxY end
        local PosX = BarTopLeft.X - (Drawings.HealthTextWidth or 0) - 3
        local PosY = BarTopLeft.Y + TextY
        if Cfg.PixelSnap then
            PosX = MathFloor(PosX + 0.5)
            PosY = MathFloor(PosY + 0.5)
        end
        HealthText.Position = Vector2New(PosX, PosY)
        HealthText.Visible = true
    end

    function PlayerEsp:Loop(Settings, DistanceOverride, PositionOverride)
        if not EspLibrary.Enabled then return self:HideDrawings() end
        local Current = self.Current
        if not Current and not PositionOverride then return self:HideDrawings() end
        local Character = Current and Current.Character
        if not Character and not PositionOverride then return self:HideDrawings() end
        local CF, Size3D
        if PositionOverride then
            CF = typeof(PositionOverride) == "CFrame" and PositionOverride or CFrameNew(PositionOverride)
            Size3D = Vector3New(4, 5, 2)
        else
            CF, Size3D = GetCachedBounds(Current, Character)
        end
        if not Size3D then return self:HideDrawings() end
        local GoalPos = CF.Position
        local ScreenPos, OnScreen = WorldToViewportPoint(CurrentCamera, GoalPos)
        if not OnScreen then return self:HideDrawings() end
        self.Hidden = false
        local Center2D = Vector2New(ScreenPos.X, ScreenPos.Y)
        local CameraCF = CurrentCamera.CFrame
        local BoxCF = CFrameNew(GoalPos, GoalPos + CameraCF.LookVector)
        local HX, HY = -Size3D.X * 0.5, Size3D.Y * 0.5
        local TopRight3D    = BoxCF:PointToWorldSpace(Vector3New(HX, HY, 0))
        local BottomRight3D = BoxCF:PointToWorldSpace(Vector3New(HX, -HY, 0))
        local TopRight2D    = WorldToViewportPoint(CurrentCamera, TopRight3D)
        local BottomRight2D = WorldToViewportPoint(CurrentCamera, BottomRight3D)
        local Offset = Vector2New(
            MathMax(MathAbs(TopRight2D.X - Center2D.X), MathAbs(BottomRight2D.X - Center2D.X)),
            MathMax(MathAbs(Center2D.Y - TopRight2D.Y), MathAbs(BottomRight2D.Y - Center2D.Y))
        )
        RenderCharacterBox(self.Drawings, Center2D - Offset, Offset * 2, Settings.Box, "corner")
        self:RenderName(Center2D, Offset, Settings.Name)
        self:RenderHealthbar(Center2D, Offset, Settings.Healthbar)
        self:RenderHealthText(Center2D, Offset, Settings.HealthText)
        self:RenderHeadDot(Offset, Settings.HeadDot)
        local BottomY = self:RenderWeapon(Center2D, Offset, Settings.Weapon, 0)
        BottomY = BottomY + self:RenderDistance(Center2D, Offset, Settings.Distance, BottomY,
            DistanceOverride or (CameraCF.Position - GoalPos).Magnitude)
        self:RenderFlags(Center2D, Offset, Settings.Flags)
    end

    EspLibrary.PlayerEsp = PlayerEsp
    EspLibrary.PlayerESP = PlayerEsp

    function EspLibrary:Unload()
        for _, EspInstance in next, PlayerEsp.PlayerCache do
            PlayerEsp.Remove(EspInstance.Player)
        end

        DisconnectAll(LibraryConnections)

        for Index = 1, #PlayerEsp.DrawingCache do
            for _, DrawingObject in next, PlayerEsp.DrawingCache[Index].All do
                DrawingObject:Remove()
            end
        end

        TableClear(PlayerEsp.DrawingCache)
    end
end

return EspLibrary, 3
