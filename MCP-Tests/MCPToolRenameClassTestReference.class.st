Class {
	#name : 'MCPToolRenameClassTestReference',
	#superclass : 'Object',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'instance creation' }
MCPToolRenameClassTestReference >> newReferencedInstance [

	^ MCPToolRenameClassTestOriginal new
]

{ #category : 'accessing' }
MCPToolRenameClassTestReference >> referencedClass [

	^ MCPToolRenameClassTestOriginal
]
