local Players = game:GetService("Players")
local lp = Players.LocalPlayer

local BASE_URL = "https://jb-hub-online.uhq7k.workers.dev"
local PING_INTERVAL = 5
local TOGGLE_ID = "hub_roles_enabled"
local DEFAULT_LABEL = "JB Hub"
local DEFAULT_COLOR = Color3.fromRGB(125, 150, 255)
local ROLE_COLORS = { Owner = Color3.fromRGB(255, 200, 60), Tester = Color3.fromRGB(90, 220, 140) }
local TAG_FONT = Drawing.Fonts.SystemBold
local TAG_SIZE = 15
local TAG_OFFSET = Vector3.new(0, -4.5, 0)
local MAX_DISTANCE = 300

local state = "off"
local statusText = "Status: Off"
local hubUsers = {}
local tags = {}
local tagLabels = {}

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

local function clearTags()
    for userId, tag in pairs(tags) do
        tag:Remove()
        tags[userId] = nil
        tagLabels[userId] = nil
    end
end

local function getTag(userId, label)
    local tag = tags[userId]
    if not tag then
        tag = Drawing.new("Text")
        tag.Center = true
        tag.Outline = true
        tag.Visible = false
        pcall(function() tag.Font = TAG_FONT end)
        pcall(function() tag.FontSize = TAG_SIZE end)
        pcall(function() tag.Size = TAG_SIZE end)
        tags[userId] = tag
    end
    if tagLabels[userId] ~= label then
        tag.Text = "[" .. label .. "]"
        tag.Color = ROLE_COLORS[label] or DEFAULT_COLOR
        tagLabels[userId] = label
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
                    local tag = getTag(userId, label)
                    seen[userId] = true
                    local worldPos = root.Position + TAG_OFFSET
                    local screenPos, onScreen = WorldToScreen(worldPos)
                    if onScreen and (worldPos - camPos).Magnitude <= MAX_DISTANCE then
                        tag.Position = Vector2.new(screenPos.X, screenPos.Y)
                        tag.Visible = true
                    else
                        tag.Visible = false
                    end
                end
            end
            for userId, tag in pairs(tags) do
                if not seen[userId] then
                    tag:Remove()
                    tags[userId] = nil
                    tagLabels[userId] = nil
                end
            end
            task.wait()
        else
            clearTags()
            task.wait(0.2)
        end
    end
end)
