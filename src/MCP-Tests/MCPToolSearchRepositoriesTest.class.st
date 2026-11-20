"
Tests for the read-only repository_search tool.
"
Class {
	#name : 'MCPToolSearchRepositoriesTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPToolSearchRepositoriesTest >> entryNamed: aRepositoryName in: repositoryEntries [

	^ repositoryEntries
		  detect: [ :each | (each at: #name) = aRepositoryName ]
		  ifNone: [ self fail: 'Missing repository entry ' , aRepositoryName ]
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
						          (#class -> self class name asString) } asDictionary.
				data := self dataFrom: result.
				repositoryNames := (data at: #repositories) collect: [ :each | each at: #name ].
				self deny: (result at: #isError ifAbsent: [ false ]).
				self assert: (data at: #repositories) size equals: 1.
				self assert: repositoryNames equals: #( 'MCP Alpha Repository' ) ]
]

{ #category : 'tests' }
MCPToolSearchRepositoriesTest >> testCanFilterByLocation [

	| data missingLocation result |
	missingLocation := FileLocator imageDirectory / 'MCPDefinitelyMissingRepositoryLocation'.
	self
		withRepositories: {
				(self newRepositoryNamed: 'MCP Missing Repository' location: missingLocation packageNames: #(  )).
				(self newRepositoryNamed: 'MCP Present Repository' location: FileLocator imageDirectory packageNames: #(  )) }
		do: [
				result := self callToolWith: { (#location -> missingLocation pathString) } asDictionary.
				data := self dataFrom: result.
				self deny: (result at: #isError ifAbsent: [ false ]).
				self assert: ((data at: #repositories) collect: [ :each | each at: #name ]) equals: #( 'MCP Missing Repository' ) ]
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
						          (#package -> 'MCP').
						          (#isModified -> true) } asDictionary.
				data := self dataFrom: result.
				repositoryNames := (data at: #repositories) collect: [ :each | each at: #name ].
				self deny: (result at: #isError ifAbsent: [ false ]).
				self assert: (data at: #repositories) size equals: 1.
				self assert: repositoryNames equals: #( 'MCP Alpha Repository' ) ]
]

{ #category : 'tests' }
MCPToolSearchRepositoriesTest >> testKeepsAStateOnlyWhenTheCallerNamesIt [
	"isModified false keeps the repositories the image holds no changes for, and a state left out keeps every repository, whichever way it is."

	| namesFor |
	namesFor := [ :arguments |
		            | result |
		            result := self callToolWith: arguments.
		            self deny: (result at: #isError ifAbsent: [ false ]).
		            ((self dataFrom: result) at: #repositories) collect: [ :each | each at: #name ] ].
	self
		withRepositories: {
				(self newRepositoryNamed: 'MCP Present Repository' location: FileLocator imageDirectory packageNames: #( 'MCP' )).
				(self
					 newRepositoryNamed: 'MCP Missing Repository'
					 location: FileLocator imageDirectory / 'MCPDefinitelyMissingRepositoryLocation'
					 packageNames: #(  )).
				(self
					 newRepositoryNamed: 'Other Repository'
					 location: FileLocator imageDirectory / 'MCPDefinitelyMissingRepositoryLocation'
					 packageNames: #(  )) }
		do: [
				self
					assert: (namesFor value: {
								 (#isModified -> false).
								 (#query -> 'MCP') } asDictionary)
					equals: #( 'MCP Missing Repository' ).
				self
					assert: (namesFor value: { (#query -> 'MCP') } asDictionary)
					equals: #( 'MCP Missing Repository' 'MCP Present Repository' ) ]
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
				self assert: (entry at: #packageCount) equals: 2.
				self assert: (entry at: #modifiedPackages) equals: #( 'MCP' 'MCP-Tests' ) ]
]

{ #category : 'tests' }
MCPToolSearchRepositoriesTest >> testListsRepositoryPackageMetadata [

	MCPTestGitRepositoryFixture withConfig: MCPTestGitRepositoryFixture richConfig do: [ :repositoryDirectory |
			| entry repository result |
			repository := MCPTestIceRepository named: 'MCP Rich Repository' location: repositoryDirectory.
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
					self assert: entry keys asSet equals: #( name location isModified isMissing packageCount ) asSet.
					self assert: (entry at: #location) equals: repositoryDirectory pathString.
					self assert: (entry at: #packageCount) equals: 1 ] ]
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
				self deny: (entry includesKey: #branch) ]
]

{ #category : 'tests' }
MCPToolSearchRepositoriesTest >> testPageStopsAtTheToolsOwnSize [
	"A search wider than one page starts at the first repository and says where the next page starts, without being told a size or an offset."

	| data limit names repositories result |
	limit := MCPToolSearchRepositories new defaultPageLimit.
	repositories := (1 to: limit + 1) collect: [ :index |
			                self
				                newRepositoryNamed: 'MCP Paged Repository ' , (index printPaddedWith: $0 to: 2)
				                location: FileLocator imageDirectory
				                packageNames: #(  ) ].
	self withRepositories: repositories do: [
			result := self callToolWith: Dictionary new.
			data := self dataFrom: result.
			names := (data at: #repositories) collect: [ :each | each at: #name ].
			self deny: (result at: #isError ifAbsent: [ false ]).
			self assert: names equals: ((repositories first: limit) collect: [ :each | each name ] as: Array).
			self assert: (data at: #nextOffset) equals: limit.
			self assert: ((data at: #pagination) at: #truncated) ]
]

{ #category : 'tests' }
MCPToolSearchRepositoriesTest >> testRowsLeadWithTheRepositoryName [

	| lines located unlocated |
	unlocated := IceLibgitRepository new
		             name: 'MCP Unlocated Repository';
		             yourself.
	located := self newRepositoryNamed: 'MCP Located Repository' location: FileLocator imageDirectory packageNames: #(  ).
	self
		withRepositories: {
				unlocated.
				located }
		do: [
				lines := (((self callToolWith: Dictionary new) at: #content) first at: #text) lines.
				self assert: (lines anySatisfy: [ :each | each beginsWith: '  MCP Unlocated Repository isMissing=true' ]).
				self assert: (lines anySatisfy: [ :each | each beginsWith: '  MCP Located Repository isMissing=false' ]).
				self deny: (lines anySatisfy: [ :each | each includesSubstring: 'name=' ]).
				self deny:
					(lines anySatisfy: [ :each | (each beginsWith: '  MCP Unlocated Repository') and: [ each includesSubstring: 'location=' ] ]) ]
]

{ #category : 'tests' }
MCPToolSearchRepositoriesTest >> testSearchOmitsAnEmptyLocation [
	"A repository registered with no location has no location to name, and an empty one would read as a field with no value."

	| data entry located unlocated |
	unlocated := IceLibgitRepository new
		             name: 'MCP Unlocated Repository';
		             yourself.
	located := self newRepositoryNamed: 'MCP Located Repository' location: FileLocator imageDirectory packageNames: #(  ).
	self
		withRepositories: {
				unlocated.
				located }
		do: [
				data := self dataFrom: (self callToolWith: Dictionary new).
				entry := self entryNamed: 'MCP Unlocated Repository' in: (data at: #repositories).
				self deny: (entry includesKey: #location).
				entry := self entryNamed: 'MCP Located Repository' in: (data at: #repositories).
				self assert: (entry at: #location) equals: FileLocator imageDirectory pathString ]
]

{ #category : 'tests' }
MCPToolSearchRepositoriesTest >> testSearchRepositoriesHasAccurateNameAndSchema [

	| propertyNames schema |
	schema := MCPToolSearchRepositories new inputSchema.
	propertyNames := schema properties collect: [ :each | each name ].
	self assert: MCPToolSearchRepositories new name equals: 'repository_search'.
	self assert: schema required equals: #(  ).
	self assert: propertyNames asSet equals: #( 'isModified' 'query' 'location' 'subdirectory' 'package' 'class' 'offset' ) asSet
]

{ #category : 'tests' }
MCPToolSearchRepositoriesTest >> testSummaryCountsTheRepositoriesOfTheImage [
	"Repositories are registered with the image, so that is where a search looks; a name, a field or a state it keeps makes the count one that matches."

	| alpha beta |
	alpha := self newRepositoryNamed: 'MCP Alpha Repository' location: FileLocator imageDirectory packageNames: #( 'MCP' ).
	beta := self newRepositoryNamed: 'MCP Beta Repository' location: FileLocator imageDirectory packageNames: #( 'Other-Package' ).
	self
		withRepositories: {
				alpha.
				beta }
		do: [
				self assert: (self summaryFrom: (self callToolWith: Dictionary new)) equals: '2 repositories in the image.'.
				self
					assert: (self summaryFrom: (self callToolWith: { (#query -> 'Alpha') } asDictionary))
					equals: '1 repository matches in the image.'.
				self
					assert: (self summaryFrom: (self callToolWith: { (#isModified -> false) } asDictionary))
					equals: 'No repositories match in the image.' ]
]

{ #category : 'private - calling' }
MCPToolSearchRepositoriesTest >> toolName [

	^ 'repository_search'
]
