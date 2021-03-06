﻿
import com.thesecretworld.chronicle.Gongju.Collection.Node;
import com.thesecretworld.chronicle.Gongju.Data.ClothingSortException;

import com.GameInterface.Chat;
import com.GameInterface.Game.Character;
import com.GameInterface.Inventory;
import com.GameInterface.InventoryItem;
import com.GameInterface.ShopInterface;

import com.Utils.LDBFormat;
import com.Utils.ID32;
import com.Utils.Archive;
import com.Utils.Signal;

class ElgaCore {
	
	private var m_WardrobeInventory:Inventory; // character wardrobe
	private var m_EquippedInventory:Inventory; // character current clothes
	private var m_SortedItems:Object; // used for sorting all clothing by placement
	private var m_RootNode:Node; // tree node of clothing = result of grouping/sorting clothing
	
	private var m_LocationLabels; // Labels for locations (Legs, Rear) with indexes like an enum (0,1,2, 3...)
	private var m_LocationLabels2; // Same as m_LocationLabels, but indexes are 2^0 = 1, 2^1 = 2, 2^2 = 4, 2^3 = 8...)
	private var m_IconIdToPlacementDict; // from a merchant item icon id, gives the placement as m_LocationLabels2 index
	private var m_PlacementIdToPowerTwo:Object; // map to link location index from enum version to 2^enum version, currently useless
	private var m_PlacementOrder:Array;
	
	private var m_LanguageCode:String;
	private var m_DefaultTranslation:String;
	
	private var m_ClothingSetNames:Object;
	
	private var m_ExceptionByLang:Object;
	
	private var m_SignalExceptionChanged:Signal;
	
	public function subscribeToWardrobeChange(functionPointer, target) {
		m_WardrobeInventory.SignalItemAdded.Connect(functionPointer, target);
        m_WardrobeInventory.SignalItemChanged.Connect(functionPointer, target);
        m_WardrobeInventory.SignalItemRemoved.Connect(functionPointer, target);
        
        m_EquippedInventory.SignalItemAdded.Connect(functionPointer, target);
        m_EquippedInventory.SignalItemChanged.Connect(functionPointer, target);
        m_EquippedInventory.SignalItemRemoved.Connect(functionPointer, target);
		
		m_SignalExceptionChanged.Connect(functionPointer, target);
	}
	
	public function unsubscribeToWardrobeChange(functionPointer, target) {
		m_WardrobeInventory.SignalItemAdded.Disconnect( functionPointer, target );
        m_WardrobeInventory.SignalItemChanged.Disconnect( functionPointer, target );
        m_WardrobeInventory.SignalItemRemoved.Disconnect( functionPointer, target );
        
        m_EquippedInventory.SignalItemAdded.Disconnect( functionPointer, target );
        m_EquippedInventory.SignalItemChanged.Disconnect( functionPointer, target );
        m_EquippedInventory.SignalItemRemoved.Disconnect( functionPointer, target );
		
		m_SignalExceptionChanged.Disconnect(functionPointer, target);
	}
	
	public function ElgaCore() {
		var clientCharacterID:ID32 = Character.GetClientCharID();
        m_WardrobeInventory = new Inventory( new com.Utils.ID32(_global.Enums.InvType.e_Type_GC_StaticInventory, clientCharacterID.GetInstance()) );
		m_EquippedInventory = new Inventory( new com.Utils.ID32(_global.Enums.InvType.e_Type_GC_WearInventory, clientCharacterID.GetInstance()) );
		
		m_LocationLabels = new Object();
		m_LocationLabels2 = new Object();
		
		m_LocationLabels[_global.Enums.ItemEquipLocation.e_Wear_FullOutfit] = undefined;
        m_LocationLabels[_global.Enums.ItemEquipLocation.e_Wear_Hat]        = undefined;
        m_LocationLabels[_global.Enums.ItemEquipLocation.e_Wear_Face]       = undefined;
        m_LocationLabels[_global.Enums.ItemEquipLocation.e_Wear_Neck]       = undefined;
        m_LocationLabels[_global.Enums.ItemEquipLocation.e_Wear_Back]       = undefined;
        m_LocationLabels[_global.Enums.ItemEquipLocation.e_Wear_Chest]      = undefined;
        m_LocationLabels[_global.Enums.ItemEquipLocation.e_Wear_Hands]      = undefined;
        m_LocationLabels[_global.Enums.ItemEquipLocation.e_Wear_Belt]       = undefined;
        m_LocationLabels[_global.Enums.ItemEquipLocation.e_Wear_Legs]       = undefined;
        m_LocationLabels[_global.Enums.ItemEquipLocation.e_Wear_Feet]       = undefined;
        m_LocationLabels[_global.Enums.ItemEquipLocation.e_Ring_1]          = undefined;
        m_LocationLabels[_global.Enums.ItemEquipLocation.e_Ring_2]          = undefined;
        m_LocationLabels[_global.Enums.ItemEquipLocation.e_HeadAccessory]   = undefined;
		
		m_IconIdToPlacementDict = new Object();
		m_IconIdToPlacementDict["1000624:7457527"] = 1; // supposition TODO: check
		m_IconIdToPlacementDict["1000624:7457528"] = 2048;
		m_IconIdToPlacementDict["1000624:7457529"] = 2; // supposition TODO: check
		m_IconIdToPlacementDict["1000624:7457530"] = 1024;
		m_IconIdToPlacementDict["1000624:7457531"] = 16;
		m_IconIdToPlacementDict["1000624:7457532"] = 32;
		m_IconIdToPlacementDict["1000624:7457533"] = 128;
		m_IconIdToPlacementDict["1000624:7457534"] = 4;
		
		m_PlacementOrder = new Array();
		m_PlacementOrder.push(Math.pow(2, _global.Enums.ItemEquipLocation.e_Wear_Hat));
		m_PlacementOrder.push(Math.pow(2, _global.Enums.ItemEquipLocation.e_HeadAccessory));
		m_PlacementOrder.push(Math.pow(2, _global.Enums.ItemEquipLocation.e_Wear_Face));
		m_PlacementOrder.push(Math.pow(2, _global.Enums.ItemEquipLocation.e_Wear_Neck));
		m_PlacementOrder.push(Math.pow(2, _global.Enums.ItemEquipLocation.e_Wear_Chest));
		m_PlacementOrder.push(Math.pow(2, _global.Enums.ItemEquipLocation.e_Wear_Back));
		m_PlacementOrder.push(Math.pow(2, _global.Enums.ItemEquipLocation.e_Wear_Hands));
		m_PlacementOrder.push(Math.pow(2, _global.Enums.ItemEquipLocation.e_Wear_Legs));
		m_PlacementOrder.push(Math.pow(2, _global.Enums.ItemEquipLocation.e_Wear_Feet));
		m_PlacementOrder.push(Math.pow(2, _global.Enums.ItemEquipLocation.e_Wear_FullOutfit));
		
        for ( var i in m_LocationLabels )
        {
            m_LocationLabels[i] = LDBFormat.LDBGetText("WearLocations", Number(i));
        }
		
		for ( var i in m_LocationLabels )
        {
			m_PlacementIdToPowerTwo[i] = Math.pow(2,Number(i));
			m_LocationLabels2[Math.pow(2,Number(i))] = m_LocationLabels[i];
        }
		
		m_LanguageCode =  LDBFormat.GetCurrentLanguageCode();
		
		if (m_LanguageCode == "de") {
			m_DefaultTranslation = "Standard";
		}
		if (m_LanguageCode == "fr") {
			m_DefaultTranslation = "défaut";
		}

		if (m_LanguageCode == "en") {
			m_DefaultTranslation = "default";
		}
		
		m_SignalExceptionChanged = new Signal();
		
	}
	
	public function getEquipedInventory():Inventory {
		return m_EquippedInventory;
	}
	
	public function equipOrUnequipClothing(item):Void {
		if ( item.m_IsEquipped ) {
            if ( canLocationBeUnequipped( item.m_IndexInInventory )) {
				m_WardrobeInventory.AddItem( item.m_InventoryID, item.m_IndexInInventory, _global.Enums.ItemEquipLocation.e_Wear_DefaultLocation );
			}
		}
		else {
			m_EquippedInventory.AddItem( item.m_InventoryID, item.m_IndexInInventory, _global.Enums.ItemEquipLocation.e_Wear_DefaultLocation );
		}
	}
	
	public function unequipClothing(slotID):Void {
		for (var count:Number = 0; count < m_EquippedInventory.GetMaxItems(); ++count) {
			var itemEquipped = m_EquippedInventory[count];
			if (itemEquipped.m_Placement == slotID) {
				if (canLocationBeUnequipped( itemEquipped.m_InventoryPos)) {
					m_WardrobeInventory.AddItem(m_EquippedInventory.m_InventoryID(),
						itemEquipped.m_InventoryPos,
						_global.Enums.ItemEquipLocation.e_Wear_DefaultLocation);
					return;
				}
			}
		}
	}
	
	public function equipClothingInWardrobeFromName(itemName, placementID):Void{
		if (itemName == undefined || itemName == "null" || itemName == null) {
			unequipClothing(placementID);
			return;
		}
		for (var idx:Number = 0; idx < m_WardrobeInventory.GetMaxItems(); ++idx) {
			var itemFromWardrobe:InventoryItem = m_WardrobeInventory.GetItemAt(idx);
			if (itemFromWardrobe && itemFromWardrobe.m_Name == itemName) {
				m_EquippedInventory.AddItem( m_WardrobeInventory.m_InventoryID, idx,
					_global.Enums.ItemEquipLocation.e_Wear_DefaultLocation );
				break;
			}
		}
	}
	
	public function previewClothing(clothingItem:Object):Boolean {
		if (clothingItem != null && clothingItem.m_IndexInInventory != null){
			
			var inventoryToPreview = null;
			if (clothingItem.m_InventoryName == "_Wardrobe") {
				inventoryToPreview = m_WardrobeInventory;
			}
			else if (clothingItem.m_InventoryName == "_Equipped") {
				inventoryToPreview = m_EquippedInventory;
			}
			else {
				var inventoryName:String = clothingItem.m_InventoryName;
				for (var shopInterfaceName in _global.gongjuShopDict) {
					if (shopInterfaceName == clothingItem.m_InventoryName) {
						inventoryToPreview = _global.gongjuShopDict[shopInterfaceName];
						break
					}
				}
			}
			
			if (inventoryToPreview != null) {
				inventoryToPreview.PreviewItem(clothingItem.m_IndexInInventory);
				return true;
			}
		}
		else {
			Chat.SignalShowFIFOMessage.Emit("Erreur sur preview", 0);
		}
		return false;
	}
	
	public function listAllWearedClothes():String {
		var result:String = "";
		for (var key in m_LocationLabels ) {
			var invItem:InventoryItem = m_EquippedInventory.GetItemAt(key);
			if (invItem != undefined && invItem.m_Name != undefined)
				result = result + invItem.m_Name + "\n";
        }
		return result;
	}
	
	public function listAllOwnedClothes():String {
		var result:String = listAllWearedClothes();
		for ( var i:Number = 0 ; i < m_WardrobeInventory.GetMaxItems() ; ++i ) {
			var invItem:InventoryItem = m_WardrobeInventory.GetItemAt(i);
			if (invItem != undefined && invItem.m_Name != undefined) {
				result = result + invItem.m_Name + "\n";
			}
		}
		return result;
	}
	
	public function getClothingList(filter:String, showVendorItems:Boolean):Node {
		m_SortedItems = new Object();
		var placementDict:Object = new Object();
		var placementArray:Array = new Array();
		
		// put all the wardrobe items in their respective placement
		for ( var i:Number = 0 ; i < m_WardrobeInventory.GetMaxItems() ; ++i ) {
			var invItem:InventoryItem = m_WardrobeInventory.GetItemAt(i);
			if ( invItem && matchFilter(invItem.m_Name, filter)) {
				// invItem.m_Placement and m_SortedItems modified by addItemToSortedItems
				addItemToSortedItems(invItem.m_Name, i, m_WardrobeInventory.m_InventoryID, "_Wardrobe", invItem.m_Placement);
				placementDict[invItem.m_Placement] = 1;
			}
		}
		
		for ( i in m_LocationLabels ) {
			var invItem:InventoryItem = m_EquippedInventory.GetItemAt(i);
			if (invItem && matchFilter(invItem.m_Name, filter))  { // filtering on equiped clothing
            //if (invItem) { // not filtering on equiped clothing
				// invItem.m_Placement and m_SortedItems modified by addItemToSortedItems
				var clothingItem = addItemToSortedItems(invItem.m_Name, i, m_EquippedInventory.m_InventoryID, "_Equipped", invItem.m_Placement);
				placementDict[invItem.m_Placement] = 1;
            }
        }
		
		if (showVendorItems)
		{
			for (var shopInterfaceKey:String in _global.gongjuShopDict) {
				var shopInterface:ShopInterface = _global.gongjuShopDict[shopInterfaceKey];
				if (shopInterface != null) {
					for (var shopInterfaceItemIdx:Number = 0; shopInterfaceItemIdx < shopInterface.m_Items.length; shopInterfaceItemIdx++) {
						var shopInterfaceItem:InventoryItem = shopInterface.m_Items[shopInterfaceItemIdx];
						if (shouldAddShopItem(shopInterfaceItem, shopInterface, filter)) {
							// result of GetPlacementForItem(shopInterfaceItem) and m_SortedItems modified by addItemToSortedItems
							addItemToSortedItems(shopInterfaceItem.m_Name, shopInterfaceItemIdx, shopInterfaceKey, shopInterfaceKey, GetPlacementForItem(shopInterfaceItem), shopInterfaceItem);
							placementDict[shopInterfaceItem.m_Placement] = 1;
						}
					}
				}
				else {
					Chat.SignalShowFIFOMessage.Emit("Error: Shop interface is null" , 0);
				}
			}
		}
		
		for (var orderIdx = 0; orderIdx < m_PlacementOrder.length; orderIdx++) {
			//if (placementDict[m_PlacementOrder[orderIdx]] == 1)
				placementArray.push(m_PlacementOrder[orderIdx]);
		}
		
		// analyse each item in a placement to try to build group of items
		m_RootNode = new Node("root");
		m_ClothingSetNames = new Object();
		for (var placementArrayIdx = 0; placementArrayIdx < placementArray.length; placementArrayIdx++) {
		//for (var placementIt in placementDict) {
			var placementIt = placementArray[placementArrayIdx];
			var placement = m_SortedItems[placementIt];
			var placementNode:Node = organizeClothing(placement, m_LocationLabels2[placementIt]);
			placementNode.sortOnName(); // sort here to avoid sorting the children of root (== placement)
			m_RootNode.addChild(placementNode);
		}
		
		return m_RootNode;
	}
	
	public function shouldAddShopItem(shopInterfaceItem:InventoryItem, shopInterface:ShopInterface, filter:String ):Boolean {
		var returnValue:Boolean = false;
		if (shopInterfaceItem != null)
			if (shopInterface.CanPreview(shopInterfaceItem.m_InventoryPos))
				if (rightToPurchaseItem(shopInterfaceItem))
					if (matchFilter(shopInterfaceItem.m_Name, filter))
						returnValue = true;
			
		return returnValue;
	}
	
	private function matchFilter(name:String, filter:String):Boolean {
		if (filter.length == 0)
			return true;
		
		name = name.toLowerCase();
		
		var searchSplit:Array = filter.split(" ");
		for (var idx:Number = 0; idx < searchSplit.length; ++idx) {
			var searchFilter = searchSplit[idx];
			if (searchFilter == null || searchFilter.length == 0)
				continue;
			if (name.indexOf(searchFilter) == -1) {
				return false;
			}
		}
		
		return true;
	}
	
	private function organizeClothing(placement:Array, placementName:String): Node {
		var rootNode:Node = new Node(placementName);
		if (placement != null) {
			for (var placementIdx:Number = 0; placementIdx < placement.length; placementIdx++) {
				var clothingItem = placement[placementIdx];
				if (!clothingItem)
					continue;
				
				getNodeNames(clothingItem);
				
				var firstNodeName:String = null;
				var secondNodeName:String = null;
				
				if (clothingItem.m_IsNameCustom) {
					if (clothingItem.m_CustomCategory == null) {
						firstNodeName = clothingItem.m_CustomShortName;
						//Chat.SignalShowFIFOMessage.Emit("Elga: Load Clothing Exception: " + clothingItem.m_Name + "|" + firstNodeName , 0);
					} else {
						firstNodeName = clothingItem.m_CustomCategory;
						secondNodeName = clothingItem.m_CustomShortName;
						//Chat.SignalShowFIFOMessage.Emit("Elga: Load Clothing Exception: " + clothingItem.m_Name + "|" + firstNodeName + ":" + secondNodeName , 0);
					}
					

				} else {
					if (clothingItem.m_DefaultCategory == null) {
						firstNodeName = clothingItem.m_DefaultShortName;
					} else {
						firstNodeName = clothingItem.m_DefaultCategory;
						secondNodeName = clothingItem.m_DefaultShortName;
					}
				}
				
				var secondNode:Node = null;
				var firstNode:Node = null;
				
				if (rootNode.hasNodeNamed(firstNodeName)) {
					//if the first node exist
					var firstNodeFromRoot = rootNode.getChildNamed(firstNodeName);
					
					if (firstNodeFromRoot.hasNodeData()) { // if the node is direclty a cloth, moving the node to the lower level
						var firstNodeData = firstNodeFromRoot.getNodeData();
						firstNodeFromRoot.setNodeData(null);
						
						var originalSecondNode:Node = new Node("(" + m_DefaultTranslation + ")");
						originalSecondNode.setNodeData(firstNodeData);
						firstNodeFromRoot.addChild(originalSecondNode);
					}
					
					if (secondNodeName == null) {
						secondNode = new Node("(" + m_DefaultTranslation + ")");
					} else {
						secondNode = new Node(secondNodeName);
					}
					secondNode.setNodeData(clothingItem);
					firstNodeFromRoot.addChild(secondNode);
				}
				else { // if the first node does not exist, i do what i want (no bother)
					firstNode = new Node(firstNodeName);
					rootNode.addChild(firstNode);
					
					if (secondNodeName != null) {
						secondNode = new Node(secondNodeName);
					}
					if (secondNode != null) {
						secondNode.setNodeData(clothingItem);
						firstNode.addChild(secondNode);
					}
					else {
						firstNode.setNodeData(clothingItem);
					}
				}
			}
		}
		return rootNode;
	}
	
	function addItemToSortedItems(itemName, itemIndexInInventory, inventoryID, inventoryName, itemPlacement, item): Object {
		var clothingItem = new Object();
		clothingItem.m_Name = itemName;
		clothingItem.m_IndexInInventory = itemIndexInInventory;
		clothingItem.m_InventoryID = inventoryID;
		clothingItem.m_Item = inventoryID;
		clothingItem.m_InventoryName = inventoryName;
		clothingItem.m_Placement = itemPlacement;
		clothingItem.m_Price = setItemTextPrice(item);
		if (inventoryName == "_Equipped")
			clothingItem.m_IsEquipped = true;
		if (inventoryName != "_Equipped" && inventoryName != "_Wardrobe")
			clothingItem.m_IsBuyable = true;
		
		if (itemPlacement  != null) {
			if (m_SortedItems[itemPlacement] == null) {
				m_SortedItems[itemPlacement] = new Array();
			}
			var placement:Array = m_SortedItems[itemPlacement];
			placement.push(clothingItem);
		}
		return clothingItem;
	}
	
	// Cut the name of clothings into 2 parts for elga columns
	private function getNodeNames(clothingItem):Void {
		var clothingName:String = clothingItem.m_Name;
		var firstNodeName:String = clothingName; // groupName, if a split was found, otherwise fullName
		var secondNodeName:String = null; // = endName, usually with the color or set name
		
		var exceptions:Object = null;
		if (m_ExceptionByLang)
			exceptions = m_ExceptionByLang[m_LanguageCode];
			
		if (exceptions && exceptions[clothingName]) {
			var cse:ClothingSortException = exceptions[clothingName];
			firstNodeName = cse.getCustomCategory();
			if (firstNodeName == null || firstNodeName == "")
				firstNodeName = cse.getCustomName();
			else
				secondNodeName = cse.getCustomName();
			
			if (secondNodeName == null || secondNodeName == "") {
				delete clothingItem.m_CustomCategory;
				clothingItem.m_CustomShortName = firstNodeName;
			} else {
				clothingItem.m_CustomCategory = firstNodeName;
				clothingItem.m_CustomShortName = secondNodeName;
			}
			clothingItem.m_IsNameCustom = true;
		} else {
			clothingItem.m_IsNameCustom = false;
		}
		
		var charIndex:Number = -1; 
		
		// move the set title at the end of the name
		// ie: Venetian Tactical Armor – Military beret
		// becomes:
		// groupName: Military beret
		// endName: (Venetian Tactical Armor)
		var firstCutIdx:Number = clothingName.indexOf(" - ");
		if (firstCutIdx != -1) {
			charIndex = clothingName.length - ( firstCutIdx + 3);
			
			var clothingSetName:String = clothingName.substring(0, firstCutIdx);
			
			if (m_ClothingSetNames[clothingSetName] == undefined)
				m_ClothingSetNames[clothingSetName] = new Object();
				
			clothingName =  clothingName.substring(firstCutIdx + 3) +
				" (" + clothingSetName + ")";
		}
		
		// put everything after the virgula at the end (virgula included)
		var virgulaIdx = clothingName.indexOf(", ");
		if (virgulaIdx != -1) {
			charIndex = virgulaIdx;
		}
		
		// remove remaining useless chars (triming spaces and removing , at ends)
		if (charIndex != -1) {
			firstNodeName = trim(clothingName.substring(0, charIndex));
			if (firstNodeName.lastIndexOf(",") == firstNodeName.length - 1) {
				firstNodeName = firstNodeName.substring(0, firstNodeName.length - 1);
			}
			secondNodeName = trim(clothingName.substring(charIndex));
			if (secondNodeName.indexOf(", ") == 0) // get rid of the starting virgula
				secondNodeName = secondNodeName.substring(2);
		}
		
		if (secondNodeName == null || secondNodeName == "") {
			delete clothingItem.m_DefaultCategory;
			clothingItem.m_DefaultShortName = firstNodeName;
		} else {
			clothingItem.m_DefaultCategory = firstNodeName;
			clothingItem.m_DefaultShortName = secondNodeName;
		}
	}
	
	private function setItemTextPrice(item:InventoryItem):String {
		if (item.m_TokenCurrencyPrice1 > 0 && item.m_TokenCurrencyType1 == _global.Enums.Token.e_Cash) {
			return item.m_TokenCurrencyPrice1 + " PAX";
		}
		if (item.m_TokenCurrencyPrice2 > 0 && item.m_TokenCurrencyType2 == _global.Enums.Token.e_Cash) {
			return  item.m_TokenCurrencyPrice2 + " PAX";
		}
		return null;
	}
	
	private function rightToPurchaseItem(inventoryItem:InventoryItem):Boolean
	{
   		return  (inventoryItem.m_CanBuy == undefined || inventoryItem.m_CanBuy);
	}
	
	private function GetPlacementForItem(invItem:InventoryItem):Object {
		return m_IconIdToPlacementDict[invItem.m_Icon];
	}
	
	private function canLocationBeUnequipped( location:Number ) : Boolean
    {
        return location != _global.Enums.ItemEquipLocation.e_Wear_Chest && location != _global.Enums.ItemEquipLocation.e_Wear_Legs;
    }
	
	private function trim(str:String):String
	{
    	for(var i = 0; str.charCodeAt(i) < 33; i++);
    	for(var j = str.length-1; str.charCodeAt(j) < 33; j--);
    	return str.substring(i, j+1);
	}
	
	public function changeClothingException(newCategory:String, newShortName:String, clothingItem:Object) {
		//m_LanguageCode
		var cse:ClothingSortException = null;
		var fullName:String = clothingItem.m_Name;
		
		if (newShortName == null || newShortName == "")
			newShortName = clothingItem.m_DefaultShortName; // shortName cannot be empty for clothing
			
		if (newCategory == "")
			newCategory = null; // but category name can be empty
			
		var changed = false;
		var isDefaultValue:Boolean = isClothingSortDefaultValue(newCategory, newShortName, clothingItem);
		if (m_ExceptionByLang[m_LanguageCode] && m_ExceptionByLang[m_LanguageCode][fullName]) {
			cse = m_ExceptionByLang[m_LanguageCode][fullName];
			if (isDefaultValue) {
				delete m_ExceptionByLang[m_LanguageCode][fullName];
				changed = true;
				//Chat.SignalShowFIFOMessage.Emit("Elga: Deleted Clothing Exception: " + fullName , 0);
			} else {
				changed = cse.update("", newCategory, newShortName);
				//Chat.SignalShowFIFOMessage.Emit("Elga: Updated Clothing Exception: " + fullName , 0);
			}
		} else {
			if (!isDefaultValue) {
				cse = new ClothingSortException(fullName, m_LanguageCode, "","", newCategory, newShortName);
				if (m_ExceptionByLang[m_LanguageCode] == null) {
					m_ExceptionByLang[m_LanguageCode] = new Object();
				}
				m_ExceptionByLang[m_LanguageCode][fullName] = cse;
				changed = true;
				//Chat.SignalShowFIFOMessage.Emit("Elga: New Clothing Exception: " + fullName + "|" + newCategory + ":" + newShortName , 0);
			}
		}
		if (changed) {
			Chat.SignalShowFIFOMessage.Emit("Elga: Clothing Exception changed: " + fullName , 0);
			m_SignalExceptionChanged.Emit(this);
		}
	}
	
	// if we are putting the default value for a cloth, removing it from the exceptions
	private function isClothingSortDefaultValue(category:String, shortName:String, clothingItem:Object):Boolean {
		var returnValue:Boolean = false;
		if (category == clothingItem.m_DefaultCategory && shortName == clothingItem.m_DefaultShortName)
			returnValue = true;
		return returnValue;
	}
	
	public function exportClothingSortException ():String {
		var result:String = "ELGA_EXPORT;0.5;" + m_LanguageCode + "\n";
		if (m_ExceptionByLang != null) {
			var exceptions = m_ExceptionByLang[m_LanguageCode];
			if (exceptions != null) {
				for (var realName:String in exceptions) {
					var cse:ClothingSortException = exceptions[realName];
					var realName = cse.getRealName();
					var customCategory = cse.getCustomCategory();
					var customShortName = cse.getCustomName();
					result = result + realName + "|" + customCategory  + "|" + customShortName + "\n";
				}
			}
		}
		
		return result;
	}
	
	// WE RESET THE EXCEPTIONS
	public static var IMPORTTYPE_RESET:String = "reset";
	public static var IMPORTTYPE_REPLACE:String = "replace";
	public static var IMPORTTYPE_LET:String = "let";
	
	public function importClothingSortException (text:String, mergeType:String):Void {
		var textSplit:Array = text.split(String.fromCharCode(13));
		var firstLine = textSplit.shift();
		var firstLineSplit = firstLine.split(";");
		if (firstLineSplit[0] != "ELGA_EXPORT") {
			Chat.SignalShowFIFOMessage.Emit("Elga : Import cancelled : Wrong import format", 0);
			return;
		}
			
		var version:String = firstLineSplit[1];
		var languageCode:String = firstLineSplit[2];
		if (languageCode != m_LanguageCode) {
			Chat.SignalShowFIFOMessage.Emit("Elga : Import cancelled : Wrong language code", 0);
			return; // wrong language code -> will not be usable
		}
		
		if (m_ExceptionByLang == null) {
			m_ExceptionByLang = new Object();
		}
		
		if (mergeType == IMPORTTYPE_RESET) {
			m_ExceptionByLang[m_LanguageCode] = new Object(); // reset the current language exceptions
		}

		var exceptions = m_ExceptionByLang[m_LanguageCode];
		
		for (var idx = 0; idx < textSplit.length; idx++ ) {
			var line:String = textSplit[idx];
			var lineSplit:Array = line.split("|");
			if (lineSplit.length == 3) {
				var fullName = lineSplit[0];
				if (exceptions[fullName] == null || mergeType == IMPORTTYPE_REPLACE) {
					var categoryName = lineSplit[1];
					var shortName = lineSplit[2];
					var cse:ClothingSortException = new ClothingSortException(fullName, "", "", m_LanguageCode, categoryName, shortName);
					exceptions[fullName] = cse; 
				}
			}
		}
		
		m_SignalExceptionChanged.Emit(this);
	}
	
	public function loadAllCSEFromArchiveArray(cseArchiveArray:Array) {
		m_ExceptionByLang = new Object();
		
		for (var idx = 0; idx < cseArchiveArray.length; idx++) {
			var cseArchive:Archive = cseArchiveArray[idx];
			var cse:ClothingSortException = ClothingSortException.buildFromArchive(cseArchive);
			
			var lang:String = cse.getLang();
			var realName:String = cse.getRealName();
			
			if (m_ExceptionByLang[lang] == null) {
				m_ExceptionByLang[lang] = new Object();
			}
			m_ExceptionByLang[lang][realName] = cse;
		}
	}
	
	public function serializeAllCSE():Array {
		var serializedDeckArray:Array = new Array();
		
		for (var lang:String in m_ExceptionByLang) {
			var exceptionDict:Object = m_ExceptionByLang[lang];
			for (var realName:String in exceptionDict) {
				var cse:ClothingSortException = exceptionDict[realName];
				var cseArchive:Archive = cse.getArchive();
				serializedDeckArray.push(cseArchive);
			}
		}
		return serializedDeckArray;
	}
}