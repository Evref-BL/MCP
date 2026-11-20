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
Exception >> mcpFailedPreconditions [
	"The refactoring conditions a warning reports as failed, from Pharo 12 on; nil when it carries none."

	^ nil
]

{ #category : '*MCP-IDE' }
Exception >> mcpMutationFailureErrorCodeSuffix [

	^ 'ExecutionError'
]

{ #category : '*MCP-IDE' }
Exception >> mcpSyntaxNotice [

	^ nil
]

{ #category : '*MCP-IDE' }
Exception >> mcpTestIssueNote [
	"What a test_run issue says beside the exception's message: nothing, unless the exception says what was meant."

	^ nil
]
