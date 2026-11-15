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

{ #category : '*MCP-IDE-Compatibility-From12' }
MCPRemoveClassesCommand >> referencesBlockingRemovalBy: anException refactoring: aRefactoring [
	"Class name to the methods Pharo's references condition found. From Pharo 13 the warning carries the conditions that failed; on 12 it carries none, and a new condition on the same model and classes finds them again. On 12 and 13 the condition answers them by class, from 14 in one list, where each method is filed under every class asked for that it refers to. An error says nothing about references: from 12 only a missing class or a metaclass signals one."

	| condition violators references |
	anException isResumable ifFalse: [ ^ Dictionary new ].
	condition := anException mcpFailedPreconditions
		             ifNil: [ aRefactoring preconditionHaveNoReferences ]
		             ifNotNil: [ :conditions |
		             conditions detect: [ :each | each isKindOf: ReClassesHaveNoReferencesCondition ] ifNone: [ ^ Dictionary new ] ].
	violators := condition violators.
	references := Dictionary new.
	violators isDictionary
		ifTrue: [
		violators keysAndValuesDo: [ :class :methods | methods ifNotEmpty: [ references at: class name asString put: methods ] ] ]
		ifFalse: [
				self resolvedClasses do: [ :each |
						(violators select: [ :method | method refersToClassNamed: each name ]) ifNotEmpty: [ :methods |
							references at: each name asString put: methods ] ] ].
	^ references
]

{ #category : '*MCP-IDE-Compatibility-From12' }
MCPRemoveClassesCommand >> subclassesBlockingRemovalOf: aClass [
	"From Pharo 12 the subclass condition compares the subclasses' names with the classes asked for, so naming a subclass in the same call does not lift it."

	^ self subclassNamesOf: aClass excluding: #(  )
]

{ #category : '*MCP-IDE-Compatibility-From12' }
MCPRemoveClassesCommand >> usersBlockingRemovalOf: aClass [
	"From Pharo 12 the classes using a trait do not block its removal."

	^ #(  )
]
