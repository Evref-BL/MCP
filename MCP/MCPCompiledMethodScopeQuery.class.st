Class {
	#name : 'MCPCompiledMethodScopeQuery',
	#superclass : 'Object',
	#instVars : [
		'scope',
		'packageNames',
		'classNames',
		'side'
	],
	#category : 'MCP-Internal',
	#package : 'MCP',
	#tag : 'Internal'
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
MCPCompiledMethodScopeQuery >> allCompiledMethods [

	| methods |
	methods := IdentitySet new.
	Smalltalk globals allBehaviorsDo: [ :eachBehavior |
		eachBehavior methods do: [ :eachMethod |
			(eachMethod isCompiledMethod and: [
				 self matchesSideForCompiledMethod: eachMethod ]) ifTrue: [
				methods add: eachMethod ] ] ].
	^ methods asArray
]

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> behaviorsForClassNames [

	| behaviors |
	behaviors := IdentitySet new.
	self classNames do: [ :eachName |
		self
			addBehaviorsForBaseClass:
			(Smalltalk globals at: eachName asSymbol) instanceSide
			to: behaviors ].
	^ behaviors asArray
]

{ #category : 'accessing' }
MCPCompiledMethodScopeQuery >> classNames [

	^ classNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPCompiledMethodScopeQuery >> classNames: someNames [

	classNames := self
		              normalizedStringCollection: someNames
		              argumentName: 'classNames'
]

{ #category : 'querying' }
MCPCompiledMethodScopeQuery >> compiledMethods [

	self validate.
	scope = 'image' ifTrue: [ ^ self allCompiledMethods ].
	scope = 'packages' ifTrue: [ ^ self compiledMethodsForPackageNames ].
	scope = 'classes' ifTrue: [
		^ self compiledMethodsForBehaviors: self behaviorsForClassNames ].
	scope = 'hierarchy' ifTrue: [
		^ self compiledMethodsForBehaviors:
			  self hierarchyBehaviorsForClassNames ].
	Error signal: 'Unsupported scope: ' , scope
]

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> compiledMethodsForBehaviors: behaviors [

	| methods |
	methods := IdentitySet new.
	behaviors do: [ :eachBehavior |
		eachBehavior methods do: [ :eachMethod | methods add: eachMethod ] ].
	^ methods asArray
]

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> compiledMethodsForPackageNames [

	| methods |
	methods := IdentitySet new.
	self packageNames do: [ :eachName |
		| package |
		package := eachName asPackage.
		package definedClasses do: [ :aClass |
			(side = 'instance' or: [ side = 'both' ]) ifTrue: [
				aClass localMethods do: [ :eachMethod | methods add: eachMethod ] ].
			(side = 'class' or: [ side = 'both' ]) ifTrue: [
				aClass classSide localMethods do: [ :eachMethod |
					methods add: eachMethod ] ] ].
		package extensionMethods do: [ :eachMethod |
			(self matchesSideForCompiledMethod: eachMethod) ifTrue: [
				methods add: eachMethod ] ] ].
	^ methods asArray
]

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> hierarchyBehaviorsForClassNames [

	| baseClasses behaviors hierarchyClasses |
	baseClasses := self classNames collect: [ :eachName |
		               (Smalltalk globals at: eachName asSymbol)
			               instanceSide ].
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
	scope := 'image'.
	packageNames := #(  ).
	classNames := #(  ).
	side := 'both'
]

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> matchesSideForCompiledMethod: aCompiledMethod [

	side = 'both' ifTrue: [ ^ true ].
	side = 'class' ifTrue: [ ^ aCompiledMethod methodClass isMeta ].
	^ aCompiledMethod methodClass isMeta not
]

{ #category : 'private - normalization' }
MCPCompiledMethodScopeQuery >> normalizedStringCollection: aValue argumentName: anArgumentName [

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
MCPCompiledMethodScopeQuery >> packageNames [

	^ packageNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPCompiledMethodScopeQuery >> packageNames: someNames [

	packageNames := self
		                normalizedStringCollection: someNames
		                argumentName: 'packageNames'
]

{ #category : 'accessing' }
MCPCompiledMethodScopeQuery >> scope [

	^ scope
]

{ #category : 'accessing' }
MCPCompiledMethodScopeQuery >> scope: aScope [

	| normalized |
	normalized := aScope
		              ifNil: [ 'image' ]
		              ifNotNil: [ aScope asLowercase ].
	(#( 'image' 'packages' 'hierarchy' 'classes' ) includes: normalized)
		ifFalse: [
			Error signal:
				'scope must be one of image, packages, hierarchy, or classes.' ].
	scope := normalized
]

{ #category : 'accessing' }
MCPCompiledMethodScopeQuery >> side [

	^ side
]

{ #category : 'accessing' }
MCPCompiledMethodScopeQuery >> side: aSide [

	| normalized |
	normalized := aSide ifNil: [ 'both' ] ifNotNil: [ aSide asLowercase ].
	(#( 'instance' 'class' 'both' ) includes: normalized) ifFalse: [
		Error signal: 'side must be one of instance, class, or both.' ].
	side := normalized
]

{ #category : 'validating' }
MCPCompiledMethodScopeQuery >> validate [

	scope = 'packages' ifTrue: [
		self packageNames ifEmpty: [
			Error signal: 'packageNames is required when scope=packages.' ] ].
	(scope = 'classes' or: [ scope = 'hierarchy' ]) ifTrue: [
		self classNames ifEmpty: [
			Error signal: 'classNames is required when scope=' , scope , '.' ] ]
]
