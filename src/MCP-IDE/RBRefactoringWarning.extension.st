Extension { #name : 'RBRefactoringWarning' }

{ #category : '*MCP-IDE' }
RBRefactoringWarning >> mcpErrorResultForMutationTool: aTool action: action requestedContext: requestedContext summary: summary [

	^ aTool errorResultForRefactoringWarning: self action: action requestedContext: requestedContext
]

{ #category : '*MCP-IDE' }
RBRefactoringWarning >> mcpMutationFailureErrorCodeSuffix [

	^ 'RefactoringWarning'
]

{ #category : '*MCP-IDE' }
RBRefactoringWarning >> mcpResumesAtToolBoundary [
	"I report a change that breaks something. A tool that may proceed anyway handles me itself behind force, so reaching the boundary around the call unresumed is what aborts an unauthorized mutation."

	^ false
]
