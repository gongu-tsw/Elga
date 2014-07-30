import com.GameInterface.Chat;
import com.GameInterface.Game.Character;
import com.GameInterface.Game.CharacterBase;

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
		var m_CustomPlacement = customPlacement;
		var m_CustomCategory = customCategory;
		var m_CustomName = customName;
	}
	
	public function getRealName():String { return realName;}
	public function getLang():String {return lang};
	public function getRealPlacement():String {return realPlacement};
	public function getCustomPlacement():String {return customPlacement};
	public function getCustomCategory():String {return customCategory};
	public function getCustomName():String {return customName};
	
	public function update(lang:String, realPlacement:String,
				customPlacement:String, customCategory:String, customName:String) {
		m_Lang = lang;
		m_RealPlacement = realPlacement;
		var m_CustomPlacement = customPlacement;
		var m_CustomCategory = customCategory;
		var m_CustomName = customName;
	}
}