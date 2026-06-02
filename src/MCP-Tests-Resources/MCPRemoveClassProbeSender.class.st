"
Fixture class that sends references used by class-removal tests.
"
Class {
	#name : 'MCPRemoveClassProbeSender',
	#superclass : 'Object',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'tests' }
MCPRemoveClassProbeSender >> useProbe [

	^ MCPRemoveClassProbeReferenced new
]
