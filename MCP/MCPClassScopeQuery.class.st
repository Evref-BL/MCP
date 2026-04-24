Class {
	#name : 'MCPClassScopeQuery',
	#superclass : 'MCPScopeQuery',
	#instVars : [
		'packageNames',
		'classNames'
	],
	#category : 'MCP-Queries',
	#package : 'MCP',
	#tag : 'Queries'
}

{ #category : 'instance creation' }
MCPClassScopeQuery class >> scope: aScope packageNames: somePackageNames classNames: someClassNames [

	^ self new
		  scope: aScope;
		  packageNames: somePackageNames;
		  classNames: someClassNames;
		  yourself
]

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

	self validate.
	scope = 'image' ifTrue: [ ^ self allClasses ].
	scope = 'packages' ifTrue: [ ^ self classesForPackageNames ].
	scope = 'classes' ifTrue: [ ^ self resolvedClassesNamed: classNames ].
	scope = 'hierarchy' ifTrue: [
		^ self hierarchyClassesNamed: classNames ].
	Error signal: 'Unsupported scope: ' , scope
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
	classNames := #(  )
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

{ #category : 'validating' }
MCPClassScopeQuery >> validate [

	self validateScopeIsOneOf:
		#( 'image' 'packages' 'hierarchy' 'classes' ).
	scope = 'packages' ifTrue: [
		packageNames ifEmpty: [
			Error signal: 'packageNames is required when scope=packages.' ] ].
	(scope = 'classes' or: [ scope = 'hierarchy' ]) ifTrue: [
		classNames ifEmpty: [
			Error signal: 'classNames is required when scope=' , scope , '.' ] ]
]
