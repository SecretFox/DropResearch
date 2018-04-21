# DropResearch

**Donwload**  
[![alt text](https://i.imgur.com/guClKqN.png "Download")](https://github.com/SecretFox/DropResearch/releases)

**Install**  
Unzip to `Secret World Legends\Data\Gui\Custom\Flash\` folder.  
Swf path should be `Secret World Legends\Data\Gui\Custom\Flash\DropResearch\DropResearch.swf` 


**About**  
Tracks Dossiers from Dungeons,Raids,Scenarios,Regionals and Missions.  
Only chests that have chance to drop dossier are counted towards Dungeons/Raids/Regionals.  
Also stores loot from raids and Caches.  
Data is stored per character, and persists between reloadui/restarting the game.

Data will be sent to http://secretfox.pythonanywhere.com/ when bank is opened, but max once per hour.  
Alternatively you can force synchronization with `/Option DropResearch_ForceSync true` chat command.  
Once upload has been completed all local data will be wiped to avoid inflating the preference file.

To view data collected by you, you can use `/Option DropResearch_ShowData true` chat command.

**Known Issues**
* Mission tracking won't work with my other mod, MissionUtils, because it bypasses the missionreport window.
* Currently no way to tell which Weapon/Talisman player got from the bag received from cache.
* Uploader.as file was not included in the source files, to make sending fake data slightly harder.


**TODO?**
* Support for tracking consumables? Bit tricky,but should be possible.
* Better layout for the web-page
* Combine some of the cache data, if it starts looking like all of them have equal chances for distillates/3rd Age Fragments.
