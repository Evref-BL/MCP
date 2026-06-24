"
Result DTO for the reusable Metacello baseline load core. It reports baseline groups, the applied load policy, newly observed packages, and newly registered Iceberg repositories.
"
Class {
	#name : 'MCPLoadBaselineResult',
	#superclass : 'Object',
	#instVars : [
		'baseline',
		'groups',
		'loadPolicy',
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

	| data policy repositories |
	data := { (#baseline -> self baseline) } asDictionary.
	policy := self loadPolicy asDictionary.
	policy ifNotEmpty: [ data at: #policy put: policy ].
	self newPackageNames ifNotEmpty: [ :packageNames |
		data at: #newPackageNames put: packageNames ].
	repositories := self repositoryDictionaries.
	repositories ifNotEmpty: [ data at: #repositories put: repositories ].
	^ data
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
	loadPolicy := aRequest loadPolicy.
	newPackageNames := packageNames asArray.
	repositoryInfos := repositories asArray
]

{ #category : 'accessing' }
MCPLoadBaselineResult >> loadPolicy [

	^ loadPolicy
]

{ #category : 'accessing' }
MCPLoadBaselineResult >> newPackageNames [

	^ newPackageNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPLoadBaselineResult >> onConflict [

	^ self loadPolicy onConflict
]

{ #category : 'accessing' }
MCPLoadBaselineResult >> onWarning [

	^ self loadPolicy onWarning
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
