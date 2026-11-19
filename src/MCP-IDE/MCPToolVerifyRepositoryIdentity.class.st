"
Concrete repository_identity_verify tool. It verifies expected Iceberg repository identity fields through MCPToolRepositoryOperation without writing files.
"
Class {
	#name : 'MCPToolVerifyRepositoryIdentity',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolVerifyRepositoryIdentity class >> toolName [

	^ 'repository_identity_verify'
]

{ #category : 'private - validation' }
MCPToolVerifyRepositoryIdentity >> addMismatchIfExpected: expectedValue actual: actualValue field: fieldName checkedFields: checkedFields mismatches: mismatches [

	checkedFields add: fieldName.
	expectedValue = actualValue ifTrue: [ ^ self ].
	mismatches add: {
			(#field -> fieldName).
			(#expected -> expectedValue).
			(#actual -> actualValue) } asDictionary
]

{ #category : 'metadata' }
MCPToolVerifyRepositoryIdentity >> additionalKeywords [

	^ super additionalKeywords , #( 'identity' 'guard' )
]

{ #category : 'metadata' }
MCPToolVerifyRepositoryIdentity >> annotations [

	^ MCPStructureToolAnnotations readOnly
]

{ #category : 'private - validation' }
MCPToolVerifyRepositoryIdentity >> compare: anInfo with: request checkedFields: checkedFields mismatches: mismatches [
	"Each expectation the call gives beside what the image holds, in the order the schema lists them."

	| reference steps |
	reference := self repositoryReferenceFor: request.
	steps := MCPRepositoryCommand new.
	reference hasLocation ifTrue: [
			self
				addMismatchIfExpected: reference location
				actual: anInfo location
				field: 'location'
				checkedFields: checkedFields
				mismatches: mismatches ].
	(self expectedBranchNameIn: request) ifNotEmpty: [ :branchName |
			self
				addMismatchIfExpected: branchName
				actual: anInfo branchName
				field: 'branch'
				checkedFields: checkedFields
				mismatches: mismatches ].
	(request hasArgumentNamed: 'subdirectory') ifTrue: [
			self
				addMismatchIfExpected: (self expectedSubdirectoryIn: request)
				actual: anInfo subdirectory
				field: 'subdirectory'
				checkedFields: checkedFields
				mismatches: mismatches ].
	(request hasArgumentNamed: 'packages') ifTrue: [
			self
				addMismatchIfExpected: (steps sortedStringsFrom: (request uniqueStringCollectionArgumentNamed: 'packages'))
				actual: anInfo packageNames
				field: 'packages'
				checkedFields: checkedFields
				mismatches: mismatches ].
	(request hasArgumentNamed: 'modifiedPackages') ifTrue: [
			self
				addMismatchIfExpected: (steps sortedStringsFrom: (request uniqueStringCollectionArgumentNamed: 'modifiedPackages'))
				actual: anInfo modifiedPackageNames
				field: 'modifiedPackages'
				checkedFields: checkedFields
				mismatches: mismatches ].
	(request hasArgumentNamed: 'isModified') ifTrue: [
			self
				addMismatchIfExpected: (request booleanArgumentNamed: 'isModified')
				actual: anInfo isModified
				field: 'isModified'
				checkedFields: checkedFields
				mismatches: mismatches ]
]

{ #category : 'private - request' }
MCPToolVerifyRepositoryIdentity >> expectedSubdirectoryIn: request [
	"As the caller wrote it, trimmed: an empty subdirectory is one to expect, the checkout's root."

	^ (request argumentNamed: 'subdirectory' ifAbsent: [ nil ]) ifNil: [ '' ] ifNotNil: [ :value | value asString trimBoth ]
]

{ #category : 'private - errors' }
MCPToolVerifyRepositoryIdentity >> failureSummaryPrefixFor: request [

	^ 'Failed to verify repository identity: '
]

{ #category : 'private - request' }
MCPToolVerifyRepositoryIdentity >> hasExpectationsIn: request [
	"Whether the call expects anything of the repository besides naming it."

	^ (self repositoryReferenceFor: request) hasLocation or: [
			  (self expectedBranchNameIn: request) isNotEmpty or: [
				  #( 'subdirectory' 'packages' 'modifiedPackages' 'isModified' ) anySatisfy: [ :each | request hasArgumentNamed: each ] ] ]
]

{ #category : 'private - execution' }
MCPToolVerifyRepositoryIdentity >> mutateWith: request [
	"Compare what the call expects with what the image believes of the repository, writing nothing. A mismatch is an error, so a success names only the fields that held."

	| checkedFields info |
	^ self
		  executeOperationFor: request
		  work: [
				  | mismatches repository |
				  repository := self repositoryToVerifyFor: request.
				  (self hasExpectationsIn: request) ifFalse: [ self signalMissingExpectationsFor: request ].
				  info := MCPRepositoryInfo fromRepository: repository.
				  checkedFields := OrderedCollection new.
				  mismatches := OrderedCollection new.
				  self
					  compare: info
					  with: request
					  checkedFields: checkedFields
					  mismatches: mismatches.
				  mismatches ifNotEmpty: [ self signalMismatches: mismatches asArray of: info for: request ] ]
		  successResult: [ :warnings |
				  self
					  successResultText: (String streamContents: [ :stream |
							   stream << 'Verified repository ' << info name << ': ' << (', ' join: checkedFields) << ' as expected.' ])
					  data: Dictionary new
					  warnings: warnings ]
]

{ #category : 'private - resolving' }
MCPToolVerifyRepositoryIdentity >> repositoryToVerifyFor: request [
	"A location that names no registered repository is an expectation that fails, not a reference that does, when a repository of that name exists."

	| reference |
	reference := self repositoryReferenceFor: request.
	^ [ reference repository ]
		  on: MCPCommandError
		  do: [ :error |
				  (error errorCode = #RepositoryNotFound and: [ reference hasName and: [ reference hasLocation ] ])
					  ifTrue: [ (MCPRepositoryReferenceSpec name: reference name location: nil) repository ]
					  ifFalse: [ error signal ] ]
]

{ #category : 'private - errors' }
MCPToolVerifyRepositoryIdentity >> requestedContextFor: request [

	| context |
	context := super requestedContextFor: request.
	(request hasArgumentNamed: 'subdirectory') ifTrue: [ context at: #subdirectory put: (self expectedSubdirectoryIn: request) ].
	(request hasArgumentNamed: 'packages') ifTrue: [
		context at: #packages put: (request uniqueStringCollectionArgumentNamed: 'packages') ].
	(request hasArgumentNamed: 'modifiedPackages') ifTrue: [
		context at: #modifiedPackages put: (request uniqueStringCollectionArgumentNamed: 'modifiedPackages') ].
	(request hasArgumentNamed: 'isModified') ifTrue: [ context at: #isModified put: (request booleanArgumentNamed: 'isModified') ].
	^ context
]

{ #category : 'private - errors' }
MCPToolVerifyRepositoryIdentity >> signalMismatches: mismatches of: anInfo for: request [

	MCPCommandError
		signalErrorCode: #RepositoryIdentityMismatch
		message: (String streamContents: [ :stream | stream << 'Repository identity verification failed for ' << anInfo name << '.' ])
		details: ((self requestedContextFor: request) copy
				 at: #repository put: anInfo asDictionary;
				 at: #mismatches put: mismatches;
				 yourself)
]

{ #category : 'private - errors' }
MCPToolVerifyRepositoryIdentity >> signalMissingExpectationsFor: request [

	MCPCommandError
		signalErrorCode: #RepositoryIdentityExpectationRequired
		message: 'repository_identity_verify requires at least one expected identity field besides name.'
		details: ((self requestedContextFor: request) copy
				 at: #expectedFields put: #( 'location' 'branch' 'subdirectory' 'packages' 'modifiedPackages' 'isModified' );
				 yourself)
]

{ #category : 'private - specs' }
MCPToolVerifyRepositoryIdentity >> toolSpec [

	^ {
		  (#title -> 'Verify Repository Identity').
		  (#description
		   ->
		   'Assert what the image believes about a registered repository, without writing files. Give at least one expectation beside the repository reference: location, branch, subdirectory, packages, modifiedPackages or isModified. The call fails when one of them does not hold.').
		  (#action -> 'verifyIdentity').
		  (#inputProperties -> {
			   self branchNameSchemaProperty.
			   self subdirectorySchemaProperty.
			   self packageNamesSchemaProperty.
			   self modifiedPackageNamesSchemaProperty.
			   self isModifiedSchemaProperty }).
		  (#requiredProperties -> #( 'repository' )) } asDictionary
]
