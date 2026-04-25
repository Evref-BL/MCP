"
Parsed edit-class update request. It uses patch semantics: omitted properties are left unchanged, while supplied properties carry the requested replacement or metadata change. suppliedProperties preserves that distinction for empty collections and empty strings.
"
Class {
	#name : 'MCPClassUpdateRequest',
	#superclass : 'Object',
	#instVars : [
		'className',
		'newClassName',
		'superclassName',
		'packageName',
		'tag',
		'classComment',
		'force',
		'slotNames',
		'classSlotNames',
		'traitNames',
		'classTraitNames',
		'sharedVariableNames',
		'sharedPoolNames',
		'layout',
		'suppliedProperties',
		'refactoringScopeSpec'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPClassUpdateRequest class >> fromRequest: request tool: aTool [

	| parsedRequest |
	parsedRequest := self new initializeFromRequest: request.
	parsedRequest refactoringScopeSpec:
		(aTool refactoringScopeSpecFromRequest: request).
	^ parsedRequest
]

{ #category : 'accessing' }
MCPClassUpdateRequest >> classComment [

	^ classComment
]

{ #category : 'private - request' }
MCPClassUpdateRequest >> classCommentFromRequest: request [

	| value |
	value := request argumentNamed: 'classComment' ifAbsent: [ ^ nil ].
	^ value ifNil: [ '' ] ifNotNil: [ value asString ]
]

{ #category : 'accessing' }
MCPClassUpdateRequest >> className [

	^ className
]

{ #category : 'accessing' }
MCPClassUpdateRequest >> classSlotNames [

	^ classSlotNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPClassUpdateRequest >> classSlots [

	^ self classSlotNames collect: #asSymbol as: Array
]

{ #category : 'accessing' }
MCPClassUpdateRequest >> classTraitNames [

	^ classTraitNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPClassUpdateRequest >> classTraits [

	^ self classTraitNames
]

{ #category : 'converting' }
MCPClassUpdateRequest >> contextValueForPropertyNamed: propertyName [

	propertyName = 'newClassName' ifTrue: [ ^ self newClassName ].
	propertyName = 'superclassName' ifTrue: [ ^ self superclassName ].
	propertyName = 'packageName' ifTrue: [ ^ self packageName ].
	propertyName = 'tag' ifTrue: [ ^ self tag ifNil: [ '' ] ].
	propertyName = 'classComment' ifTrue: [
		^ self classComment ifNil: [ '' ] ].
	propertyName = 'slots' ifTrue: [ ^ self slotNames ].
	propertyName = 'classSlots' ifTrue: [ ^ self classSlotNames ].
	propertyName = 'traits' ifTrue: [ ^ self traitNames ].
	propertyName = 'classTraits' ifTrue: [ ^ self classTraitNames ].
	propertyName = 'sharedVariables' ifTrue: [
		^ self sharedVariableNames ].
	propertyName = 'sharedPools' ifTrue: [ ^ self sharedPoolNames ].
	propertyName = 'layout' ifTrue: [ ^ self layout ifNil: [ '' ] ].
	^ nil
]

{ #category : 'private - request' }
MCPClassUpdateRequest >> definitionPropertyNames [

	^ #( 'slots' 'classSlots' 'traits' 'classTraits' 'sharedVariables'
	     'sharedPools' 'layout' )
]

{ #category : 'accessing' }
MCPClassUpdateRequest >> force [

	^ force ifNil: [ false ]
]

{ #category : 'testing' }
MCPClassUpdateRequest >> hasDefinitionUpdate [

	^ self definitionPropertyNames anySatisfy: [ :each |
		  self hasSuppliedPropertyNamed: each ]
]

{ #category : 'testing' }
MCPClassUpdateRequest >> hasSuppliedPropertyNamed: aPropertyName [

	^ self suppliedProperties includes: aPropertyName asString
]

{ #category : 'testing' }
MCPClassUpdateRequest >> hasUpdates [

	^ self suppliedProperties isNotEmpty
]

{ #category : 'initialization' }
MCPClassUpdateRequest >> initializeFromRequest: request [

	suppliedProperties := self updatePropertyNames select: [ :each |
		                      request hasArgumentNamed: each ].
	className := request stringArgumentNamed: 'className'.
	newClassName := request stringArgumentNamed: 'newClassName'.
	superclassName := request stringArgumentNamed: 'superclassName'.
	packageName := request stringArgumentNamed: 'packageName'.
	tag := request stringArgumentNamed: 'tag'.
	classComment := (self hasSuppliedPropertyNamed: 'classComment')
		                ifTrue: [ self classCommentFromRequest: request ]
		                ifFalse: [ nil ].
	force := request booleanArgumentNamed: 'force' default: false.
	slotNames := request stringCollectionArgumentNamed: 'slots'.
	classSlotNames := request stringCollectionArgumentNamed: 'classSlots'.
	traitNames := request stringCollectionArgumentNamed: 'traits'.
	classTraitNames := request stringCollectionArgumentNamed:
		                   'classTraits'.
	sharedVariableNames := request stringCollectionArgumentNamed:
		                       'sharedVariables'.
	sharedPoolNames := request stringCollectionArgumentNamed:
		                   'sharedPools'.
	layout := request stringArgumentNamed: 'layout'.
	^ self
]

{ #category : 'accessing' }
MCPClassUpdateRequest >> layout [

	^ layout
]

{ #category : 'accessing' }
MCPClassUpdateRequest >> newClassName [

	^ newClassName
]

{ #category : 'accessing' }
MCPClassUpdateRequest >> packageName [

	^ packageName
]

{ #category : 'accessing' }
MCPClassUpdateRequest >> packageName: aString [

	packageName := aString
]

{ #category : 'accessing' }
MCPClassUpdateRequest >> refactoringScopeSpec [

	^ refactoringScopeSpec
]

{ #category : 'accessing' }
MCPClassUpdateRequest >> refactoringScopeSpec: aRefactoringScopeSpec [

	refactoringScopeSpec := aRefactoringScopeSpec
]

{ #category : 'accessing' }
MCPClassUpdateRequest >> requestedClassUpdateActions [

	| actions |
	actions := OrderedCollection new.
	(self hasSuppliedPropertyNamed: 'newClassName') ifTrue: [
		actions add: 'rename' ].
	(self hasSuppliedPropertyNamed: 'superclassName') ifTrue: [
		actions add: 'reparent' ].
	((self hasSuppliedPropertyNamed: 'packageName') or: [
		 self hasSuppliedPropertyNamed: 'tag' ]) ifTrue: [
		actions add: 'move' ].
	(self hasSuppliedPropertyNamed: 'classComment') ifTrue: [
		actions add: 'setComment' ].
	self hasDefinitionUpdate ifTrue: [ actions add: 'definition' ].
	^ actions asArray
]

{ #category : 'converting' }
MCPClassUpdateRequest >> requestedContext [

	| context |
	context := Dictionary new.
	context at: #className put: self className.
	self suppliedProperties do: [ :propertyName |
		context
			at: propertyName asSymbol
			put: (self contextValueForPropertyNamed: propertyName) ].
	^ context
]

{ #category : 'accessing' }
MCPClassUpdateRequest >> sharedPoolNames [

	^ sharedPoolNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPClassUpdateRequest >> sharedPools [

	^ self sharedPoolNames
]

{ #category : 'accessing' }
MCPClassUpdateRequest >> sharedVariableNames [

	^ sharedVariableNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPClassUpdateRequest >> sharedVariables [

	^ self sharedVariableNames
]

{ #category : 'accessing' }
MCPClassUpdateRequest >> slotNames [

	^ slotNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPClassUpdateRequest >> slots [

	^ self slotNames collect: #asSymbol as: Array
]

{ #category : 'accessing' }
MCPClassUpdateRequest >> superclassName [

	^ superclassName
]

{ #category : 'accessing' }
MCPClassUpdateRequest >> suppliedDefinitionProperties [

	^ self definitionPropertyNames select: [ :each |
		  self hasSuppliedPropertyNamed: each ]
]

{ #category : 'accessing' }
MCPClassUpdateRequest >> suppliedProperties [

	^ suppliedProperties ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPClassUpdateRequest >> tag [

	^ tag
]

{ #category : 'accessing' }
MCPClassUpdateRequest >> traitNames [

	^ traitNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPClassUpdateRequest >> traits [

	^ self traitNames
]

{ #category : 'private - request' }
MCPClassUpdateRequest >> updatePropertyNames [

	^ #( 'newClassName' 'superclassName' 'packageName' 'tag' 'classComment'
	     'slots' 'classSlots' 'traits' 'classTraits' 'sharedVariables'
	     'sharedPools' 'layout' )
]
