"
Parsed input for edit-repository operation=export. It resolves the registered Iceberg repository that should be synchronized from the image working copy to files.
"
Class {
	#name : 'MCPRepositoryExportRequest',
	#superclass : 'Object',
	#instVars : [
		'repositoryReference'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPRepositoryExportRequest class >> fromRequest: request tool: aTool [

	^ self new initializeFromRequest: request
]

{ #category : 'initialization' }
MCPRepositoryExportRequest >> initializeFromRequest: request [

	repositoryReference := MCPRepositoryReferenceSpec fromRequest:
		                       request.
	^ self
]

{ #category : 'accessing' }
MCPRepositoryExportRequest >> operation [

	^ 'export'
]

{ #category : 'accessing' }
MCPRepositoryExportRequest >> repository [

	^ self repositoryReference repository
]

{ #category : 'accessing' }
MCPRepositoryExportRequest >> repositoryReference [

	^ repositoryReference
]

{ #category : 'converting' }
MCPRepositoryExportRequest >> requestedContext [

	^ self repositoryReference requestedContext
]
