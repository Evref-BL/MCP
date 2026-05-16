Class {
	#name : 'MCPToolHierarchyTestChild',
	#superclass : 'MCPToolHierarchyTestMid',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'testing' }
MCPToolHierarchyTestChild >> childHierarchySender [

	^ self hierarchyTarget
]

{ #category : 'testing' }
MCPToolHierarchyTestChild >> hierarchyProbe [

	^ 'child'
]
