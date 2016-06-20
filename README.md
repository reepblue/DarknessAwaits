# Darkness Awaits (Leadwerks Template) #

I found the old install of the 3.0 demo that included assets from the old sample game "Darkness Awaits". While models, textures of this project might be on the workshop, I don't think the scripts are. The engine has come a long way since 3.0 and instead of simply just porting assets into the newer engine and call it a day, I took the time to streamline code, textures, and fix things that were broken in the old demo. This way, the template is another example of how to make games using Leadwerks!

###Changes include:###

- The start map has been updated visually showing off the current features of the engine such as deferred shadows and decals. There is now more Goblins!
- Normal maps are now blue instead of the magenta color they where before.
- Adjusted some speculator settings in most materials.
- Removed any instances of mobile/touch controls.
- All code works with current SDK scripts (Such as the current PushButton.lua).
- Barbarian and Goblin models both have normal and spec maps for their sheets and weapons.
- The Player now dies and displays a GameOver screen.
- Player's healthbar has been fixed when the player's health reached 0.
- Player and Goblin scripts now use the ReleaseTables script.
- Other compatibility edits.
- Player and Goblin scripts calls animation names instead of sequence numbers.
- The Player's Delete() function got replaced with Release().
- Fixed Goblin's Navigation code.
- Goblins now stop attacking the player when they are dead.
- Player code now creates a camera instead of the mapper having to add one.
- Player and Goblins now have footsteps sounds.
- Models had their shapes redone in the model editor instead of the old shape tool that's under the Legacy Features.
- Added Crate Model.
- Prefabs were updated/fixed.
- Removed the switch prefab (it was broken, and broke the editor).
- The template still uses the older App.lua due to it's menu system. However, it's been modified to include newer additions in later versions of that script. (map changing, settings via Properties)

Install it under ...\Steam\steamapps\common\Leadwerks Game Engine\Templates. Should work on both Windows and Linux. I ported this project due to the fact I felt like this game showed how to make a simple menu/startscreen in Lua without needing FlowGUI, LEX, or other things.  

Also another reminder that I just did the port/fixes. "Darkness Awaits" was originally created by Josh Klint, Chris Vossen, Rich Digiovanni, and other members who where involved. Again, I did this out of curiosity, and I thought it would benefit the community if it was re-released as a template. If you have any problems, let me know.