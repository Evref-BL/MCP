"
Result DTO for replacing the class-side traits of a class. It carries the class state after replacement and the old/new class-side trait name lists for edit-class update output.
"
Class {
	#name : 'MCPReplaceClassSideTraitsResult',
	#superclass : 'Object',
	#instVars : [
		'classInfo',
		'oldClassTraitNames',
		'newClassTraitNames'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPReplaceClassSideTraitsResult class >> classInfo: aClassInfo oldClassTraitNames: oldNames newClassTraitNames: newNames [

	^ self new
		  classInfo: aClassInfo;
		  oldClassTraitNames: oldNames;
		  newClassTraitNames: newNames;
		  yourself
]

{ #category : 'converting' }
MCPReplaceClassSideTraitsResult >> asDictionary [

	| data |
	data := self classInfo asDictionary copy.
	data at: #oldClassTraitNames put: self oldClassTraitNames.
	data at: #newClassTraitNames put: self newClassTraitNames.
	^ data
]

{ #category : 'accessing' }
MCPReplaceClassSideTraitsResult >> classInfo [

	^ classInfo
]

{ #category : 'accessing' }
MCPReplaceClassSideTraitsResult >> classInfo: aClassInfo [

	classInfo := aClassInfo
]

{ #category : 'accessing' }
MCPReplaceClassSideTraitsResult >> newClassTraitNames [

	^ newClassTraitNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPReplaceClassSideTraitsResult >> newClassTraitNames: someNames [

	newClassTraitNames := someNames
		                      ifNil: [ #(  ) ]
		                      ifNotNil: [ someNames asArray ]
]

{ #category : 'accessing' }
MCPReplaceClassSideTraitsResult >> oldClassTraitNames [

	^ oldClassTraitNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPReplaceClassSideTraitsResult >> oldClassTraitNames: someNames [

	oldClassTraitNames := someNames
		                      ifNil: [ #(  ) ]
		                      ifNotNil: [ someNames asArray ]
]
