import com.GameInterface.DistributedValue;
import com.GameInterface.Game.Character;
import com.GameInterface.InventoryItem;
import com.Utils.Archive;
import com.fox.DropResearch.BaseClass;
import mx.utils.Delegate;
/**
 * ...
 * @author fox
 */
class com.fox.DropResearch.Consumable extends BaseClass {
	//consumables
	private var ItemUsed:DistributedValue;
	private var watchedItemID:Number;
	private var ConsumableTimeout;
	private var Player:Character = Character.GetClientCharacter();
	public static var WatchedConsumables:Object = new Object();

	public function Consumable() {
		//glyph bag(KD)
		WatchedConsumables["9284361"] = new Array("item");
		//Ext.ord.Talisman bag (Tribal)
		WatchedConsumables["9418597"] = new Array("item");
		//Agent Vanity Reward bag(blue)
		WatchedConsumables["9407816"] = new Array("item");
		//Agent gear reward bag(green)
		WatchedConsumables["9400612"] = new Array("item");
		//Kaidan key
		WatchedConsumables["9338616"] = new Array("item", "currency");
		
		//witch doctors weapon bag
		// WatchedConsumables["9418801"] = new Array("item"); // Always mk3, assuming equal chance for all weapons/suffixes
		//frost-bound weapon bag
		// WatchedConsumables["9382422"] = new Array("item"); // wont get enough data at this point to bother

		ItemUsed = DistributedValue.Create("ItemUsed_DR");
		ItemUsed.SetValue(false);
		ItemUsed.SignalChanged.Connect(ConsumableUsed, this);
		HookItems();
	}
	//probably not needed
	public function Disconnect(){
		ItemUsed.SignalChanged.Disconnect(ConsumableUsed, this);
	}
	//New stack started
	private function SlotItemAddedBuffer(inventoryID:com.Utils.ID32, itemPos:Number) {
		ClearConsumableMonitoring();
		ConsumableTimeout = setTimeout(Delegate.create(this, SlotItemAdded), 100,itemPos);
	}

	// Stack size changed
	private function SlotItemStatChangedBuffer(inventoryID:com.Utils.ID32, itemPos:Number, stat:Number, newValue:Number ) {
		// If player opens from stack of items we don't want it to trigger for the consumed items
		if (PlayerInventory.GetItemAt(itemPos).m_ACGItem.m_TemplateID0 != Number(watchedItemID)) {
			ClearConsumableMonitoring();
			setTimeout(Delegate.create(this, SlotItemStatChanged), 100, itemPos,stat);
		}
	}

	private function SlotItemAdded(itemPos:Number) {
		var item = PlayerInventory.GetItemAt(itemPos);
		PrintDebug(item.m_Name+" Received from consumable",true);
		ArchieveConsumable(item);
	}

	private function SlotItemStatChanged(itemPos:Number, stat) {
		var item = PlayerInventory.GetItemAt(itemPos);
		PrintDebug(item.m_Name+" Received from consumable",true);
		ArchieveConsumable(item);
	}
	
	private function SlotCurrencyAdded(id:Number, newValue:Number, oldValue:Number){
		if(newValue>oldValue){
			ClearConsumableMonitoring();
			var amount = newValue-oldValue;
			PrintDebug(amount + "of id:" + id + " Currency received from consumable", true);
			ArchieveConsumable(id);
		}
	}
	
	//Currently doesn't support counting the currency or multiple items
	private function ArchieveConsumable(item){
		if(watchedItemID && item){
			var id;
			// ItemID:SignetID
			if (item.m_ACGItem.m_TemplateID2) {
				id = string(item.m_ACGItem.m_TemplateID0) + ":" + string(item.m_ACGItem.m_TemplateID2);
			} else if(item.m_ACGItem.m_TemplateID0) {
				id = string(item.m_ACGItem.m_TemplateID0);
			}
			//Fallback
			else if(item.m_Name){
				id = item.m_Name;
			}
			//Currency
			else{
				id = item;
			}
			var ConsumableArchieves:Archive = Consumables.GetValue();
			var ConsumableArchieve = ConsumableArchieves.FindEntry(string(watchedItemID), new Archive());
			var openedAmount = Number(ConsumableArchieve.FindEntry("Opened", 0));
			ConsumableArchieve.ReplaceEntry("Opened", openedAmount + 1)
			var amount = Number(ConsumableArchieve.FindEntry(id, 0));
			ConsumableArchieve.ReplaceEntry(id, amount + 1);
			ConsumableArchieves.ReplaceEntry(string(watchedItemID), ConsumableArchieve);
			Consumables.SetValue(ConsumableArchieves);
			ManualSave();
			watchedItemID = undefined;
		}
	}

	private function ClearConsumableMonitoring() {
		PlayerInventory.SignalItemAdded.Disconnect(SlotItemAddedBuffer, this);
		PlayerInventory.SignalItemStatChanged.Disconnect(SlotItemStatChangedBuffer, this);
		Player.SignalTokenAmountChanged.Disconnect(SlotCurrencyAdded, this);
	}

	private function ConsumableUsed() {
		if (ItemUsed.GetValue() != false) {
			watchedItemID = Number(ItemUsed.GetValue());
			clearTimeout(ConsumableTimeout);
			for (var i in WatchedConsumables[string(watchedItemID)]){
				if (WatchedConsumables[string(watchedItemID)][i] == "item"){
					PlayerInventory.SignalItemAdded.Connect(SlotItemAddedBuffer, this);
					PlayerInventory.SignalItemStatChanged.Connect(SlotItemStatChangedBuffer, this);
				}
				else if (WatchedConsumables[string(watchedItemID)][i] == "currency"){
					Player.SignalTokenAmountChanged.Connect(SlotCurrencyAdded, this);
					
				}
			}
			ConsumableTimeout = setTimeout(Delegate.create(this, ClearConsumableMonitoring), 500);
		}
		ItemUsed.SetValue(false)
	}


	private function HookSlot(clip) {
		var slot = clip["m_SlotMC"];
		var item:InventoryItem = clip["m_ItemData"];
		if (!slot._onMousePress) {
			slot._onMousePress = slot.onMousePress;
			slot.onMousePress = function (buttonIdx:Number, clickCount:Number) {
				if (com.fox.DropResearch.Consumable.WatchedConsumables[string(this.m_ItemData.m_ACGItem.m_TemplateID0)] && !Key.isDown(Key.CONTROL) && (clickCount==2 || buttonIdx == 2)) {
					com.GameInterface.DistributedValueBase.SetDValue("ItemUsed_DR", string(item.m_ACGItem.m_TemplateID0));
					setTimeout(Delegate.create(this, slot._onMousePress), 25, buttonIdx, clickCount);
				} else {
					slot._onMousePress(buttonIdx, clickCount);
				}
			}
		}
	}

	// Could probably somehow connect iconbox signals instead?
	// Delays opening of watched item until i have connected my own signals
	// Only delays is ctrl is not held down, and double-click or right-click
	// There is a 25ms window where wrong item could be registered, not really a problem unless player receives item from other source 
	//	 or opens other item simultaneously (using Xeio's bagUtil mod for example)
	// 
	private function HookItems() {
		if (!_root.backpack2 || !_global.com.Components.ItemSlot.prototype.onMousePress) {
			setTimeout(Delegate.create(this, HookItems), 50);
			return
		}
		// Add our own stuff to ItemSlot OnMousePress function
		if (!_global.com.Components.ItemSlot.prototype._onMousePress) {
			_global.com.Components.ItemSlot.prototype._onMousePress = _global.com.Components.ItemSlot.prototype.onMousePress;
			_global.com.Components.ItemSlot.prototype.onMousePress = function (buttonIdx:Number, clickCount:Number) {
				if (com.fox.DropResearch.Consumable.WatchedConsumables[string(this.m_ItemData.m_ACGItem.m_TemplateID0)] && !Key.isDown(Key.CONTROL) && (clickCount==2 || buttonIdx == 2)) {
					com.GameInterface.DistributedValueBase.SetDValue("ItemUsed_DR", string(this.m_ItemData.m_ACGItem.m_TemplateID0));
					setTimeout(Delegate.create(this, this._onMousePress), 25, buttonIdx, clickCount);
				} else {
					this._onMousePress(buttonIdx, clickCount);
				}
			}
		}

		// Connect the ones that were already initialized
		// Prototype will take care of the added items
		for (var i in _root.backpack2.m_IconBoxes) {
			var box = _root.backpack2.m_IconBoxes[i];
			for (var y in box["m_ItemSlots"]) {
				for (var x in box["m_ItemSlots"][y]) {
					var slot = box["m_ItemSlots"][y][x];
					HookSlot(slot);
				}
			}
		}
	}
}