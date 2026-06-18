"
Result DTO returned by repository_create or repository_attach. It reports the registered repository and the packages managed by its working copy after creation or attachment.
"
Class {
	#name : 'MCPRepositoryCreateResult',
	#superclass : 'Object',
	#instVars : [
		'repositoryInfo',
		'packageInfos'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPRepositoryCreateResult class >> fromRepository: aRepository [

	^ self new initializeFromRepository: aRepository
]

{ #category : 'converting' }
MCPRepositoryCreateResult >> asDictionary [

	^ Dictionary new
]

{ #category : 'initialization' }
MCPRepositoryCreateResult >> initializeFromRepository: aRepository [

	| packages |
	repositoryInfo := MCPRepositoryInfo fromRepository: aRepository.
	packages := aRepository workingCopy packages asArray
		            sort: [ :left :right |
		            left name asString <= right name asString ].
	packageInfos := packages collect: [ :each |
		                MCPRepositoryPackageInfo fromPackage: each ].
	^ self
]

{ #category : 'accessing' }
MCPRepositoryCreateResult >> packageInfos [

	^ packageInfos ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryCreateResult >> packageInfos: aCollection [

	packageInfos := aCollection ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryCreateResult >> repositoryInfo [

	^ repositoryInfo
]

{ #category : 'accessing' }
MCPRepositoryCreateResult >> repositoryInfo: aRepositoryInfo [

	repositoryInfo := aRepositoryInfo
]
