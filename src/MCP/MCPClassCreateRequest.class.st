"
Parsed edit-class create request. It captures the class definition supplied by the MCP transport request so MCPToolEditClass can execute creation without repeatedly reading raw argument dictionaries.
"
Class {
	#name : 'MCPClassCreateRequest',
	#superclass : 'Object',
	#instVars : [
		'className',
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
		'layout'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPClassCreateRequest class >> fromRequest: request tool: aTool [

	^ self new initializeFromRequest: request
]

{ #category : 'accessing' }
MCPClassCreateRequest >> classComment [

	^ classComment
]

{ #category : 'private - request' }
MCPClassCreateRequest >> classCommentFromRequest: request [

	| value |
	value := request argumentNamed: 'classComment' ifAbsent: [ ^ nil ].
	^ value ifNil: [ '' ] ifNotNil: [ value asString ]
]

{ #category : 'accessing' }
MCPClassCreateRequest >> className [

	^ className
]

{ #category : 'accessing' }
MCPClassCreateRequest >> classSlotNames [

	^ classSlotNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPClassCreateRequest >> classSlots [

	^ self classSlotNames collect: #asSymbol as: Array
]

{ #category : 'accessing' }
MCPClassCreateRequest >> classTraitNames [

	^ classTraitNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPClassCreateRequest >> classTraits [

	^ self classTraitNames
]

{ #category : 'accessing' }
MCPClassCreateRequest >> force [

	^ force ifNil: [ false ]
]

{ #category : 'initialization' }
MCPClassCreateRequest >> initializeFromRequest: request [

	className := request stringArgumentNamed: 'className'.
	superclassName := request stringArgumentNamed: 'superclassName'.
	packageName := request stringArgumentNamed: 'packageName'.
	tag := request stringArgumentNamed: 'tag'.
	classComment := (request hasArgumentNamed: 'classComment')
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
MCPClassCreateRequest >> layout [

	^ layout
]

{ #category : 'accessing' }
MCPClassCreateRequest >> packageName [

	^ packageName
]

{ #category : 'converting' }
MCPClassCreateRequest >> requestedContext [

	^ {
		  (#className -> self className).
		  (#superclassName -> self superclassName).
		  (#packageName -> self packageName).
		  (#tag -> (self tag ifNil: [ '' ] ifNotNil: [ self tag ])).
		  (#classComment
		   ->
		   (self classComment ifNil: [ '' ] ifNotNil: [ self classComment ])).
		  (#slots -> self slotNames).
		  (#classSlots -> self classSlotNames).
		  (#traits -> self traitNames).
		  (#classTraits -> self classTraitNames).
		  (#sharedVariables -> self sharedVariableNames).
		  (#sharedPools -> self sharedPoolNames).
		  (#layout -> (self layout ifNil: [ '' ] ifNotNil: [ self layout ])) }
		  asDictionary
]

{ #category : 'accessing' }
MCPClassCreateRequest >> sharedPoolNames [

	^ sharedPoolNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPClassCreateRequest >> sharedPools [

	^ self sharedPoolNames
]

{ #category : 'accessing' }
MCPClassCreateRequest >> sharedVariableNames [

	^ sharedVariableNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPClassCreateRequest >> sharedVariables [

	^ self sharedVariableNames
]

{ #category : 'accessing' }
MCPClassCreateRequest >> slotNames [

	^ slotNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPClassCreateRequest >> slots [

	^ self slotNames collect: #asSymbol as: Array
]

{ #category : 'accessing' }
MCPClassCreateRequest >> superclassName [

	^ superclassName
]

{ #category : 'accessing' }
MCPClassCreateRequest >> tag [

	^ tag
]

{ #category : 'accessing' }
MCPClassCreateRequest >> traitNames [

	^ traitNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPClassCreateRequest >> traits [

	^ self traitNames
]
