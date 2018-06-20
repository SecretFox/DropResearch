import com.GameInterface.Game.Character;
import com.GameInterface.Game.CharacterBase;
import com.GameInterface.GroupFinder;
import com.GameInterface.InventoryItem;
import com.Utils.Archive;
import com.fox.DropResearch.BaseClass;
import mx.utils.Delegate;
/**
 * ...
 * @author fox
 */
class com.fox.DropResearch.Cache extends BaseClass {

	private var OpenType;
	public var SpecialEvent = false;

	public function Cache() {
		CharacterBase.SignalClientCharacterOfferedLootBox.Connect(SlotOfferedLootBox, this);
		CharacterBase.SignalClientCharacterOpenedLootBox.Connect( SlotOpenedLootBox, this);
		GroupFinder.SignalClientStartedGroupFinderActivity.Connect(SlotJoinedGroupFinderBuffer, this);
	}
	public function Disconnect() {
		CharacterBase.SignalClientCharacterOfferedLootBox.Disconnect(SlotOfferedLootBox, this);
		CharacterBase.SignalClientCharacterOpenedLootBox.Disconnect( SlotOpenedLootBox, this);
		GroupFinder.SignalClientStartedGroupFinderActivity.Disconnect(SlotJoinedGroupFinderBuffer, this);
	}
	//takes a moment to update, hopefully triggers before player gets sent in to the instnace
	private function SlotJoinedGroupFinderBuffer() {
		setTimeout(Delegate.create(this, SlotJoinedGroupFinder), 500);
	}

	private function SlotJoinedGroupFinder() {
		GroupFinderID.SetValue(GroupFinder.GetActiveQueue());
		PrintDebug("starting GF activity: " + GroupFinder.GetActiveQueue(), true);
		// we really need that GroupFinderID, and NYR tends to freeze
		ManualSave();
	}

	// Checks if player has queued for raid, is in raid instance,and that the chest can drop Dossier.
	// TODO; Expand this to dungeons so we can tell them apart(in case of Dossier nerf on lower elites)
	private function GetGFInstance(items:Array) {
		var prefix:String;
		if (Character.GetClientCharacter().GetPlayfieldID() == 5710 || Character.GetClientCharacter().GetPlayfieldID() == 5715) {
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
		for (var i in items) {
			var item:InventoryItem = items[i];
			// Search for Agent Dossier, if there isn't one then raid is on cooldown and we can ignore this lootbox
			// Alternatively we could use Character.GetClientCharacter().m_InvisibleBuffList[x] where X is 7961764 or 9125207 ( Story/Elite );
			if (item.m_Name.toLowerCase() == DossierName) {
				return prefix
			}
		}
		return
	}
	
	private function HasMegaboss(possibleItems:Array){
		for (var i in possibleItems){
			var item:InventoryItem = possibleItems[i];
			if (item.m_ACGItem.m_TemplateID0 == 9124215) return true;
			else if (item.m_ACGItem.m_TemplateID0 == 9124216) return true;
			else if (item.m_ACGItem.m_TemplateID0 == 9343405) return true;
			else if (item.m_ACGItem.m_TemplateID0 == 9121078) return true;
		}
		return false
	}
	
	private function GetEvents(possibleItems:Array){
		var Dungeon = Player.m_BuffList["9419386"];
		var Regional = Player.m_BuffList["9419387"];
		var Scenario = Player.m_BuffList["9395902"];
		if (Dungeon || Regional || Scenario) {
			PrintDebug("Ongoing free key event, attempting to identify lootbox", true);
			// Check if it can award dossier
			for (var i:Number = 0; i < possibleItems.length; i++) {
				var item:InventoryItem = possibleItems[i];
				if (item.m_Name.toLowerCase() == DossierName) {
					var Playfield = Character.GetClientCharacter().GetPlayfieldID();
					var Megaboss = HasMegaboss(possibleItems);
					if ((Playfield ==  7612 || Playfield ==  7622 || Playfield ==  7602 ) && Scenario ){
						return "Scenario"
					}
					else if (Megaboss && Regional ){
						return "Lair"
					}
					// polaris, HR, DW, ankh*2, HE
					else if ((
						Playfield == 5040 || Playfield == 5140 || Playfield == 5170 || Playfield == 5080 || Playfield == 5160 || Playfield == 6230) 
						&& Dungeon) {
						return "Dungeon"
					}
				}
			}
		}
		return undefined
	}

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
		//PrintDebug("Offered " + string(OpenType), true);
		
		if (boxType == 7){
			OpenType = "Anniversary";
			PrintDebug("Offered " + string(OpenType), true);
			return
		}
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
		// During free key events key type is undefined
		if (!OpenType) {
			var EvenType = GetEvents(possibleItems);
			if (EvenType) OpenType = EvenType;
		}
		PrintDebug("Offered " + string(OpenType), true);
	}
	
	// Finds the weapon after 500ms and replaces archieve entry that does not have signet with signeted one.
	private function GetSuffix(item:InventoryItem, Opened){
		if(item && Opened){
			var LootboxArchieve:Archive = Lootboxes.GetValue();
			var LootboxData:Archive = Archive(LootboxArchieve.FindEntry(Opened));
			if(LootboxData){
				var amount = Number(LootboxData.FindEntry(string(item.m_ACGItem.m_TemplateID0), 0));
				if (amount){
					var newItem:InventoryItem = PlayerInventory.GetItemAt(item.m_InventoryPos);
					if (newItem.m_ACGItem.m_TemplateID0 == item.m_ACGItem.m_TemplateID0 && newItem.m_ACGItem.m_TemplateID2){
						PrintDebug("Fixing weapon suffix", true);
						LootboxData.DeleteEntry(string(item.m_ACGItem.m_TemplateID0));
						var id = string(newItem.m_ACGItem.m_TemplateID0) + ":" +  string(newItem.m_ACGItem.m_TemplateID2);
						var OpenAmount = LootboxData.FindEntry(id, 0);
						LootboxData.ReplaceEntry(id, OpenAmount+1);
					}
					LootboxArchieve.ReplaceEntry(Opened, LootboxData);
					Lootboxes.SetValue(LootboxArchieve);
				}
			}
		}
	}

	// This function finds the weapon position in inventory and if it does not contain suffix it will scheduel another check after 500ms
	// current theory; Item is added to inventory without suffix, which gets added after a moment
	private function FindInventoryItem(item:InventoryItem) {
		for (var i:Number = 0; i <= PlayerInventory.GetMaxItems(); i++) {
			var CompareItem:InventoryItem = PlayerInventory.GetItemAt(i);
			PrintDebug("check item : " + CompareItem.m_Name,true );
			if (CompareItem.m_Name.indexOf(item.m_Name) != -1 && CompareItem.m_Name && item.m_Name && !CompareItem.m_IsBoundToPlayer) {
				PrintDebug("Found item : " + CompareItem.m_Name,true);
				if (!CompareItem.m_ACGItem.m_TemplateID2){
					PrintDebug("Attempting to fix suffix",true);
					setTimeout(Delegate.create(this, GetSuffix), 500, CompareItem, OpenType);
				}
				return CompareItem;
			}
		}
		PrintDebug("Match not found " + item.m_Name,true);
		return item;
	}

	// Lootbox weapons don't have realtype either?(unconfirmed)
	private function isWeapon(item:InventoryItem){
		switch (Number(item.m_RealType)) {
			case 30104:
			case 30106:
			case 30107:
			case 30118:
			case 30112:
			case 30110:
			case 30111:
			case 30100:
			case 30101:
				return true
			default:
				return false
		}
	}
	
	private function SlotOpenedLootBox(obtainedItems:Array, lootResult:Number, moreAvailable:Boolean) {
		if (OpenType && obtainedItems.length>0) {
			PrintDebug("Opening: " + OpenType, true);
			if (!SpecialEvent) {
				switch (OpenType) {
					case "Scenario":
						DossierValueChanged("ScenariosDone",1)
						break
					case "Dungeon":
						DossierValueChanged("DungeonsDone",1)
						break
					case "Lair":
						DossierValueChanged("LairsDone",1)
						break
					case "NYRStory":
						DossierValueChanged("NYRStoryDone",1)
						break
					case "NYRE1":
						DossierValueChanged("NYRE1Done",1)
						break
					case "NYRE5":
						DossierValueChanged("NYRE5Done",1)
						break
					case "NYRE10":
						DossierValueChanged("NYRE10Done",1)
						break
				}
			}
			// Checks if player got a dossier + stores loot in archieve if needed
			var LootboxLoot = new Object();
			for (var i:Number = 0; i < obtainedItems.length; i++) {
				var item:InventoryItem = obtainedItems[i];
				PrintDebug(item.m_Name + " received from lootbox", true);
				// Check if the received item name contains "agent gossier"(localized) text.
				if (!SpecialEvent) {
					if (item.m_Name.toLowerCase().indexOf(DossierName) != -1 && item.m_Name) {
						switch (OpenType) {
							case "Scenario":
								DossierValueChanged("ScenarioDossiers",1)
								break
							case "Dungeon":
								DossierValueChanged("DungeonDossiers",1)
								break
							case "Lair":
								DossierValueChanged("LairDossiers",1)
								break
							case "NYRStory":
								DossierValueChanged("NYRStoryDossiers",1)
								break
							case "NYRE1":
								DossierValueChanged("NYRE1Dossiers",1)
								break
							case "NYRE5":
								DossierValueChanged("NYRE5Dossiers",1)
								break
							case "NYRE10":
								DossierValueChanged("NYRE10Dossiers",1)
								break
						}
					}
				}
				// Store loot data in object for now
				// format is ItemID:SignetID or ItemID or ItemName
				if (OpenType != "Scenario" && OpenType != "Dungeon" && OpenType != "Lair") {
					var weapon = isWeapon(item);
					PrintDebug("Is weapon : " + item.m_Name + " " +weapon,true);
					// Obtained items doesn't contain the weapon "signet", attempt to find it in inventory
					// If it fails to retrieve suffix it will check the item position again after 500ms.
					if (weapon)	item = FindInventoryItem(item);
					if (item.m_ACGItem.m_TemplateID0) {
						var ID = string(item.m_ACGItem.m_TemplateID0);
						if (item.m_ACGItem.m_TemplateID2) ID += ":" + item.m_ACGItem.m_TemplateID2;
						var amount = LootboxLoot[ID] | 0;
						LootboxLoot[ID] = amount + 1;
					} else {
						var amount = LootboxLoot[item.m_Name] | 0;
						LootboxLoot[item.m_Name] = amount + 1;
					}
				}
			}
			// Archieve lootbox results
			// idk how to properly check if object is empty
			for (var undef in LootboxLoot) {
				PrintDebug("Saving lootbox data to archieve", true);
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
}