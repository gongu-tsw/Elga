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
import gfx.controls.TextArea;

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
	}
	
	// Window wide events
	public function onLoad() {
		configUI();
	}
	
	public function OnClickSaveButton():Void {
		if (m_CurrentClothNode != null) {
			var clothingItem = m_CurrentClothNode.getNodeData();
			var fullName:String = clothingItem.m_Name;
			var customCategory = m_CustomShortNameValue.text;
			var customShortName = m_CustomShortNameValue.text;
			// TODO ? trim names ? what if empty ?
			
			var changed:Boolean = m_ElgaCore.changeClothingException(customCategory, customShortName, clothingItem);
		}
		return;
	}
	
	public function OnClickCancelButton():Void {
		if (m_CurrentClothNode != null) {
			var clothingItem:Object = m_CurrentClothNode.getNodeData();
			
			//setCurrentCloth(clothingNode)
		}
		return;
	}
	
	public function OnClickResetButton():Void {
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
		m_DefaultShortNameValue.text = clothingItem.m_DefaultShortName;
		m_DefaultCategoryValue.text =  clothingItem.m_DefaultCategory;
		m_CustomShortNameValue.text = clothingItem.m_CustomShortName;
		m_CustomCategoryValue.text = clothingItem.m_CustomCategory;
	}
	
	public function setCurrentCategory(categoryNode:Node):Void {
		m_CurrentClothNode = null;
		m_CurrentCategoryNode = categoryNode;
		var currentCategoryName:String = categoryNode.getNodeName();
		
		m_FullNameValue.text = "";
		m_DefaultShortNameValue.text = "";
		m_DefaultCategoryValue.text = currentCategoryName;
		m_CustomShortNameValue.text = "";
		m_CustomCategoryValue.text = currentCategoryName;
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