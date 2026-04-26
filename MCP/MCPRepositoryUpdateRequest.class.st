"
Parsed update-repository request derived from one MCPToolRequest.

It identifies a registered repository and describes package membership or subdirectory changes without exposing raw argument dictionaries to commands.
"
Class {
	#name : 'MCPRepositoryUpdateRequest',
	#superclass : 'Object',
	#instVars : [
		'repositoryReference',
		'subdirectory',
		'packageNames',
		'addPackageNames',
		'removePackageNames',
		'suppliedProperties'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
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
MCPRepositoryUpdateRequest >> contextValueForPropertyNamed: propertyName [

	propertyName = 'subdirectory' ifTrue: [ ^ self subdirectory ].
	propertyName = 'packageNames' ifTrue: [ ^ self packageNames ].
	propertyName = 'addPackageNames' ifTrue: [ ^ self addPackageNames ].
	propertyName = 'removePackageNames' ifTrue: [
		^ self removePackageNames ].
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

	suppliedProperties := self updatePropertyNames select: [ :each |
		                      request hasArgumentNamed: each ].
	repositoryReference := MCPRepositoryReferenceSpec fromRequest:
		                       request.
	subdirectory := request stringArgumentNamed: 'subdirectory'.
	packageNames := request stringCollectionArgumentNamed: 'packageNames'.
	addPackageNames := request stringCollectionArgumentNamed:
		                   'addPackageNames'.
	removePackageNames := request stringCollectionArgumentNamed:
		                      'removePackageNames'.
	^ self
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

{ #category : 'accessing' }
MCPRepositoryUpdateRequest >> repositoryReference [

	^ repositoryReference
]

{ #category : 'converting' }
MCPRepositoryUpdateRequest >> requestedContext [

	| context |
	context := self repositoryReference requestedContext copy.
	self suppliedProperties do: [ :propertyName |
		context
			at: propertyName asSymbol
			put: (self contextValueForPropertyNamed: propertyName) ].
	context at: #updateActions put: self requestedRepositoryUpdateActions.
	^ context
]

{ #category : 'accessing' }
MCPRepositoryUpdateRequest >> requestedRepositoryUpdateActions [

	| actions |
	actions := OrderedCollection new.
	(self hasSuppliedPropertyNamed: 'subdirectory') ifTrue: [
		actions add: 'setSubdirectory' ].
	(self hasSuppliedPropertyNamed: 'packageNames') ifTrue: [
		actions add: 'replacePackages' ].
	(self hasSuppliedPropertyNamed: 'addPackageNames') ifTrue: [
		actions add: 'addPackages' ].
	(self hasSuppliedPropertyNamed: 'removePackageNames') ifTrue: [
		actions add: 'removePackages' ].
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

	^ #( 'subdirectory' 'packageNames' 'addPackageNames'
	     'removePackageNames' )
]
