"
DTO for rich class metadata used by class_get.

It includes package, tag, layout, slots, traits, pools, shared variables, method counts, and, for a trait, the classes using it. A trait composition is kept only when an alias or an exclusion makes it say more than the list of traits.
"
Class {
	#name : 'MCPClassDescriptionInfo',
	#superclass : 'MCPDataTransferObject',
	#instVars : [
		'className',
		'superclassName',
		'packageName',
		'tag',
		'instanceSlotNames',
		'classSlotNames',
		'traitNames',
		'classTraitNames',
		'sharedPoolNames',
		'instanceMethodCount',
		'classMethodCount',
		'layoutClassName',
		'sharedVariableNames',
		'traitComposition',
		'classTraitComposition',
		'isTrait',
		'userNames'
	],
	#category : 'MCP-DTOs',
	#package : 'MCP',
	#tag : 'DTOs'
}

{ #category : 'instance creation' }
MCPClassDescriptionInfo class >> fromClass: aClass [

	^ self new initializeFromClass: aClass
]

{ #category : 'converting' }
MCPClassDescriptionInfo >> asDictionary [

	| data |
	data := Dictionary new.
	data
		at: #class put: className;
		at: #package put: packageName;
		at: #tag put: tag;
		at: #layout put: layoutClassName;
		at: #methods put: instanceMethodCount;
		at: #classMethods put: classMethodCount.
	superclassName ifNotEmpty: [ :name | data at: #superclass put: name ].
	self isTrait ifTrue: [ data at: #isTrait put: true ].
	instanceSlotNames ifNotEmpty: [ :names | data at: #instanceSlots put: names ].
	classSlotNames ifNotEmpty: [ :names | data at: #classSlots put: names ].
	traitNames ifNotEmpty: [ :names | data at: #traits put: names ].
	classTraitNames ifNotEmpty: [ :names | data at: #classTraits put: names ].
	(self composition: traitComposition saysMoreThan: traitNames) ifTrue: [ data at: #traitComposition put: traitComposition ].
	(self composition: classTraitComposition saysMoreThan: classTraitNames) ifTrue: [
		data at: #classTraitComposition put: classTraitComposition ].
	self userNames ifNotEmpty: [ :names | data at: #users put: names ].
	sharedPoolNames ifNotEmpty: [ :names | data at: #sharedPools put: names ].
	sharedVariableNames ifNotEmpty: [ :names | data at: #sharedVariables put: names ].
	^ data
]

{ #category : 'converting' }
MCPClassDescriptionInfo >> composition: aComposition saysMoreThan: someTraitNames [
	"A composition repeats the traits it is made of unless an alias or an exclusion changed one."

	aComposition = '{}' ifTrue: [ ^ false ].
	^ aComposition ~= (' + ' join: someTraitNames)
]

{ #category : 'initialization' }
MCPClassDescriptionInfo >> initializeFromClass: aClass [

	className := aClass name asString.
	isTrait := aClass isTrait.
	superclassName := aClass superclass ifNil: [ '' ] ifNotNil: [ :aSuperclass | aSuperclass name asString ].
	packageName := aClass packageName asString.
	tag := aClass packageTagName asString.
	instanceSlotNames := (aClass slots collect: [ :each | each name asString ]) asArray.
	classSlotNames := (aClass classSide slots collect: [ :each | each name asString ]) asArray.
	traitNames := (aClass traits collect: [ :each | each name asString ]) asArray.
	classTraitNames := (aClass classSide traits collect: [ :each | each name asString ]) asArray.
	traitComposition := aClass traitCompositionString.
	classTraitComposition := aClass classSide traitCompositionString.
	userNames := (aClass users collect: [ :each | each instanceSide name asString ] as: Array) sort.
	sharedPoolNames := (aClass sharedPools collect: [ :each | each name asString ]) asArray.
	sharedVariableNames := (aClass classVarNames collect: [ :each | each asString ]) asArray.
	layoutClassName := aClass classLayout class name asString.
	instanceMethodCount := aClass selectors size.
	classMethodCount := aClass classSide selectors size.
	^ self
]

{ #category : 'accessing' }
MCPClassDescriptionInfo >> isTrait [

	^ isTrait = true
]

{ #category : 'accessing' }
MCPClassDescriptionInfo >> userNames [
	"The classes using this trait, which is what a trait has instead of subclasses."

	^ userNames ifNil: [ #(  ) ]
]
