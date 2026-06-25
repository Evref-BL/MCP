"
Parsed input for repository_identity_verify. It resolves a registered Iceberg repository and records expected identity fields that should be asserted before image-side repository work continues.
"
Class {
	#name : 'MCPRepositoryVerifyIdentityRequest',
	#superclass : 'MCPRepositoryBranchRequest',
	#instVars : [
		'subdirectory',
		'packageNames',
		'modifiedPackageNames',
		'isModified',
		'hasSubdirectory',
		'hasPackageNames',
		'hasModifiedPackageNames',
		'hasIsModified'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPRepositoryVerifyIdentityRequest class >> fromRequest: request tool: aTool [

	^ self new initializeFromRequest: request
]

{ #category : 'converting' }
MCPRepositoryVerifyIdentityRequest >> commandForTool: aTool [

	^ MCPRepositoryVerifyIdentityCommand tool: aTool request: self
]

{ #category : 'testing' }
MCPRepositoryVerifyIdentityRequest >> hasExpectedIdentityFields [

	^ self repositoryReference hasLocation or: [
		  self branchName isNotEmpty or: [
			  self hasExpectedSubdirectory or: [
				  self hasExpectedPackageNames or: [
					  self hasExpectedModifiedPackageNames or: [
						  self hasExpectedIsModified ] ] ] ] ]
]

{ #category : 'testing' }
MCPRepositoryVerifyIdentityRequest >> hasExpectedIsModified [

	^ hasIsModified ifNil: [ false ]
]

{ #category : 'testing' }
MCPRepositoryVerifyIdentityRequest >> hasExpectedModifiedPackageNames [

	^ hasModifiedPackageNames ifNil: [ false ]
]

{ #category : 'testing' }
MCPRepositoryVerifyIdentityRequest >> hasExpectedPackageNames [

	^ hasPackageNames ifNil: [ false ]
]

{ #category : 'testing' }
MCPRepositoryVerifyIdentityRequest >> hasExpectedSubdirectory [

	^ hasSubdirectory ifNil: [ false ]
]

{ #category : 'initialization' }
MCPRepositoryVerifyIdentityRequest >> initializeFromRequest: request [

	super initializeFromRequest: request.
	hasSubdirectory := request hasArgumentNamed: 'subdirectory'.
	hasPackageNames := request hasArgumentNamed: 'packageNames'.
	hasModifiedPackageNames := request hasArgumentNamed: 'modifiedPackageNames'.
	hasIsModified := request hasArgumentNamed: 'isModified'.
	hasSubdirectory ifTrue: [
		subdirectory := self
			stringArgumentNamed: 'subdirectory'
			preservingEmptyFrom: request ].
	hasPackageNames ifTrue: [
		packageNames := request uniqueStringCollectionArgumentNamed: 'packageNames' ].
	hasModifiedPackageNames ifTrue: [
		modifiedPackageNames := request uniqueStringCollectionArgumentNamed:
			'modifiedPackageNames' ].
	hasIsModified ifTrue: [
		isModified := request booleanArgumentNamed: 'isModified' default: false ]
]

{ #category : 'accessing' }
MCPRepositoryVerifyIdentityRequest >> isModified [

	^ isModified
]

{ #category : 'accessing' }
MCPRepositoryVerifyIdentityRequest >> modifiedPackageNames [

	^ modifiedPackageNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryVerifyIdentityRequest >> operation [

	^ 'verifyIdentity'
]

{ #category : 'accessing' }
MCPRepositoryVerifyIdentityRequest >> packageNames [

	^ packageNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryVerifyIdentityRequest >> repository [

	^ self repositoryReference repository
]

{ #category : 'converting' }
MCPRepositoryVerifyIdentityRequest >> requestedContext [

	| context |
	context := self repositoryReference requestedContext copy.
	self branchName ifNotEmpty: [ :expectedBranchName |
		context at: #branchName put: expectedBranchName ].
	self hasExpectedSubdirectory ifTrue: [
		context at: #subdirectory put: self subdirectory ].
	self hasExpectedPackageNames ifTrue: [
		context at: #packageNames put: self packageNames ].
	self hasExpectedModifiedPackageNames ifTrue: [
		context at: #modifiedPackageNames put: self modifiedPackageNames ].
	self hasExpectedIsModified ifTrue: [
		context at: #isModified put: self isModified ].
	^ context
]

{ #category : 'private - parsing' }
MCPRepositoryVerifyIdentityRequest >> stringArgumentNamed: anArgumentName preservingEmptyFrom: request [

	| value |
	value := request argumentNamed: anArgumentName ifAbsent: [ ^ nil ].
	value ifNil: [ ^ nil ].
	^ value asString trimBoth
]

{ #category : 'accessing' }
MCPRepositoryVerifyIdentityRequest >> subdirectory [

	^ subdirectory ifNil: [ '' ]
]
