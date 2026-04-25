"
Parsed scope query for method listings and reference lookup.

It resolves packageNames, classNames, hierarchyClassNames, subclassClassNames, parentClassNames, and side into a union of compiled methods. Directional subclass and parent scopes exclude their anchor classes.
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
		'parentClassNames'
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

{ #category : 'querying' }
MCPCompiledMethodScopeQuery >> behaviors [

	| behaviors hierarchyRoots parentRoots subclassRoots |
	self validate.
	self usesImplicitImageScope ifTrue: [ ^ self allBehaviors ].
	behaviors := IdentitySet new.
	self packageNames ifNotEmpty: [
		behaviors addAll: self behaviorsForPackageNames ].
	self classNames ifNotEmpty: [
		behaviors addAll: self behaviorsForClassNames ].
	hierarchyRoots := self hierarchyClassNames.
	hierarchyRoots ifNotEmpty: [
		behaviors addAll: self hierarchyBehaviorsForClassNames ].
	subclassRoots := self subclassClassNames.
	subclassRoots ifNotEmpty: [
		behaviors addAll: self subclassBehaviorsForClassNames ].
	parentRoots := self parentClassNames.
	parentRoots ifNotEmpty: [
		behaviors addAll: self parentBehaviorsForClassNames ].
	^ behaviors asArray
]

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> behaviorsForClassNames [

	| behaviors |
	behaviors := IdentitySet new.
	self classNames do: [ :eachName |
		self
			addBehaviorsForBaseClass: (self classNamed: eachName) instanceSide
			to: behaviors ].
	^ behaviors asArray
]

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> behaviorsForPackageNames [

	| behaviors |
	behaviors := IdentitySet new.
	self packageNames do: [ :eachName |
		| package |
		package := self packageNamed: eachName.
		package definedClasses do: [ :aClass |
			self addBehaviorsForBaseClass: aClass to: behaviors ].
		package extensionMethods do: [ :eachMethod |
			(self matchesSideForMethod: eachMethod) ifTrue: [
				behaviors add: eachMethod methodClass ] ] ].
	^ behaviors asArray
]

{ #category : 'private - resolution' }
MCPCompiledMethodScopeQuery >> classNamed: aClassName [

	^ Smalltalk globals
		  at: aClassName asSymbol
		  ifAbsent: [ MCPCommandError signalMissingClassNamed: aClassName ]
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

	| baseClasses behaviors hierarchyClasses |
	baseClasses := self hierarchyClassNames collect: [ :eachName |
		               (self classNamed: eachName) instanceSide ].
	hierarchyClasses := IdentitySet new.
	baseClasses do: [ :eachClass |
		eachClass withAllSuperAndSubclasses do: [ :relatedClass |
			hierarchyClasses add: relatedClass instanceSide ] ].
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
	side := 'both'
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

{ #category : 'querying' }
MCPCompiledMethodScopeQuery >> methods [

	| hierarchyRoots methods parentRoots subclassRoots |
	self validate.
	self usesImplicitImageScope ifTrue: [ ^ self allMethods ].
	methods := IdentitySet new.
	self packageNames ifNotEmpty: [
		methods addAll: self methodsForPackageNames ].
	self classNames ifNotEmpty: [
		methods addAll:
			(self methodsForBehaviors: self behaviorsForClassNames) ].
	hierarchyRoots := self hierarchyClassNames.
	hierarchyRoots ifNotEmpty: [
		methods addAll:
			(self methodsForBehaviors: self hierarchyBehaviorsForClassNames) ].
	subclassRoots := self subclassClassNames.
	subclassRoots ifNotEmpty: [
		methods addAll:
			(self methodsForBehaviors: self subclassBehaviorsForClassNames) ].
	parentRoots := self parentClassNames.
	parentRoots ifNotEmpty: [
		methods addAll:
			(self methodsForBehaviors: self parentBehaviorsForClassNames) ].
	^ methods asArray
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
		| package |
		package := self packageNamed: eachName.
		package definedClasses do: [ :aClass |
			(side = 'instance' or: [ side = 'both' ]) ifTrue: [
				aClass localMethods do: [ :eachMethod | methods add: eachMethod ] ].
			(side = 'class' or: [ side = 'both' ]) ifTrue: [
				aClass classSide localMethods do: [ :eachMethod |
					methods add: eachMethod ] ] ].
		package extensionMethods do: [ :eachMethod |
			(self matchesSideForMethod: eachMethod) ifTrue: [
				methods add: eachMethod ] ] ].
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

	(PackageOrganizer default hasPackage: aPackageName) ifFalse: [
		MCPCommandError signalMissingPackageNamed: aPackageName ].
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

	| baseClasses behaviors relatedClasses |
	baseClasses := self parentClassNames collect: [ :eachName |
		               (self classNamed: eachName) instanceSide ].
	relatedClasses := IdentitySet new.
	baseClasses do: [ :eachClass |
		eachClass allSuperclasses do: [ :relatedClass |
			relatedClasses add: relatedClass instanceSide ] ].
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

	| baseClasses behaviors relatedClasses |
	baseClasses := self subclassClassNames collect: [ :eachName |
		               (self classNamed: eachName) instanceSide ].
	relatedClasses := IdentitySet new.
	baseClasses do: [ :eachClass |
		eachClass allSubclasses do: [ :relatedClass |
			relatedClasses add: relatedClass instanceSide ] ].
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
		Error signal: 'side must be one of instance, class, or both.' ]
]
