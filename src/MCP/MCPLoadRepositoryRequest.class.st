"
Parsed request for load-repository. It supports baseline-only loads for baselines already available in the image and remote loads that build a Metacello repository URL.
"
Class {
	#name : 'MCPLoadRepositoryRequest',
	#superclass : 'Object',
	#instVars : [
		'mode',
		'owner',
		'project',
		'commitish',
		'sourceDirectory',
		'baseline',
		'groups',
		'onWarning',
		'onConflict',
		'hostUrl'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPLoadRepositoryRequest class >> fromRequest: request tool: aTool [

	^ self new initializeFromRequest: request tool: aTool
]

{ #category : 'accessing' }
MCPLoadRepositoryRequest >> baseline [

	^ baseline
]

{ #category : 'accessing' }
MCPLoadRepositoryRequest >> baselineRequest [

	^ MCPLoadBaselineRequest fromLoadRepositoryRequest: self
]

{ #category : 'accessing' }
MCPLoadRepositoryRequest >> commitish [

	^ commitish
]

{ #category : 'accessing' }
MCPLoadRepositoryRequest >> groups [

	^ groups ifNil: [ #(  ) ]
]

{ #category : 'private - mode' }
MCPLoadRepositoryRequest >> hasRemoteArguments [

	^ {
		  self hostUrl.
		  self owner.
		  self project.
		  self commitish.
		  self sourceDirectory } anySatisfy: [ :each | each notNil ]
]

{ #category : 'accessing' }
MCPLoadRepositoryRequest >> hostUrl [

	^ hostUrl
]

{ #category : 'initialization' }
MCPLoadRepositoryRequest >> initializeFromRequest: request tool: aTool [

	baseline := request stringArgumentNamed: 'baseline'.
	groups := request
		          uniqueStringCollectionArgumentNamed: 'groups'
		          default: #(  ).
	onWarning := request
		             stringArgumentNamed: 'onWarning'
		             default: aTool defaultOnWarning.
	onConflict := request
		              stringArgumentNamed: 'onConflict'
		              default: aTool defaultOnConflict.
	hostUrl := request stringArgumentNamed: 'hostUrl'.
	owner := request stringArgumentNamed: 'owner'.
	project := request stringArgumentNamed: 'project'.
	commitish := request stringArgumentNamed: 'commitish'.
	sourceDirectory := request stringArgumentNamed: 'sourceDirectory'.
	mode := self normalizedModeFrom:
		        (request stringArgumentNamed: 'mode').
	mode ifNil: [
		mode := self hasRemoteArguments
			        ifTrue: [ 'remote' ]
			        ifFalse: [ 'baseline' ] ].
	self validateMode.
	self isRemoteLoad
		ifTrue: [ self initializeRemoteDefaultsFromTool: aTool ]
		ifFalse: [ self validateBaselineOnlyArguments ].
	^ self
]

{ #category : 'private - mode' }
MCPLoadRepositoryRequest >> initializeRemoteDefaultsFromTool: aTool [

	(owner isNil or: [ project isNil ]) ifTrue: [
		MCPCommandError
			signalErrorCode: #MissingLoadRepositoryRemoteCoordinates
			message: 'owner and project are required when mode is remote.'
			details: self requestedContext ].
	hostUrl ifNil: [ hostUrl := aTool defaultHostUrl ].
	commitish ifNil: [ commitish := aTool defaultCommitish ].
	sourceDirectory ifNil: [
		sourceDirectory := aTool defaultSourceDirectory ]
]

{ #category : 'private - mode' }
MCPLoadRepositoryRequest >> isRemoteLoad [

	^ self mode = 'remote'
]

{ #category : 'accessing' }
MCPLoadRepositoryRequest >> mode [

	^ mode
]

{ #category : 'private - mode' }
MCPLoadRepositoryRequest >> normalizedModeFrom: rawMode [

	rawMode ifNil: [ ^ nil ].
	rawMode asLowercase = 'remote' ifTrue: [ ^ 'remote' ].
	rawMode asLowercase = 'baseline' ifTrue: [ ^ 'baseline' ].
	^ rawMode asLowercase
]

{ #category : 'accessing' }
MCPLoadRepositoryRequest >> onConflict [

	^ onConflict
]

{ #category : 'accessing' }
MCPLoadRepositoryRequest >> onWarning [

	^ onWarning
]

{ #category : 'accessing' }
MCPLoadRepositoryRequest >> owner [

	^ owner
]

{ #category : 'accessing' }
MCPLoadRepositoryRequest >> project [

	^ project
]

{ #category : 'private - repository' }
MCPLoadRepositoryRequest >> repositoryHostQualifier [

	| lower markerIndex raw remainder |
	raw := self hostUrl ifNil: [ 'github' ].
	markerIndex := raw findString: '://' startingAt: 1.
	markerIndex = 0 ifTrue: [ ^ '' ].
	markerIndex + 3 > raw size ifTrue: [ ^ '' ].
	remainder := raw copyFrom: markerIndex + 3 to: raw size.
	remainder := remainder trimBoth.
	remainder isEmpty ifTrue: [ ^ '' ].
	lower := remainder asLowercase.
	(#( 'github.com' 'gitlab.com' 'bitbucket.org' ) includes: lower)
		ifTrue: [ ^ '' ].
	^ remainder
]

{ #category : 'private - repository' }
MCPLoadRepositoryRequest >> repositoryScheme [

	| markerIndex raw scheme |
	raw := self hostUrl ifNil: [ 'github' ].
	markerIndex := raw findString: '://' startingAt: 1.
	scheme := markerIndex = 0
		          ifTrue: [ raw asLowercase ]
		          ifFalse: [
		          (raw copyFrom: 1 to: markerIndex - 1) asLowercase ].
	scheme = 'github.com' ifTrue: [ ^ 'github' ].
	scheme = 'gitlab.com' ifTrue: [ ^ 'gitlab' ].
	scheme = 'gitlabs' ifTrue: [ ^ 'gitlab' ].
	scheme = 'bitbucket.org' ifTrue: [ ^ 'bitbucket' ].
	(#( 'github' 'gitlab' 'bitbucket' ) includes: scheme) ifFalse: [
		MCPCommandError
			signalErrorCode: #UnsupportedLoadRepositoryHost
			message: 'hostUrl must identify github, gitlab, or bitbucket.'
			details: { (#hostUrl -> self hostUrl) } asDictionary ].
	^ scheme
]

{ #category : 'private - repository' }
MCPLoadRepositoryRequest >> repositorySourceDirectorySegment [

	| path |
	path := self sourceDirectory ifNil: [ '.' ].
	path := path trimBoth.
	(path isEmpty or: [ path = '.' ]) ifTrue: [ ^ '' ].
	[ path notEmpty and: [ path first = $/ ] ] whileTrue: [
		path := path allButFirst ].
	[ path notEmpty and: [ path last = $/ ] ] whileTrue: [
		path := path allButLast ].
	^ path
]

{ #category : 'accessing' }
MCPLoadRepositoryRequest >> repositoryUrl [

	| hostQualifier path scheme |
	self isRemoteLoad ifFalse: [
		MCPCommandError
			signalErrorCode: #LoadRepositoryUrlUnavailable
			message: 'repositoryUrl is only available when mode is remote.'
			details: self requestedContext ].
	scheme := self repositoryScheme.
	hostQualifier := self repositoryHostQualifier.
	path := self repositorySourceDirectorySegment.
	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: scheme;
			  nextPutAll: '://'.
		  hostQualifier isEmpty ifFalse: [
			  stream
				  nextPutAll: hostQualifier;
				  nextPut: $: ].
		  stream
			  nextPutAll: self owner;
			  nextPut: $/;
			  nextPutAll: self project;
			  nextPut: $:;
			  nextPutAll: self commitish.
		  path isEmpty ifFalse: [
			  stream
				  nextPut: $/;
				  nextPutAll: path ] ]
]

{ #category : 'converting' }
MCPLoadRepositoryRequest >> requestedContext [

	| context |
	context := {
		           (#mode -> self mode).
		           (#baseline -> self baseline).
		           (#groups -> self groups).
		           (#onWarning -> self onWarning).
		           (#onConflict -> self onConflict) } asDictionary.
	hostUrl ifNotNil: [ context at: #hostUrl put: self hostUrl ].
	owner ifNotNil: [ context at: #owner put: self owner ].
	project ifNotNil: [ context at: #project put: self project ].
	commitish ifNotNil: [ context at: #commitish put: self commitish ].
	sourceDirectory ifNotNil: [
		context at: #sourceDirectory put: self sourceDirectory ].
	(self isRemoteLoad and: [ owner notNil and: [ project notNil ] ])
		ifTrue: [ context at: #repositoryUrl put: self repositoryUrl ].
	^ context
]

{ #category : 'accessing' }
MCPLoadRepositoryRequest >> sourceDirectory [

	^ sourceDirectory
]

{ #category : 'private - mode' }
MCPLoadRepositoryRequest >> validateBaselineOnlyArguments [

	self hasRemoteArguments ifFalse: [ ^ self ].
	MCPCommandError
		signalErrorCode: #UnexpectedLoadRepositoryRemoteArguments
		message:
		'hostUrl, owner, project, commitish, and sourceDirectory are only valid when mode is remote.'
		details: self requestedContext
]

{ #category : 'private - mode' }
MCPLoadRepositoryRequest >> validateMode [

	(#( 'remote' 'baseline' ) includes: self mode) ifTrue: [ ^ self ].
	MCPCommandError
		signalErrorCode: #UnsupportedLoadRepositoryMode
		message: 'mode must be remote or baseline.'
		details: self requestedContext
]
