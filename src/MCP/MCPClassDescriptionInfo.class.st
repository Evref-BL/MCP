"
DTO for rich class metadata used by class_get.

It includes package, tag, layout, slots, traits, pools, shared variables, method counts, and trait composition strings.
"
Class {
	#name : 'MCPClassDescriptionInfo',
	#superclass : 'Object',
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
		at: #className put: className;
		at: #superclassName put: superclassName;
		at: #packageName put: packageName;
		at: #tag put: tag;
		at: #layoutClassName put: layoutClassName;
		at: #instanceMethodCount put: instanceMethodCount;
		at: #classMethodCount put: classMethodCount.
	instanceSlotNames ifNotEmpty: [ :names |
		data at: #instanceSlotNames put: names ].
	classSlotNames ifNotEmpty: [ :names |
		data at: #classSlotNames put: names ].
	traitNames ifNotEmpty: [ :names | data at: #traitNames put: names ].
	classTraitNames ifNotEmpty: [ :names |
		data at: #classTraitNames put: names ].
	traitComposition = '{}' ifFalse: [
		data at: #traitComposition put: traitComposition ].
	classTraitComposition = '{}' ifFalse: [
		data at: #classTraitComposition put: classTraitComposition ].
	sharedPoolNames ifNotEmpty: [ :names |
		data at: #sharedPoolNames put: names ].
	sharedVariableNames ifNotEmpty: [ :names |
		data at: #sharedVariableNames put: names ].
	^ data
]

{ #category : 'initialization' }
MCPClassDescriptionInfo >> initializeFromClass: aClass [

	className := aClass name asString.
	superclassName := aClass superclass
		                  ifNil: [ '' ]
		                  ifNotNil: [ :aSuperclass |
		                  aSuperclass name asString ].
	packageName := aClass package
		               ifNil: [ '' ]
		               ifNotNil: [ :aPackage | aPackage name asString ].
	tag := aClass packageTagName asString.
	instanceSlotNames := aClass slots collect: [ :each |
		                     each name asString ].
	classSlotNames := aClass classSide slots collect: [ :each |
		                  each name asString ].
	traitNames := aClass traits collect: [ :each | each name asString ].
	classTraitNames := aClass classSide traits collect: [ :each |
		                   each name asString ].
	traitComposition := aClass traitCompositionString.
	classTraitComposition := aClass classSide traitCompositionString.
	sharedVariableNames := aClass classVarNames collect: [ :each |
		                       each asString ].
	sharedPoolNames := aClass sharedPools collect: [ :each |
		                   each name asString ].
	layoutClassName := aClass classLayout class name asString.
	instanceMethodCount := aClass selectors size.
	classMethodCount := aClass classSide selectors size
]
