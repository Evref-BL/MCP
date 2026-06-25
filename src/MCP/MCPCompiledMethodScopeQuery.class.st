"
Resolves method-scope arguments into compiled methods or behavior sets.

It handles packageNames, classNames, hierarchyClassNames, subclassClassNames, parentClassNames, and side. Scope sets are unioned. Search tools keep valid scopes and record warnings for missing names. Tools that mutate the image can require a complete scope; missing names then raise a structured error with the same suggestions. Directional subclass and parent scopes exclude their anchor classes.
"
Class {
	#name : 'MCPCompiledMethodScopeQuery',
	#superclass : 'MCPScopeQuery',
	#instVars : [
		'side'
	],
	#category : 'MCP-Queries',
	#package : 'MCP',
	#tag : 'Queries'
}

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> addBehaviorsForBaseClass: aClass to: behaviors [

	self includesInstanceSide ifTrue: [
		behaviors add: aClass instanceSide ].
	self includesClassSide ifTrue: [
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

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> includesClassSide [

	^ side = 'class' or: [ side = 'both' ]
]

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> includesInstanceSide [

	^ side = 'instance' or: [ side = 'both' ]
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
	warnings := OrderedCollection new.
	requiresCompleteScope := false
]

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> matchesSideForBehavior: aBehavior [

	aBehavior isMeta ifTrue: [ ^ self includesClassSide ].
	^ self includesInstanceSide
]

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> matchesSideForMethod: aCompiledMethod [

	aCompiledMethod methodClass isMeta ifTrue: [
		^ self includesClassSide ].
	^ self includesInstanceSide
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
							self includesInstanceSide ifTrue: [
								aClass localMethods do: [ :eachMethod |
									methods add: eachMethod ] ].
							self includesClassSide ifTrue: [
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
					self includesInstanceSide ifTrue: [
							aClass localMethods do: [ :eachMethod |
									(seenMethods includes: eachMethod) ifFalse: [
											seenMethods add: eachMethod.
											aBlock value: eachMethod ] ] ].
					self includesClassSide ifTrue: [
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
MCPCompiledMethodScopeQuery >> side [

	^ side
]

{ #category : 'accessing' }
MCPCompiledMethodScopeQuery >> side: aSide [

	side := aSide ifNil: [ 'both' ]
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

{ #category : 'validating' }
MCPCompiledMethodScopeQuery >> validate [

	(#( 'instance' 'class' 'both' ) includes: side) ifFalse: [
		Error signal: 'side must be one of instance, class, or both.' ]
]
