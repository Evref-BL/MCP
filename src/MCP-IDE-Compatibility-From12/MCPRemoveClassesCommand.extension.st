Extension { #name : 'MCPRemoveClassesCommand' }

{ #category : '*MCP-IDE-Compatibility-From12' }
MCPRemoveClassesCommand >> performRemovalWithPreparedRefactoring: aRefactoring [

	aRefactoring removeClassChanges.
	aRefactoring performChanges
]

{ #category : '*MCP-IDE-Compatibility-From12' }
MCPRemoveClassesCommand >> preparedRefactoringForClassNames: someClassNames [

	| refactoring |
	refactoring := ReRemoveClassRefactoring classNames: (someClassNames collect: #asSymbol).
	refactoring prepareForExecution.
	^ refactoring
]
