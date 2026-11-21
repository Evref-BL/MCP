"
Replaces the class variables of an existing class using the Shift class installer and answers the updated class.
"
Class {
	#name : 'MCPReplaceClassSharedVariablesCommand',
	#superclass : 'MCPClassCommand',
	#instVars : [
		'sharedVariableNames'
	],
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPReplaceClassSharedVariablesCommand class >> className: aClassName sharedVariableNames: someNames [

	^ self new
		  className: aClassName;
		  sharedVariableNames: someNames;
		  yourself
]

{ #category : 'executing' }
MCPReplaceClassSharedVariablesCommand >> execute [
	"A class variable left out goes, and the methods using it are named in a warning first."

	| class |
	class := self currentClass.
	self warnOfMethodsUsing: (self variablesRemovedFrom: class) below: class.
	^ self installing: [ self replaceSharedVariablesOn: class ]
]

{ #category : 'accessing' }
MCPReplaceClassSharedVariablesCommand >> sharedVariableNames [

	^ sharedVariableNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPReplaceClassSharedVariablesCommand >> sharedVariableNames: someNames [

	sharedVariableNames := someNames ifNil: [ #(  ) ] ifNotNil: [ someNames asArray ]
]

{ #category : 'private' }
MCPReplaceClassSharedVariablesCommand >> variablesRemovedFrom: aClass [
	"The class variables of aClass that the replacement leaves out."

	^ (aClass classVarNames reject: [ :each | self sharedVariableNames includes: each asString ]) collect: [ :each |
		  aClass classVariableNamed: each ]
]
