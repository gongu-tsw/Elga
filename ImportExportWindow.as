import com.Components.Window;

import com.GameInterface.Chat;

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