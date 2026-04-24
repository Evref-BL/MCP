Class {
	#name : 'MCPCompiledMethodScopeQuery',
	#superclass : 'MCPScopeQuery',
	#instVars : [
		'packageNames',
		'classNames',
		'side'
	],
	#category : 'MCP-Queries',
	#package : 'MCP',
	#tag : 'Queries'
}

{ #category : 'instance creation' }
MCPCompiledMethodScopeQuery class >> scope: aScope packageNames: somePackageNames classNames: someClassNames side: aSide [

	^ self new
		  scope: aScope;
		  packageNames: somePackageNames;
		  classNames: someClassNames;
		  side: aSide;
		  yourself
]

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

	self validate.
	scope = 'image' ifTrue: [ ^ self allBehaviors ].
	scope = 'packages' ifTrue: [ ^ self behaviorsForPackageNames ].
	scope = 'classes' ifTrue: [ ^ self behaviorsForClassNames ].
	scope = 'hierarchy' ifTrue: [ ^ self hierarchyBehaviorsForClassNames ].
	Error signal: 'Unsupported scope: ' , scope
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

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> hierarchyBehaviorsForClassNames [

	| baseClasses behaviors hierarchyClasses |
	baseClasses := self classNames collect: [ :eachName |
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

{ #category : 'initialization' }
MCPCompiledMethodScopeQuery >> initialize [

	super initialize.
	packageNames := #(  ).
	classNames := #(  ).
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

	self validate.
	scope = 'image' ifTrue: [ ^ self allMethods ].
	scope = 'packages' ifTrue: [ ^ self methodsForPackageNames ].
	scope = 'classes' ifTrue: [
		^ self methodsForBehaviors: self behaviorsForClassNames ].
	scope = 'hierarchy' ifTrue: [
		^ self methodsForBehaviors:
			  self hierarchyBehaviorsForClassNames ].
	Error signal: 'Unsupported scope: ' , scope
]

{ #category : 'querying' }
MCPCompiledMethodScopeQuery >> methodsDo: aBlock [

	self validate.
	scope = 'image' ifTrue: [ ^ self allMethodsDo: aBlock ].
	scope = 'packages' ifTrue: [
		^ self methodsForPackageNamesDo: aBlock ].
	scope = 'classes' ifTrue: [
		^ self
			  methodsForBehaviors: self behaviorsForClassNames
			  do: aBlock ].
	scope = 'hierarchy' ifTrue: [
		^ self
			  methodsForBehaviors: self hierarchyBehaviorsForClassNames
			  do: aBlock ].
	Error signal: 'Unsupported scope: ' , scope
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

{ #category : 'accessing' }
MCPCompiledMethodScopeQuery >> side [

	^ side
]

{ #category : 'accessing' }
MCPCompiledMethodScopeQuery >> side: aSide [

	side := aSide ifNil: [ 'both' ] ifNotNil: [ aSide ]
]

{ #category : 'validating' }
MCPCompiledMethodScopeQuery >> validate [

	self validateScopeIsOneOf:
		#( 'image' 'packages' 'hierarchy' 'classes' ).
	(#( 'instance' 'class' 'both' ) includes: side) ifFalse: [
		Error signal: 'side must be one of instance, class, or both.' ].
	scope = 'packages' ifTrue: [
		self packageNames ifEmpty: [
			Error signal: 'packageNames is required when scope=packages.' ] ].
	(scope = 'classes' or: [ scope = 'hierarchy' ]) ifTrue: [
		self classNames ifEmpty: [
			Error signal: 'classNames is required when scope=' , scope , '.' ] ]
]
