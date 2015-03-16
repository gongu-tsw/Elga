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
	}
	
	// Window wide events
	public function onLoad() {
		configUI();
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