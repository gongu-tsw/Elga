import gfx.controls.ListItemRenderer;
import com.GameInterface.Chat;

class com.thesecretworld.chronicle.Gongju.Renderer.DressingRoomListItemRenderer extends gfx.controls.ListItemRenderer
{
    private var m_ItemLabel:TextField;
	private var m_IsEquippedMark:MovieClip;
	
	  private var m_IsConfigured:Boolean;
    
	public function DressingRoomListItemRenderer()
    {
		super();
		//Chat.SignalShowFIFOMessage.Emit("DressingRoomListItemRenderer", 0);
        m_IsConfigured = true;
    }
	
	 private function configUI()
	{
		super.configUI();
		//Chat.SignalShowFIFOMessage.Emit("configUI", 0);
        m_IsConfigured = true;
		m_IsEquippedMark._visible = false;
		
        UpdateVisuals();
	}
	
    public function setData( data:Object ) : Void
    {
		super.setData(data);
		//Chat.SignalShowFIFOMessage.Emit("setData", 0);
        if ( m_IsConfigured )
        {
            UpdateVisuals();
        }
    }
	
	private function UpdateVisuals()
    {
		//Chat.SignalShowFIFOMessage.Emit("UpdateVisuals", 0);
		if (data != undefined)
        {
            if ( data.m_IsEquipped )
            {
				m_IsEquippedMark._visible = true;
            }
            else
            {
				m_IsEquippedMark._visible = false;
            }
            this._visible = true;
			
			m_ItemLabel.text = data.m_ItemName;
        }
        else
        {
            this._visible = false;
		}
	}
}