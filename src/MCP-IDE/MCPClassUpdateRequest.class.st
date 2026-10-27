"
Parsed class update request.

It uses patch semantics: omitted properties are left unchanged, while supplied properties carry the requested replacement, metadata change, or slot update. suppliedProperties preserves that distinction for empty collections and empty strings.
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
		'slotDelta',
		'classSlotDelta',
		'traitNames',
		'classTraitNames',
		'sharedVariableNames',
		'sharedPoolNames',
		'layout',
		'suppliedProperties',
		'refactoringScopeSpec'
	],
	#category : 'MCP-IDE-Requests',
	#package : 'MCP-IDE',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPClassUpdateRequest class >> fromRequest: request tool: aTool [

	| parsedRequest |
	parsedRequest := self new initializeFromRequest: request.
	parsedRequest refactoringScopeSpec: (aTool refactoringScopeSpecFromRequest: request).
	^ parsedRequest
]

{ #category : 'accessing' }
MCPClassUpdateRequest >> classComment [

	^ classComment
]

{ #category : 'private - request' }
MCPClassUpdateRequest >> classCommentFromRequest: request [

	| value |
	value := request argumentNamed: 'comment' ifAbsent: [ ^ nil ].
	^ value ifNil: [ '' ] ifNotNil: [ value asString ]
]

{ #category : 'accessing' }
MCPClassUpdateRequest >> className [

	^ className
]

{ #category : 'accessing' }
MCPClassUpdateRequest >> classSlotDelta [

	^ classSlotDelta
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
MCPClassUpdateRequest >> commandForTool: aTool [

	^ MCPUpdateClassCommand tool: aTool request: self
]

{ #category : 'private - request' }
MCPClassUpdateRequest >> contextValueForPropertyNamed: propertyName [

	propertyName = 'newName' ifTrue: [ ^ self newClassName ].
	propertyName = 'superclass' ifTrue: [ ^ self superclassName ].
	propertyName = 'package' ifTrue: [ ^ self packageName ].
	propertyName = 'tag' ifTrue: [ ^ self tag ifNil: [ '' ] ].
	propertyName = 'comment' ifTrue: [ ^ self classComment ifNil: [ '' ] ].
	propertyName = 'slots' ifTrue: [ ^ self slotDelta ifNotNil: [ :delta | delta asContextValue ] ].
	propertyName = 'classSlots' ifTrue: [ ^ self classSlotDelta ifNotNil: [ :delta | delta asContextValue ] ].
	propertyName = 'traits' ifTrue: [ ^ self traitNames ].
	propertyName = 'classTraits' ifTrue: [ ^ self classTraitNames ].
	propertyName = 'sharedVariables' ifTrue: [ ^ self sharedVariableNames ].
	propertyName = 'sharedPools' ifTrue: [ ^ self sharedPoolNames ].
	propertyName = 'layout' ifTrue: [ ^ self layout ifNil: [ '' ] ].
	^ nil
]

{ #category : 'accessing' }
MCPClassUpdateRequest >> deltaForSide: aBoolean [

	^ aBoolean
		  ifTrue: [ self classSlotDelta ]
		  ifFalse: [ self slotDelta ]
]

{ #category : 'accessing' }
MCPClassUpdateRequest >> force [

	^ force ifNil: [ false ]
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

	suppliedProperties := self updatePropertyNames select: [ :each | request hasArgumentNamed: each ].
	className := request stringArgumentNamed: 'name'.
	newClassName := request stringArgumentNamed: 'newName'.
	superclassName := request stringArgumentNamed: 'superclass'.
	packageName := request stringArgumentNamed: 'package'.
	tag := request stringArgumentNamed: 'tag'.
	classComment := (self hasSuppliedPropertyNamed: 'comment') ifTrue: [ self classCommentFromRequest: request ].
	force := request booleanArgumentNamed: 'force' default: false.
	slotDelta := MCPSlotDelta fromRequest: request named: 'slots'.
	classSlotDelta := MCPSlotDelta fromRequest: request named: 'classSlots'.
	traitNames := request stringCollectionArgumentNamed: 'traits'.
	classTraitNames := request stringCollectionArgumentNamed: 'classTraits'.
	sharedVariableNames := request stringCollectionArgumentNamed: 'sharedVariables'.
	sharedPoolNames := request stringCollectionArgumentNamed: 'sharedPools'.
	layout := request stringArgumentNamed: 'layout'
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
	"The actions the scalar and stateless-collection properties ask for. Slot operations come from the deltas, which the command expands one slot at a time."

	| actions |
	actions := OrderedCollection new.
	(self hasSuppliedPropertyNamed: 'newName') ifTrue: [ actions add: 'rename' ].
	(self hasSuppliedPropertyNamed: 'superclass') ifTrue: [ actions add: 'reparent' ].
	((self hasSuppliedPropertyNamed: 'package') or: [ self hasSuppliedPropertyNamed: 'tag' ]) ifTrue: [ actions add: 'move' ].
	(self hasSuppliedPropertyNamed: 'comment') ifTrue: [ actions add: 'setComment' ].
	(self hasSuppliedPropertyNamed: 'traits') ifTrue: [ actions add: 'replaceTraits' ].
	(self hasSuppliedPropertyNamed: 'classTraits') ifTrue: [ actions add: 'replaceClassTraits' ].
	(self hasSuppliedPropertyNamed: 'sharedVariables') ifTrue: [ actions add: 'replaceSharedVariables' ].
	(self hasSuppliedPropertyNamed: 'sharedPools') ifTrue: [ actions add: 'replaceSharedPools' ].
	(self hasSuppliedPropertyNamed: 'layout') ifTrue: [ actions add: 'replaceLayout' ].
	^ actions asArray
]

{ #category : 'converting' }
MCPClassUpdateRequest >> requestedContext [

	| context |
	context := Dictionary new.
	context at: #name put: self className.
	self suppliedProperties do: [ :propertyName |
		context at: propertyName asSymbol put: (self contextValueForPropertyNamed: propertyName) ].
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
MCPClassUpdateRequest >> slotDelta [

	^ slotDelta
]

{ #category : 'accessing' }
MCPClassUpdateRequest >> superclassName [

	^ superclassName
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

	^ #( 'newName' 'superclass' 'package' 'tag' 'comment' 'slots' 'classSlots' 'traits' 'classTraits' 'sharedVariables'
	     'sharedPools' 'layout' )
]

{ #category : 'converting' }
MCPClassUpdateRequest >> validationContext [

	^ self requestedContext
]
