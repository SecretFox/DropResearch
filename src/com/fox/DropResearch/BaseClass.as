import com.GameInterface.DistributedValue;
import com.GameInterface.Game.Character;
import com.GameInterface.Inventory;
import com.Utils.Archive;
import com.GameInterface.GUIModuleIF;
import com.Utils.ID32;
import com.Utils.LDBFormat;
/**
 * ...
 * @author fox
 */
class com.fox.DropResearch.BaseClass {
	// Archieve that contain dossier data
	private var Dossier:DistributedValue;
	// Archieve that contains archieves of cache and raid loot
	private var Lootboxes:DistributedValue;
	// Archieve that contains archieves of consumable loot
	private var Consumables:DistributedValue;
	private var Debug:DistributedValue;
	private var GroupFinderID:DistributedValue;
	private var LastRun:DistributedValue;
	private var PlayerInventory:Inventory
	private var Player:Character
	private var PlayerID:Number;

	// "Agent Dossier", due to german localization we have to use toLowerCase() on it and the item name,or special dossiers wont be detected
	// Agentendossier/Spezialagentendossier
	static var DossierName:String = LDBFormat.LDBGetText(50200, 9403857).toLowerCase();
	static var ModVersion = "0.4.0"

	public function BaseClass() {
		Lootboxes = DistributedValue.Create("Lootboxes_DR");
		Consumables = DistributedValue.Create("Consumable_DR");
		Dossier = DistributedValue.Create("Dossier_DR");
		Debug = DistributedValue.Create("DropResearch_Debug");
		GroupFinderID = DistributedValue.Create("GroupFinderID_DR");
		LastRun = DistributedValue.Create("LastRun_DR");
		Player = Character.GetClientCharacter();
		PlayerID = Player.GetID().GetInstance();
		PlayerInventory = new Inventory(new ID32(_global.Enums.InvType.e_Type_GC_BackpackContainer, PlayerID));
	}

	private function DossierValueChanged(key, value) {
		var config:Archive = Dossier.GetValue();
		var oldVal = Number(config.FindEntry(key, 0));
		var newval = oldVal + value;
		PrintDebug(key +" " + oldVal +	"->" + newval, true);
		config.ReplaceEntry(key, newval);
		Dossier.SetValue(config);
	}

	private function PrintDebug(msg, debugOnly) {
		if (debugOnly) {
			if (Debug.GetValue()) com.GameInterface.UtilsBase.PrintChatText(string(msg));
		} else {
			com.GameInterface.UtilsBase.PrintChatText(string(msg));
		}
	}

	private function ManualSave() {
		var mod:GUIModuleIF = GUIModuleIF.FindModuleIF("DropResearch");
		var config:Archive = new Archive();
		config.AddEntry("DossierData", Archive(Dossier.GetValue()));
		config.AddEntry("Lootboxes", Archive(Lootboxes.GetValue()));
		config.AddEntry("Consumables", Archive(Consumables.GetValue()))
		config.AddEntry("Debug", Boolean(Debug.GetValue()));
		config.AddEntry("GroupFinderID", Number(GroupFinderID.GetValue()));
		config.AddEntry("LastRan", LastRun.GetValue());
		config.AddEntry("PlayerID", string(PlayerID));
		mod.StoreConfig(config)
	}
}