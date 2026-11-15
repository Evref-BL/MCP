"
DTO for compact class metadata used by class queries and mutation reports.

It describes class identity, whether the behavior is a trait, package placement, slots, traits, shared variables, pools, subclasses, and layout.
"
Class {
	#name : 'MCPClassInfo',
	#superclass : 'MCPDataTransferObject',
	#instVars : [
		'className',
		'superclassName',
		'packageName',
		'tag',
		'instanceSlotNames',
		'classSlotNames',
		'subclassNames',
		'traitNames',
		'classTraitNames',
		'sharedVariableNames',
		'sharedPoolNames',
		'layoutClassName',
		'isTrait',
		'hasTag'
	],
	#category : 'MCP-IDE-DTOs',
	#package : 'MCP-IDE',
	#tag : 'DTOs'
}

{ #category : 'instance creation' }
MCPClassInfo class >> fromClass: aClass [

	^ self new initializeFromClass: aClass
]

{ #category : 'converting' }
MCPClassInfo >> asDictionary [

	| data |
	data := {
		        (#class -> self className).
		        (#superclass -> self superclassName).
		        (#package -> self packageName).
		        (#tag -> self tag).
		        (#instanceSlots -> self instanceSlotNames).
		        (#classSlots -> self classSlotNames).
		        (#traits -> self traitNames).
		        (#classTraits -> self classTraitNames).
		        (#sharedVariables -> self sharedVariableNames).
		        (#sharedPools -> self sharedPoolNames).
		        (#layout -> self layoutClassName).
		        (#subclasses -> self subclassNames) } asDictionary.
	self isTrait ifTrue: [ data at: #isTrait put: true ].
	^ data
]

{ #category : 'converting' }
MCPClassInfo >> asQueryDictionary [

	^ {
		  (#class -> self className).
		  (#package -> self packageName).
		  (#tag -> self tag).
		  (#hasTag -> self hasTag).
		  (#instanceSlots -> self instanceSlotNames).
		  (#classSlots -> self classSlotNames) } asDictionary
]

{ #category : 'accessing' }
MCPClassInfo >> className [

	^ className
]

{ #category : 'accessing' }
MCPClassInfo >> classSlotNames [

	^ classSlotNames
]

{ #category : 'accessing' }
MCPClassInfo >> classTraitNames [

	^ classTraitNames
]

{ #category : 'accessing' }
MCPClassInfo >> hasTag [
	"Whether the class is filed under a tag of its own, rather than its package's root, whose name tag still answers so that a filter on it matches as it always has."

	^ hasTag = true
]

{ #category : 'initialization' }
MCPClassInfo >> initializeFromClass: aClass [

	className := aClass name asString.
	isTrait := aClass isTrait.
	superclassName := aClass superclass ifNil: [ '' ] ifNotNil: [ :aSuperclass | aSuperclass name asString ].
	packageName := aClass package ifNil: [ '' ] ifNotNil: [ :aPackage | aPackage name asString ].
	tag := aClass packageTagName asString.
	hasTag := aClass mcpTagName isNotNil.
	instanceSlotNames := aClass slots collect: [ :each | each name asString ] as: Array.
	classSlotNames := aClass classSide slots collect: [ :each | each name asString ] as: Array.
	traitNames := aClass traits collect: [ :each | each name asString ] as: Array.
	classTraitNames := aClass classSide traits collect: [ :each | each name asString ] as: Array.
	sharedVariableNames := aClass classVarNames collect: [ :each | each asString ] as: Array.
	sharedPoolNames := aClass sharedPools collect: [ :each | each name asString ] as: Array.
	layoutClassName := aClass classLayout class name asString.
	subclassNames := (aClass subclasses collect: [ :each | each name asString ] as: Array) sort.
	^ self
]

{ #category : 'accessing' }
MCPClassInfo >> instanceSlotNames [

	^ instanceSlotNames
]

{ #category : 'accessing' }
MCPClassInfo >> isTrait [

	^ isTrait = true
]

{ #category : 'accessing' }
MCPClassInfo >> layoutClassName [

	^ layoutClassName
]

{ #category : 'accessing' }
MCPClassInfo >> packageName [

	^ packageName
]

{ #category : 'accessing' }
MCPClassInfo >> sharedPoolNames [

	^ sharedPoolNames
]

{ #category : 'accessing' }
MCPClassInfo >> sharedVariableNames [

	^ sharedVariableNames
]

{ #category : 'accessing' }
MCPClassInfo >> subclassNames [

	^ subclassNames
]

{ #category : 'accessing' }
MCPClassInfo >> superclassName [

	^ superclassName
]

{ #category : 'accessing' }
MCPClassInfo >> tag [

	^ tag
]

{ #category : 'accessing' }
MCPClassInfo >> traitNames [

	^ traitNames
]
