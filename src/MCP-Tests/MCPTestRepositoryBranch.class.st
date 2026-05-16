"
Test double for an Iceberg branch used by repository tool tests.
"
Class {
	#name : 'MCPTestRepositoryBranch',
	#superclass : 'Object',
	#instVars : [
		'repository'
	],
	#category : 'MCP-Tests-Internal',
	#package : 'MCP-Tests',
	#tag : 'Internal'
}

{ #category : 'instance creation' }
MCPTestRepositoryBranch class >> repository: aRepository [

	^ self new
		  repository: aRepository;
		  yourself
]

{ #category : 'actions' }
MCPTestRepositoryBranch >> pull [

	self
		signalFailureIfNeeded: repository failPull
		defaultMessage: 'Pull failed for test repository'.
	repository recordAction: 'pull'.
	repository headDescription: 'after pull'.
	repository modifiedPackageNames: #( 'MCP-Test-Pulled' )
]

{ #category : 'actions' }
MCPTestRepositoryBranch >> push [

	self
		signalFailureIfNeeded: repository failPush
		defaultMessage: 'Push failed for test repository'.
	repository recordAction: 'push'.
	repository headDescription: 'after push'
]

{ #category : 'accessing' }
MCPTestRepositoryBranch >> repository: aRepository [

	repository := aRepository
]

{ #category : 'private' }
MCPTestRepositoryBranch >> signalFailureIfNeeded: failure defaultMessage: aString [

	failure ifNil: [ ^ self ].
	failure = false ifTrue: [ ^ self ].
	failure == true ifTrue: [ Error signal: aString ].
	(failure isAssociation and: [ failure key isBehavior ]) ifTrue: [
		failure key signal: failure value ].
	failure isString ifTrue: [ Error signal: failure ].
	(failure isKindOf: Exception) ifTrue: [ failure signal ].
	Error signal: failure asString
]
