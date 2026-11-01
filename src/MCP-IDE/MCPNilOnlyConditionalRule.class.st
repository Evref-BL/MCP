"
Renraku rule that warns when an ifNil:ifNotNil: conditional has a nil-only branch that can be removed.

When the nil case only answers nil, ifNotNil: alone says the same, since it answers nil when it does not run. Pharo's ReNilBranchRule already says it of ifTrue:ifFalse:.
"
Class {
	#name : 'MCPNilOnlyConditionalRule',
	#superclass : 'MCPMethodStyleRule',
	#category : 'MCP-IDE-Critiques',
	#package : 'MCP-IDE',
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
