import com.Components.Window;
import com.GameInterface.Chat;
import com.Utils.LDBFormat;

import ElgaCore;



class ImportExportWindow extends MovieClip {
	
	var m_CodeEntryBox:MovieClip;
	var m_ListWearedClothingButton:MovieClip;
	var m_ListAllClothingButton:MovieClip;
	var m_ImportButton:MovieClip;
	var m_ExportButton:MovieClip;
	
	var m_ElgaCore:ElgaCore;
	
	public function configUI()
    {
        super.configUI();
		
		m_ListWearedClothingButton.addEventListener("click", this, "listAllWearedClothes");
		m_ListWearedClothingButton.addEventListener("focusIn", this, "RemoveFocus");
		
		m_ListAllClothingButton.addEventListener("click", this, "listAllOwnedClothes");
		m_ListAllClothingButton.addEventListener("focusIn", this, "RemoveFocus");
		
		m_ImportButton.addEventListener("click", this, "importData");
		m_ImportButton.addEventListener("focusIn", this, "RemoveFocus");
		
		m_ExportButton.addEventListener("click", this, "exportData");
		m_ExportButton.addEventListener("focusIn", this, "RemoveFocus");
		
		var languageCode:String = LDBFormat.GetCurrentLanguageCode();
		if (languageCode == "fr") {
			m_ExportButton.label = "Exporter";
			m_ImportButton.label = "Importer";
			m_ListAllClothingButton.label = "Liste des vêtements"
			m_ListWearedClothingButton.label = "Vêtements portés"
		}
		if (languageCode == "en") {
			m_ExportButton.label = "Export";
			m_ImportButton.label = "Import";
			m_ListAllClothingButton.label = "Clothes list"
			m_ListWearedClothingButton.label = "Weared clothes"
		}
		if (languageCode == "de") {
			m_ExportButton.label = "Exportieren";
			m_ImportButton.label = "Importieren";
			m_ListAllClothingButton.label = "Kleidung Liste"
			m_ListWearedClothingButton.label = "Getragene Kleidung"
		}
		
	}
	
	// Window wide events
	public function onLoad() {
		configUI();
	}
	
	public function listAllWearedClothes(event:Object):Void {
		m_CodeEntryBox.text = m_ElgaCore.listAllWearedClothes();
	}
	
	public function listAllOwnedClothes(event:Object):Void {
		m_CodeEntryBox.text = m_ElgaCore.listAllOwnedClothes();
	}
	
	public function importData(event:Object):Void {
		m_ElgaCore.importClothingSortException(m_CodeEntryBox.text);
	}
	
	public function exportData(event:Object):Void {
		m_CodeEntryBox.text = m_ElgaCore.exportClothingSortException();
	}
	
	private function onEnterFrame()
    {
    }
    
    private function handleStartDrag() {
		this.startDrag();
	}
	
	private function handleStopDrag(buttonIdx:Number) {
		this.stopDrag();
		//SignalPositionChanged.Emit(this._x, this._y);
	}
	
	//Misc
	private function RemoveFocus()
    {
        Selection.setFocus(null);
    }
}