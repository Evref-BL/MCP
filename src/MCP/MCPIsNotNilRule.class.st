"
Renraku rule that warns when code asks notNil instead of isNotNil.

Both answer the same thing, but every other test of this kind reads is-something: isNil, isEmpty, isString. notNil is the one that does not, and nothing in the image flags it.
"
Class {
	#name : 'MCPIsNotNilRule',
	#superclass : 'MCPMethodStyleRule',
	#category : 'MCP-Critiques',
	#package : 'MCP',
	#tag : 'Critiques'
}

{ #category : 'accessing' }
MCPIsNotNilRule class >> rationale [

	^ 'Prefer isNotNil to notNil. It answers the same thing and reads like every other test of its kind.'
]

{ #category : 'accessing' }
MCPIsNotNilRule class >> ruleName [

	^ 'Use isNotNil'
]

{ #category : 'initialization' }
MCPIsNotNilRule >> initialize [

	super initialize.
	self replace: '`@receiver notNil' with: '`@receiver isNotNil'
]
