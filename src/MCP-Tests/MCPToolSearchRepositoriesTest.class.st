"
Tests for the read-only repository_search tool.
"
Class {
	#name : 'MCPToolSearchRepositoriesTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolSearchRepositoriesTest >> entryNamed: aRepositoryName in: repositoryEntries [

	^ repositoryEntries
		  detect: [ :each | (each at: #name) = aRepositoryName ]
		  ifNone: [
		  self fail: 'Missing repository entry ' , aRepositoryName ]
]

{ #category : 'private' }
MCPToolSearchRepositoriesTest >> newRepositoryNamed: aRepositoryName location: aFileReference packageNames: somePackageNames [

	| repository |
	repository := IceLibgitRepository new.
	repository name: aRepositoryName.
	repository location: aFileReference.
	somePackageNames do: [ :each |
		repository workingCopy addPackageNamed: each ].
	^ repository
]

{ #category : 'tests' }
MCPToolSearchRepositoriesTest >> testCanFilterByMissingStateAndDirectory [

	| data missing missingLocation present repositoryNames result |
	missingLocation := FileLocator imageDirectory
	                   / 'MCPDefinitelyMissingRepositoryLocation'.
	missing := self
		           newRepositoryNamed: 'MCP Missing Repository'
		           location: missingLocation
		           packageNames: #(  ).
	present := self
		           newRepositoryNamed: 'MCP Present Repository'
		           location: FileLocator imageDirectory
		           packageNames: #(  ).
	self
		withRepositories: {
				missing.
				present }
		do: [
				result := self callToolWith: {
						          (#location -> missingLocation pathString).
						          (#filterMode -> 'exact').
						          (#isMissing -> true) } asDictionary.
				data := self dataFrom: result.
				repositoryNames := (data at: #repositories) collect: [ :each |
					                   each at: #name ].
				self deny: (result at: #isError ifAbsent: [ false ]).
				self assert: (data at: #repositories) size equals: 1.
				self assert: repositoryNames equals: #( 'MCP Missing Repository' ) ]
]

{ #category : 'tests' }
MCPToolSearchRepositoriesTest >> testCanFilterByPackageNameAndModifiedState [

	| alpha beta data repositoryNames result |
	alpha := self
		         newRepositoryNamed: 'MCP Alpha Repository'
		         location: FileLocator imageDirectory
		         packageNames: #( 'MCP' ).
	beta := self
		        newRepositoryNamed: 'MCP Beta Repository'
		        location: FileLocator imageDirectory
		        packageNames: #( 'Other-Package' ).
	self
		withRepositories: {
				alpha.
				beta }
		do: [
				result := self callToolWith: {
						          (#packageName -> 'MCP').
						          (#filterMode -> 'exact').
						          (#isModified -> true) } asDictionary.
				data := self dataFrom: result.
				repositoryNames := (data at: #repositories) collect: [ :each |
					                   each at: #name ].
				self deny: (result at: #isError ifAbsent: [ false ]).
				self assert: (data at: #repositories) size equals: 1.
				self assert: repositoryNames equals: #( 'MCP Alpha Repository' ) ]
]

{ #category : 'tests' }
MCPToolSearchRepositoriesTest >> testCanFilterByRemoteUrlAndHeadCommit [

	MCPTestGitRepositoryFixture
		withConfig: MCPTestGitRepositoryFixture standardConfig
		do: [ :alphaDirectory |
				MCPTestGitRepositoryFixture
					withConfig: MCPTestGitRepositoryFixture backupConfig
					do: [ :betaDirectory |
							| alpha beta data repositoryNames result |
							alpha := MCPTestIceRepository
								         named: 'MCP Alpha Repository'
								         location: alphaDirectory pathString.
							alpha headCommitId: 'abc123'.
							beta := MCPTestIceRepository
								        named: 'MCP Beta Repository'
								        location: betaDirectory pathString.
							beta headCommitId: 'def456'.
							self
								withRepositories: {
										alpha.
										beta }
								do: [
										result := self callToolWith:
											          { (#headCommitId -> 'abc123') } asDictionary.
										data := self dataFrom: result.
										repositoryNames := (data at: #repositories) collect: [ :each |
											                   each at: #name ].
										self deny: (result at: #isError ifAbsent: [ false ]).
										self
											assert: repositoryNames
											equals: #( 'MCP Alpha Repository' ).
										result := self callToolWith:
											          { (#remoteUrl -> 'memory://backup') }
												          asDictionary.
										data := self dataFrom: result.
										repositoryNames := (data at: #repositories) collect: [ :each |
											                   each at: #name ].
										self deny: (result at: #isError ifAbsent: [ false ]).
										self
											assert: repositoryNames
											equals: #( 'MCP Beta Repository' ) ] ] ]
]

{ #category : 'tests' }
MCPToolSearchRepositoriesTest >> testListsRegisteredRepositoriesWithStructuredData [

	| alpha beta data entry result |
	alpha := self
		         newRepositoryNamed: 'MCP Alpha Repository'
		         location: FileLocator imageDirectory
		         packageNames: #( 'MCP' 'MCP-Tests' ).
	beta := self
		        newRepositoryNamed: 'MCP Beta Repository'
		        location: FileLocator imageDirectory
		        packageNames: #( 'Other-Package' ).
	self
		withRepositories: {
				alpha.
				beta }
		do: [
				result := self callToolWith: Dictionary new.
				data := self dataFrom: result.
				self deny: (result at: #isError ifAbsent: [ false ]).
				self assert: (data at: #repositories) size equals: 2.
				entry := self
					         entryNamed: 'MCP Alpha Repository'
					         in: (data at: #repositories).
				self assert: (entry at: #isModified) equals: true.
				self
					assert: (entry at: #modifiedPackageNames)
					equals: #( 'MCP' 'MCP-Tests' ).
				self deny: (entry includesKey: #location).
				self deny: (entry includesKey: #isMissing).
				self deny: (entry includesKey: #packageNames).
				self deny: (entry includesKey: #className).
				self deny: (entry includesKey: #headClassName).
				self deny: (entry includesKey: #remotes).
				self deny: (entry includesKey: #remoteNames) ]
]

{ #category : 'tests' }
MCPToolSearchRepositoriesTest >> testListsRichRepositoryMetadata [

	MCPTestGitRepositoryFixture
		withConfig: MCPTestGitRepositoryFixture richConfig
		do: [ :repositoryDirectory |
				| entry repository result |
				repository := MCPTestIceRepository
					              named: 'MCP Rich Repository'
					              location: repositoryDirectory pathString.
				repository workingCopy packageNames: #( 'MCP' ).
				repository headDescription: 'rich head'.
				repository headCommitId: 'abc123'.
				repository isDetachedHead: false.
				self withRepositories: { repository } do: [
						| data |
						result := self callToolWith:
							          { (#includeDetails -> true) } asDictionary.
						data := self dataFrom: result.
						self deny: (result at: #isError ifAbsent: [ false ]).
						entry := self
							         entryNamed: 'MCP Rich Repository'
							         in: (data at: #repositories).
						self assert: (entry at: #headDescription) equals: 'rich head'.
						self assert: (entry at: #headCommitId) equals: 'abc123'.
						self assert: (entry at: #upstreamRemoteName) equals: 'origin'.
						self assert: (entry at: #upstreamBranchName) equals: 'main'.
						self
							assert: (entry at: #upstreamRemoteUrl)
							equals: 'memory://origin'.
						self deny: (entry includesKey: #isDetachedHead).
						self deny: (entry includesKey: #headClassName).
						self deny: (entry includesKey: #remotes) ] ]
]

{ #category : 'private - calling' }
MCPToolSearchRepositoriesTest >> toolName [

	^ 'repository_search'
]

{ #category : 'private' }
MCPToolSearchRepositoriesTest >> withRepositories: repositories do: aBlock [

	| previousRepositories registry |
	registry := IceRepository registry.
	previousRepositories := registry copy.
	[
		registry removeAll.
		registry addAll: repositories.
		aBlock value ] ensure: [
			registry removeAll.
			registry addAll: previousRepositories ]
]
