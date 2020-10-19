[quickbar]: https://i.ibb.co/pXVrSgL/quickbar-highlighted.png "Button location in the quickbar"
[controls]: https://i.ibb.co/6Jm8Wr2/hotkey.png "Keyboard configuration"
[selection]: https://i.ibb.co/DQz1vw0/selection.png "Screenshot of the selection tool"
[settings]: https://i.ibb.co/bPcxvDH/settings-0-2-0.png "Mod settings"

# Bot Prioritizer 0.2.1

## A mod to help with building things quicker

Have you ever stood in front of a large blueprint that is going **to be built** or things **to be upgraded** with all the necessary things **in your pocket** and your **personal robots ready to go**, but **nothing happens** because the **base robots** took the job and are on their long, long way?  
Or have you ever **deconstructed** a few things to quickly **place them somewhere else** but the base robots **took everything far away** into the central logistics storage?

**Then this mod is for you!** With this tool you can select entities and try to **reissue the work orders**, so that your **personal construction bots can take over!**

-------------------------------------

## What's being provided by this mod?

This mod provides the ability to reassign/'reprioritize'/reissue jobs to your personal robots.  
You have the options to  

- Use a **Selection Tool** that doesn't have to be researched or crafted, or to
- just reassign jobs in your **personal roboport construction area directly** (**Direct Selection**) or
- if you're as lazy as a Factorian usually is, you can let to jobs be reassigned continuously (**Auto-Mode**)! 
&nbsp;

You can choose between these options in the mod settings on the "Per player" tab:  
![Mod settings - version 0.2.0][settings]  
(Settings of version 0.2.0. If you hover over the option name on the left, there are little descriptions of the options.)

------------------------

## How to use the mod?

After installing the mod, there are two ways to use it:

- You can click the shortcut button located next to the quickbar here:  
![Button location in the quickbar][quickbar]

- Or you can use the keyboard hotkey, which defaults to **CONTROL + D**:  
![Keyboard configuration page][controls]

Each of the two options will either **activate the selection tool** or **do the reprioritization right away**, depending on the **mod settings**. 

If you have set the mod to **use the selection tool**, the cursor will show the mod icon and if you click-and-drag to select an area there will be a purple border.

After making a selection, the mod will reissue the construction/deconstruction/upgrade commands for the selected entities, so your personal robots will get a chance to take over the job.  
Those poor base robots will turn around and go back and put their things back into storage.

It will work on:

1. Entity Ghosts/Construction Orders
2. Deconstruction Orders
3. Upgrade Orders
4. Item Request Slots (Modules, Fuel, ...)

![Screenshot of the selection tool][selection]

------------------------

## Caveats/Known issues/Things under construction

- Robotports on vehicles (train, spidertron, car, ...) currently aren't supported. To prioritize work orders in range of a **Spidertron** use the selection tool and disable the inventory checks in the mod settings.

------------------

## Credits

Credit where credit is due:


- Thanks to reddit users [u/Thinkingwithportals1](https://www.reddit.com/user/Thinkingwithportals1), who posted the [thread](https://www.reddit.com/r/factorio/comments/j614f4/400_hours_in_im_still_discovering_tricks/g7vq7nb/) and [u/DerUwe](https://www.reddit.com/user/DerUwe) whose [comment](https://www.reddit.com/r/factorio/comments/j614f4/400_hours_in_im_still_discovering_tricks/g7vq7nb/) sparked the idea to make a mod out of "undoing" build orders.
- [Nilaus](https://www.twitch.tv/nilaus), who streams over at Twitch.tv and makes excellent YouTube videos, for the original method that also inspired this mod!
- Thanks to [Panterh3art](https://mods.factorio.com/user/Panterh3art) for suggesting a automatic mode.
- A very special thanks to [aaron311](https://mods.factorio.com/user/aaron311)! They helped me a lot and have been (and are) a great sparring partner for various issues, like the Auto-Mode of 0.2.0.  
Most importantly [aaron311](https://mods.factorio.com/user/aaron311) created a very similar mod a while back, check it out! It's called [TacticalConstruction](https://mods.factorio.com/mod/TacticalConstruction).
- Thanks to [Optera](https://mods.factorio.com/user/Optera) for the [idea](https://mods.factorio.com/mod/GhostScanner/discussion/5d4e4346bf0746000dcd3c55) that made handling upgrades possible.
- Thanks to [Nexela](https://mods.factorio.com/user/Nexela) for taking the time to refactor and improve my code when I asked for advice! 
- Thanks to [Theanderblast](https://mods.factorio.com/user/Theanderblast). I shamelessly copied a few things from his [Max Rate Calculator](https://mods.factorio.com/mod/MaxRateCalculator) mod because I had no idea how to add such a tool into the game.