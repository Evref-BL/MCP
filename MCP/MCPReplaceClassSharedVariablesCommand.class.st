"
Replaces the class variables of an existing class using the Shift class installer and returns a DTO describing the old and new shared variable name lists plus the resulting class state.
"
Class {
	#name : 'MCPReplaceClassSharedVariablesCommand',
	#superclass : 'Object',
	#instVars : [
		'className',
		'sharedVariableNames'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPReplaceClassSharedVariablesCommand class >> className: aClassName sharedVariableNames: someNames [

	^ self new
		  className: aClassName;
		  sharedVariableNames: someNames;
		  yourself
]

{ #category : 'accessing' }
MCPReplaceClassSharedVariablesCommand >> className [

	^ className
]

{ #category : 'accessing' }
MCPReplaceClassSharedVariablesCommand >> className: aString [

	className := aString
]

{ #category : 'executing' }
MCPReplaceClassSharedVariablesCommand >> execute [

	| oldSharedVariableNames targetClass updatedClass |
	targetClass := self targetClass.
	oldSharedVariableNames := self sharedVariableNamesFromClass:
		                          targetClass.
	updatedClass := self replaceSharedVariablesOn: targetClass.
	^ MCPReplaceClassSharedVariablesResult
		  classInfo: (MCPClassInfo fromClass: updatedClass)
		  oldSharedVariableNames: oldSharedVariableNames
		  newSharedVariableNames: self sharedVariableNames
]

{ #category : 'private' }
MCPReplaceClassSharedVariablesCommand >> replaceSharedVariablesOn: aClass [

	^ ShiftClassInstaller
		  update: aClass
		  to: [ :builder |
		  builder sharedVariables: self sharedVariableNames ]
]

{ #category : 'accessing' }
MCPReplaceClassSharedVariablesCommand >> sharedVariableNames [

	^ sharedVariableNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPReplaceClassSharedVariablesCommand >> sharedVariableNames: someNames [

	sharedVariableNames := someNames
		                       ifNil: [ #(  ) ]
		                       ifNotNil: [ someNames asArray ]
]

{ #category : 'private' }
MCPReplaceClassSharedVariablesCommand >> sharedVariableNamesFromClass: aClass [

	^ aClass classVarNames collect: [ :each | each asString ] as: Array
]

{ #category : 'accessing' }
MCPReplaceClassSharedVariablesCommand >> sharedVariables [

	^ self sharedVariableNames
]

{ #category : 'private' }
MCPReplaceClassSharedVariablesCommand >> targetClass [

	^ Smalltalk globals
		  at: self className asSymbol
		  ifAbsent: [
		  MCPCommandError signalMissingClassNamed: self className ]
]
