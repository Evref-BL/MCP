"
Result DTO returned by repository_identity_verify. It keeps the fields the call checked, which the summary names; a mismatch is an error, so a result needs nothing more.
"
Class {
	#name : 'MCPRepositoryVerifyIdentityResult',
	#superclass : 'MCPRepositorySnapshotResult',
	#instVars : [
		'checkedFields'
	],
	#category : 'MCP-IDE-Results',
	#package : 'MCP-IDE',
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
	"A mismatch is an error, so a result says only that the fields the summary names held."

	^ Dictionary new
]

{ #category : 'accessing' }
MCPRepositoryVerifyIdentityResult >> checkedFields [

	^ checkedFields ifNil: [ #(  ) ]
]

{ #category : 'initialization' }
MCPRepositoryVerifyIdentityResult >> initializeRepository: aRepository checkedFields: fieldNames [

	self initializeSnapshotFromRepository: aRepository.
	checkedFields := fieldNames ifNil: [ #(  ) ]
]
