"
DTO for rich class metadata used by class_get.

It includes package, tag, layout, slots, traits, pools, shared variables, the counts of the methods the class defines itself, and, for a trait, the classes using it. What every class has unless it says otherwise is left out: a fixed layout, no tag, and a class side using the class side of each of its traits. A trait composition is kept only when an alias or an exclusion makes it say more than the list of traits.
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
		'userNames',
		'classTraitsMirrorTraits'
	],
	#category : 'MCP-IDE-DTOs',
	#package : 'MCP-IDE',
	#tag : 'DTOs'
}

{ #category : 'instance creation' }
MCPClassDescriptionInfo class >> fromClass: aClass [

	^ self new initializeFromClass: aClass
]

{ #category : 'converting' }
MCPClassDescriptionInfo >> asDictionary [
	"A fixed layout, no tag, and a class side using the class sides of the class's own traits are what a class has unless it says otherwise, so they are left out."

	| data |
	data := Dictionary new.
	data
		at: #class put: className;
		at: #package put: packageName;
		at: #methods put: instanceMethodCount;
		at: #classMethods put: classMethodCount.
	tag ifNotNil: [ data at: #tag put: tag ].
	layoutClassName = FixedLayout name asString ifFalse: [ data at: #layout put: layoutClassName ].
	superclassName ifNotEmpty: [ :name | data at: #superclass put: name ].
	self isTrait ifTrue: [ data at: #isTrait put: true ].
	instanceSlotNames ifNotEmpty: [ :names | data at: #instanceSlots put: names ].
	classSlotNames ifNotEmpty: [ :names | data at: #classSlots put: names ].
	traitNames ifNotEmpty: [ :names | data at: #traits put: names ].
	(classTraitsMirrorTraits = true or: [ classTraitNames isEmpty ]) ifFalse: [ data at: #classTraits put: classTraitNames ].
	(self composition: traitComposition saysMoreThan: traitNames) ifTrue: [ data at: #traitComposition put: traitComposition ].
	(self composition: classTraitComposition saysMoreThan: classTraitNames) ifTrue: [
		data at: #classTraitComposition put: classTraitComposition ].
	self userNames ifNotEmpty: [ :names | data at: #users put: names ].
	sharedPoolNames ifNotEmpty: [ :names | data at: #sharedPools put: names ].
	sharedVariableNames ifNotEmpty: [ :names | data at: #sharedVariables put: names ].
	^ data
]

{ #category : 'initialization' }
MCPClassDescriptionInfo >> classSideTraitsOf: aClass mirrorTheTraits: someTraits [
	"Whether the class side uses the class side of each trait the class uses, in order, which is what using a trait does unless a composition says otherwise."

	^ aClass classSide traits asArray = (someTraits collect: [ :each | each classSide ] as: Array)
]

{ #category : 'converting' }
MCPClassDescriptionInfo >> composition: aComposition saysMoreThan: someTraitNames [
	"A composition repeats the traits it is made of unless an alias or an exclusion changed one."

	aComposition = '{}' ifTrue: [ ^ false ].
	^ aComposition ~= (' + ' join: someTraitNames)
]

{ #category : 'initialization' }
MCPClassDescriptionInfo >> initializeFromClass: aClass [
	"The method counts are of the methods the class defines itself: those it gets from its traits are the traits', which the list of traits beside them names, and the class side of a class using traits also holds what Pharo installs there from TraitedClass. A default, such as a fixed layout or no tag, is left unset."

	className := aClass name asString.
	isTrait := aClass isTrait.
	superclassName := aClass superclass ifNil: [ '' ] ifNotNil: [ :aSuperclass | aSuperclass name asString ].
	packageName := aClass packageName asString.
	tag := aClass mcpTagName.
	instanceSlotNames := aClass slots collect: [ :each | each name asString ] as: Array.
	classSlotNames := aClass classSide slots collect: [ :each | each name asString ] as: Array.
	traitNames := aClass traits collect: [ :each | each name asString ] as: Array.
	classTraitNames := aClass classSide traits collect: [ :each | each name asString ] as: Array.
	classTraitsMirrorTraits := self classSideTraitsOf: aClass mirrorTheTraits: aClass traits.
	traitComposition := aClass traitCompositionString.
	classTraitComposition := aClass classSide traitCompositionString.
	userNames := (aClass users collect: [ :each | each instanceSide name asString ] as: Array) sort.
	sharedPoolNames := aClass sharedPools collect: [ :each | each name asString ] as: Array.
	sharedVariableNames := aClass classVarNames collect: [ :each | each asString ] as: Array.
	layoutClassName := aClass classLayout class name asString.
	instanceMethodCount := aClass localMethods size.
	classMethodCount := aClass classSide localMethods size.
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
