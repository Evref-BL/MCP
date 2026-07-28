"
Test fixture helper for creating temporary file-backed Git repository metadata without invoking Git or Iceberg libgit calls.
"
Class {
	#name : 'MCPTestGitRepositoryFixture',
	#superclass : 'Object',
	#category : 'MCP-Tests-Resources-Support',
	#package : 'MCP-Tests-Resources',
	#tag : 'Support'
}

{ #category : 'fixtures' }
MCPTestGitRepositoryFixture class >> backupConfig [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: '[remote "backup"]';
				  lf;
				  nextPutAll: String tab , 'url = memory://backup';
				  lf;
				  nextPutAll: '[branch "main"]';
				  lf;
				  nextPutAll: String tab , 'remote = backup';
				  lf;
				  nextPutAll: String tab , 'merge = refs/heads/main';
				  lf ]
]

{ #category : 'fixtures' }
MCPTestGitRepositoryFixture class >> richConfig [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: '[remote "backup"]';
				  lf;
				  nextPutAll: String tab , 'url = memory://backup';
				  lf;
				  nextPutAll: '[remote "origin"]';
				  lf;
				  nextPutAll: String tab , 'url = memory://origin';
				  lf;
				  nextPutAll: '[branch "main"]';
				  lf;
				  nextPutAll: String tab , 'remote = origin';
				  lf;
				  nextPutAll: String tab , 'merge = refs/heads/main';
				  lf ]
]

{ #category : 'fixtures' }
MCPTestGitRepositoryFixture class >> standardConfig [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: '[remote "origin"]';
				  lf;
				  nextPutAll: String tab , 'url = memory://origin';
				  lf;
				  nextPutAll: '[branch "main"]';
				  lf;
				  nextPutAll: String tab , 'remote = origin';
				  lf;
				  nextPutAll: String tab , 'merge = refs/heads/main';
				  lf ]
]

{ #category : 'fixtures' }
MCPTestGitRepositoryFixture class >> withConfig: configContents do: aBlock [

	| repositoryDirectory |
	repositoryDirectory := FileLocator temp asFileReference
	                       / ('mcp-git-fixture-' , UUID new asString).
	[
		repositoryDirectory ensureCreateDirectory.
		self writeConfig: configContents in: repositoryDirectory.
		aBlock value: repositoryDirectory ] ensure: [
		repositoryDirectory exists ifTrue: [ repositoryDirectory deleteAll ] ]
]

{ #category : 'fixtures' }
MCPTestGitRepositoryFixture class >> writeConfig: configContents in: repositoryDirectory [

	| gitDirectory |
	gitDirectory := repositoryDirectory / '.git'.
	gitDirectory ensureCreateDirectory.
	gitDirectory / 'config' writeStreamDo: [ :stream |
		stream nextPutAll: configContents ]
]
