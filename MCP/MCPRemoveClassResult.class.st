Class {
	#name : 'MCPRemoveClassResult',
	#superclass : 'Object',
	#instVars : [
		'classInfo',
		'wasEmpty',
		'reparentedToSuperclassName',
		'reparentedSubclassNames'
	],
	#category : 'MCP-Internal',
	#package : 'MCP',
	#tag : 'Internal'
}

{ #category : 'instance creation' }
MCPRemoveClassResult class >> classInfo: aClassInfo wasEmpty: aBoolean reparentedToSuperclassName: aSuperclassName reparentedSubclassNames: someNames [

	^ self new
		  classInfo: aClassInfo;
		  wasEmpty: aBoolean;
		  reparentedToSuperclassName: aSuperclassName;
		  reparentedSubclassNames: someNames;
		  yourself
]

{ #category : 'converting' }
MCPRemoveClassResult >> asDictionary [

	| data |
	data := self classInfo asDictionary copy.
	data at: #wasEmpty put: self wasEmpty.
	data
		at: #reparentedToSuperclassName
		put: self reparentedToSuperclassName.
	data at: #reparentedSubclassNames put: self reparentedSubclassNames.
	^ data
]

{ #category : 'accessing' }
MCPRemoveClassResult >> classInfo [

	^ classInfo
]

{ #category : 'accessing' }
MCPRemoveClassResult >> classInfo: anObject [

	classInfo := anObject
]

{ #category : 'accessing' }
MCPRemoveClassResult >> reparentedSubclassNames [

	^ reparentedSubclassNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRemoveClassResult >> reparentedSubclassNames: aCollection [

	reparentedSubclassNames := aCollection
		                           ifNil: [ #(  ) ]
		                           ifNotNil: [ aCollection asArray ]
]

{ #category : 'accessing' }
MCPRemoveClassResult >> reparentedToSuperclassName [

	^ reparentedToSuperclassName ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPRemoveClassResult >> reparentedToSuperclassName: aString [

	reparentedToSuperclassName := aString
		                              ifNil: [ '' ]
		                              ifNotNil: [ aString ]
]

{ #category : 'accessing' }
MCPRemoveClassResult >> wasEmpty [

	^ wasEmpty = true
]

{ #category : 'accessing' }
MCPRemoveClassResult >> wasEmpty: aBoolean [

	wasEmpty := aBoolean
]
