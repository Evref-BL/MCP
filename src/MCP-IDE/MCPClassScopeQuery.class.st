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

{ #category : 'private - scope' }
MCPClassScopeQuery >> allClasses [

	| classes |
	classes := IdentitySet new.
	Smalltalk globals allClasses do: [ :eachClass | classes add: eachClass instanceSide ].
	^ self sortedClassesByName: classes
]

{ #category : 'private - scope' }
MCPClassScopeQuery >> classScopeSets [

	| sets |
	sets := OrderedCollection new.
	self packageNames ifNotEmpty: [ sets add: self classesForPackageNames ].
	self classNames ifNotEmpty: [ sets add: (self resolvedClassesNamed: self classNames inScope: 'scope.classes') ].
	self hierarchyClassNames ifNotEmpty: [ sets add: (self hierarchyClassesNamed: self hierarchyClassNames) ].
	self subclassClassNames ifNotEmpty: [ sets add: (self subclassClassesNamed: self subclassClassNames) ].
	self parentClassNames ifNotEmpty: [ sets add: (self parentClassesNamed: self parentClassNames) ].
	^ sets asArray
]

{ #category : 'querying' }
MCPClassScopeQuery >> classes [

	self resetWarnings.
	self usesImplicitImageScope ifTrue: [ ^ self allClasses ].
	^ self unionClasses
]

{ #category : 'private - scope' }
MCPClassScopeQuery >> classesForPackageNames [

	| classes |
	classes := IdentitySet new.
	packageNames do: [ :eachName |
			(self packageNamed: eachName inScope: 'scope.packages') ifNotNil: [ :package |
				package classes do: [ :eachClass | classes add: eachClass instanceSide ] ] ].
	^ self sortedClassesByName: classes
]

{ #category : 'private - scope' }
MCPClassScopeQuery >> hierarchyClassesNamed: someClassNames [

	| classes |
	classes := IdentitySet new.
	(self resolvedClassesNamed: someClassNames inScope: 'scope.hierarchyOf') do: [ :eachClass |
		eachClass withAllSuperAndSubclasses do: [ :relatedClass | classes add: relatedClass instanceSide ] ].
	^ self sortedClassesByName: classes
]

{ #category : 'initialization' }
MCPClassScopeQuery >> initialize [

	super initialize.
	packageNames := #(  ).
	classNames := #(  ).
	hierarchyClassNames := #(  ).
	subclassClassNames := #(  ).
	parentClassNames := #(  ).
	warnings := OrderedCollection new.
	requiresCompleteScope := false
]

{ #category : 'private - scope' }
MCPClassScopeQuery >> parentClassesNamed: someClassNames [

	| classes |
	classes := IdentitySet new.
	(self resolvedClassesNamed: someClassNames inScope: 'scope.superclassesOf') do: [ :eachClass |
		eachClass allSuperclasses do: [ :relatedClass | classes add: relatedClass instanceSide ] ].
	^ self sortedClassesByName: classes
]

{ #category : 'private - resolution' }
MCPClassScopeQuery >> resolvedClassesNamed: someClassNames inScope: aScopeKey [

	| classes |
	classes := IdentitySet new.
	someClassNames do: [ :eachName |
		(self classNamed: eachName inScope: aScopeKey) ifNotNil: [ :resolvedClass | classes add: resolvedClass instanceSide ] ].
	^ self sortedClassesByName: classes
]

{ #category : 'private - scope' }
MCPClassScopeQuery >> sortedClassesByName: someClasses [

	^ someClasses asArray sort: [ :left :right | left name <= right name ]
]

{ #category : 'private - scope' }
MCPClassScopeQuery >> subclassClassesNamed: someClassNames [

	| classes |
	classes := IdentitySet new.
	(self resolvedClassesNamed: someClassNames inScope: 'scope.subclassesOf') do: [ :eachClass |
		eachClass allSubclasses do: [ :relatedClass | classes add: relatedClass instanceSide ] ].
	^ self sortedClassesByName: classes
]

{ #category : 'private - scope' }
MCPClassScopeQuery >> unionClasses [

	| classes |
	classes := IdentitySet new.
	self classScopeSets do: [ :eachSet | classes addAll: eachSet ].
	^ self sortedClassesByName: classes
]
