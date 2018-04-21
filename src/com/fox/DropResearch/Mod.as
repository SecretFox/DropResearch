/**
 * ...
 * @author fox
 */
import com.GameInterface.DistributedValue;
import com.GameInterface.DistributedValueBase;
import com.GameInterface.GUIModuleIF;
import com.GameInterface.Game.Character;
import com.GameInterface.Game.CharacterBase;
import com.GameInterface.GroupFinder;
import com.GameInterface.Inventory;
import com.GameInterface.InventoryItem;
import com.GameInterface.QuestsBase;
import com.GameInterface.UtilsBase;
import com.Utils.Archive;
import com.Utils.ID32;
import com.Utils.LDBFormat;
import com.fox.DropResearch.DossierHandler;
import com.fox.DropResearch.Uploader;
import mx.utils.Delegate;

class com.fox.DropResearch.Mod {

	// Tells us when to start tracking added items
	private var MissionCompletedSignal:DistributedValue;

	//Selected groupfinder entry, used to tell apart NYR story/E1/E5/E10
	private var GroupFinderID:DistributedValue;
	
	private var Debug:DistributedValue;
	private var ForceSync:DistributedValue;
	private var ShowData:DistributedValue;
	
	// Used to start upload
	private var BankOpened:DistributedValue;

	// Archieve that contains archieves of cache and raid loot
	private var Lootboxes:DistributedValue;

	// Lootbox type that was last offered
	private var OpenType:String;

	// "Agent Dossier", due to german localization we have to use toLowerCase() on it and the item name
	// Agentendossier/Spezialagentendossier
	static var DossierName:String = LDBFormat.LDBGetText(50200, 9403857).toLowerCase();

	private var MonitoringInventoryItems:Boolean = false;
	private var PlayerInventory:Inventory;
	private var LastRun:Number;
	private var m_Uploader:Uploader;
	private var InvMonTimeout;

	public function Mod() {
	}
	
	public function Load(){
		CharacterBase.SignalClientCharacterOfferedLootBox.Connect(SlotOfferedLootBox, this);
		CharacterBase.SignalClientCharacterOpenedLootBox.Connect( SlotOpenedLootBox, this);
		Lootboxes = DistributedValue.Create("Lootboxes_DR");
		GroupFinderID = DistributedValue.Create("GroupFinderID_DR");
		Debug = DistributedValue.Create("DropResearch_Debug");
		ForceSync = DistributedValue.Create("DropResearch_ForceSync");
		ShowData = DistributedValue.Create("DropResearch_ShowData");
		BankOpened = DistributedValue.Create("bank_window")
		MissionCompletedSignal = DistributedValue.Create("MissionCompleted_DR");
		
		ShowData.SetValue(false);
		ForceSync.SetValue(false);
		Debug.SetValue(false);
		MissionCompletedSignal.SetValue(false);
		
		ShowData.SignalChanged.Connect(ShowPlayerData, this);
		ForceSync.SignalChanged.Connect(ForceUpdate, this);
		BankOpened.SignalChanged.Connect(SendDataToServer, this);
		MissionCompletedSignal.SignalChanged.Connect(MissionCompleted, this);
		GroupFinder.SignalClientStartedGroupFinderActivity.Connect(SlotJoinedGroupFinderBuffer, this);
		
		m_Uploader = new Uploader();
	}
	
	public function Unload(){
		ClearInventoryMonitoring(false);
		ForceSync.SignalChanged.Disconnect(ForceUpdate, this);
		MissionCompletedSignal.SignalChanged.Disconnect(MissionCompleted, this);
		ShowData.SignalChanged.Disconnect(ShowPlayerData, this);
		BankOpened.SignalChanged.Disconnect(SendDataToServer, this);
		
		CharacterBase.SignalClientCharacterOfferedLootBox.Disconnect(SlotOfferedLootBox, this);
		CharacterBase.SignalClientCharacterOpenedLootBox.Disconnect( SlotOpenedLootBox, this);
		GroupFinder.SignalClientStartedGroupFinderActivity.Disconnect(SlotJoinedGroupFinderBuffer, this);
	}
	
	private function CheckIfCorrectConfig(ComparisonID){
		if (ComparisonID != string(CharacterBase.GetClientCharID().GetInstance())){
			if (Debug.GetValue()){
				// this probably never gets called because debug defaults to false,and this issue only happens when configs have not yet beeen generated
				UtilsBase.PrintChatText("Mod tried to load configs for wrong character,generating new set of configs.");
			}
			var mod:GUIModuleIF = GUIModuleIF.FindModuleIF("DropResearch");
			var config:Archive = new Archive();
			DossierHandler.LoadConfig(config);
			Lootboxes.SetValue(config);
			ManualSave();
		}
	}
	
	public function Activate(conf:Archive) {
		var config:Archive = conf;
		// Work around for mod loading wrong characters configs.
		// Everything works fine once the config has been generated for each character once.
		setTimeout(Delegate.create(this,CheckIfCorrectConfig),1000, string(config.FindEntry("PlayerID")));

		DossierHandler.LoadConfig(config.FindEntry("DossierData", new Archive()));
		Lootboxes.SetValue(config.FindEntry("Lootboxes", new Archive()));
		LastRun = Number(config.FindEntry("LastRan", (new Date()).valueOf()));
		GroupFinderID.SetValue(Number(config.FindEntry("GroupFinderID", 0 )));
		Debug.SetValue(Boolean(config.FindEntry("Debug",false)));
		PlayerInventory = new Inventory(new ID32(_global.Enums.InvType.e_Type_GC_BackpackContainer, CharacterBase.GetClientCharID().GetInstance()));
		HookMissionRewardWindow();
		if (OnGoingSpecialEvent()) {
			ManualSave();
			Unload();
		}
	}
	
	//shows statistics for player
	private function ShowPlayerData(){
		if (ShowData.GetValue()){
			m_Uploader.ShowPlayerData();
			ShowData.SetValue(false)
		}
	}
	
	private function ManualSave(){
		var mod:GUIModuleIF = GUIModuleIF.FindModuleIF("DropResearch");
		var config:Archive = new Archive();
		config.AddEntry("DossierData", Archive(DossierHandler.GetConfig()));
		config.AddEntry("Lootboxes", Archive(Lootboxes.GetValue()));
		config.AddEntry("Debug", Boolean(Debug.GetValue()));
		config.AddEntry("GroupFinderID", Number(GroupFinderID.GetValue()));
		config.AddEntry("LastRan", LastRun);
		config.AddEntry("PlayerID", string(CharacterBase.GetClientCharID().GetInstance()));
		mod.StoreConfig(config)
	}

	public function Deactivate():Archive {
		var config:Archive = new Archive();
		config.AddEntry("DossierData", Archive(DossierHandler.GetConfig()));
		config.AddEntry("Lootboxes", Archive(Lootboxes.GetValue()));
		config.AddEntry("Debug", Boolean(Debug.GetValue()));
		config.AddEntry("GroupFinderID", Number(GroupFinderID.GetValue()));
		config.AddEntry("LastRan", LastRun);
		config.AddEntry("PlayerID", string(CharacterBase.GetClientCharID().GetInstance()));
		return config
	}

	private function OnGoingSpecialEvent() {
		return Character.GetClientCharacter().m_BuffList["9420855"];
	}

//Data Syncing
	// Bank opened, sync max once per hour
	private function SendDataToServer() {
		if(BankOpened.GetValue()){
			var current:Date = new Date();
			var ms = (current.valueOf() - LastRun);
			var hr = ms / (1000 * 60 * 60);
			if (hr > 1){
				LastRun = current.valueOf();
				StartUpload();
			}else{
				if (Debug.GetValue()) UtilsBase.PrintChatText(string(60 - Math.floor(hr * 60)) + "min until next sync");
			}
		}
	}
	
	// Forces sync
	private function ForceUpdate(){
		if (ForceSync.GetValue()){
			if (Debug.GetValue()) UtilsBase.PrintChatText("Forcing upload");
			StartUpload();
			ForceSync.SetValue(false);
		}
	}

	private function StartUpload() {
		m_Uploader.Upload();
	}

//GroupFinder stuff

	//takes a moment to update
	private function SlotJoinedGroupFinderBuffer(){
		setTimeout(Delegate.create(this, SlotJoinedGroupFinder), 500);
	}
	private function SlotJoinedGroupFinder() {
		GroupFinderID.SetValue(GroupFinder.GetActiveQueue());
		if (Debug.GetValue()) UtilsBase.PrintChatText("starting GF activity: " + GroupFinder.GetActiveQueue());
		// we really need that GroupFinderID for raids,manually saving in case of stuck loading screen
		ManualSave();
	}
	
	// Checks if player has queued for raid, is in raid instance,and that the chest can drop Dossier.
	private function GetGFInstance(items:Array) {
		var prefix:String;
		if (Character.GetClientCharacter().GetPlayfieldID() == 5710) {
			switch (GroupFinderID.GetValue()) {
				case _global.Enums.LFGQueues.e_NYRaidStory:
					prefix = "NYRStory";
					break
				case _global.Enums.LFGQueues.e_NYRaidElite1:
					prefix = "NYRE1";
					break
				case _global.Enums.LFGQueues.e_NYRaidElite5:
					prefix = "NYRE5";
					break
				case _global.Enums.LFGQueues.e_NYRaidElite10:
					prefix = "NYRE10";
					break
				default:
					return
			}
		}
		for (var i in items){
			var item:InventoryItem = items[i];
			// Search for Agent Dossier, if there isn't one then raid is on cooldown and we can ignore this lootbox
			// Alternatively we could use Character.GetClientCharacter().m_InvisibleBuffList[x] where X is 7961764 or 9125207 ( Story/Elite );
			if (item.m_Name.toLowerCase() == DossierName){
				return prefix
			}
		}
		return
	}

//Caches and lootboxes
	private function SlotOfferedLootBox(possibleItems:Array, tokenType:Number, boxType:Number, backgroundId:Number) {
		delete OpenType;
		// boxType 0 for raid
		// boxType 0 for scenario
		// 1 is agarthan?
		// boxType 2 is infernal
		// 3 is haunted?
		// boxType 5 is winter
		// boxType 6 is Tribal
		// this could be used to tell apart caches,but im already using first item ID which works just fine.
		//if (Debug.GetValue()) UtilsBase.PrintChatText("boxtype " + string(boxType));
		
		if (tokenType == _global.Enums.Token.e_Scenario_Key || tokenType == _global.Enums.Token.e_Dungeon_Key || tokenType == _global.Enums.Token.e_Lair_Key) {
			// Check if it can award dossier
			for (var i:Number = 0; i < possibleItems.length; i++) {
				var item:InventoryItem = possibleItems[i];
				if (item.m_Name.toLowerCase() == DossierName) {
					switch (tokenType) {
						case _global.Enums.Token.e_Scenario_Key:
							OpenType = "Scenario";
							break
						case _global.Enums.Token.e_Dungeon_Key:
							OpenType = "Dungeon";
							break
						case _global.Enums.Token.e_Lair_Key:
							OpenType = "Lair";
							break
					}
				}
			}
		}
		// Cache, we want to store the loot
		else if (tokenType == _global.Enums.Token.e_Lockbox_Key) {
			var item:InventoryItem = possibleItems[0];
			OpenType = string(item.m_ACGItem.m_TemplateID0);
		}
		// Raid should be checked last, as it is possible to open caches in the raid instance
		// We want to store the loot, and check if we get a dossier.
		if (!OpenType) {
			var raidType = GetGFInstance(possibleItems);
			if (raidType) OpenType = raidType;
		}
		if (Debug.GetValue()) UtilsBase.PrintChatText("Offered " + string(OpenType));
	}

	private function SlotOpenedLootBox(obtainedItems:Array, lootResult:Number, moreAvailable:Boolean) {
		if (OpenType && obtainedItems.length>0) {
			if (Debug.GetValue()) UtilsBase.PrintChatText("Opening: " + OpenType);
			switch (OpenType) {
				case "Scenario":
					DossierHandler.ValueChanged("ScenariosDone",1)
					break
				case "Dungeon":
					DossierHandler.ValueChanged("DungeonsDone",1)
					break
				case "Lair":
					DossierHandler.ValueChanged("LairsDone",1)
					break
				case "NYRStory":
					DossierHandler.ValueChanged("NYRStoryDone",1)
					break
				case "NYRE1":
					DossierHandler.ValueChanged("NYRE1Done",1)
					break
				case "NYRE5":
					DossierHandler.ValueChanged("NYRE5Done",1)
					break
				case "NYRE10":
					DossierHandler.ValueChanged("NYRE10Done",1)
					break
			}
			// Checks if player got a dossier + stores loot in archieve if needed
			var LootboxLoot = new Object();
			for (var i:Number = 0; i < obtainedItems.length; i++) {
				var item:InventoryItem = obtainedItems[i];
				if (Debug.GetValue()) UtilsBase.PrintChatText(item.m_Name + " received from lootbox");
				// Check if the received item name contains "agent gossier"(localized) text.
				if (item.m_Name.toLowerCase().indexOf(DossierName) != -1 && item.m_Name) {
					switch (OpenType) {
						case "Scenario":
							DossierHandler.ValueChanged("ScenarioDossiers",1)
							break
						case "Dungeon":
							DossierHandler.ValueChanged("DungeonDossiers",1)
							break
						case "Lair":
							DossierHandler.ValueChanged("LairDossiers",1)
							break
						case "NYRStory":
							DossierHandler.ValueChanged("NYRStoryDossiers",1)
							break
						case "NYRE1":
							DossierHandler.ValueChanged("NYRE1Dossiers",1)
							break
						case "NYRE5":
							DossierHandler.ValueChanged("NYRE5Dossiers",1)
							break
						case "NYRE10":
							DossierHandler.ValueChanged("NYRE10Dossiers",1)
							break
					}
				}
				// Store loot data in object for now
				// format is ItemID:SignetID or ItemID or ItemName
				if (OpenType != "Scenario" && OpenType != "Dungeon" && OpenType != "Lair") {
					if (item.m_ACGItem.m_TemplateID0){
						if (item.m_ACGItem.m_TemplateID2){
							var amount = LootboxLoot[string(item.m_ACGItem.m_TemplateID0) + ":" + string(item.m_ACGItem.m_TemplateID2)] | 0;
							LootboxLoot[string(item.m_ACGItem.m_TemplateID0) + ":" + string(item.m_ACGItem.m_TemplateID2)] = amount + 1;
						}else{
							var amount = LootboxLoot[string(item.m_ACGItem.m_TemplateID0)] | 0;
							LootboxLoot[string(item.m_ACGItem.m_TemplateID0)] = amount + 1;
						}
					}else{
						var amount = LootboxLoot[item.m_Name] | 0;
						LootboxLoot[item.m_Name] = amount + 1;
					}
				}
			}
			// Archieve lootbox results
			for (var undef in LootboxLoot){
				if (Debug.GetValue()) UtilsBase.PrintChatText("Saving lootbox data to archieve")
				var LootboxArchieve:Archive = Lootboxes.GetValue();
				var LootboxData:Archive = Archive(LootboxArchieve.FindEntry(OpenType, new Archive()));
				var openedAmount = Number(LootboxData.FindEntry("Opened", 0));
				LootboxData.ReplaceEntry("Opened", openedAmount + 1);
				for (var i in LootboxLoot) {
					var amount = Number(LootboxData.FindEntry(i, 0));
					// ReplaceEntry creates a new key/value if it doesn't exist.
					LootboxData.ReplaceEntry(i, amount + LootboxLoot[i]);
				}
				LootboxArchieve.ReplaceEntry(OpenType, LootboxData);
				Lootboxes.SetValue(LootboxArchieve);
				break
			}
			// Crash when leaving NYR,so saving data right away
			ManualSave();
		}
	}

//Mission stuff
	private function HookMissionRewardWindow() {
		var RewardWindow = _global.GUI.Mission.MissionRewardWindow;
		if (!RewardWindow.prototype.CollectRewardsHandler) {
			setTimeout(Delegate.create(this, HookMissionRewardWindow), 50);
			return
		}
		if (!RewardWindow.prototype._CollectRewardsHandler){
			RewardWindow.prototype._CollectRewardsHandler = RewardWindow.prototype["CollectRewardsHandler"];
			RewardWindow.prototype.CollectRewardsHandler = function () {
				var found = false;
				for (var i in this.m_RewardArray) {
					var item:InventoryItem = this.m_RewardArray[i];
					//Agent Dossier
					if (item.m_Name == LDBFormat.LDBGetText(50200, 9403857)) {
						DistributedValueBase.SetDValue("MissionCompleted_DR", this.m_QuestID);
						found = true;
					}
				}
				//no dossier chance, set value to 1 so we know to disconnect signals
				if (!found){
					DistributedValueBase.SetDValue("MissionCompleted_DR", 1);
				}
				//Small delay to finish hooking up the signals and then calling the original function
				setTimeout(Delegate.create(this, function() {
					this._CollectRewardsHandler();
				}), 50)
			}
		}
	}
	
	private function MissionCompleted() {
		if (MissionCompletedSignal.GetValue()){
			//clear previously running monitoring
			ClearInventoryMonitoring();
			clearTimeout(InvMonTimeout);
			var value = MissionCompletedSignal.GetValue()
			//value = 1 -> no dossier chance
			if (value == 1){
				MissionCompletedSignal.SetValue(false);
			}
			// value = QuestID -> dossier mission, track items for 1s, or until next mission is claimed. 
			else{
				var questrewards = QuestsBase.GetAllRewards();
				// Checking that the missionID exists on pending rewards before doing anything
				for (var i in questrewards){
					var qID = questrewards[i].m_QuestTaskID;
					if(qID == value){
						QuestsBase.SignalQuestRewardInventorySpace.Connect(InventoryFull, this);
						PlayerInventory.SignalItemAdded.Connect(CheckIfMissionDossierBuffer, this);
						InvMonTimeout = setTimeout(Delegate.create(this, ClearInventoryMonitoring), 1000);
						DossierHandler.ValueChanged("MissionsDone", 1);
						if (Debug.GetValue()) UtilsBase.PrintChatText("Inventory monitoring started");
						MissionCompletedSignal.SetValue(false);
						break
					}
				}
			}
		}
	}
	
	// This only triggers for new stacks, which is fine
	// It has a small buffer so that the dossier has chance to fully load.
	// Dossiers are also the first items i have seen to trigger SignalItemLoaded, which seems to take a moment
	private function CheckIfMissionDossierBuffer(inventoryID:com.Utils.ID32, itemPos:Number){
		setTimeout(Delegate.create(this, CheckIfMissionDossier), 100,itemPos);
	}
	
	// Checks if the added item is dossier
	private function CheckIfMissionDossier(pos:Number) {
		var item:InventoryItem = PlayerInventory.GetItemAt(pos);
		if (Debug.GetValue()) UtilsBase.PrintChatText(item.m_Name+" added to inventory");
		if (item.m_Name.toLowerCase().indexOf(DossierName) != -1 && item.m_Name) {
			if (Debug.GetValue()) UtilsBase.PrintChatText("dossier found");
			DossierHandler.ValueChanged("MissionDossiers", 1);
			ManualSave();
		}
	}
	
	// In case of full inventory
	private function InventoryFull() {
		DossierHandler.ValueChanged("MissionsDone", -1);
		if (Debug.GetValue()) UtilsBase.PrintChatText("Inventory was Full");
	}
	
	//Stops inventory monitoring
	private function ClearInventoryMonitoring() {
		QuestsBase.SignalQuestRewardInventorySpace.Disconnect(InventoryFull, this);
		PlayerInventory.SignalItemAdded.Disconnect(CheckIfMissionDossierBuffer, this);
	}
}