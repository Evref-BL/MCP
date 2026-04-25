"
Result DTO for replacing the shared pools of a class. It carries the class state after replacement and the old/new shared pool name lists for edit-class update output.
"
Class {
	#name : 'MCPReplaceClassSharedPoolsResult',
	#superclass : 'Object',
	#instVars : [
		'classInfo',
		'oldSharedPoolNames',
		'newSharedPoolNames'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPReplaceClassSharedPoolsResult class >> classInfo: aClassInfo oldSharedPoolNames: oldNames newSharedPoolNames: newNames [

	^ self new
		  classInfo: aClassInfo;
		  oldSharedPoolNames: oldNames;
		  newSharedPoolNames: newNames;
		  yourself
]

{ #category : 'converting' }
MCPReplaceClassSharedPoolsResult >> asDictionary [

	| data |
	data := self classInfo asDictionary copy.
	data at: #oldSharedPoolNames put: self oldSharedPoolNames.
	data at: #newSharedPoolNames put: self newSharedPoolNames.
	^ data
]

{ #category : 'accessing' }
MCPReplaceClassSharedPoolsResult >> classInfo [

	^ classInfo
]

{ #category : 'accessing' }
MCPReplaceClassSharedPoolsResult >> classInfo: aClassInfo [

	classInfo := aClassInfo
]

{ #category : 'accessing' }
MCPReplaceClassSharedPoolsResult >> newSharedPoolNames [

	^ newSharedPoolNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPReplaceClassSharedPoolsResult >> newSharedPoolNames: someNames [

	newSharedPoolNames := someNames
		                      ifNil: [ #(  ) ]
		                      ifNotNil: [ someNames asArray ]
]

{ #category : 'accessing' }
MCPReplaceClassSharedPoolsResult >> oldSharedPoolNames [

	^ oldSharedPoolNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPReplaceClassSharedPoolsResult >> oldSharedPoolNames: someNames [

	oldSharedPoolNames := someNames
		                      ifNil: [ #(  ) ]
		                      ifNotNil: [ someNames asArray ]
]
