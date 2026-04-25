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

	^ {
		  (#className -> className).
		  (#superclassName -> superclassName).
		  (#packageName -> packageName).
		  (#tag -> tag).
		  (#instanceSlotNames -> instanceSlotNames).
		  (#classSlotNames -> classSlotNames).
		  (#traitNames -> traitNames).
		  (#classTraitNames -> classTraitNames).
		  (#traitComposition -> traitComposition).
		  (#classTraitComposition -> classTraitComposition).
		  (#sharedPoolNames -> sharedPoolNames).
		  (#sharedVariableNames -> sharedVariableNames).
		  (#layoutClassName -> layoutClassName).
		  (#instanceMethodCount -> instanceMethodCount).
		  (#classMethodCount -> classMethodCount) } asDictionary
]

{ #category : 'initialization' }
MCPClassDescriptionInfo >> initializeFromClass: aClass [

	className := aClass name asString.
	superclassName := aClass superclass
		                  ifNil: [ '' ]
		                  ifNotNil: [ :aSuperclass |
		                  aSuperclass name asString ].
	packageName := aClass packageName asString.
	tag := aClass packageTagName asString.
	instanceSlotNames := (aClass slots collect: [ :each |
		                      each name asString ]) asArray.
	classSlotNames := (aClass classSide slots collect: [ :each |
		                   each name asString ]) asArray.
	traitNames := (aClass traits collect: [ :each | each name asString ])
		              asArray.
	classTraitNames := (aClass classSide traits collect: [ :each |
		                    each name asString ]) asArray.
	traitComposition := aClass traitCompositionString.
	classTraitComposition := aClass classSide traitCompositionString.
	sharedPoolNames := (aClass sharedPools collect: [ :each |
		                    each name asString ]) asArray.
	sharedVariableNames := (aClass classVarNames collect: [ :each |
		                        each asString ]) asArray.
	layoutClassName := aClass classLayout class name asString.
	instanceMethodCount := aClass selectors size.
	classMethodCount := aClass classSide selectors size.
	^ self
]
