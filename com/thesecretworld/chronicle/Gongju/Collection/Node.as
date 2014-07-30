import com.GameInterface.Chat;

class com.thesecretworld.chronicle.Gongju.Collection.Node {
  
  	private var children:Array;
  	private var nodeData:Object;
  	private var nodeName:String;
  	private var parent:Node;
  	
  	public function Node(nodeName:String) {
  		this.nodeData = null;
  		this.nodeName = nodeName;
  		this.children = new Array();
  	}
  
    public function addChild(childNode:Node)
    {
    	if (!children) {
    		this.children = new Array();
    	}
    	// TODO check for cycling ref
    	if (childNode.getParent())
    		return; // TODO send exception: we do not add node with parent, or the node get two parents...
    	
    	this.children.push(childNode);
    	childNode.setParent(this);
    }
    
    public function getChildNodes():Array {
    	return this.children;
    }
	
	public function getChildAt(index:Number):Node {
		if (0 <= index && index < this.children.length)
			return this.children[index]
    	return null;
    }
    
    public function isLeaf():Boolean {
    	return !(this.children && this.children.length > 0);
    }
    
    public function isRoot():Boolean {
    	return !(this.parent);
    }
    
    public function getParent():Node {
    	return this.parent;
    }
    
    public function getRoot():Node {
    	if (this.parent)
    		return this.parent.getRoot();
    	else
    		return this;
    }
    
    public function hasNodeNamed(nodeName:String):Boolean {
    	return (this.getChildNamed(nodeName) != null);
    }
    
    public function getChildNamed(nodeName:String):Node {
    	for (var childIdx:Number = 0; childIdx < this.children.length; ++childIdx) {
    		var childNode:Node = this.children[childIdx];
    		if (childNode && childNode.getNodeName() == nodeName) {
    			return childNode;
    		}
    	}
    	return null;
    }
    
    public function getChild(index:Number):Node {
    	if (!children)
    		return;
    	if (index >= children.length)
    		return;
    	return children[index];
    }
    
    public function getProperty(propertyName:String): Object {
    	if (!nodeData)
    		return;
    	return nodeData[propertyName];
    }
    
    public function setNodeData(dataObject:Object) {
    	this.nodeData = dataObject;
    }
	
	public function getNodeData():Object {
    	return this.nodeData;
    }
    
    public function setNodeName(nodeName:String) {
    	return this.nodeName = nodeName;
    }
	
	public function hasNodeData():Boolean {
		return (getNodeData() != null);
	}
    
    public function getNodeName(): String {
    	return nodeName;
    }
    
    public function setProperty(propertyName:String, propertyValue:Object) {
    	if (!nodeData)
    		nodeData = new Object();
    	nodeData[propertyName] = propertyValue;
    }
    
    private function setParent(parentNode:Node) {
    	this.parent = parentNode;
    }
    
    public function compressTree() {
    	while (this.children.length == 1)
    	{
    		var childNode:Node = this.children[0];
    		var childName = childNode.getNodeName();
    		
    		this.nodeName = this.nodeName + " " + childName;
    		this.children = childNode.getChildNodes();
    	}
    	if (this.children.length > 1) {
    		for (var childIdx:Number = 0; childIdx < this.children.length; ++childIdx) {
    			this.children[childIdx].setParent(this);
    			this.children[childIdx].compressTree();
    		}
    	}
    }
	
	public function compressTreeTo2Level(depth:Number) {
		if (depth == null)
			depth = 0;
    	while (this.children.length == 1) {
    		var childNode:Node = this.children[0];
    		var childName = childNode.getNodeName();
    		
    		this.nodeName = this.nodeName + " " + childName;
    		this.children = childNode.getChildNodes();
    	}
    	if (this.children.length > 1)
    	{
    		for (var childIdx:Number = 0; childIdx < this.children.length; ++childIdx) {
    			this.children[childIdx].setParent(this);
    			this.children[childIdx].compressTree(depth + 1);
    		}
    	}
    }
	
	public function searchNode(propertyName:String, propertyValue:Object) {
		var localValue = this.getProperty(propertyName);
		if (localValue == propertyValue) {
			return [localValue];
		}
		else if (this.children.length > 0) {
			for (var childIdx:Number = 0; childIdx < this.children.length; ++childIdx) {
				var returnValue = this.children[childIdx].searchNode(propertyName, propertyValue);
				if (returnValue) {
					returnValue.unshift(childIdx);
					return returnValue;
				}
			}
		}
	}
	
	public function sortOnName() {
		this.children.sortOn("nodeName");
		for (var idx:Number = 0; idx < this.children.length; idx++) {
			children[idx].sortOnName();
		}
	}
    
    public function toString(depth:Number):String {
    	if (depth == null)
    		depth = 0;
    	var stringOffset = "";
    	for (var offsetIdx:Number = 0; offsetIdx < depth; ++offsetIdx) {
    		stringOffset = stringOffset + "\t";
    	}
    	var stringText:String = stringOffset + this.nodeName + "(" + this.children.length + ")";
    	if (this.children.length > 0) {
    		stringText = stringText + " : [\n";
    		for (var childIdx:Number = 0; childIdx < this.children.length; ++childIdx) {
    			var childNode:Node = this.children[childIdx];
    			if (childNode) {
    				var childText:String = childNode.toString(depth + 1);
    				stringText = stringText + childText;
    			}
    		}
    		stringText = stringText + stringOffset + "]";
    	}
		return stringText + "\n";
    }

}
