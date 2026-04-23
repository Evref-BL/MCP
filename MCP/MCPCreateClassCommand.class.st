Class {
	#name : 'MCPCreateClassCommand',
	#superclass : 'Object',
	#instVars : [
		'className',
		'superclassName',
		'packageName',
		'tag',
		'slots',
		'classSlots',
		'traits',
		'classTraits',
		'sharedVariables',
		'sharedPools',
		'layout'
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

{ #category : 'instance creation' }
MCPCreateClassCommand class >> className: aClassName superclassName: aSuperclassName packageName: aPackageName tag: aTag slots: someSlots classSlots: someClassSlots traits: someTraits classTraits: someClassTraits sharedVariables: someSharedVariables sharedPools: someSharedPools layout: aLayout [

	^ self new
		  className: aClassName;
		  superclassName: aSuperclassName;
		  packageName: aPackageName;
		  tag: aTag;
		  slots: someSlots;
		  classSlots: someClassSlots;
		  traits: someTraits;
		  classTraits: someClassTraits;
		  sharedVariables: someSharedVariables;
		  sharedPools: someSharedPools;
		  layout: aLayout;
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
	self traits ifNotEmpty: [ builder traits: self resolvedTraits ].
	self classTraits ifNotEmpty: [
		builder classTraits: self resolvedClassTraits ].
	self sharedVariables ifNotEmpty: [
		builder sharedVariables: self sharedVariables ].
	self sharedPools ifNotEmpty: [
		builder sharedPools: self resolvedSharedPools ].
	self layout ifNotNil: [ builder layout: self resolvedLayoutClass ].
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

{ #category : 'accessing' }
MCPCreateClassCommand >> classTraits [

	^ classTraits ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPCreateClassCommand >> classTraits: someTraits [

	classTraits := self normalizedNameStringsFrom: someTraits
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

{ #category : 'accessing' }
MCPCreateClassCommand >> layout [

	^ layout
]

{ #category : 'accessing' }
MCPCreateClassCommand >> layout: aLayoutName [

	| normalized |
	normalized := aLayoutName
		              ifNil: [ nil ]
		              ifNotNil: [ aLayoutName asString trimBoth ].
	layout := (normalized isNil or: [ normalized isEmpty ])
		          ifTrue: [ nil ]
		          ifFalse: [ normalized ]
]

{ #category : 'private' }
MCPCreateClassCommand >> normalizedNameStringsFrom: someNames [

	| rawNames |
	rawNames := someNames ifNil: [ #(  ) ] ifNotNil: [ someNames ].
	^ rawNames collect: [ :each | each asString trimBoth ] as: Array
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

{ #category : 'private' }
MCPCreateClassCommand >> resolvedClassTraitNamed: aClassTraitName [

	| behavior normalizedName originalName |
	originalName := aClassTraitName asString trimBoth.
	normalizedName := (originalName endsWith: ' classTrait')
		                  ifTrue: [
		                  originalName
			                  copyFrom: 1
			                  to: originalName size - ' classTrait' size ]
		                  ifFalse: [ originalName ].
	behavior := Smalltalk globals
		            at: normalizedName asSymbol
		            ifAbsent: [
			            MCPCommandError
				            signalErrorCode: #ClassTraitNotFound
				            message:
				            'Class trait ' , originalName , ' does not exist.'
				            details: {
						            (#className -> self className).
						            (#classTraitName -> originalName) } asDictionary ].
	behavior isTrait ifFalse: [
		MCPCommandError
			signalErrorCode: #InvalidClassTrait
			message: originalName , ' is not a class trait.'
			details: {
					(#className -> self className).
					(#classTraitName -> originalName) } asDictionary ].
	^ behavior classTrait
]

{ #category : 'private' }
MCPCreateClassCommand >> resolvedClassTraits [

	^ self classTraits
		  collect: [ :each | self resolvedClassTraitNamed: each ]
		  as: Array
]

{ #category : 'private' }
MCPCreateClassCommand >> resolvedLayoutClass [

	| behavior |
	self layout ifNil: [ ^ nil ].
	behavior := Smalltalk globals at: self layout asSymbol ifAbsent: [
		            MCPCommandError
			            signalErrorCode: #LayoutClassNotFound
			            message:
			            'Layout class ' , self layout , ' does not exist.'
			            details: {
					            (#className -> self className).
					            (#layout -> self layout) } asDictionary ].
	((behavior isBehavior and: [ behavior inheritsFrom: AbstractLayout ])
		 or: [ behavior = AbstractLayout ]) ifFalse: [
		MCPCommandError
			signalErrorCode: #InvalidLayoutClass
			message: self layout , ' is not a layout class.'
			details: {
					(#className -> self className).
					(#layout -> self layout) } asDictionary ].
	^ behavior
]

{ #category : 'private' }
MCPCreateClassCommand >> resolvedSharedPoolNamed: aSharedPoolName [

	| behavior normalizedName |
	normalizedName := aSharedPoolName asString trimBoth.
	behavior := Smalltalk globals
		            at: normalizedName asSymbol
		            ifAbsent: [
			            MCPCommandError
				            signalErrorCode: #SharedPoolNotFound
				            message:
				            'Shared pool ' , normalizedName , ' does not exist.'
				            details: {
						            (#className -> self className).
						            (#sharedPoolName -> normalizedName) } asDictionary ].
	((behavior isBehavior and: [ behavior inheritsFrom: SharedPool ])
		 or: [ behavior = SharedPool ]) ifFalse: [
		MCPCommandError
			signalErrorCode: #InvalidSharedPool
			message: normalizedName , ' is not a shared pool.'
			details: {
					(#className -> self className).
					(#sharedPoolName -> normalizedName) } asDictionary ].
	^ behavior
]

{ #category : 'private' }
MCPCreateClassCommand >> resolvedSharedPools [

	^ self sharedPools
		  collect: [ :each | self resolvedSharedPoolNamed: each ]
		  as: Array
]

{ #category : 'private' }
MCPCreateClassCommand >> resolvedTraitNamed: aTraitName [

	| behavior normalizedName |
	normalizedName := aTraitName asString trimBoth.
	(normalizedName endsWith: ' classTrait') ifTrue: [
		normalizedName := normalizedName
			                  copyFrom: 1
			                  to: normalizedName size - ' classTrait' size ].
	behavior := Smalltalk globals
		            at: normalizedName asSymbol
		            ifAbsent: [
			            MCPCommandError
				            signalErrorCode: #TraitNotFound
				            message:
				            'Trait ' , normalizedName , ' does not exist.'
				            details: {
						            (#className -> self className).
						            (#traitName -> normalizedName) } asDictionary ].
	behavior isTrait ifFalse: [
		MCPCommandError
			signalErrorCode: #InvalidTrait
			message: normalizedName , ' is not a trait.'
			details: {
					(#className -> self className).
					(#traitName -> normalizedName) } asDictionary ].
	^ behavior
]

{ #category : 'private' }
MCPCreateClassCommand >> resolvedTraits [

	^ self traits
		  collect: [ :each | self resolvedTraitNamed: each ]
		  as: Array
]

{ #category : 'accessing' }
MCPCreateClassCommand >> sharedPools [

	^ sharedPools ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPCreateClassCommand >> sharedPools: somePools [

	sharedPools := self normalizedNameStringsFrom: somePools
]

{ #category : 'accessing' }
MCPCreateClassCommand >> sharedVariables [

	^ sharedVariables ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPCreateClassCommand >> sharedVariables: someVariables [

	sharedVariables := self normalizedNameStringsFrom: someVariables
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

{ #category : 'accessing' }
MCPCreateClassCommand >> traits [

	^ traits ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPCreateClassCommand >> traits: someTraits [

	traits := self normalizedNameStringsFrom: someTraits
]
