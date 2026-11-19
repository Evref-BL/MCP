"
DTO for registered Iceberg repository metadata.

It is read-only and intended for repository_search responses and repository operation summaries. The DTO normalizes repository, head, remote, upstream, and package state from different Iceberg repository implementations while keeping tool output independent from Iceberg objects.
"
Class {
	#name : 'MCPRepositoryInfo',
	#superclass : 'Object',
	#instVars : [
		'name',
		'className',
		'location',
		'subdirectory',
		'branchName',
		'headDescription',
		'headClassName',
		'headCommitId',
		'isDetachedHead',
		'isMissing',
		'isModified',
		'packageNames',
		'modifiedPackageNames',
		'remotes',
		'upstreamRemoteName',
		'upstreamBranchName',
		'upstreamRemoteUrl'
	],
	#category : 'MCP-IDE-DTOs',
	#package : 'MCP-IDE',
	#tag : 'DTOs'
}

{ #category : 'instance creation' }
MCPRepositoryInfo class >> fromRepository: aRepository [

	^ [ self new initializeFromRepository: aRepository ]
		  on: FileException
		  do: [ :ignored | self new initializeStaleRepository: aRepository ]
]

{ #category : 'converting' }
MCPRepositoryInfo >> asDictionary [

	^ {
		  (#name -> self name).
		  (#class -> self className).
		  (#location -> self location).
		  (#subdirectory -> self subdirectory).
		  (#branch -> self branchName).
		  (#headDescription -> self headDescription).
		  (#headClassName -> self headClassName).
		  (#headCommitId -> self headCommitId).
		  (#isDetachedHead -> self isDetachedHead).
		  (#isMissing -> self isMissing).
		  (#isModified -> self isModified).
		  (#packages -> self packageNames).
		  (#modifiedPackages -> self modifiedPackageNames).
		  (#remotes -> self remotes).
		  (#upstreamRemoteName -> self upstreamRemoteName).
		  (#upstreamBranchName -> self upstreamBranchName).
		  (#upstreamRemoteUrl -> self upstreamRemoteUrl) } asDictionary
]

{ #category : 'converting' }
MCPRepositoryInfo >> asSearchDictionary [
	"A search says a repository exists, where it is and what is dirty in it. Which packages it holds is
	what package_search answers. A repository registered with no location has none to name."

	| data |
	data := Dictionary new.
	data
		at: #name put: self name;
		at: #isModified put: self isModified;
		at: #isMissing put: self isMissing.
	self location ifNotEmpty: [ :value | data at: #location put: value ].
	self subdirectory ifNotNil: [ :value | value ifNotEmpty: [ data at: #subdirectory put: value ] ].
	self packageNames ifNotEmpty: [ :names | data at: #packageCount put: names size ].
	self modifiedPackageNames ifNotEmpty: [ :names | data at: #modifiedPackages put: names ].
	^ data
]

{ #category : 'accessing' }
MCPRepositoryInfo >> branchName [

	^ branchName
]

{ #category : 'accessing' }
MCPRepositoryInfo >> className [

	^ className
]

{ #category : 'accessing' }
MCPRepositoryInfo >> headClassName [

	^ headClassName ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPRepositoryInfo >> headCommitId [

	^ headCommitId ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPRepositoryInfo >> headDescription [

	^ headDescription
]

{ #category : 'initialization' }
MCPRepositoryInfo >> initializeFromRepository: aRepository [
	"The remotes and the upstream come from one reading of the repository's git files."

	| metadata upstreamInfo |
	name := (aRepository name ifNil: [ '' ]) asString.
	className := aRepository class name asString.
	location := aRepository mcpLocationString.
	subdirectory := (aRepository subdirectory ifNil: [ '' ]) asString.
	branchName := self repositoryBranchNameFor: aRepository.
	headDescription := self repositoryHeadDescriptionFor: aRepository.
	headClassName := self repositoryHeadClassNameFor: aRepository.
	headCommitId := self repositoryHeadCommitIdFor: aRepository.
	isDetachedHead := self repositoryIsDetachedHeadFor: aRepository.
	isMissing := aRepository isMissing ifNil: [ false ].
	isModified := aRepository isModified ifNil: [ false ].
	packageNames := self sortedStringsFrom: aRepository workingCopy packageNames.
	modifiedPackageNames := self sortedStringsFrom: (aRepository modifiedPackages collect: [ :each | each name ]).
	metadata := MCPGitRepositoryMetadata forRepository: aRepository.
	remotes := metadata remoteDictionaries.
	upstreamInfo := metadata upstreamInfoForBranchNamed: self branchName.
	upstreamRemoteName := upstreamInfo at: #remoteName.
	upstreamBranchName := upstreamInfo at: #branch.
	upstreamRemoteUrl := upstreamInfo at: #remoteUrl
]

{ #category : 'initialization' }
MCPRepositoryInfo >> initializeStaleRepository: aRepository [

	name := self stringFromFileBoundary: [ aRepository name ] default: ''.
	className := aRepository class name asString.
	location := self stringFromFileBoundary: [ aRepository mcpLocationString ] default: ''.
	subdirectory := self stringFromFileBoundary: [ aRepository subdirectory ] default: ''.
	branchName := ''.
	headDescription := ''.
	headClassName := ''.
	headCommitId := ''.
	isDetachedHead := false.
	isMissing := true.
	isModified := false.
	packageNames := #(  ).
	modifiedPackageNames := #(  ).
	remotes := #(  ).
	upstreamRemoteName := ''.
	upstreamBranchName := ''.
	upstreamRemoteUrl := ''
]

{ #category : 'accessing' }
MCPRepositoryInfo >> isDetachedHead [

	^ isDetachedHead ifNil: [ false ]
]

{ #category : 'accessing' }
MCPRepositoryInfo >> isMissing [

	^ isMissing
]

{ #category : 'accessing' }
MCPRepositoryInfo >> isModified [

	^ isModified
]

{ #category : 'accessing' }
MCPRepositoryInfo >> location [

	^ location
]

{ #category : 'accessing' }
MCPRepositoryInfo >> modifiedPackageNames [

	^ modifiedPackageNames
]

{ #category : 'accessing' }
MCPRepositoryInfo >> name [

	^ name
]

{ #category : 'accessing' }
MCPRepositoryInfo >> packageNames [

	^ packageNames
]

{ #category : 'accessing' }
MCPRepositoryInfo >> remotes [

	^ remotes ifNil: [ #(  ) ]
]

{ #category : 'private' }
MCPRepositoryInfo >> repositoryBranchNameFor: aRepository [

	aRepository location ifNil: [ ^ '' ].
	^ [
		  aRepository head isDetached
			  ifTrue: [ '' ]
			  ifFalse: [ (aRepository branchName ifNil: [ '' ]) asString ] ]
		  on: NotFound
		  do: [ :ignored | '' ]
]

{ #category : 'private' }
MCPRepositoryInfo >> repositoryHeadClassNameFor: aRepository [

	aRepository location ifNil: [ ^ '' ].
	^ [ aRepository head class name asString ]
		  on: NotFound
		  do: [ :ignored | '' ]
]

{ #category : 'private' }
MCPRepositoryInfo >> repositoryHeadCommitIdFor: aRepository [

	aRepository location ifNil: [ ^ '' ].
	^ [ MCPIcebergCommitInfo idStringFrom: aRepository headCommit ]
		  on: NotFound
		  do: [ :ignored | '' ]
]

{ #category : 'private' }
MCPRepositoryInfo >> repositoryHeadDescriptionFor: aRepository [

	aRepository location ifNil: [ ^ '' ].
	^ [ (aRepository headDescription ifNil: [ '' ]) asString ]
		  on: NotFound
		  do: [ :ignored | '' ]
]

{ #category : 'private' }
MCPRepositoryInfo >> repositoryIsDetachedHeadFor: aRepository [

	aRepository location ifNil: [ ^ false ].
	^ [ aRepository head isDetached ifNil: [ false ] ]
		  on: NotFound
		  do: [ :ignored | false ]
]

{ #category : 'private' }
MCPRepositoryInfo >> sortedStringsFrom: someValues [

	^ (((someValues ifNil: [ #(  ) ]) collect: [ :each | (each ifNil: [ '' ]) asString ] as: Array) reject: [ :each | each isEmpty ])
		  sort
]

{ #category : 'private' }
MCPRepositoryInfo >> stringFromFileBoundary: aBlock default: defaultString [
	"A stale repository's handle may fail on the file system as it is read."

	^ [ (aBlock value ifNil: [ defaultString ]) asString ]
		  on: FileException
		  do: [ :ignored | defaultString ]
]

{ #category : 'accessing' }
MCPRepositoryInfo >> subdirectory [

	^ subdirectory
]

{ #category : 'accessing' }
MCPRepositoryInfo >> upstreamBranchName [

	^ upstreamBranchName ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPRepositoryInfo >> upstreamRemoteName [

	^ upstreamRemoteName ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPRepositoryInfo >> upstreamRemoteUrl [

	^ upstreamRemoteUrl ifNil: [ '' ]
]
