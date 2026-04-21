Class {
	#name : 'MCPToolGetClasses',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'executing' }
MCPToolGetClasses >> executeWithArguments: arguments [

	^ { (MCPStructureTextContent text: (([
		     (arguments at: #packageName) asPackage classes
			     collect: [ :class |
			     (arguments at: #packageName) , '/' , class name ]
			     as: Array ]
			     on: Error
			     do: [ {  } asArray ]) joinUsing: ', ')) }
]

{ #category : 'initialization' }
MCPToolGetClasses >> initialize [

	super initialize.
	name := 'get-package-class'.
	title := 'List the classes of a package'.
	description := 'Get the list of classes inside a package'.
	inputSchema := MCPStructureInputSchema new
		               type: 'object';
		               properties: { (MCPStructureProperties new
				                name: 'packageName';
				                type: 'string';
				                description:
					                'The name of the package we will look class into') };
		               yourself.
	icons := {  }
]
