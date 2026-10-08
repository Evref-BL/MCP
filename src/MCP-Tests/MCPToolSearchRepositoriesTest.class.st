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
		  ifNone: [ self fail: 'Missing repository entry ' , aRepositoryName ]
]

{ #category : 'private' }
MCPToolSearchRepositoriesTest >> newRepositoryNamed: aRepositoryName location: aFileReference packageNames: somePackageNames [

	| repository |
	repository := IceLibgitRepository new.
	repository name: aRepositoryName.
	repository location: aFileReference.
	somePackageNames do: [ :each | repository workingCopy addPackageNamed: each ].
	^ repository
]

{ #category : 'tests' }
MCPToolSearchRepositoriesTest >> testCanFilterByClassName [

	| alpha beta data repositoryNames result |
	alpha := self newRepositoryNamed: 'MCP Alpha Repository' location: FileLocator imageDirectory packageNames: #( 'MCP-Tests' ).
	beta := self newRepositoryNamed: 'MCP Beta Repository' location: FileLocator imageDirectory packageNames: #( 'MCP' ).
	self
		withRepositories: {
				alpha.
				beta }
		do: [
				result := self callToolWith: {
						          (#className -> self class name asString).
						          (#filterMode -> 'exact') } asDictionary.
				data := self dataFrom: result.
				repositoryNames := (data at: #repositories) collect: [ :each | each at: #name ].
				self deny: (result at: #isError ifAbsent: [ false ]).
				self assert: (data at: #repositories) size equals: 1.
				self assert: repositoryNames equals: #( 'MCP Alpha Repository' ) ]
]

{ #category : 'tests' }
MCPToolSearchRepositoriesTest >> testCanFilterByMissingStateAndDirectory [

	| data missing missingLocation present repositoryNames result |
	missingLocation := FileLocator imageDirectory / 'MCPDefinitelyMissingRepositoryLocation'.
	missing := self newRepositoryNamed: 'MCP Missing Repository' location: missingLocation packageNames: #(  ).
	present := self newRepositoryNamed: 'MCP Present Repository' location: FileLocator imageDirectory packageNames: #(  ).
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
				repositoryNames := (data at: #repositories) collect: [ :each | each at: #name ].
				self deny: (result at: #isError ifAbsent: [ false ]).
				self assert: (data at: #repositories) size equals: 1.
				self assert: repositoryNames equals: #( 'MCP Missing Repository' ) ]
]

{ #category : 'tests' }
MCPToolSearchRepositoriesTest >> testCanFilterByPackageNameAndModifiedState [

	| alpha beta data repositoryNames result |
	alpha := self newRepositoryNamed: 'MCP Alpha Repository' location: FileLocator imageDirectory packageNames: #( 'MCP' ).
	beta := self newRepositoryNamed: 'MCP Beta Repository' location: FileLocator imageDirectory packageNames: #( 'Other-Package' ).
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
				repositoryNames := (data at: #repositories) collect: [ :each | each at: #name ].
				self deny: (result at: #isError ifAbsent: [ false ]).
				self assert: (data at: #repositories) size equals: 1.
				self assert: repositoryNames equals: #( 'MCP Alpha Repository' ) ]
]

{ #category : 'tests' }
MCPToolSearchRepositoriesTest >> testListsRegisteredRepositoriesWithStructuredData [

	| alpha beta data entry result |
	alpha := self
		         newRepositoryNamed: 'MCP Alpha Repository'
		         location: FileLocator imageDirectory
		         packageNames: #( 'MCP' 'MCP-Tests' ).
	beta := self newRepositoryNamed: 'MCP Beta Repository' location: FileLocator imageDirectory packageNames: #( 'Other-Package' ).
	self
		withRepositories: {
				alpha.
				beta }
		do: [
				result := self callToolWith: Dictionary new.
				data := self dataFrom: result.
				self deny: (result at: #isError ifAbsent: [ false ]).
				self assert: (data at: #repositories) size equals: 2.
				entry := self entryNamed: 'MCP Alpha Repository' in: (data at: #repositories).
				self assert: (entry at: #location) equals: FileLocator imageDirectory pathString.
				self assert: (entry at: #isModified).
				self deny: (entry at: #isMissing).
				self assert: (entry at: #packageNames) equals: #( 'MCP' 'MCP-Tests' ).
				self assert: (entry at: #modifiedPackageNames) equals: #( 'MCP' 'MCP-Tests' ) ]
]

{ #category : 'tests' }
MCPToolSearchRepositoriesTest >> testListsRepositoryPackageMetadata [

	MCPTestGitRepositoryFixture withConfig: MCPTestGitRepositoryFixture richConfig do: [ :repositoryDirectory |
			| entry repository result |
			repository := MCPTestIceRepository named: 'MCP Rich Repository' location: repositoryDirectory pathString.
			repository workingCopy packageNames: #( 'MCP' ).
			repository headDescription: 'rich head'.
			repository headCommitId: 'abc123'.
			repository isDetachedHead: false.
			self withRepositories: { repository } do: [
					| data |
					result := self callToolWith: Dictionary new.
					data := self dataFrom: result.
					self deny: (result at: #isError ifAbsent: [ false ]).
					entry := self entryNamed: 'MCP Rich Repository' in: (data at: #repositories).
					self assert: entry keys asSet equals: #( name location isModified isMissing packageNames ) asSet.
					self assert: (entry at: #location) equals: repositoryDirectory pathString.
					self assert: (entry at: #packageNames) equals: #( 'MCP' ) ] ]
]

{ #category : 'tests' }
MCPToolSearchRepositoriesTest >> testListsStaleRepositoryAsMissingAndContinues [

	| data entry missingLocation present result stale |
	missingLocation := FileLocator imageDirectory / 'MCPStaleRepositoryLocation'.
	stale := MCPTestStaleRepository named: 'MCP Stale Repository' location: missingLocation.
	present := self newRepositoryNamed: 'MCP Present Repository' location: FileLocator imageDirectory packageNames: #(  ).
	self
		withRepositories: {
				stale.
				present }
		do: [
				result := self callToolWith: Dictionary new.
				data := self dataFrom: result.
				self deny: (result at: #isError ifAbsent: [ false ]).
				self assert: (data at: #repositories) size equals: 2.
				entry := self entryNamed: 'MCP Stale Repository' in: (data at: #repositories).
				self assert: (entry at: #isMissing) equals: true.
				self assert: (entry at: #location) equals: missingLocation pathString.
				self deny: (entry includesKey: #branchName) ]
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
