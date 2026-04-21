Class {
	#name : 'MCPToolSendersTestChild',
	#superclass : 'MCPToolSendersTestMid',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'testing' }
MCPToolSendersTestChild >> childHierarchySender [

	^ self hierarchyTarget
]
