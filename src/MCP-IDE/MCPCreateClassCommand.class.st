"
Command that creates a class from a parsed class creation request.

It owns the class-builder interaction for superclass, package, tag, slots, traits, shared variables, pools, and layout, then returns an MCPCreateClassResult.
"
Class {
	#name : 'MCPCreateClassCommand',
	#superclass : 'MCPClassCommand',
	#instVars : [
		'superclassName',
		'packageName',
		'tag',
		'slots',
		'classSlots',
		'traits',
		'sharedVariables',
		'sharedPools',
		'layout'
	],
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
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
MCPCreateClassCommand class >> className: aClassName superclassName: aSuperclassName packageName: aPackageName tag: aTag slots: someSlots classSlots: someClassSlots traits: someTraits sharedVariables: someSharedVariables sharedPools: someSharedPools layout: aLayout [

	^ self new
		  className: aClassName;
		  superclassName: aSuperclassName;
		  packageName: aPackageName;
		  tag: aTag;
		  slots: someSlots;
		  classSlots: someClassSlots;
		  traits: someTraits;
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
	self sharedVariables ifNotEmpty: [ builder sharedVariables: self sharedVariables ].
	self sharedPools ifNotEmpty: [ builder sharedPools: self resolvedSharedPools ].
	self layout ifNotNil: [ :layoutName | builder layout: (self resolvedLayoutClassNamed: layoutName) ].
	createdClass := builder install.
	^ createdClass
]

{ #category : 'accessing' }
MCPCreateClassCommand >> classSlots [

	^ classSlots ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPCreateClassCommand >> classSlots: someSlots [

	classSlots := someSlots ifNil: [ #(  ) ] ifNotNil: [ someSlots asArray ]
]

{ #category : 'private' }
MCPCreateClassCommand >> ensurePackageNamed: aPackageName [

	self packageOrganizer ensurePackage: aPackageName
]

{ #category : 'executing' }
MCPCreateClassCommand >> execute [

	| createdClass |
	(Smalltalk globals includesKey: self className asSymbol) ifTrue: [ MCPCommandError signalClassAlreadyExistsNamed: self className ].
	self ensurePackageNamed: self packageName.
	createdClass := self buildClass.
	^ MCPCreateClassResult classInfo: (MCPClassInfo fromClass: createdClass)
]

{ #category : 'accessing' }
MCPCreateClassCommand >> layout [

	^ layout
]

{ #category : 'accessing' }
MCPCreateClassCommand >> layout: aLayoutName [

	layout := aLayoutName
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
MCPCreateClassCommand >> resolvedSharedPools [

	^ self sharedPools collect: [ :each | self resolvedSharedPoolNamed: each ] as: Array
]

{ #category : 'private' }
MCPCreateClassCommand >> resolvedTraitNamed: aTraitName [

	| behavior traitName |
	traitName := aTraitName.
	(traitName endsWith: ' classTrait') ifTrue: [ traitName := traitName copyFrom: 1 to: traitName size - ' classTrait' size ].
	behavior := Smalltalk globals at: traitName asSymbol ifAbsent: [
			            MCPCommandError
				            signalErrorCode: #TraitNotFound
				            message: (String streamContents: [ :stream | stream << 'Trait ' << traitName << ' does not exist.' ])
				            details: {
						            (#class -> self className).
						            (#trait -> traitName) } asDictionary ].
	behavior isTrait ifFalse: [
			MCPCommandError signalErrorCode: #InvalidTrait message: traitName , ' is not a trait.' details: {
					(#class -> self className).
					(#trait -> traitName) } asDictionary ].
	^ behavior
]

{ #category : 'private' }
MCPCreateClassCommand >> resolvedTraits [

	^ self traits collect: [ :each | self resolvedTraitNamed: each ] as: Array
]

{ #category : 'accessing' }
MCPCreateClassCommand >> sharedPools [

	^ sharedPools ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPCreateClassCommand >> sharedPools: somePools [

	sharedPools := somePools ifNil: [ #(  ) ] ifNotNil: [ somePools asArray ]
]

{ #category : 'accessing' }
MCPCreateClassCommand >> sharedVariables [

	^ sharedVariables ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPCreateClassCommand >> sharedVariables: someVariables [

	sharedVariables := someVariables ifNil: [ #(  ) ] ifNotNil: [ someVariables asArray ]
]

{ #category : 'accessing' }
MCPCreateClassCommand >> slots [

	^ slots ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPCreateClassCommand >> slots: someSlots [

	slots := someSlots ifNil: [ #(  ) ] ifNotNil: [ someSlots asArray ]
]

{ #category : 'private' }
MCPCreateClassCommand >> superclass [

	^ Smalltalk globals
		  at: self superclassName asSymbol
		  ifAbsent: [ MCPCommandError signalMissingSuperclassNamed: self superclassName forClassNamed: self className ]
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

	tag := aString
]

{ #category : 'accessing' }
MCPCreateClassCommand >> traits [

	^ traits ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPCreateClassCommand >> traits: someTraits [

	traits := someTraits ifNil: [ #(  ) ] ifNotNil: [ someTraits asArray ]
]
