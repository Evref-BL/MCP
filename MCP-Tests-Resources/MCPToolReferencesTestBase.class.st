Class {
	#name : 'MCPToolReferencesTestBase',
	#superclass : 'Object',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'testing' }
MCPToolReferencesTestBase >> baseHierarchySender [

	^ self hierarchyTarget
]

{ #category : 'testing' }
MCPToolReferencesTestBase >> hierarchyTarget [

	^ 'base-target'
]
