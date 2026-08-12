"
Renraku rule that warns when an ifNil:/ifNotNil: conditional has a nil-only branch that can be removed.

When the nil case only answers nil and the present case computes a value, the shorter ifNotNil: form keeps the code direct without changing behavior.
"
Class {
	#name : 'MCPNilOnlyConditionalRule',
	#superclass : 'MCPMethodStyleRule',
	#category : 'MCP-Critiques',
	#package : 'MCP',
	#tag : 'Critiques'
}

{ #category : 'accessing' }
MCPNilOnlyConditionalRule class >> rationale [

	^ 'Remove nil-only branches in ifNil:/ifNotNil: conditionals. Prefer the shorter ifNotNil: form when the nil branch only answers nil.'
]

{ #category : 'accessing' }
MCPNilOnlyConditionalRule class >> ruleName [

	^ 'Remove nil-only conditional branches'
]

{ #category : 'initialization' }
MCPNilOnlyConditionalRule >> initialize [

	super initialize.
	self
		replace: '`@receiver ifNil: [ nil ] ifNotNil: `@block' with: '`@receiver ifNotNil: `@block';
		replace: '`@receiver ifNotNil: `@block ifNil: [ nil ]' with: '`@receiver ifNotNil: `@block'
]
