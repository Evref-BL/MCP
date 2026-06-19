"
Parsed request for repository_load. It resolves one repository source mode: hosted remote coordinates, an explicit Metacello repository URL, a local checkout path, or an existing Iceberg repository reference.
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
		'loadPolicy',
		'hostUrl',
		'repositoryUrl',
		'checkoutPath',
		'repositoryReference'
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

{ #category : 'testing' }
MCPLoadRepositoryRequest >> canResolveRepositoryUrl [

	self isRemoteLoad ifTrue: [
			^ self hasRemoteCoordinates and: [
				  hostUrl notNil and: [ commitish notNil ] ] ].
	self isUrlLoad ifTrue: [ ^ self hasExplicitRepositoryUrl ].
	self isLocalLoad ifTrue: [ ^ self hasCheckoutPath ].
	self isIcebergLoad ifTrue: [ ^ self hasIcebergRepositoryReference ].
	^ false
]

{ #category : 'accessing' }
MCPLoadRepositoryRequest >> checkoutPath [

	^ checkoutPath
]

{ #category : 'accessing' }
MCPLoadRepositoryRequest >> commitish [

	^ commitish
]

{ #category : 'private - mode' }
MCPLoadRepositoryRequest >> ensureSingleRepositorySource [

	self repositorySourceCount <= 1 ifTrue: [ ^ self ].
	MCPCommandError
		signalErrorCode: #AmbiguousLoadRepositorySource
		message:
		'repository_load accepts one source: remote owner/project, repositoryUrl, checkoutPath, or repositoryName/location.'
		details: self requestedContext
]

{ #category : 'private - repository' }
MCPLoadRepositoryRequest >> escapedCommitish [

	^ String streamContents: [ :stream |
			  self commitish do: [ :character |
					  character = $/ ifTrue: [ stream nextPutAll: '\' ].
					  stream nextPut: character ] ]
]

{ #category : 'accessing' }
MCPLoadRepositoryRequest >> groups [

	^ groups ifNil: [ #(  ) ]
]

{ #category : 'private - mode' }
MCPLoadRepositoryRequest >> hasCheckoutPath [

	^ checkoutPath notNil
]

{ #category : 'private - mode' }
MCPLoadRepositoryRequest >> hasExplicitRepositoryUrl [

	^ repositoryUrl notNil
]

{ #category : 'private - mode' }
MCPLoadRepositoryRequest >> hasIcebergRepositoryReference [

	^ repositoryReference isEmpty not
]

{ #category : 'private - mode' }
MCPLoadRepositoryRequest >> hasRemoteCoordinates [

	owner ifNil: [ ^ false ].
	project ifNil: [ ^ false ].
	^ true
]

{ #category : 'private - mode' }
MCPLoadRepositoryRequest >> hasRemoteSourceFields [

	^ hostUrl notNil or: [
		  owner notNil or: [ project notNil or: [ commitish notNil ] ] ]
]

{ #category : 'accessing' }
MCPLoadRepositoryRequest >> hostUrl [

	^ hostUrl
]

{ #category : 'private - repository' }
MCPLoadRepositoryRequest >> icebergCheckoutPath [

	^ self icebergRepository location mcpRepositoryLocationString
]

{ #category : 'private - repository' }
MCPLoadRepositoryRequest >> icebergRepository [

	^ self repositoryReference repository
]

{ #category : 'private - mode' }
MCPLoadRepositoryRequest >> initializeDefaultsFromTool: aTool [

	self isRemoteLoad ifTrue: [
		^ self initializeRemoteDefaultsFromTool: aTool ].
	self isLocalLoad ifTrue: [
			sourceDirectory ifNil: [
				sourceDirectory := aTool defaultSourceDirectory ] ].
	self isIcebergLoad ifTrue: [ self initializeIcebergDefaults ].
	^ self
]

{ #category : 'initialization' }
MCPLoadRepositoryRequest >> initializeFromRequest: request tool: aTool [

	baseline := request stringArgumentNamed: 'baseline'.
	groups := request
		          uniqueStringCollectionArgumentNamed: 'groups'
		          default: #(  ).
	loadPolicy := MCPLoadPolicySpec fromRequest: request tool: aTool.
	hostUrl := request stringArgumentNamed: 'hostUrl'.
	owner := request stringArgumentNamed: 'owner'.
	project := request stringArgumentNamed: 'project'.
	commitish := request stringArgumentNamed: 'commitish'.
	sourceDirectory := request stringArgumentNamed: 'sourceDirectory'.
	repositoryUrl := request stringArgumentNamed: 'repositoryUrl'.
	checkoutPath := request stringArgumentNamed: 'checkoutPath'.
	repositoryReference := MCPRepositoryReferenceSpec fromRequest:
		                       request.
	self ensureSingleRepositorySource.
	mode := self requestedMode.
	self initializeDefaultsFromTool: aTool.
	^ self
]

{ #category : 'private - mode' }
MCPLoadRepositoryRequest >> initializeIcebergDefaults [

	sourceDirectory ifNil: [
			sourceDirectory := self sourceDirectoryFromRepository:
				                   self icebergRepository ].
	^ self
]

{ #category : 'private - mode' }
MCPLoadRepositoryRequest >> initializeRemoteDefaultsFromTool: aTool [

	self hasRemoteCoordinates ifFalse: [
			MCPCommandError
				signalErrorCode: #MissingLoadRepositoryRemoteCoordinates
				message: 'owner and project are required for repository loads.'
				details: self requestedContext ].
	hostUrl ifNil: [ hostUrl := aTool defaultHostUrl ].
	commitish ifNil: [ commitish := aTool defaultCommitish ].
	sourceDirectory ifNil: [
		sourceDirectory := aTool defaultSourceDirectory ]
]

{ #category : 'private - mode' }
MCPLoadRepositoryRequest >> isIcebergLoad [

	^ self mode = 'iceberg'
]

{ #category : 'private - mode' }
MCPLoadRepositoryRequest >> isLocalLoad [

	^ self mode = 'local'
]

{ #category : 'private - mode' }
MCPLoadRepositoryRequest >> isRemoteLoad [

	^ self mode = 'remote'
]

{ #category : 'private - mode' }
MCPLoadRepositoryRequest >> isUrlLoad [

	^ self mode = 'url'
]

{ #category : 'accessing' }
MCPLoadRepositoryRequest >> loadPolicy [

	^ loadPolicy
]

{ #category : 'accessing' }
MCPLoadRepositoryRequest >> location [

	^ self repositoryReference location
]

{ #category : 'accessing' }
MCPLoadRepositoryRequest >> mode [

	^ mode
]

{ #category : 'private - repository' }
MCPLoadRepositoryRequest >> normalizedCheckoutPath: aCheckoutPath [

	| path |
	path := aCheckoutPath trimBoth.
	[ path size > 1 and: [ path last = $/ ] ] whileTrue: [
		path := path allButLast ].
	^ path
]

{ #category : 'accessing' }
MCPLoadRepositoryRequest >> onConflict [

	^ self loadPolicy onConflict
]

{ #category : 'accessing' }
MCPLoadRepositoryRequest >> onWarning [

	^ self loadPolicy onWarning
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
MCPLoadRepositoryRequest >> remoteRepositoryUrl [

	| hostQualifier path scheme |
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
				  nextPutAll: self escapedCommitish.
			  path isEmpty ifFalse: [
					  stream
						  nextPut: $/;
						  nextPutAll: path ] ]
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

{ #category : 'accessing' }
MCPLoadRepositoryRequest >> repositoryName [

	^ self repositoryReference name
]

{ #category : 'accessing' }
MCPLoadRepositoryRequest >> repositoryReference [

	^ repositoryReference
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

{ #category : 'private - mode' }
MCPLoadRepositoryRequest >> repositorySourceCount [

	| count |
	count := 0.
	self hasRemoteSourceFields ifTrue: [ count := count + 1 ].
	self hasExplicitRepositoryUrl ifTrue: [ count := count + 1 ].
	self hasCheckoutPath ifTrue: [ count := count + 1 ].
	self hasIcebergRepositoryReference ifTrue: [ count := count + 1 ].
	^ count
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

	self isUrlLoad ifTrue: [ ^ repositoryUrl ].
	self isLocalLoad ifTrue: [
		^ self tonelRepositoryUrlFromCheckoutPath: self checkoutPath ].
	self isIcebergLoad ifTrue: [
		^ self tonelRepositoryUrlFromCheckoutPath: self icebergCheckoutPath ].
	^ self remoteRepositoryUrl
]

{ #category : 'converting' }
MCPLoadRepositoryRequest >> requestedContext [

	| context policy |
	context := {
		           (#mode -> self mode).
		           (#baseline -> self baseline) } asDictionary.
	self groups ifNotEmpty: [ :loadGroups |
		context at: #groups put: loadGroups ].
	policy := self loadPolicy asDictionary.
	policy ifNotEmpty: [ context at: #policy put: policy ].
	hostUrl ifNotNil: [ context at: #hostUrl put: self hostUrl ].
	owner ifNotNil: [ context at: #owner put: self owner ].
	project ifNotNil: [ context at: #project put: self project ].
	commitish ifNotNil: [ context at: #commitish put: self commitish ].
	sourceDirectory ifNotNil: [
		context at: #sourceDirectory put: self sourceDirectory ].
	repositoryUrl ifNotNil: [
		context at: #repositoryUrl put: repositoryUrl ].
	checkoutPath ifNotNil: [
		context at: #checkoutPath put: self checkoutPath ].
	self repositoryName ifNotNil: [ :name |
		context at: #repositoryName put: name ].
	self location ifNotNil: [ :repositoryLocation |
		context at: #location put: repositoryLocation ].
	self canResolveRepositoryUrl ifTrue: [
		context at: #resolvedRepositoryUrl put: self repositoryUrl ].
	^ context
]

{ #category : 'private - mode' }
MCPLoadRepositoryRequest >> requestedMode [

	self hasExplicitRepositoryUrl ifTrue: [ ^ 'url' ].
	self hasCheckoutPath ifTrue: [ ^ 'local' ].
	self hasIcebergRepositoryReference ifTrue: [ ^ 'iceberg' ].
	^ 'remote'
]

{ #category : 'accessing' }
MCPLoadRepositoryRequest >> sourceDirectory [

	^ sourceDirectory
]

{ #category : 'private - repository' }
MCPLoadRepositoryRequest >> sourceDirectoryFromRepository: aRepository [

	| subdirectory |
	subdirectory := aRepository subdirectory.
	subdirectory ifNil: [ ^ '.' ].
	subdirectory asString isEmpty ifTrue: [ ^ '.' ].
	^ subdirectory asString
]

{ #category : 'private - repository' }
MCPLoadRepositoryRequest >> sourcePathFromCheckoutPath: aCheckoutPath [

	| path segment |
	path := self normalizedCheckoutPath: aCheckoutPath.
	segment := self repositorySourceDirectorySegment.
	segment isEmpty ifTrue: [ ^ path ].
	^ path , '/' , segment
]

{ #category : 'private - repository' }
MCPLoadRepositoryRequest >> tonelRepositoryUrlFromCheckoutPath: aCheckoutPath [

	^ 'tonel://' , (self sourcePathFromCheckoutPath: aCheckoutPath)
]
