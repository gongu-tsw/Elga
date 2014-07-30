import gfx.controls.ListItemRenderer;
import com.GameInterface.Chat;
import com.GameInterface.Tooltip.*;
import com.GameInterface.InventoryItem;
import com.Utils.ID32;
import gfx.controls.TextArea;
import mx.utils.Delegate;

class GongjuListItemRenderer extends gfx.controls.ListItemRenderer
{
    private var m_ItemLabel:TextField;
	private var m_IsEquippedMark:MovieClip;
	private var m_IsContainerMark:MovieClip;
	private var m_IsBuyableMark:MovieClip;
	
	private var m_InventoryItem:InventoryItem;
	private var m_InventoryID:ID32;
	
	private var m_IsConfigured:Boolean;
	
	private var m_Tooltip:TooltipInterface;
    
	public function DressingRoomListItemRenderer()
    {
		super();
        m_IsConfigured = false;
    }
	
	 private function configUI()
	{
		super.configUI();
        m_IsConfigured = true;
		m_IsEquippedMark._visible = false;
		m_IsContainerMark._visible = false;
		m_IsBuyableMark._visible = false;
		
		//this.addEventListener("onRollOver", this, "SlotIconRollOver");
		//this.addEventListener("onRollOut", this, "SlotIconRollOut");
		//this.addEventListener("onDragOut", this, "SlotIconRollOut");
		
		//m_IsBuyableMark.onRollOver = Delegate.create(this, SlotIconRollOver);
        //m_IsBuyableMark.onRollOut = m_IsBuyableMark.onDragOut = Delegate.create(this, SlotIconRollOut);
		
        UpdateVisuals();
	}
	
	private function SlotIconRollOver()
    {
        if (m_Tooltip == undefined)
        {
            OpenTooltip();
        }
    }
	
	private function SlotIconRollOut()
    {
        if (m_Tooltip != undefined)
        {
            CloseTooltip();
        }
    }
	
	public function OpenTooltip() : Void
    {
		var textArea:TextArea = ElgaWindow.getInstance().getTextArea();
		//Chat.SignalShowFIFOMessage.Emit("makeTooltip", 0);
		textArea.text = " = " + m_InventoryItem.m_Name;
		
        if (m_Tooltip == undefined)
        {
            var tooltipData:TooltipData = TooltipDataProvider.GetInventoryItemTooltip(m_InventoryID, m_InventoryItem.m_InventoryPos);

            m_Tooltip = TooltipManager.GetInstance().ShowTooltip( this, TooltipInterface.e_OrientationHorizontal, -1, tooltipData);
        }
    }
    
    public function CloseTooltip() : Void
    {
        if ( m_Tooltip != undefined && !m_Tooltip.IsFloating() )
        {
            m_Tooltip.Close();
        }
        m_Tooltip = undefined;
    }
	
    public function setData( data:Object ) : Void
    {
		super.setData(data);
		
		m_InventoryItem = data.m_Item;
        m_InventoryID = data.m_InventoryID;
		
		//Chat.SignalShowFIFOMessage.Emit("DressingRoomListItemRenderer setData", 0);
        if ( m_IsConfigured )
        {
            UpdateVisuals();
        }
    }
	
	private function UpdateVisuals()
    {
		//Chat.SignalShowFIFOMessage.Emit("DressingRoomListItemRenderer UpdateVisuals", 0);
		if (data != undefined)
        {
			//Chat.SignalShowFIFOMessage.Emit("DressingRoomListItemRenderer UpdateVisuals data defined", 0);
			//for (var propertyName in data) {
			//	Chat.SignalShowFIFOMessage.Emit("DRLIR data:" + propertyName + " = "  + data[propertyName] , 0);
			//}
            if ( data.m_IsEquipped ) {
				//Chat.SignalShowFIFOMessage.Emit("DressingRoomListItemRenderer UpdateVisuals data equipped", 0);
				m_IsEquippedMark._visible = true;
				m_IsContainerMark._visible = false;
				m_IsBuyableMark._visible = false;
            }
            else {
				if (data.m_IsContainer) {
					m_IsContainerMark._visible = true;
				}
				else {
					if (data.m_IsBuyable) {
						m_IsBuyableMark._visible = true;
					}
					else {
						m_IsBuyableMark._visible = false;
					}
					m_IsContainerMark._visible = false;
				}
				m_IsEquippedMark._visible = false;
            }
            this._visible = true;
			
			if (data.m_ItemTextColor) {
				m_ItemLabel.color = data.m_ItemTextColor
			}
			else {
				m_ItemLabel.color = 0xFF00FF;
			}
			m_ItemLabel.text = data.m_ItemName;
        }
        else
        {
			//Chat.SignalShowFIFOMessage.Emit("DressingRoomListItemRenderer UpdateVisuals data undefined", 0);
            this._visible = false;
		}
	}
}