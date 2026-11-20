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

	^ self replaceSharedVariablesOn: self currentClass
]

{ #category : 'accessing' }
MCPReplaceClassSharedVariablesCommand >> sharedVariableNames [

	^ sharedVariableNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPReplaceClassSharedVariablesCommand >> sharedVariableNames: someNames [

	sharedVariableNames := someNames ifNil: [ #(  ) ] ifNotNil: [ someNames asArray ]
]
