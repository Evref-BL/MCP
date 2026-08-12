"
Abstract MCP tool support for focused repository remote-management operations.
"
Class {
	#name : 'MCPToolRepositoryRemoteOperation',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolRepositoryRemoteOperation class >> isAbstract [

	^ self = MCPToolRepositoryRemoteOperation
]

{ #category : 'private - schema' }
MCPToolRepositoryRemoteOperation >> newRemoteNameSchemaProperty [

	^ self schemaPropertyNamed: 'newRemoteName' type: 'string' description: 'New remote name.'
]

{ #category : 'private - schema' }
MCPToolRepositoryRemoteOperation >> remoteNameSchemaProperty [

	^ self schemaPropertyNamed: 'remoteName' type: 'string' description: 'Remote name.'
]

{ #category : 'private - schema' }
MCPToolRepositoryRemoteOperation >> remoteUrlSchemaProperty [

	^ self schemaPropertyNamed: 'remoteUrl' type: 'string' description: 'Remote URL.'
]

{ #category : 'testing' }
MCPToolRepositoryRemoteOperation >> shouldSaveImageAfterSuccessfulExecutionForResult: aResult [

	^ false
]

{ #category : 'validating' }
MCPToolRepositoryRemoteOperation >> validateRequest: request [

	super validateRequest: request.
	self requiredInputProperties do: [ :each |
			(request argumentNamed: each ifAbsent: [ nil ]) ifNotNil: [ :value |
					(value isString and: [ value trimBoth isEmpty ]) ifTrue: [
						MCPInvalidToolInput signalMissingRequiredArgumentNamed: each forTool: self ] ] ]
]
