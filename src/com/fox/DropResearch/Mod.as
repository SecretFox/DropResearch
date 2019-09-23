/**
 * ...
 * @author fox
 */
import com.GameInterface.DistributedValue;
import com.GameInterface.Game.Character;
import com.GameInterface.ShopInterface;
import com.Utils.Archive;
import com.fox.DropResearch.Cache;
import com.fox.DropResearch.Consumable;
import com.fox.DropResearch.Mission;
import com.fox.DropResearch.BaseClass;
import com.fox.DropResearch.Uploader;

class com.fox.DropResearch.Mod extends BaseClass {
	private var ForceSync:DistributedValue;
	private var ShowData:DistributedValue;
	private var ShowPlayerID:DistributedValue;
	private var ShowVersion:DistributedValue;

	// Used to start upload
	private var BankOpened:DistributedValue;
	private var TradePostOpened:DistributedValue;
	private var ShopOpened:DistributedValue;

	private var m_Uploader:Uploader;
	private var m_Consumable:Consumable;
	private var m_CacheHandler:Cache;
	private var m_MissionHandler:Mission;

	public function Mod() {
		BankOpened = DistributedValue.Create("bank_window");
		TradePostOpened = DistributedValue.Create("tradepost_window");
		ShowData = DistributedValue.Create("DropResearch_ShowData");
		Debug = DistributedValue.Create("DropResearch_Debug");
		ForceSync = DistributedValue.Create("DropResearch_ForceSync");
		ShowPlayerID = DistributedValue.Create("DropResearch_PlayerID");
		ShowVersion = DistributedValue.Create("DropResearch_Version");
	}

	public function Load() {
		ShowData.SetValue(false);
		Debug.SetValue(false);
		ForceSync.SetValue(false);
		ShowPlayerID.SetValue(false);
		ShowVersion.SetValue(false);

		ShowPlayerID.SignalChanged.Connect(SlotShowPlayerID, this);
		ShowVersion.SignalChanged.Connect(SlotShowVersion, this);
		ShowData.SignalChanged.Connect(ShowPlayerData, this);
		ForceSync.SignalChanged.Connect(ForceUpdate, this);
		BankOpened.SignalChanged.Connect(SendDataToServer, this);
		TradePostOpened.SignalChanged.Connect(SendDataToServer, this);
		ShopInterface.SignalOpenShop.Connect(SendDataToServer, this);

		m_Uploader = new Uploader();
		m_Consumable = new Consumable();
		m_CacheHandler = new Cache();
		m_MissionHandler = new Mission();
	}

	public function Unload() {
		ShowPlayerID.SignalChanged.Disconnect(SlotShowPlayerID, this);
		ShowVersion.SignalChanged.Disconnect(SlotShowVersion, this);
		ShowData.SignalChanged.Disconnect(ShowPlayerData, this);
		ForceSync.SignalChanged.Disconnect(ForceUpdate, this);
		BankOpened.SignalChanged.Disconnect(SendDataToServer, this);
		TradePostOpened.SignalChanged.Disconnect(SendDataToServer, this);
		ShopInterface.SignalOpenShop.Disconnect(SendDataToServer, this);

		m_Consumable.Disconnect();
		m_CacheHandler.Disconnect();
		m_MissionHandler.Disconnect();
		m_Consumable = undefined;
		m_CacheHandler = undefined;
		m_MissionHandler = undefined;
		m_Uploader = undefined;
	}

	public function Activate(config:Archive) {
		Dossier.SetValue(config.FindEntry("DossierData", new Archive()));
		Lootboxes.SetValue(config.FindEntry("Lootboxes", new Archive()));
		Consumables.SetValue(config.FindEntry("Consumables", new Archive()));
		LastRun.SetValue(Number(config.FindEntry("LastRan", (new Date()).valueOf())))
		GroupFinderID.SetValue(Number(config.FindEntry("GroupFinderID", 0 )));
		Debug.SetValue(Boolean(config.FindEntry("Debug", false)));

		// Workaround for mod loading last used characters config when running the mod on new character for the first time
		// Everything works fine once the config has been generated for each character once.
		if (string(config.FindEntry("PlayerID")) != string(PlayerID)) {
			PrintDebug("Mod tried to load configs for wrong character,generating fresh configs.", true);
			Dossier.SetValue(new Archive());
			Lootboxes.SetValue(new Archive());
			Consumables.SetValue(new Archive());
			ManualSave();
		}
		if (OnGoingSpecialEvent()) {
			m_MissionHandler.SpecialEvent = true;
			m_CacheHandler.SpecialEvent = true;
		} else {
			m_MissionHandler.SpecialEvent = false;
			m_CacheHandler.SpecialEvent = false;
		}
	}

	public function Deactivate():Archive {
		var config:Archive = new Archive();
		config.AddEntry("DossierData",  Archive(Dossier.GetValue()));
		config.AddEntry("Lootboxes", Archive(Lootboxes.GetValue()));
		config.AddEntry("Consumables", Archive(Consumables.GetValue()))
		config.AddEntry("Debug", Boolean(Debug.GetValue()));
		config.AddEntry("GroupFinderID", Number(GroupFinderID.GetValue()));
		config.AddEntry("LastRan", LastRun.GetValue());
		config.AddEntry("PlayerID", string(PlayerID));
		return config
	}

	private function OnGoingSpecialEvent() {
		return Character.GetClientCharacter().m_BuffList["9420855"];
	}

	private function SlotShowPlayerID(dv) {
		if (dv.GetValue()) {
			PrintDebug("PlayerID is " + PlayerID);
			dv.SetValue(false);
		}
	}

	private function SlotShowVersion(dv) {
		if (dv.GetValue()) {
			PrintDebug("DropResearch v-" + ModVersion);
			dv.SetValue(false);
		}
	}

	private function ShowPlayerData(dv) {
		if (dv.GetValue()) {
			m_Uploader.ShowPlayerData();
			dv.SetValue(false)
		}
	}
//Data Syncing
	// Bank opened, sync max once per hour
	private function SendDataToServer(dv) {
		// Opened,or doesn't contain GetValue(shop)
		if (dv.GetValue() || !dv["GetValue"]) {
			var current:Date = new Date();
			var ms = (current.valueOf() - LastRun.GetValue());
			var hr = ms / (1000 * 60 * 60);
			if (hr > 1) {
				LastRun.SetValue(current.valueOf())
				StartUpload();
			} else {
				PrintDebug(string(60 - Math.floor(hr * 60)) + "min until next sync", true);
			}
		}
	}

	// Forces sync
	private function ForceUpdate(dv) {
		if (dv.GetValue()) {
			var current:Date = new Date();
			LastRun.SetValue(current.valueOf())
			PrintDebug("Forcing synchronization");
			StartUpload();
			dv.SetValue(false);
		}
	}

	private function StartUpload() {
		m_Uploader.Upload();
	}
}