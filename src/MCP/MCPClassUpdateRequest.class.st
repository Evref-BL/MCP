"
Parsed edit-class update request. It uses patch semantics: omitted properties are left unchanged, while supplied properties carry the requested replacement, metadata change, or slot edit. suppliedProperties preserves that distinction for empty collections and empty strings.
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
		'refactoringScopeSpec',
		'slotName',
		'newSlotName',
		'slotAction',
		'classSide'
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
MCPClassUpdateRequest >> classSide [

	^ classSide ifNil: [ false ]
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
	propertyName = 'slotAction' ifTrue: [ ^ self slotAction ].
	propertyName = 'slotName' ifTrue: [ ^ self slotName ].
	propertyName = 'newSlotName' ifTrue: [ ^ self newSlotName ].
	^ nil
]

{ #category : 'private - request' }
MCPClassUpdateRequest >> definitionPropertyNames [

	^ #( 'slots' 'classSlots' )
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
MCPClassUpdateRequest >> hasNewSlotName [

	^ self newSlotName notNil
]

{ #category : 'testing' }
MCPClassUpdateRequest >> hasSlotName [

	^ self slotName notNil
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
	slotName := request stringArgumentNamed: 'slotName'.
	newSlotName := request stringArgumentNamed: 'newSlotName'.
	slotAction := request stringArgumentNamed: 'slotAction'.
	classSide := request booleanArgumentNamed: 'classSide' default: false.
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
MCPClassUpdateRequest >> newSlotName [

	^ newSlotName
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

{ #category : 'converting' }
MCPClassUpdateRequest >> renameSlotRequestedContext [

	| context |
	context := self slotRequestedContext.
	context at: #newSlotName put: self newSlotName.
	^ context
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
	(self hasSuppliedPropertyNamed: 'traits') ifTrue: [
		actions add: 'replaceTraits' ].
	(self hasSuppliedPropertyNamed: 'classTraits') ifTrue: [
		actions add: 'replaceClassTraits' ].
	(self hasSuppliedPropertyNamed: 'sharedVariables') ifTrue: [
		actions add: 'replaceSharedVariables' ].
	(self hasSuppliedPropertyNamed: 'sharedPools') ifTrue: [
		actions add: 'replaceSharedPools' ].
	(self hasSuppliedPropertyNamed: 'layout') ifTrue: [
		actions add: 'replaceLayout' ].
	self hasDefinitionUpdate ifTrue: [ actions add: 'replaceDefinition' ].
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
MCPClassUpdateRequest >> slotAction [

	^ slotAction
]

{ #category : 'accessing' }
MCPClassUpdateRequest >> slotName [

	^ slotName
]

{ #category : 'accessing' }
MCPClassUpdateRequest >> slotNames [

	^ slotNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPClassUpdateRequest >> slotOperation [

	| operations |
	self slotAction ifNil: [ ^ nil ].
	operations := {
		              ('add' -> 'addSlot').
		              ('remove' -> 'removeSlot').
		              ('rename' -> 'renameSlot').
		              ('pullUp' -> 'pullUpSlot').
		              ('pushDown' -> 'pushDownSlot') } asDictionary.
	^ operations at: self slotAction ifAbsent: [
		  MCPCommandError
			  signalErrorCode: #InvalidSlotAction
			  message:
			  'slotAction must be one of add, remove, rename, pullUp, pushDown.'
			  details: self slotRequestedContext ]
]

{ #category : 'converting' }
MCPClassUpdateRequest >> slotRequestedContext [

	| context |
	context := {
		           (#className -> self className).
		           (#slotName -> self slotName).
		           (#classSide -> self classSide) } asDictionary.
	self slotAction ifNotNil: [
		context at: #slotAction put: self slotAction ].
	^ context
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
	     'sharedPools' 'layout' 'slotAction' 'slotName' 'newSlotName' )
]

{ #category : 'validating' }
MCPClassUpdateRequest >> validateSlotUpdate [

	| operation |
	operation := self slotOperation.
	operation ifNil: [
		(self hasSlotName or: [ self hasNewSlotName ]) ifTrue: [
			MCPCommandError
				signalErrorCode: #SlotActionRequired
				message:
				'slotAction is required when slotName or newSlotName is provided for update.'
				details: self slotRequestedContext ].
		^ self ].
	self hasSlotName ifFalse: [
		MCPCommandError
			signalErrorCode: #SlotNameRequired
			message: 'slotName is required for slot updates.'
			details: self slotRequestedContext ].
	(operation = 'renameSlot' and: [ self hasNewSlotName not ]) ifTrue: [
		MCPCommandError
			signalErrorCode: #NewSlotNameRequired
			message: 'newSlotName is required when slotAction=rename.'
			details: self slotRequestedContext ].
	(operation ~= 'renameSlot' and: [ self hasNewSlotName ]) ifTrue: [
		MCPCommandError
			signalErrorCode: #UnexpectedNewSlotName
			message: 'newSlotName is only accepted when slotAction=rename.'
			details: self slotRequestedContext ].
	^ self
]

{ #category : 'converting' }
MCPClassUpdateRequest >> validationContext [

	| context slotContext |
	context := self requestedContext copy.
	slotContext := self slotRequestedContext.
	slotContext keysAndValuesDo: [ :key :value |
		value ifNotNil: [ context at: key ifAbsentPut: [ value ] ] ].
	^ context
]
