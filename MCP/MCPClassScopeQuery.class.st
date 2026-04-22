Class {
	#name : 'MCPClassScopeQuery',
	#superclass : 'Object',
	#instVars : [
		'scope',
		'packageNames',
		'classNames'
	],
	#category : 'MCP-Internal',
	#package : 'MCP',
	#tag : 'Internal'
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

	classNames := self
		              normalizedStringCollection: someClassNames
		              argumentName: 'classNames'
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
	scope := 'image'.
	packageNames := #(  ).
	classNames := #(  )
]

{ #category : 'private - normalization' }
MCPClassScopeQuery >> normalizedStringCollection: aValue argumentName: anArgumentName [

	| normalized value values |
	aValue ifNil: [ ^ #(  ) ].
	value := aValue.
	(value isString or: [ value isSymbol ]) ifTrue: [ value := { value } ].
	(value isCollection and: [ value isString not ]) ifFalse: [
		Error signal: anArgumentName , ' must be an array of strings.' ].
	values := OrderedCollection new.
	value do: [ :each |
		normalized := each asString trimBoth.
		normalized isEmpty ifFalse: [ values add: normalized ] ].
	^ values asArray
]

{ #category : 'accessing' }
MCPClassScopeQuery >> packageNames [

	^ packageNames
]

{ #category : 'accessing' }
MCPClassScopeQuery >> packageNames: somePackageNames [

	packageNames := self
		                normalizedStringCollection: somePackageNames
		                argumentName: 'packageNames'
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

{ #category : 'accessing' }
MCPClassScopeQuery >> scope [

	^ scope
]

{ #category : 'accessing' }
MCPClassScopeQuery >> scope: aScope [

	scope := aScope
		         ifNil: [ 'image' ]
		         ifNotNil: [ aScope asString asLowercase ]
]

{ #category : 'private - scope' }
MCPClassScopeQuery >> sortedClassesByName: someClasses [

	^ (someClasses asSortedCollection: [ :left :right |
		   left name <= right name ]) asArray
]

{ #category : 'validating' }
MCPClassScopeQuery >> validate [

	(#( 'image' 'packages' 'hierarchy' 'classes' ) includes: scope)
		ifFalse: [
			Error signal:
				'scope must be one of image, packages, hierarchy, or classes.' ].
	scope = 'packages' ifTrue: [
		packageNames ifEmpty: [
			Error signal: 'packageNames is required when scope=packages.' ] ].
	(scope = 'classes' or: [ scope = 'hierarchy' ]) ifTrue: [
		classNames ifEmpty: [
			Error signal: 'classNames is required when scope=' , scope , '.' ] ]
]
