Class {
	#name : 'MCPDebugEditTestTarget',
	#superclass : 'Object',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'tests' }
MCPDebugEditTestTarget >> triggerMissingMethod [

	^ self mcpDebugEditGeneratedValue
]
