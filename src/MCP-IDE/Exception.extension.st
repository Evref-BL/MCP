Extension { #name : 'Exception' }

{ #category : '*MCP-IDE' }
Exception >> mcpErrorResultForMutationTool: aTool action: action requestedContext: requestedContext summary: summary [

	^ aTool
		  errorResultForCommandError: (aTool
				   normalizedCommandErrorForActionFailure: self
				   action: action
				   requestedContext: requestedContext
				   summary: summary)
		  action: action
		  requestedContext: requestedContext
]

{ #category : '*MCP-IDE' }
Exception >> mcpMutationFailureCauseForSyntaxNotice: aSyntaxNotice [

	^ aSyntaxNotice
]

{ #category : '*MCP-IDE' }
Exception >> mcpMutationFailureErrorCodeSuffix [

	^ 'ExecutionError'
]

{ #category : '*MCP-IDE' }
Exception >> mcpNoticeNode [

	^ nil
]

{ #category : '*MCP-IDE' }
Exception >> mcpSyntaxNotice [

	^ nil
]
