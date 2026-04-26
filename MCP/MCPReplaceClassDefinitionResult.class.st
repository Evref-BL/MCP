"
Result DTO for replacing the slot shape of a class. It carries the class state after replacement and the old/new instance-side and class-side slot name lists for edit-class update output.
"
Class {
	#name : 'MCPReplaceClassDefinitionResult',
	#superclass : 'Object',
	#instVars : [
		'classInfo',
		'oldInstanceSlotNames',
		'newInstanceSlotNames',
		'oldClassSlotNames',
		'newClassSlotNames'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPReplaceClassDefinitionResult class >> classInfo: aClassInfo [

	^ self new
		  classInfo: aClassInfo;
		  yourself
]

{ #category : 'converting' }
MCPReplaceClassDefinitionResult >> asDictionary [

	| data |
	data := self classInfo asDictionary copy.
	data at: #oldInstanceSlotNames put: self oldInstanceSlotNames.
	data at: #newInstanceSlotNames put: self newInstanceSlotNames.
	data at: #oldClassSlotNames put: self oldClassSlotNames.
	data at: #newClassSlotNames put: self newClassSlotNames.
	^ data
]

{ #category : 'accessing' }
MCPReplaceClassDefinitionResult >> classInfo [

	^ classInfo
]

{ #category : 'accessing' }
MCPReplaceClassDefinitionResult >> classInfo: aClassInfo [

	classInfo := aClassInfo
]

{ #category : 'accessing' }
MCPReplaceClassDefinitionResult >> newClassSlotNames [

	^ newClassSlotNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPReplaceClassDefinitionResult >> newClassSlotNames: someNames [

	newClassSlotNames := someNames
		                     ifNil: [ #(  ) ]
		                     ifNotNil: [ someNames asArray ]
]

{ #category : 'accessing' }
MCPReplaceClassDefinitionResult >> newInstanceSlotNames [

	^ newInstanceSlotNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPReplaceClassDefinitionResult >> newInstanceSlotNames: someNames [

	newInstanceSlotNames := someNames
		                        ifNil: [ #(  ) ]
		                        ifNotNil: [ someNames asArray ]
]

{ #category : 'accessing' }
MCPReplaceClassDefinitionResult >> oldClassSlotNames [

	^ oldClassSlotNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPReplaceClassDefinitionResult >> oldClassSlotNames: someNames [

	oldClassSlotNames := someNames
		                     ifNil: [ #(  ) ]
		                     ifNotNil: [ someNames asArray ]
]

{ #category : 'accessing' }
MCPReplaceClassDefinitionResult >> oldInstanceSlotNames [

	^ oldInstanceSlotNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPReplaceClassDefinitionResult >> oldInstanceSlotNames: someNames [

	oldInstanceSlotNames := someNames
		                        ifNil: [ #(  ) ]
		                        ifNotNil: [ someNames asArray ]
]
