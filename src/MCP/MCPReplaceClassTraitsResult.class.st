"
Result DTO for replacing the instance-side trait composition of a class. It carries the class state after replacement and the old/new trait name lists for edit-class update output.
"
Class {
	#name : 'MCPReplaceClassTraitsResult',
	#superclass : 'Object',
	#instVars : [
		'classInfo',
		'oldTraitNames',
		'newTraitNames'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPReplaceClassTraitsResult class >> classInfo: aClassInfo oldTraitNames: oldNames newTraitNames: newNames [

	^ self new
		  classInfo: aClassInfo;
		  oldTraitNames: oldNames;
		  newTraitNames: newNames;
		  yourself
]

{ #category : 'converting' }
MCPReplaceClassTraitsResult >> asDictionary [

	| data |
	data := self classInfo asDictionary copy.
	data at: #oldTraitNames put: self oldTraitNames.
	data at: #newTraitNames put: self newTraitNames.
	^ data
]

{ #category : 'accessing' }
MCPReplaceClassTraitsResult >> classInfo [

	^ classInfo
]

{ #category : 'accessing' }
MCPReplaceClassTraitsResult >> classInfo: aClassInfo [

	classInfo := aClassInfo
]

{ #category : 'accessing' }
MCPReplaceClassTraitsResult >> newTraitNames [

	^ newTraitNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPReplaceClassTraitsResult >> newTraitNames: someNames [

	newTraitNames := someNames
		                 ifNil: [ #(  ) ]
		                 ifNotNil: [ someNames asArray ]
]

{ #category : 'accessing' }
MCPReplaceClassTraitsResult >> oldTraitNames [

	^ oldTraitNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPReplaceClassTraitsResult >> oldTraitNames: someNames [

	oldTraitNames := someNames
		                 ifNil: [ #(  ) ]
		                 ifNotNil: [ someNames asArray ]
]
