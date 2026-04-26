"
Replaces the instance-side trait composition of an existing class and returns a DTO describing the old and new trait lists plus the resulting class state.
"
Class {
	#name : 'MCPReplaceClassTraitsCommand',
	#superclass : 'Object',
	#instVars : [
		'className',
		'traitNames'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPReplaceClassTraitsCommand class >> className: aClassName traitNames: someTraitNames [

	^ self new
		  className: aClassName;
		  traitNames: someTraitNames;
		  yourself
]

{ #category : 'accessing' }
MCPReplaceClassTraitsCommand >> className [

	^ className
]

{ #category : 'accessing' }
MCPReplaceClassTraitsCommand >> className: aString [

	className := aString
]

{ #category : 'executing' }
MCPReplaceClassTraitsCommand >> execute [

	| oldTraitNames targetClass |
	targetClass := self targetClass.
	oldTraitNames := self traitNamesFromClass: targetClass.
	targetClass setTraitComposition: self resolvedTraits.
	^ MCPReplaceClassTraitsResult
		  classInfo: (MCPClassInfo fromClass: targetClass)
		  oldTraitNames: oldTraitNames
		  newTraitNames: self traitNames
]

{ #category : 'private' }
MCPReplaceClassTraitsCommand >> resolvedTraitNamed: aTraitName [

	| behavior traitName |
	traitName := aTraitName.
	(traitName endsWith: ' classTrait') ifTrue: [
		traitName := traitName
			             copyFrom: 1
			             to: traitName size - ' classTrait' size ].
	behavior := Smalltalk globals at: traitName asSymbol ifAbsent: [
		            MCPCommandError
			            signalErrorCode: #TraitNotFound
			            message: 'Trait ' , traitName , ' does not exist.'
			            details: {
					            (#className -> self className).
					            (#traitName -> traitName).
					            (#traits -> self traitNames) } asDictionary ].
	behavior isTrait ifFalse: [
		MCPCommandError
			signalErrorCode: #InvalidTrait
			message: traitName , ' is not a trait.'
			details: {
					(#className -> self className).
					(#traitName -> traitName).
					(#traits -> self traitNames) } asDictionary ].
	^ behavior
]

{ #category : 'private' }
MCPReplaceClassTraitsCommand >> resolvedTraits [

	^ self traitNames
		  collect: [ :each | self resolvedTraitNamed: each ]
		  as: Array
]

{ #category : 'private' }
MCPReplaceClassTraitsCommand >> targetClass [

	^ Smalltalk globals
		  at: self className asSymbol
		  ifAbsent: [
		  MCPCommandError signalMissingClassNamed: self className ]
]

{ #category : 'accessing' }
MCPReplaceClassTraitsCommand >> traitNames [

	^ traitNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPReplaceClassTraitsCommand >> traitNames: someNames [

	traitNames := someNames
		              ifNil: [ #(  ) ]
		              ifNotNil: [ someNames asArray ]
]

{ #category : 'private' }
MCPReplaceClassTraitsCommand >> traitNamesFromClass: aClass [

	^ aClass traits collect: [ :each | each name asString ] as: Array
]
