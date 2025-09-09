--!nonstrict

local ProtectGui = protectgui or (syn and syn.protect_gui) or function() end
local GUIParent = gethui and gethui() or game:GetService("CoreGui")

local Request = http_request or (syn and syn.request) or request
isfile, writefile, getcustomasset, identifyexecutor, setclipboard, readfile, makefolder, toclipboard, isfolder, toHSV =
	isfile, writefile, function() end, identifyexecutor, setclipboard, readfile, makefolder, toclipboard, isfolder, Color3.toHSV

local WindUI
local NormalCreator,NormalDialog, NormalUI, NormalElement

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

if RunService:IsStudio() then
	GUIParent = LocalPlayer:WaitForChild("PlayerGui")
	writefile = function() return true end
	isfile = writefile
	isfolder = writefile
	makefolder = writefile

	readfile = function()
		return ""
	end

	identifyexecutor = function()
		return "RobloxStudio", Version()
	end
end

NormalCreator = (function(...)
	local RenderStepped = RunService.Heartbeat

	local Icons
	if RunService:IsStudio() then
		local ExternalIcons = script:FindFirstChild("Icons") :: ModuleScript
		if ExternalIcons and ExternalIcons:IsA("ModuleScript") then
			Icons = require(ExternalIcons)
		else
			return error("[WindUI]: Failed to find Icons Lib")
		end
	else
		local IconsFunction, LoadError = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Footagesus/Icons/main/Main.lua"))
		if type(IconsFunction) == "function" then
			Icons = IconsFunction()
		else
			LocalPlayer:Kick("[WindUI]: Failed to load icons (Check Console for more info).")
			return warn(LoadError)
		end
	end

	Icons.SetIconsType("lucide")

	local Creator = {
		Font = "rbxassetid://12187365364", -- Inter
		CanDraggable = true,
		Theme = nil,
		Themes = nil,
		WindUI = nil,
		Signals = {},
		Objects = {},
		FontObjects = {},
		ValidExtensions = {".png", ".jpg", ".webp"},
		Request = Request,
		DefaultProperties = {
			ScreenGui = {
				ResetOnSpawn = false,
				ZIndexBehavior = "Sibling",
			},
			CanvasGroup = {
				BorderSizePixel = 0,
				BackgroundColor3 = Color3.new(1,1,1),
			},
			Frame = {
				BorderSizePixel = 0,
				BackgroundColor3 = Color3.new(1,1,1),
			},
			TextLabel = {
				BackgroundColor3 = Color3.new(1,1,1),
				BorderSizePixel = 0,
				Text = "",
				RichText = true,
				TextColor3 = Color3.new(1,1,1),
				TextSize = 14,
			}, TextButton = {
				BackgroundColor3 = Color3.new(1,1,1),
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor= false,
				TextColor3 = Color3.new(1,1,1),
				TextSize = 14,
			},
			TextBox = {
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderColor3 = Color3.new(0, 0, 0),
				ClearTextOnFocus = false,
				Text = "",
				TextColor3 = Color3.new(0, 0, 0),
				TextSize = 14,
			},
			ImageLabel = {
				BackgroundTransparency = 1,
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
			},
			ImageButton = {
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				AutoButtonColor = false,
			},
			UIListLayout = {
				SortOrder = "LayoutOrder",
			}
		},
		Colors = {
			Red = "#e53935",    -- Danger
			Orange = "#f57c00", -- Warning
			Green = "#43a047",  -- Success
			Blue = "#039be5",   -- Info
			White = "#ffffff",   -- White
			Grey = "#484848",   -- Grey
		}
	}

	function Creator.Init(WindUI)
		Creator.WindUI = WindUI
	end

	function Creator.AddSignal(Signal, Function)
		table.insert(Creator.Signals, Signal:Connect(Function))
	end

	function Creator.DisconnectAll()
		for idx, signal in next, Creator.Signals do
			local Connection = table.remove(Creator.Signals, idx)
			Connection:Disconnect()
		end
	end

	-- ↓ Debug mode
	function Creator.SafeCallback(Function, ...)
		if not Function then
			return
		end

		local Success, Event = pcall(Function, ...)
		if not Success then
			local _, i = Event:find(":%d+: ")


			warn("[ WindUI: DEBUG Mode ] " .. Event)

			return Creator.WindUI:Notify({
				Title = "DEBUG Mode: Error",
				Content = not i and Event or Event:sub(i + 1),
				Duration = 8,
			})
		end
	end

	function Creator.SetTheme(Theme)
		Creator.Theme = Theme
		Creator.UpdateTheme(nil, true)
	end

	function Creator.AddFontObject(Object)
		table.insert(Creator.FontObjects, Object)
		Creator.UpdateFont(Creator.Font)
	end

	function Creator.UpdateFont(FontId)
		Creator.Font = FontId
		for _,Obj in next, Creator.FontObjects do
			Obj.FontFace = Font.new(FontId, Obj.FontFace.Weight, Obj.FontFace.Style)
		end
	end

	function Creator.GetThemeProperty(Property, Theme)
		return Theme[Property] or Creator.Themes["Dark"][Property]
	end

	function Creator.AddThemeObject(Object, Properties)
		Creator.Objects[Object] = { Object = Object, Properties = Properties }
		Creator.UpdateTheme(Object, false)
		return Object
	end

	function Creator.UpdateTheme(TargetObject, isTween)
		local function ApplyTheme(objData)
			for Property, ColorKey in pairs(objData.Properties or {}) do
				local Color = Creator.GetThemeProperty(ColorKey, Creator.Theme)
				if Color then
					if not isTween then
						objData.Object[Property] = Color3.fromHex(Color)
					else
						Creator.Tween(objData.Object, 0.08, { [Property] = Color3.fromHex(Color) }):Play()
					end
				end
			end
		end

		if TargetObject then
			local objData = Creator.Objects[TargetObject]
			if objData then
				ApplyTheme(objData)
			end
		else
			for _, objData in pairs(Creator.Objects) do
				ApplyTheme(objData)
			end
		end
	end

	function Creator.Icon(Icon)
		return Icons.Icon(Icon)
	end

	function Creator.New(Name, Properties, Children)
		local Object = Instance.new(Name)

		for Name, Value in next, Creator.DefaultProperties[Name] or {} do
			Object[Name] = Value
		end

		for Name, Value in next, Properties or {} do
			if Name ~= "ThemeTag" then
				Object[Name] = Value
			end
		end

		for _, Child in next, Children or {} do
			Child.Parent = Object
		end

		if Properties and Properties.ThemeTag then
			Creator.AddThemeObject(Object, Properties.ThemeTag)
		end
		if Properties and Properties.FontFace then
			Creator.AddFontObject(Object)
		end
		return Object
	end

	function Creator.Tween(Object, Time, Properties, ...)
		return TweenService:Create(Object, TweenInfo.new(Time, ...), Properties)
	end

	function Creator.NewRoundFrame(Radius, Type, Properties, Children, isButton)
		-- local ThemeTags = {}
		-- if Properties.ThemeTag then
		--     for k, v in next, Properties.ThemeTag do
		--         ThemeTags[k] = v
		--     end
		-- end
		local Image = Creator.New(isButton and "ImageButton" or "ImageLabel", {
			Image = Type == "Squircle" and "rbxassetid://85805932203780"
				or Type == "SquircleOutline" and "rbxassetid://79757452150325" 
				or Type == "Shadow-sm" and "rbxassetid://139662887329118"
				or Type == "Squircle-TL-TR" and "rbxassetid://73569156276236",
			ScaleType = "Slice",
			SliceCenter = Type ~= "Shadow-sm" and Rect.new(
				512/2,
				512/2,
				512/2,
				512/2
			) or Rect.new(512,512,512,512),
			SliceScale = 1,
			BackgroundTransparency = 1,
			ThemeTag = Properties.ThemeTag
		}, Children)

		for k, v in pairs(Properties or {}) do
			if k ~= "ThemeTag" then
				Image[k] = v
			end
		end

		local function UpdateSliceScale(newRadius)
			local sliceScale = Type ~= "Shadow-sm" and (newRadius / (512/2)) or (newRadius/512)
			Image.SliceScale = sliceScale
		end

		UpdateSliceScale(Radius)

		return Image
	end

	local New = Creator.New
	local Tween = Creator.Tween

	function Creator.SetDraggable(can)
		Creator.CanDraggable = can
	end

	function Creator.Drag(mainFrame, dragFrames, ondrag)
		local currentDragFrame = nil
		local dragging, dragInput, dragStart, startPos
		local DragModule = {
			CanDraggable = true
		}

		if not dragFrames or type(dragFrames) ~= "table" then
			dragFrames = {mainFrame}
		end

		local function update(input)
			local delta = input.Position - dragStart
			Creator.Tween(mainFrame, 0.02, {Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
				)}):Play()
		end

		for _, dragFrame in pairs(dragFrames) do
			dragFrame.InputBegan:Connect(function(input)
				if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and DragModule.CanDraggable then
					if currentDragFrame == nil then
						currentDragFrame = dragFrame
						dragging = true
						dragStart = input.Position
						startPos = mainFrame.Position

						if ondrag and type(ondrag) == "function" then 
							ondrag(true, currentDragFrame)
						end

						input.Changed:Connect(function()
							if input.UserInputState == Enum.UserInputState.End then
								dragging = false
								currentDragFrame = nil

								if ondrag and type(ondrag) == "function" then 
									ondrag(false, currentDragFrame)
								end
							end
						end)
					end
				end
			end)

			dragFrame.InputChanged:Connect(function(input)
				if currentDragFrame == dragFrame and dragging then
					if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
						dragInput = input
					end
				end
			end)
		end

		UserInputService.InputChanged:Connect(function(input)
			if input == dragInput and dragging and currentDragFrame ~= nil then
				if DragModule.CanDraggable then 
					update(input)
				end
			end
		end)

		function DragModule:Set(v)
			DragModule.CanDraggable = v
		end

		return DragModule
	end

	function Creator.GetImageExtension(ImageContent)
		if type(ImageContent) ~= "string" then return end
		local WaterMark = ImageContent:sub(0, 4)

		if WaterMark == "\137\80\78\71" then
			return "png"
		elseif WaterMark == "\255\216\255\224" then
			return "jpg"
		elseif WaterMark == "\82\73\70\70" then
			return "webp"
		else
			return
		end
	end

	function Creator.Image(CustomSize, Img, Name, Corner, Type, IsThemeTag, Themed)		
		local function SanitizeFilename(str)
			str = str:gsub("[%s/\\:*?\"<>|]+", "-")
			str = str:gsub("[^%w%-_%.]", "")
			return str
		end

		Name = SanitizeFilename(Name)

		local ImageFrame = New("Frame", {
			Size = UDim2.new(0,0,0,0), -- czjzjznsmMdj
			--AutomaticSize = "XY",
			BackgroundTransparency = 1,
		}, {
			New("ImageLabel", {
				Position = UDim2.new(0.5, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = CustomSize or UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				ScaleType = "Crop",
				ThemeTag = (Creator.Icon(Img) or Themed) and {
					ImageColor3 = IsThemeTag and "Icon" 
				} or nil,
			}, {
				New("UICorner", {
					CornerRadius = UDim.new(0,Corner)
				})
			})
		})
		if Creator.Icon(Img) then
			ImageFrame.ImageLabel.Image = Creator.Icon(Img)[1]
			ImageFrame.ImageLabel.ImageRectOffset = Creator.Icon(Img)[2].ImageRectPosition
			ImageFrame.ImageLabel.ImageRectSize = Creator.Icon(Img)[2].ImageRectSize
		end
		if string.find(Img,"http") then
			local Hash = 0

			local Indx = 1
			Img:gsub(".", function(Letter)
				Hash += Letter:byte() * Indx
				Indx += 1
			end)

			local FileName = "WindUI/.Assets/" .. tostring(Hash)
			local success, response = pcall(function()
				for _, Extension in ipairs(Creator.ValidExtensions) do
					local FinalPath = FileName .. Extension
					if isfile(FinalPath) then
						ImageFrame.ImageLabel.Image = getcustomasset(FinalPath)
						return
					end
				end

				local response = Creator.Request({
					Url = Img,
					Method = "GET",
				}).Body

				local AssetExtension = Creator.GetImageExtension(response)
				if not AssetExtension then
					return warn("[ WindUI.Creator ] File type not supported (Unknow type). Body: " .. response:sub(0, 4))
				end

				local FinalPath = FileName .. "." .. AssetExtension

				writefile(FinalPath, response)
				ImageFrame.ImageLabel.Image = getcustomasset(FinalPath)
			end)
			if not success then
				warn("[ WindUI.Creator ]  '" .. identifyexecutor() .. "' doesnt support the URL Images. Error: " .. response)

				--ImageFrame:Destroy()
			end
		elseif string.find(Img,"rbxasset", 1, true) then
			ImageFrame.ImageLabel.Image = Img
		end

		return ImageFrame
	end

	return Creator
end)()

NormalDialog = (function(...)
	local Creator = NormalCreator
	local New = Creator.New
	local Tween = Creator.Tween

	local DialogModule = {
		UICorner = 14,
		UIPadding = 12,
		Holder = nil,
		Window = nil,
	}

	function DialogModule.Init(Window)
		DialogModule.Window = Window
		return DialogModule
	end

	function DialogModule.Create(Key)
		local Dialog = {
			UICorner = 19,
			UIPadding = 16,
			UIElements = {}
		}

		if Key then Dialog.UIPadding = 0 end -- 16
		if Key then Dialog.UICorner  = 22 end

		if not Key then
			Dialog.UIElements.FullScreen = New("Frame", {
				ZIndex = 999,
				BackgroundTransparency = 1, -- 0.5
				BackgroundColor3 = Color3.fromHex("#2a2a2a"),
				Size = UDim2.new(1,0,1,0),
				Active = false, -- true
				Visible = false, -- true
				Parent = Key and DialogModule.Window or DialogModule.Window.UIElements.Main.Main
			}, {
				New("UICorner", {
					CornerRadius = UDim.new(0,DialogModule.Window.UICorner)
				})
			})
		end

		Dialog.UIElements.Main = New("Frame", {
			--Size = UDim2.new(1,0,1,0),
			ThemeTag = {
				BackgroundColor3 = "Accent", -- Error aca
			},
			AutomaticSize = "XY",
			BackgroundTransparency = 1, -- .7
			Visible = false,
			ZIndex = 99999,
		}, {
			New("UIPadding", {
				PaddingTop = UDim.new(0, Dialog.UIPadding),
				PaddingLeft = UDim.new(0, Dialog.UIPadding),
				PaddingRight = UDim.new(0, Dialog.UIPadding),
				PaddingBottom = UDim.new(0, Dialog.UIPadding),
			})
		})

		Dialog.UIElements.MainContainer = Creator.NewRoundFrame(Dialog.UICorner, "Squircle", {
			Visible = false, -- true
			--GroupTransparency = 1, -- 0
			ImageTransparency = Key and 0.15 or 0, 
			Parent = Key and DialogModule.Window or Dialog.UIElements.FullScreen,
			Position = UDim2.new(0.5,0,0.5,0),
			AnchorPoint = Vector2.new(0.5,0.5),
			AutomaticSize = "XY",
			ThemeTag = {
				ImageColor3 = "Accent"
			},
			ZIndex = 9999,
		}, {
			Dialog.UIElements.Main,
			New("UIScale", {
				Scale = .9
			}),
			Creator.NewRoundFrame(Dialog.UICorner, "SquircleOutline", {
				Size = UDim2.new(1,0,1,0),
				ImageTransparency = 1,
				ThemeTag = {
					ImageColor3 = "Outline",
				},
			}, {
				New("UIGradient", {
					Rotation = 90,
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0),
						NumberSequenceKeypoint.new(1, 1),
					})
				})
			})
		})

		function Dialog:Open()
			if not Key then
				Dialog.UIElements.FullScreen.Visible = true
				Dialog.UIElements.FullScreen.Active = true
			end

			task.spawn(function()
				Dialog.UIElements.MainContainer.Visible = true

				if not Key then
					Tween(Dialog.UIElements.FullScreen, 0.1, {BackgroundTransparency = .5}):Play()
				end
				Tween(Dialog.UIElements.MainContainer, 0.1, {ImageTransparency = 0}):Play()
				Tween(Dialog.UIElements.MainContainer.UIScale, 0.1, {Scale = 1}):Play()
				--Tween(Dialog.UIElements.MainContainer.UIStroke, 0.1, {Transparency = 1}):Play()
				task.spawn(function()
					task.wait(0.05)
					Dialog.UIElements.Main.Visible = true
				end)
			end)
		end
		function Dialog:Close()
			if not Key then
				Tween(Dialog.UIElements.FullScreen, 0.1, {BackgroundTransparency = 1}):Play()
				Dialog.UIElements.FullScreen.Active = false
				task.spawn(function()
					task.wait(.1)
					Dialog.UIElements.FullScreen.Visible = false
				end)
			end
			Dialog.UIElements.Main.Visible = false

			Tween(Dialog.UIElements.MainContainer, 0.1, {ImageTransparency = 1}):Play()
			Tween(Dialog.UIElements.MainContainer.UIScale, 0.1, {Scale = .9}):Play()
			--Tween(Dialog.UIElements.MainContainer.UIStroke, 0.1, {Transparency = 1}):Play()

			task.spawn(function()
				task.wait(.1)
				if not Key then
					Dialog.UIElements.FullScreen:Destroy()
				else
					Dialog.UIElements.MainContainer:Destroy()
				end
			end)

			return function() end
		end

		--Dialog:Open()
		return Dialog
	end

	return DialogModule
end)()

NormalUI = (function(...)
	-- Credits: https://devforum.roblox.com/t/realtime-richtext-lua-syntax-highlighting/2500399
	-- Modified by me (Footagesus)

	local Highlighter = {}
	local keywords = {
		lua = {
			"and", "break", "or", "else", "elseif", "if", "then", "until", "repeat", "while", "do", "for", "in", "end",
			"local", "return", "function", "export",
		},
		rbx = {
			"game", "workspace", "script", "math", "string", "table", "task", "wait", "select", "next", "Enum",
			"tick", "assert", "shared", "loadstring", "tonumber", "tostring", "type",
			"typeof", "unpack", "Instance", "CFrame", "Vector3", "Vector2", "Color3", "UDim", "UDim2", "Ray", "BrickColor",
			"OverlapParams", "RaycastParams", "Axes", "Random", "Region3", "Rect", "TweenInfo",
			"collectgarbage", "not", "utf8", "pcall", "xpcall", "_G", "setmetatable", "getmetatable", "os", "pairs", "ipairs"
		},
		operators = {
			"#", "+", "-", "*", "%", "/", "^", "=", "~", "=", "<", ">",
		}
	}

	local colors = {
		numbers = Color3.fromHex("#FAB387"),
		boolean = Color3.fromHex("#FAB387"),
		operator = Color3.fromHex("#94E2D5"),
		lua = Color3.fromHex("#CBA6F7"),
		rbx = Color3.fromHex("#F38BA8"), -- def
		str = Color3.fromHex("#A6E3A1"),
		comment = Color3.fromHex("#9399B2"),
		null = Color3.fromHex("#F38BA8"), -- nil
		call = Color3.fromHex("#89B4FA"),    
		self_call = Color3.fromHex("#89B4FA"),
		local_property = Color3.fromHex("#CBA6F7"),
	}

	local function createKeywordSet(keywords)
		local keywordSet = {}
		for _, keyword in ipairs(keywords) do
			keywordSet[keyword] = true
		end
		return keywordSet
	end

	local luaSet = createKeywordSet(keywords.lua)
	local rbxSet = createKeywordSet(keywords.rbx)
	local operatorsSet = createKeywordSet(keywords.operators)

	local function getHighlight(tokens, index)
		local token = tokens[index]

		if colors[token .. "_color"] then
			return colors[token .. "_color"]
		end

		if tonumber(token) then
			return colors.numbers
		elseif token == "nil" then
			return colors.null
		elseif token:sub(1, 2) == "--" then
			return colors.comment
		elseif operatorsSet[token] then
			return colors.operator
		elseif luaSet[token] then
			return colors.lua
		elseif rbxSet[token] then
			return colors.rbx
		elseif token:sub(1, 1) == "\"" or token:sub(1, 1) == "\'" then
			return colors.str
		elseif token == "true" or token == "false" then
			return colors.boolean
		end

		if tokens[index + 1] == "(" then
			if tokens[index - 1] == ":" then
				return colors.self_call
			end

			return colors.call
		end

		if tokens[index - 1] == "." then
			if tokens[index - 2] == "Enum" then
				return colors.rbx
			end

			return colors.local_property
		end
	end

	function Highlighter.run(source)
		local tokens = {}
		local currentToken = ""

		local inString = false
		local inComment = false
		local commentPersist = false

		for i = 1, #source do
			local character = source:sub(i, i)

			if inComment then
				if character == "\n" and not commentPersist then
					table.insert(tokens, currentToken)
					table.insert(tokens, character)
					currentToken = ""

					inComment = false
				elseif source:sub(i - 1, i) == "]]" and commentPersist then
					currentToken ..= "]"

					table.insert(tokens, currentToken)
					currentToken = ""

					inComment = false
					commentPersist = false
				else
					currentToken = currentToken .. character
				end
			elseif inString then
				if character == inString and source:sub(i-1, i-1) ~= "\\" or character == "\n" then
					currentToken = currentToken .. character
					inString = false
				else
					currentToken = currentToken .. character
				end
			else
				if source:sub(i, i + 1) == "--" then
					table.insert(tokens, currentToken)
					currentToken = "-"
					inComment = true
					commentPersist = source:sub(i + 2, i + 3) == "[["
				elseif character == "\"" or character == "\'" then
					table.insert(tokens, currentToken)
					currentToken = character
					inString = character
				elseif operatorsSet[character] then
					table.insert(tokens, currentToken)
					table.insert(tokens, character)
					currentToken = ""
				elseif character:match("[%w_]") then
					currentToken = currentToken .. character
				else
					table.insert(tokens, currentToken)
					table.insert(tokens, character)
					currentToken = ""
				end
			end
		end

		table.insert(tokens, currentToken)

		local highlighted = {}

		for i, token in ipairs(tokens) do
			local highlight = getHighlight(tokens, i)

			if highlight then
				local syntax = string.format("<font color = \"#%s\">%s</font>", highlight:ToHex(), token:gsub("<", "&lt;"):gsub(">", "&gt;"))

				table.insert(highlighted, syntax)
			else
				table.insert(highlighted, token)
			end
		end

		return table.concat(highlighted)
	end

	local UIComponents = {}

	local Creator = NormalCreator
	local New = Creator.New
	local Tween = Creator.Tween

	function UIComponents.Button(Title, Icon, Callback, Variant, Parent, Dialog)
		Variant = Variant or "Primary"
		local Radius = 10
		local IconButtonFrame
		if Icon and Icon ~= "" then
			IconButtonFrame = New("ImageLabel", {
				Image = Creator.Icon(Icon)[1],
				ImageRectSize = Creator.Icon(Icon)[2].ImageRectSize,
				ImageRectOffset = Creator.Icon(Icon)[2].ImageRectPosition,
				Size = UDim2.new(0,24-3,0,24-3),
				BackgroundTransparency = 1,
				ThemeTag = {
					ImageColor3 = "Icon",
				}
			})
		end

		local ButtonFrame = New("TextButton", {
			Size = UDim2.new(0,0,1,0),
			AutomaticSize = "X",
			Parent = Parent,
			BackgroundTransparency = 1
		}, {
			Creator.NewRoundFrame(Radius, "Squircle", {
				ThemeTag = {
					ImageColor3 = Variant ~= "White" and "Button" or nil,
				},
				ImageColor3 = Variant == "White" and Color3.new(1,1,1) or nil,
				Size = UDim2.new(1,0,1,0),
				Name = "Squircle",
				ImageTransparency = Variant == "Primary" and 0 or Variant == "White" and 0 or 1
			}),

			Creator.NewRoundFrame(Radius, "Squircle", {
				-- ThemeTag = {
				--     ImageColor3 = "Layer",
				-- },
				ImageColor3 = Color3.new(1,1,1),
				Size = UDim2.new(1,0,1,0),
				Name = "Special",
				ImageTransparency = Variant == "Secondary" and 0.95 or 1
			}),

			Creator.NewRoundFrame(Radius, "Shadow-sm", {
				-- ThemeTag = {
				--     ImageColor3 = "Layer",
				-- },
				ImageColor3 = Color3.new(0,0,0),
				Size = UDim2.new(1,3,1,3),
				AnchorPoint = Vector2.new(0.5,0.5),
				Position = UDim2.new(0.5,0,0.5,0),
				Name = "Shadow",
				ImageTransparency = Variant == "Secondary" and 0 or 1
			}),

			Creator.NewRoundFrame(Radius, "SquircleOutline", {
				ThemeTag = {
					ImageColor3 = Variant ~= "White" and "Outline" or nil,
				},
				Size = UDim2.new(1,0,1,0),
				ImageColor3 = Variant == "White" and Color3.new(0,0,0) or nil,
				ImageTransparency = Variant == "Primary" and .95 or .85,
			}),

			Creator.NewRoundFrame(Radius, "Squircle", {
				Size = UDim2.new(1,0,1,0),
				Name = "Frame",
				ThemeTag = {
					ImageColor3 = Variant ~= "White" and "Text" or nil
				},
				ImageColor3 = Variant == "White" and Color3.new(0,0,0) or nil,
				ImageTransparency = 1 -- .95
			}, {
				New("UIPadding", {
					PaddingLeft = UDim.new(0,12),
					PaddingRight = UDim.new(0,12),
				}),
				New("UIListLayout", {
					FillDirection = "Horizontal",
					Padding = UDim.new(0,8),
					VerticalAlignment = "Center",
					HorizontalAlignment = "Center",
				}),
				IconButtonFrame,
				New("TextLabel", {
					BackgroundTransparency = 1,
					FontFace = Font.new(Creator.Font, Enum.FontWeight.SemiBold),
					Text = Title or "Button",
					ThemeTag = {
						TextColor3 = (Variant ~= "Primary" and Variant ~= "White") and "Text",
					},
					TextColor3 = Variant == "Primary" and Color3.new(1,1,1) or Variant == "White" and Color3.new(0,0,0) or nil,
					AutomaticSize = "XY",
					TextSize = 18,
				})
			})
		})

		Creator.AddSignal(ButtonFrame.MouseEnter, function()
			Tween(ButtonFrame.Frame, .047, {ImageTransparency = .95}):Play()
		end)
		Creator.AddSignal(ButtonFrame.MouseLeave, function()
			Tween(ButtonFrame.Frame, .047, {ImageTransparency = 1}):Play()
		end)
		Creator.AddSignal(ButtonFrame.MouseButton1Up, function()
			if Dialog then
				Dialog:Close()()
			end
			if Callback then
				Creator.SafeCallback(Callback)
			end
		end)

		return ButtonFrame
	end

	function UIComponents.Input(Placeholder, Icon, Parent, Type, Callback)
		Type = Type or "Input"
		local Radius = 10
		local IconInputFrame
		if Icon and Icon ~= "" then
			IconInputFrame = New("ImageLabel", {
				Image = Creator.Icon(Icon)[1],
				ImageRectSize = Creator.Icon(Icon)[2].ImageRectSize,
				ImageRectOffset = Creator.Icon(Icon)[2].ImageRectPosition,
				Size = UDim2.new(0,24-3,0,24-3),
				BackgroundTransparency = 1,
				ThemeTag = {
					ImageColor3 = "Icon",
				}
			})
		end

		local TextBox = New("TextBox", {
			BackgroundTransparency = 1,
			TextSize = 16,
			FontFace = Font.new(Creator.Font, Enum.FontWeight.Regular),
			Size = UDim2.new(1,IconInputFrame and -29 or 0,1,0),
			PlaceholderText = Placeholder,
			ClearTextOnFocus = false,
			ClipsDescendants = true,
			MultiLine = (Type == "Input" and false) or true,
			TextWrapped = (Type == "Input" and false) or true,
			TextXAlignment = "Left",
			TextYAlignment = Type == "Input" and "Center" or "Top",
			--AutomaticSize = "XY",
			ThemeTag = {
				PlaceholderColor3 = "PlaceholderText",
				TextColor3 = "Text",
			},
		})

		local InputFrame = New("Frame", {
			Size = UDim2.new(1,0,0,42),
			Parent = Parent,
			BackgroundTransparency = 1
		}, {
			New("Frame", {
				Size = UDim2.new(1,0,1,0),
				BackgroundTransparency = 1,
			}, {
				Creator.NewRoundFrame(Radius, "Squircle", {
					ThemeTag = {
						ImageColor3 = "Accent",
					},
					Size = UDim2.new(1,0,1,0),
					ImageTransparency = .45,
				}),
				Creator.NewRoundFrame(Radius, "SquircleOutline", {
					ThemeTag = {
						ImageColor3 = "Outline",
					},
					Size = UDim2.new(1,0,1,0),
					ImageTransparency = .9,
				}),
				Creator.NewRoundFrame(Radius, "Squircle", {
					Size = UDim2.new(1,0,1,0),
					Name = "Frame",
					ImageColor3 = Color3.new(1,1,1),
					ImageTransparency = .95
				}, {
					New("UIPadding", {
						PaddingTop = UDim.new(0,Type == "Input" and 0 or 12),
						PaddingLeft = UDim.new(0,12),
						PaddingRight = UDim.new(0,12),
						PaddingBottom = UDim.new(0,Type == "Input" and 0 or 12),
					}),
					New("UIListLayout", {
						FillDirection = "Horizontal",
						Padding = UDim.new(0,8),
						VerticalAlignment = Type == "Input" and "Center" or "Top",
						HorizontalAlignment = "Left",
					}),
					IconInputFrame,
					TextBox,
				})
			})
		})

		-- InputFrame:GetPropertyChangedSignal("AbsoluteSize"), function()
		--     TextBox.Size = UDim2.new(
		--         0,
		--         IconInputFrame and InputFrame.AbsoluteSize.X -29-12 or InputFrame.AbsoluteSize.X-12,
		--         1,
		--         0
		--     )
		-- end)

		Creator.AddSignal(TextBox.FocusLost, function()
			if Callback then
				Creator.SafeCallback(Callback, TextBox.Text)
			end
		end)

		return InputFrame
	end

	function UIComponents.Label(Text, Icon, Parent)
		local Radius = 10
		local IconLabelFrame
		if Icon and Icon ~= "" then
			IconLabelFrame = New("ImageLabel", {
				Image = Creator.Icon(Icon)[1],
				ImageRectSize = Creator.Icon(Icon)[2].ImageRectSize,
				ImageRectOffset = Creator.Icon(Icon)[2].ImageRectPosition,
				Size = UDim2.new(0,24-3,0,24-3),
				BackgroundTransparency = 1,
				ThemeTag = {
					ImageColor3 = "Icon",
				}
			})
		end

		local TextLabel = New("TextLabel", {
			BackgroundTransparency = 1,
			TextSize = 16,
			FontFace = Font.new(Creator.Font, Enum.FontWeight.Regular),
			Size = UDim2.new(1,IconLabelFrame and -29 or 0,1,0),
			TextXAlignment = "Left",
			ThemeTag = {
				TextColor3 = "Text",
			},
			Text = Text,
		})

		local LabelFrame = New("TextButton", {
			Size = UDim2.new(1,0,0,42),
			Parent = Parent,
			BackgroundTransparency = 1,
			Text = "",
		}, {
			New("Frame", {
				Size = UDim2.new(1,0,1,0),
				BackgroundTransparency = 1,
			}, {
				Creator.NewRoundFrame(Radius, "Squircle", {
					ThemeTag = {
						ImageColor3 = "Accent",
					},
					Size = UDim2.new(1,0,1,0),
					ImageTransparency = .45,
				}),
				Creator.NewRoundFrame(Radius, "SquircleOutline", {
					ThemeTag = {
						ImageColor3 = "Outline",
					},
					Size = UDim2.new(1,0,1,0),
					ImageTransparency = .9,
				}),
				Creator.NewRoundFrame(Radius, "Squircle", {
					Size = UDim2.new(1,0,1,0),
					Name = "Frame",
					ImageColor3 = Color3.new(1,1,1),
					ImageTransparency = .95
				}, {
					New("UIPadding", {
						PaddingLeft = UDim.new(0,12),
						PaddingRight = UDim.new(0,12),
					}),
					New("UIListLayout", {
						FillDirection = "Horizontal",
						Padding = UDim.new(0,8),
						VerticalAlignment = "Center",
						HorizontalAlignment = "Left",
					}),
					IconLabelFrame,
					TextLabel,
				})
			})
		})

		return LabelFrame
	end

	function UIComponents.Toggle(Value, Icon, Parent, Callback)
		local Toggle = {}


		local Radius = 26/2
		local IconToggleFrame
		if Icon and Icon ~= "" then
			IconToggleFrame = New("ImageLabel", {
				Size = UDim2.new(1,-7,1,-7),
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5,0.5),
				Position = UDim2.new(0.5,0,0.5,0),
				Image = Creator.Icon(Icon)[1],
				ImageRectOffset = Creator.Icon(Icon)[2].ImageRectPosition,
				ImageRectSize = Creator.Icon(Icon)[2].ImageRectSize,
				ImageTransparency = 1,
				ImageColor3 = Color3.new(0,0,0),
			})
		end

		local ToggleFrame = Creator.NewRoundFrame(Radius, "Squircle",{
			ImageTransparency = .95,
			ThemeTag = {
				ImageColor3 = "Text"
			},
			Parent = Parent,
			Size = UDim2.new(0,20*2.1,0,26),
		}, {
			Creator.NewRoundFrame(Radius, "Squircle", {
				Size = UDim2.new(1,0,1,0),
				Name = "Layer",
				ThemeTag = {
					ImageColor3 = "Button",
				},
				ImageTransparency = 1, -- 0
			}),
			Creator.NewRoundFrame(Radius, "SquircleOutline", {
				Size = UDim2.new(1,0,1,0),
				Name = "Stroke",
				ImageColor3 = Color3.new(1,1,1),
				ImageTransparency = 1, -- .95
			}, {
				New("UIGradient", {
					Rotation = 90,
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0),
						NumberSequenceKeypoint.new(1, 1),
					})
				})
			}),

			--bar
			Creator.NewRoundFrame(Radius, "Squircle", {
				Size = UDim2.new(0,18,0,18),
				Position = UDim2.new(0,3,0.5,0),
				AnchorPoint = Vector2.new(0,0.5),
				ImageTransparency = 0,
				ImageColor3 =  Color3.new(1,1,1),
				Name = "Frame",
			}, {
				IconToggleFrame,
			})
		})

		function Toggle:Set(Toggled)
			if Toggled then
				Tween(ToggleFrame.Frame, 0.1, {
					Position = UDim2.new(1, -18 - 4, 0.5, 0),
					--Size = UDim2.new(0,20,0,20),
				}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
				Tween(ToggleFrame.Layer, 0.1, {
					ImageTransparency = 0,
				}):Play()
				Tween(ToggleFrame.Stroke, 0.1, {
					ImageTransparency = 0.95,
				}):Play()

				if IconToggleFrame then 
					Tween(IconToggleFrame, 0.1, {
						ImageTransparency = 0,
					}):Play()
				end
			else
				Tween(ToggleFrame.Frame, 0.1, {
					Position = UDim2.new(0, 4, 0.5, 0),
					Size = UDim2.new(0,18,0,18),
				}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
				Tween(ToggleFrame.Layer, 0.1, {
					ImageTransparency = 1,
				}):Play()
				Tween(ToggleFrame.Stroke, 0.1, {
					ImageTransparency = 1,
				}):Play()

				if IconToggleFrame then 
					Tween(IconToggleFrame, 0.1, {
						ImageTransparency = 1,
					}):Play()
				end
			end

			if Callback then
				task.spawn(Creator.SafeCallback, Callback, Toggled)
			end

			--Toggled = not Toggled
		end

		return ToggleFrame, Toggle
	end

	function UIComponents.Checkbox(Value, Icon, Parent, Callback)
		local Checkbox = {}

		Icon = Icon or "check"

		local Radius = 10
		local IconCheckboxFrame = New("ImageLabel", {
			Size = UDim2.new(1,-10,1,-10),
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5,0.5),
			Position = UDim2.new(0.5,0,0.5,0),
			Image = Creator.Icon(Icon)[1],
			ImageRectOffset = Creator.Icon(Icon)[2].ImageRectPosition,
			ImageRectSize = Creator.Icon(Icon)[2].ImageRectSize,
			ImageTransparency = 1,
			ImageColor3 = Color3.new(1,1,1),
		})

		local CheckboxFrame = Creator.NewRoundFrame(Radius, "Squircle",{
			ImageTransparency = .95, -- 0
			ThemeTag = {
				ImageColor3 = "Text"
			},
			Parent = Parent,
			Size = UDim2.new(0,27,0,27),
		}, {
			Creator.NewRoundFrame(Radius, "Squircle", {
				Size = UDim2.new(1,0,1,0),
				Name = "Layer",
				ThemeTag = {
					ImageColor3 = "Button",
				},
				ImageTransparency = 1, -- 0
			}),
			Creator.NewRoundFrame(Radius, "SquircleOutline", {
				Size = UDim2.new(1,0,1,0),
				Name = "Stroke",
				ImageColor3 = Color3.new(1,1,1),
				ImageTransparency = 1, -- .95
			}, {
				New("UIGradient", {
					Rotation = 90,
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0),
						NumberSequenceKeypoint.new(1, 1),
					})
				})
			}),

			IconCheckboxFrame,
		})

		function Checkbox:Set(Toggled)
			if Toggled then
				Tween(CheckboxFrame.Layer, 0.06, {
					ImageTransparency = 0,
				}):Play()
				Tween(CheckboxFrame.Stroke, 0.06, {
					ImageTransparency = 0.95,
				}):Play()
				Tween(IconCheckboxFrame, 0.06, {
					ImageTransparency = 0,
				}):Play()
			else
				Tween(CheckboxFrame.Layer, 0.05, {
					ImageTransparency = 1,
				}):Play()
				Tween(CheckboxFrame.Stroke, 0.05, {
					ImageTransparency = 1,
				}):Play()
				Tween(IconCheckboxFrame, 0.06, {
					ImageTransparency = 1,
				}):Play()
			end

			if Callback then
				task.spawn(Creator.SafeCallback, Callback, Toggled)
			end
		end

		return CheckboxFrame, Checkbox
	end

	function UIComponents.ScrollSlider(ScrollingFrame, Parent, Window, Thickness)

		local Slider = New("Frame", {
			Size = UDim2.new(0, Thickness, 1,0),
			BackgroundTransparency = 1,
			Position = UDim2.new(1, 0, 0, 0),
			AnchorPoint = Vector2.new(1, 0),
			Parent = Parent,
			ZIndex = 999,
			Active = true,
		})

		local Thumb = Creator.NewRoundFrame(Thickness/2, "Squircle", {
			Size = UDim2.new(1, 0, 0, 0),
			ImageTransparency = 0.85,
			ThemeTag = { ImageColor3 = "Text" },
			Parent = Slider,
		})

		local Hitbox = New("Frame", {
			Size = UDim2.new(1, 12, 1, 12),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Active = true,
			ZIndex = 999,
			Parent = Thumb,
		})

		local isDragging = false
		local dragOffset = 0

		local function updateSliderSize()
			local container = ScrollingFrame
			local canvasSize = container.AbsoluteCanvasSize.Y
			local windowSize = container.AbsoluteWindowSize.Y

			if canvasSize <= windowSize then
				Thumb.Visible = false
				return
			end

			local visibleRatio = math.clamp(windowSize / canvasSize, 0.1, 1)
			Thumb.Size = UDim2.new(1, 0, visibleRatio, 0)
			Thumb.Visible = true
		end

		local function updateScrollingFramePosition()        
			local thumbPositionY = Thumb.Position.Y.Scale
			local canvasSize = ScrollingFrame.AbsoluteCanvasSize.Y
			local windowSize = ScrollingFrame.AbsoluteWindowSize.Y
			local maxScroll = math.max(canvasSize - windowSize, 0)

			if maxScroll <= 0 then return end

			local maxThumbPos = math.max(1 - Thumb.Size.Y.Scale, 0)
			if maxThumbPos <= 0 then return end

			local scrollRatio = thumbPositionY / maxThumbPos

			ScrollingFrame.CanvasPosition = Vector2.new(
				ScrollingFrame.CanvasPosition.X,
				scrollRatio * maxScroll
			)
		end

		local function updateThumbPosition()
			if isDragging then return end 

			local canvasPosition = ScrollingFrame.CanvasPosition.Y
			local canvasSize = ScrollingFrame.AbsoluteCanvasSize.Y
			local windowSize = ScrollingFrame.AbsoluteWindowSize.Y
			local maxScroll = math.max(canvasSize - windowSize, 0)

			if maxScroll <= 0 then
				Thumb.Position = UDim2.new(0, 0, 0, 0)
				return
			end

			local scrollRatio = canvasPosition / maxScroll
			local maxThumbPos = math.max(1 - Thumb.Size.Y.Scale, 0)
			local newThumbPosition = math.clamp(scrollRatio * maxThumbPos, 0, maxThumbPos)

			Thumb.Position = UDim2.new(0, 0, newThumbPosition, 0)
		end

		Creator.AddSignal(Slider.InputBegan, function(input)
			if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
				local thumbTop = Thumb.AbsolutePosition.Y
				local thumbBottom = thumbTop + Thumb.AbsoluteSize.Y

				if not (input.Position.Y >= thumbTop and input.Position.Y <= thumbBottom) then
					local sliderTop = Slider.AbsolutePosition.Y
					local sliderHeight = Slider.AbsoluteSize.Y
					local thumbHeight = Thumb.AbsoluteSize.Y

					local targetY = input.Position.Y - sliderTop - thumbHeight / 2
					local maxThumbPos = sliderHeight - thumbHeight

					local newThumbPosScale = math.clamp(targetY / maxThumbPos, 0, 1 - Thumb.Size.Y.Scale)

					Thumb.Position = UDim2.new(0, 0, newThumbPosScale, 0)
					updateScrollingFramePosition()
				end
			end
		end)

		Creator.AddSignal(Hitbox.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				isDragging = true
				dragOffset = input.Position.Y - Thumb.AbsolutePosition.Y

				local moveConnection
				local releaseConnection

				moveConnection = UserInputService.InputChanged:Connect(function(changedInput)
					if changedInput.UserInputType == Enum.UserInputType.MouseMovement or changedInput.UserInputType == Enum.UserInputType.Touch then
						local sliderTop = Slider.AbsolutePosition.Y
						local sliderHeight = Slider.AbsoluteSize.Y
						local thumbHeight = Thumb.AbsoluteSize.Y

						local newY = changedInput.Position.Y - sliderTop - dragOffset
						local maxThumbPos = sliderHeight - thumbHeight

						local newThumbPosScale = math.clamp(newY / maxThumbPos, 0, 1 - Thumb.Size.Y.Scale)

						Thumb.Position = UDim2.new(0, 0, newThumbPosScale, 0)
						updateScrollingFramePosition()
					end
				end)

				releaseConnection = UserInputService.InputEnded:Connect(function(endInput)
					if endInput.UserInputType == Enum.UserInputType.MouseButton1 or endInput.UserInputType == Enum.UserInputType.Touch then
						isDragging = false
						if moveConnection then moveConnection:Disconnect() end
						if releaseConnection then releaseConnection:Disconnect() end
					end
				end)
			end
		end)

		local UpdateSizeAndPos = function()
			updateSliderSize()
			updateThumbPosition()
		end

		Creator.AddSignal(ScrollingFrame:GetPropertyChangedSignal("AbsoluteWindowSize"), UpdateSizeAndPos)
		Creator.AddSignal(ScrollingFrame:GetPropertyChangedSignal("AbsoluteCanvasSize"), UpdateSizeAndPos)

		Creator.AddSignal(ScrollingFrame:GetPropertyChangedSignal("CanvasPosition"), function()
			if not isDragging then
				updateThumbPosition()
			end
		end)

		updateSliderSize()
		updateThumbPosition()

		return Slider
	end

	function UIComponents.ToolTip(Title, Parent)
		local ToolTipModule = {
			Container = nil,
			ToolTipSize = 16,
		}

		local ToolTipTitle = New("TextLabel", {
			AutomaticSize = "XY",
			TextWrapped = true,
			BackgroundTransparency = 1,
			FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
			Text = Title,
			TextSize = 17,
			ThemeTag = {
				TextColor3 = "Text",
			}
		})

		local UIScale = New("UIScale", {
			Scale = .9 -- 1
		})

		local Container = New("CanvasGroup", {
			AnchorPoint = Vector2.new(0.5,0),
			AutomaticSize = "XY",
			BackgroundTransparency = 1,
			Parent = Parent,
			GroupTransparency = 1, -- 0
			Visible = false -- true
		}, {
			New("UISizeConstraint", {
				MaxSize = Vector2.new(400, math.huge)
			}),
			New("Frame", {
				AutomaticSize = "XY",
				BackgroundTransparency = 1,
				LayoutOrder = 99,
				Visible = false
			}, {
				New("ImageLabel", {
					Size = UDim2.new(0,ToolTipModule.ToolTipSize,0,ToolTipModule.ToolTipSize/2),
					BackgroundTransparency = 1,
					Rotation = 180,
					Image = "rbxassetid://131918670159824",
					ThemeTag = {
						ImageColor3 = "Accent",
					},
				}, {
					New("ImageLabel", {
						Size = UDim2.new(0,ToolTipModule.ToolTipSize,0,ToolTipModule.ToolTipSize/2),
						BackgroundTransparency = 1,
						LayoutOrder = 99,
						ImageTransparency = .9,
						Image = "rbxassetid://131918670159824",
						ThemeTag = {
							ImageColor3 = "Text",
						},
					}),
				}),
			}),
			New("Frame", {
				AutomaticSize = "XY",
				ThemeTag = {
					BackgroundColor3 = "Accent",
				},

			}, {
				New("UICorner", {
					CornerRadius = UDim.new(0,16),
				}),
				New("Frame", {
					ThemeTag = {
						BackgroundColor3 = "Text",
					},
					AutomaticSize = "XY",
					BackgroundTransparency = .9,
				}, {
					New("UICorner", {
						CornerRadius = UDim.new(0,16),
					}),
					New("UIListLayout", {
						Padding = UDim.new(0,12),
						FillDirection = "Horizontal",
						VerticalAlignment = "Center"
					}),
					--ToolTipIcon, 
					ToolTipTitle,
					New("UIPadding", {
						PaddingTop = UDim.new(0,12),
						PaddingLeft = UDim.new(0,12),
						PaddingRight = UDim.new(0,12),
						PaddingBottom = UDim.new(0,12),
					}),
				})
			}),
			UIScale,
			New("UIListLayout", {
				Padding = UDim.new(0,0),
				FillDirection = "Vertical",
				VerticalAlignment = "Center",
				HorizontalAlignment = "Center",
			}),
		})
		ToolTipModule.Container = Container

		function ToolTipModule:Open() 
			Container.Visible = true

			Tween(Container, .16, { GroupTransparency = 0 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
			Tween(UIScale, .18, { Scale = 1 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
		end

		function ToolTipModule:Close() 
			Tween(Container, .2, { GroupTransparency = 1 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
			Tween(UIScale, .2, { Scale = .9 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()

			task.wait(.25)

			Container.Visible = false
			Container:Destroy()
		end

		return ToolTipModule
	end

	function UIComponents.Code(Code, Title, Parent, Callback)
		local CodeModule = {
			Radius = 12,
			Padding = 10
		}

		local TextLabel = New("TextLabel", {
			Text = "",
			TextColor3 = Color3.fromHex("#CDD6F4"),
			TextTransparency = 0,
			TextSize = 14,
			TextWrapped = false,
			LineHeight = 1.15,
			RichText = true,
			TextXAlignment = "Left",
			Size = UDim2.new(0,0,0,0),
			BackgroundTransparency = 1,
			AutomaticSize = "XY",
		}, {
			New("UIPadding", {
				PaddingTop = UDim.new(0,CodeModule.Padding+3),
				PaddingLeft = UDim.new(0,CodeModule.Padding+3),
				PaddingRight = UDim.new(0,CodeModule.Padding+3),
				PaddingBottom = UDim.new(0,CodeModule.Padding+3),
			})
		})
		TextLabel.Font = "Code"

		local ScrollingFrame = New("ScrollingFrame", {
			Size = UDim2.new(1,0,0,0),
			BackgroundTransparency = 1,
			AutomaticCanvasSize = "X",
			ScrollingDirection = "X",
			ElasticBehavior = "Never",
			CanvasSize = UDim2.new(0,0,0,0),
			ScrollBarThickness = 0,
		}, {
			TextLabel
		})

		local CopyButton = New("TextButton", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0,30,0,30),
			Position = UDim2.new(1,-CodeModule.Padding/2,0,CodeModule.Padding/2),
			AnchorPoint = Vector2.new(1,0),
			Visible = Callback and true or false,
		}, {
			Creator.NewRoundFrame(CodeModule.Radius-4, "Squircle", {
				-- ThemeTag = {
				--     ImageColor3 = "Text",
				-- },
				ImageColor3 = Color3.fromHex("#ffffff"),
				ImageTransparency = 1, -- .95
				Size = UDim2.new(1,0,1,0),
				AnchorPoint = Vector2.new(0.5,0.5),
				Position = UDim2.new(0.5,0,0.5,0),
				Name = "Button",
			}, {
				New("UIScale", {
					Scale = 1, -- .9
				}),
				New("ImageLabel", {
					Image = Creator.Icon("copy")[1],
					ImageRectSize = Creator.Icon("copy")[2].ImageRectSize,
					ImageRectOffset = Creator.Icon("copy")[2].ImageRectPosition,
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0.5,0.5),
					Position = UDim2.new(0.5,0,0.5,0),
					Size = UDim2.new(0,12,0,12),
					-- ThemeTag = {
					--     ImageColor3 = "Icon",
					-- }, 
					ImageColor3 = Color3.fromHex("#ffffff"),
					ImageTransparency = .1,
				})
			})
		})

		Creator.AddSignal(CopyButton.MouseEnter, function()
			Tween(CopyButton.Button, .05, {ImageTransparency = .95}):Play()
			Tween(CopyButton.Button.UIScale, .05, {Scale = .9}):Play()
		end)
		Creator.AddSignal(CopyButton.InputEnded, function()
			Tween(CopyButton.Button, .08, {ImageTransparency = 1}):Play()
			Tween(CopyButton.Button.UIScale, .08, {Scale = 1}):Play()
		end)

		local CodeFrame = Creator.NewRoundFrame(CodeModule.Radius, "Squircle", {
			-- ThemeTag = {
			--     ImageColor3 = "Text"
			-- },
			ImageColor3 = Color3.fromHex("#212121"),
			ImageTransparency = .035,
			Size = UDim2.new(1,0,0,20+(CodeModule.Padding*2)),
			AutomaticSize = "Y",
			Parent = Parent,
		}, {
			Creator.NewRoundFrame(CodeModule.Radius, "SquircleOutline", {
				Size = UDim2.new(1,0,1,0),
				-- ThemeTag = {
				--     ImageColor3 = "Text"
				-- },
				ImageColor3 = Color3.fromHex("#ffffff"),
				ImageTransparency = .955,
			}),
			New("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1,0,0,0),
				AutomaticSize = "Y",
			}, {
				Creator.NewRoundFrame(CodeModule.Radius, "Squircle-TL-TR", {
					-- ThemeTag = {
					--     ImageColor3 = "Text"
					-- },
					ImageColor3 = Color3.fromHex("#ffffff"),
					ImageTransparency = .96,
					Size = UDim2.new(1,0,0,20+(CodeModule.Padding*2)),
					Visible = Title and true or false
				}, {
					New("ImageLabel", {
						Size = UDim2.new(0,18,0,18),
						BackgroundTransparency = 1,
						Image = "rbxassetid://102403664289366", -- luau logo
						-- ThemeTag = {
						--     ImageColor3 = "Icon",
						-- },
						ImageColor3 = Color3.fromHex("#ffffff"),
						ImageTransparency = .2,
					}),
					New("TextLabel", {
						Text = Title,
						-- ThemeTag = {
						--     TextColor3 = "Icon",
						-- },
						TextColor3 = Color3.fromHex("#ffffff"),
						TextTransparency = .2,
						TextSize = 16,
						AutomaticSize = "Y",
						FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
						TextXAlignment = "Left",
						BackgroundTransparency = 1,
						TextTruncate = "AtEnd",
						Size = UDim2.new(1,CopyButton and -20-(CodeModule.Padding*2),0,0)
					}),
					New("UIPadding", {
						--PaddingTop = UDim.new(0,CodeModule.Padding),
						PaddingLeft = UDim.new(0,CodeModule.Padding+3),
						PaddingRight = UDim.new(0,CodeModule.Padding+3),
						--PaddingBottom = UDim.new(0,CodeModule.Padding),
					}),
					New("UIListLayout", {
						Padding = UDim.new(0,CodeModule.Padding),
						FillDirection = "Horizontal",
						VerticalAlignment = "Center",
					})
				}),
				ScrollingFrame,
				New("UIListLayout", {
					Padding = UDim.new(0,0),
					FillDirection = "Vertical",
				})
			}),
			CopyButton,
		})

		Creator.AddSignal(TextLabel:GetPropertyChangedSignal("TextBounds"), function()
			ScrollingFrame.Size = UDim2.new(1,0,0,TextLabel.TextBounds.Y + ((CodeModule.Padding+3)*2))
		end)

		function CodeModule.Set(code)
			TextLabel.Text = Highlighter.run(code)
		end

		CodeModule.Set(Code)

		Creator.AddSignal(CopyButton.MouseButton1Click, function()
			if Callback then
				Callback()
				local CheckIcon = Creator.Icon("check")
				CopyButton.Button.ImageLabel.Image = CheckIcon[1]
				CopyButton.Button.ImageLabel.ImageRectSize = CheckIcon[2].ImageRectSize
				CopyButton.Button.ImageLabel.ImageRectOffset = CheckIcon[2].ImageRectPosition
			end
		end)
		return CodeModule
	end

	return UIComponents
end)()

NormalElement = (function()
	local Creator = NormalCreator
	local New = Creator.New
	local NewRoundFrame = Creator.NewRoundFrame
	local Tween = Creator.Tween

	return function(Config)
		local Element = {
			Title = Config.Title,
			Desc = Config.Desc or nil,
			Hover = Config.Hover,
			Thumbnail = Config.Thumbnail,
			ThumbnailSize = Config.ThumbnailSize or 80,
			Image = Config.Image,
			IconThemed = Config.IconThemed or false,
			ImageSize = Config.ImageSize or 30,
			Color = Config.Color,
			Scalable = Config.Scalable,
			Parent = Config.Parent,
			UIPadding = 12,
			UICorner = 13,
			UIElements = {}
		}

		local ImageSize = Element.ImageSize
		local ThumbnailSize = Element.ThumbnailSize
		local CanHover = true
		local Hovering = false

		local IconOffset = 0

		local ThumbnailFrame
		local ImageFrame
		if Element.Thumbnail then
			ThumbnailFrame = Creator.Image(
				false,
				Element.Thumbnail, 
				Element.Title, 
				Element.UICorner-3,
				"Thumbnail",
				false,
				Element.IconThemed
			)
			ThumbnailFrame.Size = UDim2.new(1,0,0,ThumbnailSize)
		end
		if Element.Image then
			ImageFrame = Creator.Image(
				false,
				Element.Image, 
				Element.Title, 
				Element.UICorner-3,
				"Image",
				Element.Color and true or false
			)
			if Element.Color == "White" then
				ImageFrame.ImageLabel.ImageColor3 = Color3.new(0,0,0)
			elseif Element.Color then
				ImageFrame.ImageLabel.ImageColor3 = Color3.new(1,1,1)
			end
			ImageFrame.Size = UDim2.new(0,ImageSize,0,ImageSize)

			IconOffset = ImageSize
		end

		local function CreateText(Title, Type)
			return New("TextLabel", {
				BackgroundTransparency = 1,
				Text = Title or "",
				TextSize = Type == "Desc" and 15 or 16,
				TextXAlignment = "Left",
				ThemeTag = {
					TextColor3 = not Element.Color and (Type == "Desc" and "Icon" or "Text") or nil,
				},
				TextColor3 = Element.Color and (Element.Color == "White" and Color3.new(0,0,0) or Element.Color ~= "White" and Color3.new(1,1,1)) or nil,
				TextTransparency = Element.Color and (Type == "Desc" and .3 or 0),
				TextWrapped = true,
				Size = UDim2.new(1,0,0,0),
				AutomaticSize = "Y",
				FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium)
			})
		end

		local Title = CreateText(Element.Title, "Title")
		local Desc = CreateText(Element.Desc, "Desc")
		if not Element.Desc or Element.Desc == "" then
			Desc.Visible = false
		end

		Element.UIElements.Container = New("Frame", {
			Size = UDim2.new(1,0,0,0),
			AutomaticSize = "Y",
			BackgroundTransparency = 1,
		}, {
			New("UIListLayout", {
				Padding = UDim.new(0,Element.UIPadding),
				FillDirection = "Vertical",
				VerticalAlignment = "Top",
				HorizontalAlignment = "Left",
			}),
			ThumbnailFrame,
			New("Frame", {
				Size = UDim2.new(1,-Config.TextOffset,0,0),
				AutomaticSize = "Y",
				BackgroundTransparency = 1,
			}, {
				New("UIListLayout", {
					Padding = UDim.new(0,Element.UIPadding),
					FillDirection = "Horizontal",
					VerticalAlignment = "Top",
					HorizontalAlignment = "Left",
				}),
				ImageFrame,
				New("Frame", {
					BackgroundTransparency = 1,
					AutomaticSize = "Y",
					Size = UDim2.new(1,-IconOffset,0,(50-(Element.UIPadding*2)))
				}, {
					New("UIListLayout", {
						Padding = UDim.new(0,4),
						FillDirection = "Vertical",
						VerticalAlignment = "Center",
						HorizontalAlignment = "Left",
					}),
					Title,
					Desc
				}),
			})
		})

		Element.UIElements.Locked = NewRoundFrame(Element.UICorner, "Squircle", {
			Size = UDim2.new(1,Element.UIPadding*2,1,Element.UIPadding*2),
			ImageTransparency = .4,
			AnchorPoint = Vector2.new(0.5,0.5),
			Position = UDim2.new(0.5,0,0.5,0),
			ImageColor3 = Color3.new(0,0,0),
			Visible = false,
			Active = false,
			ZIndex = 9999999,
		})

		Element.UIElements.Main = NewRoundFrame(Element.UICorner, "Squircle", {
			Size = UDim2.new(1,0,0,50),
			AutomaticSize = "Y",
			ImageTransparency = Element.Color and .1 or .95,
			--Text = "",
			--TextTransparency = 1,
			--AutoButtonColor = false,
			Parent = Config.Parent,
			ThemeTag = {
				ImageColor3 = not Element.Color and "Text" or nil
			},
			ImageColor3 = Element.Color and Color3.fromHex(Creator.Colors[Element.Color]) or nil
		}, {
			Element.UIElements.Container,
			Element.UIElements.Locked,
			New("UIPadding", {
				PaddingTop = UDim.new(0,Element.UIPadding),
				PaddingLeft = UDim.new(0,Element.UIPadding),
				PaddingRight = UDim.new(0,Element.UIPadding),
				PaddingBottom = UDim.new(0,Element.UIPadding),
			}),
		}, true)

		if Element.Hover then
			Creator.AddSignal(Element.UIElements.Main.MouseEnter, function()
				if CanHover then
					Tween(Element.UIElements.Main, .05, {ImageTransparency = Element.Color and .15 or .9}):Play()
				end
			end)
			Creator.AddSignal(Element.UIElements.Main.InputEnded, function()
				if CanHover then
					Tween(Element.UIElements.Main, .05, {ImageTransparency = Element.Color and .1 or .95}):Play()
				end
			end)
		end

		function Element:SetTitle(Title)
			Title.Text = Title
		end

		function Element:SetDesc(Title)
			Desc.Text = Title or ""
			if not Title then
				Desc.Visible = false
			elseif not Desc.Visible then
				Desc.Visible = true
			end
		end


		-- function Element:Show()

		-- end

		function Element:Destroy()
			Element.UIElements.Main:Destroy()
		end


		function Element:Lock()
			CanHover = false
			Element.UIElements.Locked.Active = true
			Element.UIElements.Locked.Visible = true
		end

		function Element:Unlock()
			CanHover = true
			Element.UIElements.Locked.Active = false
			Element.UIElements.Locked.Visible = false
		end

		--task.wait(.015)

		--Element:Show()

		return Element
	end
end)()

WindUI = {
	Window = nil,
	Theme = nil,
	Creator = NormalCreator,
	Themes = {
		Dark = {
			Name = "Dark",
			Accent = "#18181b",
			Outline = "#FFFFFF",
			Text = "#FFFFFF",
			Placeholder = "#999999",
			Background = "#0e0e10",
			Button = "#52525b",
			Icon = "#a1a1aa",
		},
		Light = {
			Name = "Light",
			Accent = "#FFFFFF",
			Outline = "#09090b",
			Text = "#000000",
			Placeholder = "#777777",
			Background = "#e4e4e7",
			Button = "#18181b",
			Icon = "#a1a1aa",
		},
		Rose = {
			Name = "Rose",
			Accent = "#881337",
			Outline = "#FFFFFF",
			Text = "#FFFFFF",
			Placeholder = "#6B7280",
			Background = "#4c0519",
			Button = "#52525b",
			Icon = "#a1a1aa",
		},
		Plant = {
			Name = "Plant",
			Accent = "#365314",
			Outline = "#FFFFFF",
			Text = "#e6ffe5",
			Placeholder = "#7d977d",
			Background = "#1a2e05",
			Button = "#52525b",
			Icon = "#a1a1aa",
		},
		Red = {
			Name = "Red",
			Accent = "#7f1d1d",
			Outline = "#FFFFFF",
			Text = "#ffeded",
			Placeholder = "#977d7d",
			Background = "#450a0a",
			Button = "#52525b",
			Icon = "#a1a1aa",
		},
		Indigo = {
			Name = "Indigo",
			Accent = "#312e81",
			Outline = "#FFFFFF",
			Text = "#ffeded",
			Placeholder = "#977d7d",
			Background = "#1e1b4b",
			Button = "#52525b",
			Icon = "#a1a1aa",
		},

	},
	Transparent = false,

	TransparencyValue = .15,

	ConfigManager = nil
}

local Creator = NormalCreator
local New = Creator.New
local Tween = Creator.Tween

local UIComponent = NormalUI
local CreateButton = UIComponent.Button
local CreateInput = UIComponent.Input 

local Themes = WindUI.Themes
local Creator = WindUI.Creator

local New = Creator.New
local Tween = Creator.Tween

Creator.Themes = Themes

WindUI.Themes = Themes

WindUI.ScreenGui = New("ScreenGui", {
	Name = "WindUI",
	Parent = GUIParent,
	IgnoreGuiInset = true,
	ScreenInsets = "None",
}, {
	New("Folder", {
		Name = "Window"
	}),
	-- New("Folder", {
	--     Name = "Notifications"
	-- }),
	-- New("Folder", {
	--     Name = "Dropdowns"
	-- }),
	New("Folder", {
		Name = "Popups"
	}),
	New("Folder", {
		Name = "ToolTips"
	})
})

WindUI.NotificationGui = New("ScreenGui", {
	Name = "WindUI/Notifications",
	Parent = GUIParent,
	IgnoreGuiInset = true,
})
WindUI.DropdownGui = New("ScreenGui", {
	Name = "WindUI/Dropdowns",
	Parent = GUIParent,
	IgnoreGuiInset = true,
})
ProtectGui(WindUI.ScreenGui)
ProtectGui(WindUI.NotificationGui)
ProtectGui(WindUI.DropdownGui)

Creator.Init(WindUI)

math.clamp(WindUI.TransparencyValue, 0, 0.4)

local Creator = NormalCreator
local New = Creator.New
local Tween = Creator.Tween

local Notify = {
	Size = UDim2.new(0,300,1,-100-56),
	SizeLower = UDim2.new(0,300,1,-56),
	UICorner = 16,
	UIPadding = 14,
	ButtonPadding = 9,
	Holder = nil,
	NotificationIndex = 0,
	Notifications = {}
}

function Notify.Init(Parent)
	local NotModule = {
		Lower = false
	}

	function NotModule.SetLower(val)
		NotModule.Lower = val
		NotModule.Frame.Size = val and Notify.SizeLower or Notify.Size
	end

	NotModule.Frame = New("Frame", {
		Position = UDim2.new(1,-116/4,0,56),
		AnchorPoint = Vector2.new(1,0),
		Size = Notify.Size ,
		Parent = Parent,
		BackgroundTransparency = 1,
        --[[ScrollingDirection = "Y",
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0,0,0,0),
        AutomaticCanvasSize = "Y",--]]
	}, {
		New("UIListLayout", {
			HorizontalAlignment = "Center",
			SortOrder = "LayoutOrder",
			VerticalAlignment = "Bottom",
			Padding = UDim.new(0, 8),
		}),
		New("UIPadding", {
			PaddingBottom = UDim.new(0,116/4)
		})
	})
	return NotModule
end

local UIStroke
function Notify.New(Config)
	local Notification = {
		Title = Config.Title or "Notification",
		Content = Config.Content or nil,
		Icon = Config.Icon or nil,
		IconSize = Config.IconSize or nil,
		IconThemed = Config.IconThemed,
		Background = Config.Background,
		BackgroundImageTransparency = Config.BackgroundImageTransparency,
		Duration = Config.Duration or 5,
		Buttons = Config.Buttons or {},
		CanClose = true,
		UIElements = {},
		Closed = false,
	}
	if Notification.CanClose == nil then
		Notification.CanClose = true
	end
	Notify.NotificationIndex = Notify.NotificationIndex + 1
	Notify.Notifications[Notify.NotificationIndex] = Notification

	local UICorner = New("UICorner", {
		CornerRadius = UDim.new(0,Notify.UICorner),
	})

	UIStroke = New("UIStroke", {
		ThemeTag = {
			Color = "Text"
		},
		Transparency = 1, -- - .9
		Thickness = .6,
	})

	local Icon

	if Notification.Icon then
		-- if Creator.Icon(Notification.Icon) and Creator.Icon(Notification.Icon)[2] then
		--     Icon = New("ImageLabel", {
		--         Size = UDim2.new(0,26,0,26),
		--         Position = UDim2.new(0,Notify.UIPadding,0,Notify.UIPadding),
		--         BackgroundTransparency = 1,
		--         Image = Creator.Icon(Notification.Icon)[1],
		--         ImageRectSize = Creator.Icon(Notification.Icon)[2].ImageRectSize,
		--         ImageRectOffset = Creator.Icon(Notification.Icon)[2].ImageRectPosition,
		--         ThemeTag = {
		--             ImageColor3 = "Text"
		--         }
		--     })
		-- elseif string.find(Notification.Icon, "rbxassetid") then
		--     Icon = New("ImageLabel", {
		--         Size = UDim2.new(0,26,0,26),
		--         BackgroundTransparency = 1,
		--         Position = UDim2.new(0,Notify.UIPadding,0,Notify.UIPadding),
		--         Image = Notification.Icon
		--     })
		-- end

		Icon = Creator.Image(
			Notification.IconSize,
			Notification.Icon,
			Notification.Title .. ":" .. Notification.Icon,
			0,
			"Notification",
			Notification.IconThemed
		)
		Icon.Size = UDim2.new(0,26,0,26)
		Icon.Position = UDim2.new(0,Notify.UIPadding,0,Notify.UIPadding)
		-- Icon.LayoutOrder = -1
	end

	local CloseButton
	if Notification.CanClose then
		CloseButton = New("ImageButton", {
			Image = Creator.Icon("x")[1],
			ImageRectSize = Creator.Icon("x")[2].ImageRectSize,
			ImageRectOffset = Creator.Icon("x")[2].ImageRectPosition,
			BackgroundTransparency = 1,
			Size = UDim2.new(0,16,0,16),
			Position = UDim2.new(1,-Notify.UIPadding,0,Notify.UIPadding),
			AnchorPoint = Vector2.new(1,0),
			ThemeTag = {
				ImageColor3 = "Text"
			}
		}, {
			New("TextButton", {
				Size = UDim2.new(1,8,1,8),
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5,0.5),
				Position = UDim2.new(0.5,0,0.5,0),
				Text = "",
			})
		})
	end

	local Duration = New("Frame", {
		Size = UDim2.new(1,0,0,3),
		BackgroundTransparency = .9,
		ThemeTag = {
			BackgroundColor3 = "Text",
		},
		--Visible = false,
	})

	local TextContainer = New("Frame", {
		Size = UDim2.new(1,
			Notification.Icon and -28-Notify.UIPadding or 0,
			1,0),
		Position = UDim2.new(1,0,0,0),
		AnchorPoint = Vector2.new(1,0),
		BackgroundTransparency = 1,
		AutomaticSize = "Y",
	}, {
		New("UIPadding", {
			PaddingTop = UDim.new(0,Notify.UIPadding),
			PaddingLeft = UDim.new(0,Notify.UIPadding),
			PaddingRight = UDim.new(0,Notify.UIPadding),
			PaddingBottom = UDim.new(0,Notify.UIPadding),
		}),
		New("TextLabel", {
			AutomaticSize = "Y",
			Size = UDim2.new(1,-30-Notify.UIPadding,0,0),
			TextWrapped = true,
			TextXAlignment = "Left",
			RichText = true,
			BackgroundTransparency = 1,
			TextSize = 16,
			ThemeTag = {
				TextColor3 = "Text"
			},
			Text = Notification.Title,
			FontFace = Font.new(Creator.Font, Enum.FontWeight.SemiBold)
		}),
		New("UIListLayout", {
			Padding = UDim.new(0,Notify.UIPadding/3)
		})
	})

	if Notification.Content then
		New("TextLabel", {
			AutomaticSize = "Y",
			Size = UDim2.new(1,0,0,0),
			TextWrapped = true,
			TextXAlignment = "Left",
			RichText = true,
			BackgroundTransparency = 1,
			TextTransparency = .4,
			TextSize = 15,
			ThemeTag = {
				TextColor3 = "Text"
			},
			Text = Notification.Content,
			FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
			Parent = TextContainer
		})
	end


	local Main = New("CanvasGroup", {
		Size = UDim2.new(1,0,0,0),
		Position = UDim2.new(2,0,1,0),
		AnchorPoint = Vector2.new(0,1),
		AutomaticSize = "Y",
		BackgroundTransparency = .25,
		ThemeTag = {
			BackgroundColor3 = "Accent"
		},
		--ZIndex = 20
	}, {
		New("ImageLabel", {
			Name = "Background",
			Image = Notification.Background,
			BackgroundTransparency = 1,
			Size = UDim2.new(1,0,1,0),
			ScaleType = "Crop",
			ImageTransparency = Notification.BackgroundImageTransparency
			--ZIndex = 19,
		}),

		UIStroke, UICorner,
		TextContainer,
		Icon, CloseButton,
		Duration,
		--ButtonsContainer,
	})

	local MainContainer = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1,0,0,0),
		Parent = Config.Holder
	}, {
		Main
	})

	function Notification:Close()
		if not Notification.Closed then
			Notification.Closed = true
			Tween(MainContainer, 0.45, {Size = UDim2.new(1, 0, 0, -8)}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
			Tween(Main, 0.55, {Position = UDim2.new(2,0,1,0)}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
			task.wait(.45)
			MainContainer:Destroy()
		end
	end

	task.spawn(function()
		task.wait()
		Tween(MainContainer, 0.45, {Size = UDim2.new(
			1,
			0,
			0,
			Main.AbsoluteSize.Y
			)}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
		Tween(Main, 0.45, {Position = UDim2.new(0,0,1,0)}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
		if Notification.Duration then
			Tween(Duration, Notification.Duration, {Size = UDim2.new(0,0,0,3)}, Enum.EasingStyle.Linear,Enum.EasingDirection.InOut):Play()
			task.wait(Notification.Duration)
			Notification:Close()
		end
	end)

	if CloseButton then
		Creator.AddSignal(CloseButton.TextButton.MouseButton1Click, Notification.Close)
	end

	--Tween():Play()
	return Notification
end

local Holder = Notify.Init(WindUI.NotificationGui)

function WindUI:Notify(Config)
	Config.Holder = Holder.Frame
	Config.Window = WindUI.Window
	Config.WindUI = WindUI
	return Notify.New(Config)
end

function WindUI:SetNotificationLower(Val)
	Holder.SetLower(Val)
end

function WindUI:SetFont(FontId)
	Creator.UpdateFont(FontId)
end

function WindUI:AddTheme(LTheme)
	Themes[LTheme.Name] = LTheme
	return LTheme
end

function WindUI:SetTheme(Value)
	if Themes[Value] then
		WindUI.Theme = Themes[Value]
		Creator.SetTheme(Themes[Value])
		Creator.UpdateTheme()

		return Themes[Value]
	end
	return nil
end

WindUI:SetTheme("Dark")

function WindUI:GetThemes()
	return Themes
end
function WindUI:GetCurrentTheme()
	return WindUI.Theme.Name
end
function WindUI:GetTransparency()
	return WindUI.Transparent or false
end
function WindUI:GetWindowSize()
	return WindUI.ScreenGui.UIElements.Main.Size
end


function WindUI:Popup(PopupConfig)
	PopupConfig.WindUI = WindUI
	local PopupModule = {}

	local Creator = NormalCreator
	local New = Creator.New
	local Tween = Creator.Tween


	function PopupModule.new(PopupConfig)
		local Popup = {
			Title = PopupConfig.Title or "Dialog",
			Content = PopupConfig.Content,
			Icon = PopupConfig.Icon,
			IconSize = PopupConfig.IconSize,
			IconThemed = PopupConfig.IconThemed,
			Thumbnail = PopupConfig.Thumbnail,
			Buttons = PopupConfig.Buttons
		}

		local DialogInit = NormalDialog.Init(PopupConfig.WindUI.ScreenGui.Popups)
		local Dialog = DialogInit.Create(true)

		local ThumbnailSize = 200

		local UISize = 430
		if Popup.Thumbnail and Popup.Thumbnail.Image then
			UISize = 430+(ThumbnailSize/2)
		end

		Dialog.UIElements.Main.AutomaticSize = "Y"
		Dialog.UIElements.Main.Size = UDim2.new(0,UISize,0,0)



		local IconFrame

		if Popup.Icon then
			IconFrame = Creator.Image(
				Popup.IconSize,
				Popup.Icon,
				Popup.Title .. ":" .. Popup.Icon,
				0,
				"Popup",
				PopupConfig.IconThemed
			)
			IconFrame.Size = UDim2.new(0,24,0,24)
			IconFrame.LayoutOrder = -1
		end


		local Title = New("TextLabel", {
			AutomaticSize = "XY",
			BackgroundTransparency = 1,
			Text = Popup.Title,
			TextXAlignment = "Left",
			FontFace = Font.new(Creator.Font, Enum.FontWeight.SemiBold),
			ThemeTag = {
				TextColor3 = "Text",
			},
			TextSize = 20
		})

		local IconAndTitleContainer = New("Frame", {
			BackgroundTransparency = 1,
			AutomaticSize = "XY",
		}, {
			New("UIListLayout", {
				Padding = UDim.new(0,14),
				FillDirection = "Horizontal",
				VerticalAlignment = "Center"
			}),
			IconFrame, Title
		})

		local TitleContainer = New("Frame", {
			AutomaticSize = "Y",
			Size = UDim2.new(1,0,0,0),
			BackgroundTransparency = 1,
		}, {
			-- New("UIListLayout", {
			--     Padding = UDim.new(0,9),
			--     FillDirection = "Horizontal",
			--     VerticalAlignment = "Bottom"
			-- }),
			IconAndTitleContainer,
		})

		local NoteText
		if Popup.Content and Popup.Content ~= "" then
			NoteText = New("TextLabel", {
				Size = UDim2.new(1,0,0,0),
				AutomaticSize = "Y",
				FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
				TextXAlignment = "Left",
				Text = Popup.Content,
				TextSize = 18,
				TextTransparency = .2,
				ThemeTag = {
					TextColor3 = "Text",
				},
				BackgroundTransparency = 1,
				RichText = true
			})
		end

		local ButtonsContainer = New("Frame", {
			Size = UDim2.new(1,0,0,42),
			BackgroundTransparency = 1,
		}, {
			New("UIListLayout", {
				Padding = UDim.new(0,18/2),
				FillDirection = "Horizontal",
				HorizontalAlignment = "Right"
			})
		})

		local ThumbnailFrame
		if Popup.Thumbnail and Popup.Thumbnail.Image then
			local ThumbnailTitle
			if Popup.Thumbnail.Title then
				ThumbnailTitle = New("TextLabel", {
					Text = Popup.Thumbnail.Title,
					ThemeTag = {
						TextColor3 = "Text",
					},
					TextSize = 18,
					FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
					BackgroundTransparency = 1,
					AutomaticSize = "XY",
					AnchorPoint = Vector2.new(0.5,0.5),
					Position = UDim2.new(0.5,0,0.5,0),
				})
			end
			ThumbnailFrame = New("ImageLabel", {
				Image = Popup.Thumbnail.Image,
				BackgroundTransparency = 1,
				Size = UDim2.new(0,ThumbnailSize,1,0),
				Parent = Dialog.UIElements.Main,
				ScaleType = "Crop"
			}, {
				ThumbnailTitle,
				New("UICorner", {
					CornerRadius = UDim.new(0,0),
				})
			})
		end

		local MainFrame = New("Frame", {
			--AutomaticSize = "XY",
			Size = UDim2.new(1, ThumbnailFrame and -ThumbnailSize or 0,1,0),
			Position = UDim2.new(0, ThumbnailFrame and ThumbnailSize or 0,0,0),
			BackgroundTransparency = 1,
			Parent = Dialog.UIElements.Main
		}, {
			New("Frame", {
				--AutomaticSize = "XY",
				Size = UDim2.new(1,0,1,0),
				BackgroundTransparency = 1,
			}, {
				New("UIListLayout", {
					Padding = UDim.new(0,18),
					FillDirection = "Vertical",
				}),
				TitleContainer,
				NoteText,
				ButtonsContainer,
				New("UIPadding", {
					PaddingTop = UDim.new(0,16),
					PaddingLeft = UDim.new(0,16),
					PaddingRight = UDim.new(0,16),
					PaddingBottom = UDim.new(0,16),
				})
			}),
		})

		local CreateButton = NormalUI.Button

		for _, values in next, Popup.Buttons do
			CreateButton(values.Title, values.Icon, values.Callback, values.Variant, ButtonsContainer, Dialog)
		end

		Dialog:Open()


		return Popup
	end

	return PopupModule.new(PopupConfig)
end


function WindUI:CreateWindow(Config)
	local Creator = NormalCreator
	local New = Creator.New
	local Tween = Creator.Tween

	local UIComponents = NormalUI
	local CreateLabel = UIComponents.Label
	local CreateScrollSlider = UIComponents.ScrollSlider

	-- credits: dawid

	local ConfigManager, TabModuleMain
	ConfigManager = {
		Window = nil,
		Folder = nil,
		Configs = {},
		Parser = {
			Colorpicker = {
				Save = function(obj)
					return {
						__type = obj.__type,
						value = obj.Default:ToHex(),
						transparency = obj.Transparency or nil,
					}
				end,
				Load = function(element, data)
					if element then
						element:Update(Color3.fromHex(data.value), data.transparency or nil)
					end
				end
			},
			Dropdown = {
				Save = function(obj)
					return {
						__type = obj.__type,
						value = obj.Value,
					}
				end,
				Load = function(element, data)
					if element then
						element:Select(data.value)
					end
				end
			},
			Input = {
				Save = function(obj)
					return {
						__type = obj.__type,
						value = obj.Value,
					}
				end,
				Load = function(element, data)
					if element then
						element:Set(data.value)
					end
				end
			},
			Keybind = {
				Save = function(obj)
					return {
						__type = obj.__type,
						value = obj.Value,
					}
				end,
				Load = function(element, data)
					if element then
						element:Set(data.value)
					end
				end
			},
			Slider = {
				Save = function(obj)
					return {
						__type = obj.__type,
						value = obj.Value.Default,
					}
				end,
				Load = function(element, data)
					if element then
						element:Set(data.value)
					end
				end
			},
			Toggle = {
				Save = function(obj)
					return {
						__type = obj.__type,
						value = obj.Value,
					}
				end,
				Load = function(element, data)
					if element then
						element:Set(data.value)
					end
				end
			},
		}
	}

	function ConfigManager:Init(Window)
		ConfigManager.Window = Window
		ConfigManager.Folder = Window.Folder

		return ConfigManager
	end

	function ConfigManager:CreateConfig(configFilename)
		if not isfolder(ConfigManager.Folder .. "/config") then
			makefolder(ConfigManager.Folder .. "/config")
		end
		
		local ConfigModule = {
			Path = ConfigManager.Folder .. "/config/" .. configFilename .. ".json",

			Elements = {}
		}

		if not configFilename then
			return false, "No config file is selected"
		end

		function ConfigModule:Register(Name, Element)
			ConfigModule.Elements[Name] = Element
		end

		function ConfigModule:RegisterAll()
			for TabName, Tab in pairs(TabModuleMain.Tabs) do
				if type(Tab) == "table" and rawget(Tab, "__type") == "Tab" then
					for _, Element in ipairs(Tab.Elements) do
						local RealTitle = Element.Title or ""
						local ElementTitle = RealTitle:gsub(" ", ""):gsub("👑", "")
						local FinalElementName = TabName .. "_" .. Element.__type .. "_" .. ElementTitle

						ConfigModule.Elements[FinalElementName] = Element
					end
				end
			end
		end

		function ConfigModule:Save()
			local saveData = {
				Elements = {}
			}

			for name,i in next, ConfigModule.Elements do
				if ConfigManager.Parser[i.__type] then
					saveData.Elements[tostring(name)] = ConfigManager.Parser[i.__type].Save(i)
				end
			end

			writefile(ConfigModule.Path, HttpService:JSONEncode(saveData))
		end

		function ConfigModule:Load()
			if not isfile(ConfigModule.Path) then return false, "Invalid file" end

			local loadData = HttpService:JSONDecode(readfile(ConfigModule.Path))

			for name, data in next, loadData.Elements do
				if ConfigModule.Elements[name] and ConfigManager.Parser[data.__type] then
					task.spawn(ConfigManager.Parser[data.__type].Load, ConfigModule.Elements[name], data)
				end
			end

		end

		ConfigManager.Configs[configFilename] = ConfigModule

		return ConfigModule
	end

	local Notified = false
	local CreateWindow = function(Config)
		local Window = {
			Title = Config.Title or "UI Library",
			Author = Config.Author,
			Icon = Config.Icon,
			IconSize = Config.IconSize,
			IconFrameSize = Config.IconFrameSize,
			IconThemed = Config.IconThemed,
			Folder = Config.Folder,
			Background = Config.Background,
			BackgroundImageTransparency = Config.BackgroundImageTransparency or 0,
			User = Config.User or {},
			Size = Config.Size and UDim2.new(
				0, math.clamp(Config.Size.X.Offset, 480, 700),
				0, math.clamp(Config.Size.Y.Offset, 350, 520)) or UDim2.new(0,580,0,460),
			ToggleKey = Config.ToggleKey or Enum.KeyCode.LeftControl,
			Transparent = Config.Transparent or false,
			HideSearchBar = Config.HideSearchBar or false,
			ScrollBarEnabled = Config.ScrollBarEnabled or false,
			Position = UDim2.new(
				0.5, 0,
				0.5, 0
			),
			UICorner = 16,
			UIPadding = 14,
			SideBarWidth = Config.SideBarWidth or 200,
			UIElements = {},
			CanDropdown = true,
			Closed = false,
			HasOutline = Config.HasOutline or false,
			SuperParent = Config.Parent,
			Destroyed = false,
			IsFullscreen = false,
			CanResize = true,
			IsOpenButtonEnabled = true,

			ConfigManager = nil,
			CurrentTab = nil,
			TabModule = nil,

			OnCloseCallback   = nil,
			OnDestroyCallback = nil,

			TopBarButtons = {},

		} -- wtf 


		if Window.Folder then
			makefolder("WindUI/" .. Window.Folder)
		end

		local UICorner = New("UICorner", {
			CornerRadius = UDim.new(0,Window.UICorner)
		})

		Window.ConfigManager = ConfigManager:Init(Window)

		local ResizeHandle = New("Frame", {
			Size = UDim2.new(0,32,0,32),
			Position = UDim2.new(1,0,1,0),
			AnchorPoint = Vector2.new(.5,.5),
			BackgroundTransparency = 1,
			ZIndex = 99,
			Active = true
		}, {
			New("ImageLabel", {
				Size = UDim2.new(0,48*2,0,48*2),
				BackgroundTransparency = 1,
				Image = "rbxassetid://72649237620176",
				Position = UDim2.new(0.5,-16,0.5,-16),
				AnchorPoint = Vector2.new(0.5,0.5),
				ImageTransparency = 1, -- .8; .35
			})
		})
		local FullScreenIcon = Creator.NewRoundFrame(Window.UICorner, "Squircle", {
			Size = UDim2.new(1,0,1,0),
			ImageTransparency = 1, -- .65
			ImageColor3 = Color3.new(0,0,0),
			ZIndex = 98,
			Active = false, -- true
		}, {
			New("ImageLabel", {
				Size = UDim2.new(0,70,0,70),
				Image = Creator.Icon("expand")[1],
				ImageRectOffset = Creator.Icon("expand")[2].ImageRectPosition,
				ImageRectSize = Creator.Icon("expand")[2].ImageRectSize,
				BackgroundTransparency = 1,
				Position = UDim2.new(0.5,0,0.5,0),
				AnchorPoint = Vector2.new(0.5,0.5),
				ImageTransparency = 1,
			}),
		})

		local FullScreenBlur = Creator.NewRoundFrame(Window.UICorner, "Squircle", {
			Size = UDim2.new(1,0,1,0),
			ImageTransparency = 1, -- .65
			ImageColor3 = Color3.new(0,0,0),
			ZIndex = 999,
			Active = false, -- true
		})


		local TabHighlight = Creator.NewRoundFrame(Window.UICorner-(Window.UIPadding/2), "Squircle", {
			Size = UDim2.new(1,0,0,0),
			ImageTransparency = .95,
			ThemeTag = {
				ImageColor3 = "Text",
			}
		})

		Window.UIElements.SideBar = New("ScrollingFrame", {
			Size = UDim2.new(
				1,
				Window.ScrollBarEnabled and -3-(Window.UIPadding/2) or 0,
				1, 
				not Window.HideSearchBar and -39-6 or 0
			),
			Position = UDim2.new(0,0,1,0),
			AnchorPoint = Vector2.new(0,1),
			BackgroundTransparency = 1,
			ScrollBarThickness = 0,
			ElasticBehavior = "Never",
			CanvasSize = UDim2.new(0,0,0,0),
			AutomaticCanvasSize = "Y",
			ScrollingDirection = "Y",
			ClipsDescendants = true,
			VerticalScrollBarPosition = "Left",
		}, {
			New("Frame", {
				BackgroundTransparency = 1,
				AutomaticSize = "Y",
				Size = UDim2.new(1,0,0,0),
				Name = "Frame",
			}, {
				New("UIPadding", {
					PaddingTop = UDim.new(0,Window.UIPadding/2),
					PaddingLeft = UDim.new(0,4+(Window.UIPadding/2)),
					PaddingRight = UDim.new(0,4+(Window.UIPadding/2)),
					PaddingBottom = UDim.new(0,Window.UIPadding/2),
				}),
				New("UIListLayout", {
					SortOrder = "LayoutOrder",
					Padding = UDim.new(0,6)
				})
			}),
			New("UIPadding", {
				--PaddingTop = UDim.new(0,4),
				PaddingLeft = UDim.new(0,Window.UIPadding/2),
				PaddingRight = UDim.new(0,Window.UIPadding/2),
				--PaddingBottom = UDim.new(0,Window.UIPadding),
			}),
			TabHighlight
		})

		Window.UIElements.SideBarContainer = New("Frame", {
			Size = UDim2.new(0,Window.SideBarWidth,1,Window.User.Enabled and -52 -42 -(Window.UIPadding*2) or -52 ),
			Position = UDim2.new(0,0,0,52),
			BackgroundTransparency = 1,
			Visible = true,
		}, {
			New("Frame", {
				Name = "Content",
				BackgroundTransparency = 1,
				Size = UDim2.new(
					1,
					0,
					1, 
					not Window.HideSearchBar and -39-6 or 0
				),
				Position = UDim2.new(0,0,1,0),
				AnchorPoint = Vector2.new(0,1),
			}),
			Window.UIElements.SideBar,
		})

		if Window.ScrollBarEnabled then
			CreateScrollSlider(Window.UIElements.SideBar, Window.UIElements.SideBarContainer.Content, Window, 3)
		end


		Window.UIElements.MainBar = New("Frame", {
			Size = UDim2.new(1,-Window.UIElements.SideBarContainer.AbsoluteSize.X,1,-52),
			Position = UDim2.new(1,0,1,0),
			AnchorPoint = Vector2.new(1,1),
			BackgroundTransparency = 1,
		}, {
			Creator.NewRoundFrame(Window.UICorner-(Window.UIPadding/2), "Squircle", {
				Size = UDim2.new(1,0,1,0),
				ImageColor3 = Color3.new(1,1,1),
				ZIndex = 3,
				ImageTransparency = .95,
				Name = "Background",
			}),
			New("UIPadding", {
				PaddingTop = UDim.new(0,Window.UIPadding/2),
				PaddingLeft = UDim.new(0,Window.UIPadding/2),
				PaddingRight = UDim.new(0,Window.UIPadding/2),
				PaddingBottom = UDim.new(0,Window.UIPadding/2),
			})
		})

		local Blur = New("ImageLabel", {
			Image = "rbxassetid://81273610672268",
			ImageColor3 = Color3.new(0,0,0),
			ImageTransparency = 1, -- 0.7
			Size = UDim2.new(1,120,1,116),
			Position = UDim2.new(0,-120/2,0,-116/2),
			ScaleType = "Slice",
			SliceCenter = Rect.new(99,99,99,99),
			BackgroundTransparency = 1,
			ZIndex = -999999999999999,
			Name = "Blur",
		})

		local IsPC

		if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
			IsPC = false
		elseif UserInputService.KeyboardEnabled then
			IsPC = true
		else
			IsPC = nil
		end

		local OpenButtonContainer = nil
		local OpenButton = nil
		local OpenButtonIcon = nil
		local Glow = nil

		local OpenButtonTitle, OpenButtonDrag, OpenButtonDivider

		do
			OpenButtonIcon = New("ImageLabel", {
				Image = "",
				Size = UDim2.new(0,22,0,22),
				Position = UDim2.new(0.5,0,0.5,0),
				LayoutOrder = -1,
				AnchorPoint = Vector2.new(0.5,0.5),
				BackgroundTransparency = 1,
				Name = "Icon"
			})

			OpenButtonTitle = New("TextLabel", {
				Text = Window.Title,
				TextSize = 17,
				FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
				BackgroundTransparency = 1,
				AutomaticSize = "XY",
			})

			OpenButtonDrag = New("Frame", {
				Size = UDim2.new(0,44-8,0,44-8),
				BackgroundTransparency = 1, 
				Name = "Drag",
			}, {
				New("ImageLabel", {
					Image = Creator.Icon("move")[1],
					ImageRectOffset = Creator.Icon("move")[2].ImageRectPosition,
					ImageRectSize = Creator.Icon("move")[2].ImageRectSize,
					Size = UDim2.new(0,18,0,18),
					BackgroundTransparency = 1,
					Position = UDim2.new(0.5,0,0.5,0),
					AnchorPoint = Vector2.new(0.5,0.5),
				})
			})
			OpenButtonDivider = New("Frame", {
				Size = UDim2.new(0,1,1,0),
				Position = UDim2.new(0,20+16,0.5,0),
				AnchorPoint = Vector2.new(0,0.5),
				BackgroundColor3 = Color3.new(1,1,1),
				BackgroundTransparency = .9,
			})

			OpenButtonContainer = New("Frame", {
				Size = UDim2.new(0,0,0,0),
				Position = UDim2.new(0.5,0,0,6+44/2),
				AnchorPoint = Vector2.new(0.5,0.5),
				Parent = Config.Parent,
				BackgroundTransparency = 1,
				Active = true,
				Visible = false,
			})
			OpenButton = New("TextButton", {
				Size = UDim2.new(0,0,0,44),
				AutomaticSize = "X",
				Parent = OpenButtonContainer,
				Active = false,
				BackgroundTransparency = .25,
				ZIndex = 99,
				BackgroundColor3 = Color3.new(0,0,0),
			}, {
				-- New("UIScale", {
				--     Scale = 1.05,
				-- }),
				New("UICorner", {
					CornerRadius = UDim.new(1,0)
				}),
				New("UIStroke", {
					Thickness = 1,
					ApplyStrokeMode = "Border",
					Color = Color3.new(1,1,1),
					Transparency = 0,
				}, {
					New("UIGradient", {
						Color = ColorSequence.new(Color3.fromHex("40c9ff"), Color3.fromHex("e81cff"))
					})
				}),
				OpenButtonDrag,
				OpenButtonDivider,

				New("UIListLayout", {
					Padding = UDim.new(0, 4),
					FillDirection = "Horizontal",
					VerticalAlignment = "Center",
				}),

				New("TextButton",{
					AutomaticSize = "XY",
					Active = true,
					BackgroundTransparency = 1, -- .93
					Size = UDim2.new(0,0,0,44-(4*2)),
					--Position = UDim2.new(0,20+16+16+1,0,0),
					BackgroundColor3 = Color3.new(1,1,1),
				}, {
					New("UICorner", {
						CornerRadius = UDim.new(1,-4)
					}),
					OpenButtonIcon,
					New("UIListLayout", {
						Padding = UDim.new(0, Window.UIPadding),
						FillDirection = "Horizontal",
						VerticalAlignment = "Center",
					}),
					OpenButtonTitle,
					New("UIPadding", {
						PaddingLeft = UDim.new(0,8+4),
						PaddingRight = UDim.new(0,8+4),
					}),
				}),
				New("UIPadding", {
					PaddingLeft = UDim.new(0,4),
					PaddingRight = UDim.new(0,4),
				})
			})

			local uiGradient = OpenButton and OpenButton.UIStroke.UIGradient or nil


			Creator.AddSignal(RunService.RenderStepped, function(deltaTime)
				if rawget(Window.UIElements, "Main") and OpenButtonContainer and OpenButtonContainer.Parent ~= nil then
					if uiGradient then
						uiGradient.Rotation = (uiGradient.Rotation + 1) % 360
					end
					if Glow and Glow.Parent ~= nil and Glow.UIGradient then
						Glow.UIGradient.Rotation = (Glow.UIGradient.Rotation + 1) % 360
					end
				end
			end)

			Creator.AddSignal(OpenButton:GetPropertyChangedSignal("AbsoluteSize"), function()
				OpenButtonContainer.Size = UDim2.new(
					0, OpenButton.AbsoluteSize.X,
					0, OpenButton.AbsoluteSize.Y
				)
			end)

			Creator.AddSignal(OpenButton.TextButton.MouseEnter, function()
				--Tween(OpenButton.UIScale, .1, {Scale = .99}):Play()
				Tween(OpenButton.TextButton, .1, {BackgroundTransparency = .93}):Play()
			end)
			Creator.AddSignal(OpenButton.TextButton.MouseLeave, function()
				--Tween(OpenButton.UIScale, .1, {Scale = 1.05}):Play()
				Tween(OpenButton.TextButton, .1, {BackgroundTransparency = 1}):Play()
			end)
		end

		local UserIcon
		if Window.User.Enabled then
			local ImageId, _ = Players:GetUserThumbnailAsync(
				Window.User.Anonymous and 1 or LocalPlayer.UserId, 
				Enum.ThumbnailType.HeadShot, 
				Enum.ThumbnailSize.Size420x420
			)

			UserIcon = New("TextButton", {
				Size = UDim2.new(0,
					(Window.UIElements.SideBarContainer.AbsoluteSize.X)-(Window.UIPadding/2),
					0,
					42+(Window.UIPadding)
				),
				Position = UDim2.new(0,Window.UIPadding/2,1,-(Window.UIPadding/2)),
				AnchorPoint = Vector2.new(0,1),
				BackgroundTransparency = 1,
			}, {
				Creator.NewRoundFrame(Window.UICorner-(Window.UIPadding/2), "Squircle", {
					Size = UDim2.new(1,0,1,0),
					ThemeTag = {
						ImageColor3 = "Text",
					},
					ImageTransparency = 1, -- .94
					Name = "UserIcon",
				}, {
					New("ImageLabel", {
						Image = ImageId,
						BackgroundTransparency = 1,
						Size = UDim2.new(0,42,0,42),
						ThemeTag = {
							BackgroundColor3 = "Text",
						},
						--BackgroundTransparency = .93,
					}, {
						New("UICorner", {
							CornerRadius = UDim.new(1,0)
						})
					}),
					New("Frame", {
						AutomaticSize = "XY",
						BackgroundTransparency = 1,
					}, {
						New("TextLabel", {
							Text = Window.User.Anonymous and "Anonymous" or Window.User.DisplayName or LocalPlayer.DisplayName,
							TextSize = 17,
							ThemeTag = {
								TextColor3 = "Text",
							},
							FontFace = Font.new(Creator.Font, Enum.FontWeight.SemiBold),
							AutomaticSize = "Y",
							BackgroundTransparency = 1,
							Size = UDim2.new(1,-(42/2)-6,0,0),
							TextTruncate = "AtEnd",
							TextXAlignment = "Left",
						}),
						New("TextLabel", {
							Text = Window.User.Anonymous and "@anonymous" or Window.User.Name or "@" .. LocalPlayer.Name,
							TextSize = 15,
							TextTransparency = .6,
							ThemeTag = {
								TextColor3 = "Text",
							},
							FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
							AutomaticSize = "Y",
							BackgroundTransparency = 1, 
							Size = UDim2.new(1,-(42/2)-6,0,0),
							TextTruncate = "AtEnd",
							TextXAlignment = "Left",
						}),
						New("UIListLayout", {
							Padding = UDim.new(0,4),
							HorizontalAlignment = "Left",
						})
					}),
					New("UIListLayout", {
						Padding = UDim.new(0,Window.UIPadding),
						FillDirection = "Horizontal",
						VerticalAlignment = "Center",
					}),
					New("UIPadding", {
						PaddingLeft = UDim.new(0,Window.UIPadding/2),
						PaddingRight = UDim.new(0,Window.UIPadding/2),
					})
				})
			})

			if Window.User.Callback then
				Creator.AddSignal(UserIcon.MouseButton1Click, Window.User.Callback)
				Creator.AddSignal(UserIcon.MouseEnter, function()
					Tween(UserIcon.UserIcon, 0.04, {ImageTransparency = .94}):Play()
				end)
				Creator.AddSignal(UserIcon.InputEnded, function()
					Tween(UserIcon.UserIcon, 0.04, {ImageTransparency = 1}):Play()
				end)
			end
		end

		local Outline1, Outline2 = nil, nil
		-- if Window.HasOutline then
		--     Outline1 = New("Frame", {
		--         Name = "Outline",
		--         Size = UDim2.new(1,Window.UIPadding+8,0,1),
		--         Position = UDim2.new(0,-Window.UIPadding,1,Window.UIPadding),
		--         BackgroundTransparency= .9,
		--         AnchorPoint = Vector2.new(0,0.5),
		--         ThemeTag = {
		--             BackgroundColor3 = "Outline"
		--         },
		--     })
		--     Outline2 = New("Frame", {
		--         Name = "Outline",
		--         Size = UDim2.new(0,1,1,-52),
		--         Position = UDim2.new(0,Window.SideBarWidth -Window.UIPadding/2,0,52),
		--         BackgroundTransparency= .9,
		--         AnchorPoint = Vector2.new(0.5,0),
		--         ThemeTag = {
		--             BackgroundColor3 = "Outline"
		--         },
		--     })
		-- end


		local BottomDragFrame = Creator.NewRoundFrame(99, "Squircle", {
			ImageTransparency = .8,
			ImageColor3 = Color3.new(1,1,1),
			Size = UDim2.new(0,0,0,4), -- 200
			Position = UDim2.new(0.5,0,1,4),
			AnchorPoint = Vector2.new(0.5,0),
		}, {
			New("Frame", {
				Size = UDim2.new(1,12,1,12),
				BackgroundTransparency = 1,
				Position = UDim2.new(0.5,0,0.5,0),
				AnchorPoint = Vector2.new(0.5,0.5),
				Active = true,
				ZIndex = 99,
			})
		})

		local WindowTitle = New("TextLabel", {
			Text = Window.Title,
			FontFace = Font.new(Creator.Font, Enum.FontWeight.SemiBold),
			BackgroundTransparency = 1,
			AutomaticSize = "XY",
			Name = "Title",
			TextXAlignment = "Left",
			TextSize = 16,
			ThemeTag = {
				TextColor3 = "Text"
			}
		})

		Window.UIElements.Main = New("Frame", {
			Size = Window.Size,
			Position = Window.Position,
			BackgroundTransparency = 1,
			Parent = Config.Parent,
			AnchorPoint = Vector2.new(0.5,0.5),
			Active = true,
		}, {
			Blur,
			Creator.NewRoundFrame(Window.UICorner, "Squircle", {
				ImageTransparency = 1, -- Window.Transparent and 0.25 or 0
				Size = UDim2.new(1,0,1,-240),
				AnchorPoint = Vector2.new(0.5,0.5),
				Position = UDim2.new(0.5,0,0.5,0),
				Name = "Background",
				ThemeTag = {
					ImageColor3 = "Background"
				},
				--ZIndex = -9999,
			}, {
				New("ImageLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1,0,1,0),
					Image = Window.Background,
					ImageTransparency = 1,
					ScaleType = "Crop",
				}, {
					New("UICorner", {
						CornerRadius = UDim.new(0,Window.UICorner)
					}),
				}),
				BottomDragFrame,
				ResizeHandle,
				-- New("UIScale", {
				--     Scale = 0.95,
				-- }),
			}),
			UIStroke,
			UICorner,
			FullScreenIcon,
			FullScreenBlur,
			New("Frame", {
				Size = UDim2.new(1,0,1,0),
				BackgroundTransparency = 1,
				Name = "Main",
				--GroupTransparency = 1,
				Visible = false,
				ZIndex = 97,
			}, {
				New("UICorner", {
					CornerRadius = UDim.new(0,Window.UICorner)
				}),
				Window.UIElements.SideBarContainer,
				Window.UIElements.MainBar,

				UserIcon,

				Outline2,
				New("Frame", { -- Topbar
					Size = UDim2.new(1,0,0,52),
					BackgroundTransparency = 1,
					BackgroundColor3 = Color3.fromRGB(50,50,50),
					Name = "Topbar"
				}, {
					Outline1,
                --[[New("Frame", { -- Outline
                    Size = UDim2.new(1,Window.UIPadding*2, 0, 1),
                    Position = UDim2.new(0,-Window.UIPadding, 1,Window.UIPadding-2),
                    BackgroundTransparency = 0.9,
                    BackgroundColor3 = Color3.fromHex(Config.Theme.Outline),
                }),]]
					New("Frame", { -- Topbar Left Side
						AutomaticSize = "X",
						Size = UDim2.new(0,0,1,0),
						BackgroundTransparency = 1,
						Name = "Left"
					}, {
						New("UIListLayout", {
							Padding = UDim.new(0,Window.UIPadding+4),
							SortOrder = "LayoutOrder",
							FillDirection = "Horizontal",
							VerticalAlignment = "Center",
						}),
						New("Frame", {
							AutomaticSize = "XY",
							BackgroundTransparency = 1,
							Name = "Title",
							Size = UDim2.new(0,0,1,0),
							LayoutOrder= 2,
						}, {
							New("UIListLayout", {
								Padding = UDim.new(0,0),
								SortOrder = "LayoutOrder",
								FillDirection = "Vertical",
								VerticalAlignment = "Top",
							}),
							WindowTitle,
						}),
						New("UIPadding", {
							PaddingLeft = UDim.new(0,4)
						})
					}),
					New("Frame", { -- Topbar Right Side -- Window.UIElements.Main.Main.Topbar.Right
						AutomaticSize = "XY",
						BackgroundTransparency = 1,
						Position = UDim2.new(1,0,0.5,0),
						AnchorPoint = Vector2.new(1,0.5),
						Name = "Right",
					}, {
						New("UIListLayout", {
							Padding = UDim.new(0,9),
							FillDirection = "Horizontal",
							SortOrder = "LayoutOrder",
						}),

					}),
					New("UIPadding", {
						PaddingTop = UDim.new(0,Window.UIPadding),
						PaddingLeft = UDim.new(0,Window.UIPadding),
						PaddingRight = UDim.new(0,8),
						PaddingBottom = UDim.new(0,Window.UIPadding),
					})
				})
			})
		})


		function Window:CreateTopbarButton(Name, Icon, Callback, LayoutOrder)
			local Button = New("TextButton", {
				Size = UDim2.new(0,36,0,36),
				BackgroundTransparency = 1,
				LayoutOrder = LayoutOrder or 999,
				Parent = Window.UIElements.Main.Main.Topbar.Right,
				--Active = true,
				ZIndex = 9999,
				ThemeTag = {
					BackgroundColor3 = "Text"
				},
				--BackgroundTransparency = 1 -- .93
			}, {
				New("UICorner", {
					CornerRadius = UDim.new(0,9),
				}),
				New("ImageLabel", {
					Image = Creator.Icon(Icon)[1],
					ImageRectOffset = Creator.Icon(Icon)[2].ImageRectPosition,
					ImageRectSize = Creator.Icon(Icon)[2].ImageRectSize,
					BackgroundTransparency = 1,
					Size = UDim2.new(0,16,0,16),
					ThemeTag = {
						ImageColor3 = "Text"
					},
					AnchorPoint = Vector2.new(0.5,0.5),
					Position = UDim2.new(0.5,0,0.5,0),
					Active = false,
					ImageTransparency = .2,
				}),
			})

			-- shhh

			Window.TopBarButtons[100-LayoutOrder] = {
				Name = Name,
				Object = Button
			}

			Creator.AddSignal(Button.MouseButton1Click, Callback)
			Creator.AddSignal(Button.MouseEnter, function()
				Tween(Button, .15, {BackgroundTransparency = .93}):Play()
				Tween(Button.ImageLabel, .15, {ImageTransparency = 0}):Play()
			end)
			Creator.AddSignal(Button.MouseLeave, function()
				Tween(Button, .1, {BackgroundTransparency = 1}):Play()
				Tween(Button.ImageLabel, .1, {ImageTransparency = .2}):Play()
			end)

			return Button
		end

		-- local Dragged = false

		local WindowDragModule = Creator.Drag(
			Window.UIElements.Main, 
			{Window.UIElements.Main.Main.Topbar, BottomDragFrame.Frame}, 
			function(dragging, frame) -- On drag
				if not Window.Closed then
					if dragging and frame == BottomDragFrame.Frame then
						Tween(BottomDragFrame, .1, {ImageTransparency = .35}):Play()
					else
						Tween(BottomDragFrame, .2, {ImageTransparency = .8}):Play()
					end
				end
			end
		)

		--Creator.Blur(Window.UIElements.Main.Background)
		local OpenButtonDragModule

		if not IsPC then
			OpenButtonDragModule = Creator.Drag(OpenButtonContainer)
		end

		if Window.Author then
			local Author = New("TextLabel", {
				Text = Window.Author,
				FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
				BackgroundTransparency = 1,
				TextTransparency = 0.4,
				AutomaticSize = "XY",
				Parent = Window.UIElements.Main.Main.Topbar.Left.Title,
				TextXAlignment = "Left",
				TextSize = 14,
				LayoutOrder = 2,
				ThemeTag = {
					TextColor3 = "Text"
				}
			})
			-- Author:GetPropertyChangedSignal("TextBounds"), function()
			--     Author.Size = UDim2.new(0,Author.TextBounds.X,0,Author.TextBounds.Y)
			-- end)
		end
		-- WindowTitle:GetPropertyChangedSignal("TextBounds"), function()
		--     WindowTitle.Size = UDim2.new(0,WindowTitle.TextBounds.X,0,WindowTitle.TextBounds.Y)
		-- end)
		-- Window.UIElements.Main.Main.Topbar.Frame.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		--     Window.UIElements.Main.Main.Topbar.Frame.Size = UDim2.new(0,Window.UIElements.Main.Main.Topbar.Frame.UIListLayout.AbsoluteContentSize.X,0,Window.UIElements.Main.Main.Topbar.Frame.UIListLayout.AbsoluteContentSize.Y)
		-- end)
		-- Window.UIElements.Main.Main.Topbar.Left.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		--     Window.UIElements.Main.Main.Topbar.Left.Size = UDim2.new(0,Window.UIElements.Main.Main.Topbar.Left.UIListLayout.AbsoluteContentSize.X,1,0)
		-- end)

		task.spawn(function()
			if Window.Icon then
				local ImageFrame = Creator.Image(
					Window.IconSize,
					Window.Icon,
					Window.Title,
					0,
					"Window",
					true,
					Window.IconThemed
				)
				ImageFrame.Parent = Window.UIElements.Main.Main.Topbar.Left
				ImageFrame.Size = Window.IconFrameSize or UDim2.new(0,22,0,22)

				if Creator.Icon(tostring(Window.Icon)) and Creator.Icon(tostring(Window.Icon))[1] then
					-- ImageLabel.Image = Creator.Icon(Window.Icon)[1]
					-- ImageLabel.ImageRectOffset = Creator.Icon(Window.Icon)[2].ImageRectPosition
					-- ImageLabel.ImageRectSize = Creator.Icon(Window.Icon)[2].ImageRectSize
					OpenButtonIcon.Image = Creator.Icon(Window.Icon)[1]
					OpenButtonIcon.ImageRectOffset = Creator.Icon(Window.Icon)[2].ImageRectPosition
					OpenButtonIcon.ImageRectSize = Creator.Icon(Window.Icon)[2].ImageRectSize
				end
				-- end
			else
				OpenButtonIcon.Visible = false
			end
		end)

		function Window:SetToggleKey(keycode)
			Window.ToggleKey = keycode
		end

		function Window:SetBackgroundImage(id)
			Window.UIElements.Main.Background.ImageLabel.Image = id
		end
		function Window:SetBackgroundImageTransparency(v)
			Window.UIElements.Main.Background.ImageLabel.ImageTransparency = v
			Window.BackgroundImageTransparency = v
		end

		local CurrentPos
		local CurrentSize
		local iconCopy = Creator.Icon("minimize")
		local iconSquare = Creator.Icon("maximize")

		local StartTime = 0
		function Window:Open()
			local ActualTime = tick()
			if ActualTime - StartTime < 0.75 then return end
			StartTime = ActualTime

			task.spawn(pcall, function()
				task.wait(.06)
				Window.Closed = false

				Tween(Window.UIElements.Main.Background, 0.2, {
					ImageTransparency = Config.Transparent and Config.WindUI.TransparencyValue or 0,
				}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()

				Tween(Window.UIElements.Main.Background, 0.4, {
					Size = UDim2.new(1,0,1,0),
				}, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out):Play()

				Tween(Window.UIElements.Main.Background.ImageLabel, 0.2, {ImageTransparency = Window.BackgroundImageTransparency}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
				--Tween(Window.UIElements.Main.Background.UIScale, 0.2, {Scale = 1}, Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()
				Tween(Blur, 0.25, {ImageTransparency = .7}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
				if UIStroke then
					Tween(UIStroke, 0.25, {Transparency = .8}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
				end

				task.spawn(function()
					task.wait(.5)
					Tween(BottomDragFrame, .45, {Size = UDim2.new(0,200,0,4), ImageTransparency = .8}, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out):Play()
					Tween(ResizeHandle.ImageLabel, .45, {ImageTransparency = .8}, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out):Play()
					task.wait(.45)
					WindowDragModule:Set(true)
					Window.CanResize = true
				end)


				Window.CanDropdown = true

				Window.UIElements.Main.Visible = true
				task.spawn(function()
					task.wait(.19)
					Window.UIElements.Main.Main.Visible = true
				end)
			end)
		end

		function Window:Close(...)
			local Pack = table.pack(...)
			if Pack.n ~= 3 or #Pack ~= 0 then
				local ActualTime = tick()
				if ActualTime - StartTime < 0.75 then return end
				StartTime = ActualTime
			end

			local Close = {}

			if not Window.UIElements.Main then
				return
			elseif not Window.UIElements.Main:FindFirstChild("Main") then
				return
			end

			if Window.OnCloseCallback then
				task.spawn(Creator.SafeCallback, Window.OnCloseCallback)
			end

			Window.UIElements.Main.Main.Visible = false
			Window.CanDropdown = false
			Window.Closed = true

			Tween(Window.UIElements.Main.Background, 0.32, {
				ImageTransparency = 1,
			}, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut):Play()

			Tween(Window.UIElements.Main.Background, 0.4, {
				Size = UDim2.new(1,0,1,-240),
			}, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut):Play()

			--Tween(Window.UIElements.Main.Background.UIScale, 0.19, {Scale = .95}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
			Tween(Window.UIElements.Main.Background.ImageLabel, 0.2, {ImageTransparency = 1}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
			Tween(Blur, 0.25, {ImageTransparency = 1}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
			if UIStroke then
				Tween(UIStroke, 0.25, {Transparency = 1}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
			end

			Tween(BottomDragFrame, .3, {Size = UDim2.new(0,0,0,4), ImageTransparency = 1}, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut):Play()
			Tween(ResizeHandle.ImageLabel, .3, {ImageTransparency = 1}, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out):Play()
			WindowDragModule:Set(false)
			Window.CanResize = false

			task.spawn(function()
				task.wait(0.4)
				Window.UIElements.Main.Visible = false
			end)

			function Close:Destroy()
				if Window.OnDestroyCallback then
					task.spawn(Creator.SafeCallback, Window.OnDestroyCallback)
				end
				Window.Destroyed = true
				task.wait(0.4)
				Config.Parent.Parent:Destroy()

				--Creator.DisconnectAll()
			end

			return Close
		end

		local FullscreenButton

		FullscreenButton = Window:CreateTopbarButton("Fullscreen", "maximize", function() 
			local isFullscreen = Window.IsFullscreen
			-- Creator.SetDraggable(isFullscreen)
			WindowDragModule:Set(isFullscreen)

			if not isFullscreen then
				CurrentPos = Window.UIElements.Main.Position
				CurrentSize = Window.UIElements.Main.Size
				FullscreenButton.ImageLabel.Image = iconCopy[1]
				FullscreenButton.ImageLabel.ImageRectOffset = iconCopy[2].ImageRectPosition
				FullscreenButton.ImageLabel.ImageRectSize = iconCopy[2].ImageRectSize
				Window.CanResize = false
			else
				FullscreenButton.ImageLabel.Image = iconSquare[1]
				FullscreenButton.ImageLabel.ImageRectOffset = iconSquare[2].ImageRectPosition
				FullscreenButton.ImageLabel.ImageRectSize = iconSquare[2].ImageRectSize
				Window.CanResize = true
			end

			Tween(Window.UIElements.Main, 0.45, {Size = isFullscreen and CurrentSize or UDim2.new(1,-20,1,-20-52)}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()

			Tween(Window.UIElements.Main, 0.45, {Position = isFullscreen and CurrentPos or UDim2.new(0.5,0,0.5,52/2)}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
			-- delay(0, function()
			-- end)

			Window.IsFullscreen = not isFullscreen
		end, 998)
		Window:CreateTopbarButton("Minimize", "minus", function() 
			Window:Close()
			task.spawn(function()
				task.wait(.3)
				if not IsPC and Window.IsOpenButtonEnabled then
					OpenButtonContainer.Visible = true
				end
			end)

			local NotifiedText = IsPC and "Press " .. Window.ToggleKey.Name .. " to open the Window" or "Click the Button to open the Window"

			if not Window.IsOpenButtonEnabled then
				Notified = true
			end
			if not Notified then
				Notified = not Notified
				Config.WindUI:Notify({
					Title = "Minimize",
					Content = "You've closed the Window. " .. NotifiedText,
					Icon = "eye-off",
					Duration = 5,
				})
			end
		end, 997)

		function Window:OnClose(func)
			Window.OnCloseCallback = func
		end
		function Window:OnDestroy(func)
			Window.OnDestroyCallback = func
		end

		function Window:ToggleTransparency(Value)
			-- Config.Transparent = Value
			Window.Transparent = Value
			Config.WindUI.Transparent = Value

			Window.UIElements.Main.Background.ImageTransparency = Value and Config.WindUI.TransparencyValue or 0
			-- Window.UIElements.Main.Background.ImageLabel.ImageTransparency = Value and Config.WindUI.TransparencyValue or 0
			Window.UIElements.MainBar.Background.ImageTransparency = Value and 0.97 or 0.95

		end


		if not IsPC and Window.IsOpenButtonEnabled then
			Creator.AddSignal(OpenButton.TextButton.MouseButton1Click, function()
				OpenButtonContainer.Visible = false
				Window:Open()
			end)
		end

		Creator.AddSignal(UserInputService.InputBegan, function(input, isProcessed)
			if isProcessed then return end

			if input.KeyCode == Window.ToggleKey then
				if Window.Closed then
					Window:Open()
				else
					Window:Close()
				end
			end
		end)

		task.spawn(Window.Open, Window)

		function Window:EditOpenButton(OpenButtonConfig)
			-- fuck
			--task.wait()
			if OpenButton and OpenButton.Parent ~= nil then
				local OpenButtonModule = {
					Title = OpenButtonConfig.Title,
					Icon = OpenButtonConfig.Icon or Window.Icon,
					Enabled = OpenButtonConfig.Enabled,
					Position = OpenButtonConfig.Position,
					Draggable = OpenButtonConfig.Draggable,
					OnlyMobile = OpenButtonConfig.OnlyMobile,
					CornerRadius = OpenButtonConfig.CornerRadius or UDim.new(1, 0),
					StrokeThickness = OpenButtonConfig.StrokeThickness or 2,
					Color = OpenButtonConfig.Color 
						or ColorSequence.new(Color3.fromHex("40c9ff"), Color3.fromHex("e81cff")),
				}

				-- wtf lol

				if OpenButtonModule.Enabled == false then
					Window.IsOpenButtonEnabled = false
				end
				if OpenButtonModule.Draggable == false and OpenButtonDrag and OpenButtonDivider then
					OpenButtonDrag.Visible = OpenButtonModule.Draggable
					OpenButtonDivider.Visible = OpenButtonModule.Draggable

					if OpenButtonDragModule then
						OpenButtonDragModule:Set(OpenButtonModule.Draggable)
					end
				end
				if OpenButtonModule.Position and OpenButtonContainer then
					OpenButtonContainer.Position = OpenButtonModule.Position
					--OpenButtonContainer.AnchorPoint = Vector2.new(0,0)
				end

				local IsPC = UserInputService.KeyboardEnabled or not UserInputService.TouchEnabled
				OpenButton.Visible = not OpenButtonModule.OnlyMobile or not IsPC

				if not OpenButton.Visible then return end

				if OpenButtonTitle then
					if OpenButtonModule.Title then
						OpenButtonTitle.Text = OpenButtonModule.Title
					elseif OpenButtonModule.Title == nil then
						--OpenButtonTitle.Visible = false
					end
				end

				if Creator.Icon(OpenButtonModule.Icon) and OpenButtonIcon then
					OpenButtonIcon.Visible = true
					OpenButtonIcon.Image = Creator.Icon(OpenButtonModule.Icon)[1]
					OpenButtonIcon.ImageRectOffset = Creator.Icon(OpenButtonModule.Icon)[2].ImageRectPosition
					OpenButtonIcon.ImageRectSize = Creator.Icon(OpenButtonModule.Icon)[2].ImageRectSize
				end

				OpenButton.UIStroke.UIGradient.Color = OpenButtonModule.Color
				if Glow then
					Glow.UIGradient.Color = OpenButtonModule.Color
				end

				OpenButton.UICorner.CornerRadius = OpenButtonModule.CornerRadius
				OpenButton.TextButton.UICorner.CornerRadius = UDim.new(OpenButtonModule.CornerRadius.Scale, OpenButtonModule.CornerRadius.Offset-4)
				OpenButton.UIStroke.Thickness = OpenButtonModule.StrokeThickness
			end
		end

		local Mouse = LocalPlayer:GetMouse()

		local Creator = NormalCreator
		local New = Creator.New
		local Tween = Creator.Tween

		local UI = NormalUI
		local CreateButton = UI.Button
		local CreateScrollSlider = UI.ScrollSlider


		TabModuleMain = {
			Window = nil,
			WindUI = nil,
			Tabs = {}, 
			Containers = {},
			SelectedTab = nil,
			TabCount = 0,
			ToolTipParent = nil,
			TabHighlight = nil,

			OnChangeFunc = function(v) end
		}

		function TabModuleMain.Init(Window, WindUI, ToolTipParent, TabHighlight)
			TabModuleMain.Window = Window
			TabModuleMain.WindUI = WindUI
			TabModuleMain.ToolTipParent = ToolTipParent
			TabModuleMain.TabHighlight = TabHighlight
			return TabModuleMain
		end

		function TabModuleMain.New(Config)
			local Tab = {
				__type = "Tab",
				Title = Config.Title or "Tab",
				Desc = Config.Desc,
				Icon = Config.Icon,
				IconSize = Config.IconSize,
				IconThemed = Config.IconThemed,
				Locked = Config.Locked,
				ShowTabTitle = Config.ShowTabTitle,
				Selected = false,
				Index = nil,
				Parent = Config.Parent,
				UIElements = {},
				Elements = {},
				ContainerFrame = nil,
			}

			local Window = TabModuleMain.Window
			local WindUI = TabModuleMain.WindUI

			TabModuleMain.TabCount = TabModuleMain.TabCount + 1
			local TabIndex = TabModuleMain.TabCount
			Tab.Index = TabIndex

			Tab.UIElements.Main = New("TextButton", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1,-7,0,0),
				AutomaticSize = "Y",
				Parent = Config.Parent
			}, {
				New("UIListLayout", {
					SortOrder = "LayoutOrder",
					Padding = UDim.new(0,10),
					FillDirection = "Horizontal",
					VerticalAlignment = "Center",
				}),
				New("TextLabel", {
					Text = Tab.Title,
					ThemeTag = {
						TextColor3 = "Text"
					},
					TextTransparency = not Tab.Locked and 0.4 or .7,
					TextSize = 15,
					Size = UDim2.new(1,0,0,0),
					FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
					TextWrapped = true,
					RichText = true,
					AutomaticSize = "Y",
					LayoutOrder = 2,
					TextXAlignment = "Left",
					BackgroundTransparency = 1,
				}),
				New("UIPadding", {
					PaddingTop = UDim.new(0,6),
					PaddingBottom = UDim.new(0,6),
				})
			})

			local TextOffset = 0
			local Icon

			--	Tab.UIElements.Main.TextLabel:GetPropertyChangedSignal("TextBounds"):Connect(function()
			--	    Tab.UIElements.Main.TextLabel.Size = UDim2.new(1,0,0,Tab.UIElements.Main.TextLabel.TextBounds.Y)
			--	    Tab.UIElements.Main.Size = UDim2.new(1,TextOffset,0,Tab.UIElements.Main.TextLabel.TextBounds.Y+6+6)
			--	end)

			if Tab.Icon then
				Icon = Creator.Image(
					Tab.IconSize,
					Tab.Icon,
					Tab.Icon .. ":" .. Tab.Title,
					0,
					Tab.__type,
					true,
					Tab.IconThemed
				)
				Icon.Size = UDim2.new(0,18,0,18)
				Icon.Parent = Tab.UIElements.Main
				Icon.ImageLabel.ImageTransparency = not Tab.Locked and 0 or .7
				Tab.UIElements.Main.TextLabel.Size = UDim2.new(1,-30,0,0)
				TextOffset = -30

				Tab.UIElements.Icon = Icon
			end

			Tab.UIElements.ContainerFrame = New("ScrollingFrame", {
				Size = UDim2.new(1,0,1,Tab.ShowTabTitle and -((Window.UIPadding*2.4)+12) or 0),
				BackgroundTransparency = 1,
				ScrollBarThickness = 0,
				ElasticBehavior = "Never",
				CanvasSize = UDim2.new(0,0,0,0),
				AnchorPoint = Vector2.new(0,1),
				Position = UDim2.new(0,0,1,0),
				AutomaticCanvasSize = "Y",
				--Visible = false,
				ScrollingDirection = "Y",
			}, {
				New("UIPadding", {
					PaddingTop = UDim.new(0,Window.UIPadding*1.2),
					PaddingLeft = UDim.new(0,Window.UIPadding*1.2),
					PaddingRight = UDim.new(0,Window.UIPadding*1.2),
					PaddingBottom = UDim.new(0,Window.UIPadding*1.2),
				}),
				New("UIListLayout", {
					SortOrder = "LayoutOrder",
					Padding = UDim.new(0,6),
					HorizontalAlignment = "Center",
				})
			})

			-- Tab.UIElements.ContainerFrame.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			--     Tab.UIElements.ContainerFrame.CanvasSize = UDim2.new(0,0,0,Tab.UIElements.ContainerFrame.UIListLayout.AbsoluteContentSize.Y+Window.UIPadding*2)
			-- end)

			Tab.UIElements.ContainerFrameCanvas = New("Frame", {
				Size = UDim2.new(1,0,1,0),
				BackgroundTransparency = 1,
				Visible = false,
				Parent = Window.UIElements.MainBar,
				ZIndex = 5,
			}, {
				Tab.UIElements.ContainerFrame,
				New("Frame", {
					Size = UDim2.new(1,0,0,((Window.UIPadding*2.4)+12)),
					BackgroundTransparency = 1,
					Visible = Tab.ShowTabTitle or false,
					Name = "TabTitle"
				}, {
					Icon and Icon:Clone(),
					New("TextLabel", {
						Text = Tab.Title,
						ThemeTag = {
							TextColor3 = "Text"
						},
						TextSize = 20,
						TextTransparency = .1,
						Size = UDim2.new(1,0,1,0),
						FontFace = Font.new(Creator.Font, Enum.FontWeight.SemiBold),
						TextTruncate = "AtEnd",
						RichText = true,
						LayoutOrder = 2,
						TextXAlignment = "Left",
						BackgroundTransparency = 1,
					}),
					New("UIPadding", {
						PaddingTop = UDim.new(0,Window.UIPadding*1.2),
						PaddingLeft = UDim.new(0,Window.UIPadding*1.2),
						PaddingRight = UDim.new(0,Window.UIPadding*1.2),
						PaddingBottom = UDim.new(0,Window.UIPadding*1.2),
					}),
					New("UIListLayout", {
						SortOrder = "LayoutOrder",
						Padding = UDim.new(0,10),
						FillDirection = "Horizontal",
						VerticalAlignment = "Center",
					})
				}),
				New("Frame", {
					Size = UDim2.new(1,0,0,1),
					BackgroundTransparency = .9,
					ThemeTag = {
						BackgroundColor3 = "Text"
					},
					Position = UDim2.new(0,0,0,((Window.UIPadding*2.4)+12)),
					Visible = Tab.ShowTabTitle or false,
				})
			})

			TabModuleMain.Containers[TabIndex] = Tab.UIElements.ContainerFrameCanvas
			TabModuleMain.Tabs[TabIndex] = Tab

			Tab.ContainerFrame = Tab.UIElements.ContainerFrameCanvas

			Creator.AddSignal(Tab.UIElements.Main.MouseButton1Click, function()
				if not Tab.Locked then
					TabModuleMain:SelectTab(TabIndex)
				end
			end)

			-- soon
			CreateScrollSlider(Tab.UIElements.ContainerFrame, Tab.UIElements.ContainerFrameCanvas, Window, 3)


			-- ToolTip
			if Tab.Desc then
				local ToolTip
				local hoverTimer
				local MouseConn
				local IsHovering = false

				local function removeToolTip()
					IsHovering = false
					if hoverTimer then
						task.cancel(hoverTimer)
						hoverTimer = nil
					end
					if MouseConn then
						MouseConn:Disconnect()
						MouseConn = nil
					end
					if ToolTip then
						ToolTip:Close()
						ToolTip = nil
					end
				end

				Creator.AddSignal(Tab.UIElements.Main.InputBegan, function()
					IsHovering = true
					hoverTimer = task.spawn(function()
						task.wait(0.35)
						if IsHovering and not ToolTip then
							ToolTip = UI.ToolTip(Tab.Desc, TabModuleMain.ToolTipParent)

							local function updatePosition()
								if ToolTip then
									ToolTip.Container.Position = UDim2.new(0, Mouse.X, 0, Mouse.Y - 20)
								end
							end

							updatePosition()
							MouseConn = Mouse.Move:Connect(updatePosition)
							ToolTip:Open()
						end
					end)
				end)

				Creator.AddSignal(Tab.UIElements.Main.InputEnded, removeToolTip)
			end
			-- WTF

			local Elements = {
				Button      = (function()
					local Creator = NormalCreator
					local New = Creator.New

					local Element = {}

					function Element:New(Config)
						local Button = {
							__type = "Button",
							Title = Config.Title or "Button",
							Desc = Config.Desc or nil,
							Locked = Config.Locked or false,
							Callback = Config.Callback or function() end,
							UIElements = {}
						}

						local CanCallback = true

						Button.ButtonFrame = NormalElement({
							Title = Button.Title,
							Desc = Button.Desc,
							Parent = Config.Parent,
							-- Image = Config.Image,
							-- ImageSize = Config.ImageSize,  
							-- Thumbnail = Config.Thumbnail,
							-- ThumbnailSize = Config.ThumbnailSize,
							Window = Config.Window,
							TextOffset = 20,
							Hover = true,
							Scalable = true,
						})

						Button.UIElements.ButtonIcon = New("ImageLabel",{
							Image = Creator.Icon("mouse-pointer-click")[1],
							ImageRectOffset = Creator.Icon("mouse-pointer-click")[2].ImageRectPosition,
							ImageRectSize = Creator.Icon("mouse-pointer-click")[2].ImageRectSize,
							BackgroundTransparency = 1,
							Parent = Button.ButtonFrame.UIElements.Main,
							Size = UDim2.new(0,20,0,20),
							AnchorPoint = Vector2.new(1,0.5),
							Position = UDim2.new(1,0,0.5,0),
							ThemeTag = {
								ImageColor3 = "Text"
							}
						})

						function Button:Lock()
							CanCallback = false
							return Button.ButtonFrame:Lock()
						end
						function Button:Unlock()
							CanCallback = true
							return Button.ButtonFrame:Unlock()
						end

						if Button.Locked then
							Button:Lock()
						end

						Creator.AddSignal(Button.ButtonFrame.UIElements.Main.MouseButton1Click, function()
							if CanCallback then
								task.spawn(Creator.SafeCallback, Button.Callback)
							end
						end)
						return Button.__type, Button
					end

					return Element	
				end)(),
				Toggle      = (function()
					local Creator = NormalCreator
					local New = Creator.New
					local Tween = Creator.Tween

					local UIComponent = NormalUI
					local CreateToggle = UIComponent.Toggle 
					local CreateCheckbox = UIComponent.Checkbox 

					local Element = {}

					function Element:New(Config)
						local Toggle = {
							__type = "Toggle",
							Title = Config.Title or "Toggle",
							Desc = Config.Desc or nil,
							Value = Config.Value,
							Icon = Config.Icon or nil,
							Type = Config.Type or "Toggle",
							Locked = Config.Locked or false,
							Callback = Config.Callback or function() end,
							UIElements = {}
						}
						Toggle.ToggleFrame = NormalElement({
							Title = Toggle.Title,
							Desc = Toggle.Desc,
							-- Image = Config.Image,
							-- ImageSize = Config.ImageSize,  
							-- Thumbnail = Config.Thumbnail,
							-- ThumbnailSize = Config.ThumbnailSize,
							Window = Config.Window,
							Parent = Config.Parent,
							TextOffset = 44,
							Hover = false,
						})

						local CanCallback = true

						if Toggle.Value == nil then
							Toggle.Value = false
						end

						function Toggle:Lock()
							CanCallback = false
							return Toggle.ToggleFrame:Lock()
						end
						function Toggle:Unlock()
							CanCallback = true
							return Toggle.ToggleFrame:Unlock()
						end

						if Toggle.Locked then
							Toggle:Lock()
						end

						local Toggled = Toggle.Value

						local ToggleFrame, ToggleFunc
						if Toggle.Type == "Toggle" then
							ToggleFrame, ToggleFunc = CreateToggle(Toggled, Toggle.Icon, Toggle.ToggleFrame.UIElements.Main, Toggle.Callback)
						elseif Toggle.Type == "Checkbox" then
							ToggleFrame, ToggleFunc = CreateCheckbox(Toggled, Toggle.Icon, Toggle.ToggleFrame.UIElements.Main, Toggle.Callback)
						else
							error("Unknown Toggle Type: " .. tostring(Toggle.Type))
						end

						ToggleFrame.AnchorPoint = Vector2.new(1,0.5)
						ToggleFrame.Position = UDim2.new(1,0,0.5,0)

						function Toggle:Set(v)
							if CanCallback then
								ToggleFunc:Set(v)
								Toggled = v
								Toggle.Value = v
							end
						end

						Toggle:Set(Toggled)

						Creator.AddSignal(Toggle.ToggleFrame.UIElements.Main.MouseButton1Click, function()
							Toggle:Set(not Toggled)
						end)

						return Toggle.__type, Toggle
					end

					return Element
				end)(),
				Slider      = (function()
					local Creator = NormalCreator
					local New = Creator.New
					local Tween = Creator.Tween

					local Element = {}

					local HoldingSlider = false

					function Element:New(Config)
						local Slider = {
							__type = "Slider",
							Title = Config.Title or "Slider",
							Desc = Config.Desc or nil,
							Locked = Config.Locked or nil,
							Value = Config.Value or {},
							Step = Config.Step or 1,
							Callback = Config.Callback or function() end,
							UIElements = {},
							IsFocusing = false,
						}
						local isTouch
						local moveconnection
						local releaseconnection
						local Value = Slider.Value.Default or Slider.Value.Min or 0

						local LastValue = Value
						local delta = (Value - (Slider.Value.Min or 0)) / ((Slider.Value.Max or 100) - (Slider.Value.Min or 0))

						local CanCallback = true
						local IsFloat = Slider.Step % 1 ~= 0

						local function FormatValue(val)
							if IsFloat then
								return string.format("%.2f", val)
							else
								return tostring(math.floor(val + 0.5))
							end
						end

						local function CalculateValue(rawValue)
							if IsFloat then
								return math.floor(rawValue / Slider.Step + 0.5) * Slider.Step
							else
								return math.floor(rawValue / Slider.Step + 0.5) * Slider.Step
							end
						end

						Slider.SliderFrame = NormalElement({
							Title = Slider.Title,
							Desc = Slider.Desc,
							Parent = Config.Parent,
							TextOffset = 0,
							Hover = false,
						})

						Slider.UIElements.SliderIcon = Creator.NewRoundFrame(99, "Squircle", {
							ImageTransparency = .95,
							Size = UDim2.new(1, -60-8, 0, 4),
							Name = "Frame",
							ThemeTag = {
								ImageColor3 = "Text",
							},
						}, {
							Creator.NewRoundFrame(99, "Squircle", {
								Name = "Frame",
								Size = UDim2.new(delta, 0, 1, 0),
								ImageTransparency = .1,
								ThemeTag = {
									ImageColor3 = "Button",
								},
							}, {
								Creator.NewRoundFrame(99, "Squircle", {
									Size = UDim2.new(0, 13, 0, 13),
									Position = UDim2.new(1, 0, 0.5, 0),
									AnchorPoint = Vector2.new(0.5, 0.5),
									ThemeTag = {
										ImageColor3 = "Text",
									},
								})
							})
						})

						Slider.UIElements.SliderContainer = New("Frame", {
							Size = UDim2.new(1, 0, 0, 0),
							AutomaticSize = "Y",
							Position = UDim2.new(0, 0, 0, 0),
							BackgroundTransparency = 1,
							Parent = Slider.SliderFrame.UIElements.Container,
						}, {
							New("UIListLayout", {
								Padding = UDim.new(0, 8),
								FillDirection = "Horizontal",
								VerticalAlignment = "Center",
							}),
							Slider.UIElements.SliderIcon,
							New("TextBox", {
								Size = UDim2.new(0,60,0,0),
								TextXAlignment = "Left",
								Text = FormatValue(Value),
								ThemeTag = {
									TextColor3 = "Text"
								},
								TextTransparency = .4,
								AutomaticSize = "Y",
								TextSize = 15,
								FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
								BackgroundTransparency = 1,
								LayoutOrder = -1,
							})
						})

						function Slider:Lock()
							CanCallback = false
							return Slider.SliderFrame:Lock()
						end
						function Slider:Unlock()
							CanCallback = true
							return Slider.SliderFrame:Unlock()
						end

						if Slider.Locked then
							Slider:Lock()
						end

						function Slider:Set(Value, input)
							if CanCallback then
								if not Slider.IsFocusing and not HoldingSlider and (not input or (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch)) then
									Value = math.clamp(Value, Slider.Value.Min or 0, Slider.Value.Max or 100)

									local delta = math.clamp((Value - (Slider.Value.Min or 0)) / ((Slider.Value.Max or 100) - (Slider.Value.Min or 0)), 0, 1)
									Value = CalculateValue(Slider.Value.Min + delta * (Slider.Value.Max - Slider.Value.Min))

									if Value ~= LastValue then
										Tween(Slider.UIElements.SliderIcon.Frame, 0.08, {Size = UDim2.new(delta,0,1,0)}):Play()
										Slider.UIElements.SliderContainer.TextBox.Text = FormatValue(Value)
										Slider.Value.Default = FormatValue(Value)
										LastValue = Value
										Creator.SafeCallback(Slider.Callback, FormatValue(Value))
									end

									if input then
										isTouch = (input.UserInputType == Enum.UserInputType.Touch)
										Slider.SliderFrame.Parent.ScrollingEnabled = false
										HoldingSlider = true
										moveconnection = RunService.RenderStepped:Connect(function()
											local inputPosition = isTouch and input.Position.X or UserInputService:GetMouseLocation().X
											local delta = math.clamp((inputPosition - Slider.UIElements.SliderIcon.AbsolutePosition.X) / Slider.UIElements.SliderIcon.AbsoluteSize.X, 0, 1)
											Value = CalculateValue(Slider.Value.Min + delta * (Slider.Value.Max - Slider.Value.Min))

											if Value ~= LastValue then
												Tween(Slider.UIElements.SliderIcon.Frame, 0.08, {Size = UDim2.new(delta,0,1,0)}):Play()
												Slider.UIElements.SliderContainer.TextBox.Text = FormatValue(Value)
												Slider.Value.Default = FormatValue(Value)
												LastValue = Value
												Creator.SafeCallback(Slider.Callback, FormatValue(Value))
											end
										end)
										releaseconnection = UserInputService.InputEnded:Connect(function(endInput)
											if (endInput.UserInputType == Enum.UserInputType.MouseButton1 or endInput.UserInputType == Enum.UserInputType.Touch) and input == endInput then
												moveconnection:Disconnect()
												releaseconnection:Disconnect()
												HoldingSlider = false
												Slider.SliderFrame.Parent.ScrollingEnabled = true
											end
										end)
									end
								end
							end
						end

						Creator.AddSignal(Slider.UIElements.SliderContainer.TextBox.FocusLost, function(enterPressed)
							if enterPressed then
								local newValue = tonumber(Slider.UIElements.SliderContainer.TextBox.Text)
								if newValue then
									Slider:Set(newValue)
								else
									Slider.UIElements.SliderContainer.TextBox.Text = FormatValue(LastValue)
								end
							end
						end)

						Creator.AddSignal(Slider.UIElements.SliderContainer.InputBegan, function(input)
							Slider:Set(Value, input)
						end)

						return Slider.__type, Slider
					end

					return Element
				end)(),
				Keybind     = (function()
					local Creator = NormalCreator
					local New = Creator.New
					local Tween = Creator.Tween

					local Element = {
						UICorner = 6,
						UIPadding = 8,
					}

					local UIComponent = NormalUI
					local CreateLabel = UIComponent.Label 

					function Element:New(Config)
						local Keybind = {
							__type = "Keybind",
							Title = Config.Title or "Keybind",
							Desc = Config.Desc or nil,
							Locked = Config.Locked or false,
							Value = Config.Value or "F",
							Callback = Config.Callback or function() end,
							CanChange = Config.CanChange or true,
							Picking = false,
							UIElements = {},
						}

						local CanCallback = true

						Keybind.KeybindFrame = NormalElement({
							Title = Keybind.Title,
							Desc = Keybind.Desc,
							Parent = Config.Parent,
							TextOffset = 85,
							Hover = Keybind.CanChange,
						})

						Keybind.UIElements.Keybind = CreateLabel(Keybind.Value, nil, Keybind.KeybindFrame.UIElements.Main)

						Keybind.UIElements.Keybind.Size = UDim2.new(
							0,
							12+12+Keybind.UIElements.Keybind.Frame.Frame.TextLabel.TextBounds.X,
							0,
							42
						)
						Keybind.UIElements.Keybind.AnchorPoint = Vector2.new(1,0.5)
						Keybind.UIElements.Keybind.Position = UDim2.new(1,0,0.5,0)

						New("UIScale", {
							Parent = Keybind.UIElements.Keybind,
							Scale = .85,
						})

						Creator.AddSignal(Keybind.UIElements.Keybind.Frame.Frame.TextLabel:GetPropertyChangedSignal("TextBounds"), function()
							Keybind.UIElements.Keybind.Size = UDim2.new(
								0,
								12+12+Keybind.UIElements.Keybind.Frame.Frame.TextLabel.TextBounds.X,
								0,
								42
							)
						end)

						function Keybind:Lock()
							CanCallback = false
							return Keybind.KeybindFrame:Lock()
						end
						function Keybind:Unlock()
							CanCallback = true
							return Keybind.KeybindFrame:Unlock()
						end

						function Keybind:Set(v)
							Keybind.Value = v
							Keybind.UIElements.Keybind.Frame.Frame.TextLabel.Text = v

							Creator.SafeCallback(Keybind.Callback, Keybind.Value)
						end

						if Keybind.Locked then
							Keybind:Lock()
						end

						Creator.AddSignal(Keybind.KeybindFrame.UIElements.Main.MouseButton1Click, function()
							if CanCallback then
								if Keybind.CanChange then
									Keybind.Picking = true
									Keybind.UIElements.Keybind.Frame.Frame.TextLabel.Text = "..."

									task.wait(0.2)

									local Event
									Event = UserInputService.InputBegan:Connect(function(Input)
										local Key

										if Input.UserInputType == Enum.UserInputType.Keyboard then
											Key = Input.KeyCode.Name
										elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
											Key = "MouseLeft"
										elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
											Key = "MouseRight"
										end

										local EndedEvent
										EndedEvent = UserInputService.InputEnded:Connect(function(Input)
											if Input.KeyCode.Name == Key or Key == "MouseLeft" and Input.UserInputType == Enum.UserInputType.MouseButton1 or Key == "MouseRight" and Input.UserInputType == Enum.UserInputType.MouseButton2 then
												Keybind.Picking = false

												Keybind.UIElements.Keybind.Frame.Frame.TextLabel.Text = Key
												Keybind.Value = Key

												Event:Disconnect()
												EndedEvent:Disconnect()
											end
										end)
									end)
								end
							end
						end) 
						Creator.AddSignal(UserInputService.InputBegan, function(input)
							if CanCallback then
								if input.KeyCode.Name == Keybind.Value then
									Creator.SafeCallback(Keybind.Callback, input.KeyCode.Name)
								end
							end
						end)
						return Keybind.__type, Keybind
					end

					return Element
				end)(),
				Input       = (function()
					local Creator = NormalCreator
					local New = Creator.New
					local Tween = Creator.Tween

					local Element = {
						UICorner = 8,
						UIPadding = 8,
					}


					local UIComponent = NormalUI
					local CreateButton = UIComponent.Button
					local CreateInput = UIComponent.Input 

					function Element:New(Config)
						local Input = {
							__type = "Input",
							Title = Config.Title or "Input",
							Desc = Config.Desc or nil,
							Type = Config.Type or "Input", -- Input or Textarea
							Locked = Config.Locked or false,
							InputIcon = Config.InputIcon or false,
							PlaceholderText = Config.Placeholder or "Enter Text...",
							Value = Config.Value or "",
							Callback = Config.Callback or function() end,
							ClearTextOnFocus = Config.ClearTextOnFocus or false,
							UIElements = {},
						}

						local CanCallback = true

						Input.InputFrame = NormalElement({
							Title = Input.Title,
							Desc = Input.Desc,
							Parent = Config.Parent,
							TextOffset = 0,
							Hover = false,
						})

						local InputComponent
						function Input:Set(v)
							if CanCallback then
								Creator.SafeCallback(Input.Callback, v)

								InputComponent.Frame.Frame.TextBox.Text = v
								Input.Value = v
							end
						end

						InputComponent = CreateInput(Input.PlaceholderText, Input.InputIcon, Input.InputFrame.UIElements.Container, Input.Type, function(v)
							Input:Set(v)
						end)

						InputComponent.Size = UDim2.new(1,0,0,Input.Type == "Input" and 42 or 42+56+50)

						New("UIScale", {
							Parent = InputComponent,
							Scale = 1,
						})

						function Input:Lock()
							CanCallback = false
							return Input.InputFrame:Lock()
						end
						function Input:Unlock()
							CanCallback = true
							return Input.InputFrame:Unlock()
						end

						Input:Set(Input.Value)

						if Input.Locked then
							Input:Lock()
						end

						return Input.__type, Input
					end

					return Element	
				end)(),
				Dropdown    = (function()
					local Mouse = LocalPlayer:GetMouse()
					local Camera = Workspace.CurrentCamera

					local Creator = NormalCreator
					local New = Creator.New
					local Tween = Creator.Tween

					local UIComponent = NormalUI
					local CreateLabel = UIComponent.Label 

					local Element = {
						UICorner = 10,
						UIPadding = 12,
						MenuCorner = 15,
						MenuPadding = 5,
						TabPadding = 6,
					}

					function Element:New(Config)
						local Dropdown = {
							__type = "Dropdown",
							Title = Config.Title or "Dropdown",
							Desc = Config.Desc or nil,
							Locked = Config.Locked or false,
							Values = Config.Values or {},
							Value = Config.Value,
							AllowNone = Config.AllowNone,
							Multi = Config.Multi,
							Callback = Config.Callback or function() end,

							UIElements = {},

							Opened = false,
							Tabs = {}
						}

						local CanCallback = true

						Dropdown.DropdownFrame = NormalElement({
							Title = Dropdown.Title,
							Desc = Dropdown.Desc,
							Parent = Config.Parent,
							TextOffset = 0,
							Hover = false,
						})


						Dropdown.UIElements.Dropdown = CreateLabel("", nil, Dropdown.DropdownFrame.UIElements.Container)

						Dropdown.UIElements.Dropdown.Frame.Frame.TextLabel.TextTruncate = "AtEnd"
						Dropdown.UIElements.Dropdown.Frame.Frame.TextLabel.Size = UDim2.new(1, Dropdown.UIElements.Dropdown.Frame.Frame.TextLabel.Size.X.Offset - 18 - 12 - 12,0,0)

						Dropdown.UIElements.Dropdown.Size = UDim2.new(1,0,0,40)

						-- New("UIScale", {
						--     Parent = Dropdown.UIElements.Dropdown,
						--     Scale = .85,
						-- })

						local DropdownIcon = New("ImageLabel", {
							Image = Creator.Icon("chevrons-up-down")[1],
							ImageRectOffset = Creator.Icon("chevrons-up-down")[2].ImageRectPosition,
							ImageRectSize = Creator.Icon("chevrons-up-down")[2].ImageRectSize,
							Size = UDim2.new(0,18,0,18),
							Position = UDim2.new(1,-12,0.5,0),
							ThemeTag = {
								ImageColor3 = "Icon"
							},
							AnchorPoint = Vector2.new(1,0.5),
							Parent = Dropdown.UIElements.Dropdown.Frame
						})

						Dropdown.UIElements.UIListLayout = New("UIListLayout", {
							Padding = UDim.new(0,Element.MenuPadding/1.5),
							FillDirection = "Vertical"
						})

						Dropdown.UIElements.Menu = Creator.NewRoundFrame(Element.MenuCorner, "Squircle", {
							ThemeTag = {
								ImageColor3 = "Background",
							},
							ImageTransparency = 0.05,
							Size = UDim2.new(1,0,1,0),
							AnchorPoint = Vector2.new(1,0),
							Position = UDim2.new(1,0,0,0),
						}, {
							New("UIPadding", {
								PaddingTop = UDim.new(0, Element.MenuPadding),
								PaddingLeft = UDim.new(0, Element.MenuPadding),
								PaddingRight = UDim.new(0, Element.MenuPadding),
								PaddingBottom = UDim.new(0, Element.MenuPadding),
							}),
							New("CanvasGroup", {
								BackgroundTransparency = 1,
								Size = UDim2.new(1,0,1,0),
								--Name = "CanvasGroup",
								ClipsDescendants = true
							}, {
								New("UICorner", {
									CornerRadius = UDim.new(0,Element.MenuCorner - Element.MenuPadding),
								}),
								New("ScrollingFrame", {
									Size = UDim2.new(1,0,1,0),
									ScrollBarThickness = 0,
									ScrollingDirection = "Y",
									AutomaticCanvasSize = "Y",
									CanvasSize = UDim2.new(0,0,0,0),
									BackgroundTransparency = 1,
									ScrollBarImageTransparency = 1,
								}, {
									Dropdown.UIElements.UIListLayout,
								})
							})
						})

						Dropdown.UIElements.MenuCanvas = New("CanvasGroup", {
							Size = UDim2.new(0,190,0,300),
							BackgroundTransparency = 1,
							Position = UDim2.new(-10,0,-10,0),
							Visible = false,
							Active = false,
							GroupTransparency = 1, -- 0
							Parent = Config.WindUI.DropdownGui,
							AnchorPoint = Vector2.new(1,0),
						}, {
							Dropdown.UIElements.Menu,
							-- New("UIPadding", {
							--     PaddingTop = UDim.new(0,1),
							--     PaddingLeft = UDim.new(0,1),
							--     PaddingRight = UDim.new(0,1),
							--     PaddingBottom = UDim.new(0,1),
							-- }),
							New("UISizeConstraint", {
								MinSize = Vector2.new(190,0)
							})
						})

						function Dropdown:Lock()
							CanCallback = false
							return Dropdown.DropdownFrame:Lock()
						end
						function Dropdown:Unlock()
							CanCallback = true
							return Dropdown.DropdownFrame:Unlock()
						end

						if Dropdown.Locked then
							Dropdown:Lock()
						end

						local function RecalculateCanvasSize()
							Dropdown.UIElements.Menu.CanvasGroup.ScrollingFrame.CanvasSize = UDim2.fromOffset(0, Dropdown.UIElements.UIListLayout.AbsoluteContentSize.Y)
						end

						local function RecalculateListSize()
							if #Dropdown.Values > 10 then
								Dropdown.UIElements.MenuCanvas.Size = UDim2.fromOffset(Dropdown.UIElements.UIListLayout.AbsoluteContentSize.X, 392)
							else
								Dropdown.UIElements.MenuCanvas.Size = UDim2.fromOffset(Dropdown.UIElements.UIListLayout.AbsoluteContentSize.X, Dropdown.UIElements.UIListLayout.AbsoluteContentSize.Y + Element.MenuPadding)
							end
						end

						local function UpdatePosition()
							local button = Dropdown.UIElements.Dropdown
							local menu = Dropdown.UIElements.MenuCanvas

							local availableSpaceBelow = Camera.ViewportSize.Y - (button.AbsolutePosition.Y + button.AbsoluteSize.Y) - Element.MenuPadding - 54
							local requiredSpace = menu.AbsoluteSize.Y + Element.MenuPadding

							local offset = -54 -- topbar offset
							if availableSpaceBelow < requiredSpace then
								offset = requiredSpace - availableSpaceBelow - 54
							end

							menu.Position = UDim2.new(
								0, 
								button.AbsolutePosition.X + button.AbsoluteSize.X,
								0, 
								button.AbsolutePosition.Y + button.AbsoluteSize.Y - offset + Element.MenuPadding 
							)
						end

						function Dropdown:Display()
							local Values = Dropdown.Values
							local Str = ""

							if Dropdown.Multi then
								for Idx, Value in next, Values do
									if table.find(Dropdown.Value, Value) then
										Str = Str .. Value .. ", "
									end
								end
								Str = Str:sub(1, #Str - 2)
							else
								Str = Dropdown.Value or ""
							end

							Dropdown.UIElements.Dropdown.Frame.Frame.TextLabel.Text = (Str == "" and "--" or Str)
						end

						function Dropdown:Refresh(Values)
							for _, Elementt in next, Dropdown.UIElements.Menu.CanvasGroup.ScrollingFrame:GetChildren() do
								if not Elementt:IsA("UIListLayout") then
									Elementt:Destroy()
								end
							end

							Dropdown.Tabs = {}

							for Index,Tab in next, Values do
								--task.wait(0.012)
								local TabMain = {
									Name = Tab,
									Selected = false,
									UIElements = {},
								}
								TabMain.UIElements.TabItem = New("TextButton", {
									Size = UDim2.new(1,0,0,34),
									--AutomaticSize = "Y",
									BackgroundTransparency = 1,
									Parent = Dropdown.UIElements.Menu.CanvasGroup.ScrollingFrame,
									Text = "",

								}, {
									New("UIPadding", {
										PaddingTop = UDim.new(0,Element.TabPadding),
										PaddingLeft = UDim.new(0,Element.TabPadding+2),
										PaddingRight = UDim.new(0,Element.TabPadding+2),
										PaddingBottom = UDim.new(0,Element.TabPadding),
									}),
									New("UICorner", {
										CornerRadius = UDim.new(0,Element.MenuCorner - Element.MenuPadding)
									}),
									New("ImageLabel", {
										Image = Creator.Icon("check")[1],
										ImageRectSize = Creator.Icon("check")[2].ImageRectSize,
										ImageRectOffset = Creator.Icon("check")[2].ImageRectPosition,
										ThemeTag = {
											ImageColor3 = "Text",
										},
										ImageTransparency = 1, -- .1
										Size = UDim2.new(0,18,0,18),
										AnchorPoint = Vector2.new(0,0.5),
										Position = UDim2.new(0,0,0.5,0),
										BackgroundTransparency = 1,
									}),
									New("TextLabel", {
										Text = Tab,
										TextXAlignment = "Left",
										FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
										ThemeTag = {
											TextColor3 = "Text",
											BackgroundColor3 = "Text"
										},
										TextSize = 15,
										BackgroundTransparency = 1,
										TextTransparency = .4,
										AutomaticSize = "Y",
										TextTruncate = "AtEnd",
										Size = UDim2.new(1,-18-Element.TabPadding*3,0,0),
										AnchorPoint = Vector2.new(0,0.5),
										Position = UDim2.new(0,0,0.5,0), -- 0,18+Element.TabPadding,0.5,0
									})
								})


								if Dropdown.Multi then
									TabMain.Selected = table.find(Dropdown.Value or {}, TabMain.Name)
								else
									TabMain.Selected = Dropdown.Value == TabMain.Name
								end

								if TabMain.Selected then
									TabMain.UIElements.TabItem.BackgroundTransparency = .93
									TabMain.UIElements.TabItem.ImageLabel.ImageTransparency = .1
									TabMain.UIElements.TabItem.TextLabel.Position = UDim2.new(0,18+Element.TabPadding+2,0.5,0)
									TabMain.UIElements.TabItem.TextLabel.TextTransparency = 0
								end

								Dropdown.Tabs[Index] = TabMain

								Dropdown:Display()

								local function Callback()
									Dropdown:Display()
									task.spawn(Creator.SafeCallback, Dropdown.Callback, Dropdown.Value)
								end

								Creator.AddSignal(TabMain.UIElements.TabItem.MouseButton1Click, function()
									if Dropdown.Multi then
										if not TabMain.Selected then
											TabMain.Selected = true
											Tween(TabMain.UIElements.TabItem, 0.1, {BackgroundTransparency = .93}):Play()
											Tween(TabMain.UIElements.TabItem.ImageLabel, 0.1, {ImageTransparency = .1}):Play()
											Tween(TabMain.UIElements.TabItem.TextLabel, 0.1, {Position = UDim2.new(0,18+Element.TabPadding,0.5,0), TextTransparency = 0}):Play()
											table.insert(Dropdown.Value, TabMain.Name)
										else
											if not Dropdown.AllowNone and #Dropdown.Value == 1 then
												return
											end
											TabMain.Selected = false
											Tween(TabMain.UIElements.TabItem, 0.1, {BackgroundTransparency = 1}):Play()
											Tween(TabMain.UIElements.TabItem.ImageLabel, 0.1, {ImageTransparency = 1}):Play()
											Tween(TabMain.UIElements.TabItem.TextLabel, 0.1, {Position = UDim2.new(0,0,0.5,0), TextTransparency = .4}):Play()
											for i, v in ipairs(Dropdown.Value) do
												if v == TabMain.Name then
													table.remove(Dropdown.Value, i)
													break
												end
											end
										end
									else
										for Index, TabPisun in next, Dropdown.Tabs do
											-- pisun
											Tween(TabPisun.UIElements.TabItem, 0.1, {BackgroundTransparency = 1}):Play()
											Tween(TabPisun.UIElements.TabItem.ImageLabel, 0.1, {ImageTransparency = 1}):Play()
											Tween(TabPisun.UIElements.TabItem.TextLabel, 0.1, {Position = UDim2.new(0,0,0.5,0), TextTransparency = .4}):Play()
											TabPisun.Selected = false
										end
										TabMain.Selected = true
										Tween(TabMain.UIElements.TabItem, 0.1, {BackgroundTransparency = .93}):Play()
										Tween(TabMain.UIElements.TabItem.ImageLabel, 0.1, {ImageTransparency = .1}):Play()
										Tween(TabMain.UIElements.TabItem.TextLabel, 0.1, {Position = UDim2.new(0,18+Element.TabPadding,0.5,0), TextTransparency = 0}):Play()
										Dropdown.Value = TabMain.Name
									end
									Callback()
								end)

								RecalculateCanvasSize()
								RecalculateListSize()

								Callback()
							end
						end

						Dropdown:Refresh(Dropdown.Values)

						function Dropdown:Select(Items)
							if Items then
								Dropdown.Value = Items
							end
							Dropdown:Refresh(Dropdown.Values)
						end

						--Dropdown:Display()
						RecalculateListSize()

						function Dropdown:Open()
							Dropdown.UIElements.MenuCanvas.Visible = true
							Dropdown.UIElements.MenuCanvas.Active = true
							Dropdown.UIElements.Menu.Size = UDim2.new(
								1, 0,
								0, 0
							)
							Tween(Dropdown.UIElements.Menu, 0.1, {
								Size = UDim2.new(
									1, 0,
									1, 0
								)
							}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out):Play()

							task.spawn(function()
								task.wait(.1)
								Dropdown.Opened = true
							end)

							--Tween(DropdownIcon, .15, {Rotation = 180}):Play()
							Tween(Dropdown.UIElements.MenuCanvas, .15, {GroupTransparency = 0}):Play()

							UpdatePosition()
						end
						function Dropdown:Close()
							Dropdown.Opened = false

							Tween(Dropdown.UIElements.Menu, 0.1, {
								Size = UDim2.new(
									1, 0,
									0.8, 0
								)
							}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out):Play()
							--Tween(DropdownIcon, .15, {Rotation = 0}):Play()
							Tween(Dropdown.UIElements.MenuCanvas, .15, {GroupTransparency = 1}):Play()
							task.wait(.1)
							Dropdown.UIElements.MenuCanvas.Visible = false
							Dropdown.UIElements.MenuCanvas.Active = false
						end

						Creator.AddSignal(Dropdown.UIElements.Dropdown.MouseButton1Click, function()
							if CanCallback then
								Dropdown:Open()
							end
						end)

						Creator.AddSignal(UserInputService.InputBegan, function(Input)
							if
								Input.UserInputType == Enum.UserInputType.MouseButton1
								or Input.UserInputType == Enum.UserInputType.Touch
							then
								local AbsPos, AbsSize = Dropdown.UIElements.MenuCanvas.AbsolutePosition, Dropdown.UIElements.MenuCanvas.AbsoluteSize
								if
									Config.Window.CanDropdown
									and Dropdown.Opened
									and (Mouse.X < AbsPos.X
										or Mouse.X > AbsPos.X + AbsSize.X
										or Mouse.Y < (AbsPos.Y - 20 - 1)
										or Mouse.Y > AbsPos.Y + AbsSize.Y
									)
								then
									Dropdown:Close()
								end
							end
						end)

						Creator.AddSignal(Dropdown.UIElements.Dropdown:GetPropertyChangedSignal("AbsolutePosition"), UpdatePosition)

						task.spawn(Creator.SafeCallback, Dropdown.Callback, Dropdown.Value)

						return Dropdown.__type, Dropdown
					end

					return Element
				end)(),
				Code        = (function()
					local Creator = NormalCreator
					local New = Creator.New
					local UI = NormalUI

					local Element = {}

					function Element:New(Config)
						local Code = {
							__type = "Code",
							Title = Config.Title,
							Code = Config.Code,
							Locked = Config.Locked or false,
							UIElements = {}
						}

						local CanCallback = not Code.Locked

						-- Code.CodeFrame = NormalElement({
						--     Title = Code.Title,
						--     Desc = Code.Code,
						--     Parent = Config.Parent,
						--     TextOffset = 40,
						--     Hover = false,
						-- })

						-- Code.CodeFrame.UIElements.Main.Title.Desc:Destroy()

						local CodeElement = UI.Code(Code.Code, Code.Title, Config.Parent, function()
							if CanCallback then
								local NewTitle = Code.Title or "code"
								local success, result = pcall(function()
									toclipboard(Code.Code)
								end)
								if success then
									Config.WindUI:Notify({
										Title = "Success",
										Content = "The " .. NewTitle .. " copied to your clipboard.",
										Icon = "check",
										Duration = 5,
									})
								else
									Config.WindUI:Notify({
										Title = "Error",
										Content = "The " .. NewTitle .. " is not copied. Error: " .. result,
										Icon = "x",
										Duration = 5,
									})
								end
							end
						end)

						function Code:SetCode(code)
							CodeElement.Set(code)
						end

						return Code.__type, Code
					end

					return Element
				end)(),
				Colorpicker = (function()
					local Creator = NormalCreator
					local New = Creator.New
					local Tween = Creator.Tween

					local RenderStepped = RunService.RenderStepped
					local Mouse = LocalPlayer:GetMouse()

					local UIComponent = NormalUI
					local CreateButton = UIComponent.Button
					local CreateInput = UIComponent.Input 

					local Element = {
						UICorner = 8,
						UIPadding = 8
					}

					function Element:Colorpicker(Config, OnApply)
						local Colorpicker = {
							__type = "Colorpicker",
							Title = Config.Title,
							Desc = Config.Desc,
							Default = Config.Default,
							Callback = Config.Callback,
							Transparency = Config.Transparency,
							UIElements = Config.UIElements,
						}

						function Colorpicker:SetHSVFromRGB(Color)
							local H, S, V = toHSV(Color)
							Colorpicker.Hue = H
							Colorpicker.Sat = S
							Colorpicker.Vib = V
						end

						Colorpicker:SetHSVFromRGB(Colorpicker.Default)

						local ColorpickerModule = NormalDialog.Init(Config.Window)
						local ColorpickerFrame = ColorpickerModule.Create()

						Colorpicker.ColorpickerFrame = ColorpickerFrame

						--ColorpickerFrame:Close()

						local Hue, Sat, Vib = Colorpicker.Hue, Colorpicker.Sat, Colorpicker.Vib

						Colorpicker.UIElements.Title = New("TextLabel", {
							Text = Colorpicker.Title,
							TextSize = 20,
							FontFace = Font.new(Creator.Font, Enum.FontWeight.SemiBold),
							TextXAlignment = "Left",
							Size = UDim2.new(1,0,0,0),
							AutomaticSize = "Y",
							ThemeTag = {
								TextColor3 = "Text"
							},
							BackgroundTransparency = 1,
							Parent = ColorpickerFrame.UIElements.Main
						})

						-- Colorpicker.UIElements.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
						--     Colorpicker.UIElements.Title.Size = UDim2.new(1,0,0,Colorpicker.UIElements.Title.TextBounds.Y)
						-- end)

						local SatCursor = New("ImageLabel", {
							Size = UDim2.new(0, 18, 0, 18),
							ScaleType = Enum.ScaleType.Fit,
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundTransparency = 1,
							Image = "http://www.roblox.com/asset/?id=4805639000",
						})

						Colorpicker.UIElements.SatVibMap = New("ImageLabel", {
							Size = UDim2.fromOffset(160, 182-24),
							Position = UDim2.fromOffset(0, 40),
							Image = "rbxassetid://78352573121806",
							BackgroundColor3 = Color3.fromHSV(Hue, 1, 1),
							BackgroundTransparency = 0,
							Parent = ColorpickerFrame.UIElements.Main,
						}, {
							New("UICorner", {
								CornerRadius = UDim.new(0,8),
							}),
							New("UIStroke", {
								Thickness = .6,
								ThemeTag = {
									Color = "Text"
								},
								Transparency = .8,
							}),
							SatCursor,
						})

						Colorpicker.UIElements.Inputs = New("Frame", {
							AutomaticSize = "XY",
							Size = UDim2.new(0,0,0,0),
							Position = UDim2.fromOffset(Colorpicker.Transparency and 160+10+10+10+10+10+10+20 or 160+10+10+10+20, 40),
							BackgroundTransparency = 1,
							Parent = ColorpickerFrame.UIElements.Main
						}, {
							New("UIListLayout", {
								Padding = UDim.new(0, 5),
								FillDirection = "Vertical",
							})
						})

						--	Colorpicker.UIElements.Inputs.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
						--         Colorpicker.UIElements.Inputs.Size = UDim2.new(0,Colorpicker.UIElements.Inputs.UIListLayout.AbsoluteContentSize.X,0,Colorpicker.UIElements.Inputs.UIListLayout.AbsoluteContentSize.Y)
						--     end)

						local OldColorFrame = New("Frame", {
							BackgroundColor3 = Colorpicker.Default,
							Size = UDim2.fromScale(1, 1),
							BackgroundTransparency = Colorpicker.Transparency,
						}, {
							New("UICorner", {
								CornerRadius = UDim.new(0, 8),
							}),
						})

						local OldColorFrameChecker = New("ImageLabel", {
							Image = "http://www.roblox.com/asset/?id=14204231522",
							ImageTransparency = 0.45,
							ScaleType = Enum.ScaleType.Tile,
							TileSize = UDim2.fromOffset(40, 40),
							BackgroundTransparency = 1,
							Position = UDim2.fromOffset(75+10, 40+182-24+10),
							Size = UDim2.fromOffset(75, 24),
							Parent = ColorpickerFrame.UIElements.Main,
						}, {
							New("UICorner", {
								CornerRadius = UDim.new(0, 8),
							}),
							New("UIStroke", {
								Thickness = 1,
								Transparency = 0.8,
								ThemeTag = {
									Color = "Text"
								}
							}),
							OldColorFrame,
						})

						local NewDisplayFrame = New("Frame", {
							BackgroundColor3 = Colorpicker.Default,
							Size = UDim2.fromScale(1, 1),
							BackgroundTransparency = 0,
							ZIndex = 9,
						}, {
							New("UICorner", {
								CornerRadius = UDim.new(0, 8),
							}),
						})

						local NewDisplayFrameChecker = New("ImageLabel", {
							Image = "http://www.roblox.com/asset/?id=14204231522",
							ImageTransparency = 0.45,
							ScaleType = Enum.ScaleType.Tile,
							TileSize = UDim2.fromOffset(40, 40),
							BackgroundTransparency = 1,
							Position = UDim2.fromOffset(0, 40+182-24+10),
							Size = UDim2.fromOffset(75, 24),
							Parent = ColorpickerFrame.UIElements.Main,
						}, {
							New("UICorner", {
								CornerRadius = UDim.new(0, 8),
							}),
							New("UIStroke", {
								Thickness = 1,
								Transparency = 0.8,
								ThemeTag = {
									Color = "Text"
								}
							}),
							NewDisplayFrame,
						})

						local SequenceTable = {}

						for Color = 0, 1, 0.1 do
							table.insert(SequenceTable, ColorSequenceKeypoint.new(Color, Color3.fromHSV(Color, 1, 1)))
						end

						local HueSliderGradient = New("UIGradient", {
							Color = ColorSequence.new(SequenceTable),
							Rotation = 90,
						})

						local HueDragHolder = New("Frame", {
							Size = UDim2.new(1, 0, 1, 0),
							Position = UDim2.new(0,0,0,0),
							BackgroundTransparency = 1,
						})

						local HueDrag = New("Frame", {
							Size = UDim2.new(0,14,0,14),
							AnchorPoint = Vector2.new(0.5,0.5),
							Position = UDim2.new(0.5,0,0,0),
							Parent = HueDragHolder,
							--Image = "rbxassetid://18747052224",
							--ScaleType = "Crop",
							BackgroundColor3 = Colorpicker.Default
						}, {
							New("UIStroke", {
								Thickness = 2,
								Transparency = .1,
								ThemeTag = {
									Color = "Text",
								},
							}),
							New("UICorner", {
								CornerRadius = UDim.new(1,0),
							})
						})

						local HueSlider = New("Frame", {
							Size = UDim2.fromOffset(10, 182+10),
							Position = UDim2.fromOffset(160+10+10, 40),
							Parent = ColorpickerFrame.UIElements.Main,
						}, {
							New("UICorner", {
								CornerRadius = UDim.new(1,0),
							}),
							HueSliderGradient,
							HueDragHolder,
						})


						local function CreateNewInput(Title, Value)
							local InputFrame = CreateInput(Title, nil, Colorpicker.UIElements.Inputs)

							New("TextLabel", {
								BackgroundTransparency = 1,
								TextTransparency = .4,
								TextSize = 17,
								FontFace = Font.new(Creator.Font, Enum.FontWeight.Regular),
								AutomaticSize = "XY",
								ThemeTag = {
									TextColor3 = "Placeholder",
								},
								AnchorPoint = Vector2.new(1,0.5),
								Position = UDim2.new(1,-12,0.5,0),
								Parent = InputFrame.Frame,
								Text = Title,
							})

							New("UIScale", {
								Parent = InputFrame,
								Scale = .85,
							})

							InputFrame.Frame.Frame.TextBox.Text = Value
							InputFrame.Size = UDim2.new(0,30*5,0,42)

							return InputFrame
						end

						local function ToRGB(color)
							return {
								R = math.floor(color.R * 255),
								G = math.floor(color.G * 255),
								B = math.floor(color.B * 255)
							}
						end

						local HexInput = CreateNewInput("Hex", "#" .. Colorpicker.Default:ToHex())

						local RedInput = CreateNewInput("Red", ToRGB(Colorpicker.Default)["R"])
						local GreenInput = CreateNewInput("Green", ToRGB(Colorpicker.Default)["G"])
						local BlueInput = CreateNewInput("Blue", ToRGB(Colorpicker.Default)["B"])
						local AlphaInput
						if Colorpicker.Transparency then
							AlphaInput = CreateNewInput("Alpha", ((1 - Colorpicker.Transparency) * 100) .. "%")
						end

						local ButtonsContent = New("Frame", {
							Size = UDim2.new(1,0,0,40),
							AutomaticSize = "Y",
							Position = UDim2.new(0,0,0,40+8+182+24),
							BackgroundTransparency = 1,
							Parent = ColorpickerFrame.UIElements.Main,
							LayoutOrder = 4,
						}, {
							New("UIListLayout", {
								Padding = UDim.new(0, 8),
								FillDirection = "Horizontal",
								HorizontalAlignment = "Right",
							}),
						})

						local Buttons = {
							{
								Title = "Cancel",
								Variant = "Secondary",
								Callback = function() end
							},
							{
								Title = "Apply",
								Icon = "chevron-right",
								Variant = "Primary",
								Callback = function() OnApply(Color3.fromHSV(Colorpicker.Hue, Colorpicker.Sat, Colorpicker.Vib), Colorpicker.Transparency) end
							}
						}

						for _,Button in next, Buttons do
							CreateButton(Button.Title, Button.Icon, Button.Callback, Button.Variant, ButtonsContent, ColorpickerFrame)
						end


						--	for _,Button in next, Buttons do
						--         local ButtonFrame = New("TextButton", {
						--             Text = Button.Title or "Button",
						--             TextSize = 14,
						--             FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
						--             ThemeTag = {
						--                 TextColor3 = "Text",
						--                 BackgroundColor3 = "Text",
						--             },
						--             BackgroundTransparency = .9,
						--             ZIndex = 999999,
						--             Parent = ButtonsContent,
						--             Size = UDim2.new(1 / #Buttons, -(((#Buttons - 1) * 8) / #Buttons), 0, 0),
						--             AutomaticSize = "Y",
						--         }, {
						--             New("UICorner", {
						--                 CornerRadius = UDim.new(0, ColorpickerFrame.UICorner-7),
						--             }),
						--             New("UIPadding", {
						--                 PaddingTop = UDim.new(0, ColorpickerFrame.UIPadding/1.6),
						--                 PaddingLeft = UDim.new(0, ColorpickerFrame.UIPadding/1.6),
						--                 PaddingRight = UDim.new(0, ColorpickerFrame.UIPadding/1.6),
						--                 PaddingBottom = UDim.new(0, ColorpickerFrame.UIPadding/1.6),
						--             }),
						--             New("Frame", {
						--                 Size = UDim2.new(1,(ColorpickerFrame.UIPadding/1.6)*2,1,(ColorpickerFrame.UIPadding/1.6)*2),
						--                 Position = UDim2.new(0.5,0,0.5,0),
						--                 AnchorPoint = Vector2.new(0.5,0.5),
						--                 ThemeTag = {
						--                     BackgroundColor3 = "Text"
						--                 },
						--                 BackgroundTransparency = 1, -- .9
						--             }, {
						--                 New("UICorner", {
						--                     CornerRadius = UDim.new(0, ColorpickerFrame.UICorner-7),
						--                 }),
						--             })
						--         })



						--         ButtonFrame.MouseEnter:Connect(function()
						--             Tween(ButtonFrame.Frame, 0.1, {BackgroundTransparency = .9}):Play()
						--         end)
						--         ButtonFrame.MouseLeave:Connect(function()
						--             Tween(ButtonFrame.Frame, 0.1, {BackgroundTransparency = 1}):Play()
						--         end)
						--         ButtonFrame.MouseButton1Click:Connect(function()
						--             ColorpickerFrame:Close()
						--             task.spawn(function()
						--                 Button.Callback()
						--             end)
						--         end)
						--	end


						local TransparencySlider, TransparencyDrag, TransparencyColor
						if Colorpicker.Transparency then
							local TransparencyDragHolder = New("Frame", {
								Size = UDim2.new(1, 0, 1, 0),
								Position = UDim2.fromOffset(0, 0),
								BackgroundTransparency = 1,
							})

							TransparencyDrag = New("ImageLabel", {
								Size = UDim2.new(0,14,0,14),
								AnchorPoint = Vector2.new(0.5,0.5),
								Position = UDim2.new(0.5,0,0,0),
								ThemeTag = {
									BackgroundColor3 = "Text",
								},
								Parent = TransparencyDragHolder,

							}, {
								New("UIStroke", {
									Thickness = 2,
									Transparency = .1,
									ThemeTag = {
										Color = "Text",
									},
								}),
								New("UICorner", {
									CornerRadius = UDim.new(1,0),
								})

							})

							TransparencyColor = New("Frame", {
								Size = UDim2.fromScale(1, 1),
							}, {
								New("UIGradient", {
									Transparency = NumberSequence.new({
										NumberSequenceKeypoint.new(0, 0),
										NumberSequenceKeypoint.new(1, 1),
									}),
									Rotation = 270,
								}),
								New("UICorner", {
									CornerRadius = UDim.new(0, 6),
								}),
							})

							TransparencySlider = New("Frame", {
								Size = UDim2.fromOffset(10, 182+10),
								Position = UDim2.fromOffset(160+10+10+10+10+10, 40),
								Parent = ColorpickerFrame.UIElements.Main,
								BackgroundTransparency = 1,
							}, {
								New("UICorner", {
									CornerRadius = UDim.new(1, 0),
								}),
								New("ImageLabel", {
									Image = "rbxassetid://139109456610417",
									ImageTransparency = 0.45,
									ScaleType = Enum.ScaleType.Tile,
									TileSize = UDim2.fromOffset(40, 40),
									BackgroundTransparency = 1,
									Size = UDim2.fromScale(1, 1),
								}, {
									New("UICorner", {
										CornerRadius = UDim.new(1,0),
									}),
								}),
								TransparencyColor,
								TransparencyDragHolder,
							})
						end

						function Colorpicker:Round(Number, Factor)
							if Factor == 0 then
								return math.floor(Number)
							end
							Number = tostring(Number)
							return Number:find("%.") and tonumber(Number:sub(1, Number:find("%.") + Factor)) or Number
						end


						function Colorpicker:Update(color, transparency)
							if color then Hue, Sat, Vib = toHSV(color) else Hue, Sat, Vib = Colorpicker.Hue,Colorpicker.Sat,Colorpicker.Vib end

							Colorpicker.UIElements.SatVibMap.BackgroundColor3 = Color3.fromHSV(Hue, 1, 1)
							SatCursor.Position = UDim2.new(Sat, 0, 1 - Vib, 0)
							NewDisplayFrame.BackgroundColor3 = Color3.fromHSV(Hue, Sat, Vib)
							HueDrag.BackgroundColor3 = Color3.fromHSV(Hue, 1, 1)
							HueDrag.Position = UDim2.new(0.5, 0, Hue, 0)

							HexInput.Frame.Frame.TextBox.Text = "#" .. Color3.fromHSV(Hue, Sat, Vib):ToHex()
							RedInput.Frame.Frame.TextBox.Text = ToRGB(Color3.fromHSV(Hue, Sat, Vib))["R"]
							GreenInput.Frame.Frame.TextBox.Text = ToRGB(Color3.fromHSV(Hue, Sat, Vib))["G"]
							BlueInput.Frame.Frame.TextBox.Text = ToRGB(Color3.fromHSV(Hue, Sat, Vib))["B"]

							if transparency or Colorpicker.Transparency then
								NewDisplayFrame.BackgroundTransparency =  Colorpicker.Transparency or transparency
								TransparencyColor.BackgroundColor3 = Color3.fromHSV(Hue, Sat, Vib)
								TransparencyDrag.BackgroundColor3 = Color3.fromHSV(Hue, Sat, Vib)
								TransparencyDrag.BackgroundTransparency =  Colorpicker.Transparency or transparency
								TransparencyDrag.Position = UDim2.new(0.5, 0, 1 -  Colorpicker.Transparency or transparency, 0)
								AlphaInput.Frame.Frame.TextBox.Text = Colorpicker:Round((1 - Colorpicker.Transparency or transparency) * 100, 0) .. "%"
							end
						end

						Colorpicker:Update(Colorpicker.Default, Colorpicker.Transparency)




						local function GetRGB()
							local Value = Color3.fromHSV(Colorpicker.Hue, Colorpicker.Sat, Colorpicker.Vib)
							return { R = math.floor(Value.r * 255), G = math.floor(Value.g * 255), B = math.floor(Value.b * 255) }
						end

						-- oh no!

						local function clamp(val, min, max)
							return math.clamp(tonumber(val) or 0, min, max)
						end

						Creator.AddSignal(HexInput.Frame.Frame.TextBox.FocusLost, function(Enter)
							if Enter then
								local hex = HexInput.Frame.Frame.TextBox.Text:gsub("#", "")
								local Success, Result = pcall(Color3.fromHex, hex)
								if Success and typeof(Result) == "Color3" then
									Colorpicker.Hue, Colorpicker.Sat, Colorpicker.Vib = toHSV(Result)
									Colorpicker:Update()
									Colorpicker.Default = Result
								end
							end
						end)

						local function updateColorFromInput(inputBox, component)
							Creator.AddSignal(inputBox.Frame.Frame.TextBox.FocusLost, function(Enter)
								if Enter then
									local textBox = inputBox.Frame.Frame.TextBox
									local current = GetRGB()
									local clamped = clamp(textBox.Text, 0, 255)
									textBox.Text = tostring(clamped)

									current[component] = clamped
									local Result = Color3.fromRGB(current.R, current.G, current.B)
									Colorpicker.Hue, Colorpicker.Sat, Colorpicker.Vib = toHSV(Result)
									Colorpicker:Update()
								end
							end)
						end

						updateColorFromInput(RedInput, "R")
						updateColorFromInput(GreenInput, "G")
						updateColorFromInput(BlueInput, "B")

						if Colorpicker.Transparency then
							Creator.AddSignal(AlphaInput.Frame.Frame.TextBox.FocusLost, function(Enter)
								if Enter then
									local textBox = AlphaInput.Frame.Frame.TextBox
									local clamped = clamp(textBox.Text, 0, 100)
									textBox.Text = tostring(clamped)

									Colorpicker.Transparency = 1 - clamped * 0.01
									Colorpicker:Update(nil, Colorpicker.Transparency)
								end
							end)
						end

						-- fu

						local SatVibMap = Colorpicker.UIElements.SatVibMap
						Creator.AddSignal(SatVibMap.InputBegan, function(Input)
							if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
								while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
									local MinX = SatVibMap.AbsolutePosition.X
									local MaxX = MinX + SatVibMap.AbsoluteSize.X
									local MouseX = math.clamp(Mouse.X, MinX, MaxX)

									local MinY = SatVibMap.AbsolutePosition.Y
									local MaxY = MinY + SatVibMap.AbsoluteSize.Y
									local MouseY = math.clamp(Mouse.Y, MinY, MaxY)

									Colorpicker.Sat = (MouseX - MinX) / (MaxX - MinX)
									Colorpicker.Vib = 1 - ((MouseY - MinY) / (MaxY - MinY))
									Colorpicker:Update()

									RenderStepped:Wait()
								end
							end
						end)

						Creator.AddSignal(HueSlider.InputBegan, function(Input)
							if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
								while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
									local MinY = HueSlider.AbsolutePosition.Y
									local MaxY = MinY + HueSlider.AbsoluteSize.Y
									local MouseY = math.clamp(Mouse.Y, MinY, MaxY)

									Colorpicker.Hue = ((MouseY - MinY) / (MaxY - MinY))
									Colorpicker:Update()

									RenderStepped:Wait()
								end
							end
						end)

						if Colorpicker.Transparency then
							Creator.AddSignal(TransparencySlider.InputBegan, function(Input)
								if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
									while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
										local MinY = TransparencySlider.AbsolutePosition.Y
										local MaxY = MinY + TransparencySlider.AbsoluteSize.Y
										local MouseY = math.clamp(Mouse.Y, MinY, MaxY)

										Colorpicker.Transparency = 1 - ((MouseY - MinY) / (MaxY - MinY))
										Colorpicker:Update()

										RenderStepped:Wait()
									end
								end
							end)
						end

						return Colorpicker
					end

					function Element:New(Config) 
						local Colorpicker = {
							__type = "Colorpicker",
							Title = Config.Title or "Colorpicker",
							Desc = Config.Desc or nil,
							Locked = Config.Locked or false,
							Default = Config.Default or Color3.new(1,1,1),
							Callback = Config.Callback or function() end,
							Window = Config.Window,
							Transparency = Config.Transparency,
							UIElements = {}
						}

						local CanCallback = true


						Colorpicker.ColorpickerFrame = NormalElement({
							Title = Colorpicker.Title,
							Desc = Colorpicker.Desc,
							Parent = Config.Parent,
							TextOffset = 40,
							Hover = false,
						})

						Colorpicker.UIElements.Colorpicker = Creator.NewRoundFrame(Element.UICorner, "Squircle",{
							ImageTransparency = 0,
							Active = true,
							ImageColor3 = Colorpicker.Default,
							Parent = Colorpicker.ColorpickerFrame.UIElements.Main,
							Size = UDim2.new(0,30,0,30),
							AnchorPoint = Vector2.new(1,0.5),
							Position = UDim2.new(1,0,0.5,0),
							ZIndex = 2
						}, nil, true)


						function Colorpicker:Lock()
							CanCallback = false
							return Colorpicker.ColorpickerFrame:Lock()
						end
						function Colorpicker:Unlock()
							CanCallback = true
							return Colorpicker.ColorpickerFrame:Unlock()
						end

						if Colorpicker.Locked then
							Colorpicker:Lock()
						end


						function Colorpicker:Update(Color,Transparency)
							Colorpicker.UIElements.Colorpicker.ImageTransparency = Transparency or 0
							Colorpicker.UIElements.Colorpicker.ImageColor3 = Color
							Colorpicker.Default = Color
							if Transparency then
								Colorpicker.Transparency = Transparency
							end
						end

						function Colorpicker:Set(c,t)
							return Colorpicker:Update(c,t)
						end

						Creator.AddSignal(Colorpicker.UIElements.Colorpicker.MouseButton1Click, function()
							if CanCallback then
								Element:Colorpicker(Colorpicker, function(color, transparency)
									if CanCallback then
										Colorpicker:Update(color, transparency)
										Colorpicker.Default = color
										Colorpicker.Transparency = transparency
										Creator.SafeCallback(Colorpicker.Callback, color, transparency)
									end
								end).ColorpickerFrame:Open()
							end
						end)

						return Colorpicker.__type, Colorpicker
					end

					return Element
				end)(),
				Section     = (function()
					local Creator = NormalCreator
					local New = Creator.New
					local Tween = Creator.Tween

					local Element = {}

					function Element:New(Config)
						local Section = {
							__type = "Section",
							Title = Config.Title or "Section",
							Icon = Config.Icon,
							IconSize = Config.IconSize,
							TextXAlignment = Config.TextXAlignment or "Left",
							TextSize = Config.TextSize or 19,
							UIElements = {},
						}

						local Icon
						if Section.Icon then
							Icon = Creator.Image(
								Section.IconSize,
								Section.Icon,
								Section.Icon .. ":" .. Section.Title,
								0,
								Section.__type,
								true
							)
							Icon.Size = UDim2.new(0,24,0,24)
						end

						Section.UIElements.Main = New("TextLabel", {
							BackgroundTransparency = 1,
							TextXAlignment = "Left",
							AutomaticSize = "XY",
							TextSize = Section.TextSize,
							ThemeTag = {
								TextColor3 = "Text",
							},
							FontFace = Font.new(Creator.Font, Enum.FontWeight.SemiBold),
							--Parent = Config.Parent,
							--Size = UDim2.new(1,0,0,0),
							Text = Section.Title,
						})

						local Main = New("Frame", {
							Size = UDim2.new(1,0,0,0),
							BackgroundTransparency = 1,
							AutomaticSize = "Y",
							Parent = Config.Parent,
						}, {
							Icon,
							Section.UIElements.Main,
							New("UIListLayout", {
								Padding = UDim.new(0,8),
								FillDirection = "Horizontal",
								VerticalAlignment = "Center",
								HorizontalAlignment = Section.TextXAlignment,
							}),
							New("UIPadding", {
								PaddingTop = UDim.new(0,4),
								PaddingBottom = UDim.new(0,2),
							})
						})

						-- Section.UIElements.Main:GetPropertyChangedSignal("TextBounds"):Connect(function()
						--     Section.UIElements.Main.Size = UDim2.new(1,0,0,Section.UIElements.Main.TextBounds.Y)
						-- end)

						function Section:SetTitle(Title)
							Section.UIElements.Main.Text = Title
						end
						function Section:Destroy()
							Section.UIElements.Main.AutomaticSize = "None"
							Section.UIElements.Main.Size = UDim2.new(1,0,0,Section.UIElements.Main.TextBounds.Y)

							Tween(Section.UIElements.Main, .1, {TextTransparency = 1}):Play()
							task.wait(.1)
							Tween(Section.UIElements.Main, .15, {Size = UDim2.new(1,0,0,0)}, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut):Play()
						end

						return Section.__type, Section
					end

					return Element
				end)(),
			}

			function Tab:Divider()
				local Divider = New("Frame", {
					Size = UDim2.new(1,0,0,1),
					Position = UDim2.new(0.5,0,0.5,0),
					AnchorPoint = Vector2.new(0.5,0.5),
					BackgroundTransparency = .9,
					ThemeTag = {
						BackgroundColor3 = "Text"
					}
				})
				local MainDivider = New("Frame", {
					Parent = Tab.UIElements.ContainerFrame,
					Size = UDim2.new(1,-7,0,5),
					BackgroundTransparency = 1,
				}, {
					Divider
				})

				return MainDivider
			end

			function Tab:Paragraph(ElementConfig)  
				ElementConfig.Parent = Tab.UIElements.ContainerFrame  
				ElementConfig.Window = Window  
				ElementConfig.Hover = false  
				--ElementConfig.Color = ElementConfig.Color  
				ElementConfig.TextOffset = 0  
				ElementConfig.IsButtons = ElementConfig.Buttons and #ElementConfig.Buttons > 0 and true or false  

				local ParagraphModule = {  
					__type = "Paragraph",  
					Title = ElementConfig.Title or "Paragraph",  
					Desc = ElementConfig.Desc or nil,  
					--Color = ElementConfig.Color,  
					Locked = ElementConfig.Locked or false,  
				}  
				local Paragraph = NormalElement(ElementConfig)  

				ParagraphModule.ParagraphFrame = Paragraph  
				if ElementConfig.Buttons and #ElementConfig.Buttons > 0 then  
					local ButtonsContainer = New("Frame", {  
						Size = UDim2.new(0,0,0,38),  
						BackgroundTransparency = 1,  
						AutomaticSize = "Y",
						Parent = Paragraph.UIElements.Container
					}, {  
						New("UIListLayout", {  
							Padding = UDim.new(0,10),  
							FillDirection = "Vertical",  
						})  
					})  


					for _,Button in next, ElementConfig.Buttons do  
						local ButtonFrame = CreateButton(Button.Title, Button.Icon, Button.Callback, "White", ButtonsContainer)  
						ButtonFrame.Size = UDim2.new(0,0,0,38)  
						ButtonFrame.AutomaticSize = "X"  
					end
				end  

				function ParagraphModule:SetTitle(Title)  
					ParagraphModule.ParagraphFrame:SetTitle(Title)  
				end  
				function ParagraphModule:SetDesc(Title)  
					ParagraphModule.ParagraphFrame:SetDesc(Title)  
				end  
				function ParagraphModule:Destroy()  
					ParagraphModule.ParagraphFrame:Destroy()  
				end  

				table.insert(Tab.Elements, ParagraphModule)  
				return ParagraphModule  
			end  

			for name, module in pairs(Elements) do
				Tab[name] = function(self, config)
					config.Parent = self.UIElements.ContainerFrame
					config.Window = Window
					config.WindUI = WindUI

					local elementInstance, content = module:New(config)
					table.insert(self.Elements, content)

					local frame
					for key, value in pairs(content) do
						if typeof(value) == "table" and key:match("Frame$") then
							frame = value
							break
						end
					end

					if frame then
						function content:SetTitle(title)
							frame:SetTitle(title)
						end
						function content:SetDesc(desc)
							frame:SetDesc(desc)
						end
						function content:Destroy()
							frame:Destroy()
						end
					end
					return content
				end
			end


			task.spawn(function()
				local Empty = New("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1,0,1,-Window.UIElements.Main.Main.Topbar.AbsoluteSize.Y),
					Parent = Tab.UIElements.ContainerFrame
				}, {
					New("UIListLayout", {
						Padding = UDim.new(0,8),
						SortOrder = "LayoutOrder",
						VerticalAlignment = "Center",
						HorizontalAlignment = "Center",
						FillDirection = "Vertical",
					}), 
					New("ImageLabel", {
						Size = UDim2.new(0,48,0,48),
						Image = Creator.Icon("frown")[1],
						ImageRectOffset = Creator.Icon("frown")[2].ImageRectPosition,
						ImageRectSize = Creator.Icon("frown")[2].ImageRectSize,
						ThemeTag = {
							ImageColor3 = "Icon"
						},
						BackgroundTransparency = 1,
						ImageTransparency = .6,
					}),
					New("TextLabel", {
						AutomaticSize = "XY",
						Text = "This tab is empty",
						ThemeTag = {
							TextColor3 = "Text"
						},
						TextSize = 18,
						TextTransparency = .5,
						BackgroundTransparency = 1,
						FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
					})
				})

				-- Empty.TextLabel:GetPropertyChangedSignal("TextBounds"):Connect(function()
				--     Empty.TextLabel.Size = UDim2.new(0,Empty.TextLabel.TextBounds.X,0,Empty.TextLabel.TextBounds.Y)
				-- end)

				Creator.AddSignal(Tab.UIElements.ContainerFrame.ChildAdded, function()
					Empty.Visible = false
				end)
			end)

			return Tab
		end

		function TabModuleMain:OnChange(func)
			TabModuleMain.OnChangeFunc = func
		end

		function TabModuleMain:SelectTab(TabIndex)
			if not TabModuleMain.Tabs[TabIndex].Locked then
				TabModuleMain.SelectedTab = TabIndex

				for _, TabObject in next, TabModuleMain.Tabs do
					if not TabObject.Locked then
						Tween(TabObject.UIElements.Main.TextLabel, 0.15, {TextTransparency = 0.45}):Play()
						if TabObject.UIElements.Icon then
							Tween(TabObject.UIElements.Icon.ImageLabel, 0.15, {ImageTransparency = 0.5}):Play()
						end
						TabObject.Selected = false
					end
				end
				Tween(TabModuleMain.Tabs[TabIndex].UIElements.Main.TextLabel, 0.15, {TextTransparency = 0}):Play()
				if TabModuleMain.Tabs[TabIndex].UIElements.Icon then
					Tween(TabModuleMain.Tabs[TabIndex].UIElements.Icon.ImageLabel, 0.15, {ImageTransparency = 0.15}):Play()
				end
				TabModuleMain.Tabs[TabIndex].Selected = true

				Tween(TabModuleMain.TabHighlight, .25, {Position = UDim2.new(
					0,
					0,
					0,
					TabModuleMain.Tabs[TabIndex].UIElements.Main.AbsolutePosition.Y - TabModuleMain.Tabs[TabIndex].Parent.AbsolutePosition.Y
					), 
					Size = UDim2.new(1,-7,0,TabModuleMain.Tabs[TabIndex].UIElements.Main.AbsoluteSize.Y)
				}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()

				task.spawn(function()
					for _, ContainerObject in next, TabModuleMain.Containers do
						ContainerObject.AnchorPoint = Vector2.new(0,0.05)
						ContainerObject.Visible = false
					end
					TabModuleMain.Containers[TabIndex].Visible = true
					Tween(TabModuleMain.Containers[TabIndex], 0.15, {AnchorPoint = Vector2.new(0,0)}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out):Play()
				end)

				TabModuleMain.OnChangeFunc(TabIndex)
			end
		end

		local TabModule = TabModuleMain.Init(Window, Config.WindUI, Config.Parent.Parent.ToolTips, TabHighlight)
		TabModule:OnChange(function(t) Window.CurrentTab = t end)

		Window.TabModule = TabModuleMain

		function Window:Tab(TabConfig)
			TabConfig.Parent = Window.UIElements.SideBar.Frame
			return TabModule.New(TabConfig)
		end

		function Window:SelectTab(Tab)
			TabModule:SelectTab(Tab)
		end


		function Window:Divider()
			local Divider = New("Frame", {
				Size = UDim2.new(1,0,0,1),
				Position = UDim2.new(0.5,0,0,0),
				AnchorPoint = Vector2.new(0.5,0),
				BackgroundTransparency = .9,
				ThemeTag = {
					BackgroundColor3 = "Text"
				}
			})
			local MainDivider = New("Frame", {
				Parent = Window.UIElements.SideBar.Frame,
				--AutomaticSize = "Y",
				Size = UDim2.new(1,-7,0,1),
				BackgroundTransparency = 1,
			}, {
				Divider
			})

			return MainDivider
		end

		local DialogModule = NormalDialog.Init(Window)
		function Window:Dialog(DialogConfig)
			local DialogTable = {
				Title = DialogConfig.Title or "Dialog",
				Content = DialogConfig.Content,
				Buttons = DialogConfig.Buttons or {},
			}
			local Dialog = DialogModule.Create()

			local DialogTopFrame = New("Frame", {
				Size = UDim2.new(1,0,0,0),
				AutomaticSize = "Y",
				BackgroundTransparency = 1,
				Parent = Dialog.UIElements.Main
			}, {
				New("UIListLayout", {
					FillDirection = "Horizontal",
					Padding = UDim.new(0,Dialog.UIPadding),
					VerticalAlignment = "Center"
				})
			})

			local Icon
			if DialogConfig.Icon then
				Icon = Creator.Image(
					DialogConfig.IconSize,
					DialogConfig.Icon,
					DialogTable.Title .. ":" .. DialogConfig.Icon,
					0,
					Window,
					"Dialog",
					DialogConfig.IconThemed
				)
				Icon.Size = UDim2.new(0,26,0,26)
				Icon.Parent = DialogTopFrame
			end

			Dialog.UIElements.UIListLayout = New("UIListLayout", {
				Padding = UDim.new(0,8*2.3),
				FillDirection = "Vertical",
				HorizontalAlignment = "Left",
				Parent = Dialog.UIElements.Main
			})

			New("UISizeConstraint", {
				MinSize = Vector2.new(180, 20),
				MaxSize = Vector2.new(400, math.huge),
				Parent = Dialog.UIElements.Main,
			})

			Dialog.UIElements.Title = New("TextLabel", {
				Text = DialogTable.Title,
				TextSize = 19,
				FontFace = Font.new(Creator.Font, Enum.FontWeight.SemiBold),
				TextXAlignment = "Left",
				TextWrapped = true,
				RichText = true,
				Size = UDim2.new(1,Icon and -26-Dialog.UIPadding or 0,0,0),
				AutomaticSize = "Y",
				ThemeTag = {
					TextColor3 = "Text"
				},
				BackgroundTransparency = 1,
				Parent = DialogTopFrame
			})
			if DialogTable.Content then
				local Content = New("TextLabel", {
					Text = DialogTable.Content,
					TextSize = 18,
					TextTransparency = .4,
					TextWrapped = true,
					RichText = true,
					FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
					TextXAlignment = "Left",
					Size = UDim2.new(1,0,0,0),
					AutomaticSize = "Y",
					LayoutOrder = 2,
					ThemeTag = {
						TextColor3 = "Text"
					},
					BackgroundTransparency = 1,
					Parent = Dialog.UIElements.Main
				})
			end

			-- Dialog.UIElements.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
			--     Dialog.UIElements.Main.Size = UDim2.new(0,Dialog.UIElements.UIListLayout.AbsoluteContentSize.X,0,Dialog.UIElements.UIListLayout.AbsoluteContentSize.Y+Dialog.UIPadding*2)
			-- end)
			-- Dialog.UIElements.Title:GetPropertyChangedSignal("TextBounds"), function()
			--     Dialog.UIElements.Title.Size = UDim2.new(1,0,0,Dialog.UIElements.Title.TextBounds.Y)
			-- end)

			-- New("Frame", {
			--     Name = "Line",
			--     Size = UDim2.new(1, Dialog.UIPadding*2, 0, 1),
			--     Parent = Dialog.UIElements.Main,
			--     LayoutOrder = 3,
			--     BackgroundTransparency = 1,
			--     ThemeTag = {
			--         BackgroundColor3 = "Text",
			--     }
			-- })

			local ButtonsLayout = New("UIListLayout", {
				Padding = UDim.new(0, 10),
				FillDirection = "Horizontal",
				HorizontalAlignment = "Right",
			})

			local ButtonsContent = New("Frame", {
				Size = UDim2.new(1,0,0,40),
				AutomaticSize = "None",
				BackgroundTransparency = 1,
				Parent = Dialog.UIElements.Main,
				LayoutOrder = 4,
			}, {
				ButtonsLayout,
			})

			local CreateButton = NormalUI.Button
			local Buttons = {}

			for _,Button in next, DialogTable.Buttons do
				local ButtonFrame = CreateButton(Button.Title, Button.Icon, Button.Callback, Button.Variant, ButtonsContent, Dialog)
				table.insert(Buttons, ButtonFrame)
			end

			local function CheckButtonsOverflow()
				local totalWidth = ButtonsLayout.AbsoluteContentSize.X
				local parentWidth = ButtonsContent.AbsoluteSize.X - 1

				if totalWidth > parentWidth then
					ButtonsLayout.FillDirection = "Vertical"
					ButtonsLayout.HorizontalAlignment = "Right"
					ButtonsLayout.VerticalAlignment = "Bottom"
					ButtonsContent.AutomaticSize = "Y"

					for _, button in ipairs(Buttons) do
						button.Size = UDim2.new(1, 0, 0, 40)
						button.AutomaticSize = "None"
					end
				else
					ButtonsLayout.FillDirection = "Horizontal"
					ButtonsLayout.HorizontalAlignment = "Right"
					ButtonsLayout.VerticalAlignment = "Center"
					ButtonsContent.AutomaticSize = "None"

					for _, button in ipairs(Buttons) do
						button.Size = UDim2.new(0, 0, 1, 0)
						button.AutomaticSize = "X"
					end
				end
			end

			Creator.AddSignal(Dialog.UIElements.Main:GetPropertyChangedSignal("AbsoluteSize"), CheckButtonsOverflow)
			CheckButtonsOverflow()

			Dialog:Open()

			return Dialog
		end

		Window:CreateTopbarButton("Close", "x", function()
			Tween(Window.UIElements.Main, 0.35, {Position = UDim2.new(0.5,0,0.5,0)}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
			Window:Dialog({
				Icon = "trash-2",
				Title = "Close Window",
				Content = "Do you want to close this window? You will not be able to open it again.",
				Buttons = {
					{
						Title = "Cancel",
						--Icon = "chevron-left",
						Callback = function() end,
						Variant = "Secondary",
					},
					{
						Title = "Close Window",
						--Icon = "chevron-down",
						Callback = function() 
							Window:Close(nil, nil, nil):Destroy()
							Creator.DisconnectAll()
						end,
						Variant = "Primary",
					}
				}
			})
		end, 999)

		local isResizing, initialSize, initialInputPosition
		local function startResizing(input)
			if Window.CanResize then
				isResizing = true
				FullScreenIcon.Active = true
				initialSize = Window.UIElements.Main.Size
				initialInputPosition = input.Position
				Tween(FullScreenIcon, 0.12, {ImageTransparency = .65}):Play()
				Tween(FullScreenIcon.ImageLabel, 0.12, {ImageTransparency = 0}):Play()
				Tween(ResizeHandle.ImageLabel, 0.1, {ImageTransparency = .35}):Play()

				Creator.AddSignal(input.Changed, function()
					if input.UserInputState == Enum.UserInputState.End then
						isResizing = false
						FullScreenIcon.Active = false
						Tween(FullScreenIcon, 0.2, {ImageTransparency = 1}):Play()
						Tween(FullScreenIcon.ImageLabel, 0.17, {ImageTransparency = 1}):Play()
						Tween(ResizeHandle.ImageLabel, 0.17, {ImageTransparency = .8}):Play()
					end
				end)
			end
		end

		Creator.AddSignal(ResizeHandle.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				if Window.CanResize then
					startResizing(input)
				end
			end
		end)

		Creator.AddSignal(UserInputService.InputChanged, function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				if isResizing and Window.CanResize then
					local delta = input.Position - initialInputPosition
					local newSize = UDim2.new(0, initialSize.X.Offset + delta.X*2, 0, initialSize.Y.Offset + delta.Y*2)

					Tween(Window.UIElements.Main, 0, {
						Size = UDim2.new(
							0, math.clamp(newSize.X.Offset, 480, 700),
							0, math.clamp(newSize.Y.Offset, 350, 520)
						)}):Play()
				end
			end
		end)


		-- / Search Bar /

		if not Window.HideSearchBar then
			local SearchBar = {
				Margin = 8,
				Padding = 9,
			}


			local Creator = NormalCreator
			local New = Creator.New
			local Tween = Creator.Tween


			function SearchBar.new(TabModule, Parent, OnClose)
				local SearchBarModule = {
					IconSize = 14,
					Padding = 14,
					Radius = 15,
					Width = 400,
					MaxHeight = 380,

					Icons = { -- lucide
						Tab         = "table-of-contents",
						Paragraph   = "type",
						Button      = "square-mouse-pointer",
						Toggle      = "toggle-right",
						Slider      = "sliders-horizontal",
						Keybind     = "command",
						Input       = "text-cursor-input",
						Dropdown    = "chevrons-up-down",
						Code        = "terminal",
						Colorpicker = "palette",
					}
				}


				local TextBox = New("TextBox", {
					Text = "",
					PlaceholderText = "Search...",
					ThemeTag = {
						PlaceholderColor3 = "Placeholder",
						TextColor3 = "Text",
					},
					Size = UDim2.new(
						1,
						-((SearchBarModule.IconSize*2)+(SearchBarModule.Padding*2)),
						0,
						0
					),
					AutomaticSize = "Y",
					ClipsDescendants = true,
					ClearTextOnFocus = false,
					BackgroundTransparency = 1,
					TextXAlignment = "Left",
					FontFace = Font.new(Creator.Font, Enum.FontWeight.Regular),
					TextSize = 17,
				})

				local CloseButton = New("ImageLabel", {
					Image = Creator.Icon("x")[1],
					ImageRectSize = Creator.Icon("x")[2].ImageRectSize,
					ImageRectOffset = Creator.Icon("x")[2].ImageRectPosition,
					BackgroundTransparency = 1,
					ThemeTag = {
						ImageColor3 = "Text",
					},
					ImageTransparency = .2,
					Size = UDim2.new(0,SearchBarModule.IconSize,0,SearchBarModule.IconSize)
				}, {
					New("TextButton", {
						Size = UDim2.new(1,8,1,8),
						BackgroundTransparency = 1,
						Active = true,
						ZIndex = 999999999,
						AnchorPoint = Vector2.new(0.5,0.5),
						Position = UDim2.new(0.5,0,0.5,0),
						Text = "",
					})
				})

				local ScrollingFrame = New("ScrollingFrame", { -- list
					Size = UDim2.new(1,0,0,0),
					AutomaticCanvasSize = "Y",
					ScrollingDirection = "Y",
					ElasticBehavior = "Never",
					ScrollBarThickness = 0,
					CanvasSize = UDim2.new(0,0,0,0),
					BackgroundTransparency = 1,
					Visible = false
				}, {
					New("UIListLayout", {
						Padding = UDim.new(0,0),
						FillDirection = "Vertical",
					}),
					New("UIPadding", {
						PaddingTop = UDim.new(0,SearchBarModule.Padding),
						PaddingLeft = UDim.new(0,SearchBarModule.Padding),
						PaddingRight = UDim.new(0,SearchBarModule.Padding),
						PaddingBottom = UDim.new(0,SearchBarModule.Padding),
					})
				})

				local SearchFrame = Creator.NewRoundFrame(SearchBarModule.Radius, "Squircle", {
					Size = UDim2.new(1,0,1,0),
					ThemeTag = {
						ImageColor3 = "Accent",
					},
					ImageTransparency = 0,
				}, {
					New("Frame", {
						Size = UDim2.new(1,0,1,0),
						BackgroundTransparency = 1,
						--AutomaticSize = "Y",
						Visible = false,
					}, {
						New("Frame", { -- topbar search
							Size = UDim2.new(1,0,0,46),
							BackgroundTransparency = 1,
						}, {
							-- Creator.NewRoundFrame(SearchBarModule.Radius, "Squircle-TL-TR", {
							--     Size = UDim2.new(1,0,1,0),
							--     BackgroundTransparency = 1,
							--     ThemeTag = {
							--         ImageColor3 = "Text",
							--     },
							--     ImageTransparency = .95
							-- }),
							New("Frame", {
								Size = UDim2.new(1,0,1,0),
								BackgroundTransparency = 1,
							}, {
								New("ImageLabel", {
									Image = Creator.Icon("search")[1],
									ImageRectSize = Creator.Icon("search")[2].ImageRectSize,
									ImageRectOffset = Creator.Icon("search")[2].ImageRectPosition,
									BackgroundTransparency = 1,
									ThemeTag = {
										ImageColor3 = "Icon",
									},
									ImageTransparency = .05,
									Size = UDim2.new(0,SearchBarModule.IconSize,0,SearchBarModule.IconSize)
								}),
								TextBox,
								CloseButton,
								New("UIListLayout", {
									Padding = UDim.new(0,SearchBarModule.Padding),
									FillDirection = "Horizontal",
									VerticalAlignment = "Center",
								}),  
								New("UIPadding", {
									PaddingLeft = UDim.new(0,SearchBarModule.Padding),
									PaddingRight = UDim.new(0,SearchBarModule.Padding),
								})
							})
						}),
						New("Frame", { -- results
							BackgroundTransparency = 1,
							AutomaticSize = "Y",
							Size = UDim2.new(1,0,0,0),
							Name = "Results",
						}, {
							New("Frame", {
								Size = UDim2.new(1,0,0,1),
								ThemeTag = {
									BackgroundColor3 = "Outline",
								},
								BackgroundTransparency = .9,
								Visible = false,
							}),
							ScrollingFrame,
							New("UISizeConstraint", {
								MaxSize = Vector2.new(SearchBarModule.Width, SearchBarModule.MaxHeight),
							}),
						}),
						New("UIListLayout", {
							Padding = UDim.new(0,0),
							FillDirection = "Vertical",
						}),
					})
				})

				local SearchFrameContainer = New("Frame", {
					Size = UDim2.new(0,SearchBarModule.Width,0,0),
					AutomaticSize = "Y",
					Parent = Parent,
					BackgroundTransparency = 1,
					Position = UDim2.new(0.5,0,0.5,0),
					AnchorPoint = Vector2.new(0.5,0.5),
					Visible = false, -- true
					--GroupTransparency = 1, -- 0
					ZIndex = 99999999,
				}, {
					New("UIScale", {
						Scale = .9, -- 1
					}),
					SearchFrame,
					Creator.NewRoundFrame(SearchBarModule.Radius, "SquircleOutline", {
						Size = UDim2.new(1,0,1,0),
						ThemeTag = {
							ImageColor3 = "Outline",
						},
						ImageTransparency = .9,
					})
				})

				local function CreateSearchTab(Title, Desc, Icon, Parent, IsParent, Callback)
					local Tab = New("TextButton", {
						Size = UDim2.new(1,0,0,0),
						AutomaticSize = "Y",
						BackgroundTransparency = 1,
						Parent = Parent or nil
					}, {
						Creator.NewRoundFrame(SearchBarModule.Radius-4, "Squircle", {
							Size = UDim2.new(1,0,0,0),
							Position = UDim2.new(0.5,0,0.5,0),
							AnchorPoint = Vector2.new(0.5,0.5),
							-- AutomaticSize = "Y",
							ThemeTag = {
								ImageColor3 = "Text",
							},
							ImageTransparency = 1, -- .95
							Name = "Main"
						}, {
							New("UIPadding", {
								PaddingTop = UDim.new(0,SearchBarModule.Padding-2),
								PaddingLeft = UDim.new(0,SearchBarModule.Padding),
								PaddingRight = UDim.new(0,SearchBarModule.Padding),
								PaddingBottom = UDim.new(0,SearchBarModule.Padding-2),
							}),
							New("ImageLabel", {
								Image = Creator.Icon(Icon)[1],
								ImageRectSize = Creator.Icon(Icon)[2].ImageRectSize,
								ImageRectOffset = Creator.Icon(Icon)[2].ImageRectPosition,
								BackgroundTransparency = 1,
								ThemeTag = {
									ImageColor3 = "Text",
								},
								ImageTransparency = .2,
								Size = UDim2.new(0,SearchBarModule.IconSize,0,SearchBarModule.IconSize)
							}),
							New("Frame", {
								Size = UDim2.new(1,-SearchBarModule.IconSize-SearchBarModule.Padding,0,0),
								BackgroundTransparency = 1,
							}, {
								New("TextLabel", {
									Text = Title,
									ThemeTag = {
										TextColor3 = "Text",
									},
									TextSize = 17,
									BackgroundTransparency = 1,
									TextXAlignment = "Left",
									FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
									Size = UDim2.new(1,0,0,0),
									TextTruncate = "AtEnd",
									AutomaticSize = "Y",
									Name = "Title"
								}),
								New("TextLabel", {
									Text = Desc or "",
									Visible = Desc and true or false,
									ThemeTag = {
										TextColor3 = "Text",
									},
									TextSize = 15,
									TextTransparency = .2,
									BackgroundTransparency = 1,
									TextXAlignment = "Left",
									FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
									Size = UDim2.new(1,0,0,0),
									TextTruncate = "AtEnd",
									AutomaticSize = "Y",
									Name = "Desc"
								}) or nil,
								New("UIListLayout", {
									Padding = UDim.new(0,6),
									FillDirection = "Vertical",
								})
							}),
							New("UIListLayout", {
								Padding = UDim.new(0,SearchBarModule.Padding),
								FillDirection = "Horizontal",
							})
						}, true),
						New("Frame", {
							Name = "ParentContainer",
							Size = UDim2.new(1,-SearchBarModule.Padding,0,0),
							AutomaticSize = "Y",
							BackgroundTransparency = 1,
							Visible = IsParent,
							--Position = UDim2.new(0,SearchBarModule.Padding*2,1,0),
						}, {
							Creator.NewRoundFrame(99, "Squircle", { -- line
								Size = UDim2.new(0,2,1,0),
								BackgroundTransparency = 1,
								ThemeTag = {
									ImageColor3 = "Text"
								},
								ImageTransparency = .9,
							}),
							New("Frame", {
								Size = UDim2.new(1,-SearchBarModule.Padding-2,0,0),
								Position = UDim2.new(0,SearchBarModule.Padding+2,0,0),
								BackgroundTransparency = 1,
							}, {
								New("UIListLayout", {
									Padding = UDim.new(0,0),
									FillDirection = "Vertical",
								}),
							}),
						}),
						New("UIListLayout", {
							Padding = UDim.new(0,0),
							FillDirection = "Vertical",
							HorizontalAlignment = "Right"
						})
					})

					--

					Tab.Main.Size = UDim2.new(
						1,
						0,
						0,
						Tab.Main.Frame.Desc.Visible and (((SearchBarModule.Padding-2)*2) + Tab.Main.Frame.Title.TextBounds.Y + 6 + Tab.Main.Frame.Desc.TextBounds.Y)
							or (((SearchBarModule.Padding-2)*2) + Tab.Main.Frame.Title.TextBounds.Y)
					)

					Creator.AddSignal(Tab.Main.MouseEnter, function()
						Tween(Tab.Main, .04, {ImageTransparency = .95}):Play()
					end)
					Creator.AddSignal(Tab.Main.InputEnded, function()
						Tween(Tab.Main, .08, {ImageTransparency = 1}):Play()
					end)
					Creator.AddSignal(Tab.Main.MouseButton1Click, function()
						if Callback then
							Callback()
						end
					end)

					return Tab
				end

				local function ContainsText(str, query)
					if not query or query == "" then
						return false
					end

					if not str or str == "" then
						return false
					end

					local lowerStr = string.lower(str)
					local lowerQuery = string.lower(query)

					return string.find(lowerStr, lowerQuery, 1, true) ~= nil
				end

				local function Search(query)
					if not query or query == "" then
						return {}
					end

					local results = {}
					for tabindex, tab in next, TabModule.Tabs do
						local tabMatches = ContainsText(tab.Title or "", query)
						local elementResults = {}

						for elemindex, elem in next, tab.Elements do
							if elem.__type ~= "Section" then
								local titleMatches = ContainsText(elem.Title or "", query)
								local descMatches = ContainsText(elem.Desc or "", query)

								if titleMatches or descMatches then
									elementResults[elemindex] = {
										Title = elem.Title,
										Desc = elem.Desc,
										Original = elem,
										__type = elem.__type
									}
								end
							end
						end

						if tabMatches or next(elementResults) ~= nil then
							results[tabindex] = { 
								Tab = tab,
								Title = tab.Title,
								Icon = tab.Icon,
								Elements = elementResults,
							}
						end
					end
					return results
				end

				function SearchBarModule:Open()
					task.spawn(function()
						SearchFrame.Frame.Visible = true
						SearchFrameContainer.Visible = true
						Tween(SearchFrameContainer.UIScale, .12, {Scale = 1}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
					end)
				end

				function SearchBarModule:Close()
					task.spawn(function()
						OnClose()
						SearchFrame.Frame.Visible = false
						Tween(SearchFrameContainer.UIScale, .12, {Scale = 1}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()

						task.wait(.12)
						SearchFrameContainer.Visible = false
					end)
				end

				function SearchBarModule:Search(query)
					query = query or ""

					local result = Search(query)

					ScrollingFrame.Visible = true
					SearchFrame.Frame.Results.Frame.Visible = true
					for _, item in next, ScrollingFrame:GetChildren() do
						if item.ClassName ~= "UIListLayout" and item.ClassName ~= "UIPadding" then
							item:Destroy()
						end
					end

					if result and next(result) ~= nil then
						for tabindex, i in next, result do
							local TabIcon = SearchBarModule.Icons["Tab"]
							local TabMainElement = CreateSearchTab(i.Title, nil, TabIcon, ScrollingFrame, true, function()
								SearchBarModule:Close()
								TabModule:SelectTab(tabindex) 
							end)
							if i.Elements and next(i.Elements) ~= nil then
								for elemindex, e in next, i.Elements do
									local ElementIcon = SearchBarModule.Icons[e.__type]
									CreateSearchTab(e.Title, e.Desc, ElementIcon, TabMainElement:FindFirstChild("ParentContainer") and TabMainElement.ParentContainer.Frame or nil, false, function()
										SearchBarModule:Close()
										TabModule:SelectTab(tabindex) 
										--
									end)
									--task.wait(0)
								end
							end
						end
					elseif query ~= "" then
						New("TextLabel", {
							Size = UDim2.new(1,0,0,70),
							BackgroundTransparency = 1,
							Text = "No results found",
							TextSize = 16,
							ThemeTag = {
								TextColor3 = "Text",
							},
							TextTransparency = .2,
							--BackgroundTransparency = 1,
							FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
							Parent = ScrollingFrame,
							Name = "NotFound",
						})
					else
						ScrollingFrame.Visible = false
						SearchFrame.Frame.Results.Frame.Visible = false
					end
				end

				Creator.AddSignal(TextBox:GetPropertyChangedSignal("Text"), function()
					SearchBarModule:Search(TextBox.Text)
				end)

				Creator.AddSignal(ScrollingFrame.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
					--task.wait()
					Tween(ScrollingFrame, .06, {Size = UDim2.new(
						1,
						0,
						0,
						math.clamp(ScrollingFrame.UIListLayout.AbsoluteContentSize.Y+(SearchBarModule.Padding*2), 0, SearchBarModule.MaxHeight)
						)}, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut):Play()
					-- ScrollingFrame.Size = UDim2.new(
					--     1,
					--     0,
					--     0,
					--     math.clamp(ScrollingFrame.UIListLayout.AbsoluteContentSize.Y+(SearchBarModule.Padding*2), 0, SearchBarModule.MaxHeight)
					-- )
				end)

				Creator.AddSignal(CloseButton.TextButton.MouseButton1Click, function()
					SearchBarModule:Close()
				end)

				SearchBarModule:Open()

				return SearchBarModule
			end

			local IsOpen = false
			local CurrentSearchBar

			-- local SearchButton
			-- SearchButton = Window:CreateTopbarButton("search", function() 
			--     if IsOpen then return end

			--     SearchBar.new(Window.TabModule, Window.UIElements.Main, function()
			--         -- OnClose
			--         IsOpen = false
			--         Window.CanResize = true

			--         Tween(FullScreenBlur, 0.1, {ImageTransparency = 1}):Play()
			--         FullScreenBlur.Active = false
			--     end)
			--     Tween(FullScreenBlur, 0.1, {ImageTransparency = .65}):Play()
			--     FullScreenBlur.Active = true

			--     IsOpen = true
			--     Window.CanResize = false
			-- end, 996)

			local SearchLabel = CreateLabel("Search", "search", Window.UIElements.SideBarContainer)
			SearchLabel.Size = UDim2.new(1,-Window.UIPadding/2,0,39)
			SearchLabel.Position = UDim2.new(0,Window.UIPadding/2,0,0)

			Creator.AddSignal(SearchLabel.MouseButton1Click, function()
				if IsOpen then return end

				SearchBar.new(Window.TabModule, Window.UIElements.Main, function()
					-- OnClose
					IsOpen = false
					Window.CanResize = true

					Tween(FullScreenBlur, 0.1, {ImageTransparency = 1}):Play()
					FullScreenBlur.Active = false
				end)
				Tween(FullScreenBlur, 0.1, {ImageTransparency = .65}):Play()
				FullScreenBlur.Active = true

				IsOpen = true
				Window.CanResize = false
			end)
		end


		-- / TopBar Edit /

		function Window:DisableTopbarButtons(btns)
			for _,b in next, btns do
				for _,i in next, Window.TopBarButtons do
					if i.Name == b then
						i.Object.Visible = false
					end
				end
			end
		end

		return Window
	end

	if not isfolder("WindUI") then
		makefolder("WindUI")
	end
	if not isfolder("WindUI/.Assets") then
		makefolder("WindUI/.Assets")
	end
	if Config.Folder then
		makefolder(Config.Folder)
	else
		makefolder(Config.Title)
	end

	Config.WindUI = WindUI
	Config.Parent = WindUI.ScreenGui.Window

	if WindUI.Window then
		warn("You cannot create more than one window")
		return
	end

	local CanLoadWindow = true

	local Theme = Themes[Config.Theme or "Dark"]

	WindUI.Theme = Theme

	Creator.SetTheme(Theme)

	local Filename = LocalPlayer.Name or "Unknown"
	local Window = CreateWindow(Config)

	WindUI.Transparent = Config.Transparent
	WindUI.Window = Window


	-- function Window:ToggleTransparency(Value)
	--     WindUI.Transparent = Value
	--     WindUI.Window.Transparent = Value

	--     Window.UIElements.Main.Background.BackgroundTransparency = Value and WindUI.TransparencyValue or 0
	--     Window.UIElements.Main.Background.ImageLabel.ImageTransparency = Value and WindUI.TransparencyValue or 0
	--     Window.UIElements.Main.Gradient.UIGradient.Transparency = NumberSequence.new{
	--         NumberSequenceKeypoint.new(0, 1), 
	--         NumberSequenceKeypoint.new(1, Value and 0.85 or 0.7),
	--     }
	-- end

	return Window
end

return WindUI
