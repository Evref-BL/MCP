"
Renraku rule that warns when code asks notEmpty instead of isNotEmpty.

Both answer the same thing, but every other test of this kind reads is-something: isEmpty, isNil, isString. Pharo's own comment on notEmpty says to prefer isNotEmpty for consistency with isEmpty, yet nothing in the image flags it.
"
Class {
	#name : 'MCPIsNotEmptyRule',
	#superclass : 'MCPMethodStyleRule',
	#category : 'MCP-IDE-Critiques',
	#package : 'MCP-IDE',
	#tag : 'Critiques'
}

{ #category : 'accessing' }
MCPIsNotEmptyRule class >> rationale [

	^ 'Prefer isNotEmpty to notEmpty. It answers the same thing and reads like every other test of its kind.'
]

{ #category : 'accessing' }
MCPIsNotEmptyRule class >> ruleName [

	^ 'Use isNotEmpty'
]

{ #category : 'initialization' }
MCPIsNotEmptyRule >> initialize [

	super initialize.
	self replace: '`@receiver notEmpty' with: '`@receiver isNotEmpty'
]
