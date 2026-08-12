"
Test double for an Iceberg working copy used by repository tool tests.
"
Class {
	#name : 'MCPTestRepositoryWorkingCopy',
	#superclass : 'Object',
	#instVars : [
		'repository',
		'packageNames',
		'modifiedPackages',
		'referenceCommit'
	],
	#category : 'MCP-Tests-Resources-Internal',
	#package : 'MCP-Tests-Resources',
	#tag : 'Internal'
}

{ #category : 'instance creation' }
MCPTestRepositoryWorkingCopy class >> packageNames: packageNameCollection modifiedPackages: modifiedPackageCollection [

	^ self new
		  packageNames: packageNameCollection;
		  modifiedPackages: modifiedPackageCollection;
		  yourself
]

{ #category : 'API - commits' }
MCPTestRepositoryWorkingCopy >> adoptCommit: aCommit [

	self referenceCommit = aCommit ifTrue: [ ^ self ].
	referenceCommit := aCommit.
	self repository ifNotNil: [ :owningRepository |
			owningRepository recordAction: 'adoptCommit:' , aCommit id asString.
			owningRepository modifiedPackageNames: #(  ) ]
]

{ #category : 'actions' }
MCPTestRepositoryWorkingCopy >> discardChanges [

	(modifiedPackages ifNil: [ #(  ) ]) do: [ :each | each beDirty: false ].
	self repository recordAction: 'discard'
]

{ #category : 'testing' }
MCPTestRepositoryWorkingCopy >> isModified [

	^ self modifiedPackages notEmpty
]

{ #category : 'accessing' }
MCPTestRepositoryWorkingCopy >> loadedPackages [

	^ modifiedPackages ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPTestRepositoryWorkingCopy >> modifiedPackages [

	^ (modifiedPackages ifNil: [ #(  ) ]) select: #isDirty
]

{ #category : 'accessing' }
MCPTestRepositoryWorkingCopy >> modifiedPackages: aCollection [

	modifiedPackages := aCollection ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPTestRepositoryWorkingCopy >> packageNames [

	^ packageNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPTestRepositoryWorkingCopy >> packageNames: aCollection [

	packageNames := aCollection ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPTestRepositoryWorkingCopy >> packages [

	^ #(  )
]

{ #category : 'API - commits' }
MCPTestRepositoryWorkingCopy >> referenceCommit [

	^ referenceCommit ifNil: [ MCPTestRepositoryCommit id: '' ]
]

{ #category : 'accessing' }
MCPTestRepositoryWorkingCopy >> referenceCommit: aCommit [

	referenceCommit := aCommit
]

{ #category : 'accessing' }
MCPTestRepositoryWorkingCopy >> repository [

	^ repository
]

{ #category : 'accessing' }
MCPTestRepositoryWorkingCopy >> repository: aRepository [

	repository := aRepository
]
