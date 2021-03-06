OpenTimer (Read this!)
============

SourceMod timer plugin for *CSS* and *CS:GO* bunnyhop servers. Yes, it is free as in freedom.
Test it out @ 98.166.83.179:27016 (CSS)

The plugin is written in new syntax which requires **SourceMod version 1.7**!

**Read opentimer_log.txt if you want to know what changes have been made!**

**Features:**

- Easy to setup.
- Timer with records and playback.
- Times saved with SQLite and recordings saved in binary.
- Seamlessly combines legit and autobhop, making both work on a single server at the same time.
- Toggle HUD elements, change FOV, etc.
- Zone building (Starting-Ending/Block/Freestyle/Bonus1-2 Zones/Checkpoints)
- Practising with multiple save points.
- Anti-doublestepping Technology(TM)
- Simple map voting. (Optional)


**Dependencies (Optional) (CSS):**

- For 260vel weapons: https://forums.alliedmods.net/showthread.php?t=166468
- For multihop (Maps with func_door platforms.): https://forums.alliedmods.net/showthread.php?t=90467


**Download links:**

https://dl.dropboxusercontent.com/u/142067828/download/opentimer.zip - CSS
https://dl.dropboxusercontent.com/u/142067828/download/opentimer_csgo.zip - CS:GO


**How to install:**

    1. You can download the sourcecode and the plugin by pressing the 'Download ZIP'-button on the right-side. If you do not wish to do that, you can use the links above to only download the plugin.
    2. Unzip files opentimer_csgo.smx OR opentimer.smx (Depending which game you're hosting) and place it in your <gamefolder>/addons/sourcemod/plugins directory. You're done!


**Things to remember:**

    - Make sure your admin status is root to create/delete zones. (configs/admins.cfg)
    - Use the chat command !zone to configure zones.
    - !removerecords lets you choose which records and checkpoint records to remove.
    - You can add/remove some functions such as recording or fancy chat by commenting out first few lines in the opentimer.sp file and then recompiling it.
    - !r, !respawn can be used to respawn.
    - Rest of the commands can be found with !commands.
    - This plugin will automatically create a new database called 'opentimer'. You are no longer required to change databases.cfg.
    - By default, max recording length is 45 minutes. Times can be however long.


**Required server commands for bunnyhop-gamemode to work:**

    - sv_enablebunnyhopping 1 ('sm_cvar sv_enablebunnyhopping 1' for CS:GO)
    - bot_quota_mode normal
    - sv_hudhint_sound 0 (CSS)
    - mp_ignore_round_win_conditions 1
    - mp_autoteambalance 0
    - mp_limitteams 0


**Other commands you might find useful:**

    - sv_allow_wait_command 0


**Plugin commands:**

    timer_autobhop 0/1 (Def. enabled)
    timer_ezhop 0/1 (Def. enabled)
    timer_allow_leftright 0/1 (+left/+right allowed? Def. enabled)
    timer_ac_strafevel 0/1 (Do we check for strafe inconsistencies? **Experimental anti-cheat** Def. enabled)
    timer_prespeed 0/3500 (What is our prespeed limit? 0 = No limit. Def. 300)
    timer_smoothplayback 0/1 (If false, show more accurate but not as smooth playback. Def. enabled)
    timer_allow_sw 0/1 (Allow Sideways-style? Def. enabled)
    timer_allow_w 0/1 (Allow W-Only-style? Def. enabled)
    timer_allow_hsw 0/1 (Allow HSW-style? Def. enabled)
    timer_allow_rhsw 0/1 (Allow Real HSW-style? Def. enabled)
    timer_allow_ad 0/1 (Allow A/D-Only-style? Def. enabled)
    timer_allow_mode_auto 0/1 (Is Autobhop-mode allowed? Def. enabled)
    timer_allow_mode_scroll 0/1 (Is Scroll-mode allowed? Def. enabled)
    timer_allow_mode_velcap 0/1 (Is VelCap-mode allowed? Def. enabled)
    timer_velcap_limit 250/3500 (Vel-Cap-style's limit. Def. 400)
    timer_bonus_normalonlyrec 0/1 (Do we allow only normal style to be recorded in bonuses? Prevents mass bots. Def. enabled)
    timer_def_airaccelerate <num> (What is autobhop air acceleration? (DO NOT USE sv_airaccelerate) Def. 1000)
    timer_scroll_airaccelerate <num> (What is scroll/velcap air acceleration? (DO NOT USE sv_airaccelerate) Def. 100)
    timer_maxbots <num> (Max bots to spawn. Def. 8)
    timer_def_mode <num> (What mode is the default one? 0 = Autobhop, 1 = Scroll, 2 = Scroll + VelCap. Def. 0)
    timer_fps_style <num> (How do we determine player's FPS in scroll modes? 0 = No limit. 1 = FPS can be more or equal to server's tickrate. 2 = FPS must be 300. Def. 1)


**Creating a .nav file for maps:** (Required for record bots. Tell Valve how much you hate it.)

- Local server and the map you want to generate the .nav file for.
- Aim at the floor and type this in your console: *sv_cheats 1; nav_edit 1; nav_mark_walkable*. This should generate .nav file in your maps folder. If it doesn't, type *nav_generate*.
- Move that into your server's maps folder. Potentially put it in your fast-dl. ;)


**TO-DO LIST:**

- Whatever I can still come up with.
- Fix everything.
