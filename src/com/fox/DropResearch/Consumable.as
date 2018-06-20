import com.GameInterface.DistributedValue;
import com.GameInterface.DistributedValueBase;
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
	public static var WatchedConsumables:Object = new Object();

	public function Consumable() {
		//glyph reward bag, all zones seem to have same glyph bags
		WatchedConsumables["9284361"] = ["item"];
		//Ext.ord.Talisman bag (Tribal)
		WatchedConsumables["9418597"] = ["item"];
		//Agent Vanity Reward bag(blue)
		WatchedConsumables["9407816"] = ["item"];
		//Agent gear reward bag(green,blue,purple)
		WatchedConsumables["9400612"] = ["item"];
		WatchedConsumables["9400614"] = ["item"];
		WatchedConsumables["9400616"] = ["item"];
		//Agent boosters,normal,Saf
		WatchedConsumables["9405652"] = ["item"];
		WatchedConsumables["9419208"] = ["item"];

		//Kaidan key
		WatchedConsumables["9338616"] = ["item", "currency"];
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
	public function Disconnect() {
		ItemUsed.SignalChanged.Disconnect(ConsumableUsed, this);
	}
	//New stack started
	private function SlotItemAddedBuffer(inventoryID:com.Utils.ID32, itemPos:Number) {
		var item = PlayerInventory.GetItemAt(itemPos);
		if (item) {
			PrintDebug(item.m_Name+" Received from consumable", true);
			ClearConsumableMonitoring();
			ArchieveConsumable(item);
		} else {
			setTimeout(Delegate.create(this, SlotItemAdded), 250,itemPos);
		}
	}

	// Stack size changed
	private function SlotItemStatChangedBuffer(inventoryID:com.Utils.ID32, itemPos:Number, stat:Number, newValue:Number ) {
		// If player opens from stack of items we don't want it to trigger for the consumed item
		var item = PlayerInventory.GetItemAt(itemPos);
		if (item.m_ACGItem.m_TemplateID0 != Number(watchedItemID)) {
			if (item) {
				PrintDebug(item.m_Name+" Received from consumable", true);
				ArchieveConsumable(item);
			} else {
				setTimeout(Delegate.create(this, SlotItemStatChanged), 250, itemPos);
			}
		}
	}
	private function SlotCurrencyAdded(id:Number, newValue:Number, oldValue:Number) {
		if (newValue>oldValue) {
			var amount = newValue-oldValue;
			PrintDebug(amount + "of id:" + id + " Currency received from consumable", true);
			ArchieveConsumable(id);
		}
	}

	// In case the item was not found
	private function SlotItemAdded(itemPos:Number) {
		var item = PlayerInventory.GetItemAt(itemPos);
		if (item) {
			PrintDebug(item.m_Name+" Received from consumable", true);
			ArchieveConsumable(item);
		}
	}
	private function SlotItemStatChanged(itemPos:Number) {
		var item = PlayerInventory.GetItemAt(itemPos);
		if (item) {
			PrintDebug(item.m_Name+" Received from consumable", true);
			ArchieveConsumable(item);
		}
	}

	//Currently doesn't support counting the currency, or multiple items from consumable
	private function ArchieveConsumable(item) {
		var id;
		// ItemID:SignetID
		if (item.m_ACGItem.m_TemplateID0) {
			id = string(item.m_ACGItem.m_TemplateID0);
			if (item.m_ACGItem.m_TemplateID2) id += ":" + string(item.m_ACGItem.m_TemplateID2);
		}
		//Fallback
		else if (item.m_Name) {
			id = item.m_Name;
		}
		//Currency
		else {
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
		ClearConsumableMonitoring();
	}

	private function ClearConsumableMonitoring() {
		clearTimeout(ConsumableTimeout);
		PlayerInventory.SignalItemAdded.Disconnect(SlotItemAddedBuffer, this);
		PlayerInventory.SignalItemStatChanged.Disconnect(SlotItemStatChangedBuffer, this);
		Player.SignalTokenAmountChanged.Disconnect(SlotCurrencyAdded, this);
		ItemUsed.SetValue(false)

	}

	private function ConsumableUsed() {
		var val = ItemUsed.GetValue();
		if (val) {
			watchedItemID = Number(val);
			clearTimeout(ConsumableTimeout);
			for (var i in WatchedConsumables[val]) {
				if (WatchedConsumables[val][i] == "item") {
					PlayerInventory.SignalItemAdded.Connect(SlotItemAddedBuffer, this);
					PlayerInventory.SignalItemStatChanged.Connect(SlotItemStatChangedBuffer, this);
				} else if (WatchedConsumables[val][i] == "currency") {
					Player.SignalTokenAmountChanged.Connect(SlotCurrencyAdded, this);
				}
			}
			ConsumableTimeout = setTimeout(Delegate.create(this, ClearConsumableMonitoring), 500);
		}
	}

	/* 
	* Prototyping Inventory instead of InventoryBase would allow this to somewhat work with items used by BagUtils.
	* However with no clear way to tell where the item was received from there would be mistakes due to high opening speed of the mod.
	* This only matters for Glyph Bags and Container keys, which have plenty of data anyways.
	*/ 
	public function HookItems() {
		if (!_global.com.GameInterface.InventoryBase.prototype._UseItem) {
			if (!_global.com.GameInterface.InventoryBase.prototype.UseItem) {
				setTimeout(Delegate.create(this, HookItems), 500);
				return
			}
			_global.com.GameInterface.InventoryBase.prototype._UseItem = _global.com.GameInterface.InventoryBase.prototype.UseItem;
			_global.com.GameInterface.InventoryBase.prototype.UseItem = function (pos) {
				if (com.fox.DropResearch.Consumable.WatchedConsumables[string(this.m_Items[pos].m_ACGItem.m_TemplateID0)]) {
					DistributedValueBase.SetDValue("ItemUsed_DR",string(this.m_Items[pos].m_ACGItem.m_TemplateID0));
					setTimeout(Delegate.create(this, this._UseItem), 25, pos);
				} else {
					// Still opening previous
					if (DistributedValueBase.GetDValue("ItemUsed_DR")) {
						setTimeout(Delegate.create(this,this.UseItem), 25, pos);
					} else {
						this._UseItem(pos);
					}
				}
			}
		}
	}
}