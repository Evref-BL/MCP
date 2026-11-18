"
Renraku rule that warns when code asks notNil instead of isNotNil.

Both answer the same thing, but every other test of this kind reads is-something: isNil, isEmpty, isString. notNil is the one that does not, and no rule of Pharo's asks for isNotNil.

Where Pharo has ReIsNotNilAndConditionalRule, a notNil that ifTrue:, ifFalse:, ifTrue:ifFalse: or ifFalse:ifTrue: is sent to is left to that rule, which advises ifNotNil: or ifNil: in place of the whole conditional; isNotNil would keep the test. Where Pharo lacks that rule, nothing else critiques such a notNil, so this rule still does.
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
		replace: ((self class environment includesKey: #ReIsNotNilAndConditionalRule)
				 ifTrue: [ '`@receiver `{ :node | (MCPMethodStyleRule isConditionOfIfTrueOrIfFalse: node parent) not } notNil' ]
				 ifFalse: [ '`@receiver notNil' ])
		with: '`@receiver isNotNil'
]
