"
Parsed update-repository request derived from one MCPToolRequest.

It identifies a registered repository and describes package membership or subdirectory changes without exposing raw argument dictionaries to commands.
"
Class {
	#name : 'MCPRepositoryUpdateRequest',
	#superclass : 'MCPRepositoryRequest',
	#instVars : [
		'subdirectory',
		'packageNames',
		'addPackageNames',
		'removePackageNames',
		'suppliedProperties'
	],
	#category : 'MCP-IDE-Requests',
	#package : 'MCP-IDE',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPRepositoryUpdateRequest class >> fromRequest: request tool: aTool [

	^ self new initializeFromRequest: request
]

{ #category : 'accessing' }
MCPRepositoryUpdateRequest >> addPackageNames [

	^ addPackageNames ifNil: [ #(  ) ]
]

{ #category : 'converting' }
MCPRepositoryUpdateRequest >> commandForTool: aTool [

	^ MCPUpdateRepositoryCommand tool: aTool request: self
]

{ #category : 'converting' }
MCPRepositoryUpdateRequest >> contextValueForPropertyNamed: propertyName [

	propertyName = 'subdirectory' ifTrue: [ ^ self subdirectory ].
	propertyName = 'packages' ifTrue: [ ^ self packageNames ].
	propertyName = 'addPackages' ifTrue: [ ^ self addPackageNames ].
	propertyName = 'removePackages' ifTrue: [ ^ self removePackageNames ].
	^ nil
]

{ #category : 'testing' }
MCPRepositoryUpdateRequest >> hasSuppliedPropertyNamed: aPropertyName [

	^ self suppliedProperties includes: aPropertyName asString
]

{ #category : 'testing' }
MCPRepositoryUpdateRequest >> hasUpdates [

	^ self suppliedProperties isNotEmpty
]

{ #category : 'initialization' }
MCPRepositoryUpdateRequest >> initializeFromRequest: request [

	super initializeFromRequest: request.
	suppliedProperties := self updatePropertyNames select: [ :each | request hasArgumentNamed: each ].
	subdirectory := request stringArgumentNamed: 'subdirectory'.
	packageNames := request stringCollectionArgumentNamed: 'packages'.
	addPackageNames := request stringCollectionArgumentNamed: 'addPackages'.
	removePackageNames := request stringCollectionArgumentNamed: 'removePackages'
]

{ #category : 'accessing' }
MCPRepositoryUpdateRequest >> operation [

	^ 'update'
]

{ #category : 'accessing' }
MCPRepositoryUpdateRequest >> packageNames [

	^ packageNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryUpdateRequest >> removePackageNames [

	^ removePackageNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryUpdateRequest >> repository [

	^ self repositoryReference repository
]

{ #category : 'converting' }
MCPRepositoryUpdateRequest >> requestedContext [

	| context |
	context := self repositoryReference requestedContext copy.
	self suppliedProperties do: [ :propertyName |
		context at: propertyName asSymbol put: (self contextValueForPropertyNamed: propertyName) ].
	context at: #updateActions put: self requestedRepositoryUpdateActions.
	^ context
]

{ #category : 'accessing' }
MCPRepositoryUpdateRequest >> requestedRepositoryUpdateActions [

	| actions |
	actions := OrderedCollection new.
	(self hasSuppliedPropertyNamed: 'subdirectory') ifTrue: [ actions add: 'setSubdirectory' ].
	(self hasSuppliedPropertyNamed: 'packages') ifTrue: [ actions add: 'replacePackages' ].
	(self hasSuppliedPropertyNamed: 'addPackages') ifTrue: [ actions add: 'addPackages' ].
	(self hasSuppliedPropertyNamed: 'removePackages') ifTrue: [ actions add: 'removePackages' ].
	^ actions asArray
]

{ #category : 'accessing' }
MCPRepositoryUpdateRequest >> subdirectory [

	^ subdirectory
]

{ #category : 'accessing' }
MCPRepositoryUpdateRequest >> suppliedProperties [

	^ suppliedProperties ifNil: [ #(  ) ]
]

{ #category : 'private - request' }
MCPRepositoryUpdateRequest >> updatePropertyNames [

	^ #( 'subdirectory' 'packages' 'addPackages' 'removePackages' )
]
