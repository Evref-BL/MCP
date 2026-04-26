"
Test double for IceRepository used by repository tool tests. It keeps repository metadata in memory and simulates remote operations without network access.
"
Class {
	#name : 'MCPTestIceRepository',
	#superclass : 'IceRepository',
	#instVars : [
		'location',
		'branchName',
		'headDescription',
		'remoteNames',
		'actionLog',
		'failFetch',
		'failPull',
		'failPush',
		'failCreateBranch',
		'failSwitchBranch',
		'knownBranchNames',
		'modifiedPackages'
	],
	#category : 'MCP-Tests-Internal',
	#package : 'MCP-Tests',
	#tag : 'Internal'
}

{ #category : 'instance creation' }
MCPTestIceRepository class >> named: aName location: aLocation [

	^ self new
		  name: aName;
		  location: aLocation;
		  yourself
]

{ #category : 'accessing' }
MCPTestIceRepository >> actionLog [

	^ actionLog ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPTestIceRepository >> branch [

	^ MCPTestRepositoryBranch repository: self
]

{ #category : 'accessing' }
MCPTestIceRepository >> branchName [

	^ branchName ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPTestIceRepository >> branchName: aString [

	branchName := aString
]

{ #category : 'API - branches' }
MCPTestIceRepository >> createBranch: aBranchName [

	self
		signalFailureIfNeeded: self failCreateBranch
		defaultMessage: 'Create branch failed for test repository'.
	(self knownBranchNames includes: aBranchName) ifTrue: [
		IceBranchAlreadyExists signal:
			'Branch already exists: ' , aBranchName ].
	knownBranchNames add: aBranchName.
	branchName := aBranchName.
	headDescription := 'branch ' , aBranchName.
	self recordAction: 'createBranch:' , aBranchName
]

{ #category : 'testing' }
MCPTestIceRepository >> failCreateBranch [

	^ failCreateBranch ifNil: [ false ]
]

{ #category : 'testing' }
MCPTestIceRepository >> failCreateBranch: aBoolean [

	failCreateBranch := aBoolean
]

{ #category : 'testing' }
MCPTestIceRepository >> failFetch [

	^ failFetch ifNil: [ false ]
]

{ #category : 'testing' }
MCPTestIceRepository >> failFetch: aBoolean [

	failFetch := aBoolean
]

{ #category : 'testing' }
MCPTestIceRepository >> failPull [

	^ failPull ifNil: [ false ]
]

{ #category : 'testing' }
MCPTestIceRepository >> failPull: aBoolean [

	failPull := aBoolean
]

{ #category : 'testing' }
MCPTestIceRepository >> failPush [

	^ failPush ifNil: [ false ]
]

{ #category : 'testing' }
MCPTestIceRepository >> failPush: aBoolean [

	failPush := aBoolean
]

{ #category : 'testing' }
MCPTestIceRepository >> failSwitchBranch [

	^ failSwitchBranch ifNil: [ false ]
]

{ #category : 'testing' }
MCPTestIceRepository >> failSwitchBranch: aBoolean [

	failSwitchBranch := aBoolean
]

{ #category : 'accessing' }
MCPTestIceRepository >> headDescription [

	^ headDescription ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPTestIceRepository >> headDescription: aString [

	headDescription := aString
]

{ #category : 'initialization' }
MCPTestIceRepository >> initialize [

	branchName := 'main'.
	headDescription := 'initial'.
	knownBranchNames := OrderedCollection with: branchName.
	remoteNames := #(  ).
	actionLog := OrderedCollection new.
	modifiedPackages := #(  ).
	self workingCopy: (MCPTestRepositoryWorkingCopy
			 packageNames: #(  )
			 modifiedPackages: #(  )).
	^ self
]

{ #category : 'testing' }
MCPTestIceRepository >> isMissing [

	^ false
]

{ #category : 'testing' }
MCPTestIceRepository >> isModified [

	^ self modifiedPackages notEmpty
]

{ #category : 'accessing' }
MCPTestIceRepository >> knownBranchNames [

	^ knownBranchNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPTestIceRepository >> location [

	^ location ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPTestIceRepository >> location: aLocation [

	location := aLocation
]

{ #category : 'accessing' }
MCPTestIceRepository >> modifiedPackageNames: aCollection [

	modifiedPackages := (aCollection ifNil: [ #(  ) ]) collect: [ :each |
		                    MCPTestRepositoryModifiedPackage named: each ].
	self workingCopy modifiedPackages: modifiedPackages
]

{ #category : 'accessing' }
MCPTestIceRepository >> modifiedPackages [

	^ modifiedPackages ifNil: [ #(  ) ]
]

{ #category : 'actions' }
MCPTestIceRepository >> recordAction: anActionName [

	actionLog ifNil: [ actionLog := OrderedCollection new ].
	actionLog add: anActionName
]

{ #category : 'accessing' }
MCPTestIceRepository >> remoteNames [

	^ remoteNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPTestIceRepository >> remoteNames: aCollection [

	remoteNames := aCollection ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPTestIceRepository >> remotes [

	^ self remoteNames collect: [ :each |
		  MCPTestRepositoryRemote
			  named: each
			  repository: self
			  shouldFail: self failFetch ]
]

{ #category : 'private' }
MCPTestIceRepository >> signalFailureIfNeeded: failure defaultMessage: aString [

	failure ifNil: [ ^ self ].
	failure = false ifTrue: [ ^ self ].
	failure == true ifTrue: [ Error signal: aString ].
	(failure isAssociation and: [ failure key isBehavior ]) ifTrue: [
		failure key signal: failure value ].
	failure isString ifTrue: [ Error signal: failure ].
	(failure isKindOf: Exception) ifTrue: [ failure signal ].
	Error signal: failure asString
]

{ #category : 'accessing' }
MCPTestIceRepository >> subdirectory [

	^ ''
]

{ #category : 'API - branches' }
MCPTestIceRepository >> switchToBranchNamed: aBranchName [

	self
		signalFailureIfNeeded: self failSwitchBranch
		defaultMessage: 'Switch branch failed for test repository'.
	(self knownBranchNames includes: aBranchName) ifFalse: [
		IceBranchNotFound signal: 'Branch not found: ' , aBranchName ].
	branchName := aBranchName.
	headDescription := 'branch ' , aBranchName.
	self recordAction: 'switchBranch:' , aBranchName
]
