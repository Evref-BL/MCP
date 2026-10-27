Extension { #name : 'RBRefactoringWarning' }

{ #category : '*MCP-IDE' }
RBRefactoringWarning >> mcpErrorResultForMutationTool: aTool action: action requestedContext: requestedContext summary: summary [

	^ aTool errorResultForRefactoringWarning: self action: action requestedContext: requestedContext
]

{ #category : '*MCP-IDE' }
RBRefactoringWarning >> mcpMutationFailureErrorCodeSuffix [

	^ 'RefactoringWarning'
]
