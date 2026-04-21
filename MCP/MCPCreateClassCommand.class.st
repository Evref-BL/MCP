Class {
	#name : 'MCPCreateClassCommand',
	#superclass : 'Object',
	#instVars : [
		'className',
		'superclassName',
		'packageName',
		'tag',
		'slots',
		'classSlots'
	],
	#category : 'MCP-Internal',
	#package : 'MCP',
	#tag : 'Internal'
}

{ #category : 'instance creation' }
MCPCreateClassCommand class >> className: aClassName superclassName: aSuperclassName packageName: aPackageName tag: aTag slots: someSlots classSlots: someClassSlots [

	^ self new
		  className: aClassName;
		  superclassName: aSuperclassName;
		  packageName: aPackageName;
		  tag: aTag;
		  slots: someSlots;
		  classSlots: someClassSlots;
		  yourself
]

{ #category : 'private' }
MCPCreateClassCommand >> buildClass [

	| builder createdClass |
	builder := self superclass << self className asSymbol.
	builder package: self packageName.
	self tag ifNotNil: [ builder tag: self tag ].
	builder slots: self slots.
	self classSlots ifNotEmpty: [ builder classSlots: self classSlots ].
	createdClass := builder install.
	^ createdClass
]

{ #category : 'accessing' }
MCPCreateClassCommand >> className [

	^ className
]

{ #category : 'accessing' }
MCPCreateClassCommand >> className: aString [

	className := aString
]

{ #category : 'accessing' }
MCPCreateClassCommand >> classSlots [

	^ classSlots ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPCreateClassCommand >> classSlots: someSlots [

	classSlots := self normalizedSlotNamesFrom: someSlots
]

{ #category : 'private' }
MCPCreateClassCommand >> ensurePackageNamed: aPackageName [

	self packageOrganizer ensurePackage: aPackageName
]

{ #category : 'executing' }
MCPCreateClassCommand >> execute [

	| createdClass |
	(Smalltalk globals includesKey: self className asSymbol) ifTrue: [
		MCPCommandError signalClassAlreadyExistsNamed: self className ].
	self ensurePackageNamed: self packageName.
	createdClass := self buildClass.
	^ MCPCreateClassResult classInfo:
		  (MCPClassInfo fromClass: createdClass)
]

{ #category : 'private' }
MCPCreateClassCommand >> normalizedSlotNamesFrom: someSlots [

	| rawSlots |
	rawSlots := someSlots ifNil: [ #(  ) ] ifNotNil: [ someSlots ].
	^ rawSlots collect: [ :each | each asSymbol ] as: Array
]

{ #category : 'accessing' }
MCPCreateClassCommand >> packageName [

	^ packageName
]

{ #category : 'accessing' }
MCPCreateClassCommand >> packageName: aString [

	packageName := aString
]

{ #category : 'accessing' }
MCPCreateClassCommand >> slots [

	^ slots ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPCreateClassCommand >> slots: someSlots [

	slots := self normalizedSlotNamesFrom: someSlots
]

{ #category : 'private' }
MCPCreateClassCommand >> superclass [

	^ Smalltalk globals at: self superclassName asSymbol ifAbsent: [
		  MCPCommandError
			  signalMissingSuperclassNamed: self superclassName
			  forClassNamed: self className ]
]

{ #category : 'accessing' }
MCPCreateClassCommand >> superclassName [

	^ superclassName
]

{ #category : 'accessing' }
MCPCreateClassCommand >> superclassName: aString [

	superclassName := aString
]

{ #category : 'accessing' }
MCPCreateClassCommand >> tag [

	^ tag
]

{ #category : 'accessing' }
MCPCreateClassCommand >> tag: aString [

	| normalized |
	normalized := aString
		              ifNil: [ nil ]
		              ifNotNil: [ aString asString trimBoth ].
	tag := (normalized isNil or: [ normalized isEmpty ])
		       ifTrue: [ nil ]
		       ifFalse: [ normalized ]
]
