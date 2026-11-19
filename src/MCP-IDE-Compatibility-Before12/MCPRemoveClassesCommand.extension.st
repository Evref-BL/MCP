Extension { #name : 'MCPRemoveClassesCommand' }

{ #category : '*MCP-IDE-Compatibility-Before12' }
MCPRemoveClassesCommand >> performRemovalWithPreparedRefactoring: aRefactoring [
	"The preconditions were checked already; transforming computes the changes."

	aRefactoring transform.
	aRefactoring performChanges
]

{ #category : '*MCP-IDE-Compatibility-Before12' }
MCPRemoveClassesCommand >> preparedRefactoringForClassNames: someClassNames [
	"Before Pharo 12, a refactoring computes its changes as it transforms, so there is nothing to prepare."

	^ RBRemoveClassRefactoring classNames: (someClassNames collect: #asSymbol)
]
