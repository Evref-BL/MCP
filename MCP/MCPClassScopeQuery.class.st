"
Parsed scope query for class listings.

It resolves packageNames, classNames, and hierarchyClassNames into a union of classes. Empty scope properties mean image-wide class scope.
"
Class {
	#name : 'MCPClassScopeQuery',
	#superclass : 'Object',
	#instVars : [
		'packageNames',
		'classNames',
		'hierarchyClassNames'
	],
	#category : 'MCP-Queries',
	#package : 'MCP',
	#tag : 'Queries'
}

{ #category : 'private - scope' }
MCPClassScopeQuery >> allClasses [

	| classes |
	classes := IdentitySet new.
	Smalltalk globals allClasses do: [ :eachClass |
		classes add: eachClass instanceSide ].
	^ self sortedClassesByName: classes
]

{ #category : 'accessing' }
MCPClassScopeQuery >> classNames [

	^ classNames
]

{ #category : 'accessing' }
MCPClassScopeQuery >> classNames: someClassNames [

	classNames := someClassNames
		              ifNil: [ #(  ) ]
		              ifNotNil: [ someClassNames asArray ]
]

{ #category : 'querying' }
MCPClassScopeQuery >> classes [

	| classes hierarchyRoots |
	self validate.
	self usesImplicitImageScope ifTrue: [ ^ self allClasses ].
	classes := IdentitySet new.
	self packageNames ifNotEmpty: [
		classes addAll: self classesForPackageNames ].
	self classNames ifNotEmpty: [
		classes addAll: (self resolvedClassesNamed: self classNames) ].
	hierarchyRoots := self hierarchyClassNames.
	hierarchyRoots ifNotEmpty: [
		classes addAll: (self hierarchyClassesNamed: hierarchyRoots) ].
	^ self sortedClassesByName: classes
]

{ #category : 'private - scope' }
MCPClassScopeQuery >> classesForPackageNames [

	| classes |
	classes := IdentitySet new.
	packageNames do: [ :eachName |
		(self resolvedPackageNamed: eachName) classes do: [ :eachClass |
			classes add: eachClass instanceSide ] ].
	^ self sortedClassesByName: classes
]

{ #category : 'accessing' }
MCPClassScopeQuery >> hierarchyClassNames [

	^ hierarchyClassNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPClassScopeQuery >> hierarchyClassNames: someClassNames [

	hierarchyClassNames := someClassNames
		                       ifNil: [ #(  ) ]
		                       ifNotNil: [ someClassNames asArray ]
]

{ #category : 'private - scope' }
MCPClassScopeQuery >> hierarchyClassesNamed: someClassNames [

	| classes |
	classes := IdentitySet new.
	(self resolvedClassesNamed: someClassNames) do: [ :eachClass |
		eachClass withAllSuperAndSubclasses do: [ :relatedClass |
			classes add: relatedClass instanceSide ] ].
	^ self sortedClassesByName: classes
]

{ #category : 'initialization' }
MCPClassScopeQuery >> initialize [

	super initialize.
	packageNames := #(  ).
	classNames := #(  ).
	hierarchyClassNames := #(  )
]

{ #category : 'accessing' }
MCPClassScopeQuery >> packageNames [

	^ packageNames
]

{ #category : 'accessing' }
MCPClassScopeQuery >> packageNames: somePackageNames [

	packageNames := somePackageNames
		                ifNil: [ #(  ) ]
		                ifNotNil: [ somePackageNames asArray ]
]

{ #category : 'private - resolution' }
MCPClassScopeQuery >> resolvedClassNamed: className [

	^ Smalltalk globals
		  at: className asSymbol
		  ifAbsent: [ MCPCommandError signalMissingClassNamed: className ]
]

{ #category : 'private - resolution' }
MCPClassScopeQuery >> resolvedClassesNamed: someClassNames [

	| classes |
	classes := IdentitySet new.
	someClassNames do: [ :eachName |
		classes add: (self resolvedClassNamed: eachName) instanceSide ].
	^ self sortedClassesByName: classes
]

{ #category : 'private - resolution' }
MCPClassScopeQuery >> resolvedPackageNamed: packageName [

	^ PackageOrganizer default
		  packageNamed: packageName asSymbol
		  ifAbsent: [
		  MCPCommandError signalMissingPackageNamed: packageName ]
]

{ #category : 'private - scope' }
MCPClassScopeQuery >> sortedClassesByName: someClasses [

	^ (someClasses asSortedCollection: [ :left :right |
		   left name <= right name ]) asArray
]

{ #category : 'private - source' }
MCPClassScopeQuery >> usesImplicitImageScope [

	^ self packageNames isEmpty and: [
		  self classNames isEmpty and: [ self hierarchyClassNames isEmpty ] ]
]

{ #category : 'validating' }
MCPClassScopeQuery >> validate [

	^ self
]
