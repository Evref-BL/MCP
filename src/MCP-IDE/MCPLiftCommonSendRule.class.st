"
Renraku rule that warns when both branches of a conditional send the same message to the same receiver, or both return.

A Pharo conditional is an expression, so the send can stand outside it and the conditional answer only the argument that varies. The receiver must be a variable, so evaluating it before the condition changes nothing, and the arguments must not be blocks, which would leave blocks inside a conditional. A return is lifted only out of a conditional that is a statement of its own.
"
Class {
	#name : 'MCPLiftCommonSendRule',
	#superclass : 'MCPMethodStyleRule',
	#category : 'MCP-IDE-Critiques',
	#package : 'MCP-IDE',
	#tag : 'Critiques'
}

{ #category : 'accessing' }
MCPLiftCommonSendRule class >> rationale [

	^ 'When both branches send the same message to the same receiver, or both return, send or return once and let the conditional answer what varies.'
]

{ #category : 'accessing' }
MCPLiftCommonSendRule class >> ruleName [

	^ 'Lift the send both branches make'
]

{ #category : 'initialization' }
MCPLiftCommonSendRule >> initialize [

	super initialize.
	self
		replace:
			'`@condition ifTrue: [ `receiver `message: `@first `{ :node | node isBlock not } ] ifFalse: [ `receiver `message: `@second `{ :node | node isBlock not } ]'
		with: '`receiver `message: (`@condition ifTrue: [ `@first ] ifFalse: [ `@second ])';
		replace:
			'`@condition ifFalse: [ `receiver `message: `@first `{ :node | node isBlock not } ] ifTrue: [ `receiver `message: `@second `{ :node | node isBlock not } ]'
		with: '`receiver `message: (`@condition ifFalse: [ `@first ] ifTrue: [ `@second ])';
		replace: '`@condition `{ :node | MCPMethodStyleRule isStatement: node parent } ifTrue: [ ^ `@first ] ifFalse: [ ^ `@second ]'
		with: '^ `@condition ifTrue: [ `@first ] ifFalse: [ `@second ]';
		replace: '`@condition `{ :node | MCPMethodStyleRule isStatement: node parent } ifFalse: [ ^ `@first ] ifTrue: [ ^ `@second ]'
		with: '^ `@condition ifFalse: [ `@first ] ifTrue: [ `@second ]'
]
