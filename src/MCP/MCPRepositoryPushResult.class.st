"
Result DTO returned by repository_push. It reports repository metadata, remote names, and branch/head state after the push.
"
Class {
	#name : 'MCPRepositoryPushResult',
	#superclass : 'MCPRepositorySnapshotResult',
	#instVars : [
		'remoteNames',
		'branchName',
		'headDescription'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPRepositoryPushResult class >> repository: aRepository [

	^ self new initializeRepository: aRepository
]

{ #category : 'converting' }
MCPRepositoryPushResult >> asDictionary [

	| data |
	data := Dictionary new.
	self branchName ifNotEmpty: [ :name | data at: #branchName put: name ].
	self headDescription ifNotEmpty: [ :description |
		data at: #headDescription put: description ].
	^ data
]

{ #category : 'accessing' }
MCPRepositoryPushResult >> branchName [

	^ branchName ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPRepositoryPushResult >> headDescription [

	^ headDescription ifNil: [ '' ]
]

{ #category : 'initialization' }
MCPRepositoryPushResult >> initializeRepository: aRepository [

	self initializeSnapshotFromRepository: aRepository.
	remoteNames := repositoryInfo remoteNames.
	branchName := repositoryInfo branchName.
	headDescription := repositoryInfo headDescription
]

{ #category : 'accessing' }
MCPRepositoryPushResult >> remoteNames [

	^ remoteNames ifNil: [ #(  ) ]
]
