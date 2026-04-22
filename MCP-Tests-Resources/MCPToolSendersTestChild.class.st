Class {
	#name : 'MCPToolSendersTestChild',
	#superclass : 'MCPToolSendersTestMid',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'testing' }
MCPToolSendersTestChild >> childHierarchySender [

	^ self hierarchyTarget
]
