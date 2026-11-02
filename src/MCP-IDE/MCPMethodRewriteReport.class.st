"
Result DTO for method_rewrite.

It summarizes preview or apply mode, calculated and applied change counts, normalized scope, a change-set hash, and per-method change DTOs.
"
Class {
	#name : 'MCPMethodRewriteReport',
	#superclass : 'MCPResult',
	#instVars : [
		'apply',
		'changeInfos',
		'appliedCount',
		'scope',
		'skippedTraitMethods'
	],
	#category : 'MCP-IDE-Results',
	#package : 'MCP-IDE',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPMethodRewriteReport class >> request: aRequest changeInfos: changeInfoCollection appliedCount: appliedCountInteger [

	^ self new
		  initializeFromRequest: aRequest
		  changeInfos: changeInfoCollection
		  appliedCount: appliedCountInteger
]

{ #category : 'accessing' }
MCPMethodRewriteReport >> appliedCount [

	^ appliedCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
MCPMethodRewriteReport >> apply [

	^ apply = true
]

{ #category : 'converting' }
MCPMethodRewriteReport >> asDictionary [

	| data |
	data := Dictionary new.
	data at: #apply put: self apply.
	data at: #changeCount put: self changeCount.
	data at: #appliedCount put: self appliedCount.
	data at: #scope put: self scope.
	data at: #changes put: self changeDictionaries.
	self skippedTraitMethods ifNotEmpty: [ :skipped | data at: #skippedTraitMethods put: skipped ].
	^ data
]

{ #category : 'accessing' }
MCPMethodRewriteReport >> changeCount [

	^ self changeInfos size
]

{ #category : 'converting' }
MCPMethodRewriteReport >> changeDictionaries [

	^ self changeInfos collect: [ :each | each asDictionary ] as: Array
]

{ #category : 'accessing' }
MCPMethodRewriteReport >> changeInfos [

	^ changeInfos ifNil: [ #(  ) ]
]

{ #category : 'testing' }
MCPMethodRewriteReport >> didApplyChanges [

	^ self apply and: [ self appliedCount > 0 ]
]

{ #category : 'initialization' }
MCPMethodRewriteReport >> initializeFromRequest: aRequest changeInfos: changeInfoCollection appliedCount: appliedCountInteger [

	apply := aRequest apply.
	changeInfos := changeInfoCollection asArray.
	appliedCount := appliedCountInteger.
	scope := aRequest scopeQuery asDictionary.
	^ self
]

{ #category : 'accessing' }
MCPMethodRewriteReport >> scope [

	^ scope ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
MCPMethodRewriteReport >> skippedTraitMethods [
	"The methods in scope a trait defines, named by their origin. They were left out of the rewrite: a changed copy would shadow the trait in that class alone."

	^ skippedTraitMethods ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPMethodRewriteReport >> skippedTraitMethods: someMethodReferences [

	skippedTraitMethods := someMethodReferences asArray
]
