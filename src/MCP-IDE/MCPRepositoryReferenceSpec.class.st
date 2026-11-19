"
Repository reference read by the repository tools.

A repository is identified by its name, and narrowed by its location when several registrations share that name. The repository tools use this spec to resolve a registered Iceberg repository before reading or changing it.
"
Class {
	#name : 'MCPRepositoryReferenceSpec',
	#superclass : 'Object',
	#instVars : [
		'name',
		'location'
	],
	#category : 'MCP-IDE-Specs',
	#package : 'MCP-IDE',
	#tag : 'Specs'
}

{ #category : 'instance creation' }
MCPRepositoryReferenceSpec class >> fromRequest: request [

	^ self name: (request stringArgumentNamed: 'repository') location: (request stringArgumentNamed: 'location')
]

{ #category : 'instance creation' }
MCPRepositoryReferenceSpec class >> name: aName location: aLocation [

	^ self new
		  initializeName: aName location: aLocation;
		  yourself
]

{ #category : 'testing' }
MCPRepositoryReferenceSpec >> hasLocation [

	^ self location isNotNil
]

{ #category : 'testing' }
MCPRepositoryReferenceSpec >> hasName [

	^ self name isNotNil
]

{ #category : 'initialization' }
MCPRepositoryReferenceSpec >> initializeName: aName location: aLocation [

	name := aName.
	location := aLocation
]

{ #category : 'testing' }
MCPRepositoryReferenceSpec >> isEmpty [

	^ self hasName not and: [ self hasLocation not ]
]

{ #category : 'accessing' }
MCPRepositoryReferenceSpec >> location [

	^ location
]

{ #category : 'private - resolving' }
MCPRepositoryReferenceSpec >> matchesRepository: aRepository [

	self hasName ifTrue: [ (self nameOf: aRepository) = self name ifFalse: [ ^ false ] ].
	self hasLocation ifTrue: [ aRepository mcpLocationString = self location ifFalse: [ ^ false ] ].
	^ true
]

{ #category : 'accessing' }
MCPRepositoryReferenceSpec >> name [

	^ name
]

{ #category : 'private - resolving' }
MCPRepositoryReferenceSpec >> nameOf: aRepository [

	^ (aRepository name ifNil: [ '' ]) asString
]

{ #category : 'private - resolving' }
MCPRepositoryReferenceSpec >> notFoundTextAmong: registeredRepositories [
	"What a call that named no registered repository is told: what it named, then the repositories of that name elsewhere, the registered ones when they are few, or the names closest to the one it gave."

	| names sameName |
	names := (registeredRepositories collect: [ :each | self nameOf: each ] as: Array) sort.
	sameName := self hasName
		            ifTrue: [ registeredRepositories select: [ :each | (self nameOf: each) = self name ] ]
		            ifFalse: [ #(  ) ].
	^ String streamContents: [ :stream |
			  stream << 'No repository '.
			  self hasName ifTrue: [ stream << 'named ' << self name << ' ' ].
			  stream << 'is registered'.
			  self hasLocation ifTrue: [ stream << ' at ' << self location ].
			  stream << '.'.
			  sameName
				  ifNotEmpty: [
						  stream << ' ' << self name << ' is registered at '.
						  sameName do: [ :each | stream << each mcpLocationString ] separatedBy: [ stream << ', ' ].
						  stream << '.' ]
				  ifEmpty: [ self printRegisteredNames: names on: stream ] ]
]

{ #category : 'private - resolving' }
MCPRepositoryReferenceSpec >> printRegisteredNames: names on: aStream [
	"The registered repositories when they are few, the names closest to the one asked for when they are many, or that the image has none."

	| suggestions |
	names ifEmpty: [ ^ aStream << ' The image has none: repository_attach registers an existing checkout.' ].
	names size <= MCPScopeNameSuggester defaultLimit ifTrue: [ ^ aStream << ' Registered: ' << (', ' join: names) << '.' ].
	suggestions := self hasName
		               ifTrue: [
				               MCPScopeNameSuggester
					               suggestionsFor: self name
					               candidates: (names collect: [ :each |
								                {
									                (#name -> each).
									                (#bucket -> each) } asDictionary ])
					               max: MCPScopeNameSuggester defaultLimit ]
		               ifFalse: [ #(  ) ].
	suggestions ifNotEmpty: [ ^ aStream << ' Did you mean: ' << (', ' join: suggestions) << '?' ].
	aStream << ' ' << names size printString << ' repositories are registered: repository_search lists them.'
]

{ #category : 'resolving' }
MCPRepositoryReferenceSpec >> repository [

	| matches |
	self isEmpty ifTrue: [ self signalMissingRepositoryReference ].
	matches := IceRepository repositories select: [ :each | self matchesRepository: each ].
	matches isEmpty ifTrue: [ self signalRepositoryNotFound ].
	matches size > 1 ifTrue: [ self signalAmbiguousRepository: matches ].
	^ matches anyOne
]

{ #category : 'converting' }
MCPRepositoryReferenceSpec >> requestedContext [
	"The reference as the call wrote it, under the names of its arguments."

	^ {
		  (#repository -> self name).
		  (#location -> self location) } asDictionary
]

{ #category : 'private - signaling' }
MCPRepositoryReferenceSpec >> signalAmbiguousRepository: repositories [
	"Several registered repositories match: each is named with its location, which tells them apart."

	| details matchingRepositoryNames |
	details := self requestedContext copy.
	matchingRepositoryNames := (repositories collect: [ :each | each name asString ] as: Array) sort.
	details at: #matchingRepositories put: matchingRepositoryNames.
	MCPCommandError
		signalErrorCode: #RepositoryReferenceAmbiguous
		message: (String streamContents: [ :stream |
					 stream << 'More than one registered repository matches: '.
					 (repositories asArray sort: [ :a :b | a mcpLocationString <= b mcpLocationString ])
						 do: [ :each | stream << (self nameOf: each) << ' at ' << each mcpLocationString ]
						 separatedBy: [ stream << ', ' ].
					 stream << '. Pass location to choose one.' ])
		details: details
]

{ #category : 'private - signaling' }
MCPRepositoryReferenceSpec >> signalMissingRepositoryReference [

	MCPCommandError
		signalErrorCode: #RepositoryReferenceRequired
		message: 'Repository tools require repository.'
		details: self requestedContext
]

{ #category : 'private - signaling' }
MCPRepositoryReferenceSpec >> signalRepositoryNotFound [
	"No registered repository matches: the answer says what the call named and what the image holds."

	| details registered |
	registered := IceRepository repositories asArray.
	details := self requestedContext copy.
	details at: #registeredRepositories put: (registered collect: [ :each | self nameOf: each ] as: Array) sort.
	MCPCommandError signalErrorCode: #RepositoryNotFound message: (self notFoundTextAmong: registered) details: details
]
