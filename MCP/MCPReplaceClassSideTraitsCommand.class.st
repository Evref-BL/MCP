"
Replaces the class-side traits of an existing class and returns a DTO describing the old and new class-side trait name lists plus the resulting class state.
"
Class {
	#name : 'MCPReplaceClassSideTraitsCommand',
	#superclass : 'Object',
	#instVars : [
		'className',
		'classTraitNames'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPReplaceClassSideTraitsCommand class >> className: aClassName classTraitNames: someNames [

	^ self new
		  className: aClassName;
		  classTraitNames: someNames;
		  yourself
]

{ #category : 'accessing' }
MCPReplaceClassSideTraitsCommand >> className [

	^ className
]

{ #category : 'accessing' }
MCPReplaceClassSideTraitsCommand >> className: aString [

	className := aString
]

{ #category : 'accessing' }
MCPReplaceClassSideTraitsCommand >> classTraitNames [

	^ classTraitNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPReplaceClassSideTraitsCommand >> classTraitNames: someNames [

	classTraitNames := someNames
		                   ifNil: [ #(  ) ]
		                   ifNotNil: [ someNames asArray ]
]

{ #category : 'private' }
MCPReplaceClassSideTraitsCommand >> classTraitNamesFromClass: aClass [

	^ aClass classSide traits
		  collect: [ :each | each name asString ]
		  as: Array
]

{ #category : 'accessing' }
MCPReplaceClassSideTraitsCommand >> classTraits [

	^ self classTraitNames
]

{ #category : 'executing' }
MCPReplaceClassSideTraitsCommand >> execute [

	| oldClassTraitNames targetClass |
	targetClass := self targetClass.
	oldClassTraitNames := self classTraitNamesFromClass: targetClass.
	targetClass classSide setTraitComposition: self resolvedClassTraits.
	^ MCPReplaceClassSideTraitsResult
		  classInfo: (MCPClassInfo fromClass: targetClass)
		  oldClassTraitNames: oldClassTraitNames
		  newClassTraitNames: self classTraitNames
]

{ #category : 'private' }
MCPReplaceClassSideTraitsCommand >> resolvedClassTraitNamed: aClassTraitName [

	| behavior classTraitName originalName |
	originalName := aClassTraitName.
	classTraitName := (originalName endsWith: ' classTrait')
		                  ifTrue: [
		                  originalName
			                  copyFrom: 1
			                  to: originalName size - ' classTrait' size ]
		                  ifFalse: [ originalName ].
	behavior := Smalltalk globals
		            at: classTraitName asSymbol
		            ifAbsent: [
			            MCPCommandError
				            signalErrorCode: #ClassTraitNotFound
				            message:
				            'Class trait ' , originalName , ' does not exist.'
				            details: {
						            (#className -> self className).
						            (#classTraitName -> originalName).
						            (#classTraits -> self classTraitNames) }
						            asDictionary ].
	behavior isTrait ifFalse: [
		MCPCommandError
			signalErrorCode: #InvalidClassTrait
			message: originalName , ' is not a class trait.'
			details: {
					(#className -> self className).
					(#classTraitName -> originalName).
					(#classTraits -> self classTraitNames) } asDictionary ].
	^ behavior classTrait
]

{ #category : 'private' }
MCPReplaceClassSideTraitsCommand >> resolvedClassTraits [

	^ self classTraits
		  collect: [ :each | self resolvedClassTraitNamed: each ]
		  as: Array
]

{ #category : 'private' }
MCPReplaceClassSideTraitsCommand >> targetClass [

	^ Smalltalk globals
		  at: self className asSymbol
		  ifAbsent: [
		  MCPCommandError signalMissingClassNamed: self className ]
]
