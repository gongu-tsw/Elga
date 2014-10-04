import com.Components.Window;
import com.Components.SearchBox;

import com.GameInterface.Chat;
import com.GameInterface.DistributedValue;
import com.GameInterface.Game.Character;
import com.GameInterface.Game.CharacterBase;
import com.GameInterface.Inventory;
import com.GameInterface.InventoryItem;
import com.GameInterface.Log;
import com.GameInterface.ShopInterface;
import com.GameInterface.Tooltip.TooltipUtils;
import com.GameInterface.Tooltip.TooltipInterface;


import com.thesecretworld.chronicle.Gongju.Collection.Node;
import GongjuListItemRenderer;

import com.Utils.ID32;
import com.Utils.LDBFormat;
import com.Utils.Signal;

import flash.geom.Point;

import mx.utils.Delegate;

import gfx.controls.Button;
import gfx.controls.CheckBox;
import gfx.controls.ScrollingList;
import gfx.controls.TextArea;

class ElgaWindow extends MovieClip {

	// public instances
	static public var singleton = null;
	public var SignalPositionChanged:Signal;
	public var SignalClosedWindow:Signal;
	
	// Internal instances
	private var m_NeedListUpdate:Boolean = false; // used when the character inventory/wardrobe change to call for reload
	private var m_LanguageCode:String;
	private var m_DefaultTranslation:String;
	
	// map of known colors separator for the current language.
	private var m_Colors:Object;

	// used for sorting a clothing correctly when it's not with the general mechanic (funcom fault?)
	private var m_ColorsException:Object;
	
	private var m_WardrobeInventory:Inventory; // character wardrobe
	private var m_EquippedInventory:Inventory; // character current clothes
	private var m_SortedItems:Object; // used for sorting all clothing by placement
	
	private var m_RootNode:Node; // tree node of clothing = result of grouping/sorting clothing
	private var m_RootNodeFirstIndex:Number;
	private var m_LastSelectedGroup:String;
	private var m_LastSelectedCloth:String;
	
	private var m_PreviewedClothing:Object; // character current preview in addon way
	private var m_EquippedClothing:Object; //character current clothes in addon way, currently useless
	
	private var m_LocationLabels; // Labels for locations (Legs, Rear) with indexes like an enum (0,1,2, 3...)
	private var m_LocationLabels2; // Same as m_LocationLabels, but indexes are 2^0 = 1, 2^1 = 2, 2^2 = 4, 2^3 = 8...)
	private var m_IconIdToPlacementDict; // from a merchant item icon id, gives the placement as m_LocationLabels2 index
	private var m_PlacementIdToPowerTwo:Object; // map to link location index from enum version to 2^enum version, currently useless
	private var m_PlacementOrder:Array;
	private var m_PreviousFilterValue = "";
	
	// UI instances
	private var m_CodeEntryBox:TextArea;
	private var m_Background:MovieClip
	private var m_CloseButton:Button;
	private var m_WearAllPreview:Button;
	private var m_ResetPreview:Button;
	private var m_WearText:Object;
	private var m_PreviewText:Object;
	private var m_ShowVendorText:Object;
	private var m_ShowVendorCheckBox:CheckBox;
	
	private var m_SecondItemList:ScrollingList;
	private var m_ThirdItemList:ScrollingList;
	
	private var m_FilterBox:SearchBox;
	
	// Currently wearing icons
	private var m_ClothingIconHeadgear1:MovieClip;
    private var m_ClothingIconHeadgear2:MovieClip;
    private var m_ClothingIconHats:MovieClip;
    private var m_ClothingIconNeck:MovieClip;
    private var m_ClothingIconChest:MovieClip;
    private var m_ClothingIconBack:MovieClip;
    private var m_ClothingIconHands:MovieClip;
    private var m_ClothingIconLeg:MovieClip;
    private var m_ClothingIconFeet:MovieClip;
    private var m_ClothingIconMultislot:MovieClip;
	
	// Preview icons
	private var m_PreviewIconHeadgear1:MovieClip;
    private var m_PreviewIconHeadgear2:MovieClip;
    private var m_PreviewIconHats:MovieClip;
    private var m_PreviewIconNeck:MovieClip;
    private var m_PreviewIconChest:MovieClip;
    private var m_PreviewIconBack:MovieClip;
    private var m_PreviewIconHands:MovieClip;
    private var m_PreviewIconLeg:MovieClip;
    private var m_PreviewIconFeet:MovieClip;
    private var m_PreviewIconMultislot:MovieClip;
	
	// Select slot icons
	private var m_ShowHeadgear1:MovieClip;
    private var m_ShowHeadgear2:MovieClip;
    private var m_ShowHats:MovieClip;
    private var m_ShowNeck:MovieClip;
    private var m_ShowChest:MovieClip;
    private var m_ShowBack:MovieClip;
    private var m_ShowHands:MovieClip;
    private var m_ShowLeg:MovieClip;
    private var m_ShowFeet:MovieClip;
    private var m_ShowMultislot:MovieClip;
	
	public function ElgaWindow() {
		super();
		
		SignalClosedWindow = new Signal();
		SignalPositionChanged = new Signal();;
		m_Background.onRelease = Delegate.create(this, handleStopDrag);
		m_Background.onReleaseOutside = Delegate.create(this, handleStopDrag);
		m_Background.onPress = Delegate.create(this, handleStartDrag);
		singleton = this;
		m_PreviewedClothing = new Object();
		m_EquippedClothing = new Object();
	}
	
	public function configUI()
    {
        super.configUI();
		
		m_CloseButton.addEventListener("click", this, "CloseWindow");
		
		m_ShowVendorCheckBox.addEventListener("select", this, "OnShowVendorCheckBoxSelect");
		m_ShowVendorCheckBox.addEventListener("focusIn", this, "RemoveFocus");
		
		m_WearAllPreview.addEventListener("click", this, "EquipAllPreviewedClothing");
		m_WearAllPreview.addEventListener("focusIn", this, "RemoveFocus");
		
		m_ResetPreview.addEventListener("click", this, "ResetPreview");
		m_ResetPreview.addEventListener("focusIn", this, "RemoveFocus");
		
		m_SecondItemList.addEventListener("focusIn", this, "RemoveFocus");
        m_SecondItemList.addEventListener("itemClick", this, "OnSecondItemListItemSelected");
		m_SecondItemList.addEventListener("itemDoubleClick", this, "OnItemListDoubleClicked");
		
		m_ThirdItemList.addEventListener("focusIn", this, "RemoveFocus");
        m_ThirdItemList.addEventListener("itemClick", this, "OnThirdItemListItemSelected");
		m_ThirdItemList.addEventListener("itemDoubleClick", this, "OnItemListDoubleClicked");
		
		m_ClothingIconHeadgear1.addEventListener("focusIn", this, "RemoveFocus");
   		m_ClothingIconHeadgear2.addEventListener("focusIn", this, "RemoveFocus");
    	m_ClothingIconHats.addEventListener("focusIn", this, "RemoveFocus");
    	m_ClothingIconNeck.addEventListener("focusIn", this, "RemoveFocus");
    	m_ClothingIconChest.addEventListener("focusIn", this, "RemoveFocus");
    	m_ClothingIconBack.addEventListener("focusIn", this, "RemoveFocus");
    	m_ClothingIconHands.addEventListener("focusIn", this, "RemoveFocus");
		m_ClothingIconLeg.addEventListener("focusIn", this, "RemoveFocus");
    	m_ClothingIconFeet.addEventListener("focusIn", this, "RemoveFocus");
		m_ClothingIconMultislot.addEventListener("focusIn", this, "RemoveFocus");
		
		m_ClothingIconHeadgear1.addEventListener("click", this, "ClothingIconClick");
   		m_ClothingIconHeadgear2.addEventListener("click", this, "ClothingIconClick");
    	m_ClothingIconHats.addEventListener("click", this, "ClothingIconClick");
    	m_ClothingIconNeck.addEventListener("click", this, "ClothingIconClick");
    	m_ClothingIconChest.addEventListener("click", this, "ClothingIconClick");
    	m_ClothingIconBack.addEventListener("click", this, "ClothingIconClick");
    	m_ClothingIconHands.addEventListener("click", this, "ClothingIconClick");
		m_ClothingIconLeg.addEventListener("click", this, "ClothingIconClick");
    	m_ClothingIconFeet.addEventListener("click", this, "ClothingIconClick");
		m_ClothingIconMultislot.addEventListener("click", this, "ClothingIconClick");
		
		m_ClothingIconHeadgear1.m_ClothingPlacement = _global.Enums.ItemEquipLocation.e_Wear_Face;
   		m_ClothingIconHeadgear2.m_ClothingPlacement = _global.Enums.ItemEquipLocation.e_HeadAccessory;
    	m_ClothingIconHats.m_ClothingPlacement = _global.Enums.ItemEquipLocation.e_Wear_Hat;
    	m_ClothingIconNeck.m_ClothingPlacement = _global.Enums.ItemEquipLocation.e_Wear_Neck;
    	m_ClothingIconChest.m_ClothingPlacement = _global.Enums.ItemEquipLocation.e_Wear_Chest;
    	m_ClothingIconBack.m_ClothingPlacement = _global.Enums.ItemEquipLocation.e_Wear_Back;
    	m_ClothingIconHands.m_ClothingPlacement = _global.Enums.ItemEquipLocation.e_Wear_Hands;
		m_ClothingIconLeg.m_ClothingPlacement = _global.Enums.ItemEquipLocation.e_Wear_Legs;
    	m_ClothingIconFeet.m_ClothingPlacement = _global.Enums.ItemEquipLocation.e_Wear_Feet;
		m_ClothingIconMultislot.m_ClothingPlacement = _global.Enums.ItemEquipLocation.e_Wear_FullOutfit;
		
		m_PreviewIconHeadgear1.addEventListener("focusIn", this, "RemoveFocus");
   		m_PreviewIconHeadgear2.addEventListener("focusIn", this, "RemoveFocus");
    	m_PreviewIconHats.addEventListener("focusIn", this, "RemoveFocus");
    	m_PreviewIconNeck.addEventListener("focusIn", this, "RemoveFocus");
    	m_PreviewIconChest.addEventListener("focusIn", this, "RemoveFocus");
    	m_PreviewIconBack.addEventListener("focusIn", this, "RemoveFocus");
    	m_PreviewIconHands.addEventListener("focusIn", this, "RemoveFocus");
		m_PreviewIconLeg.addEventListener("focusIn", this, "RemoveFocus");
    	m_PreviewIconFeet.addEventListener("focusIn", this, "RemoveFocus");
		m_PreviewIconMultislot.addEventListener("focusIn", this, "RemoveFocus");
		
		m_PreviewIconHeadgear1.addEventListener("click", this, "PreviewIconClick");
   		m_PreviewIconHeadgear2.addEventListener("click", this, "PreviewIconClick");
    	m_PreviewIconHats.addEventListener("click", this, "PreviewIconClick");
    	m_PreviewIconNeck.addEventListener("click", this, "PreviewIconClick");
    	m_PreviewIconChest.addEventListener("click", this, "PreviewIconClick");
    	m_PreviewIconBack.addEventListener("click", this, "PreviewIconClick");
    	m_PreviewIconHands.addEventListener("click", this, "PreviewIconClick");
		m_PreviewIconLeg.addEventListener("click", this, "PreviewIconClick");
    	m_PreviewIconFeet.addEventListener("click", this, "PreviewIconClick");
		m_PreviewIconMultislot.addEventListener("click", this, "PreviewIconClick");
		
		m_PreviewIconHeadgear1.m_ClothingPlacement = _global.Enums.ItemEquipLocation.e_Wear_Face;
   		m_PreviewIconHeadgear2.m_ClothingPlacement = _global.Enums.ItemEquipLocation.e_HeadAccessory;
    	m_PreviewIconHats.m_ClothingPlacement = _global.Enums.ItemEquipLocation.e_Wear_Hat;
    	m_PreviewIconNeck.m_ClothingPlacement = _global.Enums.ItemEquipLocation.e_Wear_Neck;
    	m_PreviewIconChest.m_ClothingPlacement = _global.Enums.ItemEquipLocation.e_Wear_Chest;
    	m_PreviewIconBack.m_ClothingPlacement = _global.Enums.ItemEquipLocation.e_Wear_Back;
    	m_PreviewIconHands.m_ClothingPlacement = _global.Enums.ItemEquipLocation.e_Wear_Hands;
		m_PreviewIconLeg.m_ClothingPlacement = _global.Enums.ItemEquipLocation.e_Wear_Legs;
    	m_PreviewIconFeet.m_ClothingPlacement = _global.Enums.ItemEquipLocation.e_Wear_Feet;
		m_PreviewIconMultislot.m_ClothingPlacement = _global.Enums.ItemEquipLocation.e_Wear_FullOutfit;
		
		m_ShowHeadgear1.addEventListener("focusIn", this, "RemoveFocus");
		m_ShowHeadgear2.addEventListener("focusIn", this, "RemoveFocus");
		m_ShowHats.addEventListener("focusIn", this, "RemoveFocus");
		m_ShowNeck.addEventListener("focusIn", this, "RemoveFocus");
		m_ShowChest.addEventListener("focusIn", this, "RemoveFocus");
		m_ShowBack.addEventListener("focusIn", this, "RemoveFocus");
		m_ShowHands.addEventListener("focusIn", this, "RemoveFocus");
		m_ShowLeg.addEventListener("focusIn", this, "RemoveFocus");
		m_ShowFeet.addEventListener("focusIn", this, "RemoveFocus");
		m_ShowMultislot.addEventListener("focusIn", this, "RemoveFocus");
		
		m_ShowHeadgear1.addEventListener("click", this, "OnShowHeadgear1");
		m_ShowHeadgear2.addEventListener("click", this, "OnShowHeadgear2");
		m_ShowHats.addEventListener("click", this, "OnShowHats");
		m_ShowNeck.addEventListener("click", this, "OnShowNeck");
		m_ShowChest.addEventListener("click", this, "OnShowChest");
		m_ShowBack.addEventListener("click", this, "OnShowBack");
		m_ShowHands.addEventListener("click", this, "OnShowHands");
		m_ShowLeg.addEventListener("click", this, "OnShowLeg");
		m_ShowFeet.addEventListener("click", this, "OnShowFeet");
		m_ShowMultislot.addEventListener("click", this, "OnShowMultislot");
		
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
		
		m_FilterBox.SetSearchOnInput(true);
		//m_FilterBox.SetDefaultText(LDBFormat.LDBGetText("GenericGUI", "SearchText"));
		m_FilterBox.addEventListener("search", this, "FilterTextChanged");
		
		InitializePreview();
		
		loadCrap();
	}
	
	private function FilterTextChanged() {
		InitClothingList();
	}
	
	private function loadCrap() {
		
		var clientCharacterID:ID32 = Character.GetClientCharID();
        m_WardrobeInventory = new Inventory( new com.Utils.ID32(_global.Enums.InvType.e_Type_GC_StaticInventory, clientCharacterID.GetInstance()) );
		m_EquippedInventory = new Inventory( new com.Utils.ID32(_global.Enums.InvType.e_Type_GC_WearInventory, clientCharacterID.GetInstance()) );
		
		// not adding listener for shopInterface -> wardrobe is enough to cover for it
		
		m_WardrobeInventory.SignalItemAdded.Connect( ScheduleListUpdate, this );
        m_WardrobeInventory.SignalItemChanged.Connect( ScheduleListUpdate, this );
        m_WardrobeInventory.SignalItemRemoved.Connect( ScheduleListUpdate, this );
        
        m_EquippedInventory.SignalItemAdded.Connect( ScheduleListUpdate, this );
        m_EquippedInventory.SignalItemChanged.Connect( ScheduleListUpdate, this );
        m_EquippedInventory.SignalItemRemoved.Connect( ScheduleListUpdate, this );
		
		_global['setTimeout'](this,'InitializeClothes',250,true); 
		InitClothingList();
	}
	
	
	// Window wide events
	public function onLoad() {
		InitStaticData();
		configUI();
	}
	
	private function onEnterFrame()
    {
        if ( m_NeedListUpdate )
        {
            m_NeedListUpdate = false;
			InitializePreview();
			loadCrap();
        }
    }
    
    private function handleStartDrag() {
		this.startDrag();
	}
	
	private function handleStopDrag(buttonIdx:Number) {
		this.stopDrag();
		SignalPositionChanged.Emit(this._x, this._y);
	}
	
	// Wearing and Preview icons events
	// TODO functions are the same, factorisation needed
	
	// on clicking on a clothing icon, the icon is selected in the lists
	private function ClothingIconClick(event:Object, object:Object) {
		var placement = event.target.m_ClothingPlacement;
		var clothingName = event.target.m_ClothingName;
		SelectClothingByName(clothingName);
	}
	
	private function ShowHideNameCustomizationWindow(event:Object) {
		
	}
	
	private function PreviewIconClick(event:Object, object:Object) {
		var placement = event.target.m_ClothingPlacement;
		var clothingName = event.target.m_ClothingName;
		var clothingSource = event.target.m_ClothingInventoryName;
		
		if (!m_ShowVendorCheckBox.selected && clothingSource != undefined &&
			clothingSource != "_Wardrobe" && clothingSource != "_Equipped") {
			if (m_LanguageCode == "fr") {
				Chat.SignalShowFIFOMessage.Emit("Erreur: inventaire des vendeurs pas affiché", 0);
			}
			else { // english, german
				Chat.SignalShowFIFOMessage.Emit("Error: vendor's inventory not displayed", 0);
			}
			return
		}
		SelectClothingByName(clothingName);
	}
	
	private function SelectClothingByName(clothingName:String) {
		var array = m_RootNode.searchNode("m_Name", clothingName);
		
		SelectNodeForSecondItemList( array[0]);
		if (array[1] != undefined && array[1] != null) {
			m_SecondItemList.selectedIndex = array[1];
			OnSecondItemListItemSelected({index: array[1]});
		}
		if (array[2] != undefined && array[2] != null) {
			m_ThirdItemList.selectedIndex = array[2];
			OnThirdItemListItemSelected({index: array[2]});
		}
	}
	
	private function OnFilterFieldChange(event:Object) {
		var filterValue:String = event.target.m_Text;
		if (filterValue == undefined || filterValue == null)
			filterValue = "";
		if (m_PreviousFilterValue == filterValue)
			return; // not a real change
		
		filterValue = trim(filterValue);
		var splitArray:Array = filterValue.split(" ");
		if (splitArray.length == 0)
			return;
		
		
	}
	
	// Clothing UI List events
	
	private function DarkenEmptyClothingSlot(rootNode:Node){
		var noAlpha:Number = 100;
		var emptyAlpha:Number = 30;
		var placementNodes:Array = rootNode.getChildNodes();
		m_ShowHeadgear1._alpha = (placementNodes[2].isLeaf()) ? emptyAlpha : noAlpha;
		m_ShowHeadgear2._alpha = (placementNodes[1].isLeaf()) ? emptyAlpha : noAlpha;
		m_ShowHats._alpha = (placementNodes[0].isLeaf()) ? emptyAlpha : noAlpha;
		m_ShowNeck._alpha = (placementNodes[3].isLeaf()) ? emptyAlpha : noAlpha;
		m_ShowChest._alpha = (placementNodes[4].isLeaf()) ? emptyAlpha : noAlpha;
		m_ShowBack._alpha = (placementNodes[5].isLeaf()) ? emptyAlpha : noAlpha;
		m_ShowHands._alpha = (placementNodes[6].isLeaf()) ? emptyAlpha : noAlpha;
		m_ShowLeg._alpha = (placementNodes[7].isLeaf()) ? emptyAlpha : noAlpha;
		m_ShowFeet._alpha = (placementNodes[8].isLeaf()) ? emptyAlpha : noAlpha;
		m_ShowMultislot._alpha = (placementNodes[9].isLeaf()) ? emptyAlpha : noAlpha;
	}
	
	private function AlignClothingSlotButton(slot:Number){
		var defaultX:Number = 6;
		var shiftedX:Number = 16;
		
		m_ShowHeadgear1._x = (slot == 2 )?shiftedX:defaultX;
		m_ShowHeadgear2._x = (slot == 1 )?shiftedX:defaultX;
		m_ShowHats._x = (slot == 0 )?shiftedX:defaultX;
		m_ShowNeck._x = (slot == 3 )?shiftedX:defaultX;
		m_ShowChest._x = (slot == 4 )?shiftedX:defaultX;
		m_ShowBack._x = (slot == 5 )?shiftedX:defaultX;
		m_ShowHands._x = (slot == 6 )?shiftedX:defaultX;
		m_ShowLeg._x = (slot == 7 )?shiftedX:defaultX;
		m_ShowFeet._x = (slot == 8 )?shiftedX:defaultX;
		m_ShowMultislot._x = (slot == 9 )?shiftedX:defaultX;
	}
	
	private function OnShowHeadgear1(event:Object, object:Object) {
		SelectNodeForSecondItemList(2);
	}
	
	private function OnShowHeadgear2(event:Object, object:Object) {
		SelectNodeForSecondItemList(1);
	}
	
	private function OnShowHats(event:Object, object:Object) {
		SelectNodeForSecondItemList(0);
	}
	
	private function OnShowNeck(event:Object, object:Object) {
		SelectNodeForSecondItemList(3);
	}
	
	private function OnShowChest(event:Object, object:Object) {
		SelectNodeForSecondItemList(4);
	}
	
	private function OnShowBack(event:Object, object:Object) {
		SelectNodeForSecondItemList(5);
	}
	
	private function OnShowHands(event:Object, object:Object) {
		SelectNodeForSecondItemList(6);
	}
	
	private function OnShowLeg(event:Object, object:Object) {
		SelectNodeForSecondItemList(7);
	}
	
	private function OnShowFeet(event:Object, object:Object) {
		SelectNodeForSecondItemList(8);
	}
	
	private function OnShowMultislot(event:Object, object:Object) {
		SelectNodeForSecondItemList(9);
	}
	
	private function SelectNodeForSecondItemList(index:Number) {
		m_RootNodeFirstIndex = index;
		var secondListParentNode:Node = m_RootNode.getChildAt(index);
		if (secondListParentNode == null)
			return;
		
		AlignClothingSlotButton(index);
		
		m_SecondItemList.selectedIndex = -1;
		m_SecondItemList.dataProvider = [];
		m_ThirdItemList.selectedIndex = -1;
		m_ThirdItemList.dataProvider = [];
		
		if (!secondListParentNode.isLeaf()) {
			var secondListNodeChildrens = secondListParentNode.getChildNodes();
			for (var childIdx:Number = 0; childIdx < secondListNodeChildrens.length; ++childIdx ) {
					var secondListChildNode:Node = secondListNodeChildrens[childIdx];
					var listItem:Object = new Object();
		    		listItem.m_ItemName = secondListChildNode.getNodeName();
					listItem.m_NodeIdx = childIdx;
					listItem.m_IsEquipped = secondListChildNode.getProperty('m_IsEquipped');
					listItem.m_IsContainer = (!secondListChildNode.isLeaf());
					listItem.m_IsBuyable = secondListChildNode.getProperty('m_IsBuyable');
					
					listItem.m_InventoryID = secondListChildNode.getProperty('m_InventoryID');
					listItem.m_Item = secondListChildNode.getProperty('m_Item');
					
					m_SecondItemList.dataProvider.push(listItem);
			}
		}
        m_SecondItemList.invalidateData();
		m_ThirdItemList.invalidateData();
	}
	
	private function OnSecondItemListItemSelected( event:Object )
    {
		// We have to fill the second list according to the first list selection
		var firstNodeIdx = m_RootNodeFirstIndex;
		
		var secondListParentNode:Node = m_RootNode.getChildAt(firstNodeIdx);
		if (secondListParentNode == null)
			return;
		
		var secondNodeIdx = m_SecondItemList.dataProvider[event.index].m_NodeIdx;
		var thirdListParentNode:Node = secondListParentNode.getChildAt(secondNodeIdx);
		if (thirdListParentNode == null)
			return;
		
		m_ThirdItemList.selectedIndex = -1;
		m_ThirdItemList.dataProvider = [];
		
		if (thirdListParentNode.isLeaf()) {
			if (event.type != undefined) {
				var clothingItem = thirdListParentNode.getNodeData();
				m_LastSelectedCloth = clothingItem.m_Name;
				PreviewClothing(clothingItem);
			}
		}
		else {
			var thirdListNodeChildrens = thirdListParentNode.getChildNodes();
			
			for (var childIdx:Number = 0; childIdx < thirdListNodeChildrens.length; ++childIdx ) {
					var thirdListChildNode:Node = thirdListNodeChildrens[childIdx];
					var listItem:Object = new Object();
		    		listItem.m_ItemName = thirdListChildNode.getNodeName();
					listItem.m_NodeIdx = childIdx;
					listItem.m_IsEquipped = thirdListChildNode.getProperty('m_IsEquipped');
					listItem.m_IsBuyable = thirdListChildNode.getProperty('m_IsBuyable');
					m_ThirdItemList.dataProvider.push(listItem);
			}
			
			// to have an automatic preview of the first item in the list when selecting a clothing category
			// imaginary example : selecting "Dotted t-shirt" will select (preview) the dotted t-shirt, blue
			if (thirdListNodeChildrens.length >= 1) {
				m_ThirdItemList.selectedIndex = 0;
				if (event.type != undefined) {
					var thirdListChildNode:Node = thirdListNodeChildrens[0];
					var clothingItem = thirdListChildNode.getNodeData();
					m_LastSelectedCloth = clothingItem.m_Name;
					PreviewClothing(clothingItem);
				}
			}
		}

        m_ThirdItemList.invalidateData();
		
	}
	
	private function OnThirdItemListItemSelected( event:Object )
    {
		var firstNodeIdx =m_RootNodeFirstIndex;
		
		var secondListParentNode:Node = m_RootNode.getChildAt(firstNodeIdx);
		if (secondListParentNode == null)
			return;
		
		var secondListIndex = m_SecondItemList.selectedIndex;
		var secondNodeIdx = m_SecondItemList.dataProvider[secondListIndex].m_NodeIdx;
		var thirdListParentNode:Node = secondListParentNode.getChildAt(secondNodeIdx);
		
		var thirdNodeIdx =  m_ThirdItemList.dataProvider[event.index].m_NodeIdx;
		var thirdListChildNode:Node = thirdListParentNode.getChildAt(thirdNodeIdx);
		var childNodes = thirdListParentNode.getChildNodes();
		if (thirdListChildNode == null) {
			return;
		}
		
		if (event.type != undefined) { // event done by user
			var clothingItem = thirdListChildNode.getNodeData();
			m_LastSelectedCloth = clothingItem.m_Name;
			PreviewClothing(clothingItem);
		}
	}
	
	// Clothing UI List events : Double click
	private function OnItemListDoubleClicked() {    
		var firstNodeIdx = m_RootNodeFirstIndex;
		
		var secondListParentNode:Node = m_RootNode.getChildAt(firstNodeIdx);
		if (secondListParentNode == null)
			return;
		
		var secondListIndex = m_SecondItemList.selectedIndex;
		var secondNodeIdx = m_SecondItemList.dataProvider[secondListIndex].m_NodeIdx;
		var thirdListParentNode:Node = secondListParentNode.getChildAt(secondNodeIdx);
		
		m_LastSelectedGroup =  m_SecondItemList.dataProvider[secondListIndex].m_Name;
		
		var finalNode = thirdListParentNode;
		if (!thirdListParentNode.isLeaf()) {
			var thirdListIndex:Number = m_ThirdItemList.selectedIndex;
			var thirdNodeIdx =  m_ThirdItemList.dataProvider[thirdListIndex].m_NodeIdx;
			var thirdListChildNode:Node = thirdListParentNode.getChildAt(thirdNodeIdx);
			var childNodes = thirdListParentNode.getChildNodes();
			if (thirdListChildNode == null) {
				return;
			}
			finalNode = thirdListChildNode;
		}

		var item = finalNode.getNodeData();
        if ( item.m_IsEquipped )
        {
            if ( CanLocationBeUnequipped( item.m_IndexInInventory ) )
            {
                m_WardrobeInventory.AddItem( item.m_InventoryID, item.m_IndexInInventory, _global.Enums.ItemEquipLocation.e_Wear_DefaultLocation );
            }
        }
        else            
        {
			m_LastSelectedCloth = item.m_Name;// not want to reselect it if removed, stupid code could reapply preview (not checked)
            m_EquippedInventory.AddItem( item.m_InventoryID, item.m_IndexInInventory, _global.Enums.ItemEquipLocation.e_Wear_DefaultLocation );
        }
    }
	
	
	// Preview icons functions
	private function PreviewClothing(clothingItem:Object) {
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
				PreviewClothingSetIcon(clothingItem);
				m_PreviewedClothing[clothingItem.m_Placement] = clothingItem;
			}
		}
		else {
			Chat.SignalShowFIFOMessage.Emit("Erreur sur preview", 0);
		}
	}
	
	private function PreviewClothingSetIcon(clothingItem:Object) {
		var tooltipWidth:Number = 200;
        var tooltipOrientation = TooltipInterface.e_OrientationVertical;
		
		var previewIcon = null;
		if (clothingItem.m_Placement == Math.pow(2,Number(_global.Enums.ItemEquipLocation.e_Wear_Face))) {
            previewIcon = m_PreviewIconHeadgear1;
        }
        if (clothingItem.m_Placement == Math.pow(2,Number(_global.Enums.ItemEquipLocation.e_HeadAccessory)))  {
            previewIcon = m_PreviewIconHeadgear2;
        }
        if (clothingItem.m_Placement == Math.pow(2,Number(_global.Enums.ItemEquipLocation.e_Wear_Hat))) {
            previewIcon = m_PreviewIconHats;
        }
        if (clothingItem.m_Placement == Math.pow(2,Number(_global.Enums.ItemEquipLocation.e_Wear_Neck))) {
           previewIcon = m_PreviewIconNeck;
        }
        if (clothingItem.m_Placement == Math.pow(2,Number(_global.Enums.ItemEquipLocation.e_Wear_Chest))) {
            previewIcon = m_PreviewIconChest;
        }
        if (clothingItem.m_Placement == Math.pow(2,Number(_global.Enums.ItemEquipLocation.e_Wear_Back))) {
           previewIcon = m_PreviewIconBack;
        }
        if (clothingItem.m_Placement == Math.pow(2,Number(_global.Enums.ItemEquipLocation.e_Wear_Hands))) {
            previewIcon = m_PreviewIconHands;
        }
        if (clothingItem.m_Placement == Math.pow(2,Number(_global.Enums.ItemEquipLocation.e_Wear_Legs))) {
            previewIcon = m_PreviewIconLeg;
        }
        if (clothingItem.m_Placement == Math.pow(2,Number(_global.Enums.ItemEquipLocation.e_Wear_Feet))) {
            previewIcon = m_PreviewIconFeet;
        }
        if (clothingItem.m_Placement == Math.pow(2,Number(_global.Enums.ItemEquipLocation.e_Wear_FullOutfit))) {
            previewIcon = m_PreviewIconMultislot;
        }
		
		if (previewIcon != null) {
			previewIcon._alpha = 100;
			var tooltipText:String = clothingItem.m_Name;
			if (clothingItem.m_Price != null) {
				tooltipText = tooltipText + "\n" + clothingItem.m_Price + "\n" + clothingItem.m_InventoryName;
			}
			previewIcon.m_ClothingName = clothingItem.m_Name;
			previewIcon.m_ClothingInventoryName = clothingItem.m_InventoryName;
			TooltipUtils.AddTextTooltip(previewIcon, tooltipText, tooltipWidth, tooltipOrientation, false);
			
		}
	}
	
	// Other UI events
	private function OnShowVendorCheckBoxSelect(event:Object) {
		InitClothingList();
	}
			
	private function InitializePreview() {
		var disabledAlpha:Number = 30;
        m_PreviewIconHeadgear1._alpha =  m_PreviewIconHeadgear2._alpha =   m_PreviewIconHats._alpha = disabledAlpha;
        m_PreviewIconNeck._alpha = m_PreviewIconChest._alpha = m_PreviewIconBack._alpha = disabledAlpha;
        m_PreviewIconHands._alpha =  m_PreviewIconLeg._alpha = m_PreviewIconFeet._alpha = disabledAlpha;
        m_PreviewIconMultislot._alpha = disabledAlpha;
		
		// removing tooltip
		m_PreviewIconHeadgear1.onRollOver = m_PreviewIconHeadgear1.onPress =  function(){return;}
		m_PreviewIconHeadgear2.onRollOver = m_PreviewIconHeadgear2.onPress =  function(){return;}
		m_PreviewIconHats.onRollOver = m_PreviewIconHats.onPress =  function(){return;}
		m_PreviewIconNeck.onRollOver = m_PreviewIconNeck.onPress =  function(){return;}
		m_PreviewIconChest.onRollOver = m_PreviewIconChest.onPress =  function(){return;}
		m_PreviewIconBack.onRollOver = m_PreviewIconBack.onPress =  function(){return;}
		m_PreviewIconHands.onRollOver = m_PreviewIconHands.onPress =  function(){return;}
		m_PreviewIconLeg.onRollOver = m_PreviewIconLeg.onPress =  function(){return;}
		m_PreviewIconFeet.onRollOver = m_PreviewIconFeet.onPress =  function(){return;}
		m_PreviewIconMultislot.onRollOver = m_PreviewIconMultislot.onPress =  function(){return;}
    }
	
	function AddItemToSortedItems(itemName, itemIndexInInventory, inventoryID, inventoryName, itemPlacement, item): Object {
		var invItemContainer = new Object();
		invItemContainer.m_Name = itemName;
		invItemContainer.m_IndexInInventory = itemIndexInInventory;
		invItemContainer.m_InventoryID = inventoryID;
		invItemContainer.m_Item = inventoryID;
		invItemContainer.m_InventoryName = inventoryName;
		invItemContainer.m_Placement = itemPlacement;
		invItemContainer.m_Price = SetItemTextPrice(item);
		if (inventoryName == "_Equipped")
			invItemContainer.m_IsEquipped = true;
		if (inventoryName != "_Equipped" && inventoryName != "_Wardrobe")
			invItemContainer.m_IsBuyable = true;
		
		if (itemPlacement  != null) {
			if (m_SortedItems[itemPlacement] == null) {
				m_SortedItems[itemPlacement] = new Array();
			}
			var placement:Array = m_SortedItems[itemPlacement];
			placement.push(invItemContainer);
		}
		return invItemContainer;
	}
	
	private function GetPlacementForItem(invItem:InventoryItem):Object {
		return m_IconIdToPlacementDict[invItem.m_Icon];
	}
	
	private function MatchFilter(name:String):Boolean {
		var searchText:String = m_FilterBox.GetSearchText().toLowerCase();
		if (searchText.length == 0)
			return true;
		
		name = name.toLowerCase();
		
		var searchSplit:Array = searchText.split(" ");
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
	
	public function InitClothingList() {
		m_SortedItems = new Object();
		var placementDict:Object = new Object();
		var placementArray:Array = new Array();
		
		var searchText:String = m_FilterBox.GetSearchText().toLowerCase();
		
		// put all the wardrobe items in their respective placement
		for ( var i:Number = 0 ; i < m_WardrobeInventory.GetMaxItems() ; ++i ) {
			var invItem:InventoryItem = m_WardrobeInventory.GetItemAt(i);
			if ( invItem && MatchFilter(invItem.m_Name)) {
				AddItemToSortedItems(invItem.m_Name, i, m_WardrobeInventory.m_InventoryID, "_Wardrobe", invItem.m_Placement);
				placementDict[invItem.m_Placement] = 1;
			}
		}
		
		//m_EquippedInventory
		for ( i in m_LocationLabels ) {
			var invItem:InventoryItem = m_EquippedInventory.GetItemAt(i);
			//if (invItem && MatchFilter(invItem.m_Name))  { // filtering on equiped clothing
            if (invItem) { // not filtering on equiped clothing
				var clothingItem = AddItemToSortedItems(invItem.m_Name, i, m_EquippedInventory.m_InventoryID, "_Equipped", invItem.m_Placement);
				placementDict[invItem.m_Placement] = 1;
				m_EquippedClothing[i] = clothingItem;
            }
        }
		
		if (m_ShowVendorCheckBox.selected)
		{
			for (var shopInterfaceKey:String in _global.gongjuShopDict) {
				var shopInterface:ShopInterface = _global.gongjuShopDict[shopInterfaceKey];
				if (shopInterface != null) {
					for (var shopInterfaceItemIdx:Number = 0; shopInterfaceItemIdx < shopInterface.m_Items.length; shopInterfaceItemIdx++) {
						var shopInterfaceItem = shopInterface.m_Items[shopInterfaceItemIdx];
						if (shopInterfaceItem != null && shopInterface.CanPreview(shopInterfaceItem)
							&& RightToPurchaseItem(shopInterfaceItem) && MatchFilter(shopInterfaceItem.m_Name)) {
							AddItemToSortedItems(shopInterfaceItem.m_Name, shopInterfaceItemIdx, shopInterfaceKey, shopInterfaceKey, GetPlacementForItem(shopInterfaceItem), shopInterfaceItem);
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
		for (var placementArrayIdx = 0; placementArrayIdx < placementArray.length; placementArrayIdx++) {
		//for (var placementIt in placementDict) {
			var placementIt = placementArray[placementArrayIdx];
			var placement = m_SortedItems[placementIt];
			var placementNode:Node = organizeClothing(placement, m_LocationLabels2[placementIt]);
			placementNode.sortOnName(); // sort here to avoid sorting the children of root (== placement)
			m_RootNode.addChild(placementNode);
		}
		
		DarkenEmptyClothingSlot(m_RootNode);
		
		m_SecondItemList.dataProvider = [];
		m_SecondItemList.selectedIndex = -1;
		
		m_ThirdItemList.dataProvider = [];
		m_ThirdItemList.selectedIndex = -1;
		
		SelectNodeForSecondItemList(m_RootNodeFirstIndex);
		SelectClothingByName(m_LastSelectedCloth);
	}
	
	private function RightToPurchaseItem(inventoryItem:InventoryItem)
	{
   		return  (inventoryItem.m_CanBuy == undefined || inventoryItem.m_CanBuy);
	}
	
	private function trim(str:String):String
	{
    	for(var i = 0; str.charCodeAt(i) < 33; i++);
    	for(var j = str.length-1; str.charCodeAt(j) < 33; j--);
    	return str.substring(i, j+1);
	}
	
	private function EquipAllPreviewedClothing() {
		var waitValue = 0;
		for (var placement:String in m_PreviewedClothing) {
			var clothingItem = m_PreviewedClothing[placement];
			if ("_Wardrobe" == clothingItem.m_InventoryName) {
				_global['setTimeout'](this,'EquipClothingInWardrobeFromName',waitValue,clothingItem.m_Name, clothingItem.m_Placement); 
				waitValue = waitValue + 250;
			}
		}
	}
	
	public function EquipClothingInWardrobeFromName(itemName, placementID){
		
		if (itemName == undefined || itemName == "null" || itemName == null) {
			UnequipClothing(placementID);
			return undefined;
		}
		for (var idx:Number = 0; idx < m_WardrobeInventory.GetMaxItems(); ++idx) {
			var itemFromWardrobe:InventoryItem = m_WardrobeInventory.GetItemAt(idx);
			if (itemFromWardrobe && itemFromWardrobe.m_Name == itemName) {
				m_EquippedInventory.AddItem( m_WardrobeInventory.m_InventoryID, idx,
					_global.Enums.ItemEquipLocation.e_Wear_DefaultLocation );
				break;
			}
		}
		//start();
	}
	
	private function UnequipClothing(slotID) {
		for (var count:Number = 0; count < m_EquippedInventory.GetMaxItems(); ++count) {
			var itemEquipped = m_EquippedInventory[count];
			if (itemEquipped.m_Placement == slotID) {
				if (CanLocationBeUnequipped( itemEquipped.m_InventoryPos)) {
					m_WardrobeInventory.AddItem(m_EquippedInventory.m_InventoryID(),
						itemEquipped.m_InventoryPos,
						_global.Enums.ItemEquipLocation.e_Wear_DefaultLocation);
					return undefined;
				}
			}
		}
	}

	private function ResetPreview() {
		m_PreviewedClothing = new Object();
		InitializeClothes(true);
		// TODO make something to reset preview on character
	}
	
	private function getNodeNames(clothingName):Array {
			var firstNodeName:String = clothingName; // groupName, if a split was found, otherwise fullName
			var secondNodeName:String = null; // = endName, usually with the color or set name
			if (m_ColorsException[clothingName]) {
				firstNodeName = m_ColorsException[clothingName][0];
				secondNodeName = m_ColorsException[clothingName][1];
			}
			else {
				var charIndex:Number = -1; 
				
				// move the set title at the end of the name
				// ie: Venetian Tactical Armor – Military beret
				// becomes:
				// groupName: Military beret
				// endName: (Venetian Tactical Armor)
				var firstCutIdx:Number = clothingName.indexOf(" - ");
				if (firstCutIdx != -1) {
					charIndex = clothingName.length - ( firstCutIdx + 3);
					clothingName =  clothingName.substring(firstCutIdx + 3) +
						" (" + clothingName.substring(0, firstCutIdx) + ")";
				}
				
				// move the color part of the name in the end name
				for (var colorName:String in m_Colors) {
					var newCharIndex:Number = clothingName.indexOf(colorName);
					if (newCharIndex != -1 && (charIndex == -1 || newCharIndex < charIndex)) {
						charIndex = newCharIndex;
					}
				}
				
				// remove remaining useless chars (triming spaces and removing , at ends)
				if (charIndex != -1) {
					firstNodeName = trim(clothingName.substring(0, charIndex));
					if (firstNodeName.lastIndexOf(",") == firstNodeName.length - 1) {
						firstNodeName = firstNodeName.substring(0, firstNodeName.length - 1);
					}
					secondNodeName = trim(clothingName.substring(charIndex));
				}
			}
			return [firstNodeName,secondNodeName];
	}
	
	private function organizeClothing(placement:Array, placementName:String): Node {
		var rootNode:Node = new Node(placementName);
		if (placement != null) {
			for (var placementIdx:Number = 0; placementIdx < placement.length; placementIdx++) {
				var clothingItem = placement[placementIdx];
				if (!clothingItem)
					continue;
							
				var clothingName:String = clothingItem.m_Name;
				
				var nodeNames = getNodeNames(clothingName);
				var firstNodeName:String = nodeNames[0];
				var secondNodeName:String = nodeNames[1];
				
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
	
	// used to set translations, color separator (language dependent) and some maps
	// not character dependent
	// may broke at each client/server update: using the icon id to set placement for clothing from merchants
	// will need update for new translations and colors too
	private function InitStaticData() {
		m_LanguageCode =  LDBFormat.GetCurrentLanguageCode();
		var predefinedColors:Array = null;
		
		if (m_LanguageCode == "de") {
			m_WearText.text = "Aktuell";
			m_PreviewText.text = "Vorschau";
			m_WearAllPreview.label = "Alle tragen";
			m_ResetPreview.label = "Reset Vorschau";
			m_ShowVendorText.text = "Inventar von Verkäufers zeigen";
			m_DefaultTranslation = "Standard";
			
			predefinedColors = [
			" beige",
			" blau", " tiefblau", "neonblau", " knallblau",
			" braun", " knallbraun",
			" Camouflage",
			" gelb", " neongelb", " knallgelb",
			" gold",
			" grau",
			" grün", " minzgrün", "neongrün", "militärgrün", " knallgrün",
			" lila",
			" magenta", 
			" mehrfarbig",
			" orange", "knallorange", 
			" original",
			" pink", " neonpink",
			" Regenbogen",
			" rot", " knallrot",
			" rosa", " pastellrosa",
			" schokoladen",
			" schwarz",
			" silber", " Silber",
			" türkis",
			" violett",
			" weiß",
			" dunkel", " hell"
			];
			
			// Langer Ledermantel = Langer Ledermantel, violett
			
			m_ColorsException = new Object();
			m_ColorsException["Teen Queen - Abgeschnittene Jeanshose mit Blumengürtel"] = ["Abgeschnittene Jeanshose","mit Blumengürtel (Teen Queen)", null];
			
			//m_ColorsException["Langer Ledermantel"] = ["Langer Ledermantel", "(violett)"];
			m_ColorsException["MMORPG-T-Shirt"] = ["MMORPG-T-Shirt", "weiß"];
			m_ColorsException["ARG-Hoodie, Die schwarzen Wachmänner"] = ["ARG-Hoodie, Die schwarzen Wachmänner", null];
			
			m_ColorsException["Gestreifte Kapuzenjacke, Regenbogen"] = ["Gestreifte Kapuzenjacke (geöffnet)","Regenbogen"];
			m_ColorsException["Gestreifte Kapuzenjacke, braun und orange"] = ["Gestreifte Kapuzenjacke (geöffnet)","braun und orange"];
			m_ColorsException["Gestreifte Kapuzenjacke, grün und gelb"] = ["Gestreifte Kapuzenjacke (geöffnet)","grün und gelb"]
			m_ColorsException["Gestreifte Kapuzenjacke, pink und blau"] = ["Gestreifte Kapuzenjacke (geöffnet)","pink und blau"]
			m_ColorsException["Gestreifte Kapuzenjacke, schwarz und rot"] = ["Gestreifte Kapuzenjacke (geöffnet)","schwarz und rot"]
		}
		if (m_LanguageCode == "fr") {
			m_WearText.text = "Porté";
			m_PreviewText.text = "Aperçu";
			m_WearAllPreview.label = "Tout porter";
			m_ResetPreview.label = "RAZ de l'aperçu";
			m_ShowVendorText.text = "Montrer l'inventaire des vendeurs";
			m_DefaultTranslation = "défaut";
			
			predefinedColors = [
			" arc-en-ciel",
			" argent", " en argent",
			" beige", " beiges",
			" blanche", " blanches", " blanche,", " blanc",
			" bleu", " bleue", " bleus", " bleues",  " bleue,", " bleu-gris", 
			" brun-rouge",
			" camouflage",
			" chocolat",
			" corail",
			" cyan/gris", " cyan",
			" dorées",
			" grise", "gris", "grises", "gris-bleu", "gris-vert", 
			" jaune", "jaunes",
			" kaki",
			" lilas",
			" magenta",
			" marron", " marrons,", " marron,",
			" menthe",
			" multicolore",
			" noir", " noires", " noire", "noire,", " noirs",
			" noire/bleues", " noires/bleues",
			" noire/grises", " noires/grises",
			" noires/marron", " noires/roses", " noires/rouges", " noires/vertes",
			" noire/violettes", " noires/violettes", 
			" or", " en or",
			" orange", " oranges",
			" rose"," roses",
			" rouge", " rouges,", " rouge,", " rouges", " rouge-gris",
			" teinte", 
			" turquoise", 
			" vert", " verte", " verts"," verte,"," vertes,"," vertes",
			" violet", " violets", " violette", " violettes"
			];
			
			m_ColorsException = new Object();
			// Mini-veste -> Mini veste (no dash)
			m_ColorsException["Bande main droite en tissu, marron"] = ["Bande main droite, tissu", "marron"]; 
			m_ColorsException["Femme fatale - Mini-veste en cuir, marron"] = ["Mini veste en cuir", "marron (Femme fatale)"]; 
			m_ColorsException["Pantalon cargo camouflage"] = ["Pantalon cargo", "camouflage"];
			m_ColorsException["Mini-short en denim bleu"] = ["Mini-short", "en denim bleu"];
			m_ColorsException["T-shirt \"Curse\", noir"] = ["T-shirt \"Curse\"", "noir"];
			m_ColorsException["Jonc, rouge"] = ["Joncs", "rouge"];
			//m_ColorsException["Manteau long en cuir"] = ["Manteau long en cuir", "(violet)"];
			
			m_ColorsException["Veste à capuche rayée, arc-en-ciel"] = ["Veste à capuche rayée (ouverte)","arc-en-ciel"];
			m_ColorsException["Veste à capuche rayée, marron et orange"] = ["Veste à capuche rayée (ouverte)","marron et orange"];
			m_ColorsException["Veste à capuche rayée, noir et rouge"] = ["Veste à capuche rayée (ouverte)","noir et rouge"];
			m_ColorsException["Veste à capuche rayée, rose et bleu"] = ["Veste à capuche rayée (ouverte)","rose et bleu"];
			m_ColorsException["Veste à capuche rayée, vert et jaune"] = ["Veste à capuche rayée (ouverte)","vert et jaune"];
		}

		if (m_LanguageCode == "en") {
			m_WearText.text = "Current";
			m_PreviewText.text = "Preview";
			m_WearAllPreview.label = "Wear all";
			m_ResetPreview.label = "Preview reset";
			m_ShowVendorText.text = "Show vendor's inventory";
			m_DefaultTranslation = "default";
			
			predefinedColors = [
			" beige", 
			" black",
			" blue", " dark blue", " light blue", " deep blue", " bright blue", " neon blue",
			" brown", " light brown", " dark brown", " deep brown",
			" camouflage", 
			" chocolate",
			" coral",
			" cyan/grey", " cyan",
			" gold", 
			" green", "dark green", " light green", " bright green", " neon green", " deep green",
			" military green", " light military green", " dark military green",
			" grey", " dark grey", " light grey", " deep grey",
			" khaki",
			" lilac", 
			" magenta",
			" mint", 
			" multicoloured", 
			" orange", " dark orange", " bright orange",
			" original",
			" pink", " light pink", " pastel pink", " neon pink", " dark pink",
			" purple", " dark purple", " light purple", " deep purple",
			" silver",
			" rainbow",
			" red", " light red", " dark red", " deep red", " bright red",
			//" tan",  // tan is a poor choise of color because tank top exists...
			" turquoise", 
			" yellow", " light yellow", " bright yellow", " neon yellow", " dark yellow",
			" white", " off-white"
			];
			
			m_ColorsException = new Object();
			m_ColorsException["MMORPG T-shirt"] = ["MMORPG t-shirt", "white"];
			m_ColorsException["Snakeskin Outfit, tan"] = ["Snakeskin Outfit", "tan"];
			m_ColorsException["High waist trousers, striped"] = ["High waist trousers", "striped"];
			m_ColorsException["Striped hoodie jacket, black and red"] = ["Striped hoodie jacket (unzipped)","black and red"];
			m_ColorsException["Striped hoodie jacket, brown and orange"] = ["Striped hoodie jacket (unzipped)","brown and orange"];
			m_ColorsException["Striped hoodie jacket, green and yellow"] = ["Striped hoodie jacket (unzipped)","green and yellow"];
			m_ColorsException["Striped hoodie jacket, pink and blue"] = ["Striped hoodie jacket (unzipped)","pink and blue"];
			m_ColorsException["Striped hoodie jacket, rainbow"] = ["Striped hoodie jacket (unzipped)","rainbow"];
			
			m_ColorsException["Dark Symmetry - Demon's head shorts with stockings, black"] = ["Demon's head shorts","stockings, black (Dark Symmetry)"];
			m_ColorsException["Rogue Mechanics - Handygirl shorts with stockings, black"] = ["Handygirl shorts","with stockings, black (Rogue Mechanics)"];
			
			m_ColorsException["Pumpkinhead, Bloody"] = ["Pumpkinhead","Bloody"];
			m_ColorsException["Head-O-Lantern"] = ["Pumpkinhead","Head-O-Lantern"];
			
			m_ColorsException["Loose \"Believe\" T-Shirt, yellow"] = ["Loose T-Shirt","\"Believe\", yellow"];
			m_ColorsException["Loose Bingo! T-Shirt"] = ["Loose T-Shirt","Bingo!"];
			m_ColorsException["Loose Mr Freezie T-Shirt"] = ["Loose T-Shirt","Mr Freezie"];
		}
		
		var uniqueColor = new Object();
		
		for (var colorIdx:Number = 0; colorIdx < predefinedColors.length; ++colorIdx) {
			var aColor:String = predefinedColors[colorIdx];
			if (uniqueColor[aColor]) {
				Chat.SignalShowFIFOMessage.Emit("Couleur en trop: " + aColor, 0);
			}
			else
			{
				uniqueColor[aColor] = true;
			}
			
		}
		m_Colors = uniqueColor;
		
		m_IconIdToPlacementDict = new Object();
		m_IconIdToPlacementDict["1000624:7457527"] = 1; // supposition TODO: check
		m_IconIdToPlacementDict["1000624:7457528"] = 2048;
		m_IconIdToPlacementDict["1000624:7457529"] = 2; // supposition TODO: check
		m_IconIdToPlacementDict["1000624:7457530"] = 1024;
		m_IconIdToPlacementDict["1000624:7457531"] = 16;
		m_IconIdToPlacementDict["1000624:7457532"] = 32;
		m_IconIdToPlacementDict["1000624:7457533"] = 128;
		m_IconIdToPlacementDict["1000624:7457534"] = 4;
		
		/*
		1		??????????????? multi-emplacement
		2		??????????????? couvre-chef
		2048	1000624:7457528 chaussures
				1000624:7457529 ?
		1024	1000624:7457530 pantalon
		16		1000624:7457531 dos
		32		1000624:7457532 torse
		128		1000624:7457533 mains
		4		1000624:7457534 visage
		pas utilisé pour le moment
		8						cou
		512						ceinture
		131072					Anneau 2
		65536					Anneau 1
		262144					Collier
		
		*/
		
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
        m_LocationLabels[_global.Enums.ItemEquipLocation.e_HeadAccessory]        = undefined;
		
        for ( var i in m_LocationLabels )
        {
            m_LocationLabels[i] = LDBFormat.LDBGetText("WearLocations", Number(i));
        }
		
		for ( var i in m_LocationLabels )
        {
			m_PlacementIdToPowerTwo[i] = Math.pow(2,Number(i));
			m_LocationLabels2[Math.pow(2,Number(i))] = m_LocationLabels[i];
        }
	}
	
	private function InitializeClothes(setPreview:Boolean)
    {
		var m_InspectionInventory:Inventory = m_EquippedInventory;
		
		m_ClothingIconHeadgear1.onRollOver = m_ClothingIconHeadgear1.onPress =  function(){return;}
		m_ClothingIconHeadgear2.onRollOver = m_ClothingIconHeadgear2.onPress =  function(){return;}
		m_ClothingIconHats.onRollOver = m_ClothingIconHats.onPress =  function(){return;}
		m_ClothingIconNeck.onRollOver = m_ClothingIconNeck.onPress =  function(){return;}
		m_ClothingIconChest.onRollOver = m_ClothingIconChest.onPress =  function(){return;}
		m_ClothingIconBack.onRollOver = m_ClothingIconBack.onPress =  function(){return;}
		m_ClothingIconHands.onRollOver = m_ClothingIconHands.onPress =  function(){return;}
		m_ClothingIconLeg.onRollOver = m_ClothingIconLeg.onPress =  function(){return;}
		m_ClothingIconFeet.onRollOver = m_ClothingIconFeet.onPress =  function(){return;}
		m_ClothingIconMultislot.onRollOver = m_ClothingIconMultislot.onPress =  function(){return;}
		
		m_ClothingIconHeadgear1._alpha = m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Face) != null ? 100 : 30;
        m_ClothingIconHeadgear2._alpha = m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_HeadAccessory) != null ? 100 : 30;
        m_ClothingIconHats._alpha = m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Hat) != null ? 100 : 30;
        m_ClothingIconNeck._alpha = m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Neck) != null ? 100 : 30;
        m_ClothingIconChest._alpha = m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Chest) != null ? 100 : 30;
        m_ClothingIconBack._alpha = m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Back) != null ? 100 : 30;
        m_ClothingIconHands._alpha = m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Hands) != null ? 100 : 30;
        m_ClothingIconLeg._alpha = m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Legs) != null ? 100 : 30;
        m_ClothingIconFeet._alpha = m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Feet) != null ? 100 : 30;
        m_ClothingIconMultislot._alpha = m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_FullOutfit) != null ? 100 : 30;
		
		if (setPreview === true) {
			m_PreviewIconHeadgear1._alpha = m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Face) != null ? 100 : 30;
       		m_PreviewIconHeadgear2._alpha = m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_HeadAccessory) != null ? 100 : 30;
        	m_PreviewIconHats._alpha = m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Hat) != null ? 100 : 30;
        	m_PreviewIconNeck._alpha = m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Neck) != null ? 100 : 30;
        	m_PreviewIconChest._alpha = m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Chest) != null ? 100 : 30;
        	m_PreviewIconBack._alpha = m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Back) != null ? 100 : 30;
        	m_PreviewIconHands._alpha = m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Hands) != null ? 100 : 30;
        	m_PreviewIconLeg._alpha = m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Legs) != null ? 100 : 30;
        	m_PreviewIconFeet._alpha = m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Feet) != null ? 100 : 30;
        	m_PreviewIconMultislot._alpha = m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_FullOutfit) != null ? 100 : 30;
			
			m_PreviewIconHeadgear1.m_ClothingName = m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Face).m_Name;
        	m_PreviewIconHeadgear2.m_ClothingName = m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_HeadAccessory).m_Name;
        	m_PreviewIconHats.m_ClothingName = m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Hat).m_Name;
        	m_PreviewIconNeck.m_ClothingName = m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Neck).m_Name;
       		m_PreviewIconChest.m_ClothingName = m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Chest).m_Name;
        	m_PreviewIconBack.m_ClothingName = m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Back).m_Name;
        	m_PreviewIconHands.m_ClothingName = m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Hands).m_Name;
        	m_PreviewIconLeg.m_ClothingName = m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Legs).m_Name;
        	m_PreviewIconFeet.m_ClothingName = m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Feet).m_Name;
        	m_PreviewIconMultislot.m_ClothingName = m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_FullOutfit).m_Name;
		}
		
		m_ClothingIconHeadgear1.m_ClothingName = m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Face).m_Name;
        m_ClothingIconHeadgear2.m_ClothingName = m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_HeadAccessory).m_Name;
        m_ClothingIconHats.m_ClothingName = m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Hat).m_Name;
        m_ClothingIconNeck.m_ClothingName = m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Neck).m_Name;
        m_ClothingIconChest.m_ClothingName = m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Chest).m_Name;
        m_ClothingIconBack.m_ClothingName = m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Back).m_Name;
        m_ClothingIconHands.m_ClothingName = m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Hands).m_Name;
        m_ClothingIconLeg.m_ClothingName = m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Legs).m_Name;
        m_ClothingIconFeet.m_ClothingName = m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Feet).m_Name;
        m_ClothingIconMultislot.m_ClothingName = m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_FullOutfit).m_Name;
		
		
        
        var tooltipWidth:Number = 200;
        var tooltipOrientation = TooltipInterface.e_OrientationVertical;
        if (m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Face) != null) {
            TooltipUtils.AddTextTooltip(m_ClothingIconHeadgear1, m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Face).m_Name , tooltipWidth, tooltipOrientation, false);
        }
        if (m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_HeadAccessory) != null) {
            TooltipUtils.AddTextTooltip(m_ClothingIconHeadgear2, m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_HeadAccessory).m_Name , tooltipWidth, tooltipOrientation, false);
        }
        if (m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Hat) != null) {
            TooltipUtils.AddTextTooltip(m_ClothingIconHats, m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Hat).m_Name , tooltipWidth, tooltipOrientation, false);
        }
        if (m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Neck) != null) {
            TooltipUtils.AddTextTooltip(m_ClothingIconNeck, m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Neck).m_Name , tooltipWidth, tooltipOrientation, false);
        }
        if (m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Chest) != null) {
            TooltipUtils.AddTextTooltip(m_ClothingIconChest, m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Chest).m_Name , tooltipWidth, tooltipOrientation, false);
        }
        if (m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Back) != null) {
            TooltipUtils.AddTextTooltip(m_ClothingIconBack, m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Back).m_Name , tooltipWidth, tooltipOrientation, false);
        }
        if (m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Hands) != null) {
            TooltipUtils.AddTextTooltip(m_ClothingIconHands, m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Hands).m_Name , tooltipWidth, tooltipOrientation, false);
        }
        if (m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Legs) != null) {
            TooltipUtils.AddTextTooltip(m_ClothingIconLeg, m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Legs).m_Name , tooltipWidth, tooltipOrientation, false);
        }
        if (m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Feet) != null) {
            TooltipUtils.AddTextTooltip(m_ClothingIconFeet, m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Feet).m_Name , tooltipWidth, tooltipOrientation, false);
        }
        if (m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_FullOutfit) != null) {
            TooltipUtils.AddTextTooltip(m_ClothingIconMultislot, m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_FullOutfit).m_Name , tooltipWidth, tooltipOrientation, false);
        }
		
		if (setPreview === true) {
			if (m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Face) != null) {
				TooltipUtils.AddTextTooltip(m_PreviewIconHeadgear1, m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Face).m_Name , tooltipWidth, tooltipOrientation, false);
			}
			if (m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_HeadAccessory) != null) {
				TooltipUtils.AddTextTooltip(m_PreviewIconHeadgear2, m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_HeadAccessory).m_Name , tooltipWidth, tooltipOrientation, false);
			}
			if (m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Hat) != null) {
				TooltipUtils.AddTextTooltip(m_PreviewIconHats, m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Hat).m_Name , tooltipWidth, tooltipOrientation, false);
			}
			if (m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Neck) != null) {
				TooltipUtils.AddTextTooltip(m_PreviewIconNeck, m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Neck).m_Name , tooltipWidth, tooltipOrientation, false);
			}
			if (m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Chest) != null) {
				TooltipUtils.AddTextTooltip(m_PreviewIconChest, m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Chest).m_Name , tooltipWidth, tooltipOrientation, false);
			}
			if (m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Back) != null) {
				TooltipUtils.AddTextTooltip(m_PreviewIconBack, m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Back).m_Name , tooltipWidth, tooltipOrientation, false);
			}
			if (m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Hands) != null) {
				TooltipUtils.AddTextTooltip(m_PreviewIconHands, m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Hands).m_Name , tooltipWidth, tooltipOrientation, false);
			}
			if (m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Legs) != null) {
				TooltipUtils.AddTextTooltip(m_PreviewIconLeg, m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Legs).m_Name , tooltipWidth, tooltipOrientation, false);
			}
			if (m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Feet) != null) {
				TooltipUtils.AddTextTooltip(m_PreviewIconFeet, m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_Feet).m_Name , tooltipWidth, tooltipOrientation, false);
			}
			if (m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_FullOutfit) != null) {
				TooltipUtils.AddTextTooltip(m_PreviewIconMultislot, m_InspectionInventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Wear_FullOutfit).m_Name , tooltipWidth, tooltipOrientation, false);
			}
		}
    }

	public function CloseWindow(eventObj:Object) {
		this.removeMovieClip();
		DistributedValue.SetDValue("Elga_OptionWindowOpen", false);
	}
	
	// For name customization
	
	private function OpenNameCustomizationWindow(){
		
	}
	
	
	//Misc
	private function RemoveFocus()
    {
        Selection.setFocus(null);
    }
    
    private function ScheduleListUpdate()
    {
        m_NeedListUpdate = true;
    }
    
    private function CanLocationBeUnequipped( location:Number ) : Boolean
    {
        return location != _global.Enums.ItemEquipLocation.e_Wear_Chest && location != _global.Enums.ItemEquipLocation.e_Wear_Legs;
    }
    
    function SetItemTextPrice(item:InventoryItem):String {
		if (item.m_TokenCurrencyPrice1 > 0 && item.m_TokenCurrencyType1 == _global.Enums.Token.e_Cash) {
			return item.m_TokenCurrencyPrice1 + " PAX";
		}
		if (item.m_TokenCurrencyPrice2 > 0 && item.m_TokenCurrencyType2 == _global.Enums.Token.e_Cash) {
			return  item.m_TokenCurrencyPrice2 + " PAX";
		}
		return null;
	}
	
	public static function getInstance() {
		return singleton;
	}
	
	public function getTextArea():TextArea {
		return this.m_CodeEntryBox;
	}
}