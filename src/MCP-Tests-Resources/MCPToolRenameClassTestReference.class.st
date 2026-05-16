Class {
	#name : 'MCPToolRenameClassTestReference',
	#superclass : 'Object',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'instance creation' }
MCPToolRenameClassTestReference >> newReferencedInstance [

	^ MCPToolRenameClassTestOriginal new
]

{ #category : 'accessing' }
MCPToolRenameClassTestReference >> referencedClass [

	^ MCPToolRenameClassTestOriginal
]
