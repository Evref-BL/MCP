"
Resolves class-scope arguments into class sets.

It handles packageNames, classNames, hierarchyClassNames, subclassClassNames, and parentClassNames. Scope sets are unioned. Query tools keep valid scopes and record warnings for missing names. Tools that mutate the image can require a complete scope; missing names then raise a structured error with the same suggestions. Directional subclass and parent scopes exclude their anchor classes.
"
Class {
	#name : 'MCPClassScopeQuery',
	#superclass : 'Object',
	#instVars : [
		'packageNames',
		'classNames',
		'hierarchyClassNames',
		'subclassClassNames',
		'parentClassNames',
		'warnings',
		'requiresCompleteScope'
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

{ #category : 'private - scope' }
MCPClassScopeQuery >> classScopeSets [

	| sets |
	sets := OrderedCollection new.
	self packageNames ifNotEmpty: [
		sets add: self classesForPackageNames ].
	self classNames ifNotEmpty: [
		sets add:
			(self resolvedClassesNamed: self classNames inScope: 'classNames') ].
	self hierarchyClassNames ifNotEmpty: [
		sets add: (self hierarchyClassesNamed: self hierarchyClassNames) ].
	self subclassClassNames ifNotEmpty: [
		sets add: (self subclassClassesNamed: self subclassClassNames) ].
	self parentClassNames ifNotEmpty: [
		sets add: (self parentClassesNamed: self parentClassNames) ].
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
		(self resolvedPackageNamed: eachName inScope: 'packageNames')
			ifNotNil: [ :package |
				package classes do: [ :eachClass |
					classes add: eachClass instanceSide ] ] ].
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
	(self
		 resolvedClassesNamed: someClassNames
		 inScope: 'hierarchyClassNames') do: [ :eachClass |
		eachClass withAllSuperAndSubclasses do: [ :relatedClass |
			classes add: relatedClass instanceSide ] ].
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

{ #category : 'accessing' }
MCPClassScopeQuery >> parentClassNames [

	^ parentClassNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPClassScopeQuery >> parentClassNames: someClassNames [

	parentClassNames := someClassNames
		                    ifNil: [ #(  ) ]
		                    ifNotNil: [ someClassNames asArray ]
]

{ #category : 'private - scope' }
MCPClassScopeQuery >> parentClassesNamed: someClassNames [

	| classes |
	classes := IdentitySet new.
	(self
		 resolvedClassesNamed: someClassNames
		 inScope: 'parentClassNames') do: [ :eachClass |
		eachClass allSuperclasses do: [ :relatedClass |
			classes add: relatedClass instanceSide ] ].
	^ self sortedClassesByName: classes
]

{ #category : 'private - resolution' }
MCPClassScopeQuery >> recordMissingClassNamed: className inScope: scopeName [

	| suggestions |
	suggestions := MCPScopeNameSuggester classSuggestionsFor: className.
	self requiresCompleteScope ifTrue: [
		^ MCPCommandError
			  signalMissingClassNamed: className
			  scopeName: scopeName ].
	warnings ifNil: [ self resetWarnings ].
	warnings add: (MCPScopeNameSuggester
			 missingNameWarningForKind: 'Class'
			 name: className
			 scope: scopeName
			 suggestions: suggestions).
	^ nil
]

{ #category : 'private - resolution' }
MCPClassScopeQuery >> recordMissingPackageNamed: packageName inScope: scopeName [

	| suggestions |
	suggestions := MCPScopeNameSuggester packageSuggestionsFor:
		               packageName.
	self requiresCompleteScope ifTrue: [
		^ MCPCommandError
			  signalMissingPackageNamed: packageName
			  scopeName: scopeName ].
	warnings ifNil: [ self resetWarnings ].
	warnings add: (MCPScopeNameSuggester
			 missingNameWarningForKind: 'Package'
			 name: packageName
			 scope: scopeName
			 suggestions: suggestions).
	^ nil
]

{ #category : 'configuring' }
MCPClassScopeQuery >> requireCompleteScope [

	self requiresCompleteScope: true
]

{ #category : 'accessing' }
MCPClassScopeQuery >> requiresCompleteScope [

	^ requiresCompleteScope ifNil: [ false ]
]

{ #category : 'accessing' }
MCPClassScopeQuery >> requiresCompleteScope: aBoolean [

	requiresCompleteScope := aBoolean = true
]

{ #category : 'private - resolution' }
MCPClassScopeQuery >> resetWarnings [

	warnings := OrderedCollection new
]

{ #category : 'private - resolution' }
MCPClassScopeQuery >> resolvedClassNamed: className [

	^ self resolvedClassNamed: className inScope: 'classes'
]

{ #category : 'private - resolution' }
MCPClassScopeQuery >> resolvedClassNamed: className inScope: scopeName [

	^ Smalltalk globals
		  at: className asSymbol
		  ifAbsent: [
		  self recordMissingClassNamed: className inScope: scopeName ]
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
		(self resolvedClassNamed: eachName inScope: scopeName) ifNotNil: [
			:resolvedClass | classes add: resolvedClass instanceSide ] ].
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
		  ifAbsent: [
		  self recordMissingPackageNamed: packageName inScope: scopeName ]
]

{ #category : 'private - scope' }
MCPClassScopeQuery >> sortedClassesByName: someClasses [

	^ (someClasses asSortedCollection: [ :left :right |
		   left name <= right name ]) asArray
]

{ #category : 'accessing' }
MCPClassScopeQuery >> subclassClassNames [

	^ subclassClassNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPClassScopeQuery >> subclassClassNames: someClassNames [

	subclassClassNames := someClassNames
		                      ifNil: [ #(  ) ]
		                      ifNotNil: [ someClassNames asArray ]
]

{ #category : 'private - scope' }
MCPClassScopeQuery >> subclassClassesNamed: someClassNames [

	| classes |
	classes := IdentitySet new.
	(self
		 resolvedClassesNamed: someClassNames
		 inScope: 'subclassClassNames') do: [ :eachClass |
		eachClass allSubclasses do: [ :relatedClass |
			classes add: relatedClass instanceSide ] ].
	^ self sortedClassesByName: classes
]

{ #category : 'private - scope' }
MCPClassScopeQuery >> unionClasses [

	| classes |
	classes := IdentitySet new.
	self classScopeSets do: [ :eachSet | classes addAll: eachSet ].
	^ self sortedClassesByName: classes
]

{ #category : 'private - source' }
MCPClassScopeQuery >> usesImplicitImageScope [

	^ self packageNames isEmpty and: [
		  self classNames isEmpty and: [
			  self hierarchyClassNames isEmpty and: [
				  self subclassClassNames isEmpty and: [
					  self parentClassNames isEmpty ] ] ] ]
]

{ #category : 'accessing' }
MCPClassScopeQuery >> warnings [

	^ warnings ifNil: [ #(  ) ] ifNotNil: [ warnings asArray ]
]
