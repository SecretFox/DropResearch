import com.GameInterface.DistributedValue;;
import com.GameInterface.InventoryItem;
import com.GameInterface.QuestsBase;
import com.Utils.LDBFormat;
import com.fox.DropResearch.BaseClass;
import mx.utils.Delegate;
/**
 * ...
 * @author fox
 */
class com.fox.DropResearch.Mission extends BaseClass {
	
	private var MissionCompletedSignal:DistributedValue;
	private var MissionLock:DistributedValue;
	private var clearlocktimeout;
	public var SpecialEvent = false;

	public function Mission() {
		HookMissionRewardWindow();
		MissionLock = DistributedValue.Create("MissionLock_DR");
		MissionLock.SetValue(false);
		
		MissionCompletedSignal = DistributedValue.Create("MissionCompleted_DR");
		MissionCompletedSignal.SetValue(false);
		MissionCompletedSignal.SignalChanged.Connect(MissionCompleted, this);
	}
	//probably not needed
	public function Disconnect(){
		MissionCompletedSignal.SignalChanged.Disconnect(MissionCompleted, this);
	}
	
	private function HookMissionRewardWindow() {
		var RewardWindow = _global.GUI.Mission.MissionRewardWindow;
		if (!RewardWindow.prototype.CollectRewardsHandler) {
			setTimeout(Delegate.create(this, HookMissionRewardWindow), 50);
			return
		}
		if (!RewardWindow.prototype._CollectRewardsHandler) {
			RewardWindow.prototype._CollectRewardsHandler = RewardWindow.prototype["CollectRewardsHandler"];
			RewardWindow.prototype.CollectRewardsHandler = function (event,Changed) {
				// Changed is undefined on the first run and true if MissionCompleted has already been set for this mission
				if (!Changed) {
					// MissionLock is set to True when signals get hooked
					// This prevents from collecting rewards until previous mission rewards has finished running.
					if (com.GameInterface.DistributedValueBase.GetDValue("MissionLock_DR")) {
						setTimeout(Delegate.create(this, this.CollectRewardsHandler), 5, event);
						return
					}
					var found = false;
					for (var i in this.m_RewardArray) {
						var item:InventoryItem = this.m_RewardArray[i];
						//Agent Dossier
						if (item.m_Name == LDBFormat.LDBGetText(50200, 9403857)) {
							com.GameInterface.DistributedValueBase.SetDValue("MissionCompleted_DR", this.m_QuestID);
							found = true;
							break
						}
					}
					//no dossier chance, set value to 1 so we know to disconnect signals
					if (!found) {
						com.GameInterface.DistributedValueBase.SetDValue("MissionCompleted_DR", 1);
					}
				}
				// Checks that everything has finished hooking before collecting rewards
				// (Value set to false after hooking)
				if (com.GameInterface.DistributedValueBase.GetDValue("MissionCompleted_DR")) {
					setTimeout(Delegate.create(this, this.CollectRewardsHandler), 5, event, true);
					return
				}
				this._CollectRewardsHandler();
			}
		}
	}

	private function MissionCompleted() {
		if (MissionCompletedSignal.GetValue()) {
			if (SpecialEvent){
				MissionCompletedSignal.SetValue(false);
				return
			}
			var value = MissionCompletedSignal.GetValue();
			//value = 1 -> no dossier chance
			if (value == 1) {
				ClearMissionlock();//this shouldn't be necessary
				MissionCompletedSignal.SetValue(false);
			}
			// value = QuestID -> dossier mission, track inventory items, stop tracking 100ms after last item was added,or if inventory was full
			else {
				var questrewards = QuestsBase.GetAllRewards();
				// Checking that the missionID exists on pending rewards before doing anything
				for (var i in questrewards) {
					var qID = questrewards[i].m_QuestTaskID;
					if (qID == value) {
						// While locked no other mission reports can be claimed, set to true once collection finishes
						MissionLock.SetValue(true);
						QuestsBase.SignalQuestRewardInventorySpace.Connect(InventoryFull, this);
						PlayerInventory.SignalItemAdded.Connect(CheckIfMissionDossierBuffer, this);
						PlayerInventory.SignalItemStatChanged.Connect(ItemStatChanged, this);
						DossierValueChanged("MissionsDone", 1)
						//settings this to false will let the report window to know we are ready to collect rewards
						MissionCompletedSignal.SetValue(false);
						// in case both item added and stat changed fail to trigger
						clearTimeout(clearlocktimeout);
						clearlocktimeout = setTimeout(Delegate.create(this, ClearMissionlock), 1000);
						break
					}
				}
			}
		}
	}

	// This only triggers for new stacks, which is fine
	// Dossiers are also the first items i have seen to trigger SignalItemLoaded, which seems to take a moment(requiring the buffer)
	private function CheckIfMissionDossierBuffer(inventoryID:com.Utils.ID32, itemPos:Number) {
		setTimeout(Delegate.create(this, CheckIfMissionDossier), 100, itemPos);
		clearTimeout(clearlocktimeout);
		clearlocktimeout = setTimeout(Delegate.create(this, ClearMissionlock), 100);
	}

	// Only used to see if rewards were claimed
	private function ItemStatChanged(id,pos) {
		PrintDebug(PlayerInventory.GetItemAt(pos).m_Name+"('s) received from mission", true);
		clearTimeout(clearlocktimeout);
		clearlocktimeout = setTimeout(Delegate.create(this, ClearMissionlock), 100);
	}

	// Missionlock is cleared 100ms after last item was added/changed, inventory was full,or 1s as fallback method(shouldn't happen).
	// While at it we disconnect the signals
	private function ClearMissionlock() {
		QuestsBase.SignalQuestRewardInventorySpace.Disconnect(InventoryFull, this);
		PlayerInventory.SignalItemAdded.Disconnect(CheckIfMissionDossierBuffer, this);
		PlayerInventory.SignalItemStatChanged.Disconnect(ItemStatChanged, this);
		MissionLock.SetValue(false);
	}

	// Checks if the added item is dossier
	private function CheckIfMissionDossier(pos:Number) {
		var item:InventoryItem = PlayerInventory.GetItemAt(pos);
		PrintDebug(item.m_Name+" received from mission", true);
		if (item.m_Name.toLowerCase().indexOf(DossierName) != -1 && item.m_Name) {
			PrintDebug("dossier found", true);
			DossierValueChanged("MissionDossiers", 1);
			ManualSave();
		}
	}

	// In case of full inventory
	private function InventoryFull() {
		ClearMissionlock();
		DossierValueChanged("MissionsDone", -1);
		PrintDebug("Inventory was Full", true);
	}

}