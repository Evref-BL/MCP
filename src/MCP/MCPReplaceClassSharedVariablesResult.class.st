"
Result DTO for replacing the class variables of a class.

It carries the class state after replacement and the old/new shared variable name lists for class update output.
"
Class {
	#name : 'MCPReplaceClassSharedVariablesResult',
	#superclass : 'MCPClassResult',
	#instVars : [
		'classInfo',
		'oldSharedVariableNames',
		'newSharedVariableNames'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPReplaceClassSharedVariablesResult class >> classInfo: aClassInfo oldSharedVariableNames: oldNames newSharedVariableNames: newNames [

	^ self new
		  classInfo: aClassInfo;
		  oldSharedVariableNames: oldNames;
		  newSharedVariableNames: newNames;
		  yourself
]

{ #category : 'converting' }
MCPReplaceClassSharedVariablesResult >> asDictionary [

	| data |
	data := self newClassInfoDictionary.
	data at: #oldSharedVariableNames put: self oldSharedVariableNames.
	data at: #newSharedVariableNames put: self newSharedVariableNames.
	^ data
]

{ #category : 'accessing' }
MCPReplaceClassSharedVariablesResult >> classInfo [

	^ classInfo
]

{ #category : 'accessing' }
MCPReplaceClassSharedVariablesResult >> classInfo: aClassInfo [

	classInfo := aClassInfo
]

{ #category : 'accessing' }
MCPReplaceClassSharedVariablesResult >> newSharedVariableNames [

	^ newSharedVariableNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPReplaceClassSharedVariablesResult >> newSharedVariableNames: someNames [

	newSharedVariableNames := someNames
		                          ifNil: [ #(  ) ]
		                          ifNotNil: [ someNames asArray ]
]

{ #category : 'accessing' }
MCPReplaceClassSharedVariablesResult >> oldSharedVariableNames [

	^ oldSharedVariableNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPReplaceClassSharedVariablesResult >> oldSharedVariableNames: someNames [

	oldSharedVariableNames := someNames
		                          ifNil: [ #(  ) ]
		                          ifNotNil: [ someNames asArray ]
]
