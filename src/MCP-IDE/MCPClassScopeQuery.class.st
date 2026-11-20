"
Resolves class-scope arguments into class sets.

It handles packageNames, classNames, hierarchyClassNames, subclassClassNames, and parentClassNames. Scope sets are unioned. Search tools keep valid scopes and record warnings for missing names. Tools that mutate the image can require a complete scope; missing names then raise a structured error with the same suggestions. Directional subclass and parent scopes exclude their anchor classes.
"
Class {
	#name : 'MCPClassScopeQuery',
	#superclass : 'MCPScopeQuery',
	#category : 'MCP-IDE-Queries',
	#package : 'MCP-IDE',
	#tag : 'Queries'
}

{ #category : 'testing' }
MCPClassScopeQuery >> asksForAHierarchy [
	"Whether the scope reaches classes by inheritance, from the superclasses, subclasses or hierarchy of others: their rows then say what each inherits from, which alone gives the chain and the tree back."

	^ self hierarchyClassNames isNotEmpty or: [ self subclassClassNames isNotEmpty or: [ self parentClassNames isNotEmpty ] ]
]

{ #category : 'querying' }
MCPClassScopeQuery >> classes [
	"Sorted by name once, after the union."

	self resetWarnings.
	^ self sortedClassesByName: (self usesImplicitImageScope
			   ifTrue: [ self class environment allClasses ]
			   ifFalse: [
					   self classesForPackageNames
						   addAll: self namedClasses;
						   yourself ])
]

{ #category : 'private - scope' }
MCPClassScopeQuery >> classesForPackageNames [

	| classes |
	classes := IdentitySet new.
	self packageNames do: [ :eachName |
			(self packageNamed: eachName inScope: 'scope.packages') ifNotNil: [ :package |
				package classes do: [ :eachClass | classes add: eachClass instanceSide ] ] ].
	^ classes
]

{ #category : 'private - scope' }
MCPClassScopeQuery >> sortedClassesByName: someClasses [

	^ someClasses asArray sort: [ :left :right | left name <= right name ]
]
