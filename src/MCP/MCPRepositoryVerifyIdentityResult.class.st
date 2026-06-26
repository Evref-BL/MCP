"
Result DTO returned by repository_identity_verify. It reports the repository snapshot that matched the caller's expected identity fields.
"
Class {
	#name : 'MCPRepositoryVerifyIdentityResult',
	#superclass : 'MCPRepositorySnapshotResult',
	#instVars : [
		'checkedFields',
		'matched'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPRepositoryVerifyIdentityResult class >> repository: aRepository checkedFields: fieldNames [

	^ self new
		  initializeRepository: aRepository checkedFields: fieldNames;
		  yourself
]

{ #category : 'converting' }
MCPRepositoryVerifyIdentityResult >> asDictionary [

	^ { (#matched -> self matched) } asDictionary
]

{ #category : 'accessing' }
MCPRepositoryVerifyIdentityResult >> checkedFields [

	^ checkedFields ifNil: [ #(  ) ]
]

{ #category : 'initialization' }
MCPRepositoryVerifyIdentityResult >> initializeRepository: aRepository checkedFields: fieldNames [

	self initializeSnapshotFromRepository: aRepository.
	checkedFields := fieldNames ifNil: [ #(  ) ].
	matched := true
]

{ #category : 'accessing' }
MCPRepositoryVerifyIdentityResult >> matched [

	^ matched ifNil: [ false ]
]
