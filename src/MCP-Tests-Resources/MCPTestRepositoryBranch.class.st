"
Test double for an Iceberg branch used by repository tool tests.
"
Class {
	#name : 'MCPTestRepositoryBranch',
	#superclass : 'Object',
	#instVars : [
		'repository'
	],
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'instance creation' }
MCPTestRepositoryBranch class >> repository: aRepository [

	^ self new
		  repository: aRepository;
		  yourself
]

{ #category : 'accessing' }
MCPTestRepositoryBranch >> repository: aRepository [

	repository := aRepository
]

{ #category : 'private' }
MCPTestRepositoryBranch >> signalFailureIfNeeded: failure defaultMessage: aString [

	failure ifNil: [ ^ self ].
	failure == false ifTrue: [ ^ self ].
	failure == true ifTrue: [ Error signal: aString ].
	failure isAssociation ifTrue: [ failure key signal: failure value ].
	failure isString ifTrue: [ Error signal: failure ].
	Error signal: failure asString
]
