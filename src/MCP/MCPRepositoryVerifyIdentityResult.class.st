"
Result DTO returned by repository_identity_verify. It reports the repository snapshot that matched the caller's expected identity fields.
"
Class {
	#name : 'MCPRepositoryVerifyIdentityResult',
	#superclass : 'Object',
	#instVars : [
		'repositoryInfo',
		'packageInfos',
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

	repositoryInfo := MCPRepositoryInfo fromRepository: aRepository.
	packageInfos := self packageInfosFromRepository: aRepository.
	checkedFields := fieldNames ifNil: [ #(  ) ].
	matched := true.
	^ self
]

{ #category : 'accessing' }
MCPRepositoryVerifyIdentityResult >> matched [

	^ matched ifNil: [ false ]
]

{ #category : 'accessing' }
MCPRepositoryVerifyIdentityResult >> packageInfos [

	^ packageInfos ifNil: [ #(  ) ]
]

{ #category : 'private' }
MCPRepositoryVerifyIdentityResult >> packageInfosFromRepository: aRepository [

	| packages |
	packages := aRepository workingCopy packages asArray
		            sort: [ :left :right |
		            left name asString <= right name asString ].
	^ packages collect: [ :each |
		  MCPRepositoryPackageInfo fromPackage: each ]
]

{ #category : 'accessing' }
MCPRepositoryVerifyIdentityResult >> repositoryInfo [

	^ repositoryInfo
]
