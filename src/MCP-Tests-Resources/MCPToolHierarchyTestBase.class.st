Class {
	#name : 'MCPToolHierarchyTestBase',
	#superclass : 'Object',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'testing' }
MCPToolHierarchyTestBase >> baseHierarchySender [

	^ self hierarchyTarget
]

{ #category : 'testing' }
MCPToolHierarchyTestBase >> hierarchyProbe [

	^ 'base'
]

{ #category : 'testing' }
MCPToolHierarchyTestBase >> hierarchyTarget [

	^ 'base-target'
]
