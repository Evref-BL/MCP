"
Tests for the read-only find-repositories tool.
"
Class {
	#name : 'MCPToolFindRepositoriesTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolFindRepositoriesTest >> entryNamed: aRepositoryName in: repositoryEntries [

	^ repositoryEntries
		  detect: [ :each | (each at: #name) = aRepositoryName ]
		  ifNone: [
		  self fail: 'Missing repository entry ' , aRepositoryName ]
]

{ #category : 'private' }
MCPToolFindRepositoriesTest >> newRepositoryNamed: aRepositoryName location: aFileReference packageNames: somePackageNames [

	| repository |
	repository := IceLibgitRepository new.
	repository name: aRepositoryName.
	repository location: aFileReference.
	somePackageNames do: [ :each |
		repository workingCopy addPackageNamed: each ].
	^ repository
]

{ #category : 'tests' }
MCPToolFindRepositoriesTest >> testCanFilterByMissingStateAndDirectory [

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
					          (#directoryPaths -> { missingLocation pathString }).
					          (#isMissing -> true) } asDictionary.
			data := self dataFrom: result.
			repositoryNames := (data at: #repositories) collect: [ :each |
				                   each at: #name ].
			self deny: (result at: #isError ifAbsent: [ false ]).
			self assert: (data at: #totalCount) equals: 1.
			self assert: repositoryNames equals: #( 'MCP Missing Repository' ) ]
]

{ #category : 'tests' }
MCPToolFindRepositoriesTest >> testCanFilterByPackageNameAndModifiedState [

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
					          (#packageNames -> #( 'MCP' )).
					          (#isModified -> true) } asDictionary.
			data := self dataFrom: result.
			repositoryNames := (data at: #repositories) collect: [ :each |
				                   each at: #name ].
			self deny: (result at: #isError ifAbsent: [ false ]).
			self assert: (data at: #totalCount) equals: 1.
			self assert: repositoryNames equals: #( 'MCP Alpha Repository' ) ]
]

{ #category : 'tests' }
MCPToolFindRepositoriesTest >> testListsRegisteredRepositoriesWithStructuredData [

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
			self assert: (data at: #totalCount) equals: 2.
			entry := self
				         entryNamed: 'MCP Alpha Repository'
				         in: (data at: #repositories).
			self assert: (entry at: #className) equals: 'IceLibgitRepository'.
			self
				assert: (entry at: #location)
				equals: FileLocator imageDirectory pathString.
			self assert: (entry at: #isMissing) equals: false.
			self assert: (entry at: #isModified) equals: true.
			self
				assert: (entry at: #packageNames)
				equals: #( 'MCP' 'MCP-Tests' ).
			self assert: (entry includesKey: #modifiedPackageNames).
			self assert: (entry includesKey: #remoteNames) ]
]

{ #category : 'private - calling' }
MCPToolFindRepositoriesTest >> toolName [

	^ 'find-repositories'
]

{ #category : 'private' }
MCPToolFindRepositoriesTest >> withRepositories: repositories do: aBlock [

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
