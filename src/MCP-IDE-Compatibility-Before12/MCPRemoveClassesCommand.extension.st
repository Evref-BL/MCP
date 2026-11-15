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

{ #category : '*MCP-IDE-Compatibility-Before12' }
MCPRemoveClassesCommand >> referencesBlockingRemovalBy: anException refactoring: aRefactoring [
	"Pharo 10 and 11 stop at the first condition that fails and keep no list of what refers to a class, so the methods are found by a scan, counted as their check counts them: outside the classes asked for, on either side."

	^ self referencesOutsideRemoval
]

{ #category : '*MCP-IDE-Compatibility-Before12' }
MCPRemoveClassesCommand >> subclassesBlockingRemovalOf: aClass [
	"Pharo 10 and 11 compare the subclasses' names with the names asked for, so a subclass removed in the same call does not block."

	^ self subclassNamesOf: aClass excluding: (self resolvedClasses collect: [ :each | each name asString ])
]

{ #category : '*MCP-IDE-Compatibility-Before12' }
MCPRemoveClassesCommand >> usersBlockingRemovalOf: aClass [
	"Pharo 10 and 11 refuse to remove a trait a class still uses. Their check compares the users, which are classes, with the names asked for, so a user removed in the same call blocks too."

	^ self traitUserNamesOf: aClass
]
