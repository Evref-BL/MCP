Class {
	#name : 'MCPToolSendersTestBase',
	#superclass : 'Object',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'testing' }
MCPToolSendersTestBase >> baseHierarchySender [

	^ self hierarchyTarget
]

{ #category : 'testing' }
MCPToolSendersTestBase >> hierarchyTarget [

	^ 'base-target'
]
