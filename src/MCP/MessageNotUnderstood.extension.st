Extension { #name : 'MessageNotUnderstood' }

{ #category : '*MCP' }
MessageNotUnderstood >> mcpAddToolErrorDetailsTo: aDictionary [
	"Name the selectors the receiver's class does understand that resemble the one it did not, the way the debugger would."

	| suggestions |
	suggestions := MCPSelectorSuggestion selectorsLike: self message selector understoodBy: self receiver class.
	suggestions ifNotEmpty: [ aDictionary at: #suggestedSelectors put: suggestions ].
	^ aDictionary
]

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
