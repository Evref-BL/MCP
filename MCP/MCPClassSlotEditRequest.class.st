"
Parsed edit-class slot request. It captures the common slot-edit arguments used by add, remove, rename, pull-up, and push-down operations so the tool execution methods do not read raw MCPToolRequest dictionaries.
"
Class {
	#name : 'MCPClassSlotEditRequest',
	#superclass : 'Object',
	#instVars : [
		'className',
		'slotName',
		'newSlotName',
		'classSide',
		'force',
		'slotAction'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPClassSlotEditRequest class >> fromRequest: request tool: aTool [

	^ self new initializeFromRequest: request
]

{ #category : 'accessing' }
MCPClassSlotEditRequest >> className [

	^ className
]

{ #category : 'accessing' }
MCPClassSlotEditRequest >> classSide [

	^ classSide ifNil: [ false ]
]

{ #category : 'accessing' }
MCPClassSlotEditRequest >> force [

	^ force ifNil: [ false ]
]

{ #category : 'testing' }
MCPClassSlotEditRequest >> hasNewSlotName [

	^ self newSlotName notNil
]

{ #category : 'testing' }
MCPClassSlotEditRequest >> hasSlotName [

	^ self slotName notNil
]

{ #category : 'initialization' }
MCPClassSlotEditRequest >> initializeFromRequest: request [

	className := request stringArgumentNamed: 'className'.
	slotName := request stringArgumentNamed: 'slotName'.
	newSlotName := request stringArgumentNamed: 'newSlotName'.
	slotAction := request stringArgumentNamed: 'slotAction'.
	classSide := request booleanArgumentNamed: 'classSide' default: false.
	force := request booleanArgumentNamed: 'force' default: false.
	^ self
]

{ #category : 'accessing' }
MCPClassSlotEditRequest >> newSlotName [

	^ newSlotName
]

{ #category : 'converting' }
MCPClassSlotEditRequest >> renameRequestedContext [

	| context |
	context := self requestedContext.
	context at: #newSlotName put: self newSlotName.
	^ context
]

{ #category : 'converting' }
MCPClassSlotEditRequest >> requestedContext [

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
MCPClassSlotEditRequest >> slotAction [

	^ slotAction
]

{ #category : 'accessing' }
MCPClassSlotEditRequest >> slotName [

	^ slotName
]

{ #category : 'accessing' }
MCPClassSlotEditRequest >> slotOperation [

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
			  details: self requestedContext ]
]

{ #category : 'validating' }
MCPClassSlotEditRequest >> validateForUpdate [

	| operation |
	operation := self slotOperation.
	operation ifNil: [
		(self hasSlotName or: [ self hasNewSlotName ]) ifTrue: [
			MCPCommandError
				signalErrorCode: #SlotActionRequired
				message:
				'slotAction is required when slotName or newSlotName is provided for update.'
				details: self requestedContext ].
		^ self ].
	self hasSlotName ifFalse: [
		MCPCommandError
			signalErrorCode: #SlotNameRequired
			message: 'slotName is required for slot updates.'
			details: self requestedContext ].
	(operation = 'renameSlot' and: [ self hasNewSlotName not ]) ifTrue: [
		MCPCommandError
			signalErrorCode: #NewSlotNameRequired
			message: 'newSlotName is required when slotAction=rename.'
			details: self requestedContext ].
	(operation ~= 'renameSlot' and: [ self hasNewSlotName ]) ifTrue: [
		MCPCommandError
			signalErrorCode: #UnexpectedNewSlotName
			message: 'newSlotName is only accepted when slotAction=rename.'
			details: self requestedContext ].
	^ self
]
