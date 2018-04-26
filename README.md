# DropResearch

**Donwload**  
[![alt text](https://i.imgur.com/bFEPBzA.gif "Download")](https://github.com/SecretFox/DropResearch/releases)

**Install**  
Unzip to `Secret World Legends\Data\Gui\Custom\Flash\` folder.  
Swf path should be `Secret World Legends\Data\Gui\Custom\Flash\DropResearch\DropResearch.swf` 


**About**  
* Tracks dossiers from Dungeons,Raids,Scenarios,Regionals and Missions. Only chests and missions that have a chance to drop dossier are counted.
* Tracks loot from raids and Caches.  
* Tracks loot from consumables, such as filthy key.

Data is stored locally for each characters,and persists between restarts.
There should be no issues using alts or other running the mod on multiple computers.

Collected data will get sent to http://secretfox.pythonanywhere.com/ whenever; bank is opened, Tradepost is opened, or vendor is opened. However upload will happen only once per hour max.
Alternatively you can force synchronization with `/Option DropResearch_ForceSync true` chat command.  
Once upload has been completed all locally stored data will be wiped.

To view your data on in-game browser you can use `/Option DropResearch_ShowData true` chat command. 
You can copy and share the browser address to share your data with others.  

**Chat commands**  
    `/option DropResearch_ShowData` Displays your collected data  
	`/option DropResearch_Debug` Enables Debug mode  
	`/option DropResearch_ForceSync` Forces data upload  
	`/option DropResearch_PlayerID` Prints out playerID (v.0.4.0 and up)  
	`/option DropResearch_Version` Print out current mod version (v.0.4.0 and up)  

**Shortening chat commands**  
The Chat commands are bit long, but there is a way to shorten them through "alias", here are some examples.  
`/Alias sync option DropResearch_ForceSync true` will allow you to upload your data with `/sync`  
`/Alias dropdata option DropResearch_ShowData true` will allow you to view your own statistics with `/dropdata`  

**Known Issues**
* Mission tracking won't work with my other mod, MissionUtils, because it bypasses the missionreport window.
* Uploader.as file was not included in the source files, to make sending fake data slightly harder.

**TODO?**
* Combine some of the cache data, if it starts looking like all of them have equal chances for distillates/3rd Age Fragments.
