import com.GameInterface.Chat;
import com.GameInterface.Game.Character;
import com.GameInterface.Game.CharacterBase;

import com.Utils.Archive;

class com.thesecretworld.chronicle.Gongju.Data.CategorySortException {

	private var m_DefaultCategory:String;
	private var m_Lang:String;
	private var m_RealPlacement:String;
	private var m_CustomPlacement:String;
	private var m_CustomCategory:String;
    
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
	
	public function CategorySortException (defaultCategory:String, lang:String, realPlacement:String,
				customPlacement:String, customCategory:String) {
		m_DefaultCategory = defaultCategory;
		m_Lang = lang;
		m_RealPlacement = realPlacement;
		m_CustomPlacement = customPlacement;
		m_CustomCategory = customCategory;
	}
	
	public static function buildFromArchive(archive:Archive) : CategorySortException {
		var defaultCategory:String = archive.FindEntry("dc", undefined);
		var lang:String = archive.FindEntry("l", undefined);
		var realPlacement:String = archive.FindEntry("rp", undefined);
    	var customPlacement:String = archive.FindEntry("cp", undefined);
    	var customCategory:String = archive.FindEntry("cc", undefined);
		
		return new CategorySortException(defaultCategory, lang, realPlacement,
			customPlacement, customCategory);
	}
	
	public function getDefaultCategory():String { return m_DefaultCategory;}
	public function getLang():String {return m_Lang};
	public function getRealPlacement():String {return m_RealPlacement};
	public function getCustomPlacement():String {return m_CustomPlacement};
	public function getCustomCategory():String {return m_CustomCategory};
	
	public function getArchive():Archive {
		var archive:Archive = new Archive();
		
		var defaultCategory:String = getDefaultCategory();
		var lang:String = getLang();
		var realPlacement:String = getRealPlacement();
		var customPlacement:String = getCustomPlacement();
		var customCategory:String = getCustomCategory();
			
		archive.AddEntry("dc", defaultCategory);
		archive.AddEntry("l", lang);
		archive.AddEntry("rp", realPlacement);
		archive.AddEntry("cp", customPlacement);
		archive.AddEntry("cc", customCategory);
		
		return archive;
	}
	
	public function toString():String {
		return getDefaultCategory() +'|' + getCustomCategory();
	}
	
	public function update(customPlacement:String, customCategory:String):Boolean {
		var changed:Boolean = false;
		if (m_CustomPlacement != customPlacement) {
			m_CustomPlacement = customPlacement;
			changed = true;
		}
		if (m_CustomCategory != customCategory) {
			m_CustomCategory = customCategory;
			changed = true;
		}
		return changed;
	}
}