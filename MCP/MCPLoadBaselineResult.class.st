"
Result DTO for the reusable Metacello baseline load core. It reports baseline options and newly observed packages and Iceberg repositories.
"
Class {
	#name : 'MCPLoadBaselineResult',
	#superclass : 'Object',
	#instVars : [
		'baseline',
		'groups',
		'onWarning',
		'onConflict',
		'newPackageNames',
		'repositoryInfos'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPLoadBaselineResult class >> request: aRequest newPackageNames: packageNames repositoryInfos: repositories [

	^ self new
		  initializeRequest: aRequest
		  newPackageNames: packageNames
		  repositoryInfos: repositories
]

{ #category : 'converting' }
MCPLoadBaselineResult >> asDictionary [

	^ {
		  (#baseline -> self baseline).
		  (#groups -> self groups).
		  (#onWarning -> self onWarning).
		  (#onConflict -> self onConflict).
		  (#newPackageNames -> self newPackageNames).
		  (#repositories -> self repositoryDictionaries) } asDictionary
]

{ #category : 'accessing' }
MCPLoadBaselineResult >> baseline [

	^ baseline
]

{ #category : 'accessing' }
MCPLoadBaselineResult >> groups [

	^ groups ifNil: [ #(  ) ]
]

{ #category : 'initialization' }
MCPLoadBaselineResult >> initializeRequest: aRequest newPackageNames: packageNames repositoryInfos: repositories [

	baseline := aRequest baseline.
	groups := aRequest groups.
	onWarning := aRequest onWarning.
	onConflict := aRequest onConflict.
	newPackageNames := packageNames asArray.
	repositoryInfos := repositories asArray.
	^ self
]

{ #category : 'accessing' }
MCPLoadBaselineResult >> newPackageNames [

	^ newPackageNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPLoadBaselineResult >> onConflict [

	^ onConflict
]

{ #category : 'accessing' }
MCPLoadBaselineResult >> onWarning [

	^ onWarning
]

{ #category : 'converting' }
MCPLoadBaselineResult >> repositoryDictionaries [

	^ (self repositoryInfos collect: [ :each | each asDictionary ])
		  asArray
]

{ #category : 'accessing' }
MCPLoadBaselineResult >> repositoryInfos [

	^ repositoryInfos ifNil: [ #(  ) ]
]
