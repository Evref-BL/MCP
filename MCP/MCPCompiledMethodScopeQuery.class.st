"
Resolves method-scope arguments into compiled methods or behavior sets.

It handles packageNames, classNames, hierarchyClassNames, subclassClassNames, parentClassNames, and side. Scope sets are unioned by default and can be intersected with scopeMode. Query tools keep valid scopes and record warnings for missing names. Tools that mutate the image can require a complete scope; missing names then raise a structured error with the same suggestions. Directional subclass and parent scopes exclude their anchor classes.
"
Class {
	#name : 'MCPCompiledMethodScopeQuery',
	#superclass : 'Object',
	#instVars : [
		'packageNames',
		'classNames',
		'side',
		'hierarchyClassNames',
		'subclassClassNames',
		'parentClassNames',
		'scopeMode',
		'warnings',
		'requiresCompleteScope'
	],
	#category : 'MCP-Queries',
	#package : 'MCP',
	#tag : 'Queries'
}

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> addBehaviorsForBaseClass: aClass to: behaviors [

	(side = 'instance' or: [ side = 'both' ]) ifTrue: [
		behaviors add: aClass instanceSide ].
	(side = 'class' or: [ side = 'both' ]) ifTrue: [
		behaviors add: aClass instanceSide classSide ]
]

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> allBehaviors [

	| behaviors |
	behaviors := IdentitySet new.
	Smalltalk globals allBehaviorsDo: [ :eachBehavior |
		(self matchesSideForBehavior: eachBehavior) ifTrue: [
			behaviors add: eachBehavior ] ].
	^ behaviors asArray
]

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> allMethods [

	^ self methodsForBehaviors: self allBehaviors
]

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> allMethodsDo: aBlock [

	| seenMethods |
	seenMethods := IdentitySet new.
	Smalltalk globals allBehaviorsDo: [ :eachBehavior |
		(self matchesSideForBehavior: eachBehavior) ifTrue: [
			eachBehavior methods do: [ :eachMethod |
				(seenMethods includes: eachMethod) ifFalse: [
					seenMethods add: eachMethod.
					aBlock value: eachMethod ] ] ] ]
]

{ #category : 'converting' }
MCPCompiledMethodScopeQuery >> asDictionary [

	^ {
		  (#packageNames -> self packageNames).
		  (#classNames -> self classNames).
		  (#hierarchyClassNames -> self hierarchyClassNames).
		  (#subclassClassNames -> self subclassClassNames).
		  (#parentClassNames -> self parentClassNames).
		  (#side -> self side) } asDictionary
]

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> behaviorScopeSets [

	| sets |
	sets := OrderedCollection new.
	self packageNames ifNotEmpty: [
		sets add: self behaviorsForPackageNames ].
	self classNames ifNotEmpty: [ sets add: self behaviorsForClassNames ].
	self hierarchyClassNames ifNotEmpty: [
		sets add: self hierarchyBehaviorsForClassNames ].
	self subclassClassNames ifNotEmpty: [
		sets add: self subclassBehaviorsForClassNames ].
	self parentClassNames ifNotEmpty: [
		sets add: self parentBehaviorsForClassNames ].
	^ sets asArray
]

{ #category : 'querying' }
MCPCompiledMethodScopeQuery >> behaviors [

	self validate.
	self resetWarnings.
	self usesImplicitImageScope ifTrue: [ ^ self allBehaviors ].
	self scopeMode = 'intersection' ifTrue: [
		^ self intersectionBehaviors ].
	^ self unionBehaviors
]

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> behaviorsForClassNames [

	| behaviors |
	behaviors := IdentitySet new.
	self classNames do: [ :eachName |
		(self classNamed: eachName inScope: 'classNames') ifNotNil: [ :class |
			self addBehaviorsForBaseClass: class instanceSide to: behaviors ] ].
	^ behaviors asArray
]

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> behaviorsForPackageNames [

	| behaviors |
	behaviors := IdentitySet new.
	self packageNames do: [ :eachName |
		(self packageNamed: eachName inScope: 'packageNames') ifNotNil: [
			:package |
			package definedClasses do: [ :aClass |
				self addBehaviorsForBaseClass: aClass to: behaviors ].
			package extensionMethods do: [ :eachMethod |
				(self matchesSideForMethod: eachMethod) ifTrue: [
					behaviors add: eachMethod methodClass ] ] ] ].
	^ behaviors asArray
]

{ #category : 'private - resolution' }
MCPCompiledMethodScopeQuery >> classNamed: aClassName [

	^ self classNamed: aClassName inScope: 'classNames'
]

{ #category : 'private - resolution' }
MCPCompiledMethodScopeQuery >> classNamed: aClassName inScope: scopeName [

	^ Smalltalk globals
		  at: aClassName asSymbol
		  ifAbsent: [
		  self recordMissingClassNamed: aClassName inScope: scopeName ]
]

{ #category : 'accessing' }
MCPCompiledMethodScopeQuery >> classNames [

	^ classNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPCompiledMethodScopeQuery >> classNames: someNames [

	classNames := someNames
		              ifNil: [ #(  ) ]
		              ifNotNil: [ someNames asArray ]
]

{ #category : 'private - source' }
MCPCompiledMethodScopeQuery >> hierarchyBehaviorsForClassNames [

	| behaviors hierarchyClasses |
	hierarchyClasses := IdentitySet new.
	self hierarchyClassNames do: [ :eachName |
		(self classNamed: eachName inScope: 'hierarchyClassNames')
			ifNotNil: [ :class |
				class instanceSide withAllSuperAndSubclasses do: [ :relatedClass |
					hierarchyClasses add: relatedClass instanceSide ] ] ].
	behaviors := IdentitySet new.
	hierarchyClasses do: [ :eachClass |
		self addBehaviorsForBaseClass: eachClass to: behaviors ].
	^ behaviors asArray
]

{ #category : 'accessing' }
MCPCompiledMethodScopeQuery >> hierarchyClassNames [

	^ hierarchyClassNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPCompiledMethodScopeQuery >> hierarchyClassNames: someNames [

	hierarchyClassNames := someNames
		                       ifNil: [ #(  ) ]
		                       ifNotNil: [ someNames asArray ]
]

{ #category : 'initialization' }
MCPCompiledMethodScopeQuery >> initialize [

	super initialize.
	packageNames := #(  ).
	classNames := #(  ).
	hierarchyClassNames := #(  ).
	subclassClassNames := #(  ).
	parentClassNames := #(  ).
	side := 'both'.
	scopeMode := 'union'.
	warnings := OrderedCollection new.
	requiresCompleteScope := false
]

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> intersectionBehaviors [

	^ (self intersectionOfSets: self behaviorScopeSets) asArray
]

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> intersectionMethods [

	^ (self intersectionOfSets: self methodScopeSets) asArray
]

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> intersectionOfSets: sets [

	| result |
	sets ifEmpty: [ ^ IdentitySet new ].
	result := sets first asIdentitySet.
	sets allButFirst do: [ :eachSet |
		result := result select: [ :eachElement |
			          eachSet includes: eachElement ] ].
	^ result
]

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> matchesSideForBehavior: aBehavior [

	side = 'both' ifTrue: [ ^ true ].
	side = 'class' ifTrue: [ ^ aBehavior isMeta ].
	^ aBehavior isMeta not
]

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> matchesSideForMethod: aCompiledMethod [

	side = 'both' ifTrue: [ ^ true ].
	side = 'class' ifTrue: [ ^ aCompiledMethod methodClass isMeta ].
	^ aCompiledMethod methodClass isMeta not
]

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> methodScopeSets [

	| sets |
	sets := OrderedCollection new.
	self packageNames ifNotEmpty: [
		sets add: self methodsForPackageNames ].
	self classNames ifNotEmpty: [
		sets add: (self methodsForBehaviors: self behaviorsForClassNames) ].
	self hierarchyClassNames ifNotEmpty: [
		sets add:
			(self methodsForBehaviors: self hierarchyBehaviorsForClassNames) ].
	self subclassClassNames ifNotEmpty: [
		sets add:
			(self methodsForBehaviors: self subclassBehaviorsForClassNames) ].
	self parentClassNames ifNotEmpty: [
		sets add:
			(self methodsForBehaviors: self parentBehaviorsForClassNames) ].
	^ sets asArray
]

{ #category : 'querying' }
MCPCompiledMethodScopeQuery >> methods [

	self validate.
	self resetWarnings.
	self usesImplicitImageScope ifTrue: [ ^ self allMethods ].
	self scopeMode = 'intersection' ifTrue: [ ^ self intersectionMethods ].
	^ self unionMethods
]

{ #category : 'querying' }
MCPCompiledMethodScopeQuery >> methodsDo: aBlock [

	| seenMethods |
	self validate.
	self usesImplicitImageScope ifTrue: [ ^ self allMethodsDo: aBlock ].
	seenMethods := IdentitySet new.
	self methods do: [ :eachMethod |
		(seenMethods includes: eachMethod) ifFalse: [
			seenMethods add: eachMethod.
			aBlock value: eachMethod ] ]
]

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> methodsForBehaviors: behaviors [

	| methods |
	methods := IdentitySet new.
	behaviors do: [ :eachBehavior |
		eachBehavior methods do: [ :eachMethod | methods add: eachMethod ] ].
	^ methods asArray
]

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> methodsForBehaviors: behaviors do: aBlock [

	| seenMethods |
	seenMethods := IdentitySet new.
	behaviors do: [ :eachBehavior |
		eachBehavior methods do: [ :eachMethod |
			(seenMethods includes: eachMethod) ifFalse: [
				seenMethods add: eachMethod.
				aBlock value: eachMethod ] ] ]
]

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> methodsForPackageNames [

	| methods |
	methods := IdentitySet new.
	self packageNames do: [ :eachName |
		(self packageNamed: eachName inScope: 'packageNames') ifNotNil: [
			:package |
			package definedClasses do: [ :aClass |
				(side = 'instance' or: [ side = 'both' ]) ifTrue: [
					aClass localMethods do: [ :eachMethod | methods add: eachMethod ] ].
				(side = 'class' or: [ side = 'both' ]) ifTrue: [
					aClass classSide localMethods do: [ :eachMethod |
						methods add: eachMethod ] ] ].
			package extensionMethods do: [ :eachMethod |
				(self matchesSideForMethod: eachMethod) ifTrue: [
					methods add: eachMethod ] ] ] ].
	^ methods asArray
]

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> methodsForPackageNamesDo: aBlock [

	| seenMethods |
	seenMethods := IdentitySet new.
	self packageNames do: [ :eachName |
		| package |
		package := self packageNamed: eachName.
		package definedClasses do: [ :aClass |
			(side = 'instance' or: [ side = 'both' ]) ifTrue: [
				aClass localMethods do: [ :eachMethod |
					(seenMethods includes: eachMethod) ifFalse: [
						seenMethods add: eachMethod.
						aBlock value: eachMethod ] ] ].
			(side = 'class' or: [ side = 'both' ]) ifTrue: [
				aClass classSide localMethods do: [ :eachMethod |
					(seenMethods includes: eachMethod) ifFalse: [
						seenMethods add: eachMethod.
						aBlock value: eachMethod ] ] ] ].
		package extensionMethods do: [ :eachMethod |
			(self matchesSideForMethod: eachMethod) ifTrue: [
				(seenMethods includes: eachMethod) ifFalse: [
					seenMethods add: eachMethod.
					aBlock value: eachMethod ] ] ] ]
]

{ #category : 'private - resolution' }
MCPCompiledMethodScopeQuery >> packageNamed: aPackageName [

	^ self packageNamed: aPackageName inScope: 'packageNames'
]

{ #category : 'private - resolution' }
MCPCompiledMethodScopeQuery >> packageNamed: aPackageName inScope: scopeName [

	(PackageOrganizer default hasPackage: aPackageName) ifFalse: [
		^ self recordMissingPackageNamed: aPackageName inScope: scopeName ].
	^ PackageOrganizer default packageNamed: aPackageName
]

{ #category : 'accessing' }
MCPCompiledMethodScopeQuery >> packageNames [

	^ packageNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPCompiledMethodScopeQuery >> packageNames: someNames [

	packageNames := someNames
		                ifNil: [ #(  ) ]
		                ifNotNil: [ someNames asArray ]
]

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> parentBehaviorsForClassNames [

	| behaviors relatedClasses |
	relatedClasses := IdentitySet new.
	self parentClassNames do: [ :eachName |
		(self classNamed: eachName inScope: 'parentClassNames') ifNotNil: [
			:class |
			class instanceSide allSuperclasses do: [ :relatedClass |
				relatedClasses add: relatedClass instanceSide ] ] ].
	behaviors := IdentitySet new.
	relatedClasses do: [ :eachClass |
		self addBehaviorsForBaseClass: eachClass to: behaviors ].
	^ behaviors asArray
]

{ #category : 'accessing' }
MCPCompiledMethodScopeQuery >> parentClassNames [

	^ parentClassNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPCompiledMethodScopeQuery >> parentClassNames: someNames [

	parentClassNames := someNames
		                    ifNil: [ #(  ) ]
		                    ifNotNil: [ someNames asArray ]
]

{ #category : 'private - resolution' }
MCPCompiledMethodScopeQuery >> recordMissingClassNamed: className inScope: scopeName [

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
MCPCompiledMethodScopeQuery >> recordMissingPackageNamed: packageName inScope: scopeName [

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
MCPCompiledMethodScopeQuery >> requireCompleteScope [

	self requiresCompleteScope: true
]

{ #category : 'accessing' }
MCPCompiledMethodScopeQuery >> requiresCompleteScope [

	^ requiresCompleteScope ifNil: [ false ]
]

{ #category : 'accessing' }
MCPCompiledMethodScopeQuery >> requiresCompleteScope: aBoolean [

	requiresCompleteScope := aBoolean = true
]

{ #category : 'private - resolution' }
MCPCompiledMethodScopeQuery >> resetWarnings [

	warnings := OrderedCollection new
]

{ #category : 'accessing' }
MCPCompiledMethodScopeQuery >> scopeMode [

	^ scopeMode ifNil: [ 'union' ]
]

{ #category : 'accessing' }
MCPCompiledMethodScopeQuery >> scopeMode: aString [

	scopeMode := aString ifNil: [ 'union' ] ifNotNil: [ aString ]
]

{ #category : 'accessing' }
MCPCompiledMethodScopeQuery >> side [

	^ side
]

{ #category : 'accessing' }
MCPCompiledMethodScopeQuery >> side: aSide [

	side := aSide ifNil: [ 'both' ] ifNotNil: [ aSide ]
]

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> subclassBehaviorsForClassNames [

	| behaviors relatedClasses |
	relatedClasses := IdentitySet new.
	self subclassClassNames do: [ :eachName |
		(self classNamed: eachName inScope: 'subclassClassNames') ifNotNil: [
			:class |
			class instanceSide allSubclasses do: [ :relatedClass |
				relatedClasses add: relatedClass instanceSide ] ] ].
	behaviors := IdentitySet new.
	relatedClasses do: [ :eachClass |
		self addBehaviorsForBaseClass: eachClass to: behaviors ].
	^ behaviors asArray
]

{ #category : 'accessing' }
MCPCompiledMethodScopeQuery >> subclassClassNames [

	^ subclassClassNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPCompiledMethodScopeQuery >> subclassClassNames: someNames [

	subclassClassNames := someNames
		                      ifNil: [ #(  ) ]
		                      ifNotNil: [ someNames asArray ]
]

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> unionBehaviors [

	| behaviors |
	behaviors := IdentitySet new.
	self behaviorScopeSets do: [ :eachSet | behaviors addAll: eachSet ].
	^ behaviors asArray
]

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> unionMethods [

	| methods |
	methods := IdentitySet new.
	self methodScopeSets do: [ :eachSet | methods addAll: eachSet ].
	^ methods asArray
]

{ #category : 'private - source' }
MCPCompiledMethodScopeQuery >> usesImplicitImageScope [

	^ self packageNames isEmpty and: [
		  self classNames isEmpty and: [
			  self hierarchyClassNames isEmpty and: [
				  self subclassClassNames isEmpty and: [
					  self parentClassNames isEmpty ] ] ] ]
]

{ #category : 'validating' }
MCPCompiledMethodScopeQuery >> validate [

	(#( 'instance' 'class' 'both' ) includes: side) ifFalse: [
		Error signal: 'side must be one of instance, class, or both.' ].
	(#( 'union' 'intersection' ) includes: self scopeMode) ifFalse: [
		Error signal: 'scopeMode must be one of union or intersection.' ]
]

{ #category : 'accessing' }
MCPCompiledMethodScopeQuery >> warnings [

	^ warnings ifNil: [ #(  ) ] ifNotNil: [ warnings asArray ]
]
