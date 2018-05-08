# DropResearch

**Donwload**  
[![alt text](https://i.imgur.com/812P61A.png "Download")](https://github.com/SecretFox/DropResearch/releases)

**Install**  
Unzip to `Secret World Legends\Data\Gui\Custom\Flash\` folder.  
Swf path should be `Secret World Legends\Data\Gui\Custom\Flash\DropResearch\DropResearch.swf` 


**About**  
* Tracks dossiers from Dungeons,Raids,Scenarios,Regionals and Missions. Only chests and missions that have a chance to drop dossier are counted.
* Tracks loot from raids and Caches.  
* Tracks loot from consumables;
    * Glyph Reward bags
    * Agent Vanity reward bags
    * Agent Boosters
    * Agent gear reward bags
    * Kaidan container keys
    * Extraordinary talisman reward bag(Tribal)
    * It's very easy for me to add more


Data is stored locally for each characters,and persists between restarts.
There should be no issues using alts or running the mod on multiple computers.  

Collected data will get sent to http://secretfox.pythonanywhere.com/ when bank, Tradepost, or vendor is opened,but only max once per hour.
Alternatively you can force synchronization with `/Option DropResearch_ForceSync true` chat command.  
Once upload has been completed all locally stored data will be wiped.

To view your data on in-game browser you can use `/Option DropResearch_ShowData true` chat command. 
You can copy and share the browser address to share your data with others.  

**Privacy**  
* Theoretically anyone could access your collected data if they knew your characterID, however finding it would require some modding experience, as it is not visibly listed anywhere on the main site or game. I'll see if i can add some privacy settings in the future though.

**Chat commands**  
    `/option DropResearch_ShowData` Displays your collected data  
    `/option DropResearch_Debug` Enables Debug mode  
    `/option DropResearch_ForceSync` Forces data upload  
    `/option DropResearch_PlayerID` Prints out playerID (v.0.4.0 and up)  
    `/option DropResearch_Version` Print out current mod version (v.0.4.0 and up)  

**Shortening chat commands**  
The Chat commands are bit long, but there is a way to shorten them through "alias", here are some examples.  
`/alias sync option DropResearch_ForceSync true` allows you to upload your data with `/sync`  
`/alias dropdata option DropResearch_ShowData true` allows you to view your own statistics with `/dropdata`  
Aliases are account wide,and you only need to create them once.

**Known Issues**
* Mission tracking won't work with my other mod, MissionUtils, because it bypasses the missionreport window.  
* Glyph bags and Container keys opened by BagUtil mod are not tracked.  
* Uploader.as file was not included in the source files, to make sending fake data slightly harder.  

**TODO?**
* More things to track?
* Bugs?
