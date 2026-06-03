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
	#category : 'MCP-DTOs',
	#package : 'MCP',
	#tag : 'DTOs'
}

{ #category : 'instance creation' }
MCPRepositoryInfo class >> commitResultRepository: aRepository packageNames: packageNames modifiedPackageNames: modifiedPackageNames headCommitId: aHeadCommitId headDescription: aHeadDescription [

	^ self new
		  initializeCommitResultRepository: aRepository
		  packageNames: packageNames
		  modifiedPackageNames: modifiedPackageNames
		  headCommitId: aHeadCommitId
		  headDescription: aHeadDescription
]

{ #category : 'instance creation' }
MCPRepositoryInfo class >> fromRepository: aRepository [

	^ self new initializeFromRepository: aRepository
]

{ #category : 'converting' }
MCPRepositoryInfo >> asDictionary [

	^ {
		  (#name -> self name).
		  (#className -> self className).
		  (#location -> self location).
		  (#subdirectory -> self subdirectory).
		  (#branchName -> self branchName).
		  (#headDescription -> self headDescription).
		  (#headClassName -> self headClassName).
		  (#headCommitId -> self headCommitId).
		  (#isDetachedHead -> self isDetachedHead).
		  (#isMissing -> self isMissing).
		  (#isModified -> self isModified).
		  (#packageNames -> self packageNames).
		  (#modifiedPackageNames -> self modifiedPackageNames).
		  (#remotes -> self remotes).
		  (#upstreamRemoteName -> self upstreamRemoteName).
		  (#upstreamBranchName -> self upstreamBranchName).
		  (#upstreamRemoteUrl -> self upstreamRemoteUrl) } asDictionary
]

{ #category : 'converting' }
MCPRepositoryInfo >> asQueryDictionary [

	^ self asDictionary
]

{ #category : 'private' }
MCPRepositoryInfo >> booleanFrom: aBlock default: defaultBoolean [

	^ aBlock value ifNil: [ defaultBoolean ]
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
MCPRepositoryInfo >> initializeCommitResultRepository: aRepository packageNames: repositoryPackageNames modifiedPackageNames: repositoryModifiedPackageNames headCommitId: aHeadCommitId headDescription: aHeadDescription [

	name := self stringFrom: [ aRepository name ] default: ''.
	className := aRepository class name asString.
	location := self repositoryLocationFor: aRepository.
	subdirectory := self repositorySubdirectoryFor: aRepository.
	branchName := ''.
	headDescription := aHeadDescription ifNil: [ '' ].
	headClassName := ''.
	headCommitId := aHeadCommitId ifNil: [ '' ].
	isDetachedHead := false.
	isMissing := false.
	isModified := repositoryModifiedPackageNames notEmpty.
	packageNames := repositoryPackageNames ifNil: [ #(  ) ].
	modifiedPackageNames := repositoryModifiedPackageNames ifNil: [
		                        #(  ) ].
	remotes := #(  ).
	upstreamRemoteName := ''.
	upstreamBranchName := ''.
	upstreamRemoteUrl := ''
]

{ #category : 'initialization' }
MCPRepositoryInfo >> initializeFromRepository: aRepository [

	| upstreamInfo |
	name := self stringFrom: [ aRepository name ] default: ''.
	className := aRepository class name asString.
	location := self repositoryLocationFor: aRepository.
	subdirectory := self repositorySubdirectoryFor: aRepository.
	branchName := self repositoryBranchNameFor: aRepository.
	headDescription := self repositoryHeadDescriptionFor: aRepository.
	headClassName := self repositoryHeadClassNameFor: aRepository.
	headCommitId := self repositoryHeadCommitIdFor: aRepository.
	isDetachedHead := self repositoryIsDetachedHeadFor: aRepository.
	isMissing := self
		             booleanFrom: [ aRepository isMissing ]
		             default: false.
	isModified := self
		              booleanFrom: [ aRepository isModified ]
		              default: false.
	packageNames := self repositoryPackageNamesFor: aRepository.
	modifiedPackageNames := self repositoryModifiedPackageNamesFor:
		                        aRepository.
	remotes := self repositoryRemotesFor: aRepository.
	upstreamInfo := self repositoryUpstreamInfoFor: aRepository.
	upstreamRemoteName := upstreamInfo at: #remoteName.
	upstreamBranchName := upstreamInfo at: #branchName.
	upstreamRemoteUrl := upstreamInfo at: #remoteUrl
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
MCPRepositoryInfo >> remoteNames [

	^ ((self remotes collect: [ :each | each at: #name ifAbsent: [ '' ] ])
		   reject: [ :each | each isEmpty ]) asArray
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
			  ifFalse: [ self stringValue: aRepository branchName default: '' ] ]
		  on: NotFound
		  do: [ :ignored | '' ]
]

{ #category : 'private' }
MCPRepositoryInfo >> repositoryHeadClassNameFor: aRepository [

	aRepository location ifNil: [ ^ '' ].
	^ [ self stringFrom: [ aRepository head class name ] default: '' ]
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
	^ [ self stringFrom: [ aRepository headDescription ] default: '' ]
		  on: NotFound
		  do: [ :ignored | '' ]
]

{ #category : 'private' }
MCPRepositoryInfo >> repositoryIsDetachedHeadFor: aRepository [

	aRepository location ifNil: [ ^ false ].
	^ [ self booleanFrom: [ aRepository head isDetached ] default: false ]
		  on: NotFound
		  do: [ :ignored | false ]
]

{ #category : 'private' }
MCPRepositoryInfo >> repositoryLocationFor: aRepository [

	^ self
		  stringFrom: [
				  aRepository location ifNotNil: [ :repositoryLocation |
					  repositoryLocation mcpRepositoryLocationString ] ]
		  default: ''
]

{ #category : 'private' }
MCPRepositoryInfo >> repositoryModifiedPackageNamesFor: aRepository [

	^ self sortedStringsFrom: [
		  aRepository modifiedPackages collect: [ :each | each name ] ]
]

{ #category : 'private' }
MCPRepositoryInfo >> repositoryPackageNamesFor: aRepository [

	^ self sortedStringsFrom: [ aRepository workingCopy packageNames ]
]

{ #category : 'private' }
MCPRepositoryInfo >> repositoryRemotesFor: aRepository [

	^ (MCPGitRepositoryMetadata forRepository: aRepository)
		  remoteDictionaries
]

{ #category : 'private' }
MCPRepositoryInfo >> repositorySubdirectoryFor: aRepository [

	^ self stringFrom: [ aRepository subdirectory ] default: ''
]

{ #category : 'private' }
MCPRepositoryInfo >> repositoryUpstreamInfoFor: aRepository [

	^ (MCPGitRepositoryMetadata forRepository: aRepository)
		  upstreamInfoForBranchNamed: self branchName
]

{ #category : 'private' }
MCPRepositoryInfo >> sortedStringsFrom: aBlock [

	| values |
	values := aBlock value ifNil: [ #(  ) ].
	^ (Array streamContents: [ :stream |
			   values do: [ :each |
					   | string |
					   string := self stringValue: each default: ''.
					   string isEmpty ifFalse: [ stream nextPut: string ] ] ]) sort
]

{ #category : 'private' }
MCPRepositoryInfo >> stringFrom: aBlock default: defaultString [

	^ self stringValue: aBlock value default: defaultString
]

{ #category : 'private' }
MCPRepositoryInfo >> stringValue: aValue default: defaultString [

	aValue ifNil: [ ^ defaultString ].
	^ aValue asString
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
