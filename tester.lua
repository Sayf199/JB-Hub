-- hello 
local Players = game:GetService("Players")
local lp = Players.LocalPlayer

local BASE_URL = "https://jb-hub-online.uhq7k.workers.dev"
local PING_INTERVAL = 5
local TOGGLE_ID = "hub_roles_enabled"
local DEFAULT_LABEL = "JB Hub"
local DEFAULT_COLOR = Color3.fromRGB(125, 150, 255)
local ROLE_COLORS = { Owner = Color3.fromRGB(255, 200, 60), Tester = Color3.fromRGB(90, 220, 140) }
local TAG_FONT = Drawing.Fonts.SystemBold
local TAG_SIZE_NEAR = 15
local TAG_SIZE_FAR = 9
local TAG_NEAR = 30
local TAG_FAR = 500
local TAG_OFFSET = Vector3.new(0, -3, 0)
local TAG_PADDING = 4

local state = "off"
local statusText = "Status: Off"
local hubUsers = {}
local tags = {}
local tagLabels = {}
local tagSizes = {}

local function makeClientId()
    pcall(function() math.randomseed(math.floor(tick() * 1000) % 2147483647) end)
    local chars = "abcdef0123456789"
    local out = {}
    for i = 1, 24 do
        local n = math.random(1, #chars)
        out[i] = string.sub(chars, n, n)
    end
    return table.concat(out)
end

local clientId = makeClientId()

local function pingPresence()
    local url = BASE_URL .. "/ping?id=" .. clientId .. "&job=" .. tostring(game.JobId) .. "&uid=" .. tostring(lp.UserId)
    local ok, body = pcall(httpget, url)
    if not ok or type(body) ~= "string" then return false end
    local list = string.match(body, '"users":%[(.-)%]')
    if not list then return false end
    local fresh = {}
    for uid in string.gmatch(list, "%d+") do
        fresh[tonumber(uid)] = DEFAULT_LABEL
    end
    local roleList = string.match(body, '"roles":{(.-)}')
    if roleList then
        for uid, role in string.gmatch(roleList, '"(%d+)":"([^"]+)"') do
            if fresh[tonumber(uid)] then
                fresh[tonumber(uid)] = role
            end
        end
    end
    if not fresh[lp.UserId] then return false end
    hubUsers = fresh
    return true
end

local function leavePresence()
    pcall(httpget, BASE_URL .. "/leave?id=" .. clientId)
    hubUsers = {}
end

local function removeTag(userId)
    local tag = tags[userId]
    if tag then tag:Remove() end
    tags[userId] = nil
    tagLabels[userId] = nil
    tagSizes[userId] = nil
end

local function clearTags()
    for userId in pairs(tags) do
        removeTag(userId)
    end
end

local function sizeForDistance(distance)
    local alpha = math.clamp((distance - TAG_NEAR) / (TAG_FAR - TAG_NEAR), 0, 1)
    return math.floor(TAG_SIZE_NEAR + (TAG_SIZE_FAR - TAG_SIZE_NEAR) * alpha + 0.5)
end

local function getTag(userId, label, size)
    local tag = tags[userId]
    if not tag then
        tag = Drawing.new("Text")
        tag.Center = true
        tag.Outline = true
        tag.Visible = false
        pcall(function() tag.Font = TAG_FONT end)
        tags[userId] = tag
    end
    if tagLabels[userId] ~= label then
        tag.Text = "[" .. label .. "]"
        tag.Color = ROLE_COLORS[label] or DEFAULT_COLOR
        tagLabels[userId] = label
    end
    if tagSizes[userId] ~= size then
        pcall(function() tag.FontSize = size end)
        pcall(function() tag.Size = size end)
        tagSizes[userId] = size
    end
    return tag
end

UI.AddTab("Hub Roles Test", function(tab)
    local sec = tab:Section("Roles", "Left")
    sec:Toggle(TOGGLE_ID, "Display JB Hub Roles - Server Sided", false)
    sec:Text(statusText)
end)

task.spawn(function()
    local lastPing = 0
    while true do
        local wanted = UI.GetValue(TOGGLE_ID) == true
        if state == "off" and wanted then
            state = "connecting"
            statusText = "Status: Connecting..."
            UI.SetValue(TOGGLE_ID, false)
            if pingPresence() then
                state = "on"
                lastPing = tick()
                statusText = "Status: Connected as " .. tostring(hubUsers[lp.UserId])
                UI.SetValue(TOGGLE_ID, true)
                notify("Connected to JB Hub server", "Hub Roles", 3)
            else
                state = "off"
                statusText = "Status: Connection failed"
                notify("Could not reach JB Hub server", "Hub Roles", 4)
            end
        elseif state == "on" and not wanted then
            state = "off"
            statusText = "Status: Off"
            leavePresence()
        elseif state == "on" and tick() - lastPing >= PING_INTERVAL then
            if not pingPresence() then
                statusText = "Status: Reconnecting..."
            else
                statusText = "Status: Connected as " .. tostring(hubUsers[lp.UserId])
            end
            lastPing = tick()
        end
        task.wait(0.2)
    end
end)

task.spawn(function()
    while true do
        if state == "on" then
            local seen = {}
            local camera = workspace.CurrentCamera
            local camPos = camera and camera.CFrame.Position
            for _, player in ipairs(Players:GetPlayers()) do
                local userId = player.UserId
                local label = hubUsers[userId]
                local char = label and player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root and camPos then
                    local worldPos = root.Position + TAG_OFFSET
                    local distance = (worldPos - camPos).Magnitude
                    local tag = getTag(userId, label, sizeForDistance(distance))
                    seen[userId] = true
                    local screenPos, onScreen = WorldToScreen(worldPos)
                    if onScreen then
                        tag.Position = Vector2.new(screenPos.X, screenPos.Y + TAG_PADDING)
                        tag.Visible = true
                    else
                        tag.Visible = false
                    end
                end
            end
            for userId in pairs(tags) do
                if not seen[userId] then
                    removeTag(userId)
                end
            end
            task.wait()
        else
            clearTags()
            task.wait(0.2)
        end
    end
end)
