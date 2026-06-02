Extension { #name : 'MessageNotUnderstood' }

{ #category : '*MCP' }
MessageNotUnderstood >> mcpDebugMethodUpdateKind [

	^ 'missingMethod'
]

{ #category : '*MCP' }
MessageNotUnderstood >> mcpDebugRepairActionsFor: aRepairAnalyzer [

	| action |
	action := aRepairAnalyzer missingMethodActionFor: self.
	^ action ifNil: [ #(  ) ] ifNotNil: [ { action } ]
]

{ #category : '*MCP' }
MessageNotUnderstood >> mcpPrepareForProceed [

	^ self mcpPrepareToResend
]

{ #category : '*MCP' }
MessageNotUnderstood >> mcpPrepareToResend [

	hasToResend := true
]

{ #category : '*MCP' }
MessageNotUnderstood >> mcpRepairContextForMethodImplementation: aCompiledMethod [

	^ self contextForMethodImplementation: aCompiledMethod
]

{ #category : '*MCP' }
MessageNotUnderstood >> mcpRepairMessageForContext: aContext [

	^ self message
]
