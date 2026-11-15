"
Result DTO returned by repository_reload. It names the packages the reload loaded from the checkout's files; where HEAD is goes in the summary.
"
Class {
	#name : 'MCPRepositoryReloadResult',
	#superclass : 'MCPRepositorySnapshotResult',
	#instVars : [
		'packageNames'
	],
	#category : 'MCP-IDE-Results',
	#package : 'MCP-IDE',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPRepositoryReloadResult class >> repository: aRepository packageNames: names [

	^ self new initializeRepository: aRepository packageNames: names
]

{ #category : 'converting' }
MCPRepositoryReloadResult >> asDictionary [

	| data |
	data := Dictionary new.
	self packageNames ifNotEmpty: [ :names | data at: #packages put: names asArray ].
	^ data
]

{ #category : 'initialization' }
MCPRepositoryReloadResult >> initializeRepository: aRepository packageNames: names [

	self initializeSnapshotFromRepository: aRepository.
	packageNames := names ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryReloadResult >> packageNames [

	^ packageNames ifNil: [ #(  ) ]
]
