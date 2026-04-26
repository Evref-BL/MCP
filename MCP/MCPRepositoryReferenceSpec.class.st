"
Parsed repository reference used by repository tools.

A repository can be identified by image name, location path, or both. Commands use this spec to resolve a registered Iceberg repository before applying read or write behavior.
"
Class {
	#name : 'MCPRepositoryReferenceSpec',
	#superclass : 'Object',
	#instVars : [
		'name',
		'location'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPRepositoryReferenceSpec class >> fromRequest: request [

	^ self
		  name: (request stringArgumentNamed: 'repositoryName')
		  location: (request stringArgumentNamed: 'location')
]

{ #category : 'instance creation' }
MCPRepositoryReferenceSpec class >> name: aName location: aLocation [

	^ self new
		  initializeName: aName location: aLocation;
		  yourself
]

{ #category : 'converting' }
MCPRepositoryReferenceSpec >> asDictionary [

	^ {
		  (#repositoryName -> self name).
		  (#location -> self location) } asDictionary
]

{ #category : 'testing' }
MCPRepositoryReferenceSpec >> hasLocation [

	^ self location notNil
]

{ #category : 'testing' }
MCPRepositoryReferenceSpec >> hasName [

	^ self name notNil
]

{ #category : 'initialization' }
MCPRepositoryReferenceSpec >> initializeName: aName location: aLocation [

	name := aName.
	location := aLocation.
	^ self
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

	| repositoryInfo |
	repositoryInfo := MCPRepositoryInfo fromRepository: aRepository.
	self hasName ifTrue: [
		repositoryInfo name = self name ifFalse: [ ^ false ] ].
	self hasLocation ifTrue: [
		repositoryInfo location = self location ifFalse: [ ^ false ] ].
	^ true
]

{ #category : 'accessing' }
MCPRepositoryReferenceSpec >> name [

	^ name
]

{ #category : 'resolving' }
MCPRepositoryReferenceSpec >> repository [

	| matches |
	self isEmpty ifTrue: [ self signalMissingRepositoryReference ].
	matches := IceRepository repositories select: [ :each |
		           self matchesRepository: each ].
	matches isEmpty ifTrue: [ self signalRepositoryNotFound ].
	matches size > 1 ifTrue: [ self signalAmbiguousRepository: matches ].
	^ matches anyOne
]

{ #category : 'converting' }
MCPRepositoryReferenceSpec >> requestedContext [

	^ self asDictionary
]

{ #category : 'private - signaling' }
MCPRepositoryReferenceSpec >> signalAmbiguousRepository: repositories [

	| details |
	details := self requestedContext copy.
	details
		at: #matchingRepositoryNames
		put: (repositories collect: [ :each | each name asString ]) asArray
				asSortedCollection asArray.
	MCPCommandError
		signalErrorCode: #RepositoryReferenceAmbiguous
		message:
		'More than one registered Iceberg repository matches the requested repository reference.'
		details: details
]

{ #category : 'private - signaling' }
MCPRepositoryReferenceSpec >> signalMissingRepositoryReference [

	MCPCommandError
		signalErrorCode: #RepositoryReferenceRequired
		message:
		'Repository tools require repositoryName, location, or both.'
		details: self requestedContext
]

{ #category : 'private - signaling' }
MCPRepositoryReferenceSpec >> signalRepositoryNotFound [

	MCPCommandError
		signalErrorCode: #RepositoryNotFound
		message:
		'No registered Iceberg repository matches the requested repository reference.'
		details: self requestedContext
]
