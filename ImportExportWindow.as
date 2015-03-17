import com.Components.Window;

import com.GameInterface.Chat;

import ElgaCore;



class ImportExportWindow extends MovieClip {
	
	var m_CodeEntryBox:MovieClip;
	var m_ButtonA:MovieClip;
	var m_ButtonB:MovieClip;
	var m_ButtonC:MovieClip;
	
	var m_ElgaCore:ElgaCore;
	
	public function configUI()
    {
        super.configUI();
		
		m_ButtonA.addEventListener("click", this, "listAllWearedClothes");
		m_ButtonA.addEventListener("focusIn", this, "RemoveFocus");
		
		m_ButtonB.addEventListener("click", this, "listAllOwnedClothes");
		m_ButtonB.addEventListener("focusIn", this, "RemoveFocus");
		
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