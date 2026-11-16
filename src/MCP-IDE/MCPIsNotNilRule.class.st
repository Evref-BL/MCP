"
Renraku rule that warns when code asks notNil instead of isNotNil.

Both answer the same thing, but every other test of this kind reads is-something: isNil, isEmpty, isString. notNil is the one that does not, and outside a conditional nothing in the image flags it.

A notNil that ifTrue: or ifFalse: tests is left to Pharo's ReIsNotNilAndConditionalRule, which advises ifNotNil: or ifNil: in place of the test; isNotNil would keep it.
"
Class {
	#name : 'MCPIsNotNilRule',
	#superclass : 'MCPMethodStyleRule',
	#category : 'MCP-IDE-Critiques',
	#package : 'MCP-IDE',
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
	self
		replace: '`@receiver `{ :node | (MCPMethodStyleRule isConditionOfIfTrueOrIfFalse: node parent) not } notNil'
		with: '`@receiver isNotNil'
]
