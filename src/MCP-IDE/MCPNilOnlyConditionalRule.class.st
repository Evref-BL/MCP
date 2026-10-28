"
Renraku rule that warns when a conditional has a nil-only branch that can be removed.

When one case only answers nil and the other computes a value, the one-armed form keeps the code direct without changing behavior: ifNotNil: for nil traversal, and ifTrue: or ifFalse: for a boolean condition, since both answer nil when they do not run.
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
		replace: '`@receiver ifNotNil: `@block ifNil: [ nil ]' with: '`@receiver ifNotNil: `@block';
		replace: '`@condition ifTrue: [ `@body ] ifFalse: [ nil ]' with: '`@condition ifTrue: [ `@body ]';
		replace: '`@condition ifFalse: [ `@body ] ifTrue: [ nil ]' with: '`@condition ifFalse: [ `@body ]'
]
