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
import ElgaCore;

import com.Utils.ID32;
import com.Utils.LDBFormat;
import com.Utils.Signal;

import flash.geom.Point;

import mx.utils.Delegate;

import gfx.controls.Button;
import gfx.controls.CheckBox;
import gfx.controls.ScrollingList;
import gfx.controls.TextInput

class NameCustomizationWindow extends MovieClip {
	
	private var m_FullNameText:Object;
	private var m_DefaultCategoryText:Object;
	private var m_DefaultShortNameText:Object;
	private var m_CustomCategoryText:Object;
	private var m_CustomShortNameText:Object;
	
	private var m_FullNameValue:Object;
	private var m_DefaultCategoryValue:Object;
	private var m_DefaultShortNameValue:Object;
	private var m_CustomCategoryValue:Object;
	private var m_CustomShortNameValue:Object;
	
	private var m_SaveButton:Button;
	private var m_CancelButton:Button;
	private var m_ResetButton:Button;
	
	public var SignalPositionChanged:Signal;
	
	private var m_ElgaCore:ElgaCore;
	private var m_CurrentClothNode:Node;
	private var m_CurrentCategoryNode:Node;
	
	public function NameCustomizatinWindow() {
		super();
		
		SignalPositionChanged = new Signal();
	}
	
	public function configUI()
    {
        super.configUI();
		m_FullNameValue.selectable = true;
		m_DefaultCategoryValue.selectable = true;
		m_DefaultShortNameValue.selectable = true;
		
		m_SaveButton.addEventListener("click", this, "OnClickSaveButton");
		m_SaveButton.addEventListener("focusIn", this, "RemoveFocus");
		
		m_CancelButton.addEventListener("click", this, "OnClickCancelButton");
		m_CancelButton.addEventListener("focusIn", this, "RemoveFocus");
		
		m_ResetButton.addEventListener("click", this, "OnClickResetButton");
		m_ResetButton.addEventListener("focusIn", this, "RemoveFocus");
		
		m_SaveButton.label = LDBFormat.LDBGetText("GenericGUI", "Save");
		m_CancelButton.label = LDBFormat.LDBGetText("GenericGUI", "Cancel");
		
		var languageCode:String = LDBFormat.GetCurrentLanguageCode();
		if (languageCode == "en") {
			// takes values from ui
		}
		
		if (languageCode == "fr") {
			m_FullNameText.text = "Nom complet";
			m_DefaultCategoryText.text = "Catégorie d'origine";
			m_DefaultShortNameText.text = "Nom d'origine";
			m_CustomCategoryText.text = "Catégorie";
			m_CustomShortNameText.text = "Nom";
		}
		
		if (languageCode == "de") {
			// TODO : have real german translation instead of default english from ui
		}
	}
	
	public function RevertFullNameValue(event:Object) {
		Chat.SignalShowFIFOMessage.Emit("RevertFullNameValue", 0);
		if (m_CurrentClothNode != null) {
			m_FullNameValue = m_CurrentClothNode.getNodeData().m_Name;
		}
	}
	
	// Window wide events
	public function onLoad() {
		configUI();
	}
	
	public function OnClickSaveButton():Void {
		if (m_CurrentClothNode != null) {
			var clothingItem = m_CurrentClothNode.getNodeData();
			var customCategory = m_CustomCategoryValue.text;
			var customShortName = m_CustomShortNameValue.text;
			// TODO ? trim names ? what if empty ?
			
			m_ElgaCore.changeClothingException(customCategory, customShortName, clothingItem);
		} else if (m_CurrentCategoryNode != null) {
			var cagetoryItem = m_CurrentCategoryNode.getNodeData();
			var customCategory = m_CustomCategoryValue.text;
			// TODO ? trim names ? what if empty ?
			
			m_ElgaCore.changeCategoryException(customCategory, cagetoryItem);
		}
		return;
	}
	
	public function OnClickCancelButton():Void {
		if (m_CurrentClothNode != null) {
			var clothingItem:Object = m_CurrentClothNode.getNodeData();
			var depth:Number = 1;
			if (clothingItem.m_IsNameCustom) {
				if (clothingItem.m_CustomCategory != null && clothingItem.m_CustomCategory != "") {
					depth = 2;
				}
			} else {
				if (clothingItem.m_DefaultCategory != null && clothingItem.m_DefaultCategory != "") {
					depth = 2;
				}
			}
			setCurrentCloth(m_CurrentClothNode, depth);
		}
		return;
	}
	
	// put back the default value in the fields (currently does not save)
	public function OnClickResetButton():Void {
		if (m_CurrentClothNode != null) {
			var clothingItem:Object = m_CurrentClothNode.getNodeData();
			m_FullNameValue.text = clothingItem.m_Name;
			m_DefaultShortNameValue.text = clothingItem.m_DefaultShortName;
			m_DefaultCategoryValue.text =  definedOrEmpty(clothingItem.m_DefaultCategory);
			//if (m_CustomCategoryValue.text != "" || m_CustomShortNameValue.text != "")
			// change -> activate save button	
			m_CustomCategoryValue.text = "";
			m_CustomShortNameValue.text = "";
		} else if (m_CurrentCategoryNode != null) {
			var categoryItem:Object = m_CurrentCategoryNode.getNodeData();
			m_FullNameValue.text = "";
			m_DefaultCategoryValue.text = definedOrEmpty(clothingItem.m_DefaultCategory);
			m_DefaultShortNameValue.text = "";
			m_CustomCategoryValue.text = "";
			m_CustomShortNameValue.text = "";
		}
		return;
	}
	
	public function setCurrentCloth(clothingNode:Node, depth:Number):Void {
		m_CurrentCategoryNode = null;
		m_CurrentClothNode = clothingNode;
		var clothingItem = clothingNode.getNodeData();
		
		var categoryNode = null;
		var currentCategoryName:String = "";
		
		var fullName:String = clothingItem.m_Name;
		var currentShortName:String = clothingNode.getNodeName();
		
		if (depth == 2) {
			categoryNode = clothingNode.getParent();
			currentCategoryName = categoryNode.getNodeName();
		}
		
		m_FullNameValue.text = fullName;
		m_DefaultShortNameValue.text = definedOrEmpty(clothingItem.m_DefaultShortName);
		m_DefaultCategoryValue.text =  definedOrEmpty(clothingItem.m_DefaultCategory);
		
		m_CustomShortNameValue.text = definedOrEmpty(clothingItem.m_CustomShortName);
		m_CustomCategoryValue.text = definedOrEmpty(clothingItem.m_CustomCategory);
		
		//disable save button	

	}
	
	private function definedOrEmpty(name:String):String {
		return (name == null ? "" : name);
	}
	
	public function setCurrentCategory(categoryNode:Node):Void {
		m_CurrentClothNode = null;
		m_CurrentCategoryNode = categoryNode;
		var currentCategoryName:String = categoryNode.getNodeName();
		var categoryData = categoryNode.getNodeData();
		
		m_FullNameValue.text = "";
		m_DefaultShortNameValue.text = "";
		m_DefaultCategoryValue.text = definedOrEmpty(categoryData.m_DefaultCategory);
		m_CustomShortNameValue.text = "";
		m_CustomCategoryValue.text = definedOrEmpty(categoryData.m_CustomCategory);
	}
	
	private function onEnterFrame()
    {
    }
    
    private function handleStartDrag() {
		this.startDrag();
	}
	
	private function handleStopDrag(buttonIdx:Number) {
		this.stopDrag();
		SignalPositionChanged.Emit(this._x, this._y);
	}
	
	//Misc
	private function RemoveFocus()
    {
        Selection.setFocus(null);
    }
}