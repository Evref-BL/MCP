Class {
	#name : 'MCPToolReferencesTestChild',
	#superclass : 'MCPToolReferencesTestMid',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'testing' }
MCPToolReferencesTestChild >> childHierarchySender [

	^ self hierarchyTarget
]
