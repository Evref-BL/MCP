Class {
	#name : 'MCPToolGetPackages',
	#superclass : 'MCPTool',
	#category : 'MCP',
	#package : 'MCP'
}

{ #category : 'executing' }
MCPToolGetPackages >> executeWithArguments: params [

	^ { (MCPStructureTextContent text:
		   ((self packageOrganizer packages collect: #name) joinUsing: ', ')) }
]

{ #category : 'initialization' }
MCPToolGetPackages >> initialize [

	super initialize.
	name := 'get-packages'.
	title := 'Get the list of packages'.
	description := 'Get the list of packages of the Pharo Image'.
	inputSchema := MCPStructureInputSchema new
		               type: 'object';
		               yourself.
	icons := {  }
]
