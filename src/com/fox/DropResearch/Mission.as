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
	private var clearlocktimeout;
	public var SpecialEvent = false;

	public function Mission() {
		HookMissionRewardWindow();
		MissionCompletedSignal = DistributedValue.Create("MissionCompleted_DR");
		MissionCompletedSignal.SetValue(false);
		MissionCompletedSignal.SignalChanged.Connect(MissionCompleted, this);
	}

	//probably not needed
	public function Disconnect() {
		MissionCompletedSignal.SignalChanged.Disconnect(MissionCompleted, this);
		ClearMissionlock();
	}

	private function HookMissionRewardWindow() {
		var RewardWindow = _global.GUI.Mission.MissionRewardWindow;
		if (!RewardWindow.prototype.CollectRewardsHandler) {
			setTimeout(Delegate.create(this, HookMissionRewardWindow), 50);
			return
		}
		if (!RewardWindow.prototype._CollectRewardsHandler) {
			RewardWindow.prototype._CollectRewardsHandler = RewardWindow.prototype["CollectRewardsHandler"];
			RewardWindow.prototype.CollectRewardsHandler = function (event) {
				// This prevents from collecting rewards until previous mission rewards has finished running.
				if (com.GameInterface.DistributedValueBase.GetDValue("MissionCompleted_DR")) {
					setTimeout(Delegate.create(this, this.CollectRewardsHandler), 50, event);
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
				setTimeout(Delegate.create(this, this._CollectRewardsHandler), 25);
			}
		}
	}

	private function MissionCompleted() {
		var value = MissionCompletedSignal.GetValue();
		if (value) {
			if (SpecialEvent) {
				ClearMissionlock();
				return
			}
			//value = 1 -> no dossier chance
			if (value == 1) {
				ClearMissionlock();
			}
			// value = QuestID -> dossier mission, track inventory items, stop tracking 100ms after last item was added,or if inventory was full
			else {
				// Should set it back to False even if quest is not found on pending rewards
				clearTimeout(clearlocktimeout);
				clearlocktimeout = setTimeout(Delegate.create(this, ClearMissionlock), 1000);
				var questrewards = QuestsBase.GetAllRewards();
				// Checking that the missionID exists on pending rewards before doing anything
				for (var i in questrewards) {
					var qID = questrewards[i].m_QuestTaskID;
					if (qID == value) {
						QuestsBase.SignalQuestRewardInventorySpace.Connect(InventoryFull, this);
						PlayerInventory.SignalItemAdded.Connect(SlotItemAddedBuffer, this);
						PlayerInventory.SignalItemStatChanged.Connect(SlotItemStatChanged, this);
						//PlayerInventory.SignalItemLoaded.Connect(SlotItemLoaded, this);
						DossierValueChanged("MissionsDone", 1)
						// in case item added,stat changed,and InventoryFull fail to trigger
						break
					}
				}
			}
		}
	}

	/* This only triggers for new stacks, which is fine. Could also try connecting to ItemBox
	 * Checks item(s) after 300ms, and clears signals 100ms after last item was added.
	 *
	 * Thoughts:
	 * Dossiers are the first items i have seen to trigger SignalItemLoaded:
	 * 		It seems that ItemLoaded has to finish before GetItemAt(pos) works, which is why there's 300ms buffer
	 * 		Desc: "SignalItemLoaded: Called from gamecode when an item is finished async loaded at the given pos."
	 * 		Does it always load the item in same position as it was added?
	 * 		Could i just use ItemLoaded to track dossiers?
	 *
	*/
	private function SlotItemAddedBuffer(inventoryID:com.Utils.ID32, pos:Number) {
		clearTimeout(clearlocktimeout);
		clearlocktimeout = setTimeout(Delegate.create(this, ClearMissionlock), 100);
		setTimeout(Delegate.create(this, SlotItemAdded), 300, pos);
	}

	// Only used to see to disconnect signals and debugging
	private function SlotItemStatChanged(id,pos) {
		PrintDebug(PlayerInventory.GetItemAt(pos).m_Name+"('s) received from mission", true)
		clearTimeout(clearlocktimeout);
		clearlocktimeout = setTimeout(Delegate.create(this, ClearMissionlock), 100);
	}

	private function SlotItemLoaded(id, pos) {
		PrintDebug(PlayerInventory.GetItemAt(pos).m_Name+"('s) loaded", true)
	}

	// Checks if the added item is Agent Dossier
	private function SlotItemAdded(pos:Number) {
		var item:InventoryItem = PlayerInventory.GetItemAt(pos);
		PrintDebug(item.m_Name+"('s) received from mission", true);
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

	// Missionlock is cleared 100ms after last item was added/changed, inventory was full,or 1000ms as fallback method(shouldn't happen).
	private function ClearMissionlock() {
		QuestsBase.SignalQuestRewardInventorySpace.Disconnect(InventoryFull, this);
		PlayerInventory.SignalItemAdded.Disconnect(SlotItemAddedBuffer, this);
		PlayerInventory.SignalItemStatChanged.Disconnect(SlotItemStatChanged, this);
		//PlayerInventory.SignalItemAdded.Disconnect(SlotItemLoaded, this);
		//settings this to false will let the report window to know we are ready to collect rewards for the next mission
		MissionCompletedSignal.SetValue(false);
	}
}