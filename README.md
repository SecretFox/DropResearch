# DropResearch

**Donwload**  
[![alt text](https://i.imgur.com/bFEPBzA.gif "Download")](https://github.com/SecretFox/DropResearch/releases)

**Install**  
Unzip to `Secret World Legends\Data\Gui\Custom\Flash\` folder.  
Swf path should be `Secret World Legends\Data\Gui\Custom\Flash\DropResearch\DropResearch.swf` 


**About**  
Tracks dossiers from Dungeons,Raids,Scenarios,Regionals and Missions.  
Only chests/missions that have a chance to drop are counted.  

Also stores loot from raids and Caches.  
Data is stored per character, and persists between reloadui/restarting the game.  
There should be no issues using alts or other running the mod on multiple computers.

Collected data will get sent to http://secretfox.pythonanywhere.com/ when bank is opened, but max once per hour.  
Alternatively you can force synchronization with `/Option DropResearch_ForceSync true` chat command.  
Once upload has been completed all locally stored data will be wiped.

You can use `/Option DropResearch_ShowData true` chat command, to open in-game browser with your collected data.  
You can copy and share the browser address to share your data with others.

**Known Issues**
* Mission tracking won't work with my other mod, MissionUtils, because it bypasses the missionreport window.
* Currently no way to tell which Weapon/Talisman player got from the bag received from cache.
* Uploader.as file was not included in the source files, to make sending fake data slightly harder.


**TODO?**
* Support for tracking consumables? Bit tricky,but should be possible.
* Better layout for the web-page
* Combine some of the cache data, if it starts looking like all of them have equal chances for distillates/3rd Age Fragments.
