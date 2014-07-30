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
    	return (this.getChildNamed(nodeName));
    }
    
    public function getChildNamed(nodeName:String):Boolean {
    	for (var childIdx:Number = 0; childIdx < this.children.length; ++childIdx) {
    		var childNode:Node = this.children[childIdx];
    		if (childNode && childNode.getNodeName() == nodeName) {
    			return childNode;
    		}
    	}
    	return;
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
    
    public function setNodeName(nodeName:String) {
    	return this.nodeName = nodeName;
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
    	if (this.children.length > 1)
    	{
    		for (var childIdx:Number = 0; childIdx < this.children.length; ++childIdx) {
    			this.children[childIdx].setParent(this);
    			this.children[childIdx].compressTree();
    		}
    	}
    }
    
    public function toString(var depth:Number) {
    	if (depth == null)
    		depth = 0;
    	var stringOffset = "";
    	for (var offsetIdx:Number = 0; offsetIdx < depth; ++offsetIdx) {
    		stringOffset = stringOffset + "\t";
    	}
    	var stringText:String = stringOffset + this.nodeName;
    	if (this.children.length > 0) {
    		stringText = stringText + " : [\n";
    		for (var childIdx:Number = 0; childIdx < this.children.length; ++childIdx) {
    			var childNode:Node = this.children[childIdx];
    			if (childNode) {
    				var childText:String = childNode.toString(depth + 1);
    				stringText = stringText + childText;
    			}
    		}
    		stringText = stringText + stringOffset + "]\n";
    	}
    }
}
