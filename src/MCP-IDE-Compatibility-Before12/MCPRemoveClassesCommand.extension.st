Extension { #name : 'MCPRemoveClassesCommand' }

{ #category : '*MCP-IDE-Compatibility-Before12' }
MCPRemoveClassesCommand >> performRemovalWithPreparedRefactoring: aRefactoring [
	"The preconditions were checked already; transforming computes the changes."

	aRefactoring transform.
	aRefactoring performChanges
]

{ #category : '*MCP-IDE-Compatibility-Before12' }
MCPRemoveClassesCommand >> preparedRefactoringForClassNames: someClassNames [
	"Pharo 11 computes the changes of a refactoring as it transforms, so there is nothing to prepare."

	^ RBRemoveClassRefactoring classNames: (someClassNames collect: #asSymbol)
]
