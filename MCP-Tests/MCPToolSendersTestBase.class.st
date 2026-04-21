Class {
	#name : 'MCPToolSendersTestBase',
	#superclass : 'Object',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'testing' }
MCPToolSendersTestBase >> baseHierarchySender [

	^ self hierarchyTarget
]

{ #category : 'testing' }
MCPToolSendersTestBase >> hierarchyTarget [

	^ 'base-target'
]
