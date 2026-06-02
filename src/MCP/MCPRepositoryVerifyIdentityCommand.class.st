"
Command wrapper for repository_identity_verify.

It performs a read-only identity assertion over a registered Iceberg repository before later repository commands or exports run.
"
Class {
	#name : 'MCPRepositoryVerifyIdentityCommand',
	#superclass : 'Object',
	#instVars : [
		'tool',
		'request'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPRepositoryVerifyIdentityCommand class >> tool: aTool request: aRequest [

	^ self new initializeTool: aTool request: aRequest
]

{ #category : 'private - validation' }
MCPRepositoryVerifyIdentityCommand >> addMismatchIfExpected: expectedValue actual: actualValue field: fieldName checkedFields: checkedFields mismatches: mismatches [

	checkedFields add: fieldName.
	expectedValue = actualValue ifTrue: [ ^ self ].
	mismatches add: {
			(#field -> fieldName).
			(#expected -> expectedValue).
			(#actual -> actualValue) } asDictionary
]

{ #category : 'private - validation' }
MCPRepositoryVerifyIdentityCommand >> checkBranchNameFor: repositoryInfo checkedFields: checkedFields mismatches: mismatches [

	self request branchName ifEmpty: [ ^ self ].
	self
		addMismatchIfExpected: self request branchName
		actual: repositoryInfo branchName
		field: 'branchName'
		checkedFields: checkedFields
		mismatches: mismatches
]

{ #category : 'private - validation' }
MCPRepositoryVerifyIdentityCommand >> checkIsModifiedFor: repositoryInfo checkedFields: checkedFields mismatches: mismatches [

	self request hasExpectedIsModified ifFalse: [ ^ self ].
	self
		addMismatchIfExpected: self request isModified
		actual: repositoryInfo isModified
		field: 'isModified'
		checkedFields: checkedFields
		mismatches: mismatches
]

{ #category : 'private - validation' }
MCPRepositoryVerifyIdentityCommand >> checkLocationFor: repositoryInfo checkedFields: checkedFields mismatches: mismatches [

	self request repositoryReference hasLocation ifFalse: [ ^ self ].
	self
		addMismatchIfExpected: self request repositoryReference location
		actual: repositoryInfo location
		field: 'location'
		checkedFields: checkedFields
		mismatches: mismatches
]

{ #category : 'private - validation' }
MCPRepositoryVerifyIdentityCommand >> checkModifiedPackageNamesFor: repositoryInfo checkedFields: checkedFields mismatches: mismatches [

	self request hasExpectedModifiedPackageNames ifFalse: [ ^ self ].
	self
		addMismatchIfExpected:
		(self sortedStringsFrom: self request modifiedPackageNames)
		actual: repositoryInfo modifiedPackageNames
		field: 'modifiedPackageNames'
		checkedFields: checkedFields
		mismatches: mismatches
]

{ #category : 'private - validation' }
MCPRepositoryVerifyIdentityCommand >> checkPackageNamesFor: repositoryInfo checkedFields: checkedFields mismatches: mismatches [

	self request hasExpectedPackageNames ifFalse: [ ^ self ].
	self
		addMismatchIfExpected:
		(self sortedStringsFrom: self request packageNames)
		actual: repositoryInfo packageNames
		field: 'packageNames'
		checkedFields: checkedFields
		mismatches: mismatches
]

{ #category : 'private - validation' }
MCPRepositoryVerifyIdentityCommand >> checkSubdirectoryFor: repositoryInfo checkedFields: checkedFields mismatches: mismatches [

	self request hasExpectedSubdirectory ifFalse: [ ^ self ].
	self
		addMismatchIfExpected: self request subdirectory
		actual: repositoryInfo subdirectory
		field: 'subdirectory'
		checkedFields: checkedFields
		mismatches: mismatches
]

{ #category : 'private - validation' }
MCPRepositoryVerifyIdentityCommand >> checkedFieldsAndMismatchesFor: repositoryInfo [

	| checkedFields mismatches |
	checkedFields := OrderedCollection new.
	mismatches := OrderedCollection new.
	self
		checkLocationFor: repositoryInfo
		checkedFields: checkedFields
		mismatches: mismatches.
	self
		checkBranchNameFor: repositoryInfo
		checkedFields: checkedFields
		mismatches: mismatches.
	self
		checkSubdirectoryFor: repositoryInfo
		checkedFields: checkedFields
		mismatches: mismatches.
	self
		checkPackageNamesFor: repositoryInfo
		checkedFields: checkedFields
		mismatches: mismatches.
	self
		checkModifiedPackageNamesFor: repositoryInfo
		checkedFields: checkedFields
		mismatches: mismatches.
	self
		checkIsModifiedFor: repositoryInfo
		checkedFields: checkedFields
		mismatches: mismatches.
	^ {
		  (#checkedFields -> checkedFields asArray).
		  (#mismatches -> mismatches asArray) } asDictionary
]

{ #category : 'executing' }
MCPRepositoryVerifyIdentityCommand >> execute [

	| repository result validation |
	^ self tool
		  executeMutationAction: 'verifyIdentity'
		  force: false
		  requestedContext: self request requestedContext
		  work: [
			  repository := self repositoryForVerifyIdentity.
			  validation := self validateRepository: repository.
			  result := MCPRepositoryVerifyIdentityResult
				            repository: repository
				            checkedFields:
				            (validation at: #checkedFields) ]
		  successResult: [ :warningMessages |
			  self tool
				  successResultText:
				  'Repository identity verification passed for '
				  , result repositoryInfo name , '.'
				  data: (self tool dataForRepositoryVerifyIdentityResult: result)
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  'Failed to verify repository identity: '
			  , (error messageText ifNil: [ error asString ]) ]
]

{ #category : 'initialization' }
MCPRepositoryVerifyIdentityCommand >> initializeTool: aTool request: aRequest [

	tool := aTool.
	request := aRequest.
	^ self
]

{ #category : 'private - resolving' }
MCPRepositoryVerifyIdentityCommand >> repositoryForVerifyIdentity [

	^ [ self request repository ]
		  on: MCPCommandError
		  do: [ :error |
			  (self shouldRetryByNameOnlyAfter: error)
				  ifTrue: [
					  (MCPRepositoryReferenceSpec
						   name: self request repositoryReference name
						   location: nil) repository ]
				  ifFalse: [ error signal ] ]
]

{ #category : 'accessing' }
MCPRepositoryVerifyIdentityCommand >> request [

	^ request
]

{ #category : 'private - resolving' }
MCPRepositoryVerifyIdentityCommand >> shouldRetryByNameOnlyAfter: anError [

	^ anError errorCode = #RepositoryNotFound and: [
		  self request repositoryReference hasName and: [
			  self request repositoryReference hasLocation ] ]
]

{ #category : 'private - validation' }
MCPRepositoryVerifyIdentityCommand >> signalIdentityMismatchFor: repositoryInfo mismatches: mismatches [

	MCPCommandError
		signalErrorCode: #RepositoryIdentityMismatch
		message:
			'Repository identity verification failed for ' , repositoryInfo name
			, '.'
		details: (self request requestedContext copy
				 at: #repository put: repositoryInfo asDictionary;
				 at: #mismatches put: mismatches;
				 yourself)
]

{ #category : 'private - validation' }
MCPRepositoryVerifyIdentityCommand >> signalMissingExpectedIdentityFields [

	MCPCommandError
		signalErrorCode: #RepositoryIdentityExpectationRequired
		message:
		'repository_identity_verify requires at least one expected identity field besides repositoryName.'
		details: (self request requestedContext copy
				 at: #expectedFields
				 put: #( 'location' 'branchName' 'subdirectory' 'packageNames'
					    'modifiedPackageNames' 'isModified' );
				 yourself)
]

{ #category : 'private' }
MCPRepositoryVerifyIdentityCommand >> sortedStringsFrom: aCollection [

	^ (aCollection collect: [ :each | each asString ]) asSortedCollection
		  asArray
]

{ #category : 'accessing' }
MCPRepositoryVerifyIdentityCommand >> tool [

	^ tool
]

{ #category : 'private - validation' }
MCPRepositoryVerifyIdentityCommand >> validateRepository: aRepository [

	| repositoryInfo validation |
	self request hasExpectedIdentityFields ifFalse: [
		self signalMissingExpectedIdentityFields ].
	repositoryInfo := MCPRepositoryInfo fromRepository: aRepository.
	validation := self checkedFieldsAndMismatchesFor: repositoryInfo.
	(validation at: #mismatches) ifNotEmpty: [ :mismatches |
		self
			signalIdentityMismatchFor: repositoryInfo
			mismatches: mismatches ].
	^ validation
]
