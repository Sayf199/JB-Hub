local JB_PLACE_ID = 606849621
local JB_GAME_ID = 245662005
local placeOk, placeId = pcall(function() return game.PlaceId end)
local gameOk, gameId = pcall(function() return game.GameId end)
if not ((placeOk and placeId == JB_PLACE_ID) or (gameOk and gameId == JB_GAME_ID)) then
    local msg = "[JB Hub] Wrong game (PlaceId " .. tostring(placeId) .. ")"
    if not pcall(warn, msg) then print(msg) end
    pcall(function() notify("Wrong game, JB Hub not loaded", "[JB Hub]", 5) end)
    return
end
_G.JB_gen = (_G.JB_gen or 0) + 1
local myGen = _G.JB_gen
local S = "_" .. tostring(math.floor(tick() * 1000))
local function uid(base) return base .. S end

SPLASH = {
    BASE = "https://raw.githubusercontent.com/Sayf199/JB-Hub/main/assets/",
    FILES = { "logo.png", "glow_red.png", "glow_blue.png", "vignette.png", "bar.png" },
    VERSION = "v2.5.1",
    DOWNLOAD_TIMEOUT = 6,
    MIN_TIME = 3,
    STEP_TIME = 0.32,
    TIMEOUT = 25,
    ROWS = 4,
    TAGS = {
        ok = { "[  OK  ]", Color3.fromRGB(90, 220, 130) },
        warn = { "[ WARN ]", Color3.fromRGB(255, 190, 70) },
        fail = { "[ FAIL ]", Color3.fromRGB(255, 85, 85) },
    },
    objects = {},
    queue = {},
    log = {},
    info = {},
    target = 0,
    shown = 0,
    labelAt = 0,
    finishing = false,
    started = false,
    done = false,
}

function SPLASH.clear()
    for _, d in ipairs(SPLASH.objects) do pcall(function() d:Remove() end) end
    SPLASH.objects = {}
    _G.JB_SPLASH = nil
    SPLASH.done = true
end

function SPLASH.ease(t)
    t = math.clamp(t, 0, 1)
    return 1 - (1 - t) ^ 3
end

function SPLASH.strobe(t, phase)
    local c = (t + phase) % 1.4
    local a = 0
    for _, s in ipairs({ 0, 0.18 }) do
        local d = c - s
        if d >= 0 and d < 0.16 then a = math.max(a, math.sin(d / 0.16 * math.pi)) end
    end
    return a
end

function SPLASH.new(kind, props)
    local d = Drawing.new(kind)
    for k, v in pairs(props) do d[k] = v end
    SPLASH.objects[#SPLASH.objects + 1] = d
    return d
end

function SPLASH.download()
    local data, pending = {}, #SPLASH.FILES + 1
    for _, f in ipairs(SPLASH.FILES) do
        task.spawn(function()
            local ok, raw = pcall(function() return game:HttpGet(SPLASH.BASE .. f) end)
            if ok and type(raw) == "string" and raw:sub(2, 4) == "PNG" then data[f] = raw end
            pending = pending - 1
        end)
    end
    task.spawn(function()
        pcall(function()
            local id = game:GetService("Players").LocalPlayer.UserId
            local info = game:GetService("HttpService"):JSONDecode(game:HttpGet("https://users.roblox.com/v1/users/" .. tostring(id)))
            if type(info) == "table" then SPLASH.account = info end
        end)
        pending = pending - 1
    end)
    local t0 = tick()
    while pending > 0 and tick() - t0 < SPLASH.DOWNLOAD_TIMEOUT do task.wait(0.05) end
    return data
end

function SPLASH.userName()
    local a = SPLASH.account
    local name = type(a) == "table" and a.name or nil
    local display = type(a) == "table" and a.displayName or nil
    if not name then
        local lp = game:GetService("Players").LocalPlayer
        name = lp and lp.Name or "player"
    end
    if type(display) == "string" and #display > 0 and display ~= name then return display .. " (" .. name .. ")" end
    return name
end

function SPLASH.start()
    if _G.JB_SPLASH then
        for _, o in ipairs(_G.JB_SPLASH) do pcall(function() o:Remove() end) end
    end
    local data = SPLASH.download()
    if not data["logo.png"] then return end
    _G.JB_SPLASH = SPLASH.objects
    local vp = workspace.CurrentCamera.ViewportSize
    local s = vp.Y / 1080
    local new = SPLASH.new
    local o = {}
    local soft = Drawing.Fonts.ProximaSoftBold or 0
    local mono = Drawing.Fonts.Monospace or soft
    if data["vignette.png"] then
        o.vignette = new("Image", { Data = data["vignette.png"], Position = Vector2.new(0, 0), Size = vp, Transparency = 0, ZIndex = 1, Visible = true })
    else
        o.vignette = new("Square", { Position = Vector2.new(0, 0), Size = vp, Color = Color3.fromRGB(4, 6, 10), Filled = true, Transparency = 0, ZIndex = 1, Visible = true })
    end
    local g = 1000 * s
    if data["glow_red.png"] then
        o.red = new("Image", { Data = data["glow_red.png"], Position = Vector2.new(-g * 0.5, -g * 0.4), Size = Vector2.new(g, g), Transparency = 0, ZIndex = 2, Visible = true })
    end
    if data["glow_blue.png"] then
        o.blue = new("Image", { Data = data["glow_blue.png"], Position = Vector2.new(vp.X - g * 0.5, -g * 0.4), Size = Vector2.new(g, g), Transparency = 0, ZIndex = 2, Visible = true })
    end
    o.logo = new("Image", { Data = data["logo.png"], Position = Vector2.new(0, 0), Size = Vector2.new(1, 1), Transparency = 0, ZIndex = 5, Visible = true })
    o.welcome = new("Text", { Text = "", Font = soft, Size = 20, Center = true, Outline = false, Color = Color3.fromRGB(225, 229, 238), Transparency = 0, ZIndex = 6, Visible = true })
    local bw, bh = 440 * s, 3
    local bx, by = (vp.X - bw) / 2, vp.Y / 2 + 95 * s
    o.track = new("Square", { Position = Vector2.new(bx, by), Size = Vector2.new(bw, bh), Color = Color3.fromRGB(34, 38, 48), Filled = true, Transparency = 0, ZIndex = 6, Visible = true })
    if data["bar.png"] then
        o.fill = new("Image", { Data = data["bar.png"], Position = Vector2.new(bx, by), Size = Vector2.new(1, bh), Transparency = 0, ZIndex = 7, Visible = true })
    else
        o.fill = new("Square", { Position = Vector2.new(bx, by), Size = Vector2.new(1, bh), Color = Color3.fromRGB(30, 110, 255), Filled = true, Transparency = 0, ZIndex = 7, Visible = true })
    end
    o.pct = new("Text", { Text = "0%", Font = mono, Size = 14, Center = false, Outline = false, Color = Color3.fromRGB(120, 128, 142), Position = Vector2.new(bx + bw + 10, by - 5), Transparency = 0, ZIndex = 7, Visible = true })
    o.rows = {}
    for r = 1, SPLASH.ROWS do
        o.rows[r] = {
            tag = new("Text", { Text = "", Font = mono, Size = 14, Center = false, Outline = false, Color = Color3.fromRGB(90, 220, 130), Transparency = 0, ZIndex = 7, Visible = true }),
            msg = new("Text", { Text = "", Font = mono, Size = 14, Center = false, Outline = false, Color = Color3.fromRGB(200, 205, 215), Transparency = 0, ZIndex = 7, Visible = true }),
        }
    end
    local measure = new("Text", { Text = "[ WARN ]", Font = mono, Size = 14, Center = false, Outline = false, Transparency = 0, ZIndex = 1, Visible = true })
    task.wait()
    task.wait()
    SPLASH.tagW = measure.TextBounds.X > 0 and measure.TextBounds.X or 64
    measure.Text = string.rep("0", 40)
    task.wait()
    task.wait()
    SPLASH.charW = measure.TextBounds.X > 0 and measure.TextBounds.X / 40 or SPLASH.tagW / 8
    measure.Visible = false
    o.left = new("Text", { Text = "JB HUB  " .. SPLASH.VERSION, Font = mono, Size = 14, Center = false, Outline = false, Color = Color3.fromRGB(110, 118, 132), Position = Vector2.new(28 * s, vp.Y - 40 * s), Transparency = 0, ZIndex = 7, Visible = true })
    o.right = new("Text", { Text = "", Font = mono, Size = 14, Center = false, Outline = false, Color = Color3.fromRGB(110, 118, 132), Position = Vector2.new(vp.X - 300, vp.Y - 40 * s), Transparency = 0, ZIndex = 7, Visible = true })
    SPLASH.o, SPLASH.vp, SPLASH.s = o, vp, s
    SPLASH.bx, SPLASH.by, SPLASH.bw, SPLASH.bh = bx, by, bw, bh
    SPLASH.info.user = SPLASH.userName()
    SPLASH.info.exec = "Matcha"
    pcall(function() SPLASH.info.exec = identifyexecutor() end)
    SPLASH.info.hybrid = "Hybrid --"
    SPLASH.started = true
end

function SPLASH.step(label, pct, state)
    local line = "[JB] " .. label
    if state == "fail" or state == "warn" then
        if not pcall(warn, line) then print(line) end
    else
        print(line)
    end
    if SPLASH.done then return end
    SPLASH.queue[#SPLASH.queue + 1] = { label = label, pct = pct, state = state or "ok" }
end

function SPLASH.reportInterface()
    if SPLASH.uiOk then
        SPLASH.step("Interface ready", 100)
    else
        SPLASH.step("Interface failed to build", 100, "fail")
    end
    SPLASH.finishing = true
end

function SPLASH.run()
    if not SPLASH.started then
        local t0 = tick()
        while not SPLASH.uiDone and tick() - t0 < 5 do task.wait(0.05) end
        SPLASH.done = true
        SPLASH.reportInterface()
        return
    end
    SPLASH.t0 = tick()
    local ok, err = pcall(SPLASH.loop)
    if not ok then print("[JB Splash] error: " .. tostring(err)) end
    SPLASH.clear()
end

function SPLASH.loop()
    local o, vp, s = SPLASH.o, SPLASH.vp, SPLASH.s
    local ease, strobe = SPLASH.ease, SPLASH.strobe
    local last, outAt = tick(), nil
    local logoW, ratio = 560 * s, 222 / 640
    local welcome = "Welcome back, " .. SPLASH.info.user
    while true do
        local now = tick()
        local dt = math.min(now - last, 0.1)
        last = now
        local t = now - SPLASH.t0
        if not SPLASH.finishing and (SPLASH.uiDone or t > 6) then
            SPLASH.reportInterface()
        end
        if #SPLASH.queue > 0 and t > 0.7 and now - SPLASH.labelAt >= SPLASH.STEP_TIME then
            local q = table.remove(SPLASH.queue, 1)
            q.at = now
            table.insert(SPLASH.log, 1, q)
            SPLASH.log[SPLASH.ROWS + 1] = nil
            SPLASH.labelAt = now
            SPLASH.target = math.max(SPLASH.target, q.pct)
        end
        SPLASH.shown = SPLASH.shown + (SPLASH.target - SPLASH.shown) * math.min(1, dt * 5)
        if SPLASH.target - SPLASH.shown < 0.3 then SPLASH.shown = SPLASH.target end
        if SPLASH.finishing and not outAt and #SPLASH.queue == 0 and SPLASH.shown >= 99.9 and t >= SPLASH.MIN_TIME then
            outAt = now + 0.5
        end
        local fadeOut = outAt and (1 - ease((now - outAt) / 0.45)) or 1
        local a = ease(t / 0.5) * fadeOut
        local lift = outAt and ease((now - outAt) / 0.45) * 30 * s or 0

        o.vignette.Transparency = a
        if o.red then o.red.Transparency = a * (0.12 + 0.55 * strobe(t, 0)) end
        if o.blue then o.blue.Transparency = a * (0.12 + 0.55 * strobe(t, 0.7)) end

        local lw = logoW * (1.06 - 0.06 * ease(t / 1.1))
        local lh = lw * ratio
        local cx, cy = vp.X / 2, vp.Y / 2 - 70 * s - lift
        o.logo.Size = Vector2.new(lw, lh)
        o.logo.Position = Vector2.new(cx - lw / 2, cy - lh / 2)
        o.logo.Transparency = ease((t - 0.05) / 0.8) * fadeOut

        local wa = ease((t - 0.5) / 0.6) * fadeOut
        local typed = math.clamp(math.floor((t - 0.5) * 38), 0, #welcome)
        o.welcome.Text = welcome:sub(1, typed)
        o.welcome.Position = Vector2.new(cx, cy + lh / 2 + 6 * s)
        o.welcome.Transparency = wa

        local ta = ease((t - 0.6) / 0.5) * fadeOut
        local by = SPLASH.by - lift
        o.track.Position = Vector2.new(SPLASH.bx, by)
        o.track.Transparency = ta * 0.9
        o.fill.Position = Vector2.new(SPLASH.bx, by)
        o.fill.Size = Vector2.new(math.max(1, SPLASH.bw * SPLASH.shown / 100), SPLASH.bh)
        o.fill.Transparency = ta
        o.pct.Text = math.floor(SPLASH.shown + 0.5) .. "%"
        o.pct.Position = Vector2.new(SPLASH.bx + SPLASH.bw + 10 * s, by - 5)
        o.pct.Transparency = ta

        local rowY = by + 18 * s
        for r = 1, SPLASH.ROWS do
            local row, e = o.rows[r], SPLASH.log[r]
            if e then
                local tag = SPLASH.TAGS[e.state] or SPLASH.TAGS.ok
                local enter = ease((now - e.at) / 0.25)
                local dim = ({ 1, 0.55, 0.32, 0.18 })[r] or 0.15
                local y = rowY + (r - 1) * 18 * s + (r == 1 and (1 - enter) * 6 or 0)
                row.tag.Text = tag[1]
                row.tag.Color = tag[2]
                row.tag.Position = Vector2.new(SPLASH.bx, y)
                row.tag.Transparency = ta * dim * (r == 1 and enter or 1)
                row.msg.Text = e.label
                row.msg.Position = Vector2.new(SPLASH.bx + SPLASH.tagW + 10, y)
                row.msg.Transparency = ta * dim * (r == 1 and enter or 1)
            else
                row.tag.Transparency, row.msg.Transparency = 0, 0
            end
        end

        o.left.Transparency = ta
        local rightText = SPLASH.info.exec .. "  /  " .. SPLASH.info.hybrid .. (SPLASH.info.online and ("  /  " .. SPLASH.info.online .. " online") or "")
        if rightText ~= SPLASH.rightText then
            SPLASH.rightText = rightText
            o.right.Text = rightText
        end
        local charW = SPLASH.charW or (SPLASH.tagW or 64) / 8
        o.right.Position = Vector2.new(vp.X - 36 * s - #rightText * charW, vp.Y - 40 * s)
        o.right.Transparency = ta

        if outAt and now - outAt >= 0.45 then break end
        if t > SPLASH.TIMEOUT then break end
        task.wait(1 / 60)
    end
end

SPLASH.start()
SPLASH.step("Jailbreak detected", 10)

local HUM_HEALTH = 0x184 -- update
local SIT_OFFSET = 0x1D7 -- update
local NFD_NAME   = "NoRagdollNoFallDamage"
local NFD_METHODS = { "Zone Follow", "Pulse" }
local NFD_ZONE_SIZE = Vector3.new(2048, 2048, 2048)
local NFD_FOLLOW_TICK = 0.1
local NFD_PULSE_TICK = 0.01
local NFD_RESET_EVERY = 15
local NFD_PULSE_TIME = 0.04
local NFD_FALLING_SPEED = -2
local PLATFORM_STAND_OFFSET = 0x1D6  -- update (Humanoid)
local PRIMITIVE_OFFSET = 0x178 -- update (BasePart)
local VELOCITY_Y_OFFSET = 0xE4 -- update
local NITRO_KEYS = { "Nitro", "NitroMax" }
local NITRO_VALUES = { Nitro = 999999, NitroMax = 999999 }
local NITRO_APPLY_TICK = 0.5
local NITRO_RESCAN_EVERY = 600
local NITRO_SEAT_DELAY = 1
local NITRO_EMPTY_RETRY = 180
local CASINO_KEY = 0x64
local CASINO_OPEN_KEY = 0x65
local VAULT_KEY = 0x66
local VAULT = {
    TITLE = "[JB Hub] Auto Vault",
    START_RANGE = 20,
    START_DELAY = 2,
    TICK = 0.01,
    PRESS_GAP = 0.3,
    RESTART_AFTER = 6,
    MAX_RESTARTS = 5,
    WHITES_NEEDED = 3,
}
local LOOT = {
    TITLE = "[JB Hub] Auto Collect Loot",
    RANGE = 40,
    TICK = 0.25,
    PER_GAP = 1,
    RESCAN = 2,
    IDLE = 0.5,
    BAG_SCAN = 1,
    BAG_LABEL = { "RobberyMoneyGui", "Frame", "Container", "Bottom", "Progress", "Amount" },
}
local VEHICLE = {
    FLY_TITLE = "[JB Hub] Vehicle Fly",
    FLY_KEY = 0x61,
    FLY_DEFAULT_SPEED = 300,
    FLY_VERTICAL_SPEED = 80,
    FLY_ACCEL = 6,
    FLY_TURN_GAIN = 4,
    FLY_KEYS = { fwd = 0x57, back = 0x53, left = 0x51, right = 0x44, up = 0x10, down = 0x11 },
    BOOST_TITLE = "[JB Hub] Engine Boost",
    BOOST_KEY = 0x62,
    BOOST_DEFAULT = 1.05,
    BOOST_MAX = 2,
    BOOST_PAIR_RANGE = 0x1000,
    BOOST_RESCAN = 3,
    ROOT_PARTS = { "Weight", "Engine" },
    FLY_LOST_GRACE = 1.5,
    FIND_RADIUS = 40,
    TIRE_TITLE = "[JB Hub] Anti Tires Pop",
    TIRE_SPIKE_SCAN = 0.5,
    TIRE_MIN_WIDTH = 5,
    BRAKE_TITLE = "[JB Hub] Instant Brake",
    BRAKE_KEY = 0x63,
    BRAKE_KEYS = { 0x53, 0x28 },
    BRAKE_MIN_SPEED = 2,
    FLIP_TITLE = "[JB Hub] Anti Flip",
    FLIP_ANG = 0xEC, -- update 
    FLIP_TRIGGER = 0.5,
    FLIP_DONE = 0.9,
    FLIP_GAIN = 5,
    FLIP_LIFT = 8,
    FLIP_TICK = 0.03,
}
local GLASS = {
    TITLE = "[JB Hub] Auto Glass",
    RANGE = 40,
    TICK = 0.25,
    PER_GAP = 1,
    RESCAN = 2,
    IDLE = 0.5,
}
local PERF = {
    SIGNS = { -1, 1 },
    ESP_SCAN_CHUNK = 60,
    ESP_PARENT_CHECK = 0.2,
    LASER_YIELD_EVERY = 100,
    PLASMA_TARGET_REFRESH = 0.3,
    PLASMA_CACHE_TIME = 1,
    LASER_ANCHOR_EVERY = 15,
    LASER_NEAR_RANGE = 400,
    LASER_NEAR_CHECK = 1,
    TURRET_RECHECK = 3,
    FLY_RECHECK = 1,
    flying = false,
    NFD_ZONE_CHECK = 2,
    TOMB_TICK = 0.5,
    TOMB_SPIKE_REFRESH = 10,
    TOMB_RECHECK = 10,
    NFD_ZONE_MARGIN = 200,
    LASER_NEAR_REFRESH = 3,
    LASER_ROTATE_REFRESH = 8,
    LASER_FULL_EVERY = 6,
    LASER_EXTRA_EVERY = 1,
    LASER_RECHECK_EVERY = 10,
    MIL_RESCAN_MAX = 300,
    solving = false,
    JOB_SAFETY_RESCAN = 1e9,
    NEAR_MILITARY = 1500,
    NEAR_CARGO = 800,
    KILL_NPC_KEY = 0x68,
	RESET_KEY = 0x52,
    ceoGuards = {},
    bountyColor = Color3.fromRGB(255, 60, 60),
    SLOT_TITLE = "[JB Hub] Unlock Weapons Slots",
    SLOT_ATTR = "InventoryItemLocked",
    SLOT_TICK = 0.25,	
    SLOT_WATCH = 5,
    SKY_TITLE = "[JB Hub] Sky Color",
    WORLD_TICK = 0.25,
    WORLD_REAPPLY = 1,
    ATMOS = { Color = 0xA0, Decay = 0xAC, Density = 0xB8, Glare = 0xBC, Haze = 0xC0, Offset = 0xC4 }, -- update
    SKY_NAMES = { "Purple", "Pink", "Sunset", "Blood Red", "Night Blue", "Toxic Green", "Ocean" },
    SKY_PRESETS = {
        { Color = { 0.8, 0.3, 1.0 }, Decay = { 0.5, 0.1, 0.9 }, Density = 0.3, Glare = 4, Haze = 6, Offset = 0.6 },
        { Color = { 1.0, 0.55, 0.85 }, Decay = { 1.0, 0.3, 0.65 }, Density = 0.3, Glare = 4, Haze = 6, Offset = 0.6 },
        { Color = { 1.0, 0.6, 0.3 }, Decay = { 0.9, 0.3, 0.15 }, Density = 0.3, Glare = 6, Haze = 5, Offset = 0.5 },
        { Color = { 0.9, 0.15, 0.1 }, Decay = { 0.5, 0.0, 0.0 }, Density = 0.35, Glare = 3, Haze = 7, Offset = 0.6 },
        { Color = { 0.25, 0.35, 0.85 }, Decay = { 0.05, 0.1, 0.4 }, Density = 0.35, Glare = 1, Haze = 7, Offset = 0.6 },
        { Color = { 0.4, 1.0, 0.45 }, Decay = { 0.1, 0.55, 0.25 }, Density = 0.3, Glare = 3, Haze = 6, Offset = 0.6 },
        { Color = { 0.3, 0.85, 1.0 }, Decay = { 0.05, 0.4, 0.7 }, Density = 0.3, Glare = 3, Haze = 6, Offset = 0.6 },
    },
    TASER_TITLE = "[JB Hub] Anti Taser",
    TASER_STUN_KEY = "brr13yas", -- update 
    TASER_DECOY_KEY = "Stunned",
    TASER_KEY_PTR = 0x10,
    TASER_CHECK = 2,
    NERF_TITLE = "[JB Hub] Nerf Skins",
    NERF_TICK = 0.25,
    NERF_HELD_RANGE = 25,
    NERF_UNLOAD_WAIT = 15,
    NERF_NAME = 0x68, -- update
    NERF_DATA = 0x0,  -- update
    NERF_SIZE = 0x10, -- update
    NERF_CAP = 0x18,  -- update
    NERF_REF = 0x28,  -- update
    NERF_ICON_ATTR = "HotbarImageSrc",
    NERF_SWAPS = { Revolver = "NerfRevolver", Pistol = "NerfPistol" },
    NERF_BACK = { NerfRevolver = "Revolver", NerfPistol = "Pistol" },
    NERF_ICONS = {
        Revolver = "rbxassetid://16647917031",
        Pistol = "rbxassetid://16647913398",
        NerfRevolver = "rbxassetid://6930017845",
        NerfPistol = "rbxassetid://6930018123",
    },
    WORLD_CHUNK_NPC = 60,
    WORLD_CHUNK_SPIKE = 50,
    npcFolders = {},
    spikeModels = {},
    homeModels = {},
    guardFlag = {},
    ownerCache = {},
    ceoNext = {},
    GUARD_RECHECK = 2,
    GUARD_PER_TICK = 3,
    CEO_RECHECK = 0.6,
    BOUNTY_EVERY = 1,
    NPC_TICK = 0.05,
    GUARD_NEW_PER_TICK = 4,
    GUARD_MAINTAIN = 0.5,
    WORLD_CHUNK_FIRST = 80,
    worldReady = false,
    FRAME = 1 / 60,
    profile = false, -- debug
    offsetDebug = false, -- debug
    PROFILE_EVERY = 5,
    equipVersion = 0,
    equipSeen = {},
    equipRaw = 0,
    JOB_BATCH_DELAY = 1.5,
    EQUIP_WATCH_TICK = 0.15,
    stats = {},
    SHOOT_TITLE = "[JB Hub] Auto Shoot",
    SHOOT_TRIES = 1,
    SHOOT_REAPPLY = 2,
    SHOOT_BOOL_TAG = 1,	
}
local COSMETICS = {
    TITLE = "[JB Hub] Cosmetics",
    KEY = 0x46,
    requested = false,
    lastFlip = 0,
    bindActive = false,
    bindNotify = false,
    leftAt = nil,
    EXIT_GRACE = 0.1,
    PLATE = { id = "cosPlate", props = { "LicensePlate" } },
    PLATE_TEXT = "JB Hub",
    SLOTS = {
        {
            id = "cosColor",
            label = "Color",
            props = { "BodyColor", "SecondBodyColor", "WheelColor", "SpoilerColor" },
            list = { "None", "Black", "HyperShift", "HyperBlueLvl5", "HyperDiamondLvl5", "HyperPinkLvl5", "HyperPurpleLvl5", "HyperOrangeLvl5", "HyperYellowLvl5", "HyperRedLvl5", "HyperGreenLvl5", "Vantablack" },
        },
        {
            id = "cosTexture",
            label = "Texture",
            props = { "Texture", "SecondTexture" },
            list = { "None", "Checker", "Drip", "Snowstorm", "GalacticCarbon", "Earthquake", "BlackIce", "BluePixel", "Fire", "Manga", "Tiger", "OrangePixel", "Pixel", "Armor" },
        },
        {
            id = "cosHorn",
            label = "Horn",
            props = { "Horn" },
            list = { "None", "Original", "Cucaracha", "ChampionTrumpets", "Winner", "Injan" },
        },
        {
            id = "cosRim",
            label = "Rim",
            props = { "Rim" },
            list = { "None", "Void", "LaserCannon", "RTX", "Radar", "Storm", "BluePortal", "Retrowave", "Live2024", "Live2026", "Pixeltary", "INF1N1TY" },
        },
        {
            id = "cosSpoiler",
            label = "Spoiler",
            props = { "Spoiler" },
            list = { "None", "Thrusters", "CashSpitter", "OG Rocket Thrusters", "DualRockets", "Ghost Catcher", "Afterburner" },
        },
        {
            id = "cosTire",
            label = "Tire Style",
            props = { "TireMesh" },
            list = { "None", "Brickset", "Spiked", "SnowTrail", "Snowchain", "Voltline", "Glacier" },
        },
        {
            id = "cosTireSticker",
            label = "Tire Sticker",
            props = { "TireSticker" },
            list = { "None", "Blue50", "JailbreakArmy", "Red50", "Japanese", "3Billion", "Lightning" },
        },
    },
}
local KILLAURA_KEY = 0x47
local GUARD_TAG  = "GuardNPC"
local LASER_TINY = Vector3.new(0.001, 0.001, 0.001)
local LASER_REFRESH = 2
local LASER_TICK = 0.25
local LASER_CONTAINERS = {
    { "Banks", sub = "Lasers" },
    { "MansionRobbery", "LaserTraps" },
	{ "MansionDetails", only = "BarbedWire" },
    { "Museum", "CaseLasers" },
	{ "Museum", "Lights", only = "Light" },
    { "OilRig", "MovingLasers" },
    { "Casino", "VaultLaserControl" },
    { "Casino", "LasersMoving" },
    { "Casino", "LaserCarousel" },
    { "Casino", "Lasers" },
	{ "Casino", "CamerasMoving" },
    { "MilitaryIsland", "MilitaryLasers" },
	{ "Interior_MaxSecurity", only = "BarbedWire" },
	{ "TombRocks1", only = "BarbedWire" },
    { "TombRocks2", only = "BarbedWire" },
--	{ "RobberyTomb", "Cart", only = "Wood" },
--  { "RobberyTomb", "Kill" },
    { "Jewelrys" },
    { "Jewelry" },
}
local LASER_SKIP_NAMES = { TouchToEnter = true, HatchTouch = true, TriggerDoor = true }
local TURRET_CONTAINERS = {
    { "OilRig", "Turrets" },
}
local TURRET_MODELS = {
    { "CargoShip", "TurretFront" },
    { "CargoShip", "TurretBack" },
}
local TURRET_TICK = 1
local TURRET_TITLE = "[JB Hub] No Turret Damage"
local TURRET_DEFAULT_HZ = 6
local CARGO = {
    FREEZE = 1e15,
    RESCAN = 15,
    PAIR_RANGE = 0x400,
    RESCAN_SLOW = 120,
    HOME_RESCAN = 5,
}
local MIL_TURRET_KEYS = { "TURRET_DAMAGE", "FIRE_RATE" }
local MIL_TURRET_VALUES = { TURRET_DAMAGE = 0, FIRE_RATE = 1e9 }
local MIL_TURRET_DEFAULTS = { TURRET_DAMAGE = 6, FIRE_RATE = 0.1 }
local MIL_TURRET_RESCAN = 5
local DART_AWAY_Y = -10000
local BRIDGE_FLAT_ANGLE = 0.0001
local BRIDGE_FROZEN_DURATION = 1e9
local BRIDGE_SETTLE_TIME = 3

local PLASMA_BURST = 4
local PLASMA_ITEM_NAME = "PlasmaPistol"
local PLASMA_MAX_AMMO = 20
local PLASMA_MAX_DISTANCE = 190
local PLASMA_TICK = 0.05
local PLASMA_EQUIP_INTERVAL = 0.5
local PLASMA_RELOAD_WAIT = 0.6
local PLASMA_IDLE_TIME = 0.4
local PLASMA_SHOOT_TO_DAMAGE = 0.02
local INSTANT_PLASMA_SCAN_KEYS = { "FireFreq", "ReloadTime", "MagSize", "Range", "Damage" }
local INSTANT_PLASMA_TARGETS = { FireFreq = 60, ReloadTime = 0.1 }
local INSTANT_PLASMA_WINDOW = 512
local INSTANT_PLASMA_SCAN_TRIES = 6
local INSTANT_PLASMA_TICK = 0.25

local FLOW_KEY = 0x67
local FLOW_START_DELAY = 2
local FLOW_SCALE = 1.25
local FLOW_SETTLE_WAIT = 0.06
local FLOW_PRESS_WAIT = 0.06
local FLOW_STEP_COUNT = 4
local FLOW_STEP_WAIT = 0.015
local FLOW_CELL_WAIT = 0.03
local FLOW_RELEASE_WAIT = 0.08
local FLOW_SOLVED_TIMEOUT = 3
local FLOW_PATH_THICKNESS = 6
local FLOW_PATH_REFRESH = 0.25
local FLOW_BASE_COLORS = {
    Color3.fromRGB(255, 0, 0),
    Color3.fromRGB(0, 120, 255),
    Color3.fromRGB(189, 0, 255),
    Color3.fromRGB(255, 154, 0),
    Color3.fromRGB(1, 255, 31),
}

local ESP_TARGETS = {
    Key = { id = "keycardEsp", label = "KEYCARD", title = "[JB Hub] Keycard ESP", color = Color3.fromRGB(0, 140, 255), parts = { "Handle" } },
    CrimeKey = { id = "crimekeyEsp", label = "CRIMEKEY", title = "[JB Hub] Crimekey ESP", color = Color3.fromRGB(255, 210, 0), parts = { "Handle" } },
    Drop = { id = "airdropEsp", label = "AIRDROP", title = "[JB Hub] Airdrop ESP", color = Color3.fromRGB(148, 96, 69), parts = { "Particles", "Root", "Handle" }, colorFrom = "Top", box = { "Bottom", "Top", "Root" }, textMin = 12, boxMin = 12 },    
	Cash = { id = "cashEsp", label = "CASH", title = "[JB Hub] Cash Dropped ESP", color = Color3.fromRGB(0, 220, 90), parts = { "BoundingBox", "Part" }, container = "DroppedCash", amountFrom = "Amount" },
    Bounty = {
        id = "bountyEsp",
        label = "BOUNTY",
        title = "[JB Hub] Bounty ESP",
        color = Color3.fromRGB(255, 60, 60),
        parts = {},
        container = "__players",
        modes = { "Color Based", "Custom Color" },
        gameColor = Color3.fromRGB(255, 0, 0),
        gameOutline = Color3.fromRGB(47, 0, 0),
        up = Vector3.new(0, 3, 0),
        down = Vector3.new(0, -3.2, 0),
        textMax = 13,
    },
}

local ESP_SEARCH_EVERY = 3
local PISTON_REFRESH = 10
local KILLAURA_KEY_CONFIRM = 0.15
local ESP_BOX_PADDING = 3
local ESP_BOX_MIN = 8
local ESP_TEXT_SIZE = 16
local ESP_TEXT_MIN = 10
PERF.ESP_MAX_PART_SIZE = 25
PERF.ESP_MAX_PARTS = 24
PERF.ESP_SKIP_PARTS = { Particles = true, Countdown = true }
PERF.ESP_PART_CLASS = { Part = true, MeshPart = true, UnionOperation = true, WedgePart = true, CornerWedgePart = true, TrussPart = true }
local ESP_TEXT_NEAR = 30
local ESP_TEXT_FAR = 500
local ESP_SCREEN_HEIGHT = 1080

local ALL_IDS = { "puzzleSolve", "puzzlePath", "nofall", "nolaser", "noturret", "noForcefield", "antiTaser", "nosit", "casino", "casinoOpen", "autoVault", "autoGlass", "autoLoot", "autoHack", "keycardEsp", "crimekeyEsp", "airdropEsp", "cashEsp", "bountyEsp", "killNpcs", "guards", "attackCeo", "npcHitbox", "swordNoCd", "swordLunge", "punchNoCd", "rocketLock", "instant", "plasma", "norecoil", "nospread", "autoShoot", "nitro", "jetpack", "unlockSlots", "nerfSkins", "plasmaKillaura", "cosmeticsBind", "cosmeticsLoop", "cosPlate", "carFly", "engineBoost", "instantBrake", "antiTirePop", "antiFlip", "tombDarts", "tombSpikes", "tombBridge", "tombCart", "ppWire", "ppPistons", "skyColor", "skinChanger", "hitSound", "autoTaser", "autoCuff", "waterCustom", "timeChanger", "timeCycle", "matrixMode", "robHud", "hitMarker", "hitKill", "resetBind", "elevLoop", "hubRoles", "antiAfk" }

PERF.SKIN_IDS = { "Drip", "Aurora", "BlackIce", "CircuitBoard", "WhiteMarble" }
PERF.SKIN_WEAPONS = { "AK47", "Rifle", "Pistol", "Revolver", "PlasmaPistol", "PlasmaShotgun", "RocketLauncher", "Sniper" }
PERF.SKIN_LABELS = {}
PERF.SKIN_TARGETS = { "All Weapons" }
for i, n in ipairs(PERF.SKIN_IDS) do PERF.SKIN_LABELS[i] = (n:gsub("(%l)(%u)", "%1 %2")) end
for _, n in ipairs(PERF.SKIN_WEAPONS) do PERF.SKIN_TARGETS[#PERF.SKIN_TARGETS + 1] = (n:gsub("(%l)(%u)", "%1 %2")) end
PERF.WATER_NAMES = { "Original", "Clear", "Turquoise", "Dark", "Blood" }
PERF.WATER_PRESETS = {
    false,
    { color = { 0.16, 0.47, 0.5 }, transparency = 0.85, reflectance = 0.35 },
    { color = { 0.05, 0.55, 0.58 }, transparency = 0.65, reflectance = 0.5 },
    { color = { 0.02, 0.05, 0.08 }, transparency = 0.08, reflectance = 0.85 },
    { color = { 0.42, 0.02, 0.03 }, transparency = 0.22, reflectance = 0.45 },
}
PERF.MATRIX = {
    TITLE = "[JB Hub] Matrix Mode",
    COLOR = 0x11C, -- update
    CC_OFF = { Tint = 0xA0, Brightness = 0xAC, Contrast = 0xB0, Saturation = 0xB4 }, -- update
    ATMOS = { Color = { 0.0, 0.35, 0.12 }, Decay = { 0.0, 0.08, 0.02 }, Density = 0.45, Glare = 0, Haze = 2.5, Offset = 0.05 },
    CC = { Tint = { 0.4, 1.0, 0.5 }, Brightness = -0.12, Contrast = 0.55, Saturation = -0.5 },
    WATER = { Color = { 0.0, 0.85, 0.3 }, Reflectance = 0.25, Transparency = 0.35 },
    PARTS = { Part = true, MeshPart = true, UnionOperation = true, WedgePart = true, CornerWedgePart = true, TrussPart = true },
    CHUNK = 1500,
    RESCAN = 15,
}
PERF.TIME = {
    TITLE = "[JB Hub] Time Changer",
    LIGHT = 0x150, -- update
    SUN = 0x160, -- update
    MOON = 0x16C, -- update
    SOURCE = 0x15C, -- update
    CS_TOP = 0xC4, -- update
    CS_BOT = 0xD0, -- update
    NOON_TINT = { 0.978, 0.978, 0.989 },
    DUSK_TINT = { 0.0625, 0.0558, 0.105 },
    TILT = 0.35,
    PRESETS = { "Custom", "Dawn", "Morning", "Noon", "Sunset", "Dusk", "Night", "Midnight" },
    HOURS = { false, 6, 9, 12, 18, 19.5, 22, 0 },
    KEYS = {
        { h = 0, bright = -0.28, tint = { 0.55, 0.65, 1.0 }, color = { 0.08, 0.1, 0.22 }, decay = { 0.02, 0.03, 0.08 }, density = 0.36, haze = 1.2 },
        { h = 5, bright = -0.22, tint = { 0.6, 0.65, 0.95 }, color = { 0.15, 0.15, 0.3 }, decay = { 0.05, 0.05, 0.12 }, density = 0.34, haze = 1.5 },
        { h = 6.5, bright = -0.06, tint = { 1.0, 0.82, 0.72 }, color = { 1.0, 0.62, 0.45 }, decay = { 0.6, 0.3, 0.2 }, density = 0.32, haze = 2.2 },
        { h = 9, bright = 0.02, tint = { 1.0, 0.97, 0.92 }, color = { 0.85, 0.85, 0.9 }, decay = { 0.85, 0.85, 0.9 }, density = 0.27, haze = 1 },
        { h = 12, bright = 0.06, tint = { 1.0, 1.0, 1.0 }, color = { 0.78, 0.86, 1.0 }, decay = { 0.9, 0.95, 1.0 }, density = 0.24, haze = 0.5 },
        { h = 16, bright = 0.03, tint = { 1.0, 0.96, 0.9 }, color = { 0.9, 0.85, 0.8 }, decay = { 0.85, 0.75, 0.65 }, density = 0.27, haze = 1 },
        { h = 18, bright = -0.03, tint = { 1.0, 0.75, 0.6 }, color = { 1.0, 0.55, 0.35 }, decay = { 0.7, 0.3, 0.15 }, density = 0.32, haze = 2.4 },
        { h = 19.5, bright = -0.14, tint = { 0.85, 0.65, 0.8 }, color = { 0.5, 0.3, 0.45 }, decay = { 0.25, 0.1, 0.2 }, density = 0.34, haze = 2 },
        { h = 21, bright = -0.26, tint = { 0.58, 0.66, 1.0 }, color = { 0.1, 0.12, 0.25 }, decay = { 0.03, 0.04, 0.1 }, density = 0.36, haze = 1.3 },
        { h = 24, bright = -0.28, tint = { 0.55, 0.65, 1.0 }, color = { 0.08, 0.1, 0.22 }, decay = { 0.02, 0.03, 0.08 }, density = 0.36, haze = 1.2 },
    },
}
PERF.WATER_OFF = { Color = 0x1C8, Reflectance = 0x1E0, Transparency = 0x1E4, WaveSize = 0x1E8, WaveSpeed = 0x1EC } -- update
pcall(function()
    local data = game:GetService("HttpService"):JSONDecode(game:HttpGet("https://offsets.imtheo.lol/Offsets.json"))
    PERF.offsetsOk = type(data) == "table" and type(data.Offsets) == "table"
    PERF.robloxVersion = data and data["Roblox Version"]
    PERF.dump = data and data.Offsets
    local t = data and data.Offsets and data.Offsets.Terrain
    if type(t) ~= "table" then return end
    local map = { Color = "WaterColor", Reflectance = "WaterReflectance", Transparency = "WaterTransparency", WaveSize = "WaterWaveSize", WaveSpeed = "WaterWaveSpeed" }
    PERF.dumpWater = {}
    for key, field in pairs(map) do
        local v = tonumber(t[field])
        if v and v > 0 and v < 0x4000 then PERF.dumpWater[key] = v end
    end
end)
if PERF.offsetsOk then
    SPLASH.step("Offset dump downloaded  " .. tostring(PERF.robloxVersion or "?"), 25)
else
    SPLASH.step("Offset dump unreachable, using built-in values", 25, "warn")
end
PERF.HIT_SOUNDS = { { "Rust", 1255040462 }, { "Bonk", 5766898159 } }
PERF.HIT_LABELS = {}
for i, s in ipairs(PERF.HIT_SOUNDS) do PERF.HIT_LABELS[i] = s[1] end
PERF.HITFX_MARKERS = { "Cross", "Rust" }
PERF.HB = {
    TITLE = "[JB Hub] NPC's Hitbox Expander",
    TR_OFF = 0x118, -- update
    TICK = 0.03,
    VERIFY = 1,
    YOUNG = 3,
    YOUNG_VERIFY = 0.2,
    REFRESH_DELAY = 0.6,
    REFRESH_PER_TICK = 4,
    REFRESH_CAP = 3,
    REFRESH_WINDOW = 10,
    SLIDER_DELAY = 0.4,
    MANSION_EVERY = 3,
    ALPHA = 0.5,
    COLOR = { 255, 40, 40 },
}
PERF.TASE = {
    TITLE = "[JB Hub] Auto Taser",
    KEY = 0x72,
    RANGE = 85,
    GAME_RANGE = 85,
    SAFETY = 2.2,
    LATENCY = 0.035,
    ITERATIONS = 4,
    EQUIP_TIME = 0.6,
    DEBUG = false,
    active = false,
    me = { vel = Vector3.new(0, 0, 0) },
    tracks = {},
    charSet = {},
    teamCache = {},
}
PERF.CUFF = {
    TITLE = "[JB Hub] Instant Auto Cuff",
    KEY = 0x71,
    KEY_E = 0x45,
    EQUIP_RANGE = 25,
    MAX_H = 9.9,
    MAX_V = 13.9,
    TAP = 0.05,
    RESULT_TIMEOUT = 0.6,
    HOLD_TIMEOUT = 1.6,
    RETRY = 0.6,
    CONFIG_RESCAN = 5,
    engaged = false,
}

local defs = {
    swordNoCd  = { label = "Sword No Cooldown",   keys = { "ReloadTime" }, vals = { ReloadTime = 0 } },
    swordLunge = { label = "Sword Always Lunge",  keys = { "SwingLunge" }, vals = { SwingLunge = -1 } },
    instant    = { label = "Instant Interaction", keys = { "Duration" },   vals = { Duration = 0 } },
    norecoil   = {
        label = "No Recoil",
        keys  = { "CamShakeMagnitude" },
        vals  = { CamShakeMagnitude = 0 },
    },
    nospread   = {
        label = "No Spread",
        keys  = { "BulletSpread" },
        vals  = { BulletSpread = 0 },
    },
    jetpack    = { label = "Infinity Jetpack", keys = { "LocalFuel", "LocalMaxFuel", "ThrustingBornAt" }, vals = { LocalFuel = 999999, LocalMaxFuel = 999999, ThrustingBornAt = 0 }, every = 20 },
}

local notified = {}
local REAPPLY_EVERY = 180
local SPRING_RESCAN_EVERY = 30
local HEAVY_COOLDOWN = 1.5  
local SIT_PRIORITY = 2    
local lastSitAt = 0 
local casinoRequested = false
local lastCasinoShown = 0
local casinoOpenRequested = false
local vaultRequested = false
local lastCasinoOpen = 0
local flowRequested = false
local JOB_ORDER = { "swordNoCd", "swordLunge", "instant", "norecoil", "nospread", "springs" }
local nextApply = {}
local springTargets = {}
local resetting = false
local gcBusy = false
local function lockedGetgc(keys)
    if keys == true then
        while gcBusy or PERF.solving or PERF.flying do task.wait(0.05) end
        gcBusy = true
        local ok, result = pcall(getgc, true)
        gcBusy = false
        return ok and result or {}
    end
    local batch = PERF.gcBatch
    if not batch then
        batch = { keys = {}, done = false, result = {}, lastAdd = tick(), born = tick() }
        PERF.gcBatch = batch
        task.spawn(function()
            repeat task.wait(0.1) until tick() - batch.lastAdd >= 1.5 or tick() - batch.born >= 6
            while gcBusy or PERF.solving or PERF.flying do task.wait(0.05) end
            PERF.gcBatch = nil
            local list = {}
            for k in pairs(batch.keys) do list[#list + 1] = k end
            gcBusy = true
            local ok, result = pcall(getgc, list)
            gcBusy = false
            batch.result = ok and result or {}
            batch.done = true
        end)
    end
    local want = {}
    for _, k in ipairs(keys) do
        if not batch.keys[k] then batch.lastAdd = tick() end
        batch.keys[k] = true
        want[k] = true
    end
    while not batch.done do task.wait(0.03) end
    local out = {}
    for _, e in ipairs(batch.result) do
        if want[tostring(e.key)] then out[#out + 1] = e end
    end
    return PERF.gcTrack(out)
end

PERF.holdKb = {}
function PERF.keyDown(name, default)
    local kb = PERF.holdKb[name]
    if kb then
        local ok, k = pcall(function() return kb:GetKey() end)
        if ok and type(k) == "number" then
            if k == 0 then return false end
            local okP, d = pcall(iskeypressed, k)
            return okP and d == true
        end
        local okE, on = pcall(function() return kb:IsEnabled() end)
        if okE and type(on) == "boolean" then return on end
    end
    local okP, d = pcall(iskeypressed, default)
    return okP and d == true
end

PERF.wsCache = {}
function PERF.ws(name)
    local e = PERF.wsCache[name]
    local now = tick()
    if e then
        if e.inst then
            local ok, parent = pcall(function() return e.inst.Parent end)
            if ok and parent then return e.inst end
        elseif now - e.at < 5 then
            return nil
        end
    end
    local inst = workspace:FindFirstChild(name)
    PERF.wsCache[name] = { inst = inst, at = now }
    return inst
end

function PERF.gcTrack(list)
    for _, e in ipairs(list) do
        local a = tonumber(e.addr)
        if a and e.kp == nil then
            local okK, kp = pcall(memory_read, "uintptr_t", a + 0x10)
            local okT, tg = pcall(memory_read, "int", a + 12)
            e.kp = okK and kp or 0
            e.tg = okT and tg or -1
        end
    end
    return list
end

function PERF.applyChunked(list, vals)
    local n = #list
    if n <= 200 then
        pcall(applygc, list, vals)
        return
    end
    for i = 1, n, 200 do
        local part = {}
        for j = i, math.min(i + 199, n) do part[#part + 1] = list[j] end
        pcall(applygc, part, vals)
        task.wait()
    end
end

function PERF.gcAlive(list)
    local out = {}
    for _, e in ipairs(list or {}) do
        local a = tonumber(e.addr)
        if a and e.kp and e.kp > 4096 then
            local okK, kp = pcall(memory_read, "uintptr_t", a + 0x10)
            local okT, tg = pcall(memory_read, "int", a + 12)
            if okK and okT and kp == e.kp and tg == e.tg then out[#out + 1] = e end
        end
    end
    return out
end

function PERF.numericOnly(list)
    local out = {}
    for _, e in ipairs(list or {}) do
        if e.tg == 3 then out[#out + 1] = e end
    end
    return out
end

function PERF.primValid(part, p)
    if not p or not part then return false end
    local okP, parent = pcall(function() return part.Parent end)
    if not okP or not parent then return false end
    local base = tonumber(part.Address)
    if not base or base <= 4096 then return false end
    local ok, cur = pcall(memory_read, "uintptr_t", base + PRIMITIVE_OFFSET)
    return ok and cur == p
end
local lastZoneScan = 0

local function count(t)
    local n = 0
    pcall(function() for _ in ipairs(t) do n = n + 1 end end)
    return n
end

local function isOn(base)
    return UI.GetValue(uid(base))
end

local function getHumanoid()
    local char = game:GetService("Players").LocalPlayer.Character
    return char and (char:FindFirstChild("Humanoid") or char:FindFirstChildOfClass("Humanoid"))
end

local function getHRP()
    local char = game:GetService("Players").LocalPlayer.Character
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
end

local function keybindActive(kb)
    if not kb then return false end
    local ok, v = pcall(function() return kb:IsEnabled() end)
    if ok and type(v) == "boolean" then return v end
    ok, v = pcall(function() return kb.value end)
    return ok and v == true
end

local function destroySeatWeld()
    pcall(function()
        local hrp = getHRP()
        if not hrp then return end
        for _, d in ipairs(game:GetService("Workspace"):GetDescendants()) do
            local ok, cls = pcall(function() return d.ClassName end)
            if ok and (cls == "Weld" or cls == "WeldConstraint") then
                local p0, p1
                pcall(function() p0 = d.Part0 end)
                pcall(function() p1 = d.Part1 end)
                if p0 == hrp or p1 == hrp then
                    local other = (p0 == hrp) and p1 or p0
                    local ocls
                    pcall(function() ocls = other and other.ClassName end)
                    if d.Name == "SeatWeld" or ocls == "Seat" or ocls == "VehicleSeat" then
                        pcall(function() d:Destroy() end)
                    end
                end
            end
        end
    end)
end

local function killSit()
    pcall(function()
        local hum = getHumanoid()
        if not hum then return end
        local addr = tonumber(hum.Address)
        if not addr or addr <= 4096 then return end
        local sit = 0
        pcall(function() sit = memory_read("byte", addr + SIT_OFFSET) end)
        if sit == 1 then
            lastSitAt = tick()
            destroySeatWeld()
            pcall(function() memory_write("byte", addr + SIT_OFFSET, 0) end)
        end
    end)
end

function PERF.run(name, fn)
    if not PERF.profile then return pcall(fn) end
    local prev = PERF.runCur
    PERF.runCur = name
    local f0 = PERF.frameNo
    local t0 = os.clock()
    local ok, err = pcall(fn)
    local dt = os.clock() - t0
    PERF.runCur = prev
    local st = PERF.stats[name]
    if not st then
        st = { total = 0, max = 0, calls = 0, slow = 0, waits = 0, errors = 0, errs = {} }
        PERF.stats[name] = st
    end
    st.calls = st.calls + 1
    if PERF.frameNo ~= f0 then
        st.waits = st.waits + 1
    else
        st.total = st.total + dt
        if dt > st.max then st.max = dt end
        if dt > 0.008 then st.slow = st.slow + 1 end
        PERF.frameWork[name] = (PERF.frameWork[name] or 0) + dt
    end
    if not ok then
        st.errors = st.errors + 1
        local msg = tostring(err):sub(1, 160)
        st.errs[msg] = (st.errs[msg] or 0) + 1
    end
    return ok, err
end
 
PERF.frameWork = {}
PERF.frameNo = 0
function PERF.timed(name, fn, ...)
    if not PERF.profile then return fn(...) end
    local f0, t0 = PERF.frameNo, os.clock()
    local r = table.pack(fn(...))
    local dt = os.clock() - t0
    if PERF.frameNo == f0 then
        local st = PERF.stats[name]
        if not st then
            st = { total = 0, max = 0, calls = 0, slow = 0, waits = 0, errors = 0, errs = {} }
            PERF.stats[name] = st
        end
        st.total, st.calls = st.total + dt, st.calls + 1
        if dt > st.max then st.max = dt end
        if dt > 0.008 then st.slow = st.slow + 1 end
        PERF.frameWork[name] = (PERF.frameWork[name] or 0) + dt
    end
    return table.unpack(r, 1, r.n)
end
function PERF.profileHooks()
    if PERF.hooked then return end
    PERF.hooked = true
    local c = { memr = 0, memw = 0, gc = 0, gcTime = 0, gcMax = 0, draw = 0, drawTotal = 0, drawBy = {}, notify = 0, notifyBy = {}, memBy = {} }
    PERF.cnt = c
    local function who() return PERF.runCur or "other" end
    local mr, mw, gg, nt = memory_read, memory_write, getgc, notify
    if mr then memory_read = function(...) c.memr = c.memr + 1 local w = who() c.memBy[w] = (c.memBy[w] or 0) + 1 return mr(...) end end
    if mw then memory_write = function(...) c.memw = c.memw + 1 local w = who() c.memBy[w] = (c.memBy[w] or 0) + 1 return mw(...) end end
    if gg then
        getgc = function(...)
            local t0 = os.clock()
            local r = { gg(...) }
            local dt = os.clock() - t0
            c.gc, c.gcTime = c.gc + 1, c.gcTime + dt
            if dt > c.gcMax then c.gcMax = dt end
            return table.unpack and table.unpack(r) or unpack(r)
        end
    end
    if nt then
        notify = function(text, title, ...)
            c.notify = c.notify + 1
            local k = tostring(title)
            c.notifyBy[k] = (c.notifyBy[k] or 0) + 1
            return nt(text, title, ...)
        end
    end
    pcall(function()
        local dn = Drawing.new
        Drawing.new = function(...)
            c.draw, c.drawTotal = c.draw + 1, c.drawTotal + 1
            local w = who()
            c.drawBy[w] = (c.drawBy[w] or 0) + 1
            return dn(...)
        end
    end)
end
 
function PERF.profileLog(lines)
    for _, l in ipairs(lines) do print(l) end
    PERF.profileBuf = PERF.profileBuf or {}
    for _, l in ipairs(lines) do PERF.profileBuf[#PERF.profileBuf + 1] = l end
    while #PERF.profileBuf > 3000 do table.remove(PERF.profileBuf, 1) end
    pcall(makefolder, "JB Hub")
    pcall(writefile, "JB Hub/profile.log", table.concat(PERF.profileBuf, "\n"))
end

PERF.HYBRID_IDS = { "casinoOpen", "autoVault", "autoGlass", "autoLoot", "autoHack", "plasmaKillaura", "cosmeticsBind", "cosmeticsLoop", "autoTaser", "autoCuff", "elevLoop" }
PERF.HYBRID_OK_CACHE = 10
PERF.HYBRID_FAIL_CACHE = 2

function PERF.probeHybrid()
    local remote = game:GetService("ReplicatedStorage"):FindFirstChild("PostieReceived")
    if not remote then return nil end
    for _ = 1, 2 do
        local id = string.format("%08x%08x", math.random(0, 0x7FFFFFFF), math.random(0, 0x7FFFFFFF))
        local t0 = os.clock()
        local ok, ret = pcall(function() return remote:FireServer(id, false) end)
        local dt = os.clock() - t0
        if not ok then return nil end
        if ret == true then return true end
        if dt >= 0.02 then return true end
        if dt < 0.001 then return false end
    end
    return nil
end

function PERF.isHybrid()
    local now = tick()
    local cache = PERF.hybridState and PERF.HYBRID_OK_CACHE or PERF.HYBRID_FAIL_CACHE
    if PERF.hybridAt and now - PERF.hybridAt < cache then return PERF.hybridState end
    if PERF.hybridChecking then
        while PERF.hybridChecking do task.wait(0.03) end
        return PERF.hybridState
    end
    PERF.hybridChecking = true
    local r = PERF.probeHybrid()
    if r == nil then r = PERF.hybridState or false end
    PERF.hybridState, PERF.hybridAt, PERF.hybridChecking = r, tick(), false
    return r
end

function PERF.requireHybrid(title)
    if PERF.isHybrid() then return true end
    notify("Hybrid Mode required - enable it in Matcha first", title or "[JB Hub]", 4)
    return false
end

function PERF.gcValueMatches(e, target)
    local text = tostring(e.value)
    local kind = type(target)
    if kind == "number" then return tonumber(text) ~= nil end
    if kind == "boolean" then return text == "true" or text == "false" end
    return true
end

function PERF.inGame()
    local ok, res = pcall(function()
        local lp = game:GetService("Players").LocalPlayer
        return lp ~= nil and lp.Parent ~= nil and lp.Character ~= nil and workspace.Parent ~= nil
    end)
    return ok and res == true
end

PERF.rawNotify = notify
notify = function(...)
    if PERF.muteNotifyUntil and tick() < PERF.muteNotifyUntil then return end
    return PERF.rawNotify(...)
end

function PERF.notifySafe(text, title, duration)
    task.spawn(function()
        task.wait(1.5)
        if _G.JB_gen == myGen and PERF.inGame() then
            notify(text, title, duration)
        end
    end)
end

PERF.PROTECTED = { instant = { 5.6, 10 } }
PERF.protectedExtra, PERF.protectedAt = {}, 0

function PERF.briefcaseTimings(force)
    if not force and tick() - PERF.protectedAt < 10 then return PERF.protectedExtra end
    PERF.protectedAt = tick()
    local list = {}
    for i, c in ipairs(workspace:GetChildren()) do
        if i % 300 == 0 then task.wait() end
        if c.ClassName == "Model" and c:FindFirstChild("Walls") and c:FindFirstChild("Particles") then
            local ok, v = pcall(function() return c:GetAttribute("BriefcaseOpenTiming") end)
            if ok and type(v) == "number" and v > 0 then list[#list + 1] = v end
        end
    end
    PERF.protectedExtra = list
    return list
end

function PERF.cuffAnchors()
    if PERF.cuffAnchorList then return PERF.cuffAnchorList end
    local list = {}
    for _, e in ipairs(lockedGetgc({ "ArrestDistance" })) do
        local v, a = tonumber(tostring(e.value)), tonumber(e.addr)
        if v == 10 and a then list[#list + 1] = a end
    end
    if #list > 0 then PERF.cuffAnchorList = list end
    return list
end

function PERF.filterProtected(id, list, force)
    local protected = PERF.PROTECTED[id]
    if not protected then return list end
    local extra = id == "instant" and PERF.briefcaseTimings(force) or {}
    local anchors = id == "instant" and PERF.cuffAnchors() or {}
    local out = {}
    for _, e in ipairs(list) do
        local ok, v = pcall(memory_read, "double", tonumber(e.addr))
        local skip = false
        if ok and type(v) == "number" then
            for _, p in ipairs(protected) do
                if math.abs(v - p) < 1e-4 then skip = true break end
            end
            if not skip then
                for _, p in ipairs(extra) do
                    if math.abs(v - p) < 1e-4 then skip = true break end
                end
            end
        end
        if not skip then
            local a = tonumber(e.addr)
            for _, c in ipairs(anchors) do
                if a and math.abs(a - c) <= 512 then
                    skip = true
                    if ok and v == 0 then pcall(memory_write, "double", a, 0.5) end
                    break
                end
            end
        end
        if not skip then out[#out + 1] = e end
    end
    return out
end

function PERF.isGuard(m)
    local key = m.Address
    local v = PERF.guardFlag[key]
    if v == true then return true end
    local now = tick()
    if type(v) == "number" and now < v then return false end
    if m:GetAttribute("GuardTriggerPressFreq") ~= nil then
        PERF.guardFlag[key] = true
        return true
    end
    PERF.guardFlag[key] = now + 0.25
    return false
end

function PERF.ownerOf(g)
    local key = g.Address
    local now = tick()
    local c = PERF.ownerCache[key]
    if c and now < c.at then return c.id end
    local id = tonumber(g:GetAttribute("NPCNetworkOwnerId"))
    PERF.ownerCache[key] = { id = id, at = now + PERF.GUARD_RECHECK + math.random() }
    return id
end

local function getGuards(folders)
    local guards = {}
    for _, folder in ipairs(folders) do
        pcall(function()
            for _, m in ipairs(folder:GetChildren()) do
                if PERF.isGuard(m) then
                    guards[#guards + 1] = m
                end
            end
        end)
    end
    return guards
end

local function getNpcRange()
    local range = tonumber(UI.GetValue(uid("npcRange"))) or 150
    local myPos = nil
    pcall(function()
        local char = game:GetService("Players").LocalPlayer.Character
        myPos = char:FindFirstChild("HumanoidRootPart").Position
    end)
    return myPos, range
end

local function npcInRange(g, myPos, range)
    if not myPos then return true end
    local ok, dist = pcall(function()
        return (g:FindFirstChild("HumanoidRootPart").Position - myPos).Magnitude
    end)
    return not ok or dist <= range
end

local function disableGuard(g, originals)
    local key = g.Address
    local o = originals[key]
    if not o then
        o = { guard = g }
        originals[key] = o
    end
    local dist = g:GetAttribute("MaxShootDist")
    if dist ~= 0 then
        o.dist = dist
        g:SetAttribute("MaxShootDist", 0)
    end
    local freq = g:GetAttribute("GuardTriggerPressFreq")
    if freq ~= 0 then
        o.freq = freq
        g:SetAttribute("GuardTriggerPressFreq", 0)
    end
    if g:GetAttribute("NPCDestType") ~= 3 then
        local home = g:GetAttribute("NPCHomePosition")
        if home then pcall(function() g:SetAttribute("NPCDestPos", home) end) end
        g:SetAttribute("NPCDestType", 3)
    end
end

local function forceReset()
    resetting = true   
    task.spawn(function()
        local wrote = false
        pcall(function()
            for i = 1, 8 do
                local hum = getHumanoid()
                if hum then
                    local addr = tonumber(hum.Address)
                    if addr and addr > 4096 then
                        if pcall(function() memory_write("float", addr + HUM_HEALTH, 0) end) then wrote = true end
                    end
                end
                task.wait()
            end
        end)
        resetting = false
        notify(wrote and "Character reset" or "Reset failed", "[JB Hub] Force Reset", 3)
    end)
end

local function findZone()
    local ws = game:GetService("Workspace")
    local z = PERF.ws(NFD_NAME)
    if z then return z end
    if tick() - lastZoneScan < (PERF.zoneScanGap or 10) then return nil end
    PERF.zoneScanGap = math.min((PERF.zoneScanGap or 10) * 2, 120)
    local ok, all = pcall(function() return ws:GetDescendants() end)
    for i, d in ipairs(ok and all or {}) do
        if d.Name == NFD_NAME then
            PERF.zoneScanGap = 10
            lastZoneScan = tick()
            return d
        end
        if i % 3000 == 0 then task.wait() end
    end
    lastZoneScan = tick()
end

local function resolveLaserRoot(pathList)
    local cur = PERF.ws(pathList[1])
    for i = 2, #pathList do
        if not cur then return nil end
        cur = cur:FindFirstChild(pathList[i])
    end
    return cur
end

local function collectLaserParts(root, pathList, list, anchors)
    local parts = 0
    for i, d in ipairs(root:GetDescendants()) do
        if i % PERF.LASER_YIELD_EVERY == 0 then task.wait() end
        local cls = d.ClassName
        if cls == "TouchTransmitter" then
            local part = d.Parent
            if part then
                local name = part.Name
                if (not pathList.only or name == pathList.only) and not LASER_SKIP_NAMES[name] then
                    list[#list + 1] = part
                end
            end
        elseif anchors and (cls == "Part" or cls == "MeshPart") then
            parts = parts + 1
            if parts % PERF.LASER_ANCHOR_EVERY == 1 then
                pcall(function()
                    local p = d.Position
                    anchors[#anchors + 1] = p.X
                    anchors[#anchors + 1] = p.Z
                end)
            end
        end
    end
end

local function collectLaserPartsSafe(root, pathList, list)
    for i, d in ipairs(root:GetDescendants()) do
        if i % PERF.LASER_YIELD_EVERY == 0 then task.wait() end
        local isTouch = false
        pcall(function() isTouch = d.ClassName == "TouchTransmitter" end)
        if isTouch then
            local part
            pcall(function() part = d.Parent end)
            if part then
                local name
                pcall(function() name = part.Name end)
                if (not pathList.only or name == pathList.only) and not LASER_SKIP_NAMES[name] then
                    list[#list + 1] = part
                end
            end
        end
    end
end

local function getLaserBeams()
    local list = {}
    for _, pathList in ipairs(LASER_CONTAINERS) do
        local root = resolveLaserRoot(pathList)
        if root then
            local partial = {}
            if pcall(collectLaserParts, root, pathList, partial) then
                for _, part in ipairs(partial) do list[#list + 1] = part end
            else
                pcall(collectLaserPartsSafe, root, pathList, list)
            end
        end
    end
    return list
end

local function getPistonOrigins()
    local list = {}
    pcall(function()
        for _, model in ipairs(game:GetService("CollectionService"):GetTagged("Piston")) do
            local origin = model:FindFirstChild("PistonOrigin")
            if origin then list[#list + 1] = origin end
        end
    end)
    if #list == 0 then
        local plant = PERF.ws("PowerPlant")
        if plant then
            for _, d in ipairs(plant:GetDescendants()) do
                if d.Name == "PistonOrigin" then list[#list + 1] = d end
            end
        end
    end
    return list
end

local function vec(inst)
    local pos
    local ok = pcall(function() pos = inst.Position end)
    if ok and pos then
        local isVec = pcall(function() return pos.X + 0 end)
        if isVec then return pos end
    end
end

local cachedDoor = nil
local function getDoor()
    if cachedDoor then
        local ok, parent = pcall(function() return cachedDoor.Parent end)
        if ok and parent then return cachedDoor end
        cachedDoor = nil
    end
    local casino = PERF.ws("Casino")
    local door = casino and casino:FindFirstChild("RobberyDoor")
    if door then cachedDoor = door end
    return door
end

local function readCasinoCode()
    local casino = PERF.ws("Casino")
    if not casino then return nil, "Get closer to the casino" end
    local okOpen, isOpen = pcall(function() return casino:GetAttribute("CasinoRobberyOpen") end)
    if okOpen and isOpen == false then return nil, "Casino is closed" end
    local door = getDoor()
    local codesFolder = door and door:FindFirstChild("Codes")
    if not codesFolder then return nil, "Get closer to the casino" end

    local digits = {}
    local axis
    for _, v in ipairs(codesFolder:GetDescendants()) do
        if v:IsA("TextLabel") then
            local ok, t = pcall(function() return v.Text end)
            if ok and type(t) == "string" and t:match("^%d$") then
                local part, pos
                pcall(function()
                    part = v.Parent.Parent
                    pos = part.Position
                end)
                if pos then
                    if not axis then
                        pcall(function()
                            local r = part.CFrame.RightVector
                            if pcall(function() return r.X + 0 end) then
                                axis = Vector3.new(-r.X, -r.Y, -r.Z)
                            end
                        end)
                    end
                    table.insert(digits, { d = t, pos = pos })
                end
            end
        end
    end

    if #digits < 4 then return nil, "Code not loaded yet, get closer to the casino" end

    for _, e in ipairs(digits) do
        if axis then
            e.key = e.pos.X * axis.X + e.pos.Y * axis.Y + e.pos.Z * axis.Z
        else
            e.key = e.pos.X
        end
    end
    table.sort(digits, function(a, b) return a.key < b.key end)

    local code = ""
    for _, e in ipairs(digits) do
        code = code .. e.d
    end
    return code
end

local function showCasinoCode()
    local code, err = readCasinoCode()
    if code then
        notify(code, "[JB Hub] Casino Code", 5)
        pcall(function() setclipboard(code) end)
    else
        notify(err or "?", "[JB Hub] Casino Code", 3)
    end
end

local function requestCasinoCode()
    if tick() - lastCasinoShown < 0.6 then return end  
    if not UI.GetValue(uid("casino")) then return end
    lastCasinoShown = tick()
    showCasinoCode()
end

local cachedCasinoRemote = nil
local function getCasinoRemote()
    if cachedCasinoRemote then
        local ok, parent = pcall(function() return cachedCasinoRemote.Parent end)
        if ok and parent then return cachedCasinoRemote end
        cachedCasinoRemote = nil
    end
    local door = getDoor()
    local keypad = door and door:FindFirstChild("Keypad")
    local pad = keypad and keypad:FindFirstChild("Pad")
    local remote = pad and pad:FindFirstChild("CasinoKeypadSubmit")
    if remote then cachedCasinoRemote = remote end
    return remote
end

local function openCasinoDoor()
    local title = "[JB Hub] Open Casino Door"
    local casino = PERF.ws("Casino")
    local okOpen, isOpen = pcall(function() return casino and casino:GetAttribute("CasinoRobberyOpen") end)
    if not (okOpen and isOpen == true) then
        notify("Casino is closed", title, 3)
        return
    end
    local okTeam, team = pcall(function() return LocalPlayer.Team and LocalPlayer.Team.Name end)
    if okTeam and team ~= "Criminal" then
        notify("You must be a criminal", title, 3)
        return
    end
    local remote = getCasinoRemote()
    if not remote then
        notify("Casino keypad not found", title, 3)
        return
    end
    local code, err = readCasinoCode()
    if not code then
        notify(err or "Code not found", title, 3)
        return
    end
    pcall(function() setclipboard(code) end)
    local door = getDoor()
    local doorModel = door and door:FindFirstChild("Door")
    if doorModel and doorModel:GetAttribute("DoorOpen") == true then
        notify("The door is already open", title, 3)
        return
    end
    if not pcall(function() remote:FireServer(code) end) then
        notify("Failed to send the code", title, 3)
        return
    end
    local t0 = tick()
    while tick() - t0 < 2 do
        if doorModel and doorModel:GetAttribute("DoorOpen") == true then
            notify("Door opened with code " .. code, title, 4)
            return
        end
        task.wait(0.1)
    end
    local okD, dist = pcall(function() return (remote.Parent.Position - getHRP().Position).Magnitude end)
    if okD and type(dist) == "number" and dist > 12 then
        notify("Door stayed closed, get closer to the keypad and retry", title, 4)
    else
        notify("Code " .. code .. " sent but the door stayed closed", title, 4)
    end
end

local function requestCasinoOpen()
    if tick() - lastCasinoOpen < 0.6 then return end
    if not UI.GetValue(uid("casinoOpen")) then return end
    lastCasinoOpen = tick() + 2
    task.spawn(openCasinoDoor)
end

local function getPlasmaItem()
    local folder = game:GetService("Players").LocalPlayer:FindFirstChild("Folder")
    return folder and folder:FindFirstChild(PLASMA_ITEM_NAME)
end

local function getPlasmaRemote(name)
    local item = getPlasmaItem()
    return item and item:FindFirstChild(name)
end

local function getPlasmaAmmo()
    local item = getPlasmaItem()
    if not item then return nil end
    return item:GetAttribute("AmmoCurrent")
end

local function isPlasmaReloading()
    local item = getPlasmaItem()
    if not item then return false end
    return item:GetAttribute("IsReloading") == true
end

local PLASMA_TARGET_MODES = { "Police", "Criminal", "NPC Guards", "Mansion Boss" }

PERF.GUARD = { MODES = { "Off", "Bodyguard" }, TEAMS = { "All", "Police", "Criminal", "None" } }

local function getPlasmaTargetMode()
    local idx = tonumber(UI.GetValue(uid("plasmaKillauraTarget"))) or 0
    return PLASMA_TARGET_MODES[idx + 1] or "Police"
end

local plasmaDropMissAt = 0

local function getPlasmaDropFolder()
    local direct = PERF.ws("Drop")
    if direct then return direct end
    if tick() - plasmaDropMissAt < 2 then return nil end
    for _, root in ipairs({ game, workspace }) do
        for _, child in ipairs(root:GetChildren()) do
            local drop = child:FindFirstChild("Drop")
            if drop then return drop end
        end
    end
    plasmaDropMissAt = tick()
    return nil
end

local function getPlasmaTargetFromModel(model)
    if not model or not model:IsA("Model") then return nil end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return nil end
    local hrp = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart or model:FindFirstChild("Head") or model:FindFirstChildWhichIsA("BasePart")
    if not hrp then return nil end
    return { humanoid = hum, hrp = hrp }
end

local function addPlasmaTargetsFromFolder(folder, list)
    if not folder then return end
    for _, npc in ipairs(folder:GetChildren()) do
        local target = getPlasmaTargetFromModel(npc)
        if target then
            table.insert(list, target)
        end
    end
end

local plasmaContainerMissAt = {}

local function findPlasmaContainer(name)
    local direct = PERF.ws(name)
    if direct then return direct end
    if tick() - (plasmaContainerMissAt[name] or 0) < 2 then return nil end
    for _, root in ipairs({ game, workspace }) do
        for _, child in ipairs(root:GetChildren()) do
            local found = child:FindFirstChild(name)
            if found then return found end
        end
    end
    plasmaContainerMissAt[name] = tick()
    return nil
end

local function getPlasmaTargets()
    local list = {}
    local mode = getPlasmaTargetMode()
    if mode == "NPC Guards" then
        local drop = getPlasmaDropFolder()
        addPlasmaTargetsFromFolder(drop and drop:FindFirstChild("NPCs"), list)
        local mansion = findPlasmaContainer("MansionRobbery")
        addPlasmaTargetsFromFolder(mansion and mansion:FindFirstChild("GuardsFolder"), list)
        local oilRig = findPlasmaContainer("OilRig")
        addPlasmaTargetsFromFolder(oilRig and oilRig:FindFirstChild("GuardsFolder"), list)
        return list
    end
    if mode == "Mansion Boss" then
        local mansion = findPlasmaContainer("MansionRobbery")
        local target = getPlasmaTargetFromModel(mansion and mansion:FindFirstChild("ActiveBoss"))
        if target then
            table.insert(list, target)
        end
        return list
    end
    local lp = game:GetService("Players").LocalPlayer
    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
        if player ~= lp and player.Team and player.Team.Name == mode then
            local target = getPlasmaTargetFromModel(player.Character)
            if target then
                table.insert(list, target)
            end
        end
    end
    return list
end

local function isPlasmaTargetValid(target)
    local ok, valid = pcall(function()
        return target.humanoid.Parent ~= nil and target.hrp.Parent ~= nil and target.humanoid.Health > 0
    end)
    return ok and valid
end

local function isPlasmaEquipped()
    local equipped = false
    pcall(function()
        local item = getPlasmaItem()
        local counter = item and item:GetAttribute("InventoryItemLocalEquipped")
        equipped = type(counter) == "number" and counter % 2 == 1
    end)
    return equipped
end

local function findInstantPlasmaEntries(raw)
    local entries = {}
    for _, e in ipairs(raw) do
        local value = tonumber(tostring(e.value))
        local addr = tonumber(e.addr)
        if value and addr then
            entries[#entries + 1] = { key = tostring(e.key), value = value, addr = addr }
        end
    end
    for _, anchor in ipairs(entries) do
        if anchor.key == "MagSize" and anchor.value == 20 then
            local hasRange = false
            for _, e in ipairs(entries) do
                if e.key == "Range" and e.value == 200 and math.abs(e.addr - anchor.addr) <= INSTANT_PLASMA_WINDOW then
                    hasRange = true
                    break
                end
            end
            if hasRange then
                local picked = {}
                for key in pairs(INSTANT_PLASMA_TARGETS) do
                    local best, bestDist
                    for _, e in ipairs(entries) do
                        if e.key == key then
                            local dist = math.abs(e.addr - anchor.addr)
                            if dist <= INSTANT_PLASMA_WINDOW and (not bestDist or dist < bestDist) then
                                best, bestDist = e, dist
                            end
                        end
                    end
                    if best then
                        local ok, read = pcall(function() return memory_read("double", best.addr) end)
                        if ok and type(read) == "number" and math.abs(read - best.value) < 0.0001 then
                            picked[#picked + 1] = best
                        end
                    end
                end
                if #picked > 0 then return picked end
            end
        end
    end
    return nil
end

local function writePlasmaTargets(targets)
    for _, e in ipairs(targets) do
        local ok, cur = pcall(memory_read, "double", e.addr)
        if not ok or type(cur) ~= "number" then return false end
        local target = INSTANT_PLASMA_TARGETS[e.key]
        if math.abs(cur - e.value) > 0.0001 and math.abs(cur - target) > 0.0001 then
            return false
        end
    end
    for _, e in ipairs(targets) do
        pcall(function() memory_write("double", e.addr, INSTANT_PLASMA_TARGETS[e.key]) end)
    end
    return true
end

local function scanInstantPlasma()
    for _ = 1, INSTANT_PLASMA_SCAN_TRIES do
        local picked = findInstantPlasmaEntries(lockedGetgc(INSTANT_PLASMA_SCAN_KEYS))
        if picked then return picked end
        task.wait(1)
    end
    return nil
end

local function solveFlow(grid, requireFull, pause)
    local H, W = #grid, #grid[1]
    local N = H * W
    local cell, ends, colors = {}, {}, {}
    for r = 1, H do
        for c = 1, W do
            local v = grid[r][c]
            local i = (r - 1) * W + c
            cell[i] = v
            if v >= 0 then
                if not ends[v] then ends[v] = {} colors[#colors + 1] = v end
                ends[v][#ends[v] + 1] = i
            end
        end
    end
    table.sort(colors)
    for _, col in ipairs(colors) do
        if #ends[col] ~= 2 then return nil end
    end
    local nb = {}
    for i = 1, N do
        local r, c = math.floor((i - 1) / W) + 1, (i - 1) % W + 1
        local t = {}
        if r > 1 then t[#t + 1] = i - W end
        if r < H then t[#t + 1] = i + W end
        if c > 1 then t[#t + 1] = i - 1 end
        if c < W then t[#t + 1] = i + 1 end
        nb[i] = t
    end
    local head, goal, done = {}, {}, {}
    local isHead, isGoal = {}, {}
    for _, col in ipairs(colors) do
        head[col], goal[col] = ends[col][1], ends[col][2]
        done[col] = false
    end
    local remaining = #colors
    local steps, budget = 0, 2000000
    local mark, stamp = {}, 0

    local function rebuildTips()
        for k in pairs(isHead) do isHead[k] = nil end
        for k in pairs(isGoal) do isGoal[k] = nil end
        for _, col in ipairs(colors) do
            if not done[col] then
                isHead[head[col]] = col
                isGoal[goal[col]] = col
            end
        end
    end

    local function reachable(col)
        stamp = stamp + 1
        local s, e = head[col], goal[col]
        local q, qh = { s }, 1
        mark[s] = stamp
        while q[qh] do
            local cur = q[qh]
            qh = qh + 1
            local t = nb[cur]
            for k = 1, #t do
                local n = t[k]
                if n == e then return true end
                if mark[n] ~= stamp and cell[n] == -1 then
                    mark[n] = stamp
                    q[#q + 1] = n
                end
            end
        end
        return false
    end

    local function deadEnds()
        for i = 1, N do
            if cell[i] == -1 then
                local free = 0
                local t = nb[i]
                for k = 1, #t do
                    local n = t[k]
                    if cell[n] == -1 or isHead[n] or isGoal[n] then free = free + 1 end
                end
                if free < 2 then return true end
            end
        end
        return false
    end

    local function strandedRegion()
        stamp = stamp + 1
        local regionStamp = stamp
        for i = 1, N do
            if cell[i] == -1 and mark[i] ~= regionStamp then
                local q, qh = { i }, 1
                mark[i] = regionStamp
                local heads, goals = {}, {}
                while q[qh] do
                    local cur = q[qh]
                    qh = qh + 1
                    local t = nb[cur]
                    for k = 1, #t do
                        local n = t[k]
                        if cell[n] == -1 then
                            if mark[n] ~= regionStamp then
                                mark[n] = regionStamp
                                q[#q + 1] = n
                            end
                        else
                            local h, g = isHead[n], isGoal[n]
                            if h then heads[h] = true end
                            if g then goals[g] = true end
                        end
                    end
                end
                local ok = false
                for col in pairs(heads) do
                    if goals[col] then ok = true break end
                end
                if not ok then return true end
            end
        end
        return false
    end

    local function valid()
        rebuildTips()
        for _, col in ipairs(colors) do
            if not done[col] and not reachable(col) then return false end
        end
        if requireFull then
            if deadEnds() then return false end
            if strandedRegion() then return false end
        end
        return true
    end

    local function freeCount(i)
        local f = 0
        local t = nb[i]
        for k = 1, #t do
            if cell[t[k]] == -1 then f = f + 1 end
        end
        return f
    end

    local function movesFrom(col, tip, target)
        local list, score = {}, {}
        local t = nb[tip]
        for k = 1, #t do
            local n = t[k]
            if n == target then
                table.insert(list, 1, n)
                score[n] = -1
            elseif cell[n] == -1 then
                list[#list + 1] = n
                score[n] = freeCount(n)
            end
        end
        table.sort(list, function(a, b) return score[a] < score[b] end)
        return list
    end

    local function movesOf(col)
        local a = movesFrom(col, head[col], goal[col])
        if #a <= 1 then return a, false end
        local b = movesFrom(col, goal[col], head[col])
        if #b < #a then return b, true end
        return a, false
    end

    local function full()
        for i = 1, N do
            if cell[i] == -1 then return false end
        end
        return true
    end

    local search
    search = function()
        steps = steps + 1
        if steps > budget then return false end
        if pause and steps % 2000 == 0 then pause() end
        if remaining == 0 then return (not requireFull) or full() end
        local best, bestMoves, bestSwap
        for _, col in ipairs(colors) do
            if not done[col] then
                local moves, swap = movesOf(col)
                if #moves == 0 then return false end
                if not best or #moves < #bestMoves then
                    best, bestMoves, bestSwap = col, moves, swap
                    if #moves == 1 then break end
                end
            end
        end
        local col = best
        if bestSwap then head[col], goal[col] = goal[col], head[col] end
        local prev = head[col]
        for _, n in ipairs(bestMoves) do
            if n == goal[col] then
                done[col] = true
                remaining = remaining - 1
                if valid() and search() then return true end
                done[col] = false
                remaining = remaining + 1
            else
                cell[n] = col
                head[col] = n
                if valid() and search() then return true end
                cell[n] = -1
                head[col] = prev
            end
        end
        if bestSwap then head[col], goal[col] = goal[col], head[col] end
        return false
    end

    if not valid() or not search() then return nil, steps end
    local work, pairsOut = {}, {}
    for r = 1, H do
        work[r] = {}
        for c = 1, W do work[r][c] = cell[(r - 1) * W + c] end
    end
    for _, col in ipairs(colors) do
        local a, b = ends[col][1], ends[col][2]
        pairsOut[col] = { { math.floor((a - 1) / W) + 1, (a - 1) % W + 1 }, { math.floor((b - 1) / W) + 1, (b - 1) % W + 1 } }
    end
    return work, pairsOut, colors, steps
end

local function traceFlowPath(solved, s, e)
    local H, W = #solved, #solved[1]
    local col = solved[s[1]][s[2]]
    local DR, DC = { -1, 1, 0, 0 }, { 0, 0, -1, 1 }
    local path, seen, total = {}, {}, 0
    for r = 1, H do
        for c = 1, W do
            if solved[r][c] == col then total = total + 1 end
        end
    end
    local function dfs(r, c)
        path[#path + 1] = { r, c }
        seen[r * 100 + c] = true
        if r == e[1] and c == e[2] then
            if #path == total then return true end
            path[#path] = nil
            seen[r * 100 + c] = nil
            return false
        end
        for d = 1, 4 do
            local nr, nc = r + DR[d], c + DC[d]
            if nr >= 1 and nr <= H and nc >= 1 and nc <= W and not seen[nr * 100 + nc] and solved[nr][nc] == col then
                if dfs(nr, nc) then return true end
            end
        end
        path[#path] = nil
        seen[r * 100 + c] = nil
        return false
    end
    if not dfs(s[1], s[2]) then
        path, seen, total = {}, {}, 0
        local function any(r, c)
            path[#path + 1] = { r, c }
            seen[r * 100 + c] = true
            if r == e[1] and c == e[2] then return true end
            for d = 1, 4 do
                local nr, nc = r + DR[d], c + DC[d]
                if nr >= 1 and nr <= H and nc >= 1 and nc <= W and not seen[nr * 100 + nc] and solved[nr][nc] == col then
                    if any(nr, nc) then return true end
                end
            end
            path[#path] = nil
            return false
        end
        any(s[1], s[2])
    end
    return path
end

local function readFlowPuzzle()
    local gui = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("FlowGui")
    local inner = gui and gui:FindFirstChild("Board") and gui.Board:FindFirstChild("Inner")
    if not inner then return nil end
    local labels, W, H = {}, 0, 0
    for _, label in ipairs(inner:GetChildren()) do
        local x, y = string.match(label.Name, "^(%d+)%.(%d+)$")
        x, y = tonumber(x), tonumber(y)
        if x and y then
            labels[y * 100 + x] = label
            if x > W then W = x end
            if y > H then H = y end
        end
    end
    if W == 0 or not labels[101] then return nil end
    local grid, counts = {}, {}
    for r = 1, H do
        grid[r] = {}
        for c = 1, W do
            local l = labels[r * 100 + c]
            local v = (l and tonumber(l.Text)) or -1
            grid[r][c] = v
            if v >= 0 then counts[v] = (counts[v] or 0) + 1 end
        end
    end
    local id = tostring(labels[101].Address) .. ":" .. W .. "x" .. H
    local clean = PERF.flowClean
    local dirty = false
    if clean and clean.id == id then
        for r = 1, H do
            for c = 1, W do
                if grid[r][c] ~= clean.grid[r][c] then dirty = true end
            end
        end
        grid = clean.grid
    else
        for _, n in pairs(counts) do
            if n ~= 2 then return nil, "dirty" end
        end
        local key = {}
        for r = 1, H do key[r] = table.concat(grid[r], ",") end
        PERF.flowClean = { id = id, grid = grid, key = table.concat(key, ";") }
        clean = PERF.flowClean
    end
    local p11 = labels[101].AbsolutePosition
    local pitchX = W > 1 and (labels[100 + W].AbsolutePosition.X - p11.X) / (W - 1) or 0
    local pitchY = H > 1 and (labels[H * 100 + 1].AbsolutePosition.Y - p11.Y) / (H - 1) or 0
    local scale = FLOW_SCALE
    local okV, vpX = pcall(function() return workspace.CurrentCamera.ViewportSize.X end)
    local boardX = (p11.X + labels[100 + W].AbsolutePosition.X) / 2 + pitchX * 0.25
    if okV and type(vpX) == "number" and boardX > 0 then
        local s = (vpX / 2) / boardX
        if s > 0.5 and s < 4 then scale = s end
    end
    local function center(r, c)
        local p = labels[r * 100 + c].AbsolutePosition
        return (p.X + pitchX * 0.25) * scale, (p.Y + pitchY * 0.25) * scale
    end
    return { labels = labels, grid = grid, W = W, H = H, center = center, key = clean.key, dirty = dirty }
end

local function isFlowOpen()
    local gui = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("FlowGui")
    local board = gui and gui:FindFirstChild("Board")
    local inner = board and board:FindFirstChild("Inner")
    return inner ~= nil and inner:FindFirstChild("1.1") ~= nil
end

local function solveFlowPuzzle(puzzle)
    local cached = PERF.flowSolved
    if cached and cached.key == puzzle.key then return cached.solved, cached.ends, cached.colors end
    while PERF.flowBusy do task.wait(0.05) end
    cached = PERF.flowSolved
    if cached and cached.key == puzzle.key then return cached.solved, cached.ends, cached.colors end
    PERF.flowBusy = true
    local pause = function() task.wait() end
    local ok, solved, ends, colors = pcall(solveFlow, puzzle.grid, true, pause)
    if not (ok and solved) then ok, solved, ends, colors = pcall(solveFlow, puzzle.grid, false, pause) end
    PERF.flowBusy = false
    if not ok then solved, ends, colors = nil, nil, nil end
    PERF.flowSolved = { key = puzzle.key, solved = solved, ends = ends, colors = colors }
    return solved, ends, colors
end

local function readFlowColor(label)
    local ok, color = pcall(function()
        local c = label.BackgroundColor3
        local r, g, b = c.R, c.G, c.B
        if type(r) ~= "number" or (r + g + b) <= 0 then return nil end
        if r > 1 or g > 1 or b > 1 then return Color3.fromRGB(r, g, b) end
        return Color3.new(r, g, b)
    end)
    if ok then return color end
    return nil
end

local function autoSolveFlow()
    local title = "[JB Hub] Auto-Solve Puzzle"
    local puzzle, why = readFlowPuzzle()
    if not puzzle then
        notify(why == "dirty" and "Press Reset on the puzzle first" or "Open the puzzle first", title, 3)
        return
    end
    notify("Starting in " .. FLOW_START_DELAY .. "s...", title, FLOW_START_DELAY)
    local solved, ends, colors = solveFlowPuzzle(puzzle)
    task.wait(FLOW_START_DELAY)
    puzzle = readFlowPuzzle()
    if not puzzle then
        notify("Open the puzzle first", title, 3)
        return
    end
    if not solved then
        notify("No solution found", title, 3)
        return
    end
    local function cell(r, c)
        local x, y = puzzle.center(r, c)
        return math.floor(x + 0.5), math.floor(y + 0.5)
    end
    local curX, curY = cell(1, 1)
    mousemoveabs(curX, curY)
    task.wait(FLOW_SETTLE_WAIT)
    local function glideTo(x, y, slow)
        local sx, sy = curX, curY
        for i = 1, FLOW_STEP_COUNT do
            local t = i / FLOW_STEP_COUNT
            mousemoveabs(math.floor(sx + (x - sx) * t + 0.5), math.floor(sy + (y - sy) * t + 0.5))
            task.wait(FLOW_STEP_WAIT * slow)
        end
        curX, curY = x, y
    end
    local function settle(slow)
        task.wait(FLOW_SETTLE_WAIT * slow)
        mousemoverel(1, 0)
        task.wait(FLOW_STEP_WAIT * 2)
        mousemoverel(-1, 0)
        task.wait(FLOW_SETTLE_WAIT * slow)
    end
    local function textOf(r, c)
        local ok, v = pcall(function() return tonumber(puzzle.labels[r * 100 + c].Text) end)
        return ok and v or nil
    end
    local function drawn(col, path)
        local s = path[1]
        if textOf(s[1], s[2]) ~= col then return true end
        for i = 2, #path - 1 do
            if textOf(path[i][1], path[i][2]) ~= col then return false end
        end
        return true
    end
    local function draw(path, slow)
        local x, y = cell(path[1][1], path[1][2])
        glideTo(x, y, slow)
        settle(slow)
        mouse1press()
        task.wait(FLOW_PRESS_WAIT * slow)
        for i = 2, #path do
            x, y = cell(path[i][1], path[i][2])
            glideTo(x, y, slow)
            task.wait(FLOW_CELL_WAIT * slow)
        end
        settle(slow)
        mouse1release()
        task.wait(FLOW_RELEASE_WAIT * slow)
    end
    if puzzle.dirty then
        for _, col in ipairs(colors) do
            local s = ends[col][1]
            local x, y = cell(s[1], s[2])
            glideTo(x, y, 1)
            settle(1)
            mouse1press()
            task.wait(FLOW_PRESS_WAIT)
            mouse1release()
            task.wait(FLOW_RELEASE_WAIT)
        end
    end
    local failed, adjacent = 0, {}
    for _, col in ipairs(colors) do
        if not isFlowOpen() then break end
        local path = traceFlowPath(solved, ends[col][1], ends[col][2])
        if #path <= 2 then
            adjacent[#adjacent + 1] = path
        else
            draw(path, 1)
            if not drawn(col, path) then
                draw(path, 2.5)
                if not drawn(col, path) then failed = failed + 1 end
            end
        end
    end
    if #adjacent > 0 then
        local t1 = tick()
        while isFlowOpen() and tick() - t1 < 0.6 do task.wait(0.1) end
        for _, path in ipairs(adjacent) do
            if not isFlowOpen() then break end
            draw(path, 1)
        end
    end
    local t0 = tick()
    while tick() - t0 < FLOW_SOLVED_TIMEOUT do
        if not isFlowOpen() then
            notify("Puzzle solved!", title, 3)
            return
        end
        task.wait(0.1)
    end
    notify(failed > 0 and (failed .. " path(s) could not be drawn, press the key again") or "Paths drawn but puzzle still open", title, 4)
end

local flowLines = {}
local function clearFlowLines()
    for _, l in ipairs(flowLines) do pcall(function() l:Remove() end) end
    flowLines = {}
end

local function showFlowPath(puzzle)
    local colorOf, nextIndex = {}, 1
    for r = 1, puzzle.H do
        for c = 1, puzzle.W do
            local v = puzzle.grid[r][c]
            if v >= 0 and not colorOf[v] then
                colorOf[v] = FLOW_BASE_COLORS[nextIndex] or readFlowColor(puzzle.labels[r * 100 + c]) or Color3.fromHSV(math.random(), 1, 1)
                nextIndex = nextIndex + 1
            end
        end
    end
    local solved, ends, colors = solveFlowPuzzle(puzzle)
    if not solved or not isFlowOpen() then return false end
    for _, col in ipairs(colors) do
        local path = traceFlowPath(solved, ends[col][1], ends[col][2])
        for i = 1, #path - 1 do
            local x1, y1 = puzzle.center(path[i][1], path[i][2])
            local x2, y2 = puzzle.center(path[i + 1][1], path[i + 1][2])
            local l = Drawing.new("Line")
            l.From = Vector2.new(x1, y1)
            l.To = Vector2.new(x2, y2)
            l.Color = colorOf[col]
            l.Thickness = FLOW_PATH_THICKNESS
            l.Transparency = 1
            l.ZIndex = 10
            l.Visible = true
            flowLines[#flowLines + 1] = l
        end
    end
    return true
end

local function getEspTextSize(dist, scale)
    local t = math.clamp((dist - ESP_TEXT_NEAR) / (ESP_TEXT_FAR - ESP_TEXT_NEAR), 0, 1)
    local size = (ESP_TEXT_SIZE - (ESP_TEXT_SIZE - ESP_TEXT_MIN) * t) * scale
    return math.max(ESP_TEXT_MIN, math.floor(size + 0.5))
end

local function newEspDrawing(info)
    local box = Drawing.new("Square")
    box.Filled = false
    box.Color = info.color
    box.Visible = false
    pcall(function() box.Thickness = 1.5 end)
    local label = Drawing.new("Text")
    label.Color = info.color
    label.Visible = false
    pcall(function() label.Center = true end)
    pcall(function() label.Outline = true end)
    pcall(function() label.Font = Drawing.Fonts.Fortnite or Drawing.Fonts.System end)
    return { box = box, label = label, color = nil, shown = false }
end

local function newBountyDrawing(color)
    local function text()
        local t = Drawing.new("Text")
        t.Color = color
        t.Visible = false
        pcall(function() t.Center = true end)
        pcall(function() t.Outline = true end)
        pcall(function() t.OutlineColor = ESP_TARGETS.Bounty.gameOutline end)
        pcall(function() t.Font = Drawing.Fonts.Fortnite or Drawing.Fonts.System end)
        return t
    end
    return { label = text(), foot = text(), color = color, shown = false }
end

local function removeEspDrawing(d)
    if d.box then pcall(function() d.box:Remove() end) end
    if d.label then pcall(function() d.label:Remove() end) end
    if d.foot then pcall(function() d.foot:Remove() end) end
end

local function setEspVisible(d, show)
    if d.shown == show then return end
    d.shown = show
    if d.box then pcall(function() d.box.Visible = show end) end
    if d.label then pcall(function() d.label.Visible = show end) end
    if d.foot then pcall(function() d.foot.Visible = show end) end
end

PERF.PART_COLOR = 0x11C -- update

local function readEspColor(part)
    local base = tonumber(part.Address)
    if base and base > 4096 then
        local okR, r = pcall(memory_read, "byte", base + PERF.PART_COLOR)
        local okG, g = pcall(memory_read, "byte", base + PERF.PART_COLOR + 1)
        local okB, b = pcall(memory_read, "byte", base + PERF.PART_COLOR + 2)
        if okR and okG and okB and type(r) == "number" and type(g) == "number" and type(b) == "number" and (r + g + b) > 0 then
            return Color3.fromRGB(r, g, b)
        end
    end
    local ok, color = pcall(function()
        local c = part.Color
        local r, g, b = c.R, c.G, c.B
        if type(r) ~= "number" or (r + g + b) <= 0 then return nil end
        if r > 1 or g > 1 or b > 1 then return Color3.fromRGB(r, g, b) end
        return Color3.new(r, g, b)
    end)
    if ok then return color end
    return nil
end

function PERF.espRel(t)
    local ok0, p0 = pcall(function() return t.part.Position end)
    if not ok0 or not p0 then return false end
    local x0, y0, z0, x1, y1, z1 = math.huge, math.huge, math.huge, -math.huge, -math.huge, -math.huge
    for _, bp in ipairs(t.boxParts) do
        local ok, p = pcall(function() return bp.part.Position end)
        if ok and p then
            local h = bp.half
            if p.X - h.X < x0 then x0 = p.X - h.X end
            if p.Y - h.Y < y0 then y0 = p.Y - h.Y end
            if p.Z - h.Z < z0 then z0 = p.Z - h.Z end
            if p.X + h.X > x1 then x1 = p.X + h.X end
            if p.Y + h.Y > y1 then y1 = p.Y + h.Y end
            if p.Z + h.Z > z1 then z1 = p.Z + h.Z end
        end
    end
    if x0 == math.huge then return false end
    t.lo = Vector3.new(x0 - p0.X, y0 - p0.Y, z0 - p0.Z)
    t.hi = Vector3.new(x1 - p0.X, y1 - p0.Y, z1 - p0.Z)
    return true
end

local function readEspTarget(child, container, name)
    name = name or child.Name
    local info = ESP_TARGETS[name]
    if not info or info.container ~= container then return nil end
    if name == "Drop" and child:GetAttribute("BriefcaseCollected") == true then return nil end
    local part
    for _, partName in ipairs(info.parts) do
        part = child:FindFirstChild(partName)
        if part then break end
    end
    if not part then return nil end
    local color = info.color
    if info.colorFrom then
        local colorSrc = child:FindFirstChild(info.colorFrom)
        color = (colorSrc and readEspColor(colorSrc)) or info.color
    end
    local amount = nil
    if info.amountFrom then
        local value = child:FindFirstChild(info.amountFrom)
        pcall(function() amount = value and value.Value end)
    end
    local boxParts = {}
    local function addPart(d)
        if #boxParts >= PERF.ESP_MAX_PARTS then return end
        local okC, cls = pcall(function() return d.ClassName end)
        if not okC or not PERF.ESP_PART_CLASS[cls] then return end
        local okN, n = pcall(function() return d.Name end)
        if okN and PERF.ESP_SKIP_PARTS[n] then return end
        local okS, s = pcall(function() return d.Size end)
        if okS and s and s.X <= PERF.ESP_MAX_PART_SIZE and s.Y <= PERF.ESP_MAX_PART_SIZE and s.Z <= PERF.ESP_MAX_PART_SIZE then
            boxParts[#boxParts + 1] = { part = d, half = Vector3.new(s.X / 2, s.Y / 2, s.Z / 2) }
        end
    end
    if info.box then
        for _, n in ipairs(info.box) do addPart(child:FindFirstChild(n)) end
    else
        addPart(child)
    end
    local okK, kids = false, nil
    if not info.box then okK, kids = pcall(function() return child:GetChildren() end) end
    if okK then
        for _, c in ipairs(kids) do
            local okC, cls = pcall(function() return c.ClassName end)
            if okC and cls == "Model" then
                local okM, sub = pcall(function() return c:GetChildren() end)
                if okM then
                    for _, cc in ipairs(sub) do addPart(cc) end
                end
            else
                addPart(c)
            end
        end
    end
    if #boxParts == 0 then
        local s = part.Size
        boxParts[1] = { part = part, half = Vector3.new(s.X / 2, s.Y / 2, s.Z / 2) }
    end
    local t = {
        id = part.Address,
        part = part,
        model = child,
        boxParts = boxParts,
        name = name,
        info = info,
        color = color,
        title = amount and (info.label .. " $" .. tostring(amount)) or info.label,
        checkAt = 0,
        relAt = 0,
        gone = false,
    }
    PERF.espRel(t)
    return t
end

local function readEspCFrame(part)
    return part.CFrame
end

function PERF.toColor(a, g, b)
    if typeof(a) == "Color3" then return a end
    local r
    if type(a) == "table" then
        r, g, b = a.R or a.r or a[1], a.G or a.g or a[2], a.B or a.b or a[3]
    else
        r = a
    end
    r, g, b = tonumber(r), tonumber(g), tonumber(b)
    if not (r and g and b) then return nil end
    if r > 1 or g > 1 or b > 1 then return Color3.fromRGB(r, g, b) end
    return Color3.new(r, g, b)
end

local function getBountyColor(amount)
    local mode = tonumber(UI.GetValue(uid("bountyColorMode"))) or 0
    if mode == 1 then
        local ok, c = pcall(function() return PERF.toColor(UI.GetValue(uid("bountyColor"))) end)
        return (ok and c) or PERF.bountyColor
    end
    return ESP_TARGETS.Bounty.gameColor
end

function PERF.readBountyRaw()
    local data = game:GetService("ReplicatedStorage"):FindFirstChild("BountyData")
    if not data then return nil end
    local base = tonumber(data.Address)
    if not base then return nil end
    PERF.bountyOff = PERF.bountyOff or 0xA8 -- update
    local function rd(a)
        local ok, x = pcall(memory_read, "uintptr_t", a)
        return ok and x or nil
    end
    local function str(a)
        local size, cap = rd(a + 16), rd(a + 24)
        if not size or not cap or size < 2 or size > 200000 or cap < size then return nil end
        local p = cap > 15 and rd(a) or a
        if not p or p < 4096 then return nil end
        local okF, first = pcall(memory_read, "byte", p)
        if not okF or first ~= 91 then return nil end
        local parts = {}
        for i = 0, size - 1, 4 do
            local okI, w = pcall(memory_read, "int", p + i)
            if not okI or type(w) ~= "number" then return nil end
            if w < 0 then w = w + 4294967296 end
            for b = 0, 3 do
                if i + b < size then parts[#parts + 1] = string.char(math.floor(w / 256 ^ b) % 256) end
            end
        end
        return table.concat(parts)
    end
    if PERF.bountyOff then
        local s = str(base + PERF.bountyOff)
        if s then return s end
    end
    for off = 0x40, 0x300, 8 do
        local s = str(base + off)
        if s then
            PERF.bountyOff = off
            return s
        end
    end
    local okV, v = pcall(function() return data.Value end)
    if okV and type(v) == "string" and #v < 255 and v:sub(1, 1) == "[" and v:sub(-1) == "]" then return v end
    return nil
end

local function readBountyTargets(list)
    local raw = PERF.readBountyRaw()
    if not raw then return end
    local entries = game:GetService("HttpService"):JSONDecode(raw)
    if type(entries) ~= "table" then return end
    local players = game:GetService("Players")
    local lp = players.LocalPlayer
    local info = ESP_TARGETS.Bounty
    local minBounty = tonumber(UI.GetValue(uid("bountyMin"))) or 0
    for _, e in ipairs(entries) do
        local amount = type(e) == "table" and tonumber(e.Bounty)
        local name = type(e) == "table" and e.Name
        if amount and amount > 0 and amount >= minBounty and name then
            pcall(function()
                local p = players:FindFirstChild(name)
                if not p or p == lp then return end
                local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                local digits = tostring(math.floor(amount))
                local money = (digits:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
                list[#list + 1] = {
                    kind = "bounty",
                    id = hrp.Address,
                    part = hrp,
                    name = "Bounty",
                    info = info,
                    color = getBountyColor(amount),
                    title = "$" .. money,
                    checkAt = 0,
                    gone = false,
                }
            end)
        end
    end
	return true
end

local function drawBountyTarget(t, d, rootPos, scale, now)
    if now >= t.checkAt then
        t.checkAt = now + PERF.ESP_PARENT_CHECK
        if t.part.Parent == nil then t.gone = true end
    end
    if t.gone then return false end
    local wpos = t.part.Position
    local head, headOn = WorldToScreen(wpos + t.info.up)
    local feet, feetOn = WorldToScreen(wpos + t.info.down)
    if not headOn and not feetOn then return false end
    local dist = rootPos and math.floor((rootPos - wpos).Magnitude) or 0
    local textSize = math.min(getEspTextSize(dist, scale), t.info.textMax or 99)
    if d.color ~= t.color then
        pcall(function() d.label.Color = t.color end)
        pcall(function() d.foot.Color = t.color end)
        d.color = t.color
    end
    if d.textSize ~= textSize then
        pcall(function() d.label.Size = textSize end)
        pcall(function() d.foot.Size = textSize end)
        d.textSize = textSize
    end
    if d.title ~= t.title then
        d.label.Text = t.title
        d.title = t.title
    end
    if d.dist ~= dist then
        d.foot.Text = "[" .. dist .. "]"
        d.dist = dist
    end
    local hx, hy = math.floor(head.X + 0.5), math.floor(head.Y + 0.5) - textSize - 2
    if d.hx ~= hx or d.hy ~= hy then
        d.label.Position = Vector2.new(hx, hy)
        d.hx, d.hy = hx, hy
    end
    local fx, fy = math.floor(feet.X + 0.5), math.floor(feet.Y + 0.5) + 2
    if d.fx ~= fx or d.fy ~= fy then
        d.foot.Position = Vector2.new(fx, fy)
        d.fx, d.fy = fx, fy
    end
    return true
end

local function getEspBounds(t)
    local lo, hi = t.lo, t.hi
    if not lo then return nil end
    local p = t.part.Position
    local ax, ay, az = p.X + lo.X, p.Y + lo.Y, p.Z + lo.Z
    local bx, by, bz = p.X + hi.X, p.Y + hi.Y, p.Z + hi.Z
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    local anyOn = false
    for i = 0, 7 do
        local sp, on = WorldToScreen(Vector3.new(i % 2 == 0 and ax or bx, i % 4 < 2 and ay or by, i < 4 and az or bz))
        if on then anyOn = true end
        if sp.X < minX then minX = sp.X end
        if sp.Y < minY then minY = sp.Y end
        if sp.X > maxX then maxX = sp.X end
        if sp.Y > maxY then maxY = sp.Y end
    end
    if not anyOn then return nil end
    return minX, minY, maxX, maxY, Vector3.new((ax + bx) / 2, (ay + by) / 2, (az + bz) / 2)
end

local function drawEspTarget(t, d, rootPos, scale, now)
    if now >= t.checkAt then
        t.checkAt = now + PERF.ESP_PARENT_CHECK
        if t.part.Parent == nil then
            t.gone = true
        elseif t.name == "Drop" and t.model:GetAttribute("BriefcaseCollected") == true then
            t.gone = true
        end
    end
    if t.gone then return false end
    if now >= t.relAt then
        t.relAt = now + 1
        PERF.espRel(t)
    end
    local okB, minX, minY, maxX, maxY, wpos = pcall(getEspBounds, t)
    if not okB or not minX then return false end
    local boxMin = t.info.boxMin or ESP_BOX_MIN
    local w = math.floor(math.max(maxX - minX + ESP_BOX_PADDING * 2, boxMin) + 0.5)
    local h = math.floor(math.max(maxY - minY + ESP_BOX_PADDING * 2, boxMin) + 0.5)
    local x = math.floor((minX + maxX) / 2 - w / 2 + 0.5)
    local y = math.floor((minY + maxY) / 2 - h / 2 + 0.5)
    local dist = rootPos and math.floor((rootPos - wpos).Magnitude) or 0
    local textSize = math.min(getEspTextSize(dist, scale), 13)
    if t.info.textMin then textSize = math.max(textSize, t.info.textMin) end
    if d.color ~= t.color then
        pcall(function() d.box.Color = t.color end)
        pcall(function() d.label.Color = t.color end)
        d.color = t.color
    end
    if d.w ~= w or d.h ~= h then
        d.box.Size = Vector2.new(w, h)
        d.w, d.h = w, h
    end
    if d.x ~= x or d.y ~= y then
        d.box.Position = Vector2.new(x, y)
        d.x, d.y = x, y
    end
    if d.textSize ~= textSize then
        pcall(function() d.label.Size = textSize end)
        d.textSize = textSize
    end
    if d.dist ~= dist or d.title ~= t.title then
        d.label.Text = string.format("%s  [%d]", t.title, dist)
        d.dist, d.title = dist, t.title
    end
    local lx, ly = math.floor(x + w / 2 + 0.5), y - textSize - 2
    if d.lx ~= lx or d.ly ~= ly then
        d.label.Position = Vector2.new(lx, ly)
        d.lx, d.ly = lx, ly
    end
    return true
end

local function vaultReadPos(part)
    local ok, pos = pcall(function() return part.Position end)
    if ok and pos and pcall(function() return pos.X + 0 end) then return pos end
    return nil
end

local function vaultReadColor(part)
    local ok, r, g, b = pcall(function()
        local c = part.Color
        return c.R, c.G, c.B
    end)
    if ok and type(r) == "number" then return r, g, b end
    return nil
end

local function vaultIsWhite(r, g, b)
    return r ~= nil and g >= 100 and b >= 100
end

local function findNearestVault()
    local char = game:GetService("Players").LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local me = hrp and vaultReadPos(hrp)
    if not me then return nil end
    local casino = PERF.ws("Casino")
    local vaults = casino and casino:FindFirstChild("HackableVaults")
    if not vaults then return nil end
    local best, bestDist = nil, math.huge
    for _, v in ipairs(vaults:GetChildren()) do
        local inner = v:FindFirstChild("InnerModel")
        local puzzle = inner and inner:FindFirstChild("Puzzle")
        local dial = puzzle and puzzle:FindFirstChild("InnerModel")
        local ptr = dial and dial:FindFirstChild("LightPtr")
        local anchor = puzzle and puzzle:FindFirstChild("Part")
        local pos = anchor and vaultReadPos(anchor)
        if ptr and pos then
            local d = (pos - me).Magnitude
            if d < bestDist then
                local light
                pcall(function() light = ptr.Value end)
                best = {
                    light = light,
                    request = puzzle:FindFirstChild("RequestHack"),
                    update = puzzle:FindFirstChild("UpdateDirection"),
                }
                bestDist = d
            end
        end
    end
    if best and bestDist <= VAULT.START_RANGE then return best end
    return nil
end

local function crackVault(target)
    local function active()
        return _G.JB_gen == myGen and UI.GetValue(uid("autoVault")) and true or false
    end
    local restarts = 0
    local whites = 0
    local wasWhite = false
    local lastPress = 0

    local function requestHack()
        restarts = restarts + 1
        pcall(function() target.request:FireServer() end)
        return tick()
    end

    notify("Starting in " .. VAULT.START_DELAY .. "s...", VAULT.TITLE, VAULT.START_DELAY)
    task.wait(VAULT.START_DELAY)
    if not active() then
        notify("Stopped", VAULT.TITLE, 3)
        return
    end
    local lastProgress = requestHack()

    while active() do
        local r, g, b = vaultReadColor(target.light)
        local white = vaultIsWhite(r, g, b)
        if white and not wasWhite and tick() - lastPress >= VAULT.PRESS_GAP then
            pcall(function() target.update:FireServer() end)
            lastPress = tick()
            lastProgress = tick()
            whites = whites + 1
            if whites >= VAULT.WHITES_NEEDED then
                notify("Vault cracked!", VAULT.TITLE, 4)
                return
            end
            notify(whites .. "/" .. VAULT.WHITES_NEEDED, VAULT.TITLE, 1)
        end
        wasWhite = white
        if tick() - lastProgress >= VAULT.RESTART_AFTER then
            if restarts >= VAULT.MAX_RESTARTS then
                notify("No white light, try another vault", VAULT.TITLE, 4)
                return
            end
            whites = 0
            lastProgress = requestHack()
        end
        task.wait(VAULT.TICK)
    end
    notify("Stopped", VAULT.TITLE, 3)
end

PERF.CFG = {
    ROOT = "JB Hub",
    DIR = "JB Hub/config",
    TITLE = "[JB Hub] Config",
    EXTRA = { "nofallMethod", "bountyColor", "bountyColorMode", "bountyMin", "hitSoundName", "hitMarkerStyle", "plasmaKillauraTarget", "skinName", "skinTarget", "skyColorPreset", "waterColor", "waterSea", "timePreset", "timeHour", "timeSpeed", "engineBoostMult", "autoTaserRange", "carFlySpeed", "npcRange", "hbX", "hbY", "hbZ", "elevFloor", "guardMode", "guardShootDist", "guardFreq", "guardProtect", "guardFollow", "guardTeam", "guardSpread", },
}

pcall(function()
    makefolder(PERF.CFG.ROOT)
    makefolder(PERF.CFG.DIR)
end)

function PERF.CFG.ids()
    local list = {}
    for _, k in ipairs(PERF.CFG.EXTRA) do list[#list + 1] = k end
    for _, slot in ipairs(COSMETICS.SLOTS) do list[#list + 1] = slot.id end
    for _, k in ipairs(ALL_IDS) do list[#list + 1] = k end
    return list
end

function PERF.CFG.clean(name)
    name = tostring(name or ""):gsub("[^%w _%-]", ""):gsub("^%s+", ""):gsub("%s+$", "")
    return name:sub(1, 32)
end

function PERF.CFG.pack(v)
    local t = type(v)
    if t == "boolean" or t == "number" or t == "string" then return v end
    if typeof(v) == "Color3" then return { c3 = { v.R, v.G, v.B } } end
    if t == "table" then
        local out = {}
        for k, x in pairs(v) do
            if type(x) ~= "number" and type(x) ~= "boolean" then return nil end
            out[k] = x
        end
        return out
    end
    return nil
end

function PERF.CFG.unpack(v)
    if type(v) == "table" and type(v.c3) == "table" then
        return Color3.new(v.c3[1] or 0, v.c3[2] or 0, v.c3[3] or 0)
    end
    return v
end

PERF.CFG.KEYS = { "resetBindKey", "puzzleSolveKey", "casinoKey", "casinoOpenKey", "autoVaultKey", "plasmaKillauraKey", "killNpcsKey", "carFlyKey", "engineBoostKey", "instantBrakeKey", "autoCuffKey", "autoTaserKey", "cosmeticsKey" }

function PERF.CFG.kb(id)
    local H = PERF.holdKb or {}
    local map = {
        resetBindKey = H.reset, puzzleSolveKey = H.puzzle, casinoKey = H.casino, casinoOpenKey = H.casinoOpen,
        autoVaultKey = H.vault, cosmeticsKey = H.cosmetics, plasmaKillauraKey = PERF.kaKeybind,
        killNpcsKey = PERF.killKeybind, autoCuffKey = PERF.cuffKeybind, autoTaserKey = PERF.taseKeybind,
        carFlyKey = VEHICLE.flyKeybind, engineBoostKey = VEHICLE.boostKeybind, instantBrakeKey = VEHICLE.brakeKeybind,
    }
    return map[id]
end

function PERF.CFG.readKey(id)
    local kb = PERF.CFG.kb(id)
    local out = {}
    if kb then
        local okK, k = pcall(function() return kb:GetKey() end)
        if okK and type(k) == "number" then out.key = k end
        local okM, m = pcall(function() return kb:GetMode() end)
        if okM and type(m) == "string" then out.mode = m end
    end
    if out.key == nil then
        local okV, v = pcall(UI.GetValue, uid(id))
        if okV and type(v) == "number" then out.key = v end
    end
    return out.key ~= nil and out or nil
end

function PERF.CFG.writeKey(id, data)
    if type(data) ~= "table" or type(data.key) ~= "number" then return end
    local kb = PERF.CFG.kb(id)
    local done = false
    if kb then
        done = pcall(function() kb:SetKey(data.key) end)
        if data.mode then pcall(function() kb:SetMode(data.mode) end) end
    end
    if not done then pcall(UI.SetValue, uid(id), data.key) end
end

function PERF.CFG.save()
    local C = PERF.CFG
    local name = C.clean(UI.GetValue(uid("cfgName")))
    if name == "" then notify("Enter a config name", C.TITLE, 3) return end
    local data = {}
    for _, k in ipairs(C.ids()) do
        local ok, v = pcall(UI.GetValue, uid(k))
        local packed = ok and C.pack(v)
        if packed ~= nil then data[k] = packed end
    end
    local keys = {}
    for _, id in ipairs(C.KEYS) do
        local d = C.readKey(id)
        if d then keys[id] = d end
    end
    data.__keys = keys
    local okE, json = pcall(function() return game:GetService("HttpService"):JSONEncode(data) end)
    local okW = okE and pcall(writefile, C.DIR .. "/" .. name .. ".json", json)
    notify(okW and ("Config saved: " .. name) or "Failed to save config", C.TITLE, 3)
end

function PERF.CFG.load()
    local C = PERF.CFG
    local name = C.clean(UI.GetValue(uid("cfgName")))
    if name == "" then notify("Enter a config name", C.TITLE, 3) return end
    local path = C.DIR .. "/" .. name .. ".json"
    if not isfile(path) then notify("Config not found: " .. name, C.TITLE, 3) return end
    local okR, raw = pcall(readfile, path)
    local okD, data = pcall(function() return game:GetService("HttpService"):JSONDecode(raw) end)
    if not (okR and okD and type(data) == "table") then notify("Config is corrupted", C.TITLE, 3) return end
    for _, k in ipairs(C.ids()) do
        if data[k] ~= nil then pcall(UI.SetValue, uid(k), C.unpack(data[k])) end
    end
    if type(data.__keys) == "table" then
        for id, d in pairs(data.__keys) do C.writeKey(id, d) end
    end
    notify("Config loaded: " .. name, C.TITLE, 3)
end

function PERF.CFG.reset()
    local C = PERF.CFG
    local defaults = {
        nofallMethod = 0, bountyColorMode = 0, bountyMin = 0, hitSoundName = 0, hitMarkerStyle = 0,
        plasmaKillauraTarget = 0, skinName = 0, skinTarget = 0, skyColorPreset = 0, waterColor = 0,
        waterSea = 32, timePreset = 0, timeHour = 12, timeSpeed = 1, npcRange = 150,
        hbX = 10, hbY = 8, hbZ = 10, elevFloor = 0,
        guardMode = 0, guardShootDist = 400, guardFreq = 3, guardProtect = 80, guardFollow = true, guardTeam = 0, guardSpread = true,
        engineBoostMult = VEHICLE.BOOST_DEFAULT, carFlySpeed = VEHICLE.FLY_DEFAULT_SPEED,
        autoTaserRange = PERF.TASE.RANGE,
    }
    PERF.muteNotifyUntil = tick() + 3
    for _, k in ipairs(ALL_IDS) do pcall(UI.SetValue, uid(k), false) end
    for _, slot in ipairs(COSMETICS.SLOTS) do pcall(UI.SetValue, uid(slot.id), 0) end
    for k, v in pairs(defaults) do pcall(UI.SetValue, uid(k), v) end
    PERF.rawNotify("All settings reset to defaults", C.TITLE, 3)
end

PERF.ONLINE = {
    URL = "https://jb-hub-online.uhq7k.workers.dev",
    INTERVAL = 300,
    count = nil,
}

function PERF.ONLINE.leave()
    local O = PERF.ONLINE
    if not O.sid or O.left then return end
    O.left = true
    pcall(function() game:HttpGet(O.URL .. "/leave?id=" .. O.sid) end)
end

function PERF.ONLINE.text()
    local O = PERF.ONLINE
    if O.count then return O.count .. (O.count == 1 and " user online" or " users online") end
    return "Connecting..."
end

PERF.ROLES = {
    TITLE = "[JB Hub] Roles",
    INTERVAL = 5,
    DEFAULT = "JB Hub",
    COLOR = Color3.fromRGB(125, 150, 255),
    COLORS = { Owner = Color3.fromRGB(255, 200, 60), Tester = Color3.fromRGB(90, 220, 140) },
    SIZE_NEAR = 15,
    SIZE_FAR = 9,
    NEAR = 30,
    FAR = 500,
    OFFSET = Vector3.new(0, -3, 0),
    PADDING = 4,
    state = "off",
    status = "Status: Off",
    users = {},
    tags = {},
    labels = {},
    sizes = {},
}

function PERF.ROLES.query()
    if PERF.ROLES.state == "off" then return "" end
    local lp = game:GetService("Players").LocalPlayer
    return "&job=" .. tostring(game.JobId) .. "&uid=" .. tostring(lp.UserId)
end

function PERF.ROLES.ping()
    local R, O = PERF.ROLES, PERF.ONLINE
    if not O.sid then return false end
    local ok, body = pcall(function() return game:HttpGet(O.URL .. "/ping?id=" .. O.sid .. R.query()) end)
    local okD, data = pcall(function() return game:GetService("HttpService"):JSONDecode(body) end)
    if not (ok and okD and type(data) == "table" and type(data.users) == "table") then return false end
    if tonumber(data.online) then O.count = tonumber(data.online) end
    local fresh = {}
    for _, user in ipairs(data.users) do
        local id = tonumber(user)
        if id then fresh[id] = R.DEFAULT end
    end
    if type(data.roles) == "table" then
        for user, role in pairs(data.roles) do
            local id = tonumber(user)
            if id and fresh[id] then fresh[id] = tostring(role) end
        end
    end
    if not fresh[game:GetService("Players").LocalPlayer.UserId] then return false end
    R.users = fresh
    return true
end

function PERF.ROLES.release()
    local R, O = PERF.ROLES, PERF.ONLINE
    R.state = "off"
    R.users = {}
    if O.sid then pcall(function() game:HttpGet(O.URL .. "/ping?id=" .. O.sid) end) end
end

function PERF.ROLES.removeTag(userId)
    local R = PERF.ROLES
    local tag = R.tags[userId]
    if tag then pcall(function() tag:Remove() end) end
    R.tags[userId], R.labels[userId], R.sizes[userId] = nil, nil, nil
end

function PERF.ROLES.clear()
    for userId in pairs(PERF.ROLES.tags) do PERF.ROLES.removeTag(userId) end
end

function PERF.ROLES.tag(userId, label, size)
    local R = PERF.ROLES
    local tag = R.tags[userId]
    if not tag then
        tag = Drawing.new("Text")
        tag.Center = true
        tag.Outline = true
        tag.Visible = false
        pcall(function() tag.Font = Drawing.Fonts.SystemBold or Drawing.Fonts.System end)
        R.tags[userId] = tag
    end
    if R.labels[userId] ~= label then
        tag.Text = "[" .. label .. "]"
        tag.Color = R.COLORS[label] or R.COLOR
        R.labels[userId] = label
    end
    if R.sizes[userId] ~= size then
        pcall(function() tag.FontSize = size end)
        pcall(function() tag.Size = size end)
        R.sizes[userId] = size
    end
    return tag
end

task.spawn(function()
    local R = PERF.ROLES
    local last = 0
    local function connectedText()
        return "Status: Connected as " .. tostring(R.users[game:GetService("Players").LocalPlayer.UserId])
    end
    while _G.JB_gen == myGen do
        PERF.run("rolesNet", function()
            local wanted = UI.GetValue(uid("hubRoles")) and true or false
            if R.state == "off" and wanted then
                R.state = "connecting"
                R.status = "Status: Connecting..."
                pcall(UI.SetValue, uid("hubRoles"), false)
                if R.ping() then
                    R.state = "on"
                    last = tick()
                    R.status = connectedText()
                    pcall(UI.SetValue, uid("hubRoles"), true)
                    notify("Connected to JB Hub server", R.TITLE, 3)
                else
                    R.state = "off"
                    R.status = "Status: Connection failed"
                    notify("Could not reach JB Hub server", R.TITLE, 4)
                end
            elseif R.state == "on" and not wanted then
                R.release()
                R.status = "Status: Off"
            elseif R.state == "on" and tick() - last >= R.INTERVAL then
                R.status = R.ping() and connectedText() or "Status: Reconnecting..."
                last = tick()
            end
        end)
        task.wait(0.2)
    end
end)

task.spawn(function()
    local R = PERF.ROLES
    local Players = game:GetService("Players")
    local tracked, lastScan = {}, 0
    while _G.JB_gen == myGen do
        if R.state == "on" then
            PERF.run("rolesDraw", function()
                local now = tick()
                if now - lastScan >= 1 then
                    lastScan = now
                    tracked = {}
                    for _, player in ipairs(Players:GetPlayers()) do
                        local userId = player.UserId
                        if R.users[userId] then
                            local char = player.Character
                            local root = char and char:FindFirstChild("HumanoidRootPart")
                            if root then tracked[#tracked + 1] = { id = userId, root = root } end
                        end
                    end
                end
                local seen = {}
                local camera = workspace.CurrentCamera
                local camPos = camera and camera.CFrame.Position
                if camPos then
                    for _, t in ipairs(tracked) do
                        local label = R.users[t.id]
                        local okP, rootPos = pcall(function() return t.root.Position end)
                        if label and okP then
                            local worldPos = rootPos + R.OFFSET
                            local alpha = math.clamp(((worldPos - camPos).Magnitude - R.NEAR) / (R.FAR - R.NEAR), 0, 1)
                            local size = math.floor(R.SIZE_NEAR + (R.SIZE_FAR - R.SIZE_NEAR) * alpha + 0.5)
                            local tag = R.tag(t.id, label, size)
                            seen[t.id] = true
                            local screenPos, onScreen = WorldToScreen(worldPos)
                            if onScreen then
                                tag.Position = Vector2.new(screenPos.X, screenPos.Y + R.PADDING)
                                tag.Visible = true
                            else
                                tag.Visible = false
                            end
                        end
                    end
                end
                for userId in pairs(R.tags) do
                    if not seen[userId] then R.removeTag(userId) end
                end
            end)
            task.wait()
        else
            R.clear()
            task.wait(0.2)
        end
    end
    R.clear()
end)

task.spawn(function()
    local O = PERF.ONLINE
    local HS = game:GetService("HttpService")
    local okG, sid = pcall(function() return HS:GenerateGUID(false) end)
    O.sid = (okG and sid) or (tostring(math.random(10000000, 99999999)) .. tostring(math.random(10000000, 99999999)))
    while _G.JB_gen == myGen do
        local ok, body = pcall(function() return game:HttpGet(O.URL .. "/ping?id=" .. O.sid .. PERF.ROLES.query()) end)
        local okD, data = pcall(function() return HS:JSONDecode(body) end)
        if ok and okD and type(data) == "table" and tonumber(data.online) then
            O.count = tonumber(data.online)
            SPLASH.info.online = O.count
        end
        local t0 = tick()
        while _G.JB_gen == myGen and tick() - t0 < O.INTERVAL do task.wait(1) end
    end
    O.leave()
end)

PERF.HERE = {
    INTERVAL = 30,
    others = 0,
    seen = {},
}

task.spawn(function()
    local H, O = PERF.HERE, PERF.ONLINE
    local okJ, job = pcall(function() return tostring(game.JobId) end)
    if not okJ or #job < 8 then return end
    local t0 = tick()
    while _G.JB_gen == myGen and (not O.sid or not SPLASH.done) and tick() - t0 < 60 do task.wait(0.5) end
    local t2 = tick()
    while _G.JB_gen == myGen and tick() - t2 < 3 do task.wait(0.5) end
    if not O.sid or _G.JB_gen ~= myGen then return end
    local base = O.URL .. "/here?id=" .. O.sid .. "&job=" .. job
    print("[HereDebug] start sid=" .. O.sid:sub(1, 8) .. " job=" .. job)
    while _G.JB_gen == myGen do
        local delay = H.INTERVAL
        local ok, body = pcall(function() return game:HttpGet(base .. "&t=" .. math.floor(tick() * 1000)) end)
        local okD, data = pcall(function() return game:GetService("HttpService"):JSONDecode(body) end)
        print(string.format("[HereDebug] %.0f ok=%s okD=%s known=%d body=%s", tick(), tostring(ok), tostring(okD), H.others, tostring(body)))
        if ok and okD and type(data) == "table" then
            if data.reg == false then
                pcall(function() game:HttpGet(O.URL .. "/ping?id=" .. O.sid .. PERF.ROLES.query()) end)
                delay = 2
            else
                local n = tonumber(data.others) or 0
                local fresh = n > H.others
                if type(data.ids) == "table" then
                    for _, k in pairs(data.ids) do
                        if not H.seen[k] then
                            H.seen[k] = true
                            fresh = true
                        end
                    end
                end
                if fresh and n > 0 then notify("JB Hub user is in the server", "[JB Hub]", 5) end
                H.others = n
            end
        end
        local t1 = tick()
        while _G.JB_gen == myGen and tick() - t1 < delay do task.wait(1) end
    end
    pcall(function() game:HttpGet(base .. "&leave=1") end)
end)

PERF.ELEV = {
    FLOORS = { "Vaults", "Ground", "Security", "The Roof" },
    INDEX = { ["Vaults"] = 1, ["Ground"] = 2, ["Security"] = 3, ["The Roof"] = 4 },
    INTERVAL = 0.05,
    selected = "Vaults",
}

function PERF.ELEV.detector(index)
    local casino = workspace:FindFirstChild("Casino")
    local elevator = casino and casino:FindFirstChild("Elevator")
    if not elevator then return nil end
    local floors = elevator:FindFirstChild("Floors")
    local floor = floors and floors:FindFirstChild(tostring(index))
    local button = floor and floor:FindFirstChild("Call")
    if not button then
        local car = elevator:FindFirstChild("Car")
        local inner = car and car:FindFirstChild("InnerModel")
        local calls = inner and inner:FindFirstChild("Calls")
        button = calls and calls:FindFirstChild(tostring(index))
    end
    if not button then return nil end
    if button.ClassName == "ClickDetector" then return button end
    for _, child in ipairs(button:GetDescendants()) do
        if child.ClassName == "ClickDetector" then return child end
    end
    return nil
end

function PERF.ELEV.floorIndex()
    local E = PERF.ELEV
    local value = UI.GetValue(uid("elevFloor"))
    if type(value) == "number" and E.FLOORS[math.floor(value) + 1] then
        return math.floor(value) + 1
    end
    if type(value) == "string" and E.INDEX[value] then
        return E.INDEX[value]
    end
    return E.INDEX[E.selected] or 1
end

function PERF.ELEV.call()
    local E = PERF.ELEV
    local index = E.floorIndex()
    local detector = E.detector(index)
    local now = tick()
    if not detector then
        if now - (E.warnAt or 0) >= 10 then
            E.warnAt = now
            local loaded = workspace:FindFirstChild("Casino") ~= nil
            notify(loaded and ("Button not found for " .. tostring(E.FLOORS[index])) or "Casino not loaded, get closer", "[JB Hub] Elevator", 3)
        end
        return false
    end
    local fired = pcall(fireclickdetector, detector)
    if not fired and now - (E.warnAt or 0) >= 10 then
        E.warnAt = now
        notify("Failed to call the elevator", "[JB Hub] Elevator", 3)
    end
    return fired
end

task.spawn(function()
    while _G.JB_gen == myGen do
        if UI.GetValue(uid("elevLoop")) then
            PERF.ELEV.call()
        end
        task.wait(PERF.ELEV.INTERVAL)
    end
end)

PERF.MANSION = {
    TITLE = "[JB Hub] Teleport to Mansion",
    POINT = Vector3.new(1369.4, -216.6, -4693.8),
    REWRITE = 6,
    SUCCESS = 50,
    TIMEOUT = 20,
    busy = false,
}

PERF.MANSION = {
    TITLE = "[JB Hub] Teleport to Mansion",
    POINT = Vector3.new(1369.4, -216.6, -4693.8),
    DEST = Vector3.new(1276.8, 42.2, -4814.1),
    NEAR = 80,
    REWRITE = 6,
    SUCCESS = 50,
    TIMEOUT = 20,
    busy = false,
}

function PERF.MANSION.teleport()
    local M = PERF.MANSION
    if M.busy then return end
    local char = game:GetService("Players").LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    if not root or not hum then
        notify("Character not found", M.TITLE, 3)
        return
    end
    local startPos = root.Position
    if (startPos - M.DEST).Magnitude < M.NEAR then
        notify("Already at the Mansion", M.TITLE, 3)
        return
    end
    local okSit, sitting = pcall(function() return hum.Sit end)
    if okSit and sitting == true then
        notify("Exit your vehicle first", M.TITLE, 3)
        return
    end
    local serverObj = hum:FindFirstChild("HumanoidUnloadServerPosition")
    local function serverPos()
        local ok, value = pcall(function() return serverObj.Value end)
        if ok and typeof(value) == "Vector3" then return value end
        return nil
    end
    local serverStart = serverObj and serverPos()
    M.busy = true
    notify("Teleporting...", M.TITLE, 3)
    local started = tick()
    local writes = 0
    local success = false
    local lastPos = startPos
    while _G.JB_gen == myGen and tick() - started < M.TIMEOUT do
        local okPos, current = pcall(function() return root.Position end)
        if not okPos or typeof(current) ~= "Vector3" then break end
        lastPos = current
        local server = serverStart and serverPos()
        if server then
            if (server - serverStart).Magnitude > M.SUCCESS and (server - M.POINT).Magnitude > M.SUCCESS then
                success = true
                break
            end
        elseif (current - startPos).Magnitude > M.SUCCESS and (current - M.POINT).Magnitude > M.SUCCESS then
            success = true
            break
        end
        if (current - M.POINT).Magnitude > M.REWRITE then
            pcall(function() root.Position = M.POINT end)
            writes = writes + 1
        end
        task.wait()
    end
    M.busy = false
    if success then
        notify("Teleported to Mansion", M.TITLE, 3)
    else
        notify("Teleport failed, try again", M.TITLE, 4)
    end
end

PERF.AFK = {
    KEYS = { 0x57, 0x41, 0x53, 0x44, 0x5A, 0x51, 0x20, 0x10, 0x11 },
    SILENT_KEY = 0x7C,
    MOVE_KEYS = { { 0x57, 0x53 }, { 0x41, 0x44 } },
    MIN_DELAY = 45,
    MAX_DELAY = 90,
    lastActivity = tick(),
    nextDelay = 60,
}

function PERF.AFK.userActive()
    if not isrbxactive() then return false end
    if ismouse1pressed() or ismouse2pressed() then return true end
    for _, key in ipairs(PERF.AFK.KEYS) do
        if iskeypressed(key) then return true end
    end
    return false
end

function PERF.AFK.pulse()
    if not isrbxactive() then return false end
    local dx = math.random(0, 1) == 0 and 2 or -2
    mousemoverel(dx, 0)
    task.wait(0.05 + math.random() * 0.05)
    mousemoverel(-dx, 0)
    local pair = PERF.AFK.MOVE_KEYS[math.random(1, #PERF.AFK.MOVE_KEYS)]
    for _, vk in ipairs(pair) do
        keypress(vk)
        task.wait(0.02 + math.random() * 0.02)
        keyrelease(vk)
        task.wait(0.05)
    end
    return true
end

task.spawn(function()
    local A = PERF.AFK
    local warnedAt = 0
    while _G.JB_gen == myGen do
        task.wait(0.25)
        if UI.GetValue(uid("antiAfk")) then
            local okA, active = pcall(A.userActive)
            if okA and active then
                A.lastActivity = tick()
            elseif tick() - A.lastActivity >= A.nextDelay then
                local okP, sent = pcall(A.pulse)
                if okP and sent then
                    A.lastActivity = tick()
                    A.nextDelay = math.random(A.MIN_DELAY, A.MAX_DELAY)
                elseif tick() - warnedAt >= 300 then
                    warnedAt = tick()
                    notify("Roblox is in the background, keep it in front to stay active", "[JB Hub] Anti AFK", 5)
                end
            end
        else
            A.lastActivity = tick()
        end
    end
end)

local function buildTab()
    UI.AddTab("JB Hub", function(tab)
        local misc = tab:Section("Misc" .. string.rep(" ", math.floor(tonumber(string.sub(S, 2)) / 1000) % 40 + 1), "Left", nil, 260)
        misc:Toggle(uid("nofall"), "No Fall Damage")
        misc:Combo(uid("nofallMethod"), "Method", NFD_METHODS, 0)
		misc:Toggle(uid("nolaser"), "No Laser Damage")
		misc:Toggle(uid("noturret"), "No Turret Damage")
		misc:Toggle(uid("noForcefield"), "Disable Forcefields")
		misc:Tip("Military Base forcefield and Mansion CEO aura blast")
		misc:Toggle(uid("antiTaser"), "Anti Taser Ragdoll")     
        misc:Toggle(uid("unlockSlots"), "Unlock Weapons Slots")
        misc:Tip("Make you able to switch weapons while holding a bag and more ...")
        misc:Toggle(uid("jetpack"), "Infinity Jetpack")		
--      misc:Toggle(uid("nosit"),  "No Sit")
        misc:Toggle(uid("resetBind"), "Force Reset Bind")
        local rk = misc:Keybind(uid("resetBindKey"), PERF.RESET_KEY, "hold", function() PERF.resetRequested = true end)
        PERF.holdKb.reset = rk
        pcall(function() rk:AddToHotkey("Force Reset", uid("resetBind")) end)
        misc:Button("Force Reset", function() forceReset() end)
		
        local esp = tab:Section("ESP", "Left")
		esp:Toggle(uid("airdropEsp"), "Airdrop ESP")
        esp:Toggle(uid("keycardEsp"), "Keycard ESP")
        esp:Toggle(uid("crimekeyEsp"), "Crimekey ESP")	
        esp:Toggle(uid("cashEsp"), "Cash Dropped ESP")
        esp:Toggle(uid("bountyEsp"), "Bounty ESP")		
        esp:ColorPicker(uid("bountyColor"), 1, 0.24, 0.24, 1, function(...) PERF.bountyColor = PERF.toColor(...) or PERF.bountyColor end)
        esp:Combo(uid("bountyColorMode"), "Bounty Color", ESP_TARGETS.Bounty.modes, 0)
        esp:SliderInt(uid("bountyMin"), "Min Bounty", 0, 25000, 0)
		
        local casino = tab:Section("Casino##" .. S, "Left", { "Casino", "Tomb", "Power Plant" })
        if casino.page == 1 then
            casino:Toggle(uid("tombSpikes"), "No Spike Damage")
            casino:Toggle(uid("tombDarts"), "No Dart Damage")
            casino:Toggle(uid("tombBridge"), "Safe Bridge")
            casino:Toggle(uid("tombCart"), "No Cart Barrier Damage")
        elseif casino.page == 2 then
            casino:Toggle(uid("puzzleSolve"), "Auto-Solve Puzzle")
            local fk = casino:Keybind(uid("puzzleSolveKey"), FLOW_KEY, "hold", function() flowRequested = true end)
            PERF.holdKb.puzzle = fk
            pcall(function() fk:AddToHotkey("Auto-Solve Puzzle", uid("puzzleSolve")) end)
            casino:Toggle(uid("puzzlePath"), "Show Puzzle Path")
            casino:Toggle(uid("ppWire"), "No Barbed Wire Damage")
            casino:Toggle(uid("ppPistons"), "No Piston Damage")
        else
            casino:Text("Require Hybrid Mod (1, 2, 3, 4, 5, 6) !!!")
            casino:Toggle(uid("casino"), "Get Casino Code")
            local ck = casino:Keybind(uid("casinoKey"), CASINO_KEY, "hold", function() casinoRequested = true end)
            PERF.holdKb.casino = ck
            pcall(function() ck:AddToHotkey("Get Casino Code", uid("casino")) end)
            casino:Toggle(uid("casinoOpen"), "Open Casino Door (1)")
            local cok = casino:Keybind(uid("casinoOpenKey"), CASINO_OPEN_KEY, "hold", function() casinoOpenRequested = true end)
            PERF.holdKb.casinoOpen = cok
            pcall(function() cok:AddToHotkey("Open Casino Door", uid("casinoOpen")) end)
            casino:Toggle(uid("autoGlass"), "Auto Glass (2)")
            casino:Toggle(uid("autoVault"), "Auto Vault (3)")
            local avk = casino:Keybind(uid("autoVaultKey"), VAULT_KEY, "hold", function() vaultRequested = true end)
            PERF.holdKb.vault = avk
            pcall(function() avk:AddToHotkey("Auto Vault", uid("autoVault")) end)
            casino:Toggle(uid("autoLoot"), "Auto Collect Loot (4)")
            casino:Toggle(uid("autoHack"), "Auto Computer Hack (5)")
            casino:Toggle(uid("elevLoop"), "Elevator Loop Call (6)")
            casino:Combo(uid("elevFloor"), "Floor", PERF.ELEV.FLOORS, 0, function(index, text)
                if type(text) == "string" and PERF.ELEV.INDEX[text] then
                    PERF.ELEV.selected = text
                elseif type(index) == "number" and PERF.ELEV.FLOORS[index + 1] then
                    PERF.ELEV.selected = PERF.ELEV.FLOORS[index + 1]
                end
            end)
            casino:Button("Call Elevator", function() PERF.ELEV.call() end)
        end
		
        local mods = tab:Section("Modifiers##" .. S, "Left", { "Modifiers", "Weapons" })
        if mods.page == 1 then
            mods:Toggle(uid("nerfSkins"), "Nerf Skins")
            mods:Tip("Pistol and Revolver use the Nerf models.")
            mods:Toggle(uid("skinChanger"), "Skin Changer")
            mods:Combo(uid("skinName"), "Skin", PERF.SKIN_LABELS, 0)
            mods:Combo(uid("skinTarget"), "Weapon", PERF.SKIN_TARGETS, 0)
            mods:Button("Apply Skin", function() PERF.skinApplyRequested = true end)
            mods:Toggle(uid("hitSound"), "Hit Sound")
            mods:Combo(uid("hitSoundName"), "Sound", PERF.HIT_LABELS, 0)
            mods:Toggle(uid("hitMarker"), "Hit Markers")
            mods:Combo(uid("hitMarkerStyle"), "Marker", PERF.HITFX_MARKERS, 0)
            mods:Toggle(uid("hitKill"), "Kill Message")
        else
            mods:Toggle(uid("swordNoCd"),  "Sword No Cooldown")
            mods:Toggle(uid("swordLunge"), "Sword Always Lunge")
            mods:Toggle(uid("punchNoCd"),  "Punch No Cooldown")
            mods:Toggle(uid("instant"),    "Instant Interaction")
            mods:Toggle(uid("plasma"),     "Instant Plasma Pistol")
            mods:Tip("Equip Plasma Pistol before enabling it")
            mods:Toggle(uid("rocketLock"), "Rocket Instant Lock")
            mods:Toggle(uid("norecoil"),   "No Recoil")
            mods:Toggle(uid("nospread"),   "No Spread")
            mods:Toggle(uid("autoShoot"),  "Auto Shoot")
            mods:Tip("Make All Weapons Automatic")
        end
		
        local cfg = tab:Section("Config##" .. S, "Right", { "Config" })
        cfg:Text("Config")
        cfg:InputText(uid("cfgName"), "Config Name", "")
        cfg:Button("Load", function() PERF.CFG.load() end)
        cfg:Button("Save", function() PERF.CFG.save() end)
        cfg:Toggle(uid("hubRoles"), "Display JB Hub Roles - Server Sided")
        cfg:Spacing()
		
        local utils = tab:Section("Utils", "Right")
		utils:Toggle(uid("antiAfk"), "Anti AFK")
        utils:Button("Teleport to Mansion", function() task.spawn(PERF.MANSION.teleport) end)
        utils:Button("Reset All To Defaults", function() PERF.CFG.reset() end)
		
		local ka = tab:Section("Killaura", "Right")
        ka:Text("Require Hybrid Mod (Pro Only) !!!")
        ka:Toggle(uid("plasmaKillaura"), "PlasmaPistol Killaura")
        local kak = ka:Keybind(uid("plasmaKillauraKey"), KILLAURA_KEY, "toggle", function() end)
        PERF.kaKeybind = kak
        pcall(function() kak:AddToHotkey("PlasmaPistol Killaura", uid("plasmaKillaura")) end)
        ka:Combo(uid("plasmaKillauraTarget"), "Target", PLASMA_TARGET_MODES, 0)

        local hbx = tab:Section("Hitbox Expander", "Right")
        hbx:Toggle(uid("npcHitbox"), "NPC's Hitbox Expander")
        hbx:SliderInt(uid("hbX"), "Hitbox X", 2, 30, 10)
        hbx:SliderInt(uid("hbY"), "Hitbox Y", 2, 30, 8)
        hbx:SliderInt(uid("hbZ"), "Hitbox Z", 2, 30, 10)

        local npc = tab:Section("NPC##" .. S, "Right", { "NPC", "Guard Control" })
        if npc.page == 1 then
            npc:Combo(uid("guardMode"), "Mode", PERF.GUARD.MODES, 0)
            npc:SliderInt(uid("guardShootDist"), "Shoot Distance", 50, 500, 400)
            npc:SliderInt(uid("guardFreq"), "Trigger Freq", 1, 10, 3)
            npc:SliderInt(uid("guardProtect"), "Protect Radius", 20, 300, 80)
            npc:Toggle(uid("guardFollow"), "Follow Me", true)
            npc:Combo(uid("guardTeam"), "Target Team", PERF.GUARD.TEAMS, 0)
            npc:Tip("None = guards only follow you")
            npc:Toggle(uid("guardSpread"), "Spread Targets", true)
            npc:Tip("Split guards between threats instead of all on the closest")
        else
            npc:Toggle(uid("killNpcs"), "Kill All NPCs")
            local knk = npc:Keybind(uid("killNpcsKey"), PERF.KILL_NPC_KEY, "toggle", function() end)
            PERF.killKeybind = knk
            pcall(function() knk:AddToHotkey("Kill All NPCs", uid("killNpcs")) end)
            npc:Toggle(uid("guards"), "Make Guards Disabled")
            npc:Toggle(uid("attackCeo"), "Make Guards Attack CEO")
            npc:SliderInt(uid("npcRange"), "Range", 0, 300, 150)
        end

        local hud = tab:Section("HUD", "Right")
        hud:Toggle(uid("robHud"), "Robbery State")
        hud:Tip("Robbery panel with timers, players and bounties")

        local veh = tab:Section("Vehicle", "Right")
        veh:Toggle(uid("carFly"), "Vehicle Fly")
        local cfk = veh:Keybind(uid("carFlyKey"), VEHICLE.FLY_KEY, "toggle", function() end)
        VEHICLE.flyKeybind = cfk
        local okHk, errHk = pcall(function() cfk:AddToHotkey("Vehicle Fly", uid("carFly")) end)
        if not okHk and not VEHICLE.hkWarned then VEHICLE.hkWarned = true print("[JB] AddToHotkey error: " .. tostring(errHk)) end
        veh:SliderInt(uid("carFlySpeed"), "Speed", 0, 1000, VEHICLE.FLY_DEFAULT_SPEED)
        veh:Toggle(uid("engineBoost"), "Engine Boost")
        local ebk = veh:Keybind(uid("engineBoostKey"), VEHICLE.BOOST_KEY, "toggle", function() end)
        VEHICLE.boostKeybind = ebk
        pcall(function() ebk:AddToHotkey("Engine Boost", uid("engineBoost")) end)
        veh:SliderFloat(uid("engineBoostMult"), "Boost", 1, VEHICLE.BOOST_MAX, VEHICLE.BOOST_DEFAULT, "%.2f")		
        veh:Toggle(uid("instantBrake"), "Instant Brake")
        local ibk = veh:Keybind(uid("instantBrakeKey"), VEHICLE.BRAKE_KEY, "toggle", function() end)
        VEHICLE.brakeKeybind = ibk
        pcall(function() ibk:AddToHotkey("Instant Brake", uid("instantBrake")) end)
        veh:Toggle(uid("antiTirePop"), "Anti Tires Pop")
        veh:Toggle(uid("antiFlip"), "Anti Flip")
        veh:Toggle(uid("nitro"), "Infinity Nitro")
		
        local police = tab:Section("Police", "Right")
        police:Toggle(uid("autoCuff"), "Auto Cuff")
        local ack = police:Keybind(uid("autoCuffKey"), PERF.CUFF.KEY, "toggle", function() end)
        PERF.cuffKeybind = ack
        pcall(function() ack:AddToHotkey("Instant Auto Cuff", uid("autoCuff")) end)
        police:Toggle(uid("autoTaser"), "Auto Taser")
        local atk = police:Keybind(uid("autoTaserKey"), PERF.TASE.KEY, "toggle", function() end)
        PERF.taseKeybind = atk
        pcall(function() atk:AddToHotkey("Auto Taser", uid("autoTaser")) end)
        police:SliderInt(uid("autoTaserRange"), "Max Range", 0, 85, PERF.TASE.RANGE)
		
        local cos = tab:Section("Cosmetics", "Right")
        for _, slot in ipairs(COSMETICS.SLOTS) do
            cos:Combo(uid(slot.id), slot.label, slot.list, 0)
        end
        cos:Toggle(uid(COSMETICS.PLATE.id), "Plate")
        cos:Button("Apply Selected Cosmetics", function()
            if PERF.requireHybrid(COSMETICS.TITLE) then COSMETICS.startBind() end
        end)
        cos:Toggle(uid("cosmeticsBind"), "Apply Cosmetics Bind")
        local cosk = cos:Keybind(uid("cosmeticsKey"), COSMETICS.KEY, "hold", function() COSMETICS.requested = true end)
        PERF.holdKb.cosmetics = cosk
        pcall(function() cosk:AddToHotkey("Apply Cosmetics", uid("cosmeticsBind")) end)
        cos:Toggle(uid("cosmeticsLoop"), "Loop Cosmetics")
		
        local world = tab:Section("World", "Right")
        world:Toggle(uid("skyColor"), "Sky Color")
        world:Combo(uid("skyColorPreset"), "Color", PERF.SKY_NAMES, 0)
        world:Toggle(uid("waterCustom"), "Water Customizer")
        world:Combo(uid("waterColor"), "Water Color", PERF.WATER_NAMES, 0)
        world:SliderInt(uid("waterSea"), "Sea State", 0, 100, 32)
        world:Tip("0 = frozen sea, 100 = maximum storm")
        world:Toggle(uid("timeChanger"), "Time Changer")
        world:Combo(uid("timePreset"), "Time", PERF.TIME.PRESETS, 0)
        world:SliderFloat(uid("timeHour"), "Custom Hour", 0, 24, 12, "%.1f h")
        world:Toggle(uid("timeCycle"), "Fast Cycle")
        world:SliderFloat(uid("timeSpeed"), "Cycle Speed", 0.1, 6, 1, "%.1f h/s")
        world:Toggle(uid("matrixMode"), "Matrix Mode")
        world:Tip("Green and black world, neon edges, green water and fog")

    end)
end

pcall(function()
    local char = game:GetService("Players").LocalPlayer.Character
    local hum = char and (char:FindFirstChild("Humanoid") or char:FindFirstChildOfClass("Humanoid"))
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local addr = hum and tonumber(hum.Address)
    local base = hrp and tonumber(hrp.Address)
    local okR, real = pcall(function() return hum.Health end)
    local okPos, pos = pcall(function() return hrp.Position end)

    local function healthAt(off)
        if not addr or addr < 4096 or not okR or type(real) ~= "number" or real <= 0 or type(off) ~= "number" then return false end
        local ok, h = pcall(memory_read, "float", addr + off)
        return ok and type(h) == "number" and math.abs(h - real) < 0.01
    end

    local function primAt(primOff, posOff)
        if not base or base < 4096 or not okPos or not pos or type(primOff) ~= "number" or type(posOff) ~= "number" then return false end
        local okP, prim = pcall(memory_read, "uintptr_t", base + primOff)
        if not okP or not prim or prim < 4096 then return false end
        for i, c in ipairs({ pos.X, pos.Y, pos.Z }) do
            local ok, v = pcall(memory_read, "float", prim + posOff + (i - 1) * 4)
            if not ok or type(v) ~= "number" or math.abs(v - c) > 0.5 then return false end
        end
        return true
    end

    local d = PERF.dump or {}
    local function same(class, field, value)
        local c = d[class]
        local v = type(c) == "table" and tonumber(c[field]) or nil
        if v == nil then return nil end
        return v == value
    end
    local function rf(a)
        local ok, v = pcall(memory_read, "float", a)
        return ok and type(v) == "number" and v or nil
    end
    local function rb(a)
        local ok, v = pcall(memory_read, "byte", a)
        return ok and v or nil
    end
    local function rp(a)
        local ok, v = pcall(memory_read, "uintptr_t", a)
        return ok and type(v) == "number" and v > 4096 and v or nil
    end
    local function ru(a)
        local ok, v = pcall(memory_read, "uintptr_t", a)
        return ok and type(v) == "number" and v or nil
    end

    local checks = {}
    local function add(name, ok) checks[#checks + 1] = { name = name, ok = ok } end

    add("HUM_HEALTH", healthAt(HUM_HEALTH))
    add("PRIMITIVE_OFFSET", primAt(PRIMITIVE_OFFSET, VELOCITY_Y_OFFSET - 4 - 0xC))
    add("SIT_OFFSET", same("Humanoid", "Sit", SIT_OFFSET))
    add("PLATFORM_STAND_OFFSET", same("Humanoid", "PlatformStand", PLATFORM_STAND_OFFSET))
    add("VELOCITY_Y_OFFSET", same("Primitive", "AssemblyLinearVelocity", VELOCITY_Y_OFFSET - 4))
    add("FLIP_ANG", same("Primitive", "AssemblyAngularVelocity", VEHICLE.FLIP_ANG))

    local atmosOk = nil
    for key, off in pairs(PERF.ATMOS) do
        local r = same("Atmosphere", key, off)
        if r == false then atmosOk = false break end
        if r then atmosOk = true end
    end
    add("ATMOS", atmosOk)

    local waterOk = nil
    local waterMap = { Color = "WaterColor", Reflectance = "WaterReflectance", Transparency = "WaterTransparency", WaveSize = "WaterWaveSize", WaveSpeed = "WaterWaveSpeed" }
    for key, field in pairs(waterMap) do
        local r = same("Terrain", field, PERF.WATER_OFF[key])
        if r == false then waterOk = false break end
        if r then waterOk = true end
    end
    add("WATER_OFF", waterOk)

    local head = char and char:FindFirstChild("Head")
    local hb = head and tonumber(head.Address)
    if base and hb and hb > 4096 then
        add("TR_OFF", rf(base + PERF.HB.TR_OFF) == 1 and rf(hb + PERF.HB.TR_OFF) == 0)
        local okC, cr, cg, cb = pcall(function()
            local c = head.Color
            return c.R, c.G, c.B
        end)
        if okC and type(cr) == "number" and type(cg) == "number" and type(cb) == "number" then
            if cr <= 1 and cg <= 1 and cb <= 1 then cr, cg, cb = cr * 255, cg * 255, cb * 255 end
            local r, g, b = rb(hb + PERF.PART_COLOR), rb(hb + PERF.PART_COLOR + 1), rb(hb + PERF.PART_COLOR + 2)
            add("PART_COLOR", r ~= nil and g ~= nil and b ~= nil and math.abs(r - cr) <= 2 and math.abs(g - cg) <= 2 and math.abs(b - cb) <= 2)
        end
    end

    local folder = game:GetService("Players").LocalPlayer:FindFirstChild("Folder")
    local item = folder and folder:GetChildren()[1]
    local itemBase = item and tonumber(item.Address)
    if itemBase and itemBase > 4096 then
        local name = item.Name
        local s = rp(itemBase + PERF.NERF_NAME)
        local size = s and ru(s + PERF.NERF_SIZE)
        local cap = s and ru(s + PERF.NERF_CAP)
        local data = cap and (cap > 15 and rp(s + PERF.NERF_DATA) or (s + PERF.NERF_DATA))
        local good = data ~= nil and size == #name
        if good then
            for i = 1, math.min(#name, 16) do
                if rb(data + i - 1) ~= string.byte(name, i) then good = false break end
            end
        end
        add("NERF_NAME / NERF_DATA / NERF_SIZE / NERF_CAP", good)
    end

    local bad, known = {}, 0
    for _, c in ipairs(checks) do
        if c.ok ~= nil then
            known = known + 1
            if not c.ok then bad[#bad + 1] = c.name end
        end
    end

    if not addr or not base then
        SPLASH.step("Memory check skipped, no character", 40, "warn")
    elseif #bad == 0 then
        SPLASH.step("Memory offsets verified  " .. known .. "/" .. #checks, 40)
    else
        SPLASH.step("Outdated offsets", 40, "warn")
    end
	
    if PERF.offsetDebug then
        if #bad > 0 then
            print("[JB Debug] Update: " .. table.concat(bad, ", "))
        else
            print("[JB Debug] All offsets up to date (" .. known .. "/" .. #checks .. ")")
        end
    end

    local rs = game:GetService("ReplicatedStorage")
    local found = 0
    for _, ok in ipairs({ rs:FindFirstChild("BountyData") ~= nil, rs:FindFirstChild("PostieReceived") ~= nil, PERF.ws("Vehicles") ~= nil }) do
        if ok then found = found + 1 end
    end
    SPLASH.step("Game data located  " .. found .. "/3", 52, found == 3 and "ok" or "warn")

    local hybrid = PERF.isHybrid()
    SPLASH.info.hybrid = hybrid and "Hybrid ON" or "Hybrid OFF"
    if hybrid then
        SPLASH.step("Hybrid mode active", 64)
    else
        SPLASH.step("Hybrid mode off, some features locked", 64, "warn")
    end
end)

task.spawn(function()
    for _ = 1, 3 do
        pcall(function() UI.RemoveTab("JB Hub") end)
        task.wait(0.05)
    end
    task.wait(0.25)
    SPLASH.uiOk = pcall(buildTab)
    SPLASH.uiDone = true
end)

local function isSittingNow()
    local sitting = false
    pcall(function()
        local hum = getHumanoid()
        local addr = hum and tonumber(hum.Address)
        if addr and addr > 4096 then
            sitting = memory_read("byte", addr + SIT_OFFSET) == 1
        end
    end)
    return sitting
end

task.spawn(function()
    local targets = nil
    local wasOn = false
    while _G.JB_gen == myGen do
        PERF.run("plasma", function()
            local on = UI.GetValue(uid("plasma")) and true or false
            if on and not wasOn then
                if not isPlasmaEquipped() then
                    UI.SetValue(uid("plasma"), false)
                    notify("Equip Plasma Pistol before", "[JB Hub] Instant Plasma Pistol", 3)
                    return
                end
                targets = scanInstantPlasma()
                if not targets then
                    UI.SetValue(uid("plasma"), false)
                    notify("Config not found, try again", "[JB Hub] Instant Plasma Pistol", 3)
                    return
                end
                if not writePlasmaTargets(targets) then
                    targets = nil
                    UI.SetValue(uid("plasma"), false)
                    notify("Config changed, try again", "[JB Hub] Instant Plasma Pistol", 3)
                    return
                end
                wasOn = true
                notify("ON", "[JB Hub] Instant Plasma Pistol", 3)
            elseif not on and wasOn then
                wasOn = false
                targets = nil
                notify("OFF", "[JB Hub] Instant Plasma Pistol", 3)
            elseif on and targets then
                if not writePlasmaTargets(targets) then
                    wasOn = false
                    targets = nil
                    UI.SetValue(uid("plasma"), false)
                    notify("Plasma Pistol changed, enable it again", "[JB Hub] Instant Plasma Pistol", 3)
                end
            end
        end)
        task.wait(INSTANT_PLASMA_TICK)
    end
end)

task.spawn(function()
    local TITLE = "[JB Hub] Infinity Nitro"
    local cache = {}
    local lastScan = 0
    local wasOn = false
    local wasSitting = false
    local seatScanned = false
    local active = false
    while _G.JB_gen == myGen do
        PERF.run("nitro", function()
            local on = UI.GetValue(uid("nitro")) and true or false
            if on ~= wasOn then
                wasOn = on
                if on then
                    seatScanned, active = false, false
                    wasSitting = isSittingNow()
                    cache = PERF.numericOnly(lockedGetgc(NITRO_KEYS))
                    lastScan = tick()
                    if #cache == 0 then notify("Get in a vehicle to activate", TITLE, 3) end
                else
                    active = false
                    notify("OFF", TITLE, 3)
                end
            end
            if on then
                local sitting = isSittingNow()
                if sitting and not wasSitting and count(cache) == 0 and (not seatScanned or tick() - lastScan >= NITRO_EMPTY_RETRY) then
                    wait(NITRO_SEAT_DELAY)
                    cache = PERF.numericOnly(lockedGetgc(NITRO_KEYS))
                    lastScan = tick()
                    seatScanned = true
                elseif not sitting and tick() - lastScan >= NITRO_RESCAN_EVERY then
                    cache = PERF.numericOnly(lockedGetgc(NITRO_KEYS))
                    lastScan = tick()
                end
                wasSitting = sitting
                cache = PERF.gcAlive(cache)
                if #cache > 0 then
                    applygc(cache, NITRO_VALUES)
                    if not active then
                        active = true
                        notify("ON", TITLE, 3)
                    end
                end
            end
        end)
        task.wait(NITRO_APPLY_TICK)
    end
end)

task.spawn(function()
    local KEYS = { "LocalFuel", "LocalMaxFuel", "ThrustingBornAt" }
    local VALUES = { LocalFuel = 999999, LocalMaxFuel = 999999, ThrustingBornAt = 0 }
    local TICK = 0.25
    local EMPTY_RETRY = 180
    local SPAWN_DELAY = 2
    local THRUST_RESCAN = 3
	
    local cache, wasOn, applied, lastScan, lastChar, lastPack, pendingAt = {}, false, false, 0, nil, nil, nil
    local thrustTried = false

    local function packModel(char)
        return char and (char:FindFirstChild("JetPack") or char:FindFirstChild("Jetpack"))
    end

    local function valid(e)
        local ok, ptr = pcall(memory_read, "uintptr_t", e.addr + 0x10)
        return ok and ptr == e.keyPtr
    end

    local function hasThrust()
        for _, e in ipairs(cache) do
            if e.key == "ThrustingBornAt" then return true end
        end
        return false
    end

    local function restore()
        for _, e in ipairs(cache) do
            if valid(e) then pcall(memory_write, "double", e.addr, e.original) end
        end
        cache = {}
    end

    local function scan()
        restore()
        local seen = {}
        for _, e in ipairs(lockedGetgc(KEYS)) do
            local key = tostring(e.key)
            local addr = tonumber(e.addr)
            if VALUES[key] ~= nil and addr and addr > 4096 and not seen[addr] and tonumber(tostring(e.value)) then
                local okP, keyPtr = pcall(memory_read, "uintptr_t", addr + 0x10)
                local okV, original = pcall(memory_read, "double", addr)
                if okP and okV and keyPtr and keyPtr > 4096 then
                    seen[addr] = true
                    cache[#cache + 1] = { addr = addr, key = key, keyPtr = keyPtr, original = original }
                end
            end
        end
        lastScan = tick()
    end

    local function apply()
        local kept, consumed = {}, false
        for _, e in ipairs(cache) do
            if valid(e) then
                if e.key == "LocalFuel" then
                    local okR, cur = pcall(memory_read, "double", e.addr)
                    if okR and type(cur) == "number" and cur < VALUES.LocalFuel - 0.5 and cur > VALUES.LocalFuel - 1000 then
                        consumed = true
                    end
                end
                if pcall(memory_write, "double", e.addr, VALUES[e.key]) then
                    kept[#kept + 1] = e
                end
            end
        end
        cache = kept
        return #kept, consumed
    end

    while _G.JB_gen == myGen do
        PERF.run("jetpack", function()
            local on = UI.GetValue(uid("jetpack")) and true or false
            if on ~= wasOn then
                wasOn = on
                if on then
                    applied = false
                    local char = game:GetService("Players").LocalPlayer.Character
                    lastChar = char and char.Address
                    lastPack = packModel(char) and true or false
                    scan()
                else
                    restore()
                    pendingAt = nil
                    notify("OFF", "[JB Hub] Infinity Jetpack", 3)
                end
            end
            if not on then return end

            local now = tick()
            local char = game:GetService("Players").LocalPlayer.Character
            local charAddr = char and char.Address
            local pack = packModel(char) and true or false
            if charAddr ~= lastChar or (pack and not lastPack) then
                pendingAt, thrustTried = now + SPAWN_DELAY, false
            end
            lastChar, lastPack = charAddr, pack

            if pendingAt and now >= pendingAt then
                pendingAt = nil
                scan()
            elseif #cache == 0 and now - lastScan >= EMPTY_RETRY then
                scan()
            end

            if #cache > 0 then
                local n, consumed = apply()
                if consumed and pack and not thrustTried and not hasThrust() then
                    thrustTried = true
                    scan()
                    apply()
                end
                if n > 0 and not applied then
                    applied = true
                    notify("ON", "[JB Hub] Infinity Jetpack", 3)
                end
            end
        end)
        task.wait(TICK)
    end
    restore()
end) 

task.spawn(function()
    local TITLE = "[JB Hub] No Laser Damage"
    local TICK, NEAR, NEAR_CHECK, NEAR_REFRESH, FAR_REFRESH, EXTRA_EVERY, FULL_EVERY = 0.15, 600, 0.5, 6, 4, 1, 1
    local slots, near = {}, {}
    local trapDone = {}
    local wasOn, nearAt, farAt, extraAt, recheckAt, nextFar, nextNear, fullAt, missAt = false, 0, 0, 0, 0, 1, 1, 0, 0

    local function refresh(i)
        local pathList = LASER_CONTAINERS[i]
        local slot = slots[i] or {}
        slots[i] = slot
        slot.at = tick()
        local root = resolveLaserRoot(pathList)
        if not root then
            slot.list, slot.anchors = {}, nil
            return
        end
        local roots = { root }
        if pathList.sub then
            local valid = slot.folders and #slot.folders > 0 and tick() - (slot.foldersAt or 0) < 10
            if valid then
                for _, f in ipairs(slot.folders) do
                    if not f.Parent then valid = false break end
                end
            end
            if not valid then
                slot.folders, slot.foldersAt = {}, tick()
                for n, d in ipairs(root:GetDescendants()) do
                    if n % PERF.LASER_YIELD_EVERY == 0 then task.wait() end
                    if d.Name == pathList.sub then slot.folders[#slot.folders + 1] = d end
                end
            end
            roots = slot.folders
        end
        local list, anchors = {}, {}
        for _, r in ipairs(roots) do
            if not pcall(collectLaserParts, r, pathList, list, anchors) then
                pcall(collectLaserPartsSafe, r, pathList, list)
            end
        end
        slot.list, slot.fresh = list, list
        if #anchors == 0 then
            for k = 1, #list, 4 do
                pcall(function()
                    local p = list[k].Position
                    anchors[#anchors + 1] = p.X
                    anchors[#anchors + 1] = p.Z
                end)
            end
        end
        if #anchors > 0 then slot.anchors = anchors end
    end

    local function foldersGone(slot)
        for _, f in ipairs(slot.folders or {}) do
            if not f.Parent then return true end
        end
        return false
    end

    local function myPos()
        local hrp = getHRP()
        return hrp and vaultReadPos(hrp)
    end

    local function updateNear(me)
        nearAt = tick()
        near = {}
        if not me then return end
        local range = NEAR * NEAR
        for i = 1, #LASER_CONTAINERS do
            local a = slots[i] and slots[i].anchors
            if a then
                for k = 1, #a - 1, 2 do
                    local dx, dz = a[k] - me.X, a[k + 1] - me.Z
                    if dx * dx + dz * dz <= range then
                        near[#near + 1] = i
                        break
                    end
                end
            end
        end
    end

    local function shrinkNear(full)
        for _, i in ipairs(near) do
            local slot = slots[i]
            local list = slot and (full and slot.list or slot.fresh)
            if slot then slot.fresh = nil end
            if list then
                for k = 1, #list do
                    pcall(function()
                        local part = list[k]
                        if part.Size.X > 0.01 then part.Size = LASER_TINY end
                    end)
                end
            end
        end
    end

    local function neutralizeTraps()
        local mansion = PERF.ws("MansionRobbery")
        local traps = mansion and mansion:FindFirstChild("LaserTraps")
        if not traps then return end
        for _, trap in ipairs(traps:GetChildren()) do
            local key = trap.Address
            if not trapDone[key] then
                pcall(function()
                    if trap:GetAttribute("LaserTrapDamage") ~= 0 then trap:SetAttribute("LaserTrapDamage", 0) end
                    trapDone[key] = true
                end)
            end
        end
    end

    local function count()
        local n = 0
        for _, slot in pairs(slots) do n = n + #(slot.list or {}) end
        return n
    end

    while _G.JB_gen == myGen do
        PERF.run("nolaser", function()
            local on = UI.GetValue(uid("nolaser")) and true or false
            if on ~= wasOn then
                wasOn = on
                if not on then
                    slots, near, trapDone = {}, {}, {}
                    notify("OFF", TITLE, 3)
                    return
                end
                for i = 1, #LASER_CONTAINERS do refresh(i) end
                updateNear(myPos())
                shrinkNear(true)
                local total = count()
                notify(total > 0 and ("ON (" .. total .. " traps)") or "ON (no traps loaded yet)", TITLE, 3)
                return
            end
            if not on then return end

            local now = tick()
            if not PERF.solving then
                if now - nearAt >= NEAR_CHECK then
                    updateNear(myPos())
                    for _, i in ipairs(near) do
                        if slots[i] and foldersGone(slots[i]) then refresh(i) end
                    end
                end
                if #near > 0 then
                    nextNear = nextNear % #near + 1
                    local i = near[nextNear]
                    if now - (slots[i] and slots[i].at or 0) >= NEAR_REFRESH then refresh(i) end
                end
                if now - missAt >= 2 then
                    missAt = now
                    for i = 1, #LASER_CONTAINERS do
                        local slot = slots[i]
                        if (not slot or not slot.anchors) and now - (slot and slot.at or 0) >= 6 and resolveLaserRoot(LASER_CONTAINERS[i]) then
                            refresh(i)
                        end
                    end
                end
                if now - farAt >= FAR_REFRESH then
                    farAt = now
                    refresh(nextFar)
                    nextFar = nextFar % #LASER_CONTAINERS + 1
                end
            end
            local full = now - fullAt >= FULL_EVERY
            if full then fullAt = now end
            shrinkNear(full)
            if now - extraAt >= EXTRA_EVERY then
                extraAt = now
                if now - recheckAt >= 10 then
                    recheckAt = now
                    trapDone = {}
                end
                pcall(neutralizeTraps)
            end
        end)
        task.wait(TICK)
    end
end)

task.spawn(function()
    local WIRE_PATH = { "PowerPlant", only = "BarbedWire" }
    local wires, pistons = {}, {}
    local wireOn, pistonOn, wireAt, pistonAt, moveAt = false, false, 0, 0, 0

    local function getWires()
        local list = {}
        local root = resolveLaserRoot(WIRE_PATH)
        if root and not pcall(collectLaserParts, root, WIRE_PATH, list) then
            list = {}
            pcall(collectLaserPartsSafe, root, WIRE_PATH, list)
        end
        local anchor
        for _, part in ipairs(list) do
            local ok, p = pcall(function() return part.Position end)
            if ok and typeof(p) == "Vector3" then anchor = p break end
        end
        if not anchor then return list end
        local function consider(part)
            if part.Name ~= "BarbedWire" then return end
            local touch = false
            for _, c in ipairs(part:GetChildren()) do
                if c.ClassName == "TouchTransmitter" then touch = true break end
            end
            if not touch then return end
            local ok, p = pcall(function() return part.Position end)
            if ok and typeof(p) == "Vector3" and (p - anchor).Magnitude <= 400 then list[#list + 1] = part end
        end
        for _, c in ipairs(workspace:GetChildren()) do
            if c.Name == "BarbedWire" then
                pcall(consider, c)
            elseif c.Name == "Model" and c.ClassName == "Model" then
                for _, m in ipairs(c:GetChildren()) do pcall(consider, m) end
            end
        end
        return list
    end

    local function moveAway(part)
        pcall(function()
            local p = part.Position
            if p.Y > DART_AWAY_Y + 100 then part.Position = Vector3.new(p.X, DART_AWAY_Y, p.Z) end
        end)
    end

    while _G.JB_gen == myGen do
        PERF.run("powerPlant", function()
            local w = UI.GetValue(uid("ppWire")) and true or false
            local p = UI.GetValue(uid("ppPistons")) and true or false
            if w ~= wireOn then
                wireOn, wires, wireAt = w, {}, 0
                notify(w and "ON" or "OFF", "[JB Hub] No Barbed Wire Damage", 3)
            end
            if p ~= pistonOn then
                pistonOn, pistons, pistonAt = p, {}, 0
                notify(p and "ON" or "OFF", "[JB Hub] No Piston Damage", 3)
            end
            local now = tick()
            if w then
                if not PERF.solving and now - wireAt >= PISTON_REFRESH then
                    wires, wireAt = getWires(), now
                end
                for _, part in ipairs(wires) do
                    pcall(function()
                        if part.Size.X > 0.01 then part.Size = LASER_TINY end
                    end)
                end
            end
            if p then
                if not PERF.solving and now - pistonAt >= PISTON_REFRESH then
                    pistons, pistonAt = getPistonOrigins(), now
                end
                if now - moveAt >= 1 then
                    moveAt = now
                    for _, origin in ipairs(pistons) do moveAway(origin) end
                end
            end
        end)
        task.wait((UI.GetValue(uid("ppWire")) or UI.GetValue(uid("ppPistons"))) and 0.15 or 0.5)
    end
end)

task.spawn(function()
    local FEATURES = {
        { id = "tombSpikes", label = "No Spike Damage" },
        { id = "tombDarts", label = "No Dart Damage" },
        { id = "tombBridge", label = "Safe Bridge" },
        { id = "tombCart", label = "No Cart Barrier Damage" },
    }
    local state = {}
    local dartOriginals, spikeOriginals, plankOriginals, woodOriginals = {}, {}, {}, {}
    local closedSince, bridgeChecked = {}, {}
    local spikeList, lastSpikeScan, lastRecheck = {}, 0, 0

    local function sinkPart(part, store)
        local p = part.Position
        if p.Y > DART_AWAY_Y + 100 then
            local key = part.Address
            if not store[key] then store[key] = { part = part, pos = p } end
            part.Position = Vector3.new(p.X, DART_AWAY_Y, p.Z)
        end
    end

    local function restorePositions(store)
        for key, e in pairs(store) do
            pcall(function() e.part.Position = e.pos end)
            store[key] = nil
        end
    end

    local function applyDarts(tomb)
        local room = tomb:FindFirstChild("DartRoom")
        local darts = room and room:FindFirstChild("Darts")
        if not darts then return end
        for _, d in ipairs(darts:GetChildren()) do
            pcall(sinkPart, d, dartOriginals)
        end
    end

    local function applySpikes(tomb, now)
        if now - lastSpikeScan >= PERF.TOMB_SPIKE_REFRESH then
            lastSpikeScan = now
            local room = tomb:FindFirstChild("SpikeRoom")
            local list = {}
            if room then pcall(collectLaserParts, room, {}, list) end
            spikeList = list
        end
        for _, part in ipairs(spikeList) do
            pcall(function()
                local size = part.Size
                if size.X > 0.01 then
                    local key = part.Address
                    if not spikeOriginals[key] then spikeOriginals[key] = { part = part, size = size } end
                    part.Size = LASER_TINY
                end
            end)
        end
    end

    local function restoreSpikes()
        for key, e in pairs(spikeOriginals) do
            pcall(function() e.part.Size = e.size end)
            spikeOriginals[key] = nil
        end
        spikeList, lastSpikeScan = {}, 0
    end

    local function isPlankVisible(plank)
        local inner = plank:FindFirstChild("InnerModel")
        local board = inner and inner:FindFirstChild("Plank")
        return board ~= nil and board.Transparency < 1
    end

    local function freezeBridge(tomb, now)
        local bridge = tomb:FindFirstChild("Bridge")
        if not bridge then return end
        for _, plank in ipairs(bridge:GetChildren()) do
            pcall(function()
                local key = plank.Address
                if bridgeChecked[key] then return end
                if plank:GetAttribute("DoorDuration") == BRIDGE_FROZEN_DURATION then
                    bridgeChecked[key] = true
                    return
                end
                if plank:GetAttribute("DoorOpen") == true or not isPlankVisible(plank) then
                    closedSince[key] = nil
                    return
                end
                closedSince[key] = closedSince[key] or now
                if now - closedSince[key] >= BRIDGE_SETTLE_TIME then
                    plankOriginals[key] = {
                        plank = plank,
                        angle = plank:GetAttribute("DoorMaxAngle"),
                        duration = plank:GetAttribute("DoorDuration"),
                    }
                    plank:SetAttribute("DoorMaxAngle", BRIDGE_FLAT_ANGLE)
                    plank:SetAttribute("DoorDuration", BRIDGE_FROZEN_DURATION)
                    bridgeChecked[key] = true
                end
            end)
        end
    end

    local function restoreBridge()
        for key, entry in pairs(plankOriginals) do
            pcall(function()
                if entry.angle ~= nil then entry.plank:SetAttribute("DoorMaxAngle", entry.angle) end
                if entry.duration ~= nil then entry.plank:SetAttribute("DoorDuration", entry.duration) end
            end)
            plankOriginals[key] = nil
        end
        closedSince, bridgeChecked = {}, {}
    end

    local function hideCartPlanks(tomb)
        local cart = tomb:FindFirstChild("Cart")
        local planks = cart and cart:FindFirstChild("Planks")
        if not planks then return end
        for _, wood in ipairs(planks:GetChildren()) do
            if wood.Name == "Wood" then pcall(sinkPart, wood, woodOriginals) end
        end
    end

    local apply = {
        tombDarts = applyDarts,
        tombSpikes = applySpikes,
        tombBridge = freezeBridge,
        tombCart = hideCartPlanks,
    }
    local restore = {
        tombDarts = function() restorePositions(dartOriginals) end,
        tombSpikes = restoreSpikes,
        tombBridge = restoreBridge,
        tombCart = function() restorePositions(woodOriginals) end,
    }

    while _G.JB_gen == myGen do
        local anyOn = false
        PERF.run("tomb", function()
            local now = tick()
            if now - lastRecheck >= PERF.TOMB_RECHECK then
                lastRecheck = now
                bridgeChecked = {}
            end
            local tomb = nil
            for _, f in ipairs(FEATURES) do
                local on = UI.GetValue(uid(f.id)) and true or false
                if on ~= (state[f.id] or false) then
                    state[f.id] = on
                    if not on then pcall(restore[f.id]) end
                    notify(on and "ON" or "OFF", "[JB Hub] " .. f.label, 3)
                end
                if on then
                    anyOn = true
                    tomb = tomb or PERF.ws("RobberyTomb")
                    if tomb then pcall(apply[f.id], tomb, now) end
                end
            end
        end)
        task.wait(anyOn and PERF.TOMB_TICK or 0.5)
    end
    for _, f in ipairs(FEATURES) do
        if state[f.id] then pcall(restore[f.id]) end
    end
end)

task.spawn(function()
    local wasOn = false
    local originals = {}
    local milEntries = nil
    local lastMilScan = 0
    local milDelay = MIL_TURRET_RESCAN

    local turretList, lastTurretScan = {}, 0
    local TURRET_SCAN_EVERY, TURRET_MAX_DEPTH = 60, 4

    local function isAutoTurret(m)
        local base, arm = m:FindFirstChild("Base"), m:FindFirstChild("Arm")
        return base and arm and base:FindFirstChild("Root") and arm:FindFirstChild("Root")
            and arm:FindFirstChild("Barrel") and arm:FindFirstChild("Tip") and true or false
    end

    local function getOilRigTurrets()
        if tick() - lastTurretScan < TURRET_SCAN_EVERY then return turretList end
        lastTurretScan = tick()
        local list, seen, visited = {}, {}, 0
        local skip = { Vehicles = true }
        for _, p in ipairs(game:GetService("Players"):GetPlayers()) do skip[p.Name] = true end

        local function add(m)
            local key = m.Address
            if not seen[key] then
                seen[key] = true
                list[#list + 1] = m
            end
        end

        local function walk(node, depth)
            for _, c in ipairs(node:GetChildren()) do
                visited = visited + 1
                if visited % 400 == 0 then task.wait() end
                local cls = c.ClassName
                if cls == "Model" or cls == "Folder" then
                    local ok, auto = false, false
                    if cls == "Model" then ok, auto = pcall(isAutoTurret, c) end
                    if ok and auto then
                        add(c)
                    elseif depth < TURRET_MAX_DEPTH and not (depth == 1 and skip[c.Name]) then
                        walk(c, depth + 1)
                    end
                end
            end
        end

        pcall(walk, workspace, 1)
        for _, pathList in ipairs(TURRET_CONTAINERS) do
            local root = resolveLaserRoot(pathList)
            if root then
                for _, t in ipairs(root:GetChildren()) do add(t) end
            end
        end
        turretList = list
        return list
    end

    local function getCargoTurrets()
        local list = {}
        for _, pathList in ipairs(TURRET_MODELS) do
            local t = resolveLaserRoot(pathList)
            if t then table.insert(list, t) end
        end
        if #list > 0 then return list end
        local ship = PERF.ws("CargoShip")
        if not ship then
            PERF.cargoFound = {}
            return list
        end
        if tick() - (PERF.cargoScanAt or 0) >= 5 then
            PERF.cargoScanAt = tick()
            local found = {}
            for i, d in ipairs(ship:GetDescendants()) do
                if i % 400 == 0 then task.wait() end
                if d.ClassName == "Model" then
                    local ok, auto = pcall(isAutoTurret, d)
                    if ok and auto then found[#found + 1] = d end
                end
            end
            PERF.cargoFound = found
        end
        return PERF.cargoFound or list
    end

    local turretDone, turretRecheckAt = {}, 0
    local function withoutCargo(list)
        local ship = PERF.ws("CargoShip")
        if not ship then return list end
        local out = {}
        for _, t in ipairs(list) do
            local ok, inside = pcall(function() return t:IsDescendantOf(ship) end)
            if not (ok and inside) then out[#out + 1] = t end
        end
        return out
    end
    local function applyTurrets(list)
        local now = tick()
        if now >= turretRecheckAt then
            turretRecheckAt = now + PERF.TURRET_RECHECK
            turretDone = {}
        end
        local count = 0
        for _, t in ipairs(list) do
            pcall(function()
                local key = t.Address
                if turretDone[key] then
                    count = count + 1
                    return
                end
                local hz = t:GetAttribute("TurretShootHz")
                if hz ~= nil or isAutoTurret(t) then
                    count = count + 1
                    if hz ~= 0 then
                        if not originals[key] then
                            originals[key] = { turret = t, hz = hz }
                        end
                        t:SetAttribute("TurretShootHz", 0)
                    end
                    turretDone[key] = true
                end
            end)
        end
        return count
    end

    local cargoSlots = {}
    local cargoDelay = CARGO.RESCAN
    local lastCargoScan = 0

    local function readNumber(addr)
        local okT, tag = pcall(memory_read, "int", addr + 12)
        local okD, d = pcall(memory_read, "double", addr)
        if okT and tag == 3 and okD and type(d) == "number" then return d end
        return nil
    end

    local function scanCargo()
        lastCargoScan = tick()
        local shoots, hits = {}, {}
        for _, e in ipairs(lockedGetgc({ "LastShoot", "LastHit" })) do
            local k = tostring(e.key)
            local a = tonumber(e.addr)
            if a and tonumber(tostring(e.value)) then
                if k == "LastShoot" then
                    table.insert(shoots, a)
                elseif k == "LastHit" then
                    table.insert(hits, a)
                end
            end
        end
        for _, a in ipairs(shoots) do
            if not cargoSlots[a] then
                for _, h in ipairs(hits) do
                    if math.abs(h - a) <= CARGO.PAIR_RANGE then
                        cargoSlots[a] = h
                        break
                    end
                end
            end
        end
    end

    local function restoreCargo()
        for a in pairs(cargoSlots) do
            if readNumber(a) == CARGO.FREEZE then
                pcall(memory_write, "double", a, os.clock())
            end
        end
        cargoSlots = {}
        lastCargoScan = 0
    end

    local function modelPos(m)
        for _, c in ipairs(m:GetChildren()) do
            local ok, p = pcall(function() return c.Position end)
            if ok and p and pcall(function() return p.X + 0 end) then return p end
        end
        for _, c in ipairs(m:GetChildren()) do
            for _, cc in ipairs(c:GetChildren()) do
                local ok, p = pcall(function() return cc.Position end)
                if ok and p and pcall(function() return p.X + 0 end) then return p end
            end
        end
        return nil
    end

    local function isNear(m, range)
        local hrp = getHRP()
        local okMe, me = pcall(function() return hrp.Position end)
        if not okMe or not me then return true end
        local okP, p = pcall(modelPos, m)
        if not okP or not p then return true end
        return (p - me).Magnitude <= range
    end

    local function applyCargo(list)
        if #list == 0 then
            restoreCargo()
            return 0
        end
        local slots = 0
        for _ in pairs(cargoSlots) do slots = slots + 1 end
        local every = slots >= #list and CARGO.RESCAN_SLOW or cargoDelay
        local near = false
        for _, t in ipairs(list) do
            local okP, p = pcall(modelPos, t)
            local hrp = getHRP()
            local okMe, me = pcall(function() return hrp.Position end)
            if okP and p and okMe and me and (p - me).Magnitude <= PERF.NEAR_CARGO then near = true break end
        end
        if near and tick() - lastCargoScan >= every then
            scanCargo()
            local after = 0
            for _ in pairs(cargoSlots) do after = after + 1 end
            cargoDelay = after > slots and CARGO.RESCAN or math.min(cargoDelay * 2, CARGO.RESCAN_SLOW)
        end
        local frozen = 0
        for a, h in pairs(cargoSlots) do
            local d = readNumber(a)
            local hv = readNumber(h)
            if d and hv and hv < CARGO.FREEZE / 10 then
                if d ~= CARGO.FREEZE then
                    pcall(memory_write, "double", a, CARGO.FREEZE)
                end
                frozen = frozen + 1
            else
                cargoSlots[a] = nil
            end
        end
        return frozen > 0 and #list or 0
    end    

    local function restoreTurrets(list, defaultHz)
        for _, t in ipairs(list) do
            pcall(function()
                local key = t.Address
                local entry = originals[key]
                if t:GetAttribute("TurretShootHz") == 0 then
                    t:SetAttribute("TurretShootHz", entry and entry.hz or defaultHz or TURRET_DEFAULT_HZ)
                end
                originals[key] = nil
            end)
        end
    end

    local function restoreAllTurrets()
        for _, entry in pairs(originals) do
            pcall(function()
                if entry.turret:GetAttribute("TurretShootHz") == 0 then
                    entry.turret:SetAttribute("TurretShootHz", entry.hz)
                end
            end)
        end
        turretDone, turretRecheckAt = {}, 0
        turretList, lastTurretScan = {}, 0
        restoreCargo()
        originals = {}
    end

    local function scanMilitary()
        lastMilScan = tick()
        local entries = {}
        for _, e in ipairs(lockedGetgc(MIL_TURRET_KEYS)) do
            local key = tostring(e.key)
            local value = tonumber(tostring(e.value))
            local addr = tonumber(e.addr)
            if MIL_TURRET_VALUES[key] ~= nil and value and addr then
                local ok, cur = pcall(memory_read, "double", addr)
                if ok and type(cur) == "number" and math.abs(cur - value) < 0.0001 then
                    local original = value
                    if math.abs(value - MIL_TURRET_VALUES[key]) < 0.0001 then
                        original = MIL_TURRET_DEFAULTS[key]
                    end
                    table.insert(entries, { key = key, original = original, addr = addr })
                end
            end
        end
        if #entries == 0 then return nil end
        return entries
    end

    local function writeMilitary(entries, restoring)
        for _, e in ipairs(entries) do
            local ok, cur = pcall(memory_read, "double", e.addr)
            if not ok or type(cur) ~= "number" then return false end
            local target = MIL_TURRET_VALUES[e.key]
            if math.abs(cur - e.original) > 0.0001 and math.abs(cur - target) > 0.0001 then
                return false
            end
        end
        for _, e in ipairs(entries) do
            local value = restoring and e.original or MIL_TURRET_VALUES[e.key]
            pcall(function() memory_write("double", e.addr, value) end)
        end
        return true
    end

    local function nearMilitary()
        local base = PERF.ws("MilitaryBase")
        local tower = base and base:FindFirstChild("MilitaryTower")
        if not tower then return true end
        local okP, p = pcall(modelPos, tower)
        local hrp = getHRP()
        local okMe, me = pcall(function() return hrp.Position end)
        if not (okP and p and okMe and me) then return false end
        return (p - me).Magnitude <= 1200
    end

    local function applyMilitary(notifyWhenFound)
        if milEntries and not writeMilitary(milEntries, false) then
            milEntries = nil
            milDelay = MIL_TURRET_RESCAN
        end
        local near = nearMilitary()
        if near and not PERF.milWasNear then lastMilScan, milDelay = 0, MIL_TURRET_RESCAN end
        PERF.milWasNear = near
        if not milEntries and tick() - lastMilScan >= milDelay and near then
            milEntries = scanMilitary()
            if milEntries and writeMilitary(milEntries, false) then
                milDelay = MIL_TURRET_RESCAN
                if notifyWhenFound then
                    PERF.notifySafe("Military turrets disabled", TURRET_TITLE, 3)
                end
            else
                milEntries = nil
                milDelay = math.min(milDelay * 2, 20)
            end
        end
        return milEntries ~= nil
    end

    local function restoreMilitary()
        if milEntries then
            writeMilitary(milEntries, true)
        end
        milEntries = nil
    end

    local homes, homeGhosts, lastHomeScan = {}, {}, 0
    local homeShown = false

    local function scanHomes()
        lastHomeScan = tick()
        local list = {}
        for _, child in ipairs(workspace:GetChildren()) do
            if child:FindFirstChild("Turret") then list[#list + 1] = child end
        end
        homes = list
    end

    local ghostList, ghostAt, ghostSrc = {}, 0, nil
    local function applyHomes()
        local now = tick()
        if PERF.homeModels ~= ghostSrc or now - ghostAt >= 10 then
            ghostSrc, ghostAt = PERF.homeModels, now
            ghostList = {}
            for _, home in ipairs(ghostSrc or {}) do
                pcall(function()
                    for _, m in ipairs(home:GetChildren()) do
                        if m.Name == "Turret" then
                            local ghost = m:FindFirstChild("IsGhost")
                            if ghost then ghostList[#ghostList + 1] = ghost end
                        end
                    end
                end)
            end
        end
        for _, ghost in ipairs(ghostList) do
            pcall(function()
                if ghost.Value ~= true then
                    local key = ghost.Address
                    if homeGhosts[key] == nil then
                        homeGhosts[key] = { value = ghost, old = ghost.Value }
                    end
                    ghost.Value = true
                end
            end)
        end
        return #ghostList
    end

    local function restoreHomes()
        for _, e in pairs(homeGhosts) do
            pcall(function() e.value.Value = e.old end)
        end
        homeGhosts = {}
        homes = {}
        ghostList, ghostAt, ghostSrc = {}, 0, nil
        lastHomeScan = 0
    end

    local oilShown, cargoShown = false, false

    local function groupNotify(name, count, wasShown, live)
        if count > 0 then
            if not wasShown then
                notify(live and (name .. " turrets disabled") or (name .. ": " .. count .. " turrets disabled"), TURRET_TITLE, 3)
            end
            return true
        end
        if not live then
            notify(name .. ": not loaded", TURRET_TITLE, 3)
        end
        return false
    end

    while _G.JB_gen == myGen do
        PERF.run("noturret", function()
            local on = UI.GetValue(uid("noturret")) and true or false
            if on and not wasOn then
                wasOn = true
                lastMilScan = 0
                milDelay = MIL_TURRET_RESCAN
                oilShown = groupNotify("Oil Rig", applyTurrets(withoutCargo(getOilRigTurrets())), false, false)
                cargoShown = groupNotify("Cargo Ship", applyCargo(getCargoTurrets()), false, false)
                homeShown = groupNotify("Home", applyHomes(), false, false)
                local mil = applyMilitary(false)
                PERF.notifySafe(mil and "Military turrets disabled" or (nearMilitary() and "Military: offsets outdated, wait for JB Hub update ..." or "Military: ready, activates near the base"), TURRET_TITLE, 3)
            elseif not on and wasOn then
                wasOn = false
                oilShown, cargoShown, homeShown = false, false, false
                restoreAllTurrets()
                restoreHomes()
                restoreMilitary()
                notify("OFF", TURRET_TITLE, 3)
            elseif on then
                oilShown = groupNotify("Oil Rig", applyTurrets(withoutCargo(getOilRigTurrets())), oilShown, true)
                cargoShown = groupNotify("Cargo Ship", applyCargo(getCargoTurrets()), cargoShown, true)
                homeShown = groupNotify("Home", applyHomes(), homeShown, true)
                applyMilitary(true)
            end
        end)
        task.wait(TURRET_TICK)
    end
    restoreAllTurrets()
    restoreHomes()
    restoreMilitary()
end)

task.spawn(function()
    local wasOn = false
    local keyDown = false
    local busy = false
    local lastDone = 0
    while _G.JB_gen == myGen do
        PERF.run("puzzleSolve", function()
            local on = UI.GetValue(uid("puzzleSolve")) and true or false
            if on ~= wasOn then
                wasOn = on
                notify(on and "ON" or "OFF", "[JB Hub] Auto-Solve Puzzle", 3)
            end
            local down = false
            down = PERF.keyDown("puzzle", FLOW_KEY)
            local trigger = (down and not keyDown) or flowRequested
            keyDown = down
            flowRequested = false
            if trigger and on and not busy and tick() - lastDone > 1 then
                busy = true
                PERF.solving = true
                local ok, err = pcall(autoSolveFlow)
                PERF.solving = false
                if not ok then
                    pcall(mouse1release)
                    notify("Error: " .. tostring(err), "[JB Hub] Auto-Solve Puzzle", 3)
                end
                flowRequested = false
                lastDone = tick()
                busy = false
            end
        end)
        task.wait(0.03)
    end
end)

task.spawn(function()
    local wasOn, shown, seen = false, false, false
    while _G.JB_gen == myGen do
        PERF.run("puzzlePath", function()
            local on = UI.GetValue(uid("puzzlePath")) and true or false
            if on ~= wasOn then
                wasOn = on
                if not on then
                    clearFlowLines()
                    shown = false
                end
                notify(on and "ON" or "OFF", "[JB Hub] Show Puzzle Path", 3)
            end
            if not isFlowOpen() then
                seen = false
                if shown then
                    clearFlowLines()
                    shown = false
                end
                return
            end
            if not seen then
                seen = true
                local puzzle = readFlowPuzzle()
                if puzzle and (on or UI.GetValue(uid("puzzleSolve"))) then
                    task.spawn(function() solveFlowPuzzle(puzzle) end)
                end
            end
            if on and not shown then
                shown = true
                local puzzle = readFlowPuzzle()
                if puzzle then
                    clearFlowLines()
                    showFlowPath(puzzle)
                end
            end
        end)
        task.wait(FLOW_PATH_REFRESH)
    end
    clearFlowLines()
end)

task.spawn(function()
    local drawings = {}
    local targets = {}
    local wasOn = {}
    local scan = nil
    local lastSearch = 0
    local scale = 1
    local lastScaleAt = 0
    local frame = 0
    local bountyList, lastBounty = {}, 0

    local classes, classesAt = {}, tick()

    local function startScan()
        if tick() - classesAt > 60 then classes, classesAt = {}, tick() end
        local cash = PERF.ws("DroppedCash")
        return {
            lists = { workspace:GetChildren(), cash and cash:GetChildren() or {} },
            li = 1,
            i = 0,
            found = {},
        }
    end

    local function stepScan(budget)
        while budget > 0 do
            local list = scan.lists[scan.li]
            if not list then return true end
            scan.i = scan.i + 1
            local child = list[scan.i]
            if child == nil then
                scan.li = scan.li + 1
                scan.i = 0
            else
                budget = budget - 1
                local okK, key = pcall(function() return child.Address end)
                local c = nil
                if okK then c = classes[key] end
                if c and c.gone then
                    classes[key] = nil
                    c = nil
                end
                if c == nil then
                    local container = scan.li == 2 and "DroppedCash" or nil
                    local okN, name = pcall(function() return child.Name end)
                    local info = okN and ESP_TARGETS[name]
                    if not info or info.container ~= container then
                        c = false
                    else
                        local ok, t = pcall(readEspTarget, child, container, name)
                        if ok and t then c = t end
                    end
                    if okK and c ~= nil then classes[key] = c end
                end
                if c then scan.found[#scan.found + 1] = c end
            end
        end
        return false
    end

    local function readRootPos()
        local c = game:GetService("Players").LocalPlayer.Character
        local root = c and c:FindFirstChild("HumanoidRootPart")
        return root and root.Position
    end

    local function readScale()
        local h = workspace.CurrentCamera.ViewportSize.Y
        if h and h > 0 then return h / ESP_SCREEN_HEIGHT end
        return 1
    end
	
	local enabledCache, enabledAt = {}, 0

    while _G.JB_gen == myGen do
        local idle = true
        PERF.run("esp", function()
            local enabled = enabledCache
            local anyOn = false
            if tick() - enabledAt >= 0.15 then
                enabledAt = tick()
                enabled = {}
                for name, info in pairs(ESP_TARGETS) do
                    enabled[name] = UI.GetValue(uid(info.id)) and true or false
                    if enabled[name] ~= (wasOn[name] or false) then
                        wasOn[name] = enabled[name]
                        notify(enabled[name] and "ON" or "OFF", info.title, 3)
                    end
                end
                enabledCache = enabled
            end
            for _, v in pairs(enabled) do
                if v then anyOn = true break end
            end
            idle = not anyOn

            local now = tick()
            if not anyOn then
                targets = {}
                bountyList = {}
                scan = nil
            else
                if enabled.Bounty then
                    if now - lastBounty >= PERF.BOUNTY_EVERY then PERF.run("espBounty", function()
                        lastBounty = now
                        local list = {}
                        local ok, good = pcall(readBountyTargets, list)
                        if ok and good then
                            bountyList = list
                            PERF.bountyGoodAt = now
                        elseif now - (PERF.bountyGoodAt or 0) > 30 then
                            bountyList = {}
                        end
                    end) end
                else
                    bountyList = {}
                    lastBounty = 0
                end
                local needScan = false
                for name, v in pairs(enabled) do
                    if v and name ~= "Bounty" then needScan = true break end
                end
                if not needScan then
                    targets, scan = {}, nil
                elseif not scan and now - lastSearch >= ESP_SEARCH_EVERY then
                    lastSearch = now
                    local ok, s = pcall(startScan)
                    if ok then scan = s end
                end
                if scan then PERF.run("espScan", function()
                    local ok, done = pcall(stepScan, PERF.ESP_SCAN_CHUNK)
                    if not ok then
                        scan = nil
                    elseif done then
                        targets = scan.found
                        scan = nil
                    end
                end) end
                if now - lastScaleAt >= 1 then
                    lastScaleAt = now
                    local ok, s = pcall(readScale)
                    if ok and s then scale = s end
                end
            end

            local okRoot, rootPos = pcall(readRootPos)
            if not okRoot then rootPos = nil end
            frame = frame + 1

            PERF.run("espDraw", function()
            for _, group in ipairs({ targets, bountyList }) do
                for _, t in ipairs(group) do
                    if enabled[t.name] then
                        local isBounty = t.kind == "bounty"
                        local d = drawings[t.id]
                        if not d then
                            d = isBounty and newBountyDrawing(t.color) or newEspDrawing(t.info)
                            drawings[t.id] = d
                        end
                        d.frame = frame
                        local ok, show = pcall(isBounty and drawBountyTarget or drawEspTarget, t, d, rootPos, scale, now)
                        setEspVisible(d, ok and show == true)
                    end
                end
            end
            end)

            for id, d in pairs(drawings) do
                if d.frame ~= frame then
                    removeEspDrawing(d)
                    drawings[id] = nil
                end
            end
        end)
        task.wait(idle and 0.25 or (#targets == 0 and #bountyList == 0 and 0.1 or 0))
    end
    for _, d in pairs(drawings) do
        removeEspDrawing(d)
    end
end)

task.spawn(function()
    local TITLE = "[JB Hub] Kill All NPCs"
    local wasOn, lastArmed = false, false
    local hums, tried, counted = {}, {}, {}
    local pending, lastNotify, lastClear = 0, 0, 0

    local function getHum(m, key)
        local h = hums[key]
        if h then
            local ok, same = pcall(function() return tonumber(h.Parent.Address) == tonumber(m.Address) end)
            if ok and same then return h end
        end
        h = m:FindFirstChildOfClass("Humanoid") or false
        hums[key] = h
        return h or nil
    end

    while _G.JB_gen == myGen do
        local active = false
        PERF.run("KillNpcs", function()
            local armed = UI.GetValue(uid("killNpcs")) and true or false
            if armed ~= lastArmed then
                lastArmed = armed
                notify(armed and "Enabled" or "Disabled", TITLE, 3)
            end
            local on = armed and keybindActive(PERF.killKeybind)
            if on ~= wasOn then
                wasOn = on
                hums, tried, counted, pending = {}, {}, {}, 0
                notify(on and "Kill ON" or "Kill OFF", TITLE, 2)
            end
            if not on or PERF.solving then return end
            active = true
            local now = tick()
            if now - lastClear >= 30 then
                lastClear = now
                hums = {}
            end
            local myPos, range = getNpcRange()
            for _, folder in ipairs(PERF.npcFolders) do
                local okC, children = pcall(function() return folder:GetChildren() end)
                if okC then
                    for _, m in ipairs(children) do
                        pcall(function()
                            local key = m.Address
                            local hum = getHum(m, key)
                            if not hum or not npcInRange(m, myPos, range) then return end
                            local hp = hum.Health
                            if hp > 0 then
                                tried[key] = true
                                pcall(function() hum.Health = 0 end)
                                local addr = tonumber(hum.Address)
                                if addr and addr > 4096 then pcall(memory_write, "float", addr + HUM_HEALTH, 0) end
                            elseif tried[key] and not counted[key] then
                                counted[key] = true
                                pending = pending + 1
                            end
                        end)
                    end
                end
            end
            if pending > 0 and now - lastNotify >= 1 then
                lastNotify = now
                notify(pending .. " NPCs killed", TITLE, 2)
                pending = 0
            end
        end)
        task.wait(active and PERF.NPC_TICK or 0.25)
    end
end)

task.spawn(function()
    local TITLE = "[JB Hub] Make Guards Disabled"
    local wasOn = false
    local originals = {}
    local myId = game:GetService("Players").LocalPlayer.UserId
    local ownerSeen = {}

    local function playerName(id)
        for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
            if p.UserId == id then
                local okD, dn = pcall(function() return p.DisplayName end)
                if okD and dn and dn ~= "" then return dn end
                local okN, n = pcall(function() return p.Name end)
                if okN and n and n ~= "" then return n end
            end
        end
        return tostring(id)
    end

    local function attr(g, name)
        local ok, v = pcall(function() return g:GetAttribute(name) end)
        return ok and v or nil
    end

    local function alive(g)
        local ok, hp = pcall(function()
            local hum = g:FindFirstChildOfClass("Humanoid")
            return hum and hum.Health
        end)
        return ok and hp ~= nil and hp > 0
    end

    local function restoreAll()
        for _, o in pairs(originals) do
            pcall(function()
                if o.dist ~= nil and o.guard:GetAttribute("MaxShootDist") == 0 then
                    o.guard:SetAttribute("MaxShootDist", o.dist)
                end
                if o.freq ~= nil and o.guard:GetAttribute("GuardTriggerPressFreq") == 0 then
                    o.guard:SetAttribute("GuardTriggerPressFreq", o.freq)
                end
            end)
        end
        originals = {}
    end

    local function enforce(o)
        local g = o.guard
        local dist = attr(g, "MaxShootDist")
        if dist ~= 0 then
            if dist ~= nil then o.dist = dist end
            g:SetAttribute("MaxShootDist", 0)
        end
        local freq = attr(g, "GuardTriggerPressFreq")
        if freq ~= 0 then
            if freq ~= nil then o.freq = freq end
            g:SetAttribute("GuardTriggerPressFreq", 0)
        end
        if attr(g, "NPCDestType") ~= 3 then
            local home = attr(g, "NPCHomePosition")
            if not home then
                if not o.stay then
                    pcall(function() o.stay = g:FindFirstChild("HumanoidRootPart").Position end)
                end
                home = o.stay
            end
            if home then pcall(function() g:SetAttribute("NPCDestPos", home) end) end
            g:SetAttribute("NPCDestType", 3)
        end
    end

    while _G.JB_gen == myGen do
        local active = false
        PERF.run("GuardsDisabled", function()
            local on = UI.GetValue(uid("guards")) and true or false
            if on ~= wasOn then
                wasOn = on
                ownerSeen = {}
                if not on then restoreAll() end
                notify(on and "ON" or "OFF", TITLE, 3)
            end
            if not on or PERF.solving then return end
            active = true
            local folders = {}
            for _, f in ipairs(PERF.npcFolders) do folders[#folders + 1] = f end
            local mansion = PERF.ws("MansionRobbery")
            local mg = mansion and mansion:FindFirstChild("GuardsFolder")
            if mg then
                local has = false
                for _, f in ipairs(folders) do
                    if f == mg then has = true break end
                end
                if not has then folders[#folders + 1] = mg end
            end
            local fresh, seen, owners = 0, {}, {}
            for _, g in ipairs(getGuards(folders)) do
                local ok, key = pcall(function() return g.Address end)
                if ok and not PERF.ceoGuards[key] and alive(g) then
                    seen[key] = true
                    local owner = tonumber(attr(g, "NPCNetworkOwnerId"))
                    if owner and owner > 0 and owner ~= myId then owners[owner] = (owners[owner] or 0) + 1 end
                    local o = originals[key]
                    if not o then
                        o = { guard = g }
                        originals[key] = o
                        fresh = fresh + 1
                    end
                    pcall(enforce, o)
                end
            end
            for key in pairs(originals) do
                if not seen[key] then originals[key] = nil end
            end
            if fresh > 0 then
                notify(fresh .. " guards disabled", TITLE, 2)
            end
            local now = tick()
            for owner, count in pairs(owners) do
                if not ownerSeen[owner] or now - ownerSeen[owner] >= 60 then
                    ownerSeen[owner] = now
                    notify(playerName(owner) .. " controls " .. count .. " guards, they can't be disabled", TITLE, 4)
                end
            end
        end)
        task.wait(active and PERF.NPC_TICK or 0.3)
    end
    restoreAll()
end)

task.spawn(function()
    local H = PERF.HB
    local holder = game:GetService("ReplicatedStorage")
    local tracked, dead, queue = {}, {}, {}
    local wasOn, lastSize, sizeAt, mansion, mansionAt = false, nil, nil, nil, 0

    local function rf(a)
        local ok, v = pcall(memory_read, "float", a)
        return ok and v or nil
    end

    local function rb(a)
        local ok, v = pcall(memory_read, "byte", a)
        return ok and v or nil
    end

    local function wanted()
        return Vector3.new(tonumber(UI.GetValue(uid("hbX"))) or 10, tonumber(UI.GetValue(uid("hbY"))) or 8, tonumber(UI.GetValue(uid("hbZ"))) or 10)
    end

    local function paint(o, alpha, r, g, b)
        local okV, live = pcall(function()
            return o.mAddr ~= nil and o.model.Parent ~= nil and tonumber(o.root.Parent.Address) == o.mAddr and tonumber(o.root.Address) == o.base
        end)
        if not okV or not live then return end
        pcall(memory_write, "float", o.base + H.TR_OFF, alpha)
        pcall(memory_write, "byte", o.base + PERF.PART_COLOR, r)
        pcall(memory_write, "byte", o.base + PERF.PART_COLOR + 1, g)
        pcall(memory_write, "byte", o.base + PERF.PART_COLOR + 2, b)
    end

    local function shape(o, size)
        pcall(function() o.root.Size = size end)
        pcall(function() o.root.CanCollide = false end)
    end

    local function capture(m, root)
        local base = tonumber(root.Address)
        if not base or base <= 4096 then return nil end
        local okS, size = pcall(function() return root.Size end)
        local okC, cc = pcall(function() return root.CanCollide end)
        local okM, mAddr = pcall(function() return tonumber(m.Address) end)
        return {
            model = m, root = root, base = base, mAddr = okM and mAddr or nil,
            hum = m:FindFirstChildOfClass("Humanoid") or m:FindFirstChild("Humanoid"),
            size = okS and size or Vector3.new(2, 2, 1),
            cc = (okC and cc ~= nil) and cc or true,
            tr = rf(base + H.TR_OFF) or 1,
            col = { rb(base + PERF.PART_COLOR) or 0, rb(base + PERF.PART_COLOR + 1) or 0, rb(base + PERF.PART_COLOR + 2) or 0 },
            checkAt = 0, born = tick(), refreshCount = 0, refreshFrom = 0,
        }
    end

    local function apply(o, size)
        paint(o, H.ALPHA, H.COLOR[1], H.COLOR[2], H.COLOR[3])
        shape(o, size)
        o.checkAt = tick() + H.YOUNG_VERIFY
    end

    local function restore(o)
        pcall(function() o.root.Size = o.size end)
        pcall(function() o.root.CanCollide = o.cc end)
        paint(o, o.tr, o.col[1], o.col[2], o.col[3])
    end

    local function canRefresh(o)
        local now = tick()
        if now - o.refreshFrom > H.REFRESH_WINDOW then o.refreshFrom, o.refreshCount = now, 0 end
        if o.refreshCount >= H.REFRESH_CAP then return false end
        o.refreshCount = o.refreshCount + 1
        return true
    end

    local function refreshBatch(list)
        local moved = {}
        for _, o in ipairs(list) do
            local okP, p = pcall(function() return o.model.Parent end)
            if okP and p and p ~= holder and pcall(function() o.model.Parent = holder end) then
                moved[#moved + 1] = { o = o, p = p }
            end
        end
        if #moved == 0 then return end
        task.wait()
        for _, e in ipairs(moved) do
            if not pcall(function() e.o.model.Parent = e.p end) then
                task.wait()
                pcall(function() e.o.model.Parent = e.p end)
            end
        end
    end

    local function restoreAll()
        local all = {}
        for _, o in pairs(tracked) do
            restore(o)
            all[#all + 1] = o
        end
        tracked, queue = {}, {}
        for i = 1, #all, H.REFRESH_PER_TICK do
            local part = {}
            for j = i, math.min(i + H.REFRESH_PER_TICK - 1, #all) do part[#part + 1] = all[j] end
            refreshBatch(part)
        end
    end

    local function getMansion(now)
        if mansion and pcall(function() return mansion.Parent.Name end) then return mansion end
        if now - mansionAt >= H.MANSION_EVERY then
            mansionAt = now
            mansion = PERF.ws("MansionRobbery")
        end
        return mansion
    end

    while _G.JB_gen == myGen do
        local active, batch = false, {}
        PERF.run("hitbox", function()
            local on = UI.GetValue(uid("npcHitbox")) and true or false
            local size = wanted()
            local sizeKey = tostring(size)
            if on ~= wasOn then
                wasOn = on
                if on then
                    dead, lastSize, sizeAt = {}, sizeKey, nil
                    notify(string.format("ON - %dx%dx%d", math.floor(size.X), math.floor(size.Y), math.floor(size.Z)), H.TITLE, 3)
                else
                    restoreAll()
                    notify("OFF - hitboxes restored", H.TITLE, 3)
                end
            end
            if not on or PERF.solving then return end
            active = true
            local now = tick()
            if now - (H.deadAt or 0) >= 60 then H.deadAt, dead = now, {} end
 
            local sources = {}
            for _, f in ipairs(PERF.npcFolders) do sources[#sources + 1] = f end
            local m0 = getMansion(now)
            if m0 then sources[#sources + 1] = m0 end

            for _, f in ipairs(sources) do
                local okC, kids = pcall(function() return f:GetChildren() end)
                for _, m in ipairs(okC and kids or {}) do
                    local okK, k = pcall(function() return tostring(m.Address) end)
                    if okK and k and not tracked[k] and not dead[k] then
                        local isBoss = m.Name == "ActiveBoss"
                        local okG, guard = pcall(function() return m:GetAttribute("GuardTriggerPressFreq") ~= nil end)
                        local root = (isBoss or (okG and guard)) and m:FindFirstChild("HumanoidRootPart")
                        if root then
                            local o = capture(m, root)
                            if o then
                                tracked[k] = o
                                apply(o, size)
                                o.refreshAt = now + H.REFRESH_DELAY
                            end
                        elseif not isBoss and okG and not guard then
                            dead[k] = true
                        end
                    end
                end
            end

            if sizeKey ~= lastSize then
                lastSize, sizeAt = sizeKey, now + H.SLIDER_DELAY
                for _, o in pairs(tracked) do shape(o, size) end
            end
            if sizeAt and now >= sizeAt then
                sizeAt = nil
                for k in pairs(tracked) do queue[k] = true end
            end

            for k, o in pairs(tracked) do
                if o.refreshAt and now >= o.refreshAt then
                    o.refreshAt = nil
                    queue[k] = true
                end
                if now >= o.checkAt then
                    o.checkAt = now + ((now - o.born < H.YOUNG) and H.YOUNG_VERIFY or H.VERIFY)
                    local okP = pcall(function() return o.model.Parent.Name end)
                    local okH, hp = pcall(function() return o.hum.Health end)
                    if not okP then
                        tracked[k] = nil
                    elseif okH and hp and hp <= 0 then
                        restore(o)
                        tracked[k], dead[k] = nil, true
                    else
                        local cur = o.model:FindFirstChild("HumanoidRootPart")
                        local okA, addr = pcall(function() return tonumber(cur.Address) end)
                        if okA and addr and addr ~= o.base then
                            local n = capture(o.model, cur)
                            if n then
                                tracked[k] = n
                                apply(n, size)
                                queue[k] = true
                            end
                        else
                            local okS, s = pcall(function() return o.root.Size end)
                            local tr = rf(o.base + H.TR_OFF)
                            if not okS or not s or math.abs(s.X - size.X) > 0.01 or math.abs(s.Y - size.Y) > 0.01 or math.abs(s.Z - size.Z) > 0.01 then
                                shape(o, size)
                                if not o.refreshAt and canRefresh(o) then queue[k] = true end
                            end
                            if tr and math.abs(tr - H.ALPHA) > 0.001 then
                                paint(o, H.ALPHA, H.COLOR[1], H.COLOR[2], H.COLOR[3])
                                queue[k] = true
                            end
                        end
                    end
                end
            end

            for k in pairs(queue) do
                queue[k] = nil
                if tracked[k] then batch[#batch + 1] = tracked[k] end
                if #batch >= H.REFRESH_PER_TICK then break end
            end
        end)
        if #batch > 0 then refreshBatch(batch) end
        task.wait(active and H.TICK or 0.3)
    end
    restoreAll()
end)

-- cmds
task.spawn(function()
    local lp = game:GetService("Players").LocalPlayer
    local prefix = tostring(lp.UserId) .. "-"
    local scroll, scrollAt, primed, pending = nil, 0, false, nil
    local seen, seenCount = {}, 0

    local function findScroll()
        local ok, s = pcall(function()
            return game:GetService("CoreGui").ExperienceChat.appLayout.chatWindow.contentFrame.scrollingView.bottomLockedScrollView.scrollView
        end)
        return ok and s or nil
    end

    local function tap(vk)
        keypress(vk)
        task.wait(0.15)
        keyrelease(vk)
    end

    local function exitGame()
        if not isrbxactive() then
            notify("Focus the Roblox window, then try again", "[JB Hub]", 3)
            return
        end
        notify("Leaving the game...", "[JB Hub]", 2)
        PERF.ONLINE.leave()
        task.wait(0.5)
        tap(0x1B)
        task.wait(1)
        tap(0x4C)
        task.wait(1)
        tap(0x0D)
    end

    local function mark(n)
        if seenCount > 500 then seen, seenCount = {}, 0 end
        seen[n], seenCount = true, seenCount + 1
    end

    while _G.JB_gen == myGen do
        PERF.run("chatCmd", function()
            local now = tick()
            if scroll and not pcall(function() return scroll.Parent.Name end) then scroll = nil end
            if not scroll then
                if now - scrollAt < 5 then return end
                scrollAt, primed = now, false
                scroll = findScroll()
                if not scroll then return end
            end
            local okC, kids = pcall(function() return scroll:GetChildren() end)
            if not okC then return end
            if not primed then
                for _, c in ipairs(kids) do
                    local okN, n = pcall(function() return c.Name end)
                    if okN then mark(n) end
                end
                primed = true
                return
            end
            for i = math.max(1, #kids - 3), #kids do
                local c = kids[i]
                local okN, n = pcall(function() return c.Name end)
                if okN and n and not seen[n] then
                    mark(n)
                    if string.sub(n, 1, #prefix) == prefix then
                        local okT, body = pcall(function() return c.TextMessage.BodyText.Text end)
                        local cmd = okT and type(body) == "string" and string.match(body, ":%s*(;%S+)%s*$")
                        cmd = cmd and string.lower(cmd)
                        if cmd == ";exit" then
                            pending = "exit"
                        elseif cmd == ";reset" then
                            pending = "reset"
                        end
                    end
                end
            end
        end)
        if pending == "exit" then
            pending = nil
            exitGame()
        elseif pending == "reset" then
            pending = nil
            forceReset()
        end
        task.wait(0.3)
    end
end)

task.spawn(function()
    local wasOn, keyDown = false, false
    while _G.JB_gen == myGen do
        PERF.run("resetBind", function()
            local on = UI.GetValue(uid("resetBind")) and true or false
            if on ~= wasOn then
                wasOn = on
                notify(on and "ON" or "OFF", "[JB Hub] Force Reset Bind", 3)
            end
            local down = on and PERF.keyDown("reset", PERF.RESET_KEY) or false
            local trigger = (down and not keyDown) or (on and PERF.resetRequested)
            keyDown = down
            PERF.resetRequested = false
            if trigger and not resetting then forceReset() end
        end)
        task.wait(0.05)
    end
end)

task.spawn(function()
    local TITLE = "[JB Hub] Make Guards Attack CEO"
    local RANGE, SCAN_EVERY, OWNER_EVERY, BOSS_EVERY, WARN_EVERY = 300, 0.5, 0.25, 0.5, 15
    local boss, entries = {}, {}
    local wasOn, bossDown, myId = false, false, nil
    local lastBoss, lastScan, lastWarn = 0, 0, 0

    local function attr(g, name)
        local ok, v = pcall(function() return g:GetAttribute(name) end)
        return ok and v or nil
    end

    local function setAttr(g, name, v)
        if attr(g, name) ~= v then pcall(function() g:SetAttribute(name, v) end) end
    end

    local function refreshBoss()
        local mansion = PERF.ws("MansionRobbery")
        local model = mansion and mansion:FindFirstChild("ActiveBoss")
        boss.folder = mansion and mansion:FindFirstChild("GuardsFolder")
        boss.root = model and model:FindFirstChild("HumanoidRootPart")
        boss.hum = model and model:FindFirstChildOfClass("Humanoid")
        local ok, a = pcall(function() return boss.root.Address end)
        boss.addr = ok and a or nil
    end

    local function bossHealth()
        if not boss.hum then return nil end
        local ok, hp = pcall(function() return boss.hum.Health end)
        return ok and type(hp) == "number" and hp or nil
    end

    local function save(e)
        local g = e.guard
        e.dv = e.dv or g:FindFirstChild("NPCDestObj")
        local okV, dest = pcall(function() return e.dv.Value end)
        e.saved = {
            involved = attr(g, "TargetingInvolvedPlayer"),
            maxShoot = attr(g, "MaxShootDist"),
            freq = attr(g, "GuardTriggerPressFreq"),
            destType = attr(g, "NPCDestType"),
            dest = okV and dest or nil,
        }
        PERF.ceoGuards[e.key] = true
    end

    local function apply(e)
        local g = e.guard
        setAttr(g, "TargetingInvolvedPlayer", true)
        if (tonumber(attr(g, "MaxShootDist")) or 0) < 1000 then setAttr(g, "MaxShootDist", 1000) end
        if (tonumber(attr(g, "GuardTriggerPressFreq")) or 0) <= 0 then setAttr(g, "GuardTriggerPressFreq", 2) end
        e.dv = e.dv or g:FindFirstChild("NPCDestObj")
        if e.dv then
            local ok, a = pcall(function() return e.dv.Value.Address end)
            if not ok or a ~= boss.addr then pcall(function() e.dv.Value = boss.root end) end
        end
        setAttr(g, "NPCDestType", 2)
    end

    local function restore(e)
        local s = e.saved
        PERF.ceoGuards[e.key] = nil
        if not s then return end
        local g = e.guard
        pcall(function() g:SetAttribute("TargetingInvolvedPlayer", s.involved) end)
        pcall(function() g:SetAttribute("MaxShootDist", s.maxShoot) end)
        pcall(function() g:SetAttribute("GuardTriggerPressFreq", s.freq) end)
        pcall(function() g:SetAttribute("NPCDestType", s.destType) end)
        if e.dv then pcall(function() e.dv.Value = s.dest end) end
        e.saved = nil
    end

    local function restoreAll()
        for _, e in pairs(entries) do pcall(restore, e) end
        entries = {}
        PERF.ceoGuards = {}
    end

    local function scanGuards(now)
        lastScan = now
        for key, e in pairs(entries) do
            local ok, p = pcall(function() return e.guard.Parent end)
            if not ok or not p then
                PERF.ceoGuards[key] = nil
                entries[key] = nil
            end
        end
        if not boss.folder or not boss.root then return end
        local okB, bossPos = pcall(function() return boss.root.Position end)
        if not okB then return end
        for _, g in ipairs(boss.folder:GetChildren()) do
            if attr(g, "GuardTriggerPressFreq") ~= nil then
                local okK, key = pcall(function() return g.Address end)
                if okK and not entries[key] then
                    local okD, d = pcall(function() return (g:FindFirstChild("HumanoidRootPart").Position - bossPos).Magnitude end)
                    if not okD or d <= RANGE then
                        entries[key] = { guard = g, key = key, owned = false, nextOwner = 0 }
                    end
                end
            end
        end
    end

    while _G.JB_gen == myGen do
        local active = false
        PERF.run("AttackCeo", function()
            local on = UI.GetValue(uid("attackCeo")) and true or false
            if on ~= wasOn then
                wasOn = on
                if not on then restoreAll() end
                bossDown, lastBoss, lastScan = false, 0, 0
                notify(on and "ON" or "OFF", TITLE, 3)
            end
            if not on or PERF.solving then return end
            myId = myId or tonumber(game:GetService("Players").LocalPlayer.UserId)
            local now = tick()

            if now - lastBoss >= BOSS_EVERY or not boss.root or boss.root.Parent == nil then
                lastBoss = now
                local old = boss.addr
                refreshBoss()
                if boss.addr ~= old then
                    restoreAll()
                    bossDown, lastScan = false, 0
                end
            end
            if not boss.root then
                if next(entries) then restoreAll() end
                bossDown = false
                return
            end

            local hp = bossHealth()
            if not hp then return end
            if hp <= 0 then
                if not bossDown then
                    bossDown = true
                    restoreAll()
                    notify("CEO defeated", TITLE, 4)
                end
                return
            end
            bossDown = false
            active = true

            if now - lastScan >= SCAN_EVERY then scanGuards(now) end

            local fresh, owned, total = 0, 0, 0
            for _, e in pairs(entries) do
                total = total + 1
                if now >= e.nextOwner then
                    e.nextOwner = now + OWNER_EVERY
                    local mine = tonumber(attr(e.guard, "NPCNetworkOwnerId")) == myId
                    if mine and not e.owned then
                        if not e.saved then pcall(save, e) end
                        fresh = fresh + 1
                    elseif not mine and e.owned then
                        pcall(restore, e)
                    end
                    e.owned = mine
                end
                if e.owned then
                    owned = owned + 1
                    pcall(apply, e)
                end
            end

            if fresh > 0 then
                notify(fresh .. " guards attacking CEO (" .. owned .. "/" .. total .. " controlled)", TITLE, 2)
            elseif total > 0 and owned == 0 and now - lastWarn >= WARN_EVERY then
                lastWarn = now
                notify(total .. " guards near CEO, all controlled by other players", TITLE, 3)
            end
        end)
        task.wait(active and PERF.NPC_TICK or 0.3)
    end
    restoreAll()
end)

task.spawn(function()
    local G = PERF.GUARD
    local TITLE = "[JB Hub] Guard Control"
    local lp = game:GetService("Players").LocalPlayer
    local myId = tonumber(lp.UserId)
    local entries = {}
    local lastMode, lastScan, lastBlock, lastOwned = "Off", 0, 0, 0

    local function setAttr(g, k, v)
        local ok, cur = pcall(function() return g:GetAttribute(k) end)
        if not ok or cur ~= v then pcall(function() g:SetAttribute(k, v) end) end
    end

    local function addrOf(inst)
        local ok, a = pcall(function() return inst.Address end)
        return ok and a or nil
    end

    local function save(e)
        local g = e.model
        local okV, dest = pcall(function() return e.dv.Value end)
        e.saved = {
            involved = g:GetAttribute("TargetingInvolvedPlayer"),
            maxShoot = g:GetAttribute("MaxShootDist"),
            freq = g:GetAttribute("GuardTriggerPressFreq"),
            destType = g:GetAttribute("NPCDestType"),
            dest = okV and dest or nil,
        }
    end

    local function restore(e)
        local s, g = e.saved, e.model
        if not s then return end
        pcall(function() g:SetAttribute("TargetingInvolvedPlayer", s.involved) end)
        pcall(function() g:SetAttribute("MaxShootDist", s.maxShoot) end)
        pcall(function() g:SetAttribute("GuardTriggerPressFreq", s.freq) end)
        pcall(function() g:SetAttribute("NPCDestType", s.destType) end)
        if e.dv then pcall(function() e.dv.Value = s.dest end) end
        e.saved, e.destAddr = nil, nil
    end

    local function restoreAll()
        for _, e in pairs(entries) do
            if e.mine then pcall(restore, e) end
        end
        entries = {}
        lastOwned = 0
    end

    local function setDest(e, part)
        local a = addrOf(part)
        if e.dv and (e.destAddr ~= a or addrOf(e.dv.Value) ~= a) then
            pcall(function() e.dv.Value = part end)
            e.destAddr = a
        end
        setAttr(e.model, "NPCDestType", 2)
    end

    local function attack(e, part)
        local g = e.model
        setAttr(g, "TargetingInvolvedPlayer", true)
        setAttr(g, "MaxShootDist", tonumber(UI.GetValue(uid("guardShootDist"))) or 400)
        setAttr(g, "GuardTriggerPressFreq", tonumber(UI.GetValue(uid("guardFreq"))) or 3)
        setDest(e, part)
    end

    local function follow(e, part)
        local g = e.model
        setAttr(g, "TargetingInvolvedPlayer", false)
        setAttr(g, "MaxShootDist", 0)
        setAttr(g, "GuardTriggerPressFreq", 0)
        setDest(e, part)
    end

    local function hold(e)
        local g = e.model
        setAttr(g, "MaxShootDist", 0)
        setAttr(g, "GuardTriggerPressFreq", 0)
        setAttr(g, "NPCDestType", 3)
        e.destAddr = nil
    end

    local function scan()
        local seen = {}
        for _, folder in ipairs(PERF.npcFolders) do
            local okC, children = pcall(function() return folder:GetChildren() end)
            if okC then
                for _, m in ipairs(children) do
                    pcall(function()
                        local key = m.Address
                        local e = entries[key]
                        if not e then
                            local hum = m:FindFirstChildOfClass("Humanoid")
                            local hrp = m:FindFirstChild("HumanoidRootPart")
                            if not hum or not hrp then return end
                            e = { model = m, hum = hum, hrp = hrp, dv = m:FindFirstChild("NPCDestObj") }
                            entries[key] = e
                        end
                        if not e.dv then e.dv = m:FindFirstChild("NPCDestObj") end
                        if e.hum.Health <= 0 then return end
                        local mine = tonumber(m:GetAttribute("NPCNetworkOwnerId")) == myId
                        if mine and not e.saved then save(e) end
                        if not mine then e.saved, e.destAddr = nil, nil end
                        e.mine = mine
                        seen[key] = true
                    end)
                end
            end
        end
        for key in pairs(entries) do
            if not seen[key] then entries[key] = nil end
        end
    end

    local function getThreats(myRoot)
        local list = {}
        local team = G.TEAMS[(tonumber(UI.GetValue(uid("guardTeam"))) or 0) + 1] or "All"
        if team == "None" then return list end
        local radius = tonumber(UI.GetValue(uid("guardProtect"))) or 80
        for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
            if p ~= lp then
                pcall(function()
                    local char = p.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hum or not hrp or hum.Health <= 0 then return end
                    local okT, name = pcall(function() return p.Team and p.Team.Name or "" end)
                    if team ~= "All" and not (okT and name == team) then return end
                    if (hrp.Position - myRoot.Position).Magnitude <= radius then
                        list[#list + 1] = { hrp = hrp, addr = addrOf(hrp), assigned = 0 }
                    end
                end)
            end
        end
        return list
    end

    while _G.JB_gen == myGen do
        local active = false
        PERF.run("GuardControl", function()
            local mode = G.MODES[(tonumber(UI.GetValue(uid("guardMode"))) or 0) + 1] or "Off"
            if mode ~= lastMode then
                if mode == "Off" then restoreAll() end
                notify(mode == "Off" and "OFF" or (mode .. " ON"), TITLE, 3)
                lastMode = mode
            end
            if mode == "Off" or PERF.solving then return end
            if UI.GetValue(uid("guards")) or UI.GetValue(uid("attackCeo")) then
                if next(entries) then restoreAll() end
                if tick() - lastBlock >= 10 then
                    lastBlock = tick()
                    notify("Disable Make Guards Disabled and Make Guards Attack CEO first", TITLE, 4)
                end
                return
            end
            active = true
            local now = tick()
            if now - lastScan >= 0.5 then
                lastScan = now
                scan()
                local owned = 0
                for _, e in pairs(entries) do
                    if e.mine then owned = owned + 1 end
                end
                if owned > lastOwned then notify(owned .. " guards under your control", TITLE, 2) end
                lastOwned = owned
            end
            local char = lp.Character
            local myRoot = char and char:FindFirstChild("HumanoidRootPart")
            if not myRoot then return end
            local threats = getThreats(myRoot)
            local spread = UI.GetValue(uid("guardSpread"))
            local followOn = UI.GetValue(uid("guardFollow"))
            for _, e in pairs(entries) do
                if e.mine then
                    local pick, best = nil, math.huge
                    for _, t in ipairs(threats) do
                        local okD, d = pcall(function() return (t.hrp.Position - e.hrp.Position).Magnitude end)
                        if okD then
                            local score = spread and d + t.assigned * 100000 or d
                            if t.addr and t.addr == e.targetAddr then score = score - 30 end
                            if score < best then pick, best = t, score end
                        end
                    end
                    if pick then
                        pick.assigned = pick.assigned + 1
                        e.targetAddr = pick.addr
                        attack(e, pick.hrp)
                    elseif followOn then
                        follow(e, myRoot)
                    else
                        hold(e)
                    end
                end
            end
        end)
        task.wait(active and 0.2 or 0.3)
    end
    restoreAll()
end)

task.spawn(function()
    local wasOn, keyDown, busy = false, false, false
    while _G.JB_gen == myGen do
        PERF.run("autoVault", function()
            local on = UI.GetValue(uid("autoVault")) and true or false
            if on ~= wasOn then
                wasOn = on
                notify(on and "ON" or "OFF", VAULT.TITLE, 3)
            end
            local down = false
            down = PERF.keyDown("vault", VAULT_KEY)
            local trigger = (down and not keyDown) or vaultRequested
            keyDown = down
            vaultRequested = false
            if trigger and on and not busy then
                busy = true
                local target = findNearestVault()
                if not target then
                    notify("No vault nearby", VAULT.TITLE, 3)
                elseif not (target.light and target.request and target.update) then
                    notify("Vault not ready", VAULT.TITLE, 3)
                else
                    local ok, err = pcall(crackVault, target)
                    if not ok then
                        notify("Error: " .. tostring(err), VAULT.TITLE, 3)
                    end
                end
                vaultRequested = false
                busy = false
            end
        end)
        task.wait(0.03)
    end
end)

task.spawn(function()
    local wasOn = false
    local cache = {}
    local lastScan = 0
    local lastFire = {}
    local cutShown = {}
    local foundShown = false

    local function rescan(casino)
        local fresh = {}
        for _, glass in ipairs(casino:GetChildren()) do
            if glass.Name == "Glass" then
                local key = glass.Address
                local entry = cache[key]
                if not entry then
                    local remote = glass:FindFirstChild("CutRemote")
                    local pos = remote and vaultReadPos(glass)
                    if pos then entry = { glass = glass, remote = remote, pos = pos } end
                end
                if entry then fresh[key] = entry end
            end
        end
        cache = fresh
    end

    while _G.JB_gen == myGen do
        local waitTime = GLASS.IDLE
        PERF.run("autoGlass", function()
            local on = UI.GetValue(uid("autoGlass")) and true or false
            if on ~= wasOn then
                wasOn = on
                cache = {}
                lastFire = {}
                cutShown = {}
                foundShown = false
                lastScan = 0
                notify(on and "ON" or "OFF", GLASS.TITLE, 3)
            end
            if not on then return end

            local now = tick()
            if now - lastScan >= GLASS.RESCAN then
                lastScan = now
                local casino = PERF.ws("Casino")
                if casino then rescan(casino) else cache = {} end
                if not foundShown then
                    local n = 0
                    for _ in pairs(cache) do n = n + 1 end
                    if n > 0 then
                        foundShown = true
                        notify(n .. " glass found", GLASS.TITLE, 3)
                    end
                end
            end
            if next(cache) == nil then return end

            local char = game:GetService("Players").LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local me = hrp and vaultReadPos(hrp)
            if not me then return end
            waitTime = GLASS.TICK

            for key, entry in pairs(cache) do
                local inRange = (entry.pos - me).Magnitude <= GLASS.RANGE
                if inRange or (lastFire[key] and not cutShown[key]) then
                    local isCut
                    pcall(function() isCut = entry.glass:GetAttribute("IsCut") end)
                    if isCut == true then
                        if lastFire[key] and not cutShown[key] then
                            cutShown[key] = true
                            notify("Glass cut", GLASS.TITLE, 2)
                        end
                    else
                        cutShown[key] = nil
                        if inRange and now - (lastFire[key] or 0) >= GLASS.PER_GAP then
                            lastFire[key] = now
                            pcall(function() entry.remote:FireServer() end)
                        end
                    end
                end
            end
        end)
        task.wait(waitTime)
    end
end)

task.spawn(function()
    local wasOn = false
    local cache = {}
    local lastScan = 0
    local lastFire = {}
    local bag, bagScanAt = nil, 0
    local fullShown = false

    local function lootPos(loot)
        if loot:IsA("BasePart") then return vaultReadPos(loot) end
        for _, d in ipairs(loot:GetDescendants()) do
            if d:IsA("BasePart") then
                local p = vaultReadPos(d)
                if p then return p end
            end
        end
        return nil
    end

    local function rescan(loots)
        local fresh = {}
        for _, loot in ipairs(loots:GetChildren()) do
            local key = loot.Address
            local entry = cache[key]
            if not entry then
                local remote = loot:FindFirstChild("CasinoLootCollect")
                local pos = remote and lootPos(loot)
                if pos then entry = { remote = remote, pos = pos } end
            end
            if entry then fresh[key] = entry end
        end
        cache = fresh
    end

    local function findBag()
        local lp = game:GetService("Players").LocalPlayer
        for _, c in ipairs(lp:GetChildren()) do
            if c.Name == "Value" and c:FindFirstChild("Amount") and c:FindFirstChild("Maximum") then
                return c
            end
        end
        return nil
    end

    local function readLabel()
        local gui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
        local node = gui
        for _, name in ipairs(LOOT.BAG_LABEL) do
            node = node and node:FindFirstChild(name)
        end
        if not node then return nil end
        local text = tostring(node.Text):gsub(",", "")
        local a, b = text:match("(%d+)%s*/%s*%$?(%d+)")
        return tonumber(a), tonumber(b)
    end

    local function bagFull(now)
        if not bag or bag.Parent == nil then
            bag = nil
            if now - bagScanAt >= LOOT.BAG_SCAN then
                bagScanAt = now
                bag = findBag()
            end
            if not bag then return false end
        end
        local amount, cap
        local okL, la, lb = pcall(readLabel)
        if okL then cap = lb end
        pcall(function()
            amount = tonumber(bag.Amount.Value)
            if not cap or cap <= 0 then
                local max = tonumber(bag.Maximum.Value) or 0
                local mult = 1
                local enabled = bag:FindFirstChild("MultEnabled")
                local m = bag:FindFirstChild("Mult")
                if enabled and enabled.Value == true and m then mult = tonumber(m.Value) or 1 end
                cap = max * mult
            end
        end)
        if okL and la and (not amount or la > amount) then amount = la end
        if not amount or not cap or cap <= 0 then return false end
        return amount >= cap
    end

    while _G.JB_gen == myGen do
        local waitTime = LOOT.IDLE
        PERF.run("autoLoot", function()
            local on = UI.GetValue(uid("autoLoot")) and true or false
            if on ~= wasOn then
                wasOn = on
                cache = {}
                lastFire = {}
                lastScan = 0
                bag, bagScanAt, fullShown = nil, 0, false
                notify(on and "ON" or "OFF", LOOT.TITLE, 3)
            end
            if not on then return end

            local now = tick()
            if now - lastScan >= LOOT.RESCAN then
                lastScan = now
                local casino = PERF.ws("Casino")
                local loots = casino and casino:FindFirstChild("Loots")
                if loots then rescan(loots) else cache = {} end
            end
            if next(cache) == nil then return end

            local char = game:GetService("Players").LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local me = hrp and vaultReadPos(hrp)
            if not me then return end
            waitTime = LOOT.TICK

            local targets = {}
            for key, entry in pairs(cache) do
                if (entry.pos - me).Magnitude <= LOOT.RANGE and now - (lastFire[key] or 0) >= LOOT.PER_GAP then
                    targets[#targets + 1] = key
                end
            end
            if #targets == 0 then return end

            if bagFull(now) then
                if not fullShown then
                    fullShown = true
                    notify("Bag full, collecting paused", LOOT.TITLE, 3)
                end
                return
            end
            if fullShown then
                fullShown = false
                notify("Collecting resumed", LOOT.TITLE, 2)
            end

            for _, key in ipairs(targets) do
                local entry = cache[key]
                lastFire[key] = now
                pcall(function() entry.remote:FireServer() end)
            end
        end)
        task.wait(waitTime)
    end
end)

task.spawn(function()
    local TITLE = "[JB Hub] Auto Computer Hack"
    local RANGE, GAP, TICK, IDLE = 15, 3, 0.2, 1
    local wasOn, lastFire, posCache, securityShown = false, {}, {}, false

    local function keyOf(pc, i)
        local ok, a = pcall(function() return tostring(pc.Address) end)
        return (ok and a) or tostring(i)
    end

    local function posOf(key, pc)
        if posCache[key] then return posCache[key] end
        local okP, prim = pcall(function() return pc.PrimaryPart end)
        local p = okP and prim and vaultReadPos(prim)
        if not p then
            for _, d in ipairs(pc:GetChildren()) do
                p = vaultReadPos(d)
                if p then break end
            end
        end
        posCache[key] = p
        return p
    end

    while _G.JB_gen == myGen do
        local waitTime = IDLE
        PERF.run("autoHack", function()
            local on = UI.GetValue(uid("autoHack")) and true or false
            if on ~= wasOn then
                wasOn = on
                lastFire, posCache, securityShown = {}, {}, false
                notify(on and "ON" or "OFF", TITLE, 3)
            end
            if not on then return end

            local casino = PERF.ws("Casino")
            local computers = casino and casino:FindFirstChild("Computers")
            if not computers then return end
            local char = game:GetService("Players").LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local me = hrp and vaultReadPos(hrp)
            if not me then return end

            local list = computers:GetChildren()
            local first = list[1] and posOf(keyOf(list[1], 1), list[1])
            if first and (first - me).Magnitude > 300 then return end

            local now, security, active = tick(), false, false
            for i, pc in ipairs(list) do
                if pc:GetAttribute("ComputerActive") == true then
                    if pc:GetAttribute("ShowDisableSecurityPrompt") == true then
                        security = true
                    else
                        active = true
                        local key = keyOf(pc, i)
                        local pos = posOf(key, pc)
                        local remote = pc:FindFirstChild("CasinoComputerHack")
                        if remote and pos and (pos - me).Magnitude <= RANGE and now - (lastFire[key] or 0) >= GAP then
                            lastFire[key] = now
                            pcall(function() remote:FireServer() end)
                        end
                    end
                end
            end
            if active then waitTime = TICK end

            if security and not securityShown then
                securityShown = true
                notify("Security computer found - hold E on the red screen", TITLE, 5)
            elseif not security then
                securityShown = false
            end
        end)
        task.wait(waitTime)
    end
end)

task.spawn(function()
    local casDown, kaDown, openDown = false, false, false
    PERF.kaArmed, PERF.kaActive = false, false   
    while _G.JB_gen == myGen do
        PERF.run("plasmaKillaura", function()
            local cnow = false
            cnow = PERF.keyDown("casino", CASINO_KEY)
            if (cnow and not casDown) or casinoRequested then
                casinoRequested = false
                if cnow then casDown = true end
                requestCasinoCode()
            elseif not cnow then
                casDown = false
            end
			
			local onow = false
            onow = PERF.keyDown("casinoOpen", CASINO_OPEN_KEY)
            if (onow and not openDown) or casinoOpenRequested then
                casinoOpenRequested = false
                if onow then openDown = true end
                requestCasinoOpen()
            elseif not onow then
                openDown = false
            end

            local kaArmed = UI.GetValue(uid("plasmaKillaura")) and true or false
            if kaArmed ~= PERF.kaArmed then
                PERF.kaArmed = kaArmed
                notify(kaArmed and "Enabled" or "Disabled", "[JB Hub] PlasmaPistol Killaura", 3)
            end
            PERF.kaActive = kaArmed and keybindActive(PERF.kaKeybind)      

--          if UI.GetValue(uid("nosit")) then
--              killSit()
--          end
        end)
        task.wait(0.03)
    end
end)

task.spawn(function()
    local camera = workspace.CurrentCamera
    local wasOn = false
    local lastAmmo = nil
    local lastAmmoChange = os.clock()
    local lastEquip = 0
    local lastMode = nil
    local gear = nil
    local gearAt = 0
    local targets = {}
    local targetsAt = 0
    local targetsMode = nil

    local function loadGear()
        local item = getPlasmaItem()
        if not item then return nil end
        local g = {
            item = item,
            equip = item:FindFirstChild("InventoryEquipRemote"),
            reload = item:FindFirstChild("Reload"),
            shoot = item:FindFirstChild("Shoot"),
            damage = item:FindFirstChild("Damage"),
        }
        if g.equip and g.reload and g.shoot and g.damage then return g end
        return nil
    end

    local function readAmmo()
        local ammo = nil
        pcall(function() ammo = gear and gear.item:GetAttribute("AmmoCurrent") end)
        return ammo
    end

    local function isReloading()
        local reloading = false
        pcall(function() reloading = gear ~= nil and gear.item:GetAttribute("IsReloading") == true end)
        return reloading
    end

    local function refreshGear(force)
        local now = os.clock()
        if force or not gear or now - gearAt >= PERF.PLASMA_CACHE_TIME then
            gearAt = now
            local ok, g = pcall(loadGear)
            gear = ok and g or nil
        end
        return gear
    end

    while _G.JB_gen == myGen do
        local enabled = PERF.kaArmed and PERF.kaActive and true or false

        local mode = getPlasmaTargetMode()
        if mode ~= lastMode then
            if lastMode ~= nil then
                notify("Target: " .. mode, "[JB Hub] PlasmaPistol Killaura", 3)
            end
            lastMode = mode
        end

        if enabled then
            if not wasOn then
                wasOn = true
                notify("ON", "[JB Hub] PlasmaPistol Killaura", 3)
                refreshGear(true)
                lastAmmo = readAmmo()
                lastAmmoChange = os.clock()
                lastEquip = 0
                targetsAt = 0
            end

            pcall(function()
                if PERF.solving then return end
                if not refreshGear(false) then return end

                local now = os.clock()

                if now - lastEquip >= PLASMA_EQUIP_INTERVAL then
                    pcall(function() gear.equip:FireServer(true) end)
                    lastEquip = now
                end

                local ammo = readAmmo()

                if ammo ~= nil and ammo ~= lastAmmo then
                    lastAmmo = ammo
                    lastAmmoChange = now
                end

                local idleFor = now - lastAmmoChange

                if ammo ~= nil and (ammo <= 0 or (ammo < PLASMA_MAX_AMMO and idleFor >= PLASMA_IDLE_TIME)) and not isReloading() then
                    pcall(function() gear.reload:FireServer() end)
                    task.wait(PLASMA_RELOAD_WAIT)
                    lastAmmo = readAmmo()
                    lastAmmoChange = os.clock()
                end

                local lp = game:GetService("Players").LocalPlayer
                local myHRP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")

                if myHRP and ammo and ammo > 0 then
                    if mode ~= targetsMode or now - targetsAt >= PERF.PLASMA_TARGET_REFRESH then
                        targetsMode = mode
                        targetsAt = now
                        targets = getPlasmaTargets()
                    end
                    local shoot, damage = gear.shoot, gear.damage
                    for _, target in ipairs(targets) do
                        if isPlasmaTargetValid(target) and (myHRP.Position - target.hrp.Position).Magnitude <= PLASMA_MAX_DISTANCE then
                            camera.CFrame = CFrame.lookAt(camera.CFrame.Position, target.hrp.Position)

                            for _ = 1, PLASMA_BURST do
                                if not isPlasmaTargetValid(target) then break end
                                local position = target.hrp.Position
                                pcall(function() shoot:FireServer() end)
                                task.wait(PLASMA_SHOOT_TO_DAMAGE)
                                pcall(function() damage:FireServer(position, target.humanoid) end)
                            end
                        end
                    end
                end
            end)

            task.wait(PLASMA_TICK)
        else
            if wasOn then
                wasOn = false
                gear = nil
                targets = {}
                notify("OFF", "[JB Hub] PlasmaPistol Killaura", 3)
            end
            task.wait(0.25)
        end
    end
end)

local function jobEnabled(id)
    if id == "springs" then
        return isOn("norecoil")
    end
    return isOn(id)
end

local function scanSprings()
    local found = {}
    for _, entry in ipairs(lockedGetgc(true)) do
        if typeof(entry) == "table" then
            local ok, has = pcall(function()
                return entry.SpringCamera ~= nil
                    or (entry.CrossHair ~= nil and entry.CrossHair.Spring ~= nil)
            end)
            if ok and has then found[#found + 1] = entry end
        end
    end
    springTargets = found
end

local function applySprings()
    for _, entry in ipairs(springTargets) do
        pcall(function()
            if entry.SpringCamera then
                entry.SpringCamera:SetTarget(Vector3.new(0, 0, 0))
                entry.SpringCamera:Accelerate(Vector3.new(0, 0, 0))
            end
            if entry.CrossHair and entry.CrossHair.Spring then
                entry.CrossHair.Spring:SetTarget(0)
                entry.CrossHair.Spring:Accelerate(0)
            end
        end)
    end
end

local function getNfdMethod()
    local idx = tonumber(UI.GetValue(uid("nofallMethod"))) or 0
    return NFD_METHODS[idx + 1] or "Zone Follow"
end

local function getNfdVelocityY(hrp)
    local base = tonumber(hrp.Address)
    if not base or base <= 4096 then return nil end
    local prim = memory_read("uintptr_t", base + PRIMITIVE_OFFSET)
    if not prim or prim <= 4096 then return nil end
    return memory_read("float", prim + VELOCITY_Y_OFFSET)
end

task.spawn(function()
    local wasOn = false
    local applied = false
    local activeMethod = nil
    local zone = nil
    local dropped = 0
    local lastTime = tick()
    local pulseUntil = 0
    local pulseAddr = nil
    local checkedAddr, offsetsOk, offsetsWarned = nil, false, false

    local function pulseOffsetsValid(hum, hrp, addr)
        local okH, h = pcall(memory_read, "float", addr + HUM_HEALTH)
        local okR, real = pcall(function() return hum.Health end)
        if not (okH and okR and type(h) == "number" and type(real) == "number" and math.abs(h - real) < 0.01) then return false end
        local okB, b = pcall(memory_read, "byte", addr + PLATFORM_STAND_OFFSET)
        if not okB or (b ~= 0 and b ~= 1) then return false end
        local okPS, ps = pcall(function() return hum.PlatformStand end)
        if okPS and type(ps) == "boolean" and (ps and 1 or 0) ~= b then return false end
        local okV, vy = pcall(getNfdVelocityY, hrp)
        if not okV or type(vy) ~= "number" or vy ~= vy or math.abs(vy) > 2000 then return false end
        local okA, av = pcall(function() return hrp.AssemblyLinearVelocity.Y end)
        if okA and type(av) == "number" and math.abs(av - vy) > 5 then return false end
        return true
    end

    local function releasePulse()
        if pulseAddr then
            pcall(function() memory_write("byte", pulseAddr + PLATFORM_STAND_OFFSET, 0) end)
        end
        pulseUntil = 0
        pulseAddr = nil
        dropped = 0
    end

    local function restoreZone()
        pcall(function()
            local z = zone or findZone()
            if z then
                if _G.NFD_original then z.Size = _G.NFD_original end
                if _G.NFD_originalPos then z.Position = _G.NFD_originalPos end
            end
        end)
        zone = nil
    end

    local function stopMethod(method)
        if method == "Zone Follow" then
            restoreZone()
        elseif method == "Pulse" then
            releasePulse()
            restoreZone()
        end
    end

    local zoneCenter, zoneCheckAt = nil, 0
    local function stepZone()
        local now = tick()
        if not zone or now >= zoneCheckAt then
            zoneCheckAt = now + PERF.NFD_ZONE_CHECK
            zoneCenter = nil
            if not zone or zone.Parent == nil then
                zone = findZone()
                zoneCenter = nil
                if not zone then return false end
                _G.NFD_original = _G.NFD_original or zone.Size
                _G.NFD_originalPos = _G.NFD_originalPos or zone.Position
            end
            if zone.Size.X < 2000 then
                zone.Size = NFD_ZONE_SIZE
                zoneCenter = nil
            end
        end
        local char = game:GetService("Players").LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end
        local p = hrp.Position
        local c = zoneCenter
        local m = PERF.NFD_ZONE_MARGIN
        if not c or math.abs(p.X - c.X) > m or math.abs(p.Y - c.Y) > m or math.abs(p.Z - c.Z) > m then
            zone.Position = p
            zoneCenter = p
        end
        return true
    end

    local function stepPulse()
        local now = tick()
        local dt = math.min(now - lastTime, 0.1)
        lastTime = now
        local char = game:GetService("Players").LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not (hum and hrp) then
            dropped = 0
            return false
        end
        local addr = tonumber(hum.Address)
        if not addr or addr <= 4096 then return false end
        if addr ~= checkedAddr and pulseUntil == 0 then
            checkedAddr = addr
            offsetsOk = pulseOffsetsValid(hum, hrp, addr)
            if not offsetsOk and not offsetsWarned then
                offsetsWarned = true
                PERF.notifySafe("Pulse is outdated, using Zone Follow until JB Hub update", "[JB Hub] No Fall Damage", 5)
            end
        end
        if not offsetsOk then return stepZone() end
        local vy = getNfdVelocityY(hrp)
        if not vy then return false end
        if pulseUntil > 0 then
            if now >= pulseUntil then
                memory_write("byte", addr + PLATFORM_STAND_OFFSET, 0)
                pulseUntil = 0
            end
            return true
        end
        if vy < NFD_FALLING_SPEED then
            dropped = dropped + (-vy) * dt
            local okB, b = pcall(memory_read, "byte", addr + PLATFORM_STAND_OFFSET)
            if dropped >= NFD_RESET_EVERY and okB and b == 0 then
                memory_write("byte", addr + PLATFORM_STAND_OFFSET, 1)
                pulseAddr = addr
                pulseUntil = now + NFD_PULSE_TIME
                dropped = 0
            end
        else
            dropped = 0
        end
        return true
    end

    while _G.JB_gen == myGen do
        local waitTime = 0.25
        PERF.run("nofall", function()
            local on = UI.GetValue(uid("nofall")) and true or false
            if not on then
                if wasOn then
                    stopMethod(activeMethod)
                    activeMethod = nil
                    applied = false
                    wasOn = false
                    notify("OFF", "[JB Hub] No Fall Damage", 3)
                end
                return
            end

            local method = getNfdMethod()
            if method ~= activeMethod then
                if activeMethod then stopMethod(activeMethod) end
                zoneCenter = nil
                activeMethod = method
                applied = false
                lastTime = tick()
            end
            wasOn = true

            local okCall, ok
            if method == "Pulse" then
                okCall, ok = pcall(stepPulse)
                waitTime = NFD_PULSE_TICK
            else
                okCall, ok = pcall(stepZone)
                waitTime = NFD_FOLLOW_TICK
            end

            if okCall and ok and not applied then
                applied = true
                notify("ON (" .. method .. ")", "[JB Hub] No Fall Damage", 3)
            end
        end)
        task.wait(waitTime)
    end
    stopMethod(activeMethod)
end)

task.spawn(function()
    local casinoWasOn, nositWasOn = false, false
	local casinoOpenWasOn = false
    local jobCache, jobDirty = {}, {}
    local springRaw = -1
    local lastSig, lastSigCheck, lastReapply, lastSafety = nil, 0, 0, tick()

    local function equipSignature()
        local sig = 0
        pcall(function()
            local folder = game:GetService("Players").LocalPlayer:FindFirstChild("Folder")
            for _, item in ipairs(folder:GetChildren()) do
                local c = item:GetAttribute("InventoryItemLocalEquipped")
                if type(c) == "number" then sig = sig + c end
            end
        end)
        return sig
    end
    while _G.JB_gen == myGen do
        local ranHeavy = false
        PERF.run("jobs", function()
            if not resetting and tick() - lastSitAt > SIT_PRIORITY then
                local now = tick()
                if now - lastSigCheck >= 1 then
                    lastSigCheck = now
                    local sig = PERF.equipVersion
                    local safety = now - lastSafety >= PERF.JOB_SAFETY_RESCAN
                    if (lastSig ~= nil and sig ~= lastSig) or safety then
                        lastSafety = now
                        for id in pairs(jobCache) do jobDirty[id] = now + 2 end
                    end
                    lastSig = sig
                end

                local keys, owners = {}, {}
                local due = false
                for _, id in ipairs(JOB_ORDER) do
                    if id ~= "springs" then
                        if jobEnabled(id) then
                            if not jobCache[id] and not jobDirty[id] then jobDirty[id] = now + PERF.JOB_BATCH_DELAY end
                            if jobDirty[id] and jobDirty[id] <= now then due = true end
                        else
                            jobCache[id], jobDirty[id], notified[id] = nil, nil, false
                        end
                    end
                end
                if due then
                    for _, id in ipairs(JOB_ORDER) do
                        if id ~= "springs" and jobDirty[id] then
                            for _, k in ipairs(defs[id].keys) do
                                if not owners[k] then
                                    keys[#keys + 1] = k
                                    owners[k] = {}
                                end
                                table.insert(owners[k], id)
                            end
                        end
                    end
                end

                if #keys > 0 then
                    ranHeavy = true
                    local found = {}
                    for _, e in ipairs(lockedGetgc(keys)) do
                        local key = tostring(e.key)
                        local ids = owners[key]
                        if ids then
                            for _, id in ipairs(ids) do
                                if PERF.gcValueMatches(e, defs[id].vals[key]) then
                                    found[id] = found[id] or {}
                                    table.insert(found[id], e)
                                end
                            end
                        end
                    end
                    for _, ids in pairs(owners) do
                        for _, id in ipairs(ids) do
                            if jobDirty[id] then
                                jobDirty[id] = nil
                                jobCache[id] = found[id] or {}
                                pcall(applygc, PERF.filterProtected(id, jobCache[id], true), defs[id].vals)                                
                                if #jobCache[id] > 0 and not notified[id] then
                                    notified[id] = true
                                    notify("ON", "[JB Hub] " .. defs[id].label, 3)
                                end
                            end
                        end
                    end
                elseif now - lastReapply >= 4 then
                    lastReapply = now
                    for id, cache in pairs(jobCache) do
                        if #cache > 0 then
                            local alive = PERF.gcAlive(cache)
                            if #alive == 0 then
                                jobCache[id] = nil
                            else
                                jobCache[id] = alive
                                PERF.applyChunked(PERF.filterProtected(id, alive), defs[id].vals)
                            end
                        end
                    end
                end

                if jobEnabled("springs") then
                    local char = game:GetService("Players").LocalPlayer.Character
                    local charAddr = char and char.Address
                    local first = nextApply.springs == nil or nextApply.springs == 0
                    local need = first or #springTargets == 0 or charAddr ~= springRaw
                    if need and (nextApply.springs or 0) <= now then
                        ranHeavy = true
                        springRaw = charAddr
                        nextApply.springs = now + SPRING_RESCAN_EVERY
                        scanSprings()
                    end
                else
                    nextApply.springs = 0
                end
            end
            local casinoOn = UI.GetValue(uid("casino")) and true or false
            if casinoOn ~= casinoWasOn then
                casinoWasOn = casinoOn
                notify(casinoOn and "ON" or "OFF", "[JB Hub] Get Casino Code", 3)
            end
			
			local casinoOpenOn = UI.GetValue(uid("casinoOpen")) and true or false
            if casinoOpenOn ~= casinoOpenWasOn then
                casinoOpenWasOn = casinoOpenOn
                notify(casinoOpenOn and "ON" or "OFF", "[JB Hub] Open Casino Door", 3)
            end

--          local nositOn = UI.GetValue(uid("nosit")) and true or false
--          if nositOn ~= nositWasOn then
--              nositWasOn = nositOn
--              notify("JB", "No Sit " .. (nositOn and "on" or "off"), 3)
--          end

            if isOn("norecoil") and not resetting then
                applySprings()
            end
        end)
        task.wait(ranHeavy and HEAVY_COOLDOWN or 0.25)
    end
end)

function COSMETICS.findRemote(name)
    local rs = game:GetService("ReplicatedStorage")
    local r = rs:FindFirstChild(name, true)
    if not r then
        pcall(function() r = game:FindFirstChild(name, true) end)
    end
    return r
end

function COSMETICS.getPicks()
    local picks, sig = {}, {}
    for _, slot in ipairs(COSMETICS.SLOTS) do
        local idx = tonumber(UI.GetValue(uid(slot.id))) or 0
        local value = slot.list[idx + 1]
        table.insert(sig, tostring(idx))
        if value and value ~= "None" then
            table.insert(picks, { slot = slot, value = value })
        end
    end
    local plate = UI.GetValue(uid(COSMETICS.PLATE.id)) and true or false
    table.insert(sig, plate and "P" or "-")
    if plate then
        table.insert(picks, { slot = COSMETICS.PLATE, value = COSMETICS.PLATE_TEXT })
    end
    return picks, table.concat(sig, ",")
end

function COSMETICS.startBind()
    if tick() - COSMETICS.lastFlip < 0.3 then return end
    COSMETICS.lastFlip = tick()
    if not COSMETICS.carKey() then
        notify("Get in a vehicle first", COSMETICS.TITLE, 3)
        return
    end
    local picks = COSMETICS.getPicks()
    if #picks == 0 then
        notify("Nothing selected", COSMETICS.TITLE, 3)
        return
    end
    COSMETICS.bindActive = true
    COSMETICS.bindNotify = true
    COSMETICS.leftAt = nil
end

function COSMETICS.stopBind(reason)
    if not COSMETICS.bindActive then return end
    COSMETICS.bindActive = false
    COSMETICS.bindNotify = false
    COSMETICS.leftAt = nil
    if reason then notify(reason, COSMETICS.TITLE, 3) end
end

task.spawn(function()
    while _G.JB_gen == myGen do
        if COSMETICS.bindActive then
            PERF.run("cosmeticsBind", function()
                if COSMETICS.carKey() then
                    COSMETICS.leftAt = nil
                else
                    COSMETICS.leftAt = COSMETICS.leftAt or tick()
                    if tick() - COSMETICS.leftAt >= COSMETICS.EXIT_GRACE then
                        COSMETICS.stopBind("Left vehicle, apply stopped")
                    end
                end
            end)
            task.wait(PERF.FRAME)
        else
            task.wait(0.1)
        end
    end
end)

task.spawn(function()
    local wasOn, keyDown = false, false
    while _G.JB_gen == myGen do
        PERF.run("cosmeticsBind", function()
            local on = UI.GetValue(uid("cosmeticsBind")) and true or false
            if on ~= wasOn then
                wasOn = on
                if not on then COSMETICS.stopBind() end
                notify(on and "Bind ON" or "Bind OFF", COSMETICS.TITLE, 3)
            end
            local now = false
            if on then now = PERF.keyDown("cosmetics", COSMETICS.KEY) end
            local fire = (now and not keyDown) or (COSMETICS.requested and on)
            COSMETICS.requested = false
            keyDown = now
            if fire then COSMETICS.startBind() end
        end)
        task.wait(0.05)
    end
end)

COSMETICS.ORDER = { BodyColor = 1, SecondBodyColor = 1, WheelColor = 1, SpoilerColor = 1, Texture = 2, SecondTexture = 2, Horn = 2, Spoiler = 3, TireMesh = 4, Rim = 5, TireSticker = 6, LicensePlate = 2 }

function COSMETICS.carKey()
    local ok, _, _, model = pcall(VEHICLE.findMine)
    if not ok or not model then return nil end
    local okA, addr = pcall(function() return tostring(model.Address) end)
    return okA and addr or nil
end

COSMETICS.DEBUG = false -- debug
COSMETICS.HEAVY = { Spoiler = true, SpoilerColor = true, TireMesh = true, Rim = true, TireSticker = true, WheelColor = true }
COSMETICS.lastSent = {}
COSMETICS.FOLLOW = { Rim = "WheelColor", TireMesh = "WheelColor", Spoiler = "SpoilerColor" }

function COSMETICS.spoilerBump(value)
    task.wait(1.8)
end

function COSMETICS.apply(picks, full, bump)
    if full then COSMETICS.lastSent = {} end
    local list = {}
    for _, pick in ipairs(picks) do
        for _, prop in ipairs(pick.slot.props) do
            if COSMETICS.lastSent[prop] ~= pick.value then
                list[#list + 1] = { prop = prop, value = pick.value, order = COSMETICS.ORDER[prop] or 2, idx = #list + 1 }
            end
        end
    end
    table.sort(list, function(a, b)
        if a.order ~= b.order then return a.order < b.order end
        return a.idx < b.idx
    end)
    local picked = {}
    for _, pick in ipairs(picks) do
        for _, prop in ipairs(pick.slot.props) do picked[prop] = pick.value end
    end
    local need = {}
    for _, e in ipairs(list) do
        local f = COSMETICS.FOLLOW[e.prop]
        if f and picked[f] then need[f] = true end
    end
    for _, f in ipairs({ "WheelColor", "SpoilerColor" }) do
        if need[f] then
            for i = #list, 1, -1 do
                if list[i].prop == f then table.remove(list, i) end
            end
            list[#list + 1] = { prop = f, value = picked[f] }
        end
    end
    if COSMETICS.DEBUG then
        print(string.format("[CosDebug] apply %d props | full=%s", #list, tostring(full)))
    end
    local allOk = true
    for i, e in ipairs(list) do
        if bump and e.prop == "Spoiler" then COSMETICS.spoilerBump(e.value) end
        local ok, ret = pcall(function() return COSMETICS.equip:FireServer(e.prop, e.value) end)
        if ok then
            COSMETICS.lastSent[e.prop] = e.value
        else
            allOk = false
        end
        if COSMETICS.DEBUG then
            print(string.format("[CosDebug] #%d %s = %s | ok=%s ret=%s", i, e.prop, e.value, tostring(ok), tostring(ret)))
        end
        if i < #list then task.wait(COSMETICS.HEAVY[e.prop] and 0.3 or 0.08) end
    end
    return allOk
end

COSMETICS.REAPPLY = { 0.1, 0.7, 1.8 }

task.spawn(function()
    local wasLoop, wasActive = false, false
    local appliedKey, car, lastCarCheck = nil, nil, 0
    local seatedAt, passes = nil, 0
    while _G.JB_gen == myGen do
        local active = false
        PERF.run("cosmeticsLoop", function()
            local loopOn = UI.GetValue(uid("cosmeticsLoop")) and true or false
            if loopOn ~= wasLoop then
                wasLoop = loopOn
                appliedKey = nil
                notify(loopOn and "Loop ON" or "Loop OFF", COSMETICS.TITLE, 3)
            end
            active = loopOn or COSMETICS.bindActive
            if active ~= wasActive then
                wasActive = active
                appliedKey, car, lastCarCheck, seatedAt, passes = nil, nil, 0, nil, 0
                COSMETICS.uiOpen = COSMETICS.uiOpen or COSMETICS.findRemote("GarageSetUIOpen")
                if COSMETICS.uiOpen then
                    pcall(function() COSMETICS.uiOpen:FireServer(active) end)
                end
            end
            if not active or PERF.solving then return end
            COSMETICS.equip = COSMETICS.equip or COSMETICS.findRemote("GarageEquipItem")
            if not COSMETICS.equip then return end

            local now = tick()
            if now - lastCarCheck >= 0.1 then
                lastCarCheck = now
                local newCar = COSMETICS.carKey()
                if newCar ~= car then
                    car, appliedKey, seatedAt, passes = newCar, nil, nil, 0
                    COSMETICS.lastSent = {}
                end
            end
            if not car then return end
            if not seatedAt then
                seatedAt, passes = now, 0
                COSMETICS.uiOpen = COSMETICS.uiOpen or COSMETICS.findRemote("GarageSetUIOpen")
                if COSMETICS.uiOpen then
                    pcall(function() COSMETICS.uiOpen:FireServer(false) end)
                    pcall(function() COSMETICS.uiOpen:FireServer(true) end)
                end
            end

            local picks, sig = COSMETICS.getPicks()
            local key = car .. "|" .. sig
            local forced = COSMETICS.bindNotify
            if passes < #COSMETICS.REAPPLY then
                if now - seatedAt < COSMETICS.REAPPLY[passes + 1] then return end
                passes = passes + 1
                forced = true
            end
            if key == appliedKey and not forced then return end
            local firstPass = passes >= #COSMETICS.REAPPLY and (forced or key ~= appliedKey)
            appliedKey = key

            local msg
            if #picks == 0 then
                msg = "Nothing selected"
            elseif COSMETICS.apply(picks, forced, forced and passes >= #COSMETICS.REAPPLY) then
                msg = "Applied Cosmetics"
            else
                msg = "Failed to apply cosmetics"
            end
            if COSMETICS.bindNotify or (loopOn and firstPass) then
                COSMETICS.bindNotify = false
                notify(msg, COSMETICS.TITLE, 4)
            end
        end)
        if active then task.wait(0.1) else task.wait(0.25) end
    end
    if COSMETICS.uiOpen then pcall(function() COSMETICS.uiOpen:FireServer(false) end) end
end)

function VEHICLE.isMine(v)
    local ok, mine = pcall(function()
        return v:GetAttribute("VehicleHasDriver") == true and tonumber(v:GetAttribute("LastDriverId")) == game:GetService("Players").LocalPlayer.UserId
    end)
    return ok and mine
end

function VEHICLE.findMine()
    local vehicles = PERF.ws("Vehicles")
    if not vehicles then return nil end
    local hrp = getHRP()
    local okP, pos = pcall(function() return hrp.Position end)
    for _, v in ipairs(vehicles:GetChildren()) do
        local ref = v:FindFirstChild("Engine")
        local near = true
        if ref and okP and pos then
            local okD, d = pcall(function() return (ref.Position - pos).Magnitude end)
            near = not okD or d <= VEHICLE.FIND_RADIUS
        end
        if ref and near and VEHICLE.isMine(v) then
            local roots = {}
            for _, name in ipairs(VEHICLE.ROOT_PARTS) do
                local part = v:FindFirstChild(name)
                if part then roots[#roots + 1] = part end
            end
            local body = v:FindFirstChild("Model")
            local hidden = body and body:FindFirstChild("InvisibleCollision")
            if hidden then roots[#roots + 1] = hidden end
            return ref, roots, v
        end
    end
    return nil
end

function VEHICLE.getMine()
    local c = VEHICLE.cache
    local now = tick()
    if c and now - c.at < 2 then return c.ref, c.roots, c.model end
    if c and c.model and c.model.Parent and VEHICLE.isMine(c.model) then
        c.at = now
        return c.ref, c.roots, c.model
    end
    local ref, roots, model = VEHICLE.findMine()
    VEHICLE.cache = { ref = ref, roots = roots, model = model, at = now }
    return ref, roots, model
end

task.spawn(function()
    local wasOn = false
    local lastArmed = false
    local engine, roots, car, lastFind, lostSince = nil, {}, nil, 0, nil
    local vel = Vector3.new(0, 0, 0)
    local last = tick()
    local warned = false

    local function key(k)
        local ok, down = pcall(iskeypressed, k)
        return ok and down
    end

    local prims = {}

    local function primOf(part)
        local base = tonumber(part.Address)
        if not base or base <= 4096 then return nil end
        local p = memory_read("uintptr_t", base + PRIMITIVE_OFFSET)
        if not p or p <= 4096 then return nil end
        return p
    end

    local function bindPrims()
        prims = {}
        for _, r in ipairs(roots) do
            local ok, p = pcall(primOf, r)
            prims[#prims + 1] = ok and p or false
        end
    end

    local function writeVel(v)
        for i, r in ipairs(roots) do
            local p = prims[i]
            if p then
                if PERF.primValid(r, p) then
                    memory_write("float", p + VELOCITY_Y_OFFSET - 4, v.X)
                    memory_write("float", p + VELOCITY_Y_OFFSET, v.Y)
                    memory_write("float", p + VELOCITY_Y_OFFSET + 4, v.Z)
                end
            else
                r.AssemblyLinearVelocity = v
            end
        end
    end

    local function fly(dt)
        local keys = VEHICLE.FLY_KEYS
        local speed = tonumber(UI.GetValue(uid("carFlySpeed"))) or VEHICLE.FLY_DEFAULT_SPEED
        local cam = workspace.CurrentCamera.CFrame
        local look, right = cam.LookVector, cam.RightVector
        local dir = Vector3.new(0, 0, 0)
        if key(keys.fwd) then dir = dir + look end
        if key(keys.back) then dir = dir - look end
        if key(keys.right) then dir = dir + right end
        if key(keys.left) then dir = dir - right end
        local target = Vector3.new(0, 0, 0)
        if dir.Magnitude > 0.01 then target = dir.Unit * speed end
        if key(keys.up) then target = target + Vector3.new(0, VEHICLE.FLY_VERTICAL_SPEED, 0) end
        if key(keys.down) then target = target - Vector3.new(0, VEHICLE.FLY_VERTICAL_SPEED, 0) end
        local a = math.clamp(VEHICLE.FLY_ACCEL * dt, 0, 1)
        vel = vel + (target - vel) * a
        writeVel(vel)
    end

    local notSeatedSince, lastSearch = nil, 0

    while _G.JB_gen == myGen do
        local active = false
        PERF.run("carFly", function()
            local armed = UI.GetValue(uid("carFly")) and true or false
            if armed ~= lastArmed then
                lastArmed = armed
                notify(armed and "Enabled" or "Disabled", VEHICLE.FLY_TITLE, 3)
            end
            local on = armed and keybindActive(VEHICLE.flyKeybind)
            if on ~= wasOn then
                wasOn = on
                vel = Vector3.new(0, 0, 0)
                engine, car, lastFind, lostSince, warned, notSeatedSince = nil, nil, 0, nil, false, nil
                notify(on and "Fly ON" or "Fly OFF", VEHICLE.FLY_TITLE, 2)
            end
            if not on then return end

            local now = tick()
            local dt = math.min(now - last, 0.1)
            last = now

            if isSittingNow() then
                notSeatedSince = nil
            else
                notSeatedSince = notSeatedSince or now
                if now - notSeatedSince > 0.5 then
                    engine, car, lostSince = nil, nil, nil
                    vel = Vector3.new(0, 0, 0)
                    return
                end
            end

            if engine and not engine.Parent then engine, car = nil, nil end

            if engine and now - lastFind > PERF.FLY_RECHECK then
                lastFind = now
                if not car or not car.Parent or not VEHICLE.isMine(car) then
                    local e, r, c = VEHICLE.findMine()
                    if e and c ~= car then
                        engine, roots, car = e, r or {}, c
                        bindPrims()
                    end
                end
            end

            if not engine and now - lastSearch >= 0.25 then
                lastSearch = now
                local e, r, c = VEHICLE.findMine()
                if e then
                    engine, roots, car = e, r or {}, c
                    lastFind = now
                    bindPrims()
                end
            end

            if engine then
                lostSince, warned = nil, false
                active = true
                fly(dt)
            else
                lostSince = lostSince or now
                if not warned and now - lostSince > VEHICLE.FLY_LOST_GRACE then
                    warned = true
                    notify("Get in a vehicle first", VEHICLE.FLY_TITLE, 3)
                end
            end
        end)
        PERF.flying = wasOn
        if active then task.wait(0.016) else task.wait(0.03) end
        if not active then last = tick() end
    end
end)

task.spawn(function()
    local lastArmed = false
    local target, lastScan, lastApply = nil, 0, 0
    local wasOn = false

    local function readNumber(addr)
        local okT, tag = pcall(memory_read, "int", addr + 12)
        local okD, d = pcall(memory_read, "double", addr)
        if okT and tag == 3 and okD and type(d) == "number" then return d end
        return nil
    end

    local function getMult()
        local m = tonumber(UI.GetValue(uid("engineBoostMult"))) or VEHICLE.BOOST_DEFAULT
        return math.clamp(m, 1, VEHICLE.BOOST_MAX)
    end

    local function findTarget()
        local garages, trues = {}, {}
        for _, e in ipairs(lockedGetgc({ "GarageEngineSpeed", "TrueEngineSpeed" })) do
            local a = tonumber(e.addr)
            local v = a and readNumber(a)
            if v then
                local k = tostring(e.key)
                if k == "GarageEngineSpeed" then garages[#garages + 1] = { addr = a, value = v }
                elseif k == "TrueEngineSpeed" then trues[#trues + 1] = { addr = a, value = v } end
            end
        end
        local best, bestGap = nil, math.huge
        for _, g in ipairs(garages) do
            for _, t in ipairs(trues) do
                local gap = math.abs(t.addr - g.addr)
                if gap <= VEHICLE.BOOST_PAIR_RANGE and gap < bestGap then
                    best = { garage = g.addr, orig = g.value, total = t.value, written = nil }
                    bestGap = gap
                end
            end
        end
        return best
    end

    local function restore()
        if not target then return end
        local cur = readNumber(target.garage)
        if cur and target.written and math.abs(cur - target.written) < 0.001 then
            pcall(memory_write, "double", target.garage, target.orig)
        end
        target = nil
    end

    while _G.JB_gen == myGen do
        PERF.run("engineBoost", function()
            local armed = UI.GetValue(uid("engineBoost")) and true or false
            if armed ~= lastArmed then
                lastArmed = armed
                notify(armed and "Enabled" or "Disabled", VEHICLE.BOOST_TITLE, 3)
            end
            local on = armed and keybindActive(VEHICLE.boostKeybind)
            if on ~= wasOn then
                wasOn = on
                if not on then restore() end
                lastScan = 0
                notify(on and string.format("Boost ON (x%.2f)", getMult()) or "Boost OFF", VEHICLE.BOOST_TITLE, 2)
            end
            if not on or PERF.solving then return end

            local now = tick()
            if now - lastApply < 0.5 then return end
            lastApply = now

            if not isSittingNow() then
                if target then restore() end
                VEHICLE.boostDelay = VEHICLE.BOOST_RESCAN
                return
            end
            if target and not readNumber(target.garage) then target = nil end
            if not target and now - lastScan >= (VEHICLE.boostDelay or VEHICLE.BOOST_RESCAN) then
                lastScan = now
                target = findTarget()
                VEHICLE.boostDelay = target and VEHICLE.BOOST_RESCAN or math.min((VEHICLE.boostDelay or VEHICLE.BOOST_RESCAN) * 2, 30)
                if target then
                    notify(string.format("Vehicle boosted (engine %.1f)", target.total * getMult()), VEHICLE.BOOST_TITLE, 2)
                end
            end
            if target then
                local want = target.orig + target.total * (getMult() - 1)
                local cur = readNumber(target.garage)
                if cur and math.abs(cur - want) > 0.001 then
                    pcall(memory_write, "double", target.garage, want)
                end
                target.written = want
            end
        end)
        task.wait(0.03)
    end
    restore()
end)

task.spawn(function()
    local shrunk = {}
    local car, tires = nil, {}
    local lastFind, lastSpikeScan, lastProtect = 0, 0, 0
    local wasOn = false

    local function getTires(c)
        local list = {}
        for _, d in ipairs(c:GetDescendants()) do
            if d.ClassName == "Model" and d.Name:sub(1, 5) == "Wheel" and d.Name ~= "Wheels" and d.Name ~= "WheelModels" then
                local tm = d:FindFirstChild("TireMesh")
                if tm and not tm:FindFirstChild("Dual1") then list[#list + 1] = tm end
            end
        end
        return list
    end

    local function scanSpikes()
        for _, m in ipairs(PERF.spikeModels) do
            if m.Parent then
                local hit = m:FindFirstChild("Part")
                if hit then
                    local ok, size = pcall(function() return hit.Size end)
                    if ok and size and size.X > 0.01 then
                        local addr = hit.Address
                        if shrunk[addr] or size.X >= VEHICLE.TIRE_MIN_WIDTH then
                            if not shrunk[addr] then shrunk[addr] = { part = hit, size = size } end
                            pcall(function() hit.Size = LASER_TINY end)
                        end
                    end
                end
            end
        end
        for addr, s in pairs(shrunk) do
            if s.part.Parent == nil then shrunk[addr] = nil end
        end
    end

    local function restoreSpikes()
        for _, s in pairs(shrunk) do
            if s.part.Parent then pcall(function() s.part.Size = s.size end) end
        end
        shrunk = {}
    end

    local function protect(c)
        local last = c:GetAttribute("VehicleTiresLastPop")
        if type(last) ~= "number" or last == 0 then return end
        c:SetAttribute("VehicleTiresLastPop", 0)
        local max = c:GetAttribute("MaxVehicleTireHealth")
        local hp = c:GetAttribute("VehicleTireHealth")
        if type(max) == "number" and type(hp) == "number" and hp < max then
            c:SetAttribute("VehicleTireHealth", max)
        end
    end

    local function showTires()
        for _, tm in ipairs(tires) do
            pcall(function() tm.Transparency = 0 end)
            pcall(function() tm.LocalTransparencyModifier = 0 end)
        end
    end

    while _G.JB_gen == myGen do
        local wait = 0.25
        PERF.run("antiTirePop", function()
            local on = UI.GetValue(uid("antiTirePop")) and true or false
            if on ~= wasOn then
                wasOn = on
                if not on then
                    restoreSpikes()
                    car, tires = nil, {}
                end
                notify(on and "Enabled" or "Disabled", VEHICLE.TIRE_TITLE, 3)
            end
            if not on then return end

            local now = tick()
            if now - lastSpikeScan >= VEHICLE.TIRE_SPIKE_SCAN then
                lastSpikeScan = now
                pcall(scanSpikes)
            end
            if not isSittingNow() then
                car, tires = nil, {}
                wait = 0.1
                return
            end
            if not car or not car.Parent or now - lastFind >= 2 then
                lastFind = now
                local _, _, c = VEHICLE.getMine()
                if c ~= car then
                    car = c
                    tires = c and getTires(c) or {}
                end
            end
            if car then
                if now - lastProtect >= 0.05 then
                    lastProtect = now
                    pcall(protect, car)
                end
                showTires()
            end
            wait = nil
        end)
        task.wait(wait)
    end
    restoreSpikes()
end)

task.spawn(function()
    local engine, roots, car, prims = nil, {}, nil, {}
    local lastFind, lastCheck = 0, 0
    local wasOn, lastArmed = false, false
    local braking = false

    local function primOf(part)
        local base = tonumber(part.Address)
        if not base or base <= 4096 then return false end
        local p = memory_read("uintptr_t", base + PRIMITIVE_OFFSET)
        if not p or p <= 4096 then return false end
        return p
    end

    local function bind(e, r, c)
        engine, roots, car = e, r or {}, c
        prims = {}
        for i, part in ipairs(roots) do
            local ok, p = pcall(primOf, part)
            prims[i] = ok and p or false
        end
    end

    local function reset()
        engine, roots, car, prims = nil, {}, nil, {}
        braking = false
    end

    local function brakePressed()
        for _, k in ipairs(VEHICLE.BRAKE_KEYS) do
            local ok, down = pcall(iskeypressed, k)
            if ok and down then return true end
        end
        return false
    end

    local function flyActive()
        return UI.GetValue(uid("carFly")) and keybindActive(VEHICLE.flyKeybind)
    end

    local function readVel()
        for i, p in ipairs(prims) do
            if p and PERF.primValid(roots[i], p) then
                return Vector3.new(
                    memory_read("float", p + VELOCITY_Y_OFFSET - 4),
                    memory_read("float", p + VELOCITY_Y_OFFSET),
                    memory_read("float", p + VELOCITY_Y_OFFSET + 4)
                )
            end
        end
        return (roots[1] or engine).AssemblyLinearVelocity
    end

    local function writeVel(v)
        for i, r in ipairs(roots) do
            local p = prims[i]
            if p then
                if PERF.primValid(r, p) then
                    memory_write("float", p + VELOCITY_Y_OFFSET - 4, v.X)
                    memory_write("float", p + VELOCITY_Y_OFFSET, v.Y)
                    memory_write("float", p + VELOCITY_Y_OFFSET + 4, v.Z)
                end
            else
                pcall(function() r.AssemblyLinearVelocity = v end)
            end
        end
    end

    local function tryBrake()
        local v = readVel()
        local forward = v:Dot(engine.CFrame.LookVector)
        if not braking and forward <= VEHICLE.BRAKE_MIN_SPEED then return end
        braking = forward > 0.5
        writeVel(Vector3.new(0, math.min(v.Y, 0), 0))
    end

    while _G.JB_gen == myGen do
        local wait = 0.1
        PERF.run("instantBrake", function()
            local armed = UI.GetValue(uid("instantBrake")) and true or false
            if armed ~= lastArmed then
                lastArmed = armed
                notify(armed and "Enabled" or "Disabled", VEHICLE.BRAKE_TITLE, 3)
            end
            local on = armed and keybindActive(VEHICLE.brakeKeybind)
            if on ~= wasOn then
                wasOn = on
                reset()
                notify(on and "Brake ON" or "Brake OFF", VEHICLE.BRAKE_TITLE, 2)
            end
            if not on then return end
            if not isSittingNow() then
                reset()
                return
            end
            local now = tick()
            if not engine or not engine.Parent then
                if now - lastFind >= 0.3 then
                    lastFind, lastCheck = now, now
                    local ok, e, r, c = pcall(VEHICLE.findMine)
                    if ok and e then bind(e, r, c) else reset() end
                end
            elseif now - lastCheck >= 3 then
                lastCheck = now
                if not car or not car.Parent or not VEHICLE.isMine(car) then reset() end
            end
            if not engine then return end
            wait = 0.016
            if brakePressed() and not flyActive() then
                local ok = pcall(tryBrake)
                if not ok then reset() end
            else
                braking = false
            end
        end)
        task.wait(wait)
    end
end)

task.spawn(function()
    local engine, roots, car, prims = nil, {}, nil, {}
    local lastFind, lastCheck = 0, 0
    local lastArmed, correcting = false, false
    local primParts = {}
    local worldUp = Vector3.new(0, 1, 0)

    local function primOf(part)
        local base = tonumber(part.Address)
        if not base or base <= 4096 then return false end
        local p = memory_read("uintptr_t", base + PRIMITIVE_OFFSET)
        if not p or p <= 4096 then return false end
        return p
    end

    local function bind(e, r, c)
        engine, roots, car = e, r or {}, c
        prims, primParts = {}, {}
        for _, part in ipairs(roots) do
            local ok, p = pcall(primOf, part)
            if ok and p then
                prims[#prims + 1] = p
                primParts[#primParts + 1] = part
            end
        end
    end

    local function reset()
        engine, roots, car, prims = nil, {}, nil, {}
        primParts = {}
        correcting = false
    end

    local function release()
        for i, p in ipairs(prims) do
            if PERF.primValid(primParts[i], p) then
                memory_write("float", p + VEHICLE.FLIP_ANG, 0)
                memory_write("float", p + VEHICLE.FLIP_ANG + 8, 0)
            end
        end
    end

    local function step()
        local cf = engine.CFrame
        local up = cf.UpVector
        if up.Y < VEHICLE.FLIP_TRIGGER or (correcting and up.Y < VEHICLE.FLIP_DONE) then
            correcting = true
            local axis = up:Cross(worldUp)
            if axis.Magnitude < 0.05 then axis = cf.LookVector end
            local w = axis.Unit * VEHICLE.FLIP_GAIN
            for i, p in ipairs(prims) do
                if PERF.primValid(primParts[i], p) then
                    memory_write("float", p + VEHICLE.FLIP_ANG, w.X)
                    memory_write("float", p + VEHICLE.FLIP_ANG + 8, w.Z)
                    if up.Y < 0 then
                        local vy = memory_read("float", p + VELOCITY_Y_OFFSET)
                        if vy < VEHICLE.FLIP_LIFT then memory_write("float", p + VELOCITY_Y_OFFSET, VEHICLE.FLIP_LIFT) end
                    end
                end
            end
        elseif correcting then
            correcting = false
            release()
        end
    end

    while _G.JB_gen == myGen do
        local wait = 0.1
        PERF.run("antiFlip", function()
            local armed = UI.GetValue(uid("antiFlip")) and true or false
            if armed ~= lastArmed then
                lastArmed = armed
                if not armed and correcting then pcall(release) end
                reset()
                notify(armed and "ON" or "OFF", VEHICLE.FLIP_TITLE, 3)
            end
            if not armed then return end
            if not isSittingNow() then
                reset()
                return
            end
            local now = tick()
            if not engine or not engine.Parent then
                if now - lastFind >= 0.3 then
                    lastFind, lastCheck = now, now
                    local ok, e, r, c = pcall(VEHICLE.findMine)
                    if ok and e then bind(e, r, c) else reset() end
                end
            elseif now - lastCheck >= 3 then
                lastCheck = now
                if not car or not car.Parent or not VEHICLE.isMine(car) then reset() end
            end
            if not engine or #prims == 0 then return end
            wait = correcting and VEHICLE.FLIP_TICK or 0.1
            if not pcall(step) then reset() end
        end)
        task.wait(wait)
    end
end)

task.spawn(function()
    _G.JB_AutoShootOrig = _G.JB_AutoShootOrig or {}
    local original = _G.JB_AutoShootOrig
    local targets = {}
    local wasOn = false
    local dirtyAt, lastApply, lastSigCheck, lastSig = nil, 0, 0, nil

    local function readRaw(a)
        return {
            lo = memory_read("int", a),
            hi = memory_read("int", a + 4),
            tag = memory_read("int", a + 12),
        }
    end

    local function writeRaw(a, raw)
        memory_write("int", a, raw.lo)
        memory_write("int", a + 4, raw.hi)
        memory_write("int", a + 12, raw.tag)
    end

    local function equipSignature()
        local sig = 0
        pcall(function()
            local folder = game:GetService("Players").LocalPlayer:FindFirstChild("Folder")
            for _, item in ipairs(folder:GetChildren()) do
                local c = item:GetAttribute("InventoryItemLocalEquipped")
                if type(c) == "number" then sig = sig + c end
            end
        end)
        return sig
    end

    local function scanOnce()
        local added = 0
        for _, e in ipairs(lockedGetgc({ "FireAuto" })) do
            local a = tonumber(e.addr)
            if a and tostring(e.key) == "FireAuto" then
                local key = tostring(a)
                if not original[key] then
                    local ok, raw = pcall(readRaw, a)
                    if ok and raw.tag == PERF.SHOOT_BOOL_TAG and raw.lo == 0 then
                        original[key] = { addr = a, raw = raw, entry = e }
                        added = added + 1
                    end
                end
            end
        end
        return added
    end

    local function rebuild()
        targets = {}
        for _, o in pairs(original) do targets[#targets + 1] = o.entry end
    end

    local function scan(tries)
        local added = 0
        for _ = 1, tries do
            added = scanOnce()
            if added > 0 or next(original) then break end
            task.wait(0.15)
        end
        rebuild()
        return added
    end

    local function apply()
        targets = PERF.gcAlive(targets)
        if #targets > 0 then pcall(applygc, targets, { FireAuto = true }) end
    end

    local function restore()
        local n = 0
        for key, o in pairs(original) do
            if o.entry and #PERF.gcAlive({ o.entry }) == 1 and pcall(writeRaw, o.addr, o.raw) then n = n + 1 end
            original[key] = nil
        end
        targets = {}
        return n
    end

    while _G.JB_gen == myGen do
        PERF.run("autoShoot", function()
            local on = UI.GetValue(uid("autoShoot")) and true or false
            local now = tick()
            if on ~= wasOn then
                wasOn = on
                if on then
                    dirtyAt, lastSig = now, PERF.equipVersion
                    notify("Enabled", PERF.SHOOT_TITLE, 3)
                else
                    dirtyAt = nil
                    local n = restore()
                    notify(n > 0 and ("Disabled, " .. n .. " weapon(s) restored") or "Disabled", PERF.SHOOT_TITLE, 3)
                end
            end
            if not on then return end

            if now - lastSigCheck >= 1 then
                lastSigCheck = now
                local sig = PERF.equipVersion
                if sig ~= lastSig then
                    lastSig = sig
                    dirtyAt = now + 2
                end
            end

            if dirtyAt and now >= dirtyAt and not PERF.solving then
                local first = #targets == 0
                dirtyAt = nil
                local added = scan(first and PERF.SHOOT_TRIES or 1)
                apply()
                lastApply = tick()
                if added > 0 then
                    notify(added .. " weapon(s) set to full auto", PERF.SHOOT_TITLE, 3)
                elseif #targets == 0 then
                    notify("Equip a semi-auto weapon", PERF.SHOOT_TITLE, 3)
                end
            elseif now - lastApply >= PERF.SHOOT_REAPPLY then
                lastApply = now
                apply()
            end
        end)
        task.wait(0.25)
    end
    restore()
end)

task.spawn(function()
    local unlocked = {}
    local firstSeen = {}
    local wasOn = false

    local function relock()
        local n = 0
        for key, item in pairs(unlocked) do
            if item.Parent then
                pcall(function() item:SetAttribute(PERF.SLOT_ATTR, true) end)
                n = n + 1
            end
            unlocked[key] = nil
        end
        return n
    end

    while _G.JB_gen == myGen do
        PERF.run("unlockSlots", function()
            local on = UI.GetValue(uid("unlockSlots")) and true or false
            if on ~= wasOn then
                wasOn = on
                if on then
                    firstSeen = {}
                    notify("Enabled", PERF.SLOT_TITLE, 3)
                else
                    local n = relock()
                    notify(n > 0 and ("Disabled, " .. n .. " item(s) relocked") or "Disabled", PERF.SLOT_TITLE, 3)
                end
            end
            if not on then return end
            local folder = game:GetService("Players").LocalPlayer:FindFirstChild("Folder")
            if not folder then return end
            local now = tick()
            local seen = {}
            for _, item in ipairs(folder:GetChildren()) do
                local key = tostring(item.Address)
                seen[key] = firstSeen[key] or now
                if unlocked[key] or now - seen[key] < PERF.SLOT_WATCH then
                    if item:GetAttribute(PERF.SLOT_ATTR) == true then
                        item:SetAttribute(PERF.SLOT_ATTR, false)
                        if not unlocked[key] then
                            unlocked[key] = item
                            notify(item.Name .. " unlocked", PERF.SLOT_TITLE, 2)
                        end
                    end
                end
            end
            firstSeen = seen
            for key, item in pairs(unlocked) do
                if not item.Parent then unlocked[key] = nil end
            end
        end)
        task.wait(PERF.SLOT_TICK)
    end
    relock()
end)

task.spawn(function()
    local lp = game:GetService("Players").LocalPlayer
    local DEBOUNCE = 0.6
    local wasOn, wanted, changedAt, waitNotified = false, false, 0, false

    local rs = game:GetService("ReplicatedStorage")
    local nameObjs = {}

    local function warnOutdated()
        if not PERF.nerfWarned then
            PERF.nerfWarned = true
            PERF.notifySafe("Offsets outdated, wait for JB Hub update ...", PERF.NERF_TITLE, 5)
        end
    end

    local function rdPtr(a)
        local ok, v = pcall(memory_read, "uintptr_t", a)
        return ok and type(v) == "number" and v or nil
    end

    local function rdInt(a)
        local ok, v = pcall(memory_read, "int", a)
        return ok and type(v) == "number" and v or nil
    end

    local function textAt(obj)
        local size = rdInt(obj + PERF.NERF_SIZE)
        if not size or size < 1 or size > 15 then return nil end
        local chars = {}
        for i = 1, size do
            local ok, b = pcall(memory_read, "byte", obj + PERF.NERF_DATA + i - 1)
            if not ok or type(b) ~= "number" then return nil end
            chars[i] = string.char(b)
        end
        return table.concat(chars)
    end

    local function nameObj(name)
        local obj = nameObjs[name]
        if obj and textAt(obj) == name then return obj end
        nameObjs[name] = nil
        local game_ = rs:FindFirstChild("Game")
        local holder = game_ and game_:FindFirstChild("ItemConfig")
        local inst = holder and holder:FindFirstChild(name)
        obj = inst and rdPtr(tonumber(inst.Address) + PERF.NERF_NAME)
        if obj and textAt(obj) == name then
            nameObjs[name] = obj
            return obj
        end
        return nil
    end

    local function addRef(obj, delta)
        local r = rdInt(obj + PERF.NERF_REF)
        if not r or r < 1 or r > 1000000 then return false end
        return pcall(memory_write, "int", obj + PERF.NERF_REF, r + delta)
    end

    local function swapName(item, from, to)
        local fromObj, toObj = nameObj(from), nameObj(to)
        local slot = tonumber(item.Address) + PERF.NERF_NAME
        local cur = rdPtr(slot)
        if toObj and cur == toObj then return true end
        if not fromObj or not toObj or cur ~= fromObj or not addRef(toObj, 1) then
            warnOutdated()
            return false
        end
        if not pcall(memory_write, "uintptr_t", slot, toObj) or rdPtr(slot) ~= toObj then
            addRef(toObj, -1)
            return false
        end
        addRef(fromObj, -1)
        return true
    end

    local function isHeld(item)
        local v = item:GetAttribute("InventoryItemLocalEquipped")
        return type(v) == "number" and v % 2 == 1
    end

    _G.JB_NerfSwapped = _G.JB_NerfSwapped or {}
    local swapped = _G.JB_NerfSwapped

    local function apply(item)
        local key = tostring(item.Address)
        local name = item.Name
        local target = PERF.NERF_SWAPS[name]
        if not target or swapped[key] then return false end
        local icon = item:GetAttribute(PERF.NERF_ICON_ATTR) or PERF.NERF_ICONS[name]
        if not swapName(item, name, target) then return false end
        swapped[key] = { name = name, icon = icon }
        pcall(function() item:SetAttribute(PERF.NERF_ICON_ATTR, PERF.NERF_ICONS[target]) end)
        return true
    end

    local function restore(item)
        local key = tostring(item.Address)
        local entry = swapped[key]
        if not entry then return false end
        if not swapName(item, PERF.NERF_SWAPS[entry.name], entry.name) then return false end
        swapped[key] = nil
        pcall(function() item:SetAttribute(PERF.NERF_ICON_ATTR, entry.icon or PERF.NERF_ICONS[entry.name]) end)
        return true
    end

    local function sync(on)
        local folder = lp:FindFirstChild("Folder")
        if not folder then return 0, 0, 0 end
        local done, pending, left = 0, 0, 0
        for _, item in ipairs(folder:GetChildren()) do
            local key = tostring(item.Address)
            local needs = (on and PERF.NERF_SWAPS[item.Name] and not swapped[key]) or (not on and swapped[key])
            if needs then
                if isHeld(item) then
                    pending = pending + 1
                elseif (on and apply(item)) or (not on and restore(item)) then
                    done = done + 1
                else
                    left = left + 1
                end
            end
        end
        return done, pending, left
    end

    while _G.JB_gen == myGen do
        PERF.run("nerfSkins", function()
            local now = tick()
            local toggle = UI.GetValue(uid("nerfSkins")) and true or false
            if toggle ~= wanted then
                wanted = toggle
                changedAt = now
            end
            if wanted ~= wasOn and now - changedAt >= DEBOUNCE then
                wasOn = wanted
                waitNotified = false
                PERF.nerfWarned = false
                notify(wasOn and "Enabled" or "Disabled", PERF.NERF_TITLE, 3)
            end
            if wanted ~= wasOn or wasOn then PERF.nerfIdle = false end
            if not wasOn and PERF.nerfIdle then return end
            local done, pending, left = sync(wasOn)
            if not wasOn and pending == 0 and left == 0 then PERF.nerfIdle = true end
            if done > 0 then
                notify(wasOn and (done .. " weapon(s) set to Nerf") or (done .. " weapon(s) restored"), PERF.NERF_TITLE, 3)
            end
            if pending > 0 and not waitNotified then
                waitNotified = true
                notify(wasOn and "Put the weapon away to apply" or "Put the weapon away to restore", PERF.NERF_TITLE, 3)
            elseif pending == 0 then
                waitNotified = false
            end
        end)
        task.wait(PERF.NERF_TICK)
    end
    local deadline = tick() + PERF.NERF_UNLOAD_WAIT
    while tick() < deadline do
        local _, pending = sync(false)
        if pending == 0 then break end
        task.wait(PERF.NERF_TICK)
    end
end)

task.spawn(function()
    local TITLE = "[JB Hub] Skin Changer"
    local ATTR = "SkinName"
    local lp = game:GetService("Players").LocalPlayer
    local assigned, original, wasOn, lastLabel = {}, {}, false, ""

    local function selection()
        local si = (tonumber(UI.GetValue(uid("skinName"))) or 0) + 1
        local ti = tonumber(UI.GetValue(uid("skinTarget"))) or 0
        return PERF.SKIN_IDS[si], PERF.SKIN_LABELS[si], ti
    end

    local function assign()
        local skin, label, ti = selection()
        if not skin then return end
        if ti == 0 then
            for _, w in ipairs(PERF.SKIN_WEAPONS) do assigned[w] = skin end
        elseif PERF.SKIN_WEAPONS[ti] then
            assigned[PERF.SKIN_WEAPONS[ti]] = skin
        end
        lastLabel = label .. " on " .. (PERF.SKIN_TARGETS[ti + 1] or "?")
    end

    local function isEquipped(item)
        local v = item:GetAttribute("InventoryItemLocalEquipped")
        return type(v) == "number" and v % 2 == 1
    end

    local function setSkin(item, value)
        return pcall(function() item:SetAttribute(ATTR, value) end)
    end

    local function sync(on)
        if not on and next(original) == nil then return 0, 0 end
        local folder = lp:FindFirstChild("Folder")
        if not folder then return 0, 0 end
        local changed, held, alive = 0, 0, {}
        for _, item in ipairs(folder:GetChildren()) do
            local key = tostring(item.Address)
            alive[key] = true
            local want = on and assigned[item.Name] or nil
            local cur = item:GetAttribute(ATTR)
            local did = false
            if want then
                if original[key] == nil then original[key] = { value = cur } end
                if cur ~= want then did = setSkin(item, want) end
            elseif original[key] then
                if cur ~= original[key].value then did = setSkin(item, original[key].value) end
                original[key] = nil
            end
            if did then
                changed = changed + 1
                if isEquipped(item) then held = held + 1 end
            end
        end
        for key in pairs(original) do
            if not alive[key] then original[key] = nil end
        end
        return changed, held
    end

    while _G.JB_gen == myGen do
        PERF.run("skinChanger", function()
            local on = UI.GetValue(uid("skinChanger")) and true or false
            if on ~= wasOn then
                wasOn = on
                if on then
                    assign()
                else
                    assigned = {}
                end
            end
            if PERF.skinApplyRequested then
                PERF.skinApplyRequested = false
                if on then
                    assign()
                else
                    notify("Enable Skin Changer first", TITLE, 3)
                end
            end
            local changed, held = sync(on)
            if changed > 0 then
                local text = on and ("ON - " .. lastLabel) or "OFF - original skins restored"
                if held > 0 then text = text .. " (re-equip to see it)" end
                notify(text, TITLE, 3)
            elseif not on and wasOn == false and changed == 0 and PERF.skinOffNotified == false then
                PERF.skinOffNotified = true
            end
        end)
        task.wait(0.3)
    end
    sync(false)
end)

task.spawn(function()
    local TITLE = "[JB Hub] Punch No Cooldown"
    local CLOSURE_TYPE = 5 -- update
    local CLOSURE_UPVALS = 0x20 -- update
    local UPVAL_VALUE = 0x8 -- update
    local addr, wasOn, lastScan, retryDelay, warned, fails = nil, false, 0, 5, false, 0

    local function rd(t, a)
        local ok, v = pcall(memory_read, t, a)
        if ok and type(v) == "number" then return v end
    end

    local function isPtr(v)
        return v and v > 0x10000000000 and v < 0x7FFFFFFFFFFF
    end

    local function valid(a)
        local d = a and rd("double", a)
        return d ~= nil and (d == 0 or d > 1e9)
    end

    local function scan()
        lastScan = tick()
        for _, e in ipairs(lockedGetgc({ "attemptPunch" })) do
            local closure = rd("uintptr_t", tonumber(e.addr))
            if isPtr(closure) and rd("byte", closure + CLOSURE_TYPE) == 6 then
                local upval = rd("uintptr_t", closure + CLOSURE_UPVALS)
                local valueAddr = isPtr(upval) and rd("uintptr_t", upval + UPVAL_VALUE)
                if isPtr(valueAddr) and rd("int", valueAddr + 12) == 3 then
                    local d = rd("double", valueAddr)
                    if d and (d == 0 or d > 1e9) then return valueAddr end
                end
            end
        end
    end

    while _G.JB_gen == myGen do
        PERF.run("punchNoCd", function()
            local on = UI.GetValue(uid("punchNoCd")) and true or false
            if on ~= wasOn then
                wasOn = on
                if on then
                    retryDelay, lastScan, warned, fails = 5, 0, false, 0
                else
                    if addr then notify("OFF", TITLE, 3) end
                    addr = nil
                end
            end
            if not on then return end
            if addr and not valid(addr) then
                addr, lastScan, retryDelay = nil, 0, 5
            end
            if not addr then
                if tick() - lastScan < retryDelay then return end
                addr = scan()
                if addr then
                    retryDelay, warned, fails = 5, false, 0
                    notify("ON", TITLE, 3)
                else
                    fails = fails + 1
                    retryDelay = math.min(retryDelay * 2, 60)
                    if fails >= 3 and not warned then
                        warned = true
                        PERF.notifySafe("Offsets outdated, wait for JB Hub update ...", TITLE, 5)
                    end
                    return
                end
            end
            local d = rd("double", addr)
            if d and d ~= 0 then pcall(memory_write, "double", addr, 0) end
        end)
        task.wait(UI.GetValue(uid("punchNoCd")) and 0.05 or 0.25)
    end
end)

task.spawn(function()
    local TITLE = "[JB Hub] Rocket Instant Lock"
    local KEY = "SEEKING_LOCK_MIN_DURATION"
    local FAST = 0.01
    local NUMBER_TAG = 3
    local cache, wasOn, lastScan, retryDelay, warned = {}, false, 0, 5, false

    local function rd(t, a)
        local ok, v = pcall(memory_read, t, a)
        if ok and type(v) == "number" then return v end
    end

    local function valid(e)
        return rd("uintptr_t", e.addr + 0x10) == e.keyPtr and rd("int", e.addr + 12) == NUMBER_TAG
    end

    local function restore()
        for _, e in ipairs(cache) do
            if valid(e) then pcall(memory_write, "double", e.addr, e.original) end
        end
        cache = {}
    end

    local function scan()
        lastScan = tick()
        local seen = {}
        for _, e in ipairs(lockedGetgc({ KEY })) do
            local addr = tonumber(e.addr)
            if addr and addr > 4096 and not seen[addr] and tostring(e.key) == KEY then
                local keyPtr = rd("uintptr_t", addr + 0x10)
                local v = rd("double", addr)
                if keyPtr and keyPtr > 4096 and rd("int", addr + 12) == NUMBER_TAG and v and v > FAST and v < 60 then
                    seen[addr] = true
                    cache[#cache + 1] = { addr = addr, keyPtr = keyPtr, original = v }
                end
            end
        end
        return #cache > 0
    end

    while _G.JB_gen == myGen do
        PERF.run("rocketLock", function()
            local on = UI.GetValue(uid("rocketLock")) and true or false
            if on ~= wasOn then
                wasOn = on
                if on then
                    retryDelay, lastScan, warned = 5, 0, false
                else
                    local had = #cache > 0
                    restore()
                    if had then notify("OFF", TITLE, 3) end
                end
            end
            if not on then return end
            if #cache == 0 then
                if tick() - lastScan < retryDelay then return end
                if scan() then
                    retryDelay, warned = 5, false
                    notify("ON", TITLE, 3)
                else
                    retryDelay = math.min(retryDelay * 2, 120)
                    if not warned then
                        warned = true
                        PERF.notifySafe("Offsets outdated, wait for JB Hub update ...", TITLE, 5)
                    end
                    return
                end
            end
            local kept = {}
            for _, e in ipairs(cache) do
                if valid(e) then
                    kept[#kept + 1] = e
                    if rd("double", e.addr) ~= FAST then pcall(memory_write, "double", e.addr, FAST) end
                end
            end
            cache = kept
        end)
        task.wait(0.5)
    end
    restore()
end)

task.spawn(function()
    local TITLE = "[JB Hub] Disable Forcefields"
    local AURA_KEY = "AURA_BLAST_MAX_SIZE"
    local NUMBER_TAG = 3
    local dome, saved, aura = nil, nil, {}
    local wasOn, lastFind, lastAuraScan, auraDelay, warned = false, 0, 0, 5, false

    local function rd(t, a)
        local ok, v = pcall(memory_read, t, a)
        if ok and type(v) == "number" then return v end
    end

    local function findDome()
        lastFind = tick()
        local mil = PERF.ws("MilitaryBase")
        local model = mil and mil:FindFirstChild("Forcefield")
        if not model then return nil end
        local part = model:FindFirstChild("Forcefield")
        if part and part:IsA("BasePart") then return part end
        for _, c in ipairs(model:GetChildren()) do
            if c:IsA("BasePart") then return c end
        end
    end

    local function capture(d)
        local s = { collide = d.CanCollide, transp = d.Transparency, decals = {} }
        for _, c in ipairs(d:GetChildren()) do
            if c.ClassName == "Decal" then s.decals[#s.decals + 1] = { obj = c, transp = c.Transparency } end
        end
        return s
    end

    local function applyDome()
        pcall(function()
            if dome.CanCollide then dome.CanCollide = false end
            if dome.Transparency ~= 1 then dome.Transparency = 1 end
            for _, e in ipairs(saved.decals) do
                if e.obj.Transparency ~= 1 then e.obj.Transparency = 1 end
            end
        end)
    end

    local function auraValid(e)
        return rd("uintptr_t", e.addr + 0x10) == e.keyPtr and rd("int", e.addr + 12) == NUMBER_TAG
    end

    local function scanAura()
        lastAuraScan = tick()
        local seen = {}
        for _, e in ipairs(lockedGetgc({ AURA_KEY })) do
            local addr = tonumber(e.addr)
            if addr and addr > 4096 and not seen[addr] and tostring(e.key) == AURA_KEY then
                local keyPtr = rd("uintptr_t", addr + 0x10)
                local v = rd("double", addr)
                if keyPtr and keyPtr > 4096 and rd("int", addr + 12) == NUMBER_TAG and v and v > 0 and v < 10000 then
                    seen[addr] = true
                    aura[#aura + 1] = { addr = addr, keyPtr = keyPtr, original = v }
                end
            end
        end
        return #aura > 0
    end

    local function applyAura()
        local kept = {}
        for _, e in ipairs(aura) do
            if auraValid(e) then
                kept[#kept + 1] = e
                if rd("double", e.addr) ~= 0 then pcall(memory_write, "double", e.addr, 0) end
            end
        end
        aura = kept
    end

    local function restore()
        if dome and saved then
            pcall(function()
                dome.CanCollide = saved.collide
                dome.Transparency = saved.transp
                for _, e in ipairs(saved.decals) do e.obj.Transparency = e.transp end
            end)
        end
        for _, e in ipairs(aura) do
            if auraValid(e) then pcall(memory_write, "double", e.addr, e.original) end
        end
        dome, saved, aura = nil, nil, {}
    end

    while _G.JB_gen == myGen do
        PERF.run("noForcefield", function()
            local on = UI.GetValue(uid("noForcefield")) and true or false
            if on ~= wasOn then
                wasOn = on
                if on then
                    lastFind, lastAuraScan, auraDelay, warned = 0, 0, 5, false
                    notify("ON", TITLE, 3)
                else
                    local had = dome ~= nil or #aura > 0
                    restore()
                    if had then notify("OFF", TITLE, 3) end
                end
            end
            if not on then return end

            local announce = false
            if dome and not dome.Parent then dome, saved = nil, nil end
            if not dome and tick() - lastFind >= 5 then
                local d = findDome()
                if d then
                    local ok, s = pcall(capture, d)
                    if ok then
                        dome, saved = d, s
                        announce = "Military Base forcefield disabled"
                    end
                end
            end
            local mansion = PERF.ws("MansionRobbery")
            local bossUp = mansion and mansion:FindFirstChild("ActiveBoss") ~= nil
            if #aura == 0 and bossUp and tick() - lastAuraScan >= auraDelay then
                if scanAura() then
                    auraDelay = 5
                    announce = "Mansion CEO aura blast disabled"
                else
                    auraDelay = math.min(auraDelay * 2, 120)
                end
            end

            if dome then applyDome() end
            if #aura > 0 then applyAura() end

            if announce then notify(announce, TITLE, 3) end
        end)
        task.wait(0.5)
    end
    restore()
end)

task.spawn(function()
    local TITLE = "[JB Hub] Hit Sound"
    local ORIGINAL = 2837091387
    local CLOSURE_PROTO = 0x18 -- update
    local PROTO_CONSTANTS = 0x28 -- update
    local RETRY, retryDelay = 10, 10
    local slots, wasOn, current, lastScan = {}, false, nil, 0

    local known = { [ORIGINAL] = true }
    for _, s in ipairs(PERF.HIT_SOUNDS) do known[s[2]] = true end

    local function rd(a)
        local ok, v = pcall(memory_read, "uintptr_t", a)
        if ok and type(v) == "number" and v > 0x10000 and v < 0x7FFFFFFFFFFF then return v end
    end

    local function readSlot(s)
        local ok, v = pcall(memory_read, "double", s)
        return ok and v or nil
    end

    local function scan()
        slots, lastScan = {}, tick()
        for _, e in ipairs(lockedGetgc({ "BulletEmitterOnLocalHitPlayer" })) do
            local a = tonumber(e.addr)
            local closure = a and rd(a)
            local proto = closure and rd(closure + CLOSURE_PROTO)
            local k = proto and rd(proto + PROTO_CONSTANTS)
            if k then
                for i = 0, 63 do
                    if known[readSlot(k + i * 16)] then
                        slots[#slots + 1] = k + i * 16
                        break
                    end
                end
            end
        end
        return #slots > 0
    end

    local function write(id)
        local kept = {}
        for _, s in ipairs(slots) do
            if known[readSlot(s)] and pcall(memory_write, "double", s, id) then kept[#kept + 1] = s end
        end
        slots = kept
        return #kept
    end

    local function selected()
        local i = (tonumber(UI.GetValue(uid("hitSoundName"))) or 0) + 1
        local s = PERF.HIT_SOUNDS[i] or PERF.HIT_SOUNDS[1]
        return s[2], s[1]
    end

    while _G.JB_gen == myGen do
        PERF.run("hitSound", function()
            local on = UI.GetValue(uid("hitSound")) and true or false
            if on ~= wasOn then
                wasOn = on
                PERF.hitWarned = false
                if not on then
                    write(ORIGINAL)
                    current = nil
                    notify("OFF", TITLE, 3)
                end
            end
            if not on then return end
            if #slots == 0 and tick() - lastScan >= retryDelay then
                if scan() then
                    retryDelay = RETRY
                else
                    retryDelay = math.min(retryDelay * 2, 300)
                    if not PERF.hitWarned then
                        PERF.hitWarned = true
                        PERF.notifySafe("Offsets outdated, wait for JB Hub update ...", TITLE, 5)
                    end
                end
            end
            if #slots == 0 then return end
            local id, label = selected()
            if id ~= current then
                if write(id) > 0 then
                    current = id
                    notify("ON - " .. label, TITLE, 3)
                else
                    current = nil
                end
            end
        end)
        task.wait(0.5)
    end
    write(ORIGINAL)
end)

task.spawn(function()
    local TITLE = "[JB Hub] Hit Markers"
    local P = game:GetService("Players")
    local lp = P.LocalPlayer
    local cam = workspace.CurrentCamera
    local DUR, TH = 0.38, 2
    local cfg = { marker = "Cross", kill = true }
    local COL, SHADOW = {}, {}
    for k, c in pairs({ hit = { 255, 255, 255 }, head = { 255, 196, 60 }, kill = { 255, 70, 70 }, gold = { 255, 255, 85 }, white = { 255, 255, 255 } }) do
        COL[k] = Color3.fromRGB(c[1], c[2], c[3])
        SHADOW[k] = Color3.fromRGB(math.floor(c[1] / 4), math.floor(c[2] / 4), math.floor(c[3] / 4))
    end
    local BLACK = Color3.fromRGB(0, 0, 0)

    local objs = {}
    local function new(kind, props)
        local d = Drawing.new(kind)
        for k, v in pairs(props) do pcall(function() d[k] = v end) end
        d.Visible = false
        objs[#objs + 1] = d
        return d
    end

    local GLYPH_SRC = {
        ["A"] = ".###./#...#/#...#/#####/#...#/#...#/#...#", ["B"] = "####./#...#/####./#...#/#...#/#...#/####.",
        ["C"] = ".###./#...#/#..../#..../#..../#...#/.###.", ["D"] = "####./#...#/#...#/#...#/#...#/#...#/####.",
        ["E"] = "#####/#..../###../#..../#..../#..../#####", ["F"] = "#####/#..../###../#..../#..../#..../#....",
        ["G"] = ".####/#..../#..##/#...#/#...#/#...#/.####", ["H"] = "#...#/#...#/#####/#...#/#...#/#...#/#...#",
        ["I"] = "###/.#./.#./.#./.#./.#./###", ["J"] = "....#/....#/....#/....#/....#/#...#/.###.",
        ["K"] = "#...#/#..#./###../#..#./#...#/#...#/#...#", ["L"] = "#..../#..../#..../#..../#..../#..../#####",
        ["M"] = "#...#/##.##/#.#.#/#...#/#...#/#...#/#...#", ["N"] = "#...#/##..#/#.#.#/#..##/#...#/#...#/#...#",
        ["O"] = ".###./#...#/#...#/#...#/#...#/#...#/.###.", ["P"] = "####./#...#/####./#..../#..../#..../#....",
        ["Q"] = ".###./#...#/#...#/#...#/#...#/#..#./.##.#", ["R"] = "####./#...#/####./#...#/#...#/#...#/#...#",
        ["S"] = ".####/#..../.###./....#/....#/#...#/.###.", ["T"] = "#####/..#../..#../..#../..#../..#../..#..",
        ["U"] = "#...#/#...#/#...#/#...#/#...#/#...#/.###.", ["V"] = "#...#/#...#/#...#/#...#/#...#/.#.#./..#..",
        ["W"] = "#...#/#...#/#...#/#...#/#.#.#/##.##/#...#", ["X"] = "#...#/.#.#./..#../.#.#./#...#/#...#/#...#",
        ["Y"] = "#...#/.#.#./..#../..#../..#../..#../..#..", ["Z"] = "#####/....#/...#./..#../.#.../#..../#####",
        ["0"] = ".###./#...#/#..##/#.#.#/##..#/#...#/.###.", ["1"] = "..#../.##../..#../..#../..#../..#../#####",
        ["2"] = ".###./#...#/....#/..##./.#.../#...#/#####", ["3"] = ".###./#...#/....#/..##./....#/#...#/.###.",
        ["4"] = "...##/..#.#/.#..#/#...#/#####/....#/....#", ["5"] = "#####/#..../####./....#/....#/#...#/.###.",
        ["6"] = "..##./.#.../#..../####./#...#/#...#/.###.", ["7"] = "#####/#...#/....#/...#./..#../..#../..#..",
        ["8"] = ".###./#...#/#...#/.###./#...#/#...#/.###.", ["9"] = ".###./#...#/#...#/.####/....#/...#./.##..",
        ["a"] = "...../...../.###./....#/.####/#...#/.####", ["b"] = "#..../#..../#.##./##..#/#...#/#...#/####.",
        ["c"] = "...../...../.###./#...#/#..../#...#/.###.", ["d"] = "....#/....#/.##.#/#..##/#...#/#...#/.####",
        ["e"] = "...../...../.###./#...#/#####/#..../.####", ["f"] = "..##/.#../####/.#../.#../.#../.#..",
        ["g"] = "...../...../.####/#...#/#...#/.####/....#/####.", ["h"] = "#..../#..../#.##./##..#/#...#/#...#/#...#", ["i"] = "#/./#/#/#/#/#",
        ["j"] = "....#/...../....#/....#/....#/....#/#...#/.###.", ["k"] = "#.../#.../#..#/#.#./##../#.#./#..#", ["l"] = "#./#./#./#./#./#./.#",
        ["m"] = "...../...../##.#./#.#.#/#.#.#/#...#/#...#", ["n"] = "...../...../####./#...#/#...#/#...#/#...#",
        ["o"] = "...../...../.###./#...#/#...#/#...#/.###.", ["p"] = "...../...../#.##./##..#/#...#/####./#..../#....",
        ["q"] = "...../...../.##.#/#..##/#...#/.####/....#/....#", ["r"] = "...../...../#.##./##..#/#..../#..../#....",
        ["s"] = "...../...../.####/#..../.###./....#/####.", ["t"] = ".#../.#../####/.#../.#../.#../..##",
        ["u"] = "...../...../#...#/#...#/#...#/#...#/.####", ["v"] = "...../...../#...#/#...#/#...#/.#.#./..#..",
        ["w"] = "...../...../#...#/#...#/#.#.#/#.#.#/.####", ["x"] = "...../...../#...#/.#.#./..#../.#.#./#...#",
        ["y"] = "...../...../#...#/#...#/#...#/.####/....#/####.", ["z"] = "...../...../#####/...#./..#../.#.../#####",
        [" "] = ".../.../.../.../.../.../...", ["."] = "././././././#", ["!"] = "#/#/#/#/#/./#",
        ["_"] = "...../...../...../...../...../...../...../#####", ["-"] = "...../...../...../#####/...../...../.....",
        ["+"] = "...../..#../..#../#####/..#../..#../.....", ["?"] = ".###./#...#/....#/...#./..#../...../..#.."
    }
    local GLYPH = {}
    for ch, src in pairs(GLYPH_SRC) do
        local rows = {}
        for r in src:gmatch("[^/]+") do rows[#rows + 1] = r end
        local runs = {}
        for y, r in ipairs(rows) do
            local x = 1
            while x <= #r do
                if r:sub(x, x) == "#" then
                    local s0 = x
                    while x <= #r and r:sub(x, x) == "#" do x = x + 1 end
                    local merged = false
                    for _, m in ipairs(runs) do
                        if m[1] == s0 - 1 and m[3] == x - s0 and m[2] + m[4] == y - 1 then
                            m[4] = m[4] + 1
                            merged = true
                            break
                        end
                    end
                    if not merged then runs[#runs + 1] = { s0 - 1, y - 1, x - s0, 1 } end
                else
                    x = x + 1
                end
            end
        end
        GLYPH[ch] = { w = #rows[1], runs = runs }
    end

    local function label()
        return { str = "", sq = {}, sh = {}, runs = {}, pw = 0 }
    end

    local function build(o)
        o.pstr = o.str
        local runs, cx = {}, 0
        for ch in o.str:gmatch(".") do
            local g = GLYPH[ch] or GLYPH["?"]
            for _, r in ipairs(g.runs) do runs[#runs + 1] = { cx + r[1], r[2], r[3], r[4] } end
            cx = cx + g.w + 1
        end
        o.runs, o.pw = runs, math.max(cx - 1, 0)
        for i = #o.sq + 1, #runs do
            o.sh[i] = new("Square", { Filled = true, Transparency = 1, ZIndex = 65 })
            o.sq[i] = new("Square", { Filled = true, Transparency = 1, ZIndex = 66 })
        end
        for i = #runs + 1, #o.sq do o.sq[i].Visible = false o.sh[i].Visible = false end
        o.key, o.col, o.a, o.vis = nil, nil, nil, false
    end

    local function hide(o)
        if o.vis then
            for i = 1, #o.sq do o.sq[i].Visible = false o.sh[i].Visible = false end
            o.vis = false
        end
    end

    local function draw(o, x, y, size, ck, a)
        a = math.floor(a * 20 + 0.5) / 20
        if o.pstr ~= o.str then build(o) end
        local u = math.max(1, math.floor(size / 8 + 0.5))
        local x0, y0 = math.floor(x - o.pw * u / 2 + 0.5), math.floor(y - 4 * u + 0.5)
        local key = x0 * 100000 + y0 * 10 + u
        local moved, recol, refade = key ~= o.key, o.col ~= ck, o.a ~= a
        for i, r in ipairs(o.runs) do
            local q, h = o.sq[i], o.sh[i]
            if moved then
                q.Position = Vector2.new(x0 + r[1] * u, y0 + r[2] * u)
                q.Size = Vector2.new(r[3] * u, r[4] * u)
                h.Position = Vector2.new(x0 + (r[1] + 1) * u, y0 + (r[2] + 1) * u)
                h.Size = Vector2.new(r[3] * u, r[4] * u)
            end
            if recol then q.Color = COL[ck] h.Color = SHADOW[ck] end
            if refade then q.Transparency = a h.Transparency = a end
            if not o.vis then q.Visible = true h.Visible = true end
        end
        o.key, o.col, o.a, o.vis = key, ck, a, true
    end

    local lines, shades = {}, {}
    for i = 1, 4 do
        shades[i] = new("Line", { Color = BLACK, Thickness = TH + 2, Transparency = 1, ZIndex = 60 })
        lines[i] = new("Line", { Thickness = TH, Transparency = 1, ZIndex = 61 })
    end
    local burst = new("Circle", { Filled = false, NumSides = 48, Thickness = TH, Transparency = 1, ZIndex = 61 })
    local line1, line2 = label(), label()
    local pool = {}
    for i = 1, 12 do pool[i] = { l = label(), live = false, t0 = 0 } end

    local mouse
    pcall(function() mouse = lp:GetMouse() end)
    local function anchor()
        if mouse then
            local ok, x, y = pcall(function() return mouse.X, mouse.Y end)
            if ok and type(x) == "number" then return x, y end
        end
        local v = cam.ViewportSize
        return v.X / 2, v.Y / 2
    end

    local function out3(x) return 1 - (1 - x) ^ 3 end
    local function clamp(x) return x < 0 and 0 or (x > 1 and 1 or x) end
    local function ascii(s) return (tostring(s or ""):gsub("[^\32-\126]", "")) end
    local DIAG = { { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }

    local mk = { t0 = -1, kind = "hit" }
    local banner = { t0 = -1, streak = 0, last = -10 }
    local shownMarker = false

    local function myName()
        local ok, d = pcall(function() return lp.DisplayName end)
        local n = ok and ascii(d) or ""
        if n == "" then n = ascii(lp.Name) end
        return n
    end

    local function fire(kind, dmg, name)
        local now = tick()
        if cfg.show then
            if not (mk.kind == "kill" and kind ~= "kill" and now - mk.t0 < DUR * 1.8) then mk.kind = kind end
            mk.t0 = now
        end
        if cfg.show and dmg and dmg > 0 then
            local slot
            for _, p in ipairs(pool) do if not p.live then slot = p break end end
            if not slot then
                slot = pool[1]
                for _, p in ipairs(pool) do if p.t0 < slot.t0 then slot = p end end
            end
            local a = math.rad(math.random(-75, -15))
            slot.live, slot.t0, slot.kind, slot.dx, slot.dy = true, now, kind, math.cos(a), math.sin(a)
            slot.l.str = tostring(math.floor(dmg + 0.5))
        end
        if kind == "kill" and cfg.kill then
            banner.streak = now - banner.last < 5 and banner.streak + 1 or 1
            banner.last, banner.t0 = now, now
            local target = ascii(name)
            if target == "" then target = "Player" end
            line1.str = target .. " was slain by " .. myName()
            local streaks = { "", "Double Kill!", "Triple Kill!" }
            line2.str = streaks[banner.streak] or ("Killing Spree x" .. banner.streak)
        end
    end

    local function drawMarker(now, ax, ay)
        local kind, rust = mk.kind, cfg.marker == "Rust"
        local D = DUR * (kind == "kill" and 1.8 or 1) * (rust and 0.7 or 1)
        local t = now - mk.t0
        if mk.t0 < 0 or t > D then
            if shownMarker then
                for i = 1, 4 do lines[i].Visible = false shades[i].Visible = false end
                burst.Visible = false
                shownMarker = false
            end
            return
        end
        shownMarker = true
        local col = COL[kind]
        local th = TH + (kind == "kill" and 1 or 0) - (rust and 1 or 0)
        local alpha = t < D * 0.45 and 1 or clamp(1 - (t - D * 0.45) / (D * 0.55))
        local pop = rust and 0 or (kind == "kill" and 0.8 or 0.55)
        local z = (1 + pop * (1 - out3(clamp(t / (D * 0.22))))) * (kind == "kill" and 1.3 or 1)
        local g, l = 7 * z, 9 * z
        if rust then g, l = 3 * z, 5 * z end
        for i, v in ipairs(DIAG) do
            local f = Vector2.new(ax + v[1] * g * 0.7071, ay + v[2] * g * 0.7071)
            local e = Vector2.new(ax + v[1] * (g + l) * 0.7071, ay + v[2] * (g + l) * 0.7071)
            local L, Sh = lines[i], shades[i]
            Sh.From, Sh.To, Sh.Thickness, Sh.Transparency, Sh.Visible = f, e, th + 2, alpha * 0.55, true
            L.From, L.To, L.Thickness, L.Color, L.Transparency, L.Visible = f, e, th, col, alpha, true
        end
        --if kind == "kill" then
        --    local q = clamp(t / (D * 0.8))
        --    burst.Position, burst.Radius, burst.Color = Vector2.new(ax, ay), 10 + 26 * out3(q), col
        --    burst.Transparency, burst.Visible = clamp(1 - q), q < 1
        --elseif burst.Visible then
        --    burst.Visible = false
        --end
    end

    local function drawTexts(now, ax, ay)
        for _, p in ipairs(pool) do
            if p.live then
                local t = now - p.t0
                local life = p.kind == "kill" and 1.1 or 0.85
                if t > life then
                    p.live = false
                    hide(p.l)
                else
                    local k = t / life
                    local base = p.kind == "kill" and 22 or (p.kind == "head" and 20 or 17)
                    local r = 26 + 22 * out3(k)
                    draw(p.l, ax + p.dx * r, ay + p.dy * r, base * (1 + 0.5 * (1 - out3(clamp(t / 0.12)))), p.kind, k < 0.55 and 1 or clamp(1 - (k - 0.55) / 0.45))
                end
            end
        end
        local t = now - banner.t0
        if banner.t0 < 0 or t > 2.6 or not cfg.kill then
            hide(line1)
            hide(line2)
            return
        end
        local a = (t < 2.2 and 1 or clamp(1 - (t - 2.2) / 0.4)) * clamp(t / 0.08)
        local vp = cam.ViewportSize
        local kx, ky = math.floor(vp.X / 2), math.floor(vp.Y * 0.68)
        draw(line1, kx, ky, 16, "white", a)
        if line2.str ~= "" then draw(line2, kx, ky + 22, 16, "gold", a) else hide(line2) end
    end

    local counts = {}
    local function headshot(delta)
        local w = "?"
        local c = lp.Character
        if c then for _, x in ipairs(c:GetChildren()) do if x.ClassName == "Tool" then w = x.Name break end end end
        if w:lower():find("shotgun") then return false end
        local m = counts[w]
        if not m then m = {} counts[w] = m end
        local key = math.floor(delta + 0.5)
        m[key] = (m[key] or 0) + 1
        local mode, best, total = nil, 0, 0
        for k, v in pairs(m) do
            total = total + v
            if v > best then mode, best = k, v end
        end
        return total >= 2 and mode and key >= mode * 1.4
    end

    local track, ready, lastPrune = {}, false, 0
    local function scan(now)
        local list = {}
        for _, pl in ipairs(P:GetPlayers()) do
            if pl ~= lp and pl.Character then list[#list + 1] = { pl.Character, pl.DisplayName or pl.Name } end
        end
        pcall(function()
            for _, m in ipairs(game:GetService("CollectionService"):GetTagged(GUARD_TAG)) do list[#list + 1] = { m, "Guard" } end
        end)
        for _, e in ipairs(list) do
            local model, name = e[1], e[2]
            pcall(function()
                local key = model.Address
                local st = track[key]
                local hrp = model:FindFirstChild("HumanoidRootPart")
                local hum = model:FindFirstChild("Humanoid")
                local bb = hrp and hrp:FindFirstChild("DamageBillboard")
                local tl = bb and bb:FindFirstChild("TextLabel")
                local n = tl and tonumber(tl.Text)
                local hp = hum and hum.Health or 100
                if not st then
                    st = { bb = bb and bb.Address, n = n or 0, hitT = -10, dead = hp <= 0 }
                    track[key] = st
                    if not ready then st.seen = now return end
                end
                st.seen = now
                local delta
                if bb and n then
                    local id = bb.Address
                    if id ~= st.bb then delta = n st.bb = id
                    elseif n > st.n then delta = n - st.n end
                    st.n = n
                elseif not bb then
                    st.bb, st.n = nil, 0
                end
                if hp > 0 then st.dead = false end
                if delta and delta > 0 then
                    st.hitT = now
                    local kind = headshot(delta) and "head" or "hit"
                    if hp <= 0 and not st.dead then kind = "kill" st.dead = true end
                    fire(kind, delta, name)
                elseif hp <= 0 and not st.dead and now - st.hitT < 1 then
                    st.dead = true
                    fire("kill", 0, name)
                end
            end)
        end
        ready = true
        if now - lastPrune > 5 then
            lastPrune = now
            for k, st in pairs(track) do if now - st.seen > 5 then track[k] = nil end end
        end
    end

    local wasOn, lastRefresh, linger = false, 0, false
    local wasMarker, wasKill = false, false
    while _G.JB_gen == myGen do
        local now = tick()
        local markerOn = UI.GetValue(uid("hitMarker")) and true or false
        local killOn = UI.GetValue(uid("hitKill")) and true or false
        if markerOn ~= wasMarker then
            wasMarker = markerOn
            notify(markerOn and "ON" or "OFF", TITLE, 3)
        end
        if killOn ~= wasKill then
            wasKill = killOn
            notify(killOn and "ON" or "OFF", "[JB Hub] Kill Message", 3)
        end
        local on = markerOn or killOn
        if on ~= wasOn then
            wasOn = on
            if on then ready, track = false, {} end
        end
        if on or linger then
            if now - lastRefresh > 0.2 then
                lastRefresh = now
                cfg.marker = PERF.HITFX_MARKERS[(tonumber(UI.GetValue(uid("hitMarkerStyle"))) or 0) + 1] or "Cross"
                cfg.kill = UI.GetValue(uid("hitKill")) and true or false
                cfg.show = UI.GetValue(uid("hitMarker")) and true or false
            end
            PERF.run("hitMarker", function()
                if on then scan(now) end
                local ax, ay = anchor()
                drawMarker(now, ax, ay)
                drawTexts(now, ax, ay)
            end)
            linger = now - math.max(mk.t0, banner.t0) < 3
            if not on and not linger then
                for _, o in ipairs(objs) do pcall(function() o.Visible = false end) end
                for _, p in ipairs(pool) do p.live = false p.l.vis = false end
                line1.vis, line2.vis, mk.t0, banner.t0 = false, false, -1, -1
            end
            task.wait(PERF.FRAME)
        else
            task.wait(0.25)
        end
    end
    for _, o in ipairs(objs) do pcall(function() o:Remove() end) end
end)

task.spawn(function()
    local targets, saved, decoyPtr = {}, {}, nil
    local wasOn = false
    local lastCheck = 0

    local function resolveKey()
        if PERF.stunKeyResolved then return end
        local lp = game:GetService("Players").LocalPlayer
        local list = {}
        local ps = lp:FindFirstChild("PlayerScripts")
        if ps and ps:FindFirstChild("LocalScript") then list[#list + 1] = ps.LocalScript end
        local sp = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
        if sp and sp:FindFirstChild("LocalScript") then list[#list + 1] = sp.LocalScript end
        for _, script in ipairs(list) do
            local ok, src = pcall(decompile, script)
            if ok and type(src) == "string" then
                local at = src:find("= p%d+ or [%w_]+%.Time%.Stunned") or src:find("Time.Stunned", 1, true)
                if at then
                    local key
                    for k in src:sub(math.max(1, at - 600), at):gmatch("function [%w_]+%.([%w_]+)%(") do key = k end
                    if key then
                        PERF.TASER_STUN_KEY = key
                        PERF.stunKeyResolved = true
                        return
                    end
                end
            end
        end
    end

    local function scan()
        pcall(resolveKey)
        targets, saved, decoyPtr = {}, {}, nil
        local found, decoys = {}, {}
        for _, e in ipairs(lockedGetgc({ PERF.TASER_STUN_KEY, PERF.TASER_DECOY_KEY })) do
            local a = tonumber(e.addr)
            local k = tostring(e.key)
            if a then
                if k == PERF.TASER_STUN_KEY then
                    found[#found + 1] = a
                elseif k == PERF.TASER_DECOY_KEY then
                    decoys[#decoys + 1] = a
                end
            end
        end
        if #found == 0 or #decoys == 0 then return false end
        local okd, ptr = pcall(memory_read, "uintptr_t", decoys[1] + PERF.TASER_KEY_PTR)
        if not okd or not ptr or ptr < 4096 then return false end
        decoyPtr = ptr
        for _, a in ipairs(found) do
            local ok, p = pcall(memory_read, "uintptr_t", a + PERF.TASER_KEY_PTR)
            if ok and p and p > 4096 and p ~= decoyPtr then
                targets[#targets + 1] = a
                saved[#saved + 1] = p
            end
        end
        return #targets > 0
    end

    local function patch()
        local n = 0
        for i, a in ipairs(targets) do
            pcall(memory_write, "uintptr_t", a + PERF.TASER_KEY_PTR, decoyPtr)
            local ok, now = pcall(memory_read, "uintptr_t", a + PERF.TASER_KEY_PTR)
            if ok and now == decoyPtr then n = n + 1 end
        end
        return n
    end

    local function restore()
        local n = 0
        for i, a in ipairs(targets) do
            local ok, now = pcall(memory_read, "uintptr_t", a + PERF.TASER_KEY_PTR)
            if ok and now == decoyPtr then
                pcall(memory_write, "uintptr_t", a + PERF.TASER_KEY_PTR, saved[i])
                n = n + 1
            end
        end
        targets, saved = {}, {}
        return n
    end

    while _G.JB_gen == myGen do
        PERF.run("antiTaser", function()
            local on = UI.GetValue(uid("antiTaser")) and true or false
            if on ~= wasOn then
                wasOn = on
                if on then
                    if scan() then
                        notify("Enabled, " .. patch() .. "/" .. #targets .. " handler(s) blocked", PERF.TASER_TITLE, 3)
                    else
                        PERF.notifySafe("Stun handler not found, wait for JB Hub update ...", PERF.TASER_TITLE, 4)
                    end
                    lastCheck = tick()
                else
                    notify("Disabled, " .. restore() .. " handler(s) restored", PERF.TASER_TITLE, 3)
                end
            end
            if on and #targets > 0 and tick() - lastCheck >= PERF.TASER_CHECK then
                lastCheck = tick()
                for i, a in ipairs(targets) do
                    local ok, now = pcall(memory_read, "uintptr_t", a + PERF.TASER_KEY_PTR)
                    if ok and now == saved[i] then
                        pcall(memory_write, "uintptr_t", a + PERF.TASER_KEY_PTR, decoyPtr)
                    end
                end
            end
        end)
        task.wait(0.25)
    end
    restore()
end)

task.spawn(function()
    local lighting = game:GetService("Lighting")
    local atmosOriginal = {}
    local skyWas, skyIndex, lastReapply = false, -1, 0

    local function atmosAddress()
        local a = lighting:FindFirstChildOfClass("Atmosphere")
        return a and tonumber(a.Address)
    end

    local function readAtmos(a)
        local t = {}
        for name, off in pairs(PERF.ATMOS) do
            local n = (name == "Color" or name == "Decay") and 3 or 1
            t[name] = {}
            for i = 0, n - 1 do t[name][i + 1] = memory_read("float", a + off + i * 4) end
        end
        return t
    end

    local function writeAtmos(a, set)
        for name, off in pairs(PERF.ATMOS) do
            local v = set[name]
            if v ~= nil then
                if type(v) == "number" then v = { v } end
                for i, x in ipairs(v) do memory_write("float", a + off + (i - 1) * 4, x) end
            end
        end
    end

    local function applySky(preset)
        local a = atmosAddress()
        if not a then return false end
        if not atmosOriginal[a] then atmosOriginal[a] = readAtmos(a) end
        writeAtmos(a, preset or atmosOriginal[a])
        return true
    end

    pcall(applySky, nil)

    while _G.JB_gen == myGen do
        PERF.run("skyColor", function()
            if PERF.timeOn or PERF.matrixOn then lastReapply = 0 return end
            local skyOn = UI.GetValue(uid("skyColor")) and true or false
            local idx = (tonumber(UI.GetValue(uid("skyColorPreset"))) or 0) + 1
            local dirty = false
            if skyOn ~= skyWas then
                skyWas, skyIndex, dirty = skyOn, idx, true
                notify(skyOn and ("Enabled, " .. (PERF.SKY_NAMES[idx] or "?")) or "Disabled, original sky restored", PERF.SKY_TITLE, 3)
            elseif skyOn and idx ~= skyIndex then
                skyIndex, dirty = idx, true
                notify("Color: " .. (PERF.SKY_NAMES[idx] or "?"), PERF.SKY_TITLE, 2)
            end
            local now = tick()
            if dirty or (skyOn and now - lastReapply >= PERF.WORLD_REAPPLY) then
                lastReapply = now
                applySky(skyOn and PERF.SKY_PRESETS[idx] or nil)
            end
        end)
        task.wait(PERF.WORLD_TICK)
    end

    pcall(applySky, nil)
end)

task.spawn(function()
    local TITLE = "[JB Hub] Water Customizer"
    local OFF = PERF.WATER_OFF
    local saved, wasOn, lastColor, lastSea, lastApply = {}, false, -1, -1, 0

    local terrainCache, terrainAt = nil, 0
    local function terrainAddr()
        if terrainCache and tick() - terrainAt < 10 then return terrainCache end
        local t = workspace:FindFirstChildOfClass("Terrain")
        terrainCache, terrainAt = t and tonumber(t.Address), tick()
        return terrainCache
    end

    local function rf(a)
        local ok, v = pcall(memory_read, "float", a)
        return ok and v or nil
    end

    local function wf(a, v)
        if v then pcall(memory_write, "float", a, v) end
    end

    local function save(t)
        if saved[t] then return saved[t] end
        saved[t] = {
            color = { rf(t + OFF.Color), rf(t + OFF.Color + 4), rf(t + OFF.Color + 8) },
            transparency = rf(t + OFF.Transparency),
            reflectance = rf(t + OFF.Reflectance),
            waveSize = rf(t + OFF.WaveSize),
            waveSpeed = rf(t + OFF.WaveSpeed),
        }
        return saved[t]
    end

    local function seaValues(sea)
        local s = math.clamp(sea / 100, 0, 1)
        return s, (s ^ 1.5) * 100
    end

    local function apply(t, colorIdx, sea)
        local o = save(t)
        local p = PERF.WATER_PRESETS[colorIdx] or o
        local c = p.color or o.color
        wf(t + OFF.Color, c[1])
        wf(t + OFF.Color + 4, c[2])
        wf(t + OFF.Color + 8, c[3])
        wf(t + OFF.Transparency, p.transparency or o.transparency)
        wf(t + OFF.Reflectance, p.reflectance or o.reflectance)
        local size, speed = seaValues(sea)
        wf(t + OFF.WaveSize, size)
        wf(t + OFF.WaveSpeed, speed)
    end

    local function restore()
        for t, o in pairs(saved) do
            wf(t + OFF.Color, o.color[1])
            wf(t + OFF.Color + 4, o.color[2])
            wf(t + OFF.Color + 8, o.color[3])
            wf(t + OFF.Transparency, o.transparency)
            wf(t + OFF.Reflectance, o.reflectance)
            wf(t + OFF.WaveSize, o.waveSize)
            wf(t + OFF.WaveSpeed, o.waveSpeed)
        end
    end

    while _G.JB_gen == myGen do
        PERF.run("waterCustom", function()
            if PERF.matrixOn then lastApply = 0 return end
            local on = UI.GetValue(uid("waterCustom")) and true or false
            if not on and not wasOn then return end
            local colorIdx = (tonumber(UI.GetValue(uid("waterColor"))) or 0) + 1
            local sea = tonumber(UI.GetValue(uid("waterSea"))) or 32
            local t = terrainAddr()
            if not t then return end
            local now = tick()
            if on ~= wasOn then
                wasOn = on
                if on then
                    apply(t, colorIdx, sea)
                    notify("ON - " .. (PERF.WATER_NAMES[colorIdx] or "?") .. ", sea " .. sea, TITLE, 3)
                else
                    restore()
                    notify("OFF - original water restored", TITLE, 3)
                end
                lastColor, lastSea, lastApply = colorIdx, sea, now
                return
            end
            if not on then return end
            if colorIdx ~= lastColor then
                notify("Color: " .. (PERF.WATER_NAMES[colorIdx] or "?"), TITLE, 2)
            end
            if colorIdx ~= lastColor or sea ~= lastSea or now - lastApply >= PERF.WORLD_REAPPLY then
                lastColor, lastSea, lastApply = colorIdx, sea, now
                apply(t, colorIdx, sea)
            end
        end)
        task.wait(PERF.WORLD_TICK)
    end
    restore()
end)

task.spawn(function()
    local TC = PERF.TIME
    local lighting = game:GetService("Lighting")
    local sunSaved, moodSaved = {}, {}
    local wasOn, cycleHour, lastPreset, lastT, addrAt = false, nil, -1, tick(), 0
    local lightAddr, atmosAddr, ccAddr
    local guard = { on = false, vecs = {}, s = 0 }

    local function rf(a)
        local ok, v = pcall(memory_read, "float", a)
        return ok and v or nil
    end

    local function wf(a, v)
        if a and v then pcall(memory_write, "float", a, v) end
    end

    local function addrOf(inst)
        local ok, a = pcall(function() return tonumber(inst.Address) end)
        return ok and a or nil
    end

    local function refreshAddrs()
        if tick() - addrAt < 2 and lightAddr then return end
        addrAt = tick()
        lightAddr, atmosAddr, ccAddr = addrOf(lighting), nil, nil
        for _, c in ipairs(lighting:GetChildren()) do
            if not atmosAddr and c.ClassName == "Atmosphere" then atmosAddr = addrOf(c) end
            if not ccAddr and c.ClassName == "ColorCorrectionEffect" then ccAddr = addrOf(c) end
        end
    end

    local function lerp(a, b, t) return a + (b - a) * t end

    local function moodAt(h)
        h = h % 24
        for i = 1, #TC.KEYS - 1 do
            local k1, k2 = TC.KEYS[i], TC.KEYS[i + 1]
            if h >= k1.h and h <= k2.h then
                local t = (h - k1.h) / (k2.h - k1.h)
                local m = { bright = lerp(k1.bright, k2.bright, t), density = lerp(k1.density, k2.density, t), haze = lerp(k1.haze, k2.haze, t), tint = {}, color = {}, decay = {} }
                for j = 1, 3 do
                    m.tint[j] = lerp(k1.tint[j], k2.tint[j], t)
                    m.color[j] = lerp(k1.color[j], k2.color[j], t)
                    m.decay[j] = lerp(k1.decay[j], k2.decay[j], t)
                end
                return m
            end
        end
        return TC.KEYS[1]
    end

    local function saveBlock(store, a, first, count)
        if not a or store[a] then return end
        local t = {}
        for i = 0, count - 1 do t[i] = rf(a + first + i * 4) end
        store[a] = { first = first, values = t }
    end

    local function restoreStore(store)
        for a, s in pairs(store) do
            for i, v in pairs(s.values) do wf(a + s.first + i * 4, v) end
        end
    end

    task.spawn(function()
        while _G.JB_gen == myGen do
            if guard.on and lightAddr then
                for _, v in ipairs(guard.vecs) do
                    local a = lightAddr + v[1]
                    local cx, cy = rf(a), rf(a + 4)
                    if not cx or not cy or math.abs(cx - v[2]) > 0.0005 or math.abs(cy - v[3]) > 0.0005 then
                        wf(a, v[2]) wf(a + 4, v[3]) wf(a + 8, v[4])
                    end
                end
                local ok, b = pcall(memory_read, "byte", lightAddr + TC.SOURCE)
                if ok and b ~= guard.s then pcall(memory_write, "byte", lightAddr + TC.SOURCE, guard.s) end
                task.wait()
            else
                task.wait(PERF.WORLD_TICK)
            end
        end
    end)

    local function restoreAll()
        guard.on = false
        restoreStore(sunSaved)
        restoreStore(moodSaved)
        sunSaved, moodSaved = {}, {}
    end

    local function writeVec(off, x, y, z)
        saveBlock(sunSaved, lightAddr + off, 0, 3)
        wf(lightAddr + off, x) wf(lightAddr + off + 4, y) wf(lightAddr + off + 8, z)
    end

    local function apply(h)
        local th = (h - 6) / 12 * math.pi
        local x, y, z = math.cos(th), math.sin(th), TC.TILT
        local len = math.sqrt(x * x + y * y + z * z)
        x, y, z = x / len, y / len, z / len
        if lightAddr then
            local day = y > -0.05
            local lx, ly, lz = x, y, z
            if not day then lx, ly, lz = -x, -y, -z end
            writeVec(TC.SUN, x, y, z)
            writeVec(TC.MOON, -x, -y, -z)
            writeVec(TC.LIGHT, lx, ly, lz)
            guard.s = day and 0 or 1
            pcall(memory_write, "byte", lightAddr + TC.SOURCE, guard.s)
            local vecs = { { TC.LIGHT, lx, ly, lz }, { TC.SUN, x, y, z }, { TC.MOON, -x, -y, -z } }
            if not PERF.matrixOn then
                local f = math.clamp((y + 0.1) / 0.6, 0, 1)
                local r = lerp(TC.DUSK_TINT[1], TC.NOON_TINT[1], f)
                local g = lerp(TC.DUSK_TINT[2], TC.NOON_TINT[2], f)
                local b = lerp(TC.DUSK_TINT[3], TC.NOON_TINT[3], f)
                writeVec(TC.CS_TOP, r, g, b)
                writeVec(TC.CS_BOT, r, g, b)
                vecs[#vecs + 1] = { TC.CS_TOP, r, g, b }
                vecs[#vecs + 1] = { TC.CS_BOT, r, g, b }
            end
            guard.vecs, guard.on = vecs, true
        end
        if PERF.matrixOn then return end
        local m = moodAt(h)
        if atmosAddr then
            saveBlock(moodSaved, atmosAddr, PERF.ATMOS.Color, 9)
            for j = 1, 3 do
                wf(atmosAddr + PERF.ATMOS.Color + (j - 1) * 4, m.color[j])
                wf(atmosAddr + PERF.ATMOS.Decay + (j - 1) * 4, m.decay[j])
            end
            wf(atmosAddr + PERF.ATMOS.Density, m.density)
            wf(atmosAddr + PERF.ATMOS.Haze, m.haze)
        end
        if ccAddr then
            local cco = PERF.MATRIX.CC_OFF
            saveBlock(moodSaved, ccAddr, cco.Tint, 4)
            for j = 1, 3 do wf(ccAddr + cco.Tint + (j - 1) * 4, m.tint[j]) end
            wf(ccAddr + cco.Brightness, m.bright)
        end
    end

    local function fmtHour(h)
        h = h % 24
        return string.format("%02d:%02d", math.floor(h), math.floor((h % 1) * 60))
    end

    while _G.JB_gen == myGen do
        local on = UI.GetValue(uid("timeChanger")) and true or false
        PERF.timeOn = on
        if on or wasOn then
            PERF.run("timeChanger", function()
                local now = tick()
                local dt = math.min(now - lastT, 0.1)
                lastT = now
                local idx = (tonumber(UI.GetValue(uid("timePreset"))) or 0) + 1
                local fixed = TC.HOURS[idx]
                local hour = fixed or tonumber(UI.GetValue(uid("timeHour"))) or 12
                local cycle = UI.GetValue(uid("timeCycle")) and true or false
                local speed = tonumber(UI.GetValue(uid("timeSpeed"))) or 1
                if on ~= wasOn then
                    wasOn = on
                    if on then
                        cycleHour = hour
                        notify("Enabled, " .. (TC.PRESETS[idx] or "?") .. " " .. fmtHour(hour), TC.TITLE, 3)
                    else
                        restoreAll()
                        notify("Disabled, real time restored", TC.TITLE, 3)
                        return
                    end
                elseif idx ~= lastPreset then
                    notify((TC.PRESETS[idx] or "?") .. (fixed and (" " .. fmtHour(fixed)) or ", use the slider"), TC.TITLE, 2)
                end
                lastPreset = idx
                if cycle then
                    cycleHour = ((cycleHour or hour) + speed * dt) % 24
                else
                    cycleHour = hour
                end
                refreshAddrs()
                apply(cycleHour)
            end)
        else
            lastT = tick()
        end
        task.wait(on and 0 or PERF.WORLD_TICK)
    end
    restoreAll()
end)

task.spawn(function()
    local MX = PERF.MATRIX
    local lighting = game:GetService("Lighting")
    local players = game:GetService("Players")
    local saved, floats = {}, {}
    local wasOn, scanning, lastScan, lastApply = false, false, 0, 0

    local function rf(a)
        local ok, v = pcall(memory_read, "float", a)
        return ok and v or nil
    end

    local function wf(a, v)
        if a and v then pcall(memory_write, "float", a, v) end
    end

    local function rb(a)
        local ok, v = pcall(memory_read, "byte", a)
        return ok and v or nil
    end

    local function wb(a, v)
        if a and v then pcall(memory_write, "byte", a, v) end
    end

    local function addrOf(inst)
        local ok, a = pcall(function() return tonumber(inst.Address) end)
        return ok and a or nil
    end

    local function buildFloats()
        local list = {}
        local function add(a, offs, values)
            if not a then return end
            for name, v in pairs(values) do
                local off = offs[name]
                if off then
                    if type(v) == "table" then
                        for j = 1, #v do list[#list + 1] = { a + off + (j - 1) * 4, v[j] } end
                    else
                        list[#list + 1] = { a + off, v }
                    end
                end
            end
        end
        for _, c in ipairs(lighting:GetChildren()) do
            if c.ClassName == "Atmosphere" then
                add(addrOf(c), PERF.ATMOS, MX.ATMOS)
            elseif c.ClassName == "ColorCorrectionEffect" then
                add(addrOf(c), MX.CC_OFF, MX.CC)
            end
        end
        add(addrOf(workspace:FindFirstChildOfClass("Terrain")), PERF.WATER_OFF, MX.WATER)
        for _, f in ipairs(list) do f[3] = rf(f[1]) end
        return list
    end

    local function matrixColor(r, g, b, s)
        local lum = 0.3 * r + 0.59 * g + 0.11 * b
        if s and math.min(s.X, s.Y, s.Z) <= 1.2 and math.max(s.X, s.Y, s.Z) <= 40 then return 40, 255, 110 end
        if lum < 70 then return 0, 6, 2 end
        local gg = math.clamp(math.floor(lum * 0.42), 12, 110)
        return 0, gg, math.floor(gg * 0.3)
    end

    local function recolor(d)
        local a = addrOf(d)
        if not a or saved[a] then return end
        local c = a + MX.COLOR
        local r, g, b = rb(c), rb(c + 1), rb(c + 2)
        if not r or not g or not b then return end
        local okS, s = pcall(function() return d.Size end)
        local okP, pa = pcall(function() return tonumber(d.Parent.Address) end)
        saved[a] = { r, g, b, d, okP and pa or nil }
        local nr, ng, nb = matrixColor(r, g, b, okS and s or nil)
        wb(c, nr) wb(c + 1, ng) wb(c + 2, nb)
    end

    local function scan()
        local chars = {}
        for _, pl in ipairs(players:GetPlayers()) do chars[pl.Name] = true end
        local ok, kids = pcall(function() return workspace:GetChildren() end)
        if not ok then return end
        local done = 0
        for _, top in ipairs(kids) do
            if not PERF.matrixOn or _G.JB_gen ~= myGen then return end
            if not chars[top.Name] and top.ClassName ~= "Terrain" and top.ClassName ~= "Camera" then
                if MX.PARTS[top.ClassName] then recolor(top) end
                local okD, desc = pcall(function() return top:GetDescendants() end)
                if okD then
                    for _, d in ipairs(desc) do
                        if not PERF.matrixOn then return end
                        if MX.PARTS[d.ClassName] then recolor(d) end
                        done = done + 1
                        if done % MX.CHUNK == 0 then task.wait() end
                    end
                end
            end
        end
    end

    local function restoreAll()
        for _, f in ipairs(floats) do wf(f[1], f[3]) end
        floats = {}
        local n = 0
        for a, c in pairs(saved) do
            local okL, live = pcall(function() return c[5] ~= nil and tonumber(c[4].Parent.Address) == c[5] end)
            if okL and live then
                local p = a + MX.COLOR
                wb(p, c[1]) wb(p + 1, c[2]) wb(p + 2, c[3])
            end
            n = n + 1
            if n % 4000 == 0 then task.wait() end
        end
        saved = {}
    end

    while _G.JB_gen == myGen do
        local on = UI.GetValue(uid("matrixMode")) and true or false
        PERF.matrixOn = on
        if on ~= wasOn then
            wasOn = on
            PERF.run("matrixMode", function()
                if on then
                    floats = buildFloats()
                    for _, f in ipairs(floats) do wf(f[1], f[2]) end
                    lastScan, lastApply = 0, tick()
                    notify("Enabled, wake up...", MX.TITLE, 3)
                else
                    restoreAll()
                    notify("Disabled, world restored", MX.TITLE, 3)
                end
            end)
        end
        if on then
            local now = tick()
            if now - lastApply >= PERF.WORLD_REAPPLY then
                lastApply = now
                for _, f in ipairs(floats) do wf(f[1], f[2]) end
            end
            if not scanning and now - lastScan >= MX.RESCAN then
                scanning = true
                task.spawn(function()
                    pcall(scan)
                    lastScan = tick()
                    scanning = false
                end)
            end
        end
        task.wait(PERF.WORLD_TICK)
    end
    PERF.matrixOn = false
    restoreAll()
end)

function PERF.robHud(keep)
local T = "[RobHUD]"
local P = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local mouse = P.LocalPlayer:GetMouse()

local NAMES = {
    [1] = "Bank", [2] = "Jewelry", [3] = "Museum", [4] = "Power Plant", [5] = "Passenger Train",
    [6] = "Cargo Train", [7] = "Cargo Ship", [8] = "Cargo Plane", [9] = "Gas Station",
    [10] = "Donut", [11] = "Grocery", [12] = "Money Truck", [14] = "Tomb", [15] = "Casino",
    [16] = "Mansion", [17] = "Oil Rig"
}
local C = {
    bg = Color3.fromRGB(8, 10, 15), line = Color3.fromRGB(34, 38, 48), text = Color3.fromRGB(225, 229, 238),
    sub = Color3.fromRGB(200, 205, 215), dim = Color3.fromRGB(110, 118, 132), red = Color3.fromRGB(255, 60, 70),
    blue = Color3.fromRGB(30, 110, 255), white = Color3.new(1, 1, 1), dark = Color3.fromRGB(8, 10, 15),
    open = Color3.fromRGB(90, 220, 130), active = Color3.fromRGB(255, 190, 70), closed = Color3.fromRGB(255, 85, 85)
}
local STATE = { [1] = { "OPEN", C.open }, [2] = { "ACTIVE", C.active }, [3] = { "CLOSED", C.closed } }
local TABS = { { 0, "ALL", C.blue }, { 1, "OPEN", C.open }, { 3, "CLOSED", C.closed } }
local soft = Drawing.Fonts.ProximaSoftBold or Drawing.Fonts.UI or 0
local mono = Drawing.Fonts.Monospace or soft
local brand = Drawing.Fonts.Fortnite or soft

local W, HEAD, TABH, ROW, ROWS, FOOT, BH, BW = 370, 36, 28, 26, 6, 24, 64, 68
local LIST = ROW * ROWS
local H = HEAD + TABH + LIST + FOOT
local vp = workspace.CurrentCamera.ViewportSize
local px, py = vp.X - W - 24, math.floor(vp.Y * 0.3)

local objs, cache = {}, {}
PERF.robHudObjs = objs
local function new(kind, props)
    local d = Drawing.new(kind)
    for k, v in pairs(props) do pcall(function() d[k] = v end) end
    d.Visible = false
    objs[#objs + 1] = d
    cache[d] = { Visible = false }
    return d
end
local function set(d, k, v)
    local c = cache[d]
    if c[k] ~= v then c[k] = v d[k] = v end
end
local function setPos(d, x, y)
    local c = cache[d]
    if c.px ~= x or c.py ~= y then c.px, c.py = x, y d.Position = Vector2.new(x, y) end
end
local function setSize(d, w, h)
    local c = cache[d]
    if c.sw ~= w or c.sh ~= h then c.sw, c.sh = w, h d.Size = Vector2.new(w, h) end
end
local function show(list, on)
    for _, d in ipairs(list) do set(d, "Visible", on) end
end

local panel, badge = {}, {}
local function P_(kind, props) local d = new(kind, props) panel[#panel + 1] = d return d end
local function B_(kind, props) local d = new(kind, props) badge[#badge + 1] = d return d end

local bg = P_("Square", { Filled = true, Color = C.bg, Transparency = 0.93, ZIndex = 20, Corner = 6 })
local border = P_("Square", { Filled = false, Color = C.line, Thickness = 1, Transparency = 1, ZIndex = 21, Corner = 6 })
local accL = P_("Square", { Filled = true, Color = C.red, Transparency = 1, ZIndex = 22 })
local accR = P_("Square", { Filled = true, Color = C.blue, Transparency = 1, ZIndex = 22 })
local title = P_("Text", { Text = "ROBBERY STATE", Font = brand, Size = 17, Color = C.text, Outline = false, Center = false, Transparency = 1, ZIndex = 23 })
local count = P_("Text", { Text = "", Font = mono, Size = 12, Color = C.open, Outline = false, Center = false, Transparency = 1, ZIndex = 23 })
local mini = P_("Text", { Text = "-", Font = mono, Size = 14, Color = C.dim, Outline = false, Center = false, Transparency = 1, ZIndex = 23 })
local sep1 = P_("Square", { Filled = true, Color = C.line, Transparency = 1, ZIndex = 22 })
local sep2 = P_("Square", { Filled = true, Color = C.line, Transparency = 1, ZIndex = 22 })
local tabT, tabU = {}, {}
for i, t in ipairs(TABS) do
    tabT[i] = P_("Text", { Text = t[2], Font = mono, Size = 12, Color = C.dim, Outline = false, Center = false, Transparency = 1, ZIndex = 23 })
    tabU[i] = P_("Square", { Filled = true, Color = t[3], Transparency = 1, ZIndex = 23 })
end
local rows = {}
for i = 1, ROWS + 1 do
    rows[i] = {
        hover = P_("Square", { Filled = true, Color = C.white, Transparency = 0, ZIndex = 21, Corner = 4 }),
        bell = P_("Circle", { Filled = true, Radius = 3, NumSides = 12, Color = C.blue, Transparency = 0, ZIndex = 23 }),
        halo = P_("Circle", { Filled = true, Radius = 4, NumSides = 20, Color = C.open, Transparency = 0, ZIndex = 22 }),
        dot = P_("Circle", { Filled = true, Radius = 4, NumSides = 16, Color = C.open, Transparency = 0, ZIndex = 23 }),
        name = P_("Text", { Text = "", Font = soft, Size = 14, Color = C.sub, Outline = false, Center = false, Transparency = 0, ZIndex = 23 }),
        pill = P_("Square", { Filled = true, Color = C.open, Transparency = 0, ZIndex = 22, Corner = 3 }),
        tag = P_("Text", { Text = "", Font = mono, Size = 11, Color = C.open, Outline = false, Center = true, Transparency = 0, ZIndex = 23 }),
        time = P_("Text", { Text = "", Font = mono, Size = 11, Color = C.dim, Outline = false, Center = true, Transparency = 0, ZIndex = 23 }),
        bounty = P_("Text", { Text = "", Font = mono, Size = 11, Color = C.red, Outline = false, Center = true, Transparency = 0, ZIndex = 23 }),
        chip = P_("Square", { Filled = true, Color = C.blue, Transparency = 0, ZIndex = 22, Corner = 4 }),
        chipB = P_("Square", { Filled = false, Color = C.blue, Thickness = 1, Transparency = 0, ZIndex = 22, Corner = 4 }),
        meta = P_("Text", { Text = "", Font = mono, Size = 11, Color = C.active, Outline = false, Center = true, Transparency = 0, ZIndex = 23 })
    }
end
local track = P_("Square", { Filled = true, Color = C.line, Transparency = 0.6, ZIndex = 22, Corner = 2 })
local thumb = P_("Square", { Filled = true, Color = C.dim, Transparency = 1, ZIndex = 23, Corner = 2 })
local empty = P_("Text", { Text = "Nothing here right now", Font = mono, Size = 12, Color = C.dim, Outline = false, Center = true, Transparency = 1, ZIndex = 23 })
local foot = P_("Text", { Text = "row: notify  |  ppl: players  |  drag: scroll", Font = mono, Size = 11, Color = C.dim, Outline = false, Center = false, Transparency = 1, ZIndex = 23 })

local PW, PROW, PMAX = 236, 24, 8
local pop = {
    bg = P_("Square", { Filled = true, Color = C.bg, Transparency = 0.95, ZIndex = 30, Corner = 6 }),
    border = P_("Square", { Filled = false, Color = C.line, Thickness = 1, Transparency = 1, ZIndex = 31, Corner = 6 }),
    accL = P_("Square", { Filled = true, Color = C.red, Transparency = 1, ZIndex = 32 }),
    accR = P_("Square", { Filled = true, Color = C.blue, Transparency = 1, ZIndex = 32 }),
    title = P_("Text", { Text = "", Font = brand, Size = 14, Color = C.text, Outline = false, Center = false, Transparency = 1, ZIndex = 33 }),
    total = P_("Text", { Text = "", Font = mono, Size = 12, Color = C.red, Outline = false, Center = false, Transparency = 1, ZIndex = 33 }),
    close = P_("Text", { Text = "x", Font = mono, Size = 12, Color = C.dim, Outline = false, Center = false, Transparency = 1, ZIndex = 33 }),
    sep = P_("Square", { Filled = true, Color = C.line, Transparency = 1, ZIndex = 32 }),
    wait = P_("Text", { Text = "Nobody nearby", Font = mono, Size = 11, Color = C.dim, Outline = false, Center = false, Transparency = 1, ZIndex = 33 }),
    rows = {}
}
for i = 1, PMAX do
    pop.rows[i] = {
        ring = P_("Circle", { Filled = true, Radius = 11, NumSides = 20, Color = C.line, Transparency = 1, ZIndex = 32 }),
        img = P_("Image", { Transparency = 1, ZIndex = 33, Rounding = 9 }),
        name = P_("Text", { Text = "", Font = soft, Size = 13, Color = C.sub, Outline = false, Center = false, Transparency = 1, ZIndex = 33 }),
        bounty = P_("Text", { Text = "", Font = mono, Size = 11, Color = C.red, Outline = false, Center = false, Transparency = 1, ZIndex = 33 })
    }
end

local bBg = B_("Square", { Filled = true, Color = C.bg, Transparency = 0.95, ZIndex = 20, Corner = 10 })
local bBorder = B_("Square", { Filled = false, Color = C.line, Thickness = 1, Transparency = 1, ZIndex = 21, Corner = 10 })
local bGlowR = B_("Square", { Filled = true, Color = C.red, Transparency = 0, ZIndex = 21, Corner = 4 })
local bGlowB = B_("Square", { Filled = true, Color = C.blue, Transparency = 0, ZIndex = 21, Corner = 4 })
local bBarR = B_("Square", { Filled = true, Color = C.red, Transparency = 1, ZIndex = 22, Corner = 2 })
local bBarB = B_("Square", { Filled = true, Color = C.blue, Transparency = 1, ZIndex = 22, Corner = 2 })
local bShadow = B_("Text", { Text = "JB", Font = brand, Size = 24, Color = Color3.new(0, 0, 0), Outline = false, Center = true, Transparency = 0.55, ZIndex = 22 })
local bJB = B_("Text", { Text = "JB", Font = brand, Size = 24, Color = C.text, Outline = false, Center = true, Transparency = 1, ZIndex = 23 })
local bHub = B_("Text", { Text = "H U B", Font = brand, Size = 12, Color = C.dim, Outline = false, Center = true, Transparency = 1, ZIndex = 23 })
local function strobe(t, phase)
    local c = (t + phase) % 1.4
    local a = 0
    for _, s in ipairs({ 0, 0.18 }) do
        local d = c - s
        if d >= 0 and d < 0.16 then a = math.max(a, math.sin(d / 0.16 * math.pi)) end
    end
    return a
end

local static = { bg, border, accL, accR, title, count, mini, sep1, sep2, foot }
for i = 1, #TABS do static[#static + 1] = tabT[i] end
local dynamic = { empty, track, thumb }
for i = 1, #TABS do dynamic[#dynamic + 1] = tabU[i] end
for _, o in ipairs(rows) do for _, d in pairs(o) do dynamic[#dynamic + 1] = d end end
local popStatic = { pop.bg, pop.border, pop.accL, pop.accR, pop.title, pop.close, pop.sep }
local popAll = { pop.bg, pop.border, pop.accL, pop.accR, pop.title, pop.close, pop.sep, pop.wait }
for _, o in ipairs(pop.rows) do popAll[#popAll + 1] = o.ring popAll[#popAll + 1] = o.img popAll[#popAll + 1] = o.name popAll[#popAll + 1] = o.bounty end
popAll[#popAll + 1] = pop.total
for _, d in ipairs(popAll) do dynamic[#dynamic + 1] = d end
show(static, true)
task.wait()
task.wait()
local cw12, cw11 = 7, 6.5
pcall(function() if tabT[1].TextBounds.X > 0 then cw12 = tabT[1].TextBounds.X / #tabT[1].Text end end)
pcall(function() if foot.TextBounds.X > 0 then cw11 = foot.TextBounds.X / #foot.Text end end)

local data, last, notifyOn = {}, {}, {}
local filter, scroll, scrollT = 0, 0, 0
local collapsed, pulseUntil = false, 0
local bxs, bys = 0, 0
local since = {}
local STAMP = {
    [17] = { "OilRig", { [2] = "LastStartedTime", [3] = "LastClosedTime" } },
    [16] = { "MansionRobbery", { [2] = "MansionRobberyIntroCutsceneBornAt", [3] = "LastClosedTime" } },
    [15] = { "Casino", { [1] = "CasinoRobberyActiveChangedAt", [2] = "CasinoRobberyActiveChangedAt", [3] = "CasinoRobberyActiveChangedAt" } },
    [14] = { "RobberyTomb", { [1] = "TombRobberyStatusChangedAt", [2] = "TombRobberyStatusChangedAt", [3] = "TombRobberyStatusChangedAt" } }
}
local CROWD = {
    [1] = "Bank", [2] = "Jewelry", [3] = "Museum", [4] = "PowerPlant", [9] = "Gas",
    [10] = "Donut", [11] = "Grocery", [14] = "Tomb", [15] = "Casino", [16] = "Mansion", [17] = "OilRig"
}
local CROWD_RANGE = 150
local crowdWho, popupId, metaRect = {}, nil, {}
local nameCache, avatarCache = {}, {}
local HS = game:GetService("HttpService")

local function get(url)
    local ok, body = pcall(PERF.timed, "hud.http", function() return game:HttpGet(url) end)
    if ok and type(body) == "string" then return body end
    local ok2, body2 = pcall(httpget, url)
    if ok2 and type(body2) == "string" then return body2 end
    return nil
end

local ACCENT = {
    [192] = "A", [193] = "A", [194] = "A", [195] = "A", [196] = "A", [197] = "A", [199] = "C", [200] = "E", [201] = "E", [202] = "E", [203] = "E",
    [204] = "I", [205] = "I", [206] = "I", [207] = "I", [209] = "N", [210] = "O", [211] = "O", [212] = "O", [213] = "O", [214] = "O", [216] = "O",
    [217] = "U", [218] = "U", [219] = "U", [220] = "U", [221] = "Y", [223] = "ss", [224] = "a", [225] = "a", [226] = "a", [227] = "a", [228] = "a",
    [229] = "a", [231] = "c", [232] = "e", [233] = "e", [234] = "e", [235] = "e", [236] = "i", [237] = "i", [238] = "i", [239] = "i", [241] = "n",
    [242] = "o", [243] = "o", [244] = "o", [245] = "o", [246] = "o", [248] = "o", [249] = "u", [250] = "u", [251] = "u", [252] = "u", [253] = "y", [255] = "y"
}
local function cleanName(name, fallback)
    local out, kept, dropped = {}, 0, 0
    for ch in string.gmatch(name, "[%z\1-\127\194-\244][\128-\191]*") do
        local b1 = string.byte(ch, 1)
        if b1 < 128 then
            if b1 >= 32 then out[#out + 1] = ch kept = kept + 1 end
        else
            local cp
            if #ch == 2 then cp = (b1 - 192) * 64 + (string.byte(ch, 2) - 128) end
            local rep = cp and ACCENT[cp]
            if rep then out[#out + 1] = rep kept = kept + 1 else dropped = dropped + 1 end
        end
    end
    local res = (table.concat(out):gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s%s+", " "))
    if #res < 2 or dropped > kept then return fallback end
    return res
end

local avatarTry = {}
local function fetchProfile(uid, fallback)
    local t = avatarTry[uid]
    if t and (t.busy or avatarCache[uid] or t.n >= 5 or tick() < t.next) then return end
    if not t then
        t = { n = 0, next = 0 }
        avatarTry[uid] = t
        nameCache[uid] = nameCache[uid] or fallback
    end
    t.busy = true
    task.spawn(function()
        if not t.named then
            local raw = get("https://users.roblox.com/v1/users/" .. uid)
            local ok, info = pcall(function() return HS:JSONDecode(raw) end)
            if ok and type(info) == "table" and type(info.displayName) == "string" and info.displayName ~= "" then
                nameCache[uid] = cleanName(info.displayName, fallback)
                t.named = true
            end
        end
        local meta = get("https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. uid .. "&size=48x48&format=Png&isCircular=true")
        local okM, m = pcall(function() return HS:JSONDecode(meta) end)
        local d = okM and type(m) == "table" and type(m.data) == "table" and m.data[1]
        local url = type(d) == "table" and d.imageUrl
        if type(url) == "string" and url ~= "" then
            local png = get(url)
            if png and png:sub(2, 4) == "PNG" then avatarCache[uid] = png end
        end
        t.n = t.n + 1
        t.next = tick() + 2 * t.n
        t.busy = false
    end)
end

local function attr(inst, name)
    local ok, v = pcall(function() return inst:GetAttribute(name) end)
    return ok and v or nil
end

local wsCache = {}
local function ws(name)
    local c = wsCache[name]
    local now = tick()
    if c then
        if c.inst then
            local ok, p = pcall(function() return c.inst.Parent end)
            if ok and p then return c.inst end
        elseif now < c.at then
            return nil
        end
    end
    local inst = PERF.timed("hud.ws", function() return workspace:FindFirstChild(name) end)
    wsCache[name] = { inst = inst, at = now + 20 + math.random() * 20 }
    return inst
end

local markerPos, markerAt = {}, 0
local function markers()
    if tick() - markerAt < 30 and next(markerPos) then return markerPos end
    markerAt = tick()
    local folder = ws("RobberyMarkers")
    for id, name in pairs(CROWD) do
        local m = folder and folder:FindFirstChild(name)
        local ok, p = pcall(function() return m.Position end)
        if ok and p then markerPos[id] = p end
    end
    return markerPos
end

local function stampOf(id, state)
    local s = STAMP[id]
    if s and s[2][state] then
        local m = ws(s[1])
        local v = m and tonumber(attr(m, s[2][state]))
        if v and v > 1e9 then return math.floor(v) end
    end
    return since[id]
end

local ZONES = {
    [1] = { "Banks", "Region" }, [2] = { "Jewelrys", "Region" }, [3] = { "Museum.Region" },
    [4] = { "PowerPlant.InnerRegions" }, [9] = { "GasStations", "Region" }, [10] = { "DonutShop", "Region" },
    [14] = { "RobberyTomb.Regions" }, [15] = { "Casino.Regions" }, [16] = { "MansionRobbery.Regions" }, [17] = { "OilRig.ActiveRobberyRegion" }
}
local PARTS = { Part = true, MeshPart = true, UnionOperation = true, WedgePart = true, CornerWedgePart = true, TrussPart = true }
local zoneBoxes, zoneAt = {}, 0

local function resolve(path)
    local inst
    for seg in string.gmatch(path, "[^%.]+") do
        if not inst then inst = ws(seg) else inst = inst:FindFirstChild(seg) end
        if not inst then return nil end
    end
    return inst
end

local function toBox(part)
    local okC, cf = pcall(function() return part.CFrame end)
    local okS, sz = pcall(function() return part.Size end)
    if not okC or not okS or not cf or not sz then return nil end
    local n = {}
    for v in string.gmatch(tostring(cf), "[%-%d%.e]+") do n[#n + 1] = tonumber(v) end
    if #n < 12 then return nil end
    return { n[1], n[2], n[3], n[4], n[5], n[6], n[7], n[8], n[9], n[10], n[11], n[12], sz.X / 2 + 0.5, sz.Y / 2 + 0.5, sz.Z / 2 + 0.5 }
end

local autoRegions, autoState = nil, 0
local SKIP_PARENT = { AerialSpawn = true, RedGoal = true, BlueGoal = true }
local function autoScan()
    autoState = 1
    task.spawn(function()
        local list = {}
        local okC, kids = pcall(function() return workspace:GetChildren() end)
        local n = 0
        for _, k in ipairs(okC and kids or {}) do
            local ok, all = pcall(function() return k:GetDescendants() end)
            if ok then
                for _, d in ipairs(all) do
                    if d.Name == "Region" and PARTS[d.ClassName] then
                        local okP, pn = pcall(function() return d.Parent.Name end)
                        if not (okP and SKIP_PARENT[pn]) then list[#list + 1] = d end
                    end
                    n = n + 1
                    if n >= 500 then n = 0 task.wait() end
                end
            end
            n = n + 25
            if n >= 500 then n = 0 task.wait() end
        end
        autoRegions = list
        zoneAt = 0
    end)
end

local function zones()
    if tick() - zoneAt < 90 then return zoneBoxes end
    zoneAt = tick()
    local old = zoneBoxes
    zoneBoxes = {}
    local used = {}
    for id, z in pairs(ZONES) do
        local root = resolve(z[1])
        if root then
            local list = {}
            local function add(d)
                if PARTS[d.ClassName] and (not z[2] or d.Name == z[2]) then
                    local okP, pn = pcall(function() return d.Parent.Name end)
                    if not (okP and SKIP_PARENT[pn]) then
                        local b = toBox(d)
                        if b then list[#list + 1] = b used[d] = true end
                    end
                end
            end
            add(root)
            local ok, desc = pcall(function() return root:GetDescendants() end)
            if ok then for i, d in ipairs(desc) do add(d) if i % 300 == 0 then task.wait() end end end
            if #list > 0 then zoneBoxes[id] = list end
        end
    end
    if autoState == 0 then autoScan() end
    if autoRegions then
        local pos = markers()
        for id in pairs(CROWD) do
            local mp = pos[id]
            if not zoneBoxes[id] and mp then
                local list = {}
                for _, d in ipairs(autoRegions) do
                    if not used[d] then
                        local okP, rp = pcall(function() return d.Position end)
                        if okP and rp and math.sqrt((rp.X - mp.X) ^ 2 + (rp.Z - mp.Z) ^ 2) <= 90 then
                            local b = toBox(d)
                            if b then list[#list + 1] = b end
                        end
                    end
                end
                if #list > 0 then zoneBoxes[id] = list end
            end
        end
    end
    for id, l in pairs(old) do if not zoneBoxes[id] then zoneBoxes[id] = l end end
    return zoneBoxes
end

local function billboardName(hrp)
    local bb = hrp:FindFirstChild("PlayerBillboard")
    local fr = bb and bb:FindFirstChild("Frame")
    local tl = fr and fr:FindFirstChild("TextLabel")
    local ok, t = pcall(function() return tl.Text end)
    if ok and type(t) == "string" and t ~= "" then return t end
    return nil
end

local function inBox(b, x, y, z)
    local dx, dy, dz = x - b[1], y - b[2], z - b[3]
    return math.abs(b[4] * dx + b[7] * dy + b[10] * dz) <= b[13]
        and math.abs(b[5] * dx + b[8] * dy + b[11] * dz) <= b[14]
        and math.abs(b[6] * dx + b[9] * dy + b[12] * dz) <= b[15]
end

local bountyOf, bountyRaw = {}, nil
local bountyOff = 0xA8 -- update
local function readMem(a)
    local ok, x = pcall(memory_read, "uintptr_t", a)
    return ok and x or nil
end
local function readStd(a)
    local size, cap = readMem(a + 16), readMem(a + 24)
    if not size or not cap or size < 2 or size > 200000 or cap < size then return nil end
    local p = cap > 15 and readMem(a) or a
    if not p or p < 4096 then return nil end
    local okF, first = pcall(memory_read, "byte", p)
    if not okF or first ~= 91 then return nil end
    local parts = {}
    for i = 0, size - 1, 4 do
        local okI, w = pcall(memory_read, "int", p + i)
        if not okI or type(w) ~= "number" then return nil end
        if w < 0 then w = w + 4294967296 end
        for b = 0, 3 do
            if i + b < size then parts[#parts + 1] = string.char(math.floor(w / 256 ^ b) % 256) end
        end
    end
    return table.concat(parts)
end
local function readBountyRaw()
    local bv = RS:FindFirstChild("BountyData")
    if not bv then return nil end
    local okA, base = pcall(function() return tonumber(bv.Address) end)
    if okA and base then
        if bountyOff then
            local s2 = readStd(base + bountyOff)
            if s2 then return s2 end
        end
        for off = 0x40, 0x300, 8 do
            local s2 = readStd(base + off)
            if s2 then bountyOff = off return s2 end
        end
    end
    local okV, v = pcall(function() return bv.Value end)
    if okV and type(v) == "string" then return v end
    return nil
end

local function bounties()
    local raw = readBountyRaw()
    if type(raw) ~= "string" or raw == bountyRaw then return end
    if raw:sub(1, 1) ~= "[" or raw:sub(-1) ~= "]" then return end
    bountyRaw = raw
    local map, n = {}, 0
    for obj in string.gmatch(raw, "{[^{}]*}") do
        local uid = tonumber(string.match(obj, '"UserId"%s*:%s*(%d+)'))
        local val = tonumber(string.match(obj, '"Bounty"%s*:%s*(%d+)'))
        if uid and val then map[uid] = val n = n + 1 end
    end
    bountyOf = map
end

local TEAMRANK = { Criminal = 1, Police = 2, Prisoner = 3 }
local TEAMCOL = { Police = C.blue, Criminal = C.closed, Prisoner = C.active }
local function teamOf(pl)
    local okT, t = pcall(function() return pl.Team.Name end)
    if okT and type(t) == "string" and t ~= "" then return t end
    local tv = pl:FindFirstChild("TeamValue")
    local ok, v = pcall(function() return tv.Value end)
    return ok and type(v) == "string" and v or ""
end

local function folderSet(path)
    local set = {}
    local f = resolve(path)
    local ok, kids = pcall(function() return f:GetChildren() end)
    if ok and kids then
        for _, c in ipairs(kids) do
            set[c.Name] = true
            local okV, v = pcall(function() return c.Value end)
            if okV and typeof(v) == "Instance" then set[v.Name] = true end
        end
    end
    return set
end

local seen = {}
local function crowd()
    PERF.timed("hud.bounties", bounties)
    local out, who, bty = {}, {}, {}
    local zb = PERF.timed("hud.zones", zones)
    local pos = PERF.timed("hud.markers", markers)
    local ids = {}
    for id in pairs(CROWD) do
        if zb[id] or pos[id] then ids[#ids + 1] = id out[id] = 0 who[id] = {} bty[id] = 0 end
    end
    local listed = { [16] = folderSet("MansionRobbery.InRobberyFolder"), [17] = folderSet("OilRig.PlayersInRobberyFolder") }
    local now = tick()
    local alive = {}
    for pi, pl in ipairs(P:GetPlayers()) do
        if pi % 5 == 0 then task.wait() end
        local okU, uid = pcall(function() return pl.UserId end)
        uid = okU and uid or 0
        alive[uid] = true
        local ch = pl.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        local ok, hp = pcall(function() return hrp.Position end)
        local hits
        if ok and hp then
            hits = {}
            local x, y, z = hp.X, hp.Y, hp.Z
            for _, id in ipairs(ids) do
                local hit = false
                if zb[id] then
                    for _, b in ipairs(zb[id]) do
                        if inBox(b, x, y, z) then hit = true break end
                    end
                else
                    hit = (hp - pos[id]).Magnitude <= CROWD_RANGE
                end
                if hit then hits[#hits + 1] = id end
            end
            local dn = billboardName(hrp)
            seen[uid] = { hits = hits, at = now, dname = dn or (seen[uid] and seen[uid].dname) }
        elseif seen[uid] and now - seen[uid].at < 20 then
            hits = seen[uid].hits
        else
            hits = {}
        end
        for lid, set in pairs(listed) do
            if set[pl.Name] and out[lid] then
                local dup = false
                for _, h in ipairs(hits) do if h == lid then dup = true break end end
                if not dup then hits[#hits + 1] = lid end
            end
        end
        local b = bountyOf[uid] or 0
        local dn = seen[uid] and seen[uid].dname
        for _, id in ipairs(hits) do
            if out[id] then
                out[id] = out[id] + 1
                bty[id] = bty[id] + b
                table.insert(who[id], { uid = uid, name = pl.Name, dname = dn and cleanName(dn, pl.Name) or nil, bounty = b, team = teamOf(pl) })
            end
        end
    end
    for uid in pairs(seen) do if not alive[uid] then seen[uid] = nil end end
    for _, l in pairs(who) do
        table.sort(l, function(a, b2)
            local ra, rb = TEAMRANK[a.team] or 4, TEAMRANK[b2.team] or 4
            if ra ~= rb then return ra < rb end
            if a.bounty ~= b2.bounty then return a.bounty > b2.bounty end
            return a.name < b2.name
        end)
    end
    crowdWho = who
    local mansion = ws("MansionRobbery")
    local inLift = mansion and tonumber(attr(mansion, "NumPlayersInElevator"))
    return out, bty, inLift
end

local function money(n)
    if n >= 1e6 then return string.format("$%.1fM", n / 1e6) end
    if n >= 1e4 then return string.format("$%dk", math.floor(n / 1000)) end
    if n >= 1e3 then return string.format("$%.1fk", n / 1000) end
    return "$" .. n
end

local function moneyFull(n)
    local s2 = tostring(math.floor(n))
    local out = s2:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    if out:sub(1, 1) == "," then out = out:sub(2) end
    return "$" .. out
end

local function fmt(sec)
    if not sec or sec < 0 then return "--:--" end
    local h, m, s2 = math.floor(sec / 3600), math.floor(sec / 60) % 60, sec % 60
    if h > 0 then return string.format("%d:%02d:%02d", h, m, s2) end
    return string.format("%d:%02d", m, s2)
end

local function refresh()
    local folder = RS:FindFirstChild("RobberyState")
    if not folder then return end
    local list = {}
    local ppl, bty, lift = crowd()
    for _, c in ipairs(folder:GetChildren()) do
        local id = tonumber(c.Name)
        local okV, v = pcall(function() return c.Value end)
        if id and NAMES[id] and okV and STATE[v] then
            if last[id] and last[id] ~= v then
                since[id] = os.time()
                if v == 1 then
                    pulseUntil = tick() + 10
                    if notifyOn[id] then notify(NAMES[id] .. " is open", "[JB Hub] Robbery State", 4) end
                end
            end
            last[id] = v
            list[#list + 1] = { id = id, name = NAMES[id], state = v, t = stampOf(id, v), ppl = ppl[id], bounty = bty[id], lift = id == 16 and lift or nil }
        end
    end
    table.sort(list, function(a, b)
        if a.state ~= b.state then return a.state < b.state end
        return a.name < b.name
    end)
    data = list
    if popupId and last[popupId] == 3 then popupId = nil end
end

local function inside(x, y, w, h, mx, my) return mx >= x and mx <= x + w and my >= y and my <= y + h end

local blocked = false
local function setBlock(b)
    if b ~= blocked then
        blocked = b
        pcall(setrobloxinput, not b)
    end
end

local wasDown, drag, thumbDrag, listDrag, badgeDrag = false, nil, nil, nil, nil
local lastRefresh, lastT = 0, tick()
_G.RobHUDGen = (_G.RobHUDGen or 0) + 1
local gen = _G.RobHUDGen
notify("Robbery State loaded", "[JB Hub] Robbery State", 3)
task.spawn(function()
    while _G.RobHUDGen == gen and keep() do
        pcall(PERF.timed, "hud.refresh", refresh)
        task.wait(1)
    end
end)
 
local function frame()
    local now = tick()
    local dt = math.min(now - lastT, 0.1)
    lastT = now

    local mx, my = mouse.X, mouse.Y
    local down = ismouse1pressed()
    local clicked = down and not wasDown
    local released = wasDown and not down
    wasDown = down

    local counts = { [1] = 0, [2] = 0, [3] = 0 }
    local view = {}
    for _, r in ipairs(data) do
        counts[r.state] = counts[r.state] + 1
        if filter == 0 or r.state == filter or (filter == 1 and r.state == 2) then view[#view + 1] = r end
    end

    if collapsed then
        local bx, by = bxs, bys
        local hov = inside(bx, by, BW, BH, mx, my)
        setBlock(hov or badgeDrag ~= nil)
        if clicked and hov then
            badgeDrag = { mx - bx, my - by, mx, my, false }
        end
        if badgeDrag then
            if math.abs(mx - badgeDrag[3]) + math.abs(my - badgeDrag[4]) > 4 then badgeDrag[5] = true end
            if badgeDrag[5] then
                bx = math.clamp(mx - badgeDrag[1], 0, vp.X - BW)
                by = math.clamp(my - badgeDrag[2], 0, vp.Y - BH)
                bxs, bys = bx, by
            end
            if released then
                if not badgeDrag[5] then
                    collapsed = false
                    px = math.clamp(bxs + BW - W, 0, vp.X - W)
                    py = math.clamp(bys, 0, vp.Y - H)
                end
                badgeDrag = nil
            end
        end
        if collapsed then
            show(static, false)
            show(dynamic, false)
            show(badge, true)
            local hot = now < pulseUntil
            local speed = hot and 2.2 or 1
            local r = strobe(now * speed, 0)
            local b = strobe(now * speed, 0.7)
            local base = hot and 0.35 or 0.2
            set(bBg, "Transparency", hov and 0.97 or 0.95)
            setPos(bBg, bx, by) setSize(bBg, BW, BH)
            set(bBorder, "Color", hov and C.dim or C.line)
            setPos(bBorder, bx, by) setSize(bBorder, BW, BH)
            local half = (BW - 30) / 2
            local barY = by + BH - 13
            set(bBarR, "Transparency", math.floor((base + (1 - base) * r) * 20) / 20)
            set(bBarB, "Transparency", math.floor((base + (1 - base) * b) * 20) / 20)
            setPos(bBarR, bx + 14, barY) setSize(bBarR, half, 4)
            setPos(bBarB, bx + 16 + half, barY) setSize(bBarB, half, 4)
            local gMax = hot and 0.45 or 0.28
            set(bGlowR, "Transparency", math.floor(gMax * r * 20) / 20)
            set(bGlowB, "Transparency", math.floor(gMax * b * 20) / 20)
            setPos(bGlowR, bx + 11, barY - 4) setSize(bGlowR, half + 6, 12)
            setPos(bGlowB, bx + 13 + half, barY - 4) setSize(bGlowB, half + 6, 12)
            local okJ, jh = pcall(function() return bJB.TextBounds.Y end)
            local okH, hh = pcall(function() return bHub.TextBounds.Y end)
            jh = (okJ and jh and jh > 0) and jh or 20
            hh = (okH and hh and hh > 0) and hh or 12
            local area = BH - 18
            local top = by + 4 + math.floor((area - (jh + hh + 2)) / 2)
            setPos(bShadow, bx + BW / 2 + 1, top + 2)
            setPos(bJB, bx + BW / 2, top)
            setPos(bHub, bx + BW / 2, top + jh + 2)
            set(bHub, "Color", hov and C.sub or C.dim)
        end
    end

    if not collapsed then
        show(badge, false)
        show(static, true)
        local maxScroll = math.max(0, #view * ROW - LIST)
        local listY = py + HEAD + TABH
        local trackX, trackH = px + W - 8, LIST - 8
        local thumbH = #view * ROW > LIST and math.max(24, trackH * LIST / (#view * ROW)) or trackH
        local thumbY = listY + 4 + (maxScroll > 0 and (trackH - thumbH) * (scroll / maxScroll) or 0)
        local popH = popupId and crowdWho[popupId] and (34 + math.max(math.min(#crowdWho[popupId], PMAX), 1) * PROW + 8) or 0
        local popX = px - PW - 8
        if popX < 0 then popX = px + W + 8 end
        local overPop = popH > 0 and inside(popX, math.clamp(py, 0, vp.Y - popH), PW, popH, mx, my)
        setBlock(inside(px, py, W, H, mx, my) or overPop or drag ~= nil or thumbDrag ~= nil or listDrag ~= nil)

        if clicked then
            if inside(px + W - 24, py + 8, 18, 20, mx, my) then
                collapsed = true
                bxs, bys = px + W - BW, py
                scrollT, listDrag, thumbDrag = 0, nil, nil
            elseif inside(px, py, W, HEAD, mx, my) then
                drag = { mx - px, my - py }
            elseif maxScroll > 0 and inside(trackX - 4, thumbY, 11, thumbH, mx, my) then
                thumbDrag = my - thumbY
            elseif maxScroll > 0 and inside(trackX - 4, listY, 11, LIST, mx, my) then
                scrollT = math.clamp((my - listY - thumbH / 2) / (trackH - thumbH), 0, 1) * maxScroll
            elseif inside(px, py + HEAD, W, TABH, mx, my) then
                local x = px + 12
                for _, t in ipairs(TABS) do
                    local label = t[2] .. " " .. (t[1] == 0 and #data or (t[1] == 1 and counts[1] + counts[2] or counts[t[1]]))
                    local w = #label * cw12
                    if mx >= x - 4 and mx <= x + w + 4 then filter = t[1] scrollT = 0 break end
                    x = x + w + 14
                end
            elseif inside(px, listY, W - 14, LIST, mx, my) then
                listDrag = { x = mx, y = my, from = scrollT, moved = false }
            end
        end
        if listDrag then
            if math.abs(my - listDrag.y) > 4 then listDrag.moved = true end
            if listDrag.moved then scrollT = listDrag.from - (my - listDrag.y) end
            if released then
                if not listDrag.moved then
                    local r = view[math.floor((listDrag.y - listY + scroll) / ROW) + 1]
                    local mr = r and metaRect[r.id]
                    if mr and listDrag.x >= mr[1] - 4 and listDrag.x <= mr[1] + mr[2] + 4 then
                        popupId = popupId ~= r.id and r.id or nil
                    elseif r then
                        notifyOn[r.id] = not notifyOn[r.id]
                    end
                end
                listDrag = nil
            end
        end
        if not down then drag, thumbDrag = nil, nil end
        if inside(px, py, W, H, mx, my) then
            local dir = (iskeypressed(0x28) and 1 or 0) - (iskeypressed(0x26) and 1 or 0)
            if dir ~= 0 then scrollT = scrollT + dir * 320 * dt end
        end
        if drag then
            px = math.clamp(mx - drag[1], 0, vp.X - W)
            py = math.clamp(my - drag[2], 0, vp.Y - H)
        end
        if thumbDrag and maxScroll > 0 then
            scrollT = math.clamp((my - thumbDrag - listY - 4) / (trackH - thumbH), 0, 1) * maxScroll
        end
        scrollT = math.clamp(scrollT, 0, maxScroll)
        scroll = scroll + (scrollT - scroll) * math.min(1, dt * 14)
        if math.abs(scrollT - scroll) < 0.5 then scroll = scrollT end
        listY = py + HEAD + TABH
        trackX = px + W - 8
        thumbY = listY + 4 + (maxScroll > 0 and (trackH - thumbH) * (scroll / maxScroll) or 0)

        setPos(bg, px, py) setSize(bg, W, H)
        setPos(border, px, py) setSize(border, W, H)
        setPos(accL, px + 6, py) setSize(accL, W / 2 - 6, 2)
        setPos(accR, px + W / 2, py) setSize(accR, W / 2 - 6, 2)
        setPos(title, px + 14, py + 10)
        set(count, "Text", (counts[1] + counts[2]) .. " open")
        setPos(count, px + W - 36 - #count.Text * cw12, py + 13)
        set(mini, "Color", inside(px + W - 24, py + 8, 18, 20, mx, my) and C.text or C.dim)
        setPos(mini, px + W - 19, py + 11)
        setPos(sep1, px + 10, py + HEAD) setSize(sep1, W - 20, 1)
        setPos(sep2, px + 10, py + HEAD + TABH - 1) setSize(sep2, W - 20, 1)

        local x = px + 12
        for i, t in ipairs(TABS) do
            local label = t[2] .. " " .. (t[1] == 0 and #data or (t[1] == 1 and counts[1] + counts[2] or counts[t[1]]))
            local w = #label * cw12
            local active = filter == t[1]
            local hov = inside(x - 4, py + HEAD, w + 8, TABH, mx, my)
            set(tabT[i], "Text", label)
            set(tabT[i], "Color", active and C.text or (hov and C.sub or C.dim))
            setPos(tabT[i], x, py + HEAD + 8)
            set(tabU[i], "Visible", active)
            setPos(tabU[i], x, py + HEAD + TABH - 3) setSize(tabU[i], w, 2)
            x = x + w + 14
        end

        local first = math.floor(scroll / ROW)
        local off = scroll - first * ROW
        for k = 1, ROWS + 1 do
            local o, r = rows[k], view[first + k]
            local y = listY + (k - 1) * ROW - off
            local a = 0
            if r then
                a = 1
                if y < listY then a = 1 - (listY - y) / ROW end
                if y + ROW > listY + LIST then a = 1 - (y + ROW - listY - LIST) / ROW end
                a = math.clamp(a, 0, 1)
            end
            local vis = a > 0.02
            for k2, d in pairs(o) do if k2 ~= "chip" and k2 ~= "chipB" and k2 ~= "bounty" then set(d, "Visible", vis) end end
            local chipOn, bText = false, ""
            if vis then
                local st = STATE[r.state]
                local hov = not drag and not thumbDrag and inside(px, math.max(y, listY), W - 14, ROW, mx, my) and inside(px, listY, W, LIST, mx, my)
                set(o.hover, "Transparency", hov and 0.06 * a or 0)
                setPos(o.hover, px + 6, y + 2) setSize(o.hover, W - 22, ROW - 4)
                set(o.bell, "Filled", notifyOn[r.id] and true or false)
                set(o.bell, "Color", notifyOn[r.id] and C.blue or C.dim)
                set(o.bell, "Transparency", (notifyOn[r.id] and 1 or 0.5) * a)
                setPos(o.bell, px + 14, y + ROW / 2)
                local live = r.state ~= 3
                local speed = r.state == 2 and 1.6 or 0.8
                local ph = (now * speed) % 1
                local beat = live and (0.5 + 0.5 * math.sin(now * speed * math.pi * 2)) or 0
                set(o.dot, "Color", st[2])
                set(o.dot, "Transparency", (live and 1 or 0.55) * a)
                set(o.dot, "Radius", math.floor(((hov and 5 or 4) + (r.state == 2 and beat * 0.8 or 0)) * 2 + 0.5) / 2)
                setPos(o.dot, px + 28, y + ROW / 2)
                set(o.halo, "Color", st[2])
                set(o.halo, "Radius", math.floor((4 + ph * (hov and 8 or 6)) * 2) / 2)
                set(o.halo, "Transparency", live and math.floor((1 - ph) * (hov and 0.55 or 0.4) * a * 20) / 20 or 0)
                setPos(o.halo, px + 28, y + ROW / 2)
                set(o.name, "Text", r.name)
                set(o.name, "Color", hov and C.text or C.sub)
                set(o.name, "Transparency", a)
                setPos(o.name, px + 40, y + 6)
                local pillW, colW, chipW = 54, 48, 50
                local pillX = px + W - 22 - pillW
                local timeX = pillX - 8 - colW
                local chipX = timeX - 8 - chipW
                local bountyX = chipX - 6 - colW
                set(o.pill, "Color", st[2])
                set(o.pill, "Transparency", 0.16 * a)
                setPos(o.pill, pillX, y + 5) setSize(o.pill, pillW, ROW - 10)
                set(o.tag, "Text", st[1])
                set(o.tag, "Color", st[2])
                set(o.tag, "Transparency", a)
                setPos(o.tag, pillX + pillW / 2, y + ROW / 2)
                local tt = fmt(r.t and (os.time() - r.t) or nil)
                set(o.time, "Text", tt)
                set(o.time, "Transparency", a)
                setPos(o.time, timeX + colW / 2, y + ROW / 2)
                local meta, mcol = "", C.active
                if r.id == 16 and r.state == 1 then
                    do
                        local n = math.clamp(r.lift or 0, 0, 3)
                        meta = n .. "/3"
                        mcol = n == 0 and C.dim or (n == 3 and C.closed or C.active)
                    end
                elseif r.state ~= 3 and r.ppl and r.ppl > 0 then
                    meta = r.ppl .. " ppl"
                    chipOn = true
                end
                local opened = popupId == r.id
                local overChip = chipOn and not drag and not thumbDrag and inside(chipX, y + 4, chipW, ROW - 8, mx, my) and inside(px, listY, W, LIST, mx, my)
                if chipOn then
                    mcol = (opened or overChip) and C.white or C.sub
                    set(o.chip, "Transparency", (opened and 0.4 or (overChip and 0.28 or 0.14)) * a)
                    set(o.chipB, "Transparency", (opened and 1 or (overChip and 0.9 or 0.55)) * a)
                    setPos(o.chip, chipX, y + 5) setSize(o.chip, chipW, ROW - 10)
                    setPos(o.chipB, chipX, y + 5) setSize(o.chipB, chipW, ROW - 10)
                end
                set(o.meta, "Text", meta)
                set(o.meta, "Color", mcol)
                set(o.meta, "Transparency", a)
                setPos(o.meta, chipX + chipW / 2, y + ROW / 2)
                metaRect[r.id] = chipOn and { chipX + 4, chipW - 8 } or nil
                if chipOn and r.bounty and r.bounty > 0 then
                    bText = money(r.bounty)
                    set(o.bounty, "Text", bText)
                    set(o.bounty, "Transparency", a)
                    setPos(o.bounty, bountyX + colW / 2, y + ROW / 2)
                end
            end
            set(o.bounty, "Visible", bText ~= "")
            set(o.chip, "Visible", chipOn)
            set(o.chipB, "Visible", chipOn)
        end
        set(empty, "Visible", #view == 0)
        setPos(empty, px + W / 2, listY + LIST / 2 - 6)
        set(track, "Visible", maxScroll > 0)
        setPos(track, trackX, listY + 4) setSize(track, 3, trackH)
        set(thumb, "Visible", maxScroll > 0)
        set(thumb, "Color", (thumbDrag or inside(trackX - 4, thumbY, 11, thumbH, mx, my)) and C.blue or C.dim)
        setPos(thumb, trackX, thumbY) setSize(thumb, 3, thumbH)
        setPos(foot, px + 14, py + H - FOOT + 5)

        local list = popupId and crowdWho[popupId]
        if list then
            local n = math.min(#list, PMAX)
            local ph = 34 + math.max(n, 1) * PROW + 8
            local qx = px - PW - 8
            if qx < 0 then qx = px + W + 8 end
            local qy = math.clamp(py, 0, vp.Y - ph)
            show(popStatic, true)
            setPos(pop.bg, qx, qy) setSize(pop.bg, PW, ph)
            setPos(pop.border, qx, qy) setSize(pop.border, PW, ph)
            setPos(pop.accL, qx + 6, qy) setSize(pop.accL, PW / 2 - 6, 2)
            setPos(pop.accR, qx + PW / 2, qy) setSize(pop.accR, PW / 2 - 6, 2)
            set(pop.title, "Text", string.upper(NAMES[popupId] or "?") .. "  " .. #list)
            setPos(pop.title, qx + 12, qy + 9)
            local tot = 0
            for _, e in ipairs(list) do tot = tot + (e.bounty or 0) end
            local tt = tot > 0 and moneyFull(tot) or ""
            set(pop.total, "Visible", tot > 0)
            set(pop.total, "Text", tt)
            setPos(pop.total, math.floor(qx + PW - 26 - #tt * cw11), qy + 10)
            local overClose = inside(qx + PW - 20, qy + 6, 14, 18, mx, my)
            set(pop.close, "Color", overClose and C.text or C.dim)
            setPos(pop.close, qx + PW - 16, qy + 9)
            if clicked and overClose then popupId = nil end
            setPos(pop.sep, qx + 10, qy + 30) setSize(pop.sep, PW - 20, 1)
            set(pop.wait, "Visible", n == 0)
            setPos(pop.wait, qx + 12, qy + 40)
            for i = 1, PMAX do
                local o, e = pop.rows[i], list[i]
                local vis = e ~= nil
                set(o.ring, "Visible", vis)
                set(o.name, "Visible", vis)
                set(o.bounty, "Visible", vis and (e.bounty or 0) > 0)
                if vis then
                    fetchProfile(e.uid, e.name)
                    local ry = qy + 36 + (i - 1) * PROW
                    local tc = TEAMCOL[e.team] or C.sub
                    set(o.ring, "Color", tc)
                    setPos(o.ring, qx + 22, ry + PROW / 2)
                    set(o.name, "Color", tc)
                    local png = avatarCache[e.uid]
                    if png and cache[o.img].uid ~= e.uid then
                        cache[o.img].uid = e.uid
                        pcall(PERF.timed, "hud.avatarSet", function() o.img.Data = png end)
                    end
                    set(o.img, "Visible", png and cache[o.img].uid == e.uid or false)
                    setPos(o.img, qx + 13, ry + PROW / 2 - 9) setSize(o.img, 18, 18)
                    local bt = (e.bounty or 0) > 0 and moneyFull(e.bounty) or ""
                    local room = math.floor((PW - 50 - (#bt > 0 and #bt * cw11 + 8 or 0)) / 7)
                    local nm = e.dname or nameCache[e.uid] or e.name
                    if #nm > room then nm = nm:sub(1, math.max(room - 2, 3)) .. ".." end
                    set(o.name, "Text", nm)
                    setPos(o.name, qx + 38, ry + 5)
                    set(o.bounty, "Text", bt)
                    setPos(o.bounty, math.floor(qx + PW - 12 - #bt * cw11), ry + 7)
                else
                    set(o.img, "Visible", false)
                end
            end
        else
            show(popAll, false)
        end
    end
end
 
local fails = 0
while _G.RobHUDGen == gen and keep() do
    if PERF.run("robHud", frame) then fails = 0 else fails = fails + 1 end
    task.wait(PERF.FRAME)
end
setBlock(false)
return fails < 300
end

task.spawn(function()
    local function keep()
        return _G.JB_gen == myGen and UI.GetValue(uid("robHud")) and true or false
    end
    while _G.JB_gen == myGen do
        if keep() then
            local ok, res = pcall(PERF.robHud, keep)
            for _, d in ipairs(PERF.robHudObjs or {}) do pcall(function() d:Remove() end) end
            PERF.robHudObjs = nil
            pcall(setrobloxinput, true)
            task.wait((ok and res ~= false) and 0.5 or 5)
        else
            task.wait(0.25)
        end
    end
end)

task.spawn(function()
    local list, index = nil, 0
    local folders, spikes, homesFound = {}, {}, {}
    while _G.JB_gen == myGen do
        local needNpc = (UI.GetValue(uid("killNpcs")) or UI.GetValue(uid("guards")) or UI.GetValue(uid("npcHitbox")) or (tonumber(UI.GetValue(uid("guardMode"))) or 0) ~= 0) and true or false
        local needSpike = UI.GetValue(uid("antiTirePop")) and true or false
        local needHome = UI.GetValue(uid("noturret")) and true or false
        if not needNpc and not needSpike and not needHome then
            list = nil
            PERF.worldReady = false
            task.wait(0.5)
        else
            if not list and tick() >= (PERF.worldNextScan or 0) then
                local ok, children = pcall(function() return workspace:GetChildren() end)
                list, index = ok and children or {}, 0
                folders, spikes, homesFound = {}, {}, {}
            end
            local budget = list and (not PERF.worldReady and PERF.WORLD_CHUNK_FIRST or (needNpc and PERF.WORLD_CHUNK_NPC or PERF.WORLD_CHUNK_SPIKE)) or 0
            while budget > 0 do
                index = index + 1
                local c = list[index]
                if c == nil then
                    PERF.npcFolders, PERF.spikeModels, PERF.homeModels = folders, spikes, homesFound
                    PERF.worldReady = true
                    PERF.worldNextScan = tick() + 2
                    list = nil
                    break
                end
                budget = budget - 1
                pcall(function()
                    if needNpc then
                        local a = c:FindFirstChild("NPCs")
                        local b = c:FindFirstChild("GuardsFolder")
                        if a then folders[#folders + 1] = a end
                        if b then folders[#folders + 1] = b end
                    end
                    if needSpike and c.Name == "Model" and c:FindFirstChild("Box") then
                        spikes[#spikes + 1] = c
                    end
                    if needHome and c:FindFirstChild("Turret") then
                        homesFound[#homesFound + 1] = c
                    end
                end)
            end
            task.wait(PERF.FRAME)
        end
    end
end)

task.spawn(function()
    local ids = { "swordNoCd", "swordLunge", "instant", "norecoil", "nospread", "autoShoot" }
    local values, index, itemSeen, primed = {}, 0, {}, false
    while _G.JB_gen == myGen do
        local need = false
        for _, id in ipairs(ids) do
            if UI.GetValue(uid(id)) then need = true break end
        end
        if need then
            PERF.run("equipWatch", function()
                local folder = game:GetService("Players").LocalPlayer:FindFirstChild("Folder")
                if not folder then return end
                local items = folder:GetChildren()
                for _, it in ipairs(items) do
                    local name = it.Name
                    if not itemSeen[name] then
                        itemSeen[name] = true
                        if primed then PERF.equipVersion = PERF.equipVersion + 1 end
                    end
                end
                primed = true
                if #items == 0 then return end
                index = index % #items + 1
                local item = items[index]
                local key = tostring(item.Address)
                local v = item:GetAttribute("InventoryItemLocalEquipped")
                if values[key] ~= nil and values[key] ~= v then
                    PERF.equipRaw = PERF.equipRaw + 1
                    local name = item.Name
                    if not PERF.equipSeen[name] then
                        PERF.equipSeen[name] = true
                        PERF.equipVersion = PERF.equipVersion + 1
                    end
                end
                values[key] = v
            end)
            task.wait(PERF.EQUIP_WATCH_TICK)
        else
            values, index, itemSeen, primed = {}, 0, {}, false
            task.wait(0.5)
        end
    end
end)

task.spawn(function()
    local players = game:GetService("Players")
    local lp = players.LocalPlayer
    local ZERO = Vector3.new(0, 0, 0)
    local T, C = PERF.TASE, PERF.CUFF

    local CFG = {
        DEBUG = false,
        TASE_RANGE = T.RANGE,
        LATENCY = 0.035,
        PING_LEAD = 0.5,
        VEL_WINDOW = 0.25,
        MAX_TARGET_SPEED = 120,
        TIP_WAIT = 0.6,
        EQUIP_SETTLE = 0.15,
        TASER_SETTLE = 0.45,
        PREARM = 0.6,
        UNEQUIP_TIMEOUT = 0.6,
        EQUIP_TIMEOUT = 0.6,
        EQUIP_BACKOFF = 2,
        RESYNC_GAP = 0.1,
        CUFF_RELEASE = 1,
        TASER_RELEASE = 2,
        HIT_COOLDOWN = 7,
        BLOCKED_WAIT = 0.3,
        UNLOCK_SETTLE = 0.2,
        CURSOR_GUARD_WAIT = 1,
        CAM_TURN_DOT = 0.9995,
        MISS_BLOCK = 6,
        MISS_MOVE = 4,
        STILL_SPEED = 3,
        CUFF_EQUIP_RANGE = C.EQUIP_RANGE,
        CUFF_KEEP_RANGE = 32,
        CUFF_H = C.MAX_H,
        CUFF_V = C.MAX_V,
        KEY_E = C.KEY_E,
        TAP = C.TAP,
        RESULT_TIMEOUT = C.RESULT_TIMEOUT,
        HOLD_TIMEOUT = C.HOLD_TIMEOUT,
        ARREST_WAIT = 0.5,
        EJECT_ARREST_WAIT = 1,
        EJECT_TIMEOUT = 4,
        RETRY = C.RETRY,
        ARRESTED_IGNORE = 30,
        FAIL_STREAK = 3,
        FAIL_IGNORE = 10,
        RAG_CACHE = 0.15,
        SEAT_CACHE = 0.2,
        SEAT_HOLD = 0.6,
        VEHICLE_RADIUS = 20,
        VEHICLE_REFRESH = 0.25,
        SEAT_INDEX_REFRESH = 5,
        SEAT_DIST = 2.5,
    }

    local MANAGED = { Taser = true, Handcuffs = true }
    local SEAT_NAMES = { Seat = true, Passenger = true, DriverSeat = true, VehicleSeat = true }

    local state = {
        active = false,
        readyAt = 0,
        blockedUntil = 0,
        cursorBlockUntil = 0,
        equipFailUntil = 0,
        unlockedAt = 0,
        hybridWarned = false,
        tracks = {},
        rag = {},
        seat = {},
        seatIndex = {},
        vehList = {},
        vehAt = 0,
        retryAt = {},
        arrested = {},
        failStreak = {},
        missBlock = {},
        teamCache = {},
        inHand = nil,
        owned = nil,
        prevItem = nil,
        switching = false,
        equippedAt = 0,
        needCuffAt = 0,
        needTaserAt = 0,
        me = { vel = ZERO },
        tipPart = nil,
        camEntry = nil,
        prefEntry = nil,
        camOriginal = nil,
        cuffConfig = nil,
        cuffOriginal = nil,
        shots = 0, hits = 0, attempts = 0, arrests = 0,
    }

    local lastLog = {}
    local function dbg(key, msg)
        if not CFG.DEBUG or lastLog[key] == msg then return end
        lastLog[key] = msg
        print(string.format("[JB Police %.2f] %s", tick() % 1000, msg))
    end

    local function event(msg)
        if CFG.DEBUG then print(string.format("[JB Police %.2f] %s", tick() % 1000, msg)) end
    end

    local function keyOf(inst)
        local ok, a = pcall(function() return inst.Address end)
        return ok and tostring(a) or nil
    end

    local function item(name)
        local f = lp:FindFirstChild("Folder")
        return f and f:FindFirstChild(name)
    end

    local function teamOf(p)
        local name = p.Name
        local now = tick()
        local c = state.teamCache[name]
        if not c or now - c.t > 0.5 then
            c = { t = now, team = tostring(p.Team) }
            state.teamCache[name] = c
        end
        return c.team
    end

    local function markArrested(name, duration, reason)
        local now = tick()
        if now >= (state.arrested[name] or 0) then
            event(string.format("%s ignored %ds (%s)", name, duration, reason))
        end
        state.arrested[name] = math.max(state.arrested[name] or 0, now + duration)
        state.failStreak[name] = nil
    end

    local function isOdd(it)
        local v = it and it:GetAttribute("InventoryItemLocalEquipped")
        return type(v) == "number" and v % 2 == 1
    end

    local function heldList()
        local list = {}
        local f = lp:FindFirstChild("Folder")
        if f then
            for _, it in ipairs(f:GetChildren()) do
                if isOdd(it) then list[#list + 1] = it end
            end
        end
        return list
    end

    local function syncHand()
        local list = heldList()
        local name = #list == 1 and list[1].Name or (#list > 1 and "CONFLICT" or nil)
        if name ~= state.inHand then
            state.inHand = name
            event("hand = " .. tostring(name))
            if state.owned and not state.switching and name ~= state.owned then
                event("user took over, ownership dropped")
                state.owned, state.prevItem = nil, nil
            end
        end
        return list
    end

    local function held(it)
        local list = syncHand()
        return it ~= nil and #list == 1 and list[1].Name == it.Name
    end

    local function waitParity(it, odd, timeout)
        local start = tick()
        while tick() - start < timeout do
            if isOdd(it) == odd then return true end
            task.wait(0.03)
        end
        return false
    end

    local function fireEquip(it, value)
        pcall(function() it.InventoryEquipRemote:FireServer(value) end)
    end

    local function unequip(it)
        local start = tick()
        fireEquip(it, false)
        local ok = waitParity(it, false, CFG.UNEQUIP_TIMEOUT)
        event(string.format("unequip %s %s (%.2fs)", it.Name, ok and "OK" or "TIMEOUT", tick() - start))
        return ok
    end

    local function equipRaw(it)
        local start = tick()
        fireEquip(it, true)
        if waitParity(it, true, CFG.EQUIP_TIMEOUT) then
            event(string.format("equip %s OK (%.2fs)", it.Name, tick() - start))
            return true
        end
        fireEquip(it, false)
        task.wait(CFG.RESYNC_GAP)
        fireEquip(it, true)
        local ok = waitParity(it, true, CFG.EQUIP_TIMEOUT)
        event(string.format("equip %s %s after resync (%.2fs)", it.Name, ok and "OK" or "TIMEOUT", tick() - start))
        return ok
    end

    local function equip(it)
        if held(it) then return true, false end
        for _, other in ipairs(heldList()) do
            if other.Name ~= it.Name and not unequip(other) then return false, false end
        end
        if not isOdd(it) and not equipRaw(it) then return false, false end
        syncHand()
        return true, true
    end

    local function takeItem(it)
        syncHand()
        if held(it) then
            if state.owned == nil then state.owned, state.prevItem = it.Name, nil end
            return true, false
        end
        if tick() < state.equipFailUntil then return false, false end
        if state.owned == nil then
            local cur = state.inHand
            state.prevItem = (cur and cur ~= "CONFLICT" and not MANAGED[cur]) and cur or nil
        end
        state.switching = true
        local ok, switched = equip(it)
        state.switching = false
        if ok then
            state.owned = it.Name
            if switched then state.equippedAt = tick() end
        else
            state.equipFailUntil = tick() + CFG.EQUIP_BACKOFF
            event(string.format("equip %s failed, backoff %.1fs", it.Name, CFG.EQUIP_BACKOFF))
        end
        return ok, switched
    end

    local function release(reason)
        if not state.owned then return end
        local owned, prevName = state.owned, state.prevItem
        local prev = prevName and item(prevName)
        local cur = item(owned)
        state.switching = true
        if prev then
            equip(prev)
        elseif cur and isOdd(cur) then
            unequip(cur)
        end
        state.switching = false
        state.owned, state.prevItem = nil, nil
        syncHand()
        event(string.format("release %s -> %s (%s)", owned, tostring(prevName or "nothing"), reason))
    end

    local function circleHelp()
        local gui = lp:FindFirstChild("PlayerGui")
        local a = gui and gui:FindFirstChild("CircleAction")
        local b = a and a:FindFirstChild("CircleAction")
        local h = b and b:FindFirstChild("Help")
        local ok, t = pcall(function() return h and h.Text end)
        return ok and t or nil
    end

    local function isEjectPrompt(text)
        return type(text) == "string" and string.find(string.lower(text), "eject", 1, true) ~= nil
    end

    local function isRagdolled(name, char)
        local now = tick()
        local c = state.rag[name]
        if c and now - c.at < CFG.RAG_CACHE then return c.v end
        local ok, w = pcall(function() return char:FindFirstChild("RagdollWaist", true) end)
        local v = ok and w ~= nil
        state.rag[name] = { v = v, at = now }
        return v
    end

    local function vehicleList()
        local now = tick()
        if now - state.vehAt < CFG.VEHICLE_REFRESH then return state.vehList end
        local list = {}
        local vehicles = PERF.ws("Vehicles")
        if vehicles then
            for _, v in ipairs(vehicles:GetChildren()) do
                local ref = v:FindFirstChild("Engine") or v:FindFirstChild("Seat")
                local ok, p = pcall(function() return ref.Position end)
                if ok and p then list[#list + 1] = { model = v, pos = p, key = keyOf(v) } end
            end
        end
        state.vehList, state.vehAt = list, now
        return list
    end

    local function vehicleSeats(entry)
        local now = tick()
        local c = state.seatIndex[entry.key]
        if c and now - c.at < CFG.SEAT_INDEX_REFRESH then return c.seats end
        local seats = {}
        pcall(function()
            for _, d in ipairs(entry.model:GetDescendants()) do
                local cls = d.ClassName
                if cls == "Seat" or cls == "VehicleSeat" or (SEAT_NAMES[d.Name] and (cls == "Part" or cls == "MeshPart")) then
                    seats[#seats + 1] = d
                end
            end
        end)
        state.seatIndex[entry.key] = { at = now, seats = seats }
        return seats
    end

    local function rawSeated(hrp)
        local v = false
        pcall(function()
            local pos = hrp.Position
            local hk = keyOf(hrp)
            for _, e in ipairs(vehicleList()) do
                if (e.pos - pos).Magnitude <= CFG.VEHICLE_RADIUS then
                    for _, seat in ipairs(vehicleSeats(e)) do
                        local w = seat:FindFirstChild("SeatWeld")
                        local okW, p1 = pcall(function() return w and w.Part1 end)
                        if okW and p1 and keyOf(p1) == hk then
                            v = true
                            break
                        end
                        local okS, sp = pcall(function() return seat.Position end)
                        if okS and sp and (sp - pos).Magnitude <= CFG.SEAT_DIST then
                            v = true
                            break
                        end
                    end
                end
                if v then break end
            end
        end)
        return v
    end

    local function isSeated(name, hrp, force)
        local now = tick()
        local c = state.seat[name]
        if not force and c and now - c.at < CFG.SEAT_CACHE then return c.v end
        local raw = rawSeated(hrp)
        local v = raw
        if not raw and not force and c and c.v and now - (c.lastTrue or 0) < CFG.SEAT_HOLD then v = true end
        state.seat[name] = { v = v, at = now, lastTrue = raw and now or (c and c.lastTrue) }
        return v
    end

    local function updateMotion(track, pos, now)
        local s = track.samples
        if not s then
            s = {}
            track.samples = s
        end
        local last = s[#s]
        if last and (pos - last.pos).Magnitude > 60 then
            s = {}
            track.samples = s
            last = nil
        end
        if not last or (pos - last.pos).Magnitude > 0.001 or now - last.t > 0.1 then
            s[#s + 1] = { t = now, pos = pos }
        end
        while #s > 2 and now - s[1].t > CFG.VEL_WINDOW do table.remove(s, 1) end
        local first, newest = s[1], s[#s]
        if first and newest ~= first and newest.t - first.t >= 0.05 then
            track.vel = (newest.pos - first.pos) * (1 / (newest.t - first.t))
        else
            track.vel = ZERO
        end
    end

    task.spawn(function()
        while _G.JB_gen == myGen do
            if not state.active then
                state.tracks = {}
                task.wait(0.25)
            else
                pcall(function()
                    local now = tick()
                    local myName = lp.Name
                    local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                    if root then updateMotion(state.me, root.Position, now) end
                    local alive = {}
                    for _, p in ipairs(players:GetPlayers()) do
                        local name = p.Name
                        if name ~= myName then
                            local char = p.Character
                            local hrp = char and char:FindFirstChild("HumanoidRootPart")
                            if hrp and string.find(teamOf(p), "Criminal", 1, true) then
                                alive[name] = true
                                local rk = keyOf(hrp)
                                local track = state.tracks[name]
                                if not track or track.rootKey ~= rk then
                                    track = { name = name, vel = ZERO, rootKey = rk }
                                    state.tracks[name] = track
                                end
                                track.char, track.root = char, hrp
                                updateMotion(track, hrp.Position, now)
                            end
                        end
                    end
                    for name in pairs(state.tracks) do
                        if not alive[name] then
                            state.tracks[name] = nil
                            state.rag[name] = nil
                            state.seat[name] = nil
                            state.missBlock[name] = nil
                            state.failStreak[name] = nil
                        end
                    end
                end)
                task.wait(PERF.FRAME)
            end
        end
    end)

    local function gather(root)
        local list = {}
        local myPos = root.Position
        local now = tick()
        for name, track in pairs(state.tracks) do
            local ok, valid = pcall(function()
                local char, hrp = track.char, track.root
                local hum = char:FindFirstChild("Humanoid")
                if not hum or hum.Health <= 0 or hrp.Parent == nil then return false end
                local d = hrp.Position - myPos
                track.h = math.sqrt(d.X * d.X + d.Z * d.Z)
                track.v = math.abs(d.Y)
                track.dist = d.Magnitude
                if char:GetAttribute("HasHandcuffs") == true then
                    markArrested(name, CFG.ARRESTED_IGNORE, "HasHandcuffs")
                end
                track.cuffed = now < (state.arrested[name] or 0)
                local near = not track.cuffed and track.dist <= CFG.TASE_RANGE + 5
                track.rag = near and isRagdolled(name, char) or false
                track.seated = near and isSeated(name, hrp) or false
                return true
            end)
            if ok and valid then list[#list + 1] = track end
        end
        table.sort(list, function(a, b) return a.dist < b.dist end)
        return list
    end

    local function markSearched(list, help)
        if help ~= "Search" then return end
        for _, t in ipairs(list) do
            if not t.cuffed and t.h <= CFG.CUFF_H and t.v <= CFG.CUFF_V then
                markArrested(t.name, CFG.ARRESTED_IGNORE, "Search prompt")
                t.cuffed = true
                return
            end
        end
    end

    local function missBlocked(t)
        local m = state.missBlock[t.name]
        if not m then return false end
        if tick() >= m.untilT or (t.root.Position - m.pos).Magnitude >= CFG.MISS_MOVE then
            state.missBlock[t.name] = nil
            return false
        end
        return true
    end

    local function findTip(root)
        local tp = state.tipPart
        if tp and tp.Parent and (tp.Position - root.Position).Magnitude < 8 then return tp end
        state.tipPart = nil
        local items = PERF.ws("Items")
        if not items then return nil end
        local best, bestDist
        for _, m in ipairs(items:GetChildren()) do
            if m.Name == "Taser" then
                local sk = m:FindFirstChild("Skeleton")
                local part = sk and sk:FindFirstChild("Tip")
                if part then
                    local d = (part.Position - root.Position).Magnitude
                    if d < 8 and (not bestDist or d < bestDist) then best, bestDist = part, d end
                end
            end
        end
        state.tipPart = best
        return best
    end

    local function currentLead()
        local ok, ping = pcall(GetPingValue)
        ping = ok and tonumber(ping) or 0
        return CFG.LATENCY + ping / 1000 * CFG.PING_LEAD
    end

    local function aimAt(track, root, myChar, range, lead)
        local tipPart = findTip(root)
        local tip = tipPart and tipPart.Position
        if not tip then
            local head = myChar:FindFirstChild("Head")
            tip = head and head.Position
        end
        if not tip then return nil, "no tip" end
        local target = track.root.Position + track.vel * lead
        if (target - tip).Magnitude > range then return nil, "out of range" end
        local pos, onScreen = WorldToScreen(target - state.me.vel * lead)
        if not onScreen then return nil, "off screen" end
        return pos
    end

    local function findCameraEntries()
        local anchors, candidates, pref = {}, {}, nil
        for _, e in ipairs(lockedGetgc({ "Locked", "updateMouseLock", "SetRecoilSpring", "weaponCamLock" })) do
            local key = tostring(e.key)
            if key == "updateMouseLock" or key == "SetRecoilSpring" then
                anchors[#anchors + 1] = tonumber(e.addr) or 0
            elseif key == "Locked" and e.type == "boolean" then
                candidates[#candidates + 1] = e
            elseif key == "weaponCamLock" and e.type == "boolean" and not pref then
                pref = e
            end
        end
        local best, bestDist
        for _, e in ipairs(candidates) do
            local a = tonumber(e.addr) or 0
            for _, anchor in ipairs(anchors) do
                local d = math.abs(a - anchor)
                if not bestDist or d < bestDist then best, bestDist = e, d end
            end
        end
        if not (best and bestDist <= 4096) then best = nil end
        return best, pref
    end

    local function readBool(e)
        if not e then return nil end
        local ok, v = pcall(memory_read, "int", tonumber(e.addr))
        if not ok or type(v) ~= "number" then return nil end
        return v ~= 0
    end

    local function camLive()
        return readBool(state.camEntry)
    end

    local function camSet(value)
        local e = state.camEntry
        if not e then return false end
        local ok, n = pcall(applygc, { e }, "Locked", value)
        return ok and (tonumber(n) or 0) > 0
    end

    local function enforceUnlock()
        if not state.camEntry then return end
        if camLive() == true then
            camSet(false)
            state.unlockedAt = tick()
        end
    end

    local function restoreCamLock()
        if not state.camEntry then return nil end
        local want = readBool(state.prefEntry)
        if want == nil then want = state.camOriginal end
        if want ~= nil then camSet(want) end
        state.camOriginal = nil
        return want
    end

    local function camTurned(a, b)
        local ok, dot = pcall(function() return a.LookVector:Dot(b.LookVector) end)
        return ok and dot < CFG.CAM_TURN_DOT
    end

    local function tryFire(taser, track, root, myChar, range)
        if tick() < state.cursorBlockUntil then return false end
        local okR, rmb = pcall(ismouse2pressed)
        if okR and rmb then return false end
        enforceUnlock()
        local settle = state.unlockedAt + CFG.UNLOCK_SETTLE - tick()
        if settle > 0 then task.wait(settle) end
        if camLive() == true then return false end
        local lead = currentLead()
        local pos, why = aimAt(track, root, myChar, range, lead)
        if not pos then
            dbg("solve_" .. track.name, track.name .. " not fired: " .. tostring(why))
            return false
        end
        local cam = workspace.CurrentCamera
        local camBefore = cam.CFrame
        mousemoveabs(math.floor(pos.X + 0.5), math.floor(pos.Y + 0.5))
        task.wait(PERF.FRAME)
        if camTurned(camBefore, cam.CFrame) then
            state.cursorBlockUntil = tick() + CFG.CURSOR_GUARD_WAIT
            event("cursor turned the camera, shot aborted")
            return false
        end
        lead = currentLead()
        pos = aimAt(track, root, myChar, range, lead)
        if not pos then return false end
        mousemoveabs(math.floor(pos.X + 0.5), math.floor(pos.Y + 0.5))
        local before = taser:GetAttribute("LastUsedAt")
        mouse1click()
        local start = tick()
        while tick() - start < 0.5 do
            local after = taser:GetAttribute("LastUsedAt")
            if after ~= before then
                local cd = (taser:GetAttribute("NextUse") or 0) - after
                state.readyAt = tick() + math.max(cd, 0)
                state.shots = state.shots + 1
                local hit = cd >= CFG.HIT_COOLDOWN
                if hit then
                    state.hits = state.hits + 1
                    state.missBlock[track.name] = nil
                elseif track.vel.Magnitude < CFG.STILL_SPEED then
                    state.missBlock[track.name] = { pos = track.root.Position, untilT = tick() + CFG.MISS_BLOCK }
                end
                event(string.format("%s %s | %.0f studs | vel %.0f | %d/%d", hit and "HIT" or "MISS", track.name, track.dist, track.vel.Magnitude, state.hits, state.shots))
                return true
            end
            task.wait(PERF.FRAME)
        end
        state.readyAt = tick() + 0.3
        return true
    end

    local function findCuffConfig()
        local entries = {}
        for _, e in ipairs(lockedGetgc({ "ArrestDistance", "Duration", "ContentionDuration", "VerticalDistMult" })) do
            local v = tonumber(tostring(e.value))
            local a = tonumber(e.addr)
            if v and a then entries[#entries + 1] = { key = tostring(e.key), value = v, addr = a, raw = e } end
        end
        for _, anchor in ipairs(entries) do
            if anchor.key == "ArrestDistance" and anchor.value == 10 then
                local picked, original, hasMult = {}, {}, false
                for _, key in ipairs({ "Duration", "ContentionDuration" }) do
                    local best, bestDist
                    for _, e in ipairs(entries) do
                        local d = math.abs(e.addr - anchor.addr)
                        if e.key == key and d <= 512 and (not bestDist or d < bestDist) then best, bestDist = e, d end
                    end
                    if best then
                        picked[#picked + 1] = best.raw
                        original[key] = best.value
                    end
                end
                for _, e in ipairs(entries) do
                    if e.key == "VerticalDistMult" and math.abs(e.addr - anchor.addr) <= 512 then hasMult = true end
                end
                if #picked > 0 and hasMult then return picked, original end
            end
        end
        return nil
    end

    local function scanCuffConfig()
    end

    local function restoreConfig()
        if not state.cuffConfig then return end
        local o = state.cuffOriginal
        pcall(applygc, state.cuffConfig, {
            Duration = (o.Duration and o.Duration ~= 0) and o.Duration or 0.5,
            ContentionDuration = (o.ContentionDuration and o.ContentionDuration ~= 0) and o.ContentionDuration or 1,
        })
        state.cuffConfig, state.cuffOriginal = nil, nil
    end

    local function tryArrest(t)
        state.attempts = state.attempts + 1
        local instant = state.cuffConfig ~= nil
        local start = tick()
        keypress(CFG.KEY_E)
        if instant then
            task.wait(CFG.TAP)
            keyrelease(CFG.KEY_E)
        end
        local success = false
        local limit = instant and CFG.RESULT_TIMEOUT or CFG.HOLD_TIMEOUT
        while tick() - start < limit do
            task.wait(PERF.FRAME)
            if _G.JB_gen ~= myGen then break end
            if t.char:GetAttribute("HasHandcuffs") == true or circleHelp() == "Search" then
                success = true
                break
            end
        end
        if not instant then keyrelease(CFG.KEY_E) end
        state.retryAt[t.name] = tick() + CFG.RETRY
        if success then
            state.arrests = state.arrests + 1
            t.cuffed = true
            markArrested(t.name, CFG.ARRESTED_IGNORE, "arrested")
            notify(t.name .. " arrested", C.TITLE, 2)
        else
            local streak = (state.failStreak[t.name] or 0) + 1
            state.failStreak[t.name] = streak
            if streak >= CFG.FAIL_STREAK then
                markArrested(t.name, CFG.FAIL_IGNORE, streak .. " failed arrests in a row")
            end
        end
    end

    local function taserTargets(list, range)
        local cands = {}
        for _, t in ipairs(list) do
            if t.dist <= range + 5 and not t.rag and not t.cuffed and not t.seated
                and t.vel.Magnitude <= CFG.MAX_TARGET_SPEED and not missBlocked(t) then
                cands[#cands + 1] = t
            end
        end
        return cands
    end

    local function decide(list, taserOn, cuffOn, range, help)
        local now = tick()
        local inZone = {}
        if cuffOn then
            for _, t in ipairs(list) do
                if t.h <= CFG.CUFF_H and t.v <= CFG.CUFF_V and not t.cuffed then inZone[#inZone + 1] = t end
            end
            if isEjectPrompt(help) then
                for _, t in ipairs(inZone) do
                    if now >= (state.retryAt[t.name] or 0) then return "eject", t, false end
                end
            end
        end

        local cands = taserOn and taserTargets(list, range) or {}
        local hasCands = #cands > 0
        if hasCands and now >= state.readyAt and now >= state.blockedUntil then return "tase", cands, true end

        local holdTarget
        for _, t in ipairs(inZone) do
            if now >= (state.retryAt[t.name] or 0) and not t.seated then
                return "cuff", t, hasCands
            end
            holdTarget = holdTarget or t
        end

        if hasCands and state.readyAt - now <= CFG.PREARM then return "arm", cands[1], true end
        if holdTarget then return "hold", holdTarget, hasCands end

        if cuffOn then
            for _, t in ipairs(list) do
                if t.h <= CFG.CUFF_EQUIP_RANGE and t.v <= CFG.CUFF_EQUIP_RANGE and not t.cuffed then
                    return "precuff", t, hasCands
                end
            end
        end
        return "idle", nil, hasCands
    end

    local function doCuff(t, arrestWait)
        local cuffs = item("Handcuffs")
        if not cuffs then return end
        if not takeItem(cuffs) then return end
        local settle = state.equippedAt + CFG.EQUIP_SETTLE - tick()
        if settle > 0 then task.wait(settle) end
        local deadline = tick() + (arrestWait or CFG.ARREST_WAIT)
        while circleHelp() ~= "Arrest" and tick() < deadline do task.wait(0.03) end
        local help = circleHelp()
        if help == "Search" then
            markArrested(t.name, CFG.ARRESTED_IGNORE, "Search prompt")
            return
        end
        if help ~= "Arrest" then return end
        if t.char:GetAttribute("HasHandcuffs") == true then
            markArrested(t.name, CFG.ARRESTED_IGNORE, "HasHandcuffs")
            return
        end
        tryArrest(t)
    end

    local function doEject(t)
        local cuffs = item("Handcuffs")
        if not cuffs then return end
        if not takeItem(cuffs) then return end
        local settle = state.equippedAt + CFG.EQUIP_SETTLE - tick()
        if settle > 0 then task.wait(settle) end
        if not isEjectPrompt(circleHelp()) then return end
        local wasSeated = isSeated(t.name, t.root, true)
        local ejected = false
        local start = tick()
        keypress(CFG.KEY_E)
        while tick() - start < CFG.EJECT_TIMEOUT do
            task.wait(PERF.FRAME)
            if _G.JB_gen ~= myGen then break end
            local cur = circleHelp()
            if cur == "Arrest" or (wasSeated and not isSeated(t.name, t.root, true)) then
                ejected = true
                break
            end
            if tick() - start > 0.3 and not isEjectPrompt(cur) then break end
        end
        keyrelease(CFG.KEY_E)
        event(string.format("EJECT %s %s (%.2fs)", ejected and "OK" or "FAIL", t.name, tick() - start))
        if not ejected then
            state.retryAt[t.name] = tick() + CFG.RETRY
            return
        end
        t.seated = false
        doCuff(t, CFG.EJECT_ARREST_WAIT)
    end

    local function armTaser()
        local taser = item("Taser")
        if not taser then return nil end
        local ok, switched = takeItem(taser)
        if not ok then return nil end
        if switched then state.tipPart = nil end
        return taser
    end

    local function doTase(cands, root, myChar, range)
        local taser = armTaser()
        if not taser then return false end
        if tick() < state.equippedAt + CFG.TASER_SETTLE then
            local start = tick()
            while not findTip(root) and tick() - start < CFG.TIP_WAIT do task.wait(0.03) end
            local settle = state.equippedAt + CFG.TASER_SETTLE - tick()
            if settle > 0 then task.wait(settle) end
        end
        for _, t in ipairs(cands) do
            if not t.cuffed and tryFire(taser, t, root, myChar, range) then return true end
        end
        return false
    end

    local function anyWithin(list, range)
        for _, t in ipairs(list) do
            if not t.cuffed and t.h <= range and t.v <= range then return true end
        end
        return false
    end

    local function isDead(myChar)
        local hum = myChar and myChar:FindFirstChild("Humanoid")
        if not hum then return true end
        local ok, hp = pcall(function() return hum.Health end)
        return not ok or type(hp) ~= "number" or hp <= 0
    end

    local lastTaserArmed, lastCuffArmed = false, false
    local wasTaser, wasCuff, wasDead = false, false, false

    while _G.JB_gen == myGen do
        local waitTime = 0.05
        PERF.run("police", function()
            local taserArmed = UI.GetValue(uid("autoTaser")) and true or false
            local cuffArmed = UI.GetValue(uid("autoCuff")) and true or false
            if taserArmed ~= lastTaserArmed then
                lastTaserArmed = taserArmed
                notify(taserArmed and "Enabled" or "Disabled", T.TITLE, 3)
            end
            if cuffArmed ~= lastCuffArmed then
                lastCuffArmed = cuffArmed
                notify(cuffArmed and "Enabled" or "Disabled", C.TITLE, 3)
            end
            local taserOn = taserArmed and keybindActive(PERF.taseKeybind)
            local cuffOn = cuffArmed and keybindActive(PERF.cuffKeybind)
            state.active = taserOn or cuffOn

            if taserOn ~= wasTaser then
                wasTaser = taserOn
                if taserOn then
                    state.readyAt, state.blockedUntil, state.cursorBlockUntil, state.shots, state.hits = 0, 0, 0, 0, 0
                    state.camEntry, state.prefEntry = findCameraEntries()
                    state.camOriginal = camLive()
                    if state.camEntry then
                        camSet(false)
                        state.unlockedAt = tick()
                    end
                    notify("Auto Taser ON", T.TITLE, 2)
                else
                    if state.owned == "Taser" then release("taser disabled") end
                    local restored = restoreCamLock()
                    state.camEntry, state.prefEntry = nil, nil
                    notify(string.format("Auto Taser OFF (%d/%d hits)%s", state.hits, state.shots, restored == true and ", camera lock restored" or ""), T.TITLE, 2)
                end
            end
            if cuffOn ~= wasCuff then
                wasCuff = cuffOn
                if cuffOn then
                    state.retryAt, state.failStreak, state.attempts, state.arrests = {}, {}, 0, 0
                    scanCuffConfig()
                    notify("Auto Cuff ON" .. (state.cuffConfig and " (instant)" or ""), C.TITLE, 2)
                else
                    if state.owned == "Handcuffs" then release("cuff disabled") end
                    pcall(keyrelease, CFG.KEY_E)
                    restoreConfig()
                    notify(string.format("Auto Cuff OFF (%d/%d arrests)", state.arrests, state.attempts), C.TITLE, 2)
                end
            end

            if not taserOn and not cuffOn then
                waitTime = 0.25
                return
            end
            if not PERF.isHybrid() then
                if not state.hybridWarned then
                    state.hybridWarned = true
                    notify("Hybrid Mode required - enable it in Matcha", T.TITLE, 4)
                end
                waitTime = 0.5
                return
            end
            state.hybridWarned = false
            if PERF.solving then
                waitTime = 0.2
                return
            end
            if taserOn then enforceUnlock() end

            local myChar = lp.Character
            local root = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local dead = not root or isDead(myChar)
            if dead ~= wasDead then
                wasDead = dead
                if dead then
                    state.owned, state.prevItem, state.inHand, state.tipPart = nil, nil, nil, nil
                    state.equippedAt, state.equipFailUntil = 0, 0
                    pcall(keyrelease, CFG.KEY_E)
                end
            end
            if dead then
                waitTime = 0.25
                return
            end
            syncHand()
            if not isrbxactive() or not string.find(tostring(lp.Team), "Police", 1, true) then
                waitTime = 0.2
                return
            end
            if isSeated("__me", root) then
                waitTime = 0.2
                return
            end

            local help = circleHelp()
            local range = tonumber(UI.GetValue(uid("autoTaserRange"))) or CFG.TASE_RANGE
            local list = gather(root)
            markSearched(list, help)
            local action, arg, taserTarget = decide(list, taserOn, cuffOn, range, help)
            dbg("action", "action = " .. action)

            local now = tick()
            if action == "cuff" or action == "hold" or action == "precuff" or action == "eject" then state.needCuffAt = now end
            if state.owned == "Handcuffs" and cuffOn and anyWithin(list, CFG.CUFF_KEEP_RANGE) and action ~= "tase" and action ~= "arm" then
                state.needCuffAt = now
            end
            if taserTarget then state.needTaserAt = now end

            if action == "tase" then
                if not doTase(arg, root, myChar, range) then state.blockedUntil = tick() + CFG.BLOCKED_WAIT end
                waitTime = 0.03
            elseif action == "cuff" then
                doCuff(arg)
                waitTime = 0.03
            elseif action == "eject" then
                doEject(arg)
                waitTime = 0.03
            elseif action == "arm" then
                local taser = item("Taser")
                if taser and not held(taser) then armTaser() end
            elseif action == "precuff" or action == "hold" then
                local cuffs = item("Handcuffs")
                if cuffs and not held(cuffs) then takeItem(cuffs) end
            end

            now = tick()
            if state.owned == "Handcuffs" and (not cuffOn or now - state.needCuffAt >= CFG.CUFF_RELEASE) then
                release("cuffs not needed")
            elseif state.owned == "Taser" and (not taserOn or now - state.needTaserAt >= CFG.TASER_RELEASE) then
                release("no taser target")
            end
        end)
        task.wait(waitTime)
    end
    state.active = false
    pcall(keyrelease, C.KEY_E)
    pcall(release, "unloaded")
    pcall(restoreCamLock)
    pcall(restoreConfig)
end)

task.spawn(function()
    local was = {}
    while _G.JB_gen == myGen do
        PERF.run("hybridGate", function()
            for _, id in ipairs(PERF.HYBRID_IDS) do
                local on = UI.GetValue(uid(id)) and true or false
                if on and not was[id] and not PERF.requireHybrid("[JB Hub] " .. id) then
                    pcall(function() UI.SetValue(uid(id), false) end)
                    on = false
                end
                was[id] = on
            end
        end)
        task.wait(0.1)
    end
end)

task.spawn(function()
    local LIST = {
        { "Auto-Solve Puzzle", function() return PERF.holdKb.puzzle end },
        { "Get Casino Code", function() return PERF.holdKb.casino end },
        { "Open Casino Door", function() return PERF.holdKb.casinoOpen end },
        { "Auto Vault", function() return PERF.holdKb.vault end },
        { "Apply Cosmetics", function() return PERF.holdKb.cosmetics end },
        { "PlasmaPistol Killaura", function() return PERF.kaKeybind end },
        { "Kill All NPCs", function() return PERF.killKeybind end },
        { "Vehicle Fly", function() return VEHICLE.flyKeybind end },
        { "Engine Boost", function() return VEHICLE.boostKeybind end },
        { "Instant Brake", function() return VEHICLE.brakeKeybind end },
        { "Instant Auto Cuff", function() return PERF.cuffKeybind end },
        { "Auto Taser", function() return PERF.taseKeybind end },
    }
    local last, primed = {}, false
    while _G.JB_gen == myGen do
        PERF.run("keyGuard", function()
            local cur = {}
            for i, e in ipairs(LIST) do
                local kb = e[2]()
                local ok, k = pcall(function() return kb:GetKey() end)
                cur[i] = { kb = kb, key = (ok and type(k) == "number") and k or nil }
            end
            for i, c in ipairs(cur) do
                if primed and c.key and c.key ~= 0 and c.key ~= last[i] then
                    for j, o in ipairs(cur) do
                        if j ~= i and o.key == c.key then
                            local okN, name = pcall(function() return c.kb:GetKeyName() end)
                            local back = last[i] or 0
                            pcall(function() c.kb:SetKey(back) end)
                            c.key = back
                            notify("Key " .. string.upper(okN and tostring(name) or "?") .. " is already used by " .. LIST[j][1], "[JB Hub] " .. LIST[i][1], 4)
                            break
                        end
                    end
                end
                last[i] = c.key
            end
            primed = true
        end)
        task.wait(0.3)
    end
end)

task.spawn(function()
    if not PERF.profile then return end
    PERF.profileHooks()
    local c = PERF.cnt
    local last = os.clock()
    local lastReport, startAt = last, last
    local frames, maxGap, worstWho = 0, 0, ""
    local b33, b100, b250 = 0, 0, 0
    local memStart, memLast
    local function luaMem()
        local ok, kb = pcall(gcinfo)
        if ok and type(kb) == "number" then return kb end
        local ok2, kb2 = pcall(collectgarbage, "count")
        return ok2 and type(kb2) == "number" and kb2 or nil
    end
    local function fmtTop(map, n, unit)
        local rows = {}
        for k, v in pairs(map) do rows[#rows + 1] = { k, v } end
        table.sort(rows, function(a, b) return a[2] > b[2] end)
        local out = {}
        for i = 1, math.min(n, #rows) do out[#out + 1] = string.format("%s %s%s", rows[i][1], unit == "ms" and string.format("%.0f", rows[i][2] * 1000) or tostring(rows[i][2]), unit or "") end
        return #out > 0 and table.concat(out, ", ") or "-"
    end
    memStart = luaMem()
    while _G.JB_gen == myGen and not SPLASH.done do task.wait(0.1) end
    task.wait(0.2)
    memStart = luaMem()
    memLast = memStart
    last, lastReport, startAt = os.clock(), os.clock(), os.clock()
    PERF.profileLog({ string.format("[JBProfile] started %s | every %ds | log: JB Hub/profile.log", os.date and os.date("%H:%M:%S") or "", PERF.PROFILE_EVERY) })
    while _G.JB_gen == myGen do
        task.wait(PERF.FRAME)
        local now = os.clock()
        local gap = now - last
        last = now
        frames = frames + 1
        PERF.frameNo = PERF.frameNo + 1
        if gap > 0.033 then b33 = b33 + 1 end
        if gap > 0.1 then b100 = b100 + 1 end
        if gap > 0.25 then b250 = b250 + 1 end
        if gap > maxGap then
            maxGap = gap
            worstWho = fmtTop(PERF.frameWork, 3, "ms")
        end
        PERF.frameWork = {}
        if now - lastReport >= PERF.PROFILE_EVERY then
            local window = now - lastReport
            lastReport = now
            local mem = luaMem()
            local lines = {}
            lines[#lines + 1] = string.format("[JBProfile] ===== %.0fs | loop %d Hz | worst gap %.0fms (%s) | stalls >33ms %d, >100ms %d, >250ms %d",
                now - startAt, frames / window, maxGap * 1000, worstWho, b33, b100, b250)
            lines[#lines + 1] = string.format("[JBProfile] lua mem %s KB (%s since last, %s since start) | drawings created %d (total %d) | notify %d",
                mem and string.format("%.0f", mem) or "?", (mem and memLast) and string.format("%+.0f", mem - memLast) or "?", (mem and memStart) and string.format("%+.0f", mem - memStart) or "?", c.draw, c.drawTotal, c.notify)
            lines[#lines + 1] = string.format("[JBProfile] getgc %d calls %.0fms total max %.0fms | memory read %d/s write %d/s | by: %s",
                c.gc, c.gcTime * 1000, c.gcMax * 1000, math.floor(c.memr / window), math.floor(c.memw / window), fmtTop(c.memBy, 5))
            if c.draw > 0 then lines[#lines + 1] = "[JBProfile] drawings created by: " .. fmtTop(c.drawBy, 6) end
            if c.notify > 0 then lines[#lines + 1] = "[JBProfile] notify by: " .. fmtTop(c.notifyBy, 6) end
            local rows = {}
            for name, s in pairs(PERF.stats) do rows[#rows + 1] = { name = name, s = s } end
            table.sort(rows, function(a, b) return a.s.total > b.s.total end)
            for i = 1, math.min(#rows, 12) do
                local s = rows[i].s
                lines[#lines + 1] = string.format("[JBProfile]   %-18s %6.1fms/s | %5d calls avg %.2fms max %.0fms | slow %d | waited %d | err %d",
                    rows[i].name, s.total / window * 1000, s.calls, s.total / math.max(s.calls - s.waits, 1) * 1000, s.max * 1000, s.slow, s.waits, s.errors)
            end
            for _, r in ipairs(rows) do
                for msg, n in pairs(r.s.errs) do
                    lines[#lines + 1] = string.format("[JBError] %s x%d: %s", r.name, n, msg)
                end
            end
            PERF.profileLog(lines)
            PERF.stats, maxGap, worstWho, frames, b33, b100, b250 = {}, 0, "", 0, 0, 0, 0
            c.memr, c.memw, c.gc, c.gcTime, c.gcMax, c.draw, c.notify = 0, 0, 0, 0, 0, 0, 0
            c.drawBy, c.notifyBy, c.memBy = {}, {}, {}
            memLast = mem
        end
    end
end)

SPLASH.run()
print("[JB Hub] successfully loaded ! Welcome " .. SPLASH.userName() .. " !")
notify("JB", "Welcome " .. SPLASH.userName() .. " !", 4)
