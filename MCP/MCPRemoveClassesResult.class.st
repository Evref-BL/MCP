Class {
	#name : 'MCPRemoveClassesResult',
	#superclass : 'Object',
	#instVars : [
		'removedClasses',
		'removedPackageNames'
	],
	#category : 'MCP-Internal',
	#package : 'MCP',
	#tag : 'Internal'
}

{ #category : 'instance creation' }
MCPRemoveClassesResult class >> removedClasses: someRemovedClasses removedPackageNames: somePackageNames [

	^ self new
		  removedClasses: someRemovedClasses;
		  removedPackageNames: somePackageNames;
		  yourself
]

{ #category : 'converting' }
MCPRemoveClassesResult >> asDictionary [

	^ {
		  (#classNames
		   ->
			   (self removedClasses collect: [ :each |
				    each classInfo className ]) asArray).
		  (#removedClasses
		   -> (self removedClasses collect: #asDictionary) asArray).
		  (#removedPackageNames -> self removedPackageNames asArray) }
		  asDictionary
]

{ #category : 'accessing' }
MCPRemoveClassesResult >> removedClasses [

	^ removedClasses ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRemoveClassesResult >> removedClasses: aCollection [

	removedClasses := aCollection
		                  ifNil: [ #(  ) ]
		                  ifNotNil: [ aCollection asArray ]
]

{ #category : 'accessing' }
MCPRemoveClassesResult >> removedPackageNames [

	^ removedPackageNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRemoveClassesResult >> removedPackageNames: aCollection [

	removedPackageNames := aCollection
		                       ifNil: [ #(  ) ]
		                       ifNotNil: [ aCollection asArray ]
]
