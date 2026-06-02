"
Reads safe, file-backed Git repository metadata for MCP repository DTOs.

Iceberg's libgit-backed remote and upstream access can crash the VM when its native repository handle is stale. This helper intentionally reads only plain Git files such as .git/config and worktree commondir files for read-only metadata. Real Git operations still belong to Iceberg.
"
Class {
	#name : 'MCPGitRepositoryMetadata',
	#superclass : 'Object',
	#instVars : [
		'location',
		'gitDirectory',
		'configEntries'
	],
	#category : 'MCP-Support',
	#package : 'MCP',
	#tag : 'Support'
}

{ #category : 'instance creation' }
MCPGitRepositoryMetadata class >> forRepository: aRepository [

	^ self new initializeForRepository: aRepository
]

{ #category : 'instance creation' }
MCPGitRepositoryMetadata class >> fromLocationString: aString [

	^ self new initializeWithLocationString: aString
]

{ #category : 'private - parsing' }
MCPGitRepositoryMetadata >> branchNameFromMerge: mergeReference [

	| prefix |
	prefix := 'refs/heads/'.
	(mergeReference beginsWith: prefix) ifFalse: [ ^ mergeReference ].
	^ mergeReference allButFirst: prefix size
]

{ #category : 'private - files' }
MCPGitRepositoryMetadata >> commonGitDirectoryFor: aGitDirectory [

	| commonPath contents |
	aGitDirectory ifNil: [ ^ nil ].
	contents := self
		            fileContentsOf: aGitDirectory / 'commondir'
		            ifAbsent: [ ^ aGitDirectory ].
	commonPath := contents lines
		              ifEmpty: [ '' ]
		              ifNotEmpty: [ :lines | lines first trimBoth ].
	commonPath isEmpty ifTrue: [ ^ aGitDirectory ].
	^ self directoryFromPath: commonPath relativeTo: aGitDirectory
]

{ #category : 'accessing' }
MCPGitRepositoryMetadata >> configEntries [

	^ configEntries ifNil: [ Dictionary new ]
]

{ #category : 'private - parsing' }
MCPGitRepositoryMetadata >> configEntriesFromFile: configFile [

	| contents |
	contents := self
		            fileContentsOf: configFile
		            ifAbsent: [ ^ Dictionary new ].
	^ self parseConfig: contents
]

{ #category : 'private - parsing' }
MCPGitRepositoryMetadata >> configEntriesFromGitDirectory: aGitDirectory [

	aGitDirectory ifNil: [ ^ Dictionary new ].
	^ self configEntriesFromFile: aGitDirectory / 'config'
]

{ #category : 'private - files' }
MCPGitRepositoryMetadata >> directoryFromPath: pathString relativeTo: baseDirectory [

	| reference |
	pathString isEmpty ifTrue: [ ^ nil ].
	reference := pathString asFileReference.
	reference isAbsolute ifTrue: [ ^ reference canonicalize ].
	^ (baseDirectory resolveString: pathString) canonicalize
]

{ #category : 'private' }
MCPGitRepositoryMetadata >> emptyUpstreamInfo [

	^ {
		  (#remoteName -> '').
		  (#branchName -> '').
		  (#remoteUrl -> '') } asDictionary
]

{ #category : 'private - files' }
MCPGitRepositoryMetadata >> fileContentsOf: aFileReference ifAbsent: absentBlock [

	aFileReference ifNil: [ ^ absentBlock value ].
	^ [
		  (aFileReference exists and: [ aFileReference isFile ])
			  ifTrue: [ aFileReference contents ]
			  ifFalse: [ absentBlock value ] ]
		  on: FileException , FileSystemError , ZnCharacterEncodingError
		  do: [ :ignored | absentBlock value ]
]

{ #category : 'accessing' }
MCPGitRepositoryMetadata >> gitDirectory [

	^ gitDirectory
]

{ #category : 'private - files' }
MCPGitRepositoryMetadata >> gitDirectoryForLocation: aLocationString [

	| dotGit repositoryDirectory |
	aLocationString isEmpty ifTrue: [ ^ nil ].
	repositoryDirectory := aLocationString asFileReference.
	dotGit := repositoryDirectory / '.git'.
	dotGit isDirectory ifTrue: [ ^ self commonGitDirectoryFor: dotGit ].
	dotGit exists ifFalse: [ ^ nil ].
	^ self commonGitDirectoryFor: (self
			   gitDirectoryFromGitFile: dotGit
			   repositoryDirectory: repositoryDirectory)
]

{ #category : 'private - files' }
MCPGitRepositoryMetadata >> gitDirectoryFromGitFile: gitFile repositoryDirectory: repositoryDirectory [

	| contents gitdirPath |
	contents := self fileContentsOf: gitFile ifAbsent: [ ^ nil ].
	gitdirPath := self gitdirPathFrom: contents.
	gitdirPath isEmpty ifTrue: [ ^ nil ].
	^ self directoryFromPath: gitdirPath relativeTo: repositoryDirectory
]

{ #category : 'private - parsing' }
MCPGitRepositoryMetadata >> gitdirPathFrom: fileContents [

	| line prefix trimmed |
	prefix := 'gitdir:'.
	line := fileContents lines
		        detect: [ :each | each trimBoth beginsWith: prefix ]
		        ifNone: [ ^ '' ].
	trimmed := line trimBoth.
	^ (trimmed copyFrom: prefix size + 1 to: trimmed size) trimBoth
]

{ #category : 'initialization' }
MCPGitRepositoryMetadata >> initializeForRepository: aRepository [

	^ self initializeWithLocationString:
		  (aRepository location ifNotNil: [ :repositoryLocation |
			   repositoryLocation mcpRepositoryLocationString ])
]

{ #category : 'initialization' }
MCPGitRepositoryMetadata >> initializeWithLocationString: aString [

	location := aString ifNil: [ '' ].
	gitDirectory := self gitDirectoryForLocation: location.
	configEntries := self configEntriesFromGitDirectory: gitDirectory.
	^ self
]

{ #category : 'private - parsing' }
MCPGitRepositoryMetadata >> isCommentLine: aString [

	^ aString first = $# or: [ aString first = $; ]
]

{ #category : 'private - parsing' }
MCPGitRepositoryMetadata >> isRemoteSectionName: sectionName [

	^ sectionName beginsWith: 'remote.'
]

{ #category : 'accessing' }
MCPGitRepositoryMetadata >> location [

	^ location ifNil: [ '' ]
]

{ #category : 'private - parsing' }
MCPGitRepositoryMetadata >> nameFromSectionName: sectionName prefix: prefix [

	(sectionName beginsWith: prefix) ifFalse: [ ^ '' ].
	^ sectionName allButFirst: prefix size
]

{ #category : 'private - parsing' }
MCPGitRepositoryMetadata >> parseConfig: fileContents [

	| currentEntries entries trimmed |
	entries := Dictionary new.
	currentEntries := nil.
	fileContents lines do: [ :line |
			trimmed := line trimBoth.
			(trimmed isEmpty or: [ self isCommentLine: trimmed ]) ifFalse: [
					(self sectionNameFromLine: trimmed)
						ifNil: [
								currentEntries ifNotNil: [
									self storeConfigEntryFromLine: trimmed in: currentEntries ] ]
						ifNotNil: [ :sectionName |
								currentEntries := entries
									                  at: sectionName
									                  ifAbsentPut: [ Dictionary new ] ] ] ].
	^ entries
]

{ #category : 'accessing' }
MCPGitRepositoryMetadata >> remoteDictionaries [

	| remotes |
	remotes := OrderedCollection new.
	self configEntries keysAndValuesDo: [ :sectionName :entries |
			(self isRemoteSectionName: sectionName) ifTrue: [
					| remoteName remoteUrl |
					remoteName := self
						              nameFromSectionName: sectionName
						              prefix: 'remote.'.
					remoteUrl := entries at: 'url' ifAbsent: [ '' ].
					(remoteName isEmpty and: [ remoteUrl isEmpty ]) ifFalse: [
							remotes add: {
									(#name -> remoteName).
									(#url -> remoteUrl) } asDictionary ] ] ].
	^ remotes asArray sort: [ :left :right |
		  (left at: #name) <= (right at: #name) ]
]

{ #category : 'accessing' }
MCPGitRepositoryMetadata >> remoteUrlNamed: aRemoteName [

	| remoteEntries |
	aRemoteName isEmpty ifTrue: [ ^ '' ].
	remoteEntries := self configEntries
		                 at: 'remote.' , aRemoteName
		                 ifAbsent: [ ^ '' ].
	^ remoteEntries at: 'url' ifAbsent: [ '' ]
]

{ #category : 'private - parsing' }
MCPGitRepositoryMetadata >> sectionNameFromLine: aString [

	| header quoteEnd quoteStart sectionName |
	((aString beginsWith: '[') and: [ aString endsWith: ']' ]) ifFalse: [
		^ nil ].
	header := (aString copyFrom: 2 to: aString size - 1) trimBoth.
	quoteStart := header indexOf: $".
	quoteStart isZero ifTrue: [ ^ header ].
	quoteEnd := header lastIndexOf: $".
	quoteEnd <= quoteStart ifTrue: [ ^ header ].
	sectionName := (header copyFrom: 1 to: quoteStart - 1) trimBoth.
	sectionName isEmpty ifTrue: [
		^ (header copyFrom: quoteStart + 1 to: quoteEnd - 1) trimBoth ].
	^ sectionName , '.'
	  , (header copyFrom: quoteStart + 1 to: quoteEnd - 1) trimBoth
]

{ #category : 'private - parsing' }
MCPGitRepositoryMetadata >> storeConfigEntryFromLine: aString in: entryDictionary [

	| key separator value |
	separator := aString indexOf: $=.
	separator isZero ifTrue: [ ^ self ].
	key := (aString copyFrom: 1 to: separator - 1) trimBoth.
	key isEmpty ifTrue: [ ^ self ].
	value := separator = aString size
		         ifTrue: [ '' ]
		         ifFalse: [
		         (aString copyFrom: separator + 1 to: aString size) trimBoth ].
	entryDictionary at: key put: (self unquotedConfigValue: value)
]

{ #category : 'private - parsing' }
MCPGitRepositoryMetadata >> unquotedConfigValue: aString [

	(aString size >= 2 and: [
		 aString first = $" and: [ aString last = $" ] ]) ifFalse: [
		^ aString ].
	^ aString copyFrom: 2 to: aString size - 1
]

{ #category : 'accessing' }
MCPGitRepositoryMetadata >> upstreamInfoForBranchNamed: aBranchName [

	| branchEntries branchName remoteName remoteUrl |
	aBranchName isEmpty ifTrue: [ ^ self emptyUpstreamInfo ].
	branchEntries := self configEntries
		                 at: 'branch.' , aBranchName
		                 ifAbsent: [ ^ self emptyUpstreamInfo ].
	remoteName := branchEntries at: 'remote' ifAbsent: [ '' ].
	branchName := self branchNameFromMerge:
		              (branchEntries at: 'merge' ifAbsent: [ '' ]).
	remoteUrl := self remoteUrlNamed: remoteName.
	^ {
		  (#remoteName -> remoteName).
		  (#branchName -> branchName).
		  (#remoteUrl -> remoteUrl) } asDictionary
]
