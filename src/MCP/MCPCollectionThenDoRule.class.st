"
Renraku rule that warns when code builds a collection only to iterate over it immediately.

Use collect:thenDo:, select:thenDo:, or reject:thenDo: when the transformation or filter exists only to feed a do: block.
"
Class {
	#name : 'MCPCollectionThenDoRule',
	#superclass : 'MCPMethodStyleRule',
	#category : 'MCP-Critiques',
	#package : 'MCP',
	#tag : 'Critiques'
}

{ #category : 'accessing' }
MCPCollectionThenDoRule class >> rationale [

	^ 'Use collect:thenDo:, select:thenDo:, or reject:thenDo: when an intermediate collection is only used for iteration.'
]

{ #category : 'accessing' }
MCPCollectionThenDoRule class >> ruleName [

	^ 'Use fused collection iteration'
]

{ #category : 'initialization' }
MCPCollectionThenDoRule >> initialize [

	super initialize.
	self
		replace: '(`@collection collect: `@collectBlock) do: `@doBlock' with: '`@collection collect: `@collectBlock thenDo: `@doBlock';
		replace: '(`@collection select: `@filterBlock) do: `@doBlock' with: '`@collection select: `@filterBlock thenDo: `@doBlock';
		replace: '(`@collection reject: `@filterBlock) do: `@doBlock' with: '`@collection reject: `@filterBlock thenDo: `@doBlock'
]
