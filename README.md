[quickbar]: https://i.ibb.co/pXVrSgL/quickbar-highlighted.png "Button location in the quickbar"
[controls]: https://i.ibb.co/6Jm8Wr2/hotkey.png "Keyboard configuration"
[selection]: https://i.ibb.co/DQz1vw0/selection.png "Screenshot of the selection tool"

# Bot Prioritizer 0.1.4

## A mod to help with building things quicker

Have you ever stood in front of a large blueprint that is going **to be built** or things **to be upgraded** with all the neccessary things **in your pocket** and your **personal robots ready to go**, but **nothing happens** because the **base robots** took the job and are on their long, long way?  
Or have you ever **deconstructed** a few things to quickly **place them somewhere else** but the base robots **took everything far away** into the central logistics storage?

**Then this mod is for you!** With this tool you can select entities and try to **re-issue the work orders**, so that your **personal construction bots can take over!**

-------------------------------------

## What's being provided by this mod?

This mod provides a selection-tool that doesn't have to be researched or crafted. Since it doesn't change a thing in your game and only gives your personal robots priority I don't find it neccessary to set any hurdles to use the tool.  

After installing the mod, there are two ways to use it:

- You can click the shortcut button located next to the quickbar here:  
![Button location in the quickbar][quickbar]

- Or you can use the keyboard hotkey, which defaults to **CONTROL + D**:
![Keyboard configuration page][controls]

## New in 0.1.4

There's also an option to just use the current personal roboport area as selection area! This way is much quicker to take over robot jobs!

------------------------

## How to use the mod?

Each of the two previsouly shown options will either **activate the selection tool** or **do the re-prioritization right away**, depending on the **mod settings**. 

If you have set the mod to **use the selection tool**, the cursor will show the mod icon and if you click-and-drag to select an area there will be a purple border.

After making a selection, the mod will re-issue the construction/deconstruction/upgrade commands for the selected entities, so your personal robots will get a chance to take over the job. Those poor base robots will turn around and go back and put their things back into storage.

It will work on:

1. Entity Ghosts/Construction Orders
2. Deconstruction Orders
3. Upgrade Orders

![Screenshot of the selection tool][selection]

Currently I'm still working on Item Request Orders, i.e. module requests for assemblers, fuel requests for trains. I'm not sure if this is already covered by Upgrade Orders.

------------------------

## How does it even work?

This section is just for those, who are interested in some implementation details and a little history about the mod. You can skip this, everything has been explained above ;) 

This mod was inspired by the trick I have learned from Nilaus: If you want your personal robots to take over, simply deconstruct everything and quickly press CTRL+Z to undo it. Now the personal robot take over. 

So I thought to myself "This must be easy! I'll quickly write a little mod." ... Wrong. Since you cannot access the undo function using the Factorio API I had to do everything manually. Essentially this mod clones existing ghosts at the same location and removes the original, cancels and reissues deconstruction commands and (through some magic) cancels upgrades and orders them again.

Especially those upgrades are really finnicky. The function that should return the desired end result of upgrades (```get_upgrade_target()```) didn't return anything for me. So I had to find a workaround that doesn't rely on this function.

Luckily @Optera mentioned an alternative in a comment  in another mod's discussion page: Instead of using the function (which is even described as being very slow in the official documentation), the mod hooks into the ```on_marked_for_upgrade``` and ```on_cancelled_upgrade``` to keep a persistent list of all the upgrades and their desired outcomes. Of course there's also a routine that purges old and invalid entries from this list. This way the mod can modify those upgrade orders very fast; probably faster than the built-in function.

------------------

## Credits

Credit where credit is due:

- [Nilaus](https://www.twitch.tv/nilaus), who streams over at Twitch.tv and makes excellent YouTube videos, for the original method that inspired this mod!
- [Optera](https://mods.factorio.com/user/Optera) for the [idea](https://mods.factorio.com/mod/GhostScanner/discussion/5d4e4346bf0746000dcd3c55) that made handling upgrades possible.
- Thanks to [Nexela](https://mods.factorio.com/user/Nexela) for taking the time to refactor and improve my code when I asked for advice! 
- Thanks to [Theanderblast](https://mods.factorio.com/user/Theanderblast). I shamelessly copied a few things from his [Max Rate Calculator](https://mods.factorio.com/mod/MaxRateCalculator) mod because I had no idea how to add such a tool into the game.