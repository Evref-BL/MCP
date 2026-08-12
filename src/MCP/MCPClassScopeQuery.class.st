"
Resolves class-scope arguments into class sets.

It handles packageNames, classNames, hierarchyClassNames, subclassClassNames, and parentClassNames. Scope sets are unioned. Search tools keep valid scopes and record warnings for missing names. Tools that mutate the image can require a complete scope; missing names then raise a structured error with the same suggestions. Directional subclass and parent scopes exclude their anchor classes.
"
Class {
	#name : 'MCPClassScopeQuery',
	#superclass : 'MCPScopeQuery',
	#category : 'MCP-Queries',
	#package : 'MCP',
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
	self classNames ifNotEmpty: [ sets add: (self resolvedClassesNamed: self classNames inScope: 'classNames') ].
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
			(self resolvedPackageNamed: eachName inScope: 'packageNames') ifNotNil: [ :package |
				package classes do: [ :eachClass | classes add: eachClass instanceSide ] ] ].
	^ self sortedClassesByName: classes
]

{ #category : 'private - scope' }
MCPClassScopeQuery >> hierarchyClassesNamed: someClassNames [

	| classes |
	classes := IdentitySet new.
	(self resolvedClassesNamed: someClassNames inScope: 'hierarchyClassNames') do: [ :eachClass |
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
	(self resolvedClassesNamed: someClassNames inScope: 'parentClassNames') do: [ :eachClass |
		eachClass allSuperclasses do: [ :relatedClass | classes add: relatedClass instanceSide ] ].
	^ self sortedClassesByName: classes
]

{ #category : 'private - resolution' }
MCPClassScopeQuery >> resolvedClassNamed: className [

	^ self resolvedClassNamed: className inScope: 'classes'
]

{ #category : 'private - resolution' }
MCPClassScopeQuery >> resolvedClassNamed: className inScope: scopeName [

	^ Smalltalk globals at: className asSymbol ifAbsent: [ self recordMissingClassNamed: className inScope: scopeName ]
]

{ #category : 'private - resolution' }
MCPClassScopeQuery >> resolvedClassesNamed: someClassNames [

	^ self resolvedClassesNamed: someClassNames inScope: 'classes'
]

{ #category : 'private - resolution' }
MCPClassScopeQuery >> resolvedClassesNamed: someClassNames inScope: scopeName [

	| classes |
	classes := IdentitySet new.
	someClassNames do: [ :eachName |
		(self resolvedClassNamed: eachName inScope: scopeName) ifNotNil: [ :resolvedClass | classes add: resolvedClass instanceSide ] ].
	^ self sortedClassesByName: classes
]

{ #category : 'private - resolution' }
MCPClassScopeQuery >> resolvedPackageNamed: packageName [

	^ self resolvedPackageNamed: packageName inScope: 'packages'
]

{ #category : 'private - resolution' }
MCPClassScopeQuery >> resolvedPackageNamed: packageName inScope: scopeName [

	^ PackageOrganizer default
		  packageNamed: packageName asSymbol
		  ifAbsent: [ self recordMissingPackageNamed: packageName inScope: scopeName ]
]

{ #category : 'private - scope' }
MCPClassScopeQuery >> sortedClassesByName: someClasses [

	^ someClasses asArray sort: [ :left :right | left name <= right name ]
]

{ #category : 'private - scope' }
MCPClassScopeQuery >> subclassClassesNamed: someClassNames [

	| classes |
	classes := IdentitySet new.
	(self resolvedClassesNamed: someClassNames inScope: 'subclassClassNames') do: [ :eachClass |
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
