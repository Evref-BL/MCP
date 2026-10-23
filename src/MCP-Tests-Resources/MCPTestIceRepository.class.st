"
Test double for IceRepository used by repository tool tests. It keeps repository metadata in memory.
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
		'modifiedPackages',
		'headCommitId',
		'isDetachedHead',
		'upstreamRemoteName',
		'upstreamBranchName'
	],
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
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

{ #category : 'accessing' }
MCPTestIceRepository >> head [

	^ MCPTestRepositoryHead repository: self
]

{ #category : 'accessing' }
MCPTestIceRepository >> headCommit [

	^ MCPTestRepositoryCommit id: self headCommitId
]

{ #category : 'accessing' }
MCPTestIceRepository >> headCommitId [

	^ headCommitId ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPTestIceRepository >> headCommitId: aString [

	headCommitId := aString
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
	"Super initialization reaches libgit-backed Iceberg state; keep this test double in memory."

	branchName := 'main'.
	headDescription := 'initial'.
	knownBranchNames := OrderedCollection with: branchName.
	remoteNames := #(  ).
	actionLog := OrderedCollection new.
	modifiedPackages := #(  ).
	self workingCopy: (MCPTestRepositoryWorkingCopy packageNames: #(  ) modifiedPackages: #(  )).
	^ self
]

{ #category : 'testing' }
MCPTestIceRepository >> isDetachedHead [

	^ isDetachedHead ifNil: [ false ]
]

{ #category : 'testing' }
MCPTestIceRepository >> isDetachedHead: aBoolean [

	isDetachedHead := aBoolean
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
MCPTestIceRepository >> location [

	^ location
]

{ #category : 'accessing' }
MCPTestIceRepository >> location: aLocation [

	location := aLocation
]

{ #category : 'accessing' }
MCPTestIceRepository >> modifiedPackageNames: aCollection [

	modifiedPackages := (aCollection ifNil: [ #(  ) ]) collect: [ :each | MCPTestRepositoryModifiedPackage named: each ].
	self workingCopy modifiedPackages: modifiedPackages
]

{ #category : 'accessing' }
MCPTestIceRepository >> modifiedPackages [

	^ self workingCopy modifiedPackages
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

	^ self remoteNames collect: [ :each | MCPTestRepositoryRemote named: each repository: self ]
]

{ #category : 'private' }
MCPTestIceRepository >> signalFailureIfNeeded: failure defaultMessage: aString [

	failure ifNil: [ ^ self ].
	failure == false ifTrue: [ ^ self ].
	failure == true ifTrue: [ Error signal: aString ].
	failure isAssociation ifTrue: [ failure key signal: failure value ].
	failure isString ifTrue: [ Error signal: failure ].
	Error signal: failure asString
]

{ #category : 'accessing' }
MCPTestIceRepository >> subdirectory [

	^ ''
]

{ #category : 'accessing' }
MCPTestIceRepository >> upstreamBranchName [

	^ upstreamBranchName ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPTestIceRepository >> upstreamRemoteName [

	^ upstreamRemoteName ifNil: [ '' ]
]

