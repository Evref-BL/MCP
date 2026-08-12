"
Tests safe file-backed Git repository metadata used by MCP repository DTOs.
"
Class {
	#name : 'MCPGitRepositoryMetadataTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-DTOs',
	#package : 'MCP-Tests',
	#tag : 'DTOs'
}

{ #category : 'tests' }
MCPGitRepositoryMetadataTest >> testDirectoryGitConfigProducesEmptyMetadata [

	self withTemporaryRepositoryDo: [ :repositoryDirectory |
			| configPath gitDirectory metadata upstreamInfo |
			gitDirectory := repositoryDirectory / '.git'.
			gitDirectory ensureCreateDirectory.
			configPath := gitDirectory / 'config'.
			configPath ensureCreateDirectory.
			metadata := MCPGitRepositoryMetadata fromLocationString: repositoryDirectory pathString.
			self assert: metadata remoteDictionaries equals: #(  ).
			self assert: (metadata remoteUrlNamed: 'origin') equals: ''.
			upstreamInfo := metadata upstreamInfoForBranchNamed: 'main'.
			self assert: (upstreamInfo at: #remoteName) equals: ''.
			self assert: (upstreamInfo at: #branchName) equals: ''.
			self assert: (upstreamInfo at: #remoteUrl) equals: '' ]
]

{ #category : 'tests' }
MCPGitRepositoryMetadataTest >> testMissingGitConfigProducesEmptyMetadata [

	self withTemporaryRepositoryDo: [ :repositoryDirectory |
			| metadata upstreamInfo |
			metadata := MCPGitRepositoryMetadata fromLocationString: repositoryDirectory pathString.
			self assert: metadata remoteDictionaries equals: #(  ).
			self assert: (metadata remoteUrlNamed: 'origin') equals: ''.
			upstreamInfo := metadata upstreamInfoForBranchNamed: 'main'.
			self assert: (upstreamInfo at: #remoteName) equals: ''.
			self assert: (upstreamInfo at: #branchName) equals: ''.
			self assert: (upstreamInfo at: #remoteUrl) equals: '' ]
]

{ #category : 'tests' }
MCPGitRepositoryMetadataTest >> testReadsRemoteAndUpstreamMetadataFromGitConfig [

	self withTemporaryRepositoryDo: [ :repositoryDirectory |
			| metadata remotes upstreamInfo |
			self writeStandardConfigIn: repositoryDirectory.
			metadata := MCPGitRepositoryMetadata fromLocationString: repositoryDirectory pathString.
			remotes := metadata remoteDictionaries.
			self assert: remotes size equals: 2.
			self assert: (remotes first at: #name) equals: 'backup'.
			self assert: (remotes first at: #url) equals: 'ssh://example.com/backup.git'.
			self assert: (remotes second at: #name) equals: 'origin'.
			self assert: (remotes second at: #url) equals: 'https://example.com/project.git'.
			upstreamInfo := metadata upstreamInfoForBranchNamed: 'main'.
			self assert: (upstreamInfo at: #remoteName) equals: 'origin'.
			self assert: (upstreamInfo at: #branchName) equals: 'main'.
			self assert: (upstreamInfo at: #remoteUrl) equals: 'https://example.com/project.git' ]
]

{ #category : 'tests' }
MCPGitRepositoryMetadataTest >> testReadsWorktreeMetadataFromCommonGitDirectory [

	self withTemporaryRepositoryDo: [ :repositoryDirectory |
			| commonGitDirectory metadata upstreamInfo |
			commonGitDirectory := self writeWorktreeConfigIn: repositoryDirectory.
			metadata := MCPGitRepositoryMetadata fromLocationString: repositoryDirectory pathString.
			self assert: metadata gitDirectory pathString equals: commonGitDirectory pathString.
			self assert: (metadata remoteUrlNamed: 'origin') equals: 'https://example.com/worktree.git'.
			upstreamInfo := metadata upstreamInfoForBranchNamed: 'feature'.
			self assert: (upstreamInfo at: #remoteName) equals: 'origin'.
			self assert: (upstreamInfo at: #branchName) equals: 'feature'.
			self assert: (upstreamInfo at: #remoteUrl) equals: 'https://example.com/worktree.git' ]
]

{ #category : 'tests' }
MCPGitRepositoryMetadataTest >> testRepositoryWithNilLocationProducesEmptyMetadata [

	| metadata repository upstreamInfo |
	repository := MCPTestIceRepository named: 'MCP Repository Without Location' location: nil.
	metadata := MCPGitRepositoryMetadata forRepository: repository.
	self assert: metadata remoteDictionaries equals: #(  ).
	self assert: (metadata remoteUrlNamed: 'origin') equals: ''.
	upstreamInfo := metadata upstreamInfoForBranchNamed: 'main'.
	self assert: (upstreamInfo at: #remoteName) equals: ''.
	self assert: (upstreamInfo at: #branchName) equals: ''.
	self assert: (upstreamInfo at: #remoteUrl) equals: ''
]

{ #category : 'private' }
MCPGitRepositoryMetadataTest >> withTemporaryRepositoryDo: aBlock [

	| repositoryDirectory |
	repositoryDirectory := FileLocator temp asFileReference / ('mcp-git-metadata-' , UUID new asString).
	[
		repositoryDirectory ensureCreateDirectory.
		aBlock value: repositoryDirectory ] ensure: [ repositoryDirectory exists ifTrue: [ repositoryDirectory deleteAll ] ]
]

{ #category : 'private' }
MCPGitRepositoryMetadataTest >> writeStandardConfigIn: repositoryDirectory [

	| gitDirectory |
	gitDirectory := repositoryDirectory / '.git'.
	gitDirectory ensureCreateDirectory.
	gitDirectory / 'config' writeStreamDo: [ :stream |
			stream
				nextPutAll: '[remote "backup"]';
				lf;
				nextPutAll: String tab , 'url = ssh://example.com/backup.git';
				lf;
				nextPutAll: '[remote "origin"]';
				lf;
				nextPutAll: String tab , 'url = https://example.com/project.git';
				lf;
				nextPutAll: '[branch "main"]';
				lf;
				nextPutAll: String tab , 'remote = origin';
				lf;
				nextPutAll: String tab , 'merge = refs/heads/main';
				lf ].
	^ gitDirectory
]

{ #category : 'private' }
MCPGitRepositoryMetadataTest >> writeWorktreeConfigIn: repositoryDirectory [

	| commonGitDirectory worktreeGitDirectory |
	commonGitDirectory := repositoryDirectory / 'common.git'.
	worktreeGitDirectory := commonGitDirectory / 'worktrees' / 'example'.
	commonGitDirectory ensureCreateDirectory.
	worktreeGitDirectory ensureCreateDirectory.
	repositoryDirectory / '.git' writeStreamDo: [ :stream |
			stream
				nextPutAll: 'gitdir: common.git/worktrees/example';
				lf ].
	worktreeGitDirectory / 'commondir' writeStreamDo: [ :stream |
			stream
				nextPutAll: '../..';
				lf ].
	commonGitDirectory / 'config' writeStreamDo: [ :stream |
			stream
				nextPutAll: '[remote "origin"]';
				lf;
				nextPutAll: String tab , 'url = https://example.com/worktree.git';
				lf;
				nextPutAll: '[branch "feature"]';
				lf;
				nextPutAll: String tab , 'remote = origin';
				lf;
				nextPutAll: String tab , 'merge = refs/heads/feature';
				lf ].
	^ commonGitDirectory
]
