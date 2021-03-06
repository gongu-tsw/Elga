﻿import com.GameInterface.Chat;
import com.GameInterface.Game.Character;
import com.GameInterface.Game.CharacterBase;

import com.Utils.Archive;

class com.thesecretworld.chronicle.Gongju.Data.ClothingSortException {

	private var m_RealName:String;
	private var m_Lang:String;
	private var m_RealPlacement:String;
	private var m_CustomPlacement:String;
	private var m_CustomCategory:String;
	private var m_CustomName:String;
    
    static public var m_AllPlacement:Object = [
		_global.Enums.ItemEquipLocation.e_Wear_Face,
		_global.Enums.ItemEquipLocation.e_HeadAccessory,
		_global.Enums.ItemEquipLocation.e_Wear_Hat,
		_global.Enums.ItemEquipLocation.e_Wear_Neck,
		_global.Enums.ItemEquipLocation.e_Wear_Chest,
		_global.Enums.ItemEquipLocation.e_Wear_Back,
		_global.Enums.ItemEquipLocation.e_Wear_Hands,
		_global.Enums.ItemEquipLocation.e_Wear_Legs,
		_global.Enums.ItemEquipLocation.e_Wear_Feet,
		_global.Enums.ItemEquipLocation.e_Wear_FullOutfit
	];
	
	public function ClothingSortException (realName:String, lang:String, realPlacement:String,
				customPlacement:String, customCategory:String, customName:String) {
		m_RealName = realName;
		m_Lang = lang;
		m_RealPlacement = realPlacement;
		m_CustomPlacement = customPlacement;
		m_CustomCategory = customCategory;
		m_CustomName = customName;
	}
	
	public static function buildFromArchive(archive:Archive) {
		var realName:String = archive.FindEntry("n", undefined);
		var lang:String = archive.FindEntry("l", undefined);
		var realPlacement:String = archive.FindEntry("rp", undefined);
    	var customPlacement:String = archive.FindEntry("cp", undefined);
    	var customCategory:String = archive.FindEntry("cc", undefined);
    	var customName:String = archive.FindEntry("cn", undefined);
		
		return new ClothingSortException(realName, lang, realPlacement,
			customPlacement, customCategory, customName);
	}
	
	public function getRealName():String { return m_RealName;}
	public function getLang():String {return m_Lang};
	public function getRealPlacement():String {return m_RealPlacement};
	public function getCustomPlacement():String {return m_CustomPlacement};
	public function getCustomCategory():String {return m_CustomCategory};
	public function getCustomName():String {return m_CustomName};
	
	public function getArchive():Archive {
		var archive:Archive = new Archive();
		
		var realName:String = getRealName();
		var lang:String = getLang();
		var realPlacement:String = getRealPlacement();
		var customPlacement:String = getCustomPlacement();
		var customCategory:String = getCustomCategory();
		var customName:String = getCustomName();
			
		archive.AddEntry("n", realName);
		archive.AddEntry("l", lang);
		archive.AddEntry("rp", realPlacement);
		archive.AddEntry("cp", customPlacement);
		archive.AddEntry("cc", customCategory);
		archive.AddEntry("cn", customName);
		
		return archive;
	}
	
	public function toString():String {
		return getRealName() +'|' + getCustomCategory() + '|' + getCustomName();
	}
	
	public function update(customPlacement:String,
			customCategory:String, customName:String):Boolean {
		var changed:Boolean = false;
		if (m_CustomPlacement != customPlacement) {
			m_CustomPlacement = customPlacement;
			changed = true;
		}
		if (m_CustomCategory != customCategory) {
			m_CustomCategory = customCategory;
			changed = true;
		}
		if (m_CustomName != customName) {
			m_CustomName = customName;
			changed = true;
		}
		return changed;
	}
}