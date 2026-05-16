"
DTO for registered Iceberg repository metadata.

It is read-only and intended for find-repositories responses and repository operation summaries. The DTO normalizes repository, head, remote, upstream, and package state from different Iceberg repository implementations while keeping tool output independent from Iceberg objects.
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

	^ [ aBlock value ifNil: [ defaultBoolean ] ]
		  on: Error
		  do: [ :ignored | defaultBoolean ]
]

{ #category : 'accessing' }
MCPRepositoryInfo >> branchName [

	^ branchName
]

{ #category : 'accessing' }
MCPRepositoryInfo >> className [

	^ className
]

{ #category : 'private' }
MCPRepositoryInfo >> emptyUpstreamInfo [

	^ {
		  (#remoteName -> '').
		  (#branchName -> '').
		  (#remoteUrl -> '') } asDictionary
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
	upstreamRemoteUrl := ''.
	^ self
]

{ #category : 'initialization' }
MCPRepositoryInfo >> initializeFromRepository: aRepository [

	| upstreamInfo |
	name := self stringFrom: [ aRepository name ] default: ''.
	className := aRepository class name asString.
	location := self repositoryLocationFor: aRepository.
	subdirectory := self repositorySubdirectoryFor: aRepository.
	branchName := self stringFrom: [ aRepository branchName ] default: ''.
	headDescription := self
		                   stringFrom: [ aRepository headDescription ]
		                   default: ''.
	headClassName := self repositoryHeadClassNameFor: aRepository.
	headCommitId := self repositoryHeadCommitIdFor: aRepository.
	isDetachedHead := self repositoryIsDetachedHeadFor: aRepository.
	isMissing := self
		             booleanFrom: [
			             (aRepository respondsTo: #isMissing)
				             ifTrue: [ aRepository isMissing ]
				             ifFalse: [ false ] ]
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
	upstreamRemoteUrl := upstreamInfo at: #remoteUrl.
	^ self
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

{ #category : 'private' }
MCPRepositoryInfo >> remoteDictionaryFor: aRemote [

	^ {
		  (#name -> (self stringFrom: [ aRemote name ] default: '')).
		  (#url -> (self stringFrom: [ aRemote url ] default: '')) }
		  asDictionary
]

{ #category : 'accessing' }
MCPRepositoryInfo >> remoteNames [

	^ ((self remotes collect: [ :each | each at: #name ifAbsent: [ '' ] ])
		   reject: [ :each | each isEmpty ]) asArray
]

{ #category : 'private' }
MCPRepositoryInfo >> remoteUrlNamed: aRemoteName in: aRepository [

	| remote |
	aRemoteName isEmpty ifTrue: [ ^ '' ].
	remote := [
	          aRepository remotes
		          detect: [ :each |
		          (self stringValue: each name default: '') = aRemoteName ]
		          ifNone: [ nil ] ]
		          on: Error
		          do: [ :ignored | nil ].
	remote ifNil: [ ^ '' ].
	^ self stringFrom: [ remote url ] default: ''
]

{ #category : 'accessing' }
MCPRepositoryInfo >> remotes [

	^ remotes ifNil: [ #(  ) ]
]

{ #category : 'private' }
MCPRepositoryInfo >> repositoryHeadClassNameFor: aRepository [

	^ self stringFrom: [ aRepository head class name ] default: ''
]

{ #category : 'private' }
MCPRepositoryInfo >> repositoryHeadCommitIdFor: aRepository [

	^ self stringFrom: [ aRepository headCommit id ] default: ''
]

{ #category : 'private' }
MCPRepositoryInfo >> repositoryIsDetachedHeadFor: aRepository [

	^ self
		  booleanFrom: [
			  | head |
			  head := aRepository head.
			  (head respondsTo: #isDetached)
				  ifTrue: [ head isDetached ]
				  ifFalse: [ head class name asString = 'IceGitCommit' ] ]
		  default: false
]

{ #category : 'private' }
MCPRepositoryInfo >> repositoryLocationFor: aRepository [

	^ self
		  stringFrom: [
			  (aRepository respondsTo: #location)
				  ifTrue: [ aRepository location ]
				  ifFalse: [ '' ] ]
		  default: ''
]

{ #category : 'private' }
MCPRepositoryInfo >> repositoryModifiedPackageNamesFor: aRepository [

	^ self sortedStringsFrom: [
		  (aRepository respondsTo: #modifiedPackages)
			  ifTrue: [
			  aRepository modifiedPackages collect: [ :each | each name ] ]
			  ifFalse: [ #(  ) ] ]
]

{ #category : 'private' }
MCPRepositoryInfo >> repositoryPackageNamesFor: aRepository [

	^ self sortedStringsFrom: [
		  (aRepository respondsTo: #workingCopy)
			  ifTrue: [ aRepository workingCopy packageNames ]
			  ifFalse: [ #(  ) ] ]
]

{ #category : 'private' }
MCPRepositoryInfo >> repositoryRemotesFor: aRepository [

	| normalized values |
	values := [
	          (aRepository respondsTo: #remotes)
		          ifTrue: [ aRepository remotes ]
		          ifFalse: [ #(  ) ] ]
		          on: Error
		          do: [ :ignored | #(  ) ].
	normalized := OrderedCollection new.
	values do: [ :each |
		| remoteDictionary |
		remoteDictionary := self remoteDictionaryFor: each.
		((remoteDictionary at: #name) isEmpty and: [
			 (remoteDictionary at: #url) isEmpty ]) not ifTrue: [
			normalized add: remoteDictionary ] ].
	^ (normalized asArray asSortedCollection: [ :left :right |
		   (left at: #name) <= (right at: #name) ]) asArray
]

{ #category : 'private' }
MCPRepositoryInfo >> repositorySubdirectoryFor: aRepository [

	^ self
		  stringFrom: [
			  (aRepository respondsTo: #subdirectory)
				  ifTrue: [ aRepository subdirectory ]
				  ifFalse: [ '' ] ]
		  default: ''
]

{ #category : 'private' }
MCPRepositoryInfo >> repositoryUpstreamInfoFor: aRepository [

	| head remoteName resolvedUpstreamBranchName upstream |
	head := [ aRepository head ]
		        on: Error
		        do: [ :ignored | ^ self emptyUpstreamInfo ].
	((head respondsTo: #hasUpstream) and: [
		 [ head hasUpstream ]
			 on: Error
			 do: [ :ignored | false ] ]) ifFalse: [ ^ self emptyUpstreamInfo ].
	upstream := [ head upstream ]
		            on: Error
		            do: [ :ignored | ^ self emptyUpstreamInfo ].
	remoteName := self stringFrom: [ upstream remoteName ] default: ''.
	resolvedUpstreamBranchName := self
		                              stringFrom: [
			                              (upstream respondsTo: #shortname)
				                              ifTrue: [ upstream shortname ]
				                              ifFalse: [ upstream name ] ]
		                              default: ''.
	^ {
		  (#remoteName -> remoteName).
		  (#branchName -> resolvedUpstreamBranchName).
		  (#remoteUrl -> (self remoteUrlNamed: remoteName in: aRepository)) }
		  asDictionary
]

{ #category : 'private' }
MCPRepositoryInfo >> sortedStringsFrom: aBlock [

	| normalized values |
	values := [ aBlock value ifNil: [ #(  ) ] ]
		          on: Error
		          do: [ :ignored | #(  ) ].
	normalized := OrderedCollection new.
	values do: [ :each |
		| string |
		string := self stringValue: each default: ''.
		string isEmpty ifFalse: [ normalized add: string ] ].
	^ normalized asArray asSortedCollection asArray
]

{ #category : 'private' }
MCPRepositoryInfo >> stringFrom: aBlock default: defaultString [

	^ [ self stringValue: aBlock value default: defaultString ]
		  on: Error
		  do: [ :ignored | defaultString ]
]

{ #category : 'private' }
MCPRepositoryInfo >> stringValue: aValue default: defaultString [

	aValue ifNil: [ ^ defaultString ].
	(aValue respondsTo: #pathString) ifTrue: [
		^ aValue pathString asString ].
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
