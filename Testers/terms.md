⚠️ About short freezes when enabling some features

When you turn on certain features, your game can freeze for a few seconds (usually 2-10s). This is normal and it only happens once.

Why? These features need to find specific values in the game's memory. To do that, JB Hub uses Matcha's memory scan (getgc), and while it runs, everything waits until the scan is done. JB Hub can't make the scan itself faster, it's how Matcha works. The longer you've been in the server, the bigger the game's memory gets, so the freeze can last a bit longer late in a session.

Features that can cause this one-time freeze:
• Modifiers: Instant Interaction, No Recoil, No Spread, Sword mods, Infinity Nitro / Jetpack, Auto Shoot, Punch No Cooldown, Rocket Instant Lock, Plasma mods
• Weapons: Hit Sound
• Misc: Anti Taser
• Police: Auto Taser, Auto Cuff
• Vehicle: Engine Boost
• Robbery protections: Disable Forcefields (Mansion CEO aura), No Turret Damage

When does it happen?
• When you enable one of these features
• When you pick up a weapon type you didn't have before (the hub scans for its config)
• Sometimes after respawning

Tips:
• Enable all the features you want at once (or load your config). The hub groups the scans, so you get one freeze instead of several.
• Don't spam the toggle on/off, every new activation can trigger a new scan.
• After that, the features keep working with no more freezes.

If your game freezes for much longer than 10 seconds, or crashes, send us your workspace/JB Hub/crash.log 🙏