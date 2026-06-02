Extension { #name : 'RBRefactoringWarning' }

{ #category : '*MCP' }
RBRefactoringWarning >> mcpErrorResultForMutationTool: aTool action: action requestedContext: requestedContext summary: summary [

	^ aTool
		  errorResultForRefactoringWarning: self
		  action: action
		  requestedContext: requestedContext
]

{ #category : '*MCP' }
RBRefactoringWarning >> mcpMutationFailureErrorCodeSuffix [

	^ 'RefactoringWarning'
]
