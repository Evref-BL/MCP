"
DTO for rich class metadata used by class_get.

It includes package, tag, layout, slots, traits, pools, shared variables, method counts, and trait composition strings.
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
		'classTraitComposition'
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
		at: #superclass put: superclassName;
		at: #package put: packageName;
		at: #tag put: tag;
		at: #layout put: layoutClassName;
		at: #methods put: instanceMethodCount;
		at: #classMethods put: classMethodCount.
	instanceSlotNames ifNotEmpty: [ :names | data at: #instanceSlots put: names ].
	classSlotNames ifNotEmpty: [ :names | data at: #classSlots put: names ].
	traitNames ifNotEmpty: [ :names | data at: #traits put: names ].
	classTraitNames ifNotEmpty: [ :names | data at: #classTraits put: names ].
	traitComposition = '{}' ifFalse: [ data at: #traitComposition put: traitComposition ].
	classTraitComposition = '{}' ifFalse: [ data at: #classTraitComposition put: classTraitComposition ].
	sharedPoolNames ifNotEmpty: [ :names | data at: #sharedPools put: names ].
	sharedVariableNames ifNotEmpty: [ :names | data at: #sharedVariables put: names ].
	^ data
]

{ #category : 'initialization' }
MCPClassDescriptionInfo >> initializeFromClass: aClass [

	className := aClass name asString.
	superclassName := aClass superclass ifNil: [ '' ] ifNotNil: [ :aSuperclass | aSuperclass name asString ].
	packageName := aClass packageName asString.
	tag := aClass packageTagName asString.
	instanceSlotNames := (aClass slots collect: [ :each | each name asString ]) asArray.
	classSlotNames := (aClass classSide slots collect: [ :each | each name asString ]) asArray.
	traitNames := (aClass traits collect: [ :each | each name asString ]) asArray.
	classTraitNames := (aClass classSide traits collect: [ :each | each name asString ]) asArray.
	traitComposition := aClass traitCompositionString.
	classTraitComposition := aClass classSide traitCompositionString.
	sharedPoolNames := (aClass sharedPools collect: [ :each | each name asString ]) asArray.
	sharedVariableNames := (aClass classVarNames collect: [ :each | each asString ]) asArray.
	layoutClassName := aClass classLayout class name asString.
	instanceMethodCount := aClass selectors size.
	classMethodCount := aClass classSide selectors size.
	^ self
]
