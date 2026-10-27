"
Parsed class creation request.

It captures the class definition supplied by the MCP transport request so the shared class tool implementation can execute creation without repeatedly reading raw argument dictionaries.
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
		'slotNames',
		'classSlotNames',
		'traitNames',
		'classTraitNames',
		'sharedVariableNames',
		'sharedPoolNames',
		'layout'
	],
	#category : 'MCP-IDE-Requests',
	#package : 'MCP-IDE',
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
	value := request argumentNamed: 'comment' ifAbsent: [ ^ nil ].
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

{ #category : 'converting' }
MCPClassCreateRequest >> commandForTool: aTool [

	^ MCPCreateClassToolCommand tool: aTool request: self
]

{ #category : 'initialization' }
MCPClassCreateRequest >> initializeFromRequest: request [

	className := request stringArgumentNamed: 'name'.
	superclassName := request stringArgumentNamed: 'superclass'.
	packageName := request stringArgumentNamed: 'package'.
	tag := request stringArgumentNamed: 'tag'.
	classComment := (request hasArgumentNamed: 'comment') ifTrue: [ self classCommentFromRequest: request ].
	slotNames := request stringCollectionArgumentNamed: 'slots'.
	classSlotNames := request stringCollectionArgumentNamed: 'classSlots'.
	traitNames := request stringCollectionArgumentNamed: 'traits'.
	classTraitNames := request stringCollectionArgumentNamed: 'classTraits'.
	sharedVariableNames := request stringCollectionArgumentNamed: 'sharedVariables'.
	sharedPoolNames := request stringCollectionArgumentNamed: 'sharedPools'.
	layout := request stringArgumentNamed: 'layout'
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
		  (#class -> self className).
		  (#superclass -> self superclassName).
		  (#package -> self packageName).
		  (#tag -> (self tag ifNil: [ '' ])).
		  (#comment -> (self classComment ifNil: [ '' ])).
		  (#slots -> self slotNames).
		  (#classSlots -> self classSlotNames).
		  (#traits -> self traitNames).
		  (#classTraits -> self classTraitNames).
		  (#sharedVariables -> self sharedVariableNames).
		  (#sharedPools -> self sharedPoolNames).
		  (#layout -> (self layout ifNil: [ '' ])) } asDictionary
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
	"Object when the caller omits it, because that is what a new class subclasses unless it says otherwise. Defaulting here rather than in the command keeps requestedContext and the failure messages naming the superclass the class actually gets."

	^ superclassName ifNil: [ 'Object' ]
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
