"
A screen reader whose own code sends a mistyped selector, as a slip in a tool would.
"
Class {
	#name : 'MCPToolReadScreenMistyping',
	#superclass : 'MCPToolReadScreen',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'private - user interface' }
MCPToolReadScreenMistyping >> targetMorphNamed: aTitle [

	^ Morph new adMorph: Morph new
]
