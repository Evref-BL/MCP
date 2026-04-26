"
Command that performs a Metacello baseline load and reports packages and repositories that appeared afterward. Repository-backed loads reuse this command by adding Metacello configuration before execution.
"
Class {
	#name : 'MCPLoadBaselineCommand',
	#superclass : 'Object',
	#instVars : [
		'tool',
		'request',
		'configureMetacelloBlock'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPLoadBaselineCommand class >> tool: aTool request: aRequest [

	^ self
		  tool: aTool
		  request: aRequest
		  configureMetacello: [ :metacello | metacello ]
]

{ #category : 'instance creation' }
MCPLoadBaselineCommand class >> tool: aTool request: aRequest configureMetacello: aBlock [

	^ self new
		  initializeTool: aTool
		  request: aRequest
		  configureMetacello: aBlock
]

{ #category : 'private - loading' }
MCPLoadBaselineCommand >> applyConflictPolicyTo: metacello [

	self request onConflict = 'useLoaded' ifTrue: [
		^ metacello onConflictUseLoaded ].
	self request onConflict = 'useIncoming' ifTrue: [
		^ metacello onConflictUseIncoming ].
	self request onConflict = 'pass' ifTrue: [ ^ self ].
	MCPCommandError
		signalErrorCode: #UnsupportedLoadBaselineConflictPolicy
		message: 'onConflict must be useLoaded, useIncoming, or pass.'
		details: self request requestedContext
]

{ #category : 'private - loading' }
MCPLoadBaselineCommand >> applyWarningPolicyTo: metacello [

	self request onWarning = 'log' ifTrue: [ ^ metacello onWarningLog ].
	self request onWarning = 'resume' ifTrue: [
		^ metacello onWarning: [ :warning | warning resume ] ].
	self request onWarning = 'pass' ifTrue: [ ^ self ].
	MCPCommandError
		signalErrorCode: #UnsupportedLoadBaselineWarningPolicy
		message: 'onWarning must be log, resume, or pass.'
		details: self request requestedContext
]

{ #category : 'private - loading' }
MCPLoadBaselineCommand >> configureMetacello: metacello [

	configureMetacelloBlock ifNotNil: [
		configureMetacelloBlock value: metacello ].
	^ metacello
]

{ #category : 'private - loading' }
MCPLoadBaselineCommand >> configuredMetacello [

	| metacello |
	metacello := Metacello new.
	metacello baseline: self request baseline.
	self applyWarningPolicyTo: metacello.
	self applyConflictPolicyTo: metacello.
	^ metacello
]

{ #category : 'private - image state' }
MCPLoadBaselineCommand >> currentPackageNames [

	^ (PackageOrganizer default packageNames collect: [ :each |
		   each asString ]) asArray asSortedCollection asArray
]

{ #category : 'private - image state' }
MCPLoadBaselineCommand >> currentRepositories [

	^ [ IceRepository repositories asArray ]
		  on: Error
		  do: [ :ignored | #(  ) ]
]

{ #category : 'executing' }
MCPLoadBaselineCommand >> execute [

	| beforePackageNames beforeRepositories metacello |
	beforePackageNames := self currentPackageNames.
	beforeRepositories := self currentRepositories.
	metacello := self configuredMetacello.
	self configureMetacello: metacello.
	self loadMetacello: metacello.
	^ MCPLoadBaselineResult
		  request: self request
		  newPackageNames: (self newPackageNamesAfter: beforePackageNames)
		  repositoryInfos:
		  (self newRepositoryInfosAfter: beforeRepositories)
]

{ #category : 'initialization' }
MCPLoadBaselineCommand >> initializeTool: aTool request: aRequest configureMetacello: aBlock [

	tool := aTool.
	request := aRequest.
	configureMetacelloBlock := aBlock.
	^ self
]

{ #category : 'private - loading' }
MCPLoadBaselineCommand >> loadMetacello: metacello [

	[
	self request groups isEmpty
		ifTrue: [ metacello load ]
		ifFalse: [ metacello load: self request groups ] ]
		on: MetacelloNotification
		do: [ :notification | notification resume ]
]

{ #category : 'private - image state' }
MCPLoadBaselineCommand >> newPackageNamesAfter: beforePackageNames [

	| beforeSet |
	beforeSet := beforePackageNames asSet.
	^ (self currentPackageNames reject: [ :each |
		   beforeSet includes: each ]) asArray asSortedCollection asArray
]

{ #category : 'private - image state' }
MCPLoadBaselineCommand >> newRepositoryInfosAfter: beforeRepositories [

	| beforeSet |
	beforeSet := IdentitySet new.
	beforeSet addAll: beforeRepositories.
	^ ((self currentRepositories reject: [ :each |
		    beforeSet includes: each ]) collect: [ :each |
		   MCPRepositoryInfo fromRepository: each ]) asArray
]

{ #category : 'accessing' }
MCPLoadBaselineCommand >> request [

	^ request
]

{ #category : 'accessing' }
MCPLoadBaselineCommand >> tool [

	^ tool
]
