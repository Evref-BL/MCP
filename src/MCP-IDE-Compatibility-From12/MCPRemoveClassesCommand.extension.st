Extension { #name : 'MCPRemoveClassesCommand' }

{ #category : '*MCP-IDE-Compatibility-From12' }
MCPRemoveClassesCommand >> classesTheCheckReads [

	| classes |
	classes := IdentitySet new.
	self resolvedClasses do: [ :each | classes addAll: each withAllSuperAndSubclasses ].
	self methodsThatMayRefer do: [ :each | classes add: each methodClass instanceSide ].
	^ classes
]

{ #category : '*MCP-IDE-Compatibility-From12' }
MCPRemoveClassesCommand >> performRemovalWithPreparedRefactoring: aRefactoring [
	"The removal runs in a model of the whole image, not the one the check read: moving a subclass up redefines it, with traits and pools that model may not hold."

	(ReRemoveClassRefactoring classNames: aRefactoring classNames)
		prepareForExecution;
		removeClassChanges;
		performChanges
]

{ #category : '*MCP-IDE-Compatibility-From12' }
MCPRemoveClassesCommand >> preparedRefactoringForClassNames: someClassNames [
	"Pharo's check sweeps every class of the refactoring's model for references to the classes, so the model holds only what the check can read: the classes with their superclasses and subclasses, and the classes of the methods that may refer to them."

	^ (ReRemoveClassRefactoring
		   model: (RBNamespace onEnvironment: (RBBrowserEnvironment new forClasses: self classesTheCheckReads))
		   classNames: (someClassNames collect: #asSymbol))
		  prepareForExecution;
		  yourself
]
