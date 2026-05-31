Class {
	#name : 'MCPToolRepositoryOperation',
	#superclass : 'MCPToolEditRepository',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolRepositoryOperation class >> isAbstract [

	^ self = MCPToolRepositoryOperation
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> branchNameSchemaProperty [

	^ self
		  schemaPropertyNamed: 'branchName'
		  type: 'string'
		  description:
		  'Branch name for repository_branch_create or repository_branch_switch, or an optional expected current branch guard for repository_head_adopt and repository_identity_verify.'
]

{ #category : 'private - execution' }
MCPToolRepositoryOperation >> commandClass [

	^ self repositoryOperationSpec at: #commandClass
]

{ #category : 'private - execution' }
MCPToolRepositoryOperation >> commandForRequest: repositoryRequest [

	^ self commandClass tool: self request: repositoryRequest
]

{ #category : 'defaults' }
MCPToolRepositoryOperation >> defaultDescription [

	^ self repositoryOperationSpec at: #description
]

{ #category : 'defaults' }
MCPToolRepositoryOperation >> defaultInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: self inputProperties;
		  required: self requiredInputProperties;
		  additionalProperties: false;
		  yourself
]

{ #category : 'defaults' }
MCPToolRepositoryOperation >> defaultTitle [

	^ self repositoryOperationSpec at: #title
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> inputProperties [

	^ (self repositoryOperationSpec
		   at: #referenceInputProperties
		   ifAbsent: [ self repositoryReferenceInputProperties ])
	  ,
	  (self repositoryOperationSpec
		   at: #inputProperties
		   ifAbsent: [ #(  ) ])
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> isModifiedSchemaProperty [

	^ self
		  booleanSchemaPropertyNamed: 'isModified'
		  description:
		  'Expected repository modified state for repository identity verification.'
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> messageSchemaProperty [

	^ self
		  schemaPropertyNamed: 'message'
		  type: 'string'
		  description: 'Commit message for the repository commit.'
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> modifiedPackageNamesSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'modifiedPackageNames'
		  description:
		  'Expected modified package names for repository identity verification.'
		  itemDescription: 'An expected modified package name.'
]

{ #category : 'private - errors' }
MCPToolRepositoryOperation >> operationForErrorFromParsedRequest: editRequest rawRequest: rawRequest [

	^ self operationName
]

{ #category : 'private - operations' }
MCPToolRepositoryOperation >> operationName [

	^ self repositoryOperationSpec at: #operation
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> packageNamesSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'packageNames'
		  description:
		  'Expected managed package names for repository identity verification.'
		  itemDescription: 'An expected package name.'
]

{ #category : 'private - request' }
MCPToolRepositoryOperation >> parsedRequestFromToolRequest: request [

	^ self requestClass fromRequest: request tool: self
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> repositoryEditDataProperties [

	^ super repositoryEditDataProperties collect: [ :property |
			  property name = 'action'
				  ifTrue: [
						  self
							  schemaPropertyNamed: 'action'
							  type: 'string'
							  description:
							  'The repository action executed by this focused tool.' ]
				  ifFalse: [ property ] ]
]

{ #category : 'private - operations' }
MCPToolRepositoryOperation >> repositoryOperationSpec [

	self subclassResponsibility
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> repositoryReferenceInputProperties [

	^ {
		  (self
			   schemaPropertyNamed: 'repositoryName'
			   type: 'string'
			   description: 'Registered repository name to target.').
		  (self
			   schemaPropertyNamed: 'location'
			   type: 'string'
			   description:
			   'Optional filesystem path used with repositoryName to disambiguate or guard the selected registered repository.') }
]

{ #category : 'private - execution' }
MCPToolRepositoryOperation >> requestClass [

	^ self repositoryOperationSpec at: #requestClass
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> requiredInputProperties [

	^ self repositoryOperationSpec
		  at: #requiredProperties
		  ifAbsent: [ #( 'repositoryName' ) ]
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> subdirectorySchemaProperty [

	^ self
		  schemaPropertyNamed: 'subdirectory'
		  type: 'string'
		  description:
		  'Expected source subdirectory for repository identity verification. Empty string is accepted.'
]

{ #category : 'validating' }
MCPToolRepositoryOperation >> validateRequest: request [

	self requiredInputProperties do: [ :each |
			(request argumentNamed: each ifAbsent: [ nil ]) ifNil: [
					MCPInvalidToolInput
						signalMissingRequiredArgumentNamed: each
						forTool: self ] ]
]
