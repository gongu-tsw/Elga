import com.Components.Window;

import com.GameInterface.Chat;
import com.GameInterface.DistributedValue;
import com.GameInterface.Game.Character;
import com.GameInterface.Game.CharacterBase;
import com.GameInterface.InventoryItem;
import com.GameInterface.Log;
import com.GameInterface.ShopInterface;
import com.GameInterface.Tooltip.Tooltip;
import com.GameInterface.Tooltip.TooltipData;
import com.GameInterface.Tooltip.TooltipManager;

import com.Utils.Archive;
import com.Utils.LDBFormat;

import flash.geom.Point;
import gfx.controls.Button;
import mx.utils.Delegate;

import ElgaWindow;
import ElgaCore;

var m_WindowPosition:Point;
var m_ButtonPosition:Point;
var m_ElgaWindow:MovieClip;
var m_ElgaButton:MovieClip;
var m_OpenIcon:MovieClip;
var m_Icon:MovieClip;
var m_Tooltip;
_global.gongjuShopDict = new Object();

// for Integration in 'Topbar Information Overload' by Viper
var m_VTIOIsLoadedMonitor:DistributedValue;
var VTIOAddonInfo:String = "Elgå|Gongju|0.5|Elga_OptionWindowOpen|_root.elga_elga.m_Icon"; 
var m_OptionWindowState:DistributedValue;

function SlotCheckVTIOIsLoaded() {
	if (DistributedValue.GetDValue("VTIO_IsLoaded")) {
		DistributedValue.SetDValue("VTIO_RegisterAddon", VTIOAddonInfo);
	}
}

function SlotOptionWindowState() {
	var isOpen:Boolean = DistributedValue.GetDValue("Elga_OptionWindowOpen");
	SetOpenMainWindow(isOpen);
}

//Init
function onLoad() {
	ShopInterface.SignalOpenShop.Connect(ElgaSlotOpenShop, this);
	
	//next 5 lines for Topbar Information Overload
	m_VTIOIsLoadedMonitor = DistributedValue.Create("VTIO_IsLoaded");
	m_VTIOIsLoadedMonitor.SignalChanged.Connect(SlotCheckVTIOIsLoaded, this);
	m_OptionWindowState = DistributedValue.Create("Elga_OptionWindowOpen");
	m_OptionWindowState.SignalChanged.Connect(SlotOptionWindowState, this);
	DistributedValue.SetDValue("Elga_OptionWindowOpen", false);
	
	InitIcon();
	
	SlotCheckVTIOIsLoaded();
}

// Module (de)activation
function OnModuleActivated(config:Archive) {
	m_WindowPosition = config.FindEntry("WindowPosition");
	if (m_WindowPosition == undefined) {
		m_WindowPosition = new Point();
		m_WindowPosition.x = 500;
		m_WindowPosition.y = 500;
	}
	m_ButtonPosition = config.FindEntry("ButtonPosition");
	if (m_ButtonPosition == undefined) {
		m_ButtonPosition = new Point();
		m_ButtonPosition.x = 8;
		m_ButtonPosition.y = 150;
	}
	
	if (DistributedValue.GetDValue("VTIO_IsLoaded") != true) {
		m_Icon._x = m_ButtonPosition.x;
		m_Icon._y = m_ButtonPosition.y;
	}
}

function InitIcon() {
	m_Tooltip = undefined
	m_Icon = attachMovie("Icon", "m_Icon", getNextHighestDepth());
	m_Icon._width = 18;
	m_Icon._height = 18;
	m_Icon.onMousePress = function(buttonID) {
		if (m_Tooltip != undefined)	m_Tooltip.Close();
		if (buttonID == 1) {
			// Do left mouse button stuff.
			SetOpenMainWindow((m_ElgaWindow == undefined || !m_ElgaWindow._visible));
		} else if (buttonID == 2) {
			if (DistributedValue.GetDValue("VTIO_IsLoaded") != true) {
				m_ButtonPosition.x = m_Icon._x;
				m_ButtonPosition.y = m_Icon._y;
				startDrag(m_Icon,0);
			}
		}
	}
	// Can be used instead of onMousePress for just left click ability.
	/*m_Icon.onPress = function() {
		Chat.SignalShowFIFOMessage.Emit("m_Icon.onPress", 0);
		if (m_Tooltip != undefined)	m_Tooltip.Close();

	}*/
	
	m_Icon.onMouseRelease = function(eventObj:Object) {
		if (m_Tooltip != undefined) m_Tooltip.Close();
		if (DistributedValue.GetDValue("VTIO_IsLoaded") != true) {
			m_ButtonPosition.x = m_Icon._x;
			m_ButtonPosition.y = m_Icon._y;
		}
		stopDrag();
	}
	
	var openCloseText:String = "Open/Close Elgå";
	var languageCode:String =  LDBFormat.GetCurrentLanguageCode();
	if (languageCode == "fr") {
		openCloseText = "Ouvrir/Fermer Elgå";
	}
	if (languageCode == "de") {
		openCloseText = "Elgå öffnen/schließen";
	}
	
	m_Icon.onRollOver = function() {
		if (m_Tooltip != undefined) m_Tooltip.Close();
        var tooltipData:TooltipData = new TooltipData();
		tooltipData.AddAttribute("", "<font face='_StandardFont' size='13' color='#FF8000'><b>Elgå</b></font>");
        tooltipData.AddAttributeSplitter();
        tooltipData.AddAttribute("", "");
        tooltipData.AddAttribute("", "<font face='_StandardFont' size='12' color='#FFFFFF'>" + openCloseText + "</font>");
        tooltipData.m_Padding = 4;
        tooltipData.m_MaxWidth = 210;
		m_Tooltip = TooltipManager.GetInstance().ShowTooltip(undefined, TooltipInterface.e_OrientationVertical, 0, tooltipData);
	}
	m_Icon.onRollOut = function() {
		if (m_Tooltip != undefined)	m_Tooltip.Close();
	}
}

function OnModuleDeactivated() {
	var archive:Archive = new Archive();
	archive.AddEntry("ButtonPosition", m_ButtonPosition);
	if (DistributedValue.GetDValue("VTIO_IsLoaded") != true) {
		archive.AddEntry("WindowPosition", m_WindowPosition);
	}
	
	if (m_ElgaWindow != undefined && m_ElgaWindow != null) {
		m_ElgaWindow.removeMovieClip();
	}
	
	// CSE means ClothingSortException
	var allCSEArchives:Array = m_ElgaCore.serializeAllCSE()
	for (var idx:Number = 0; idx < allCSEArchives.length; ++idx) {
		archive.AddEntry("CSE", allCSEArchives[idx]); 
	}
	
	m_ElgaCore = undefined;
	
	return archive;
}

function ElgaSlotOpenShop(shopInterface:ShopInterface) {
	if (shopInterface.m_Items.length == 0)
		return;
	
	var m_Character = Character.GetClientCharacter();
	var targetId = m_Character.GetDefensiveTarget();
	var targetChar = Character.GetCharacter(targetId)
	var shopInterfaceErsatzID = targetChar.GetName();
	
	var somethingToPreview:Boolean = false;
	for (var i:Number = 0; i < shopInterface.m_Items.length; i++) {
		var item = shopInterface.m_Items[i];
		if (item != undefined) {
			
			var preview:Boolean = (shopInterface.CanPreview(item) && RightToPurchaseItem(item));
			if (preview)  {
				somethingToPreview = true;
			}
		}
	}
	
	if (!somethingToPreview)
		return;
	
	_global.gongjuShopDict[shopInterfaceErsatzID] = shopInterface;
}

// Events
function onElgaWindowUnload() {
	m_ElgaWindow = undefined;
}

function SetOpenMainWindow(open:Boolean) {
	if (open) {
		if (m_ElgaCore == undefined) {
			m_ElgaCore = new ElgaCore();
			
			var cseArray:Array = config.FindEntryArray("CSE");
			if (cseArray == undefined) {
				cseArray = [];
			}
				
			m_ElgaCore.loadAllCSEFromArchiveArray(cseArray);
		}
		
		if (m_ElgaWindow == undefined)  {
			m_ElgaWindow = attachMovie("ElgaWindow", "window", getNextHighestDepth(), {
				m_ElgaCore:m_ElgaCore
			});
			m_ElgaWindow._x = m_WindowPosition.x;
			m_ElgaWindow._y = m_WindowPosition.y;
			m_ElgaWindow.SignalPositionChanged.Connect(onPositionChanged, this);
			m_ElgaWindow.onUnload = Delegate.create(this, onElgaWindowUnload);
		}
		else {
			m_ElgaWindow._visible = true;
		}
		DistributedValue.SetDValue("Elga_OptionWindowOpen", true);
	}
	else {
		if (m_ElgaWindow != undefined)  {
			m_ElgaWindow.removeMovieClip();
			//m_ElgaWindow._visible = false; // TODO maybe destroy the window rather than hiding it
		}
		DistributedValue.SetDValue("Elga_OptionWindowOpen", false);
	}
}

function onPositionChanged(incX:Number, incY:Number) {
	m_WindowPosition.x = incX;
	m_WindowPosition.y = incY;
}

// Misc Functions

function ResetFocus() {
	Selection.setFocus(null);
}

function RightToPurchaseItem(inventoryItem:InventoryItem)
{
   return  (inventoryItem.m_CanBuy == undefined || inventoryItem.m_CanBuy);
}