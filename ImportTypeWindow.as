import com.Components.Window;
import com.GameInterface.Chat;
import com.Utils.LDBFormat;

class ImportTypeWindow extends MovieClip {
	
	var m_Title:Object;
	var m_ResetText:Object;
	var m_MergeText:Object;
	var m_NiceText:Object;
	var m_CancelText:Object;
	
	var m_ResetTypeButton:MovieClip;
	var m_MergeTypeButton:MovieClip;
	var m_NiceImportButton:MovieClip;
	var m_CancelButton:MovieClip;
	
	var m_ImportExportWindow:MovieClip;
	
	public function configUI()
    {
        super.configUI();
		
		m_ResetTypeButton.addEventListener("click", this, "resetTypeImport");
		m_ResetTypeButton.addEventListener("focusIn", this, "RemoveFocus");
		
		m_MergeTypeButton.addEventListener("click", this, "mergeTypeImport");
		m_MergeTypeButton.addEventListener("focusIn", this, "RemoveFocus");
		
		m_NiceImportButton.addEventListener("click", this, "niceTypeImport");
		m_NiceImportButton.addEventListener("focusIn", this, "RemoveFocus");
		
		m_CancelButton.addEventListener("click", this, "cancelImport");
		m_CancelButton.addEventListener("focusIn", this, "RemoveFocus");
		
		var languageCode:String = LDBFormat.GetCurrentLanguageCode();
		if (languageCode == "fr") {
			m_Title.text = "Choisissez le type d'import:";
			m_ResetText.text = "Reset: Les personnalisations précédentes sont effacées.";
			m_MergeText.text = "Ecraser: En cas de conflit de personnalisation, la nouvelle version est gardée.";
			m_NiceText.text = "Passer: En cas de conflit de personnalisation, l'ancienne version est gardée.";
			m_CancelText.text = "Annuler l'import, tout simplement";
			
			m_ResetTypeButton.label = "Reset";
			m_MergeTypeButton.label = "Ecraser";
			m_NiceImportButton.label = "Passer";
			m_CancelButton.label = "Annuler";
		}
		if (languageCode == "en") {
			m_Title.text = "Choose the type of import :";
			m_ResetText.text = "Reset : All your previous clothes customizations will be lost";
			m_MergeText.text = "Merge : A previous customization for a cloth is replaced if a new one is imported.";
			m_NiceText.text = "Nice : A new customization for a cloth will not replace an existing one";
			m_CancelText.text = "Cancel : Well, maybe next time.";
			
			m_ResetTypeButton.label = "Reset import";
			m_MergeTypeButton.label = "Override import";
			m_NiceImportButton.label = "Nice import";
			m_CancelButton.label = "Cancel import";
		}
		if (languageCode == "de") {
			m_Title.text = "Import type wählen:";
			m_ResetText.text = "Reset : All your previous clothes customizations will be lost";
			m_MergeText.text = "Merge : A previous customization for a cloth is replaced if a new one is imported.";
			m_NiceText.text = "Nice : A new customization for a cloth will not replace an existing one";
			m_CancelText.text = "Abbrechen : Well, maybe next time.";
			
			m_ResetTypeButton.label = "Reset";
			m_MergeTypeButton.label = "Override";
			m_NiceImportButton.label = "Nice";
			m_CancelButton.label = "Abbrechen";
		}
	}
	
	public function resetTypeImport(event:Object):Void {
		m_ImportExportWindow.resetImport();
	}
	
	public function mergeTypeImport(event:Object):Void {
		m_ImportExportWindow.mergeImport();
	}
		
	public function niceTypeImport(event:Object):Void {
		m_ImportExportWindow.niceImport();
	}
	
	public function cancelImport(event:Object):Void {
		m_ImportExportWindow.cancelImport();
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