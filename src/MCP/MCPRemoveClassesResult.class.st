"
Result DTO for class_remove.

It groups per-class removal results, package names removed as cleanup, and warning messages produced by safe-removal checks.
"
Class {
	#name : 'MCPRemoveClassesResult',
	#superclass : 'MCPResult',
	#instVars : [
		'removedClasses',
		'removedPackageNames',
		'warningMessages'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPRemoveClassesResult class >> removedClasses: someRemovedClasses removedPackageNames: somePackageNames [

	^ self
		  removedClasses: someRemovedClasses
		  removedPackageNames: somePackageNames
		  warningMessages: #(  )
]

{ #category : 'instance creation' }
MCPRemoveClassesResult class >> removedClasses: someRemovedClasses removedPackageNames: somePackageNames warningMessages: someWarningMessages [

	^ self new
		  removedClasses: someRemovedClasses;
		  removedPackageNames: somePackageNames;
		  warningMessages: someWarningMessages;
		  yourself
]

{ #category : 'converting' }
MCPRemoveClassesResult >> asDictionary [

	| data reparentedSubclassNames |
	data := Dictionary new.
	self removedPackageNames ifNotEmpty: [
		data at: #removedPackageNames put: self removedPackageNames asArray ].
	reparentedSubclassNames := Array streamContents: [ :stream |
			                           self removedClasses do: [ :each |
					                           each reparentedSubclassNames do: [
						                           :subclassName |
						                           stream nextPut: subclassName ] ] ].
	reparentedSubclassNames ifNotEmpty: [
		data at: #reparentedSubclassNames put: reparentedSubclassNames ].
	^ data
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

{ #category : 'accessing' }
MCPRemoveClassesResult >> warningMessages [

	^ warningMessages ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRemoveClassesResult >> warningMessages: aCollection [

	warningMessages := aCollection
		                   ifNil: [ #(  ) ]
		                   ifNotNil: [ aCollection asArray ]
]
