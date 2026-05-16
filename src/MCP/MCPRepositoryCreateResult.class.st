"
Result DTO returned by edit-repository operation=create. It reports the registered repository and the packages managed by its working copy after creation.
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

	^ {
		  (#repository -> self repositoryInfo asDictionary).
		  (#packages
		   ->
		   (self packageInfos
			    collect: [ :each | each asDictionary ]
			    as: Array)).
		  (#packageNames -> self repositoryInfo packageNames) } asDictionary
]

{ #category : 'initialization' }
MCPRepositoryCreateResult >> initializeFromRepository: aRepository [

	| packages |
	repositoryInfo := MCPRepositoryInfo fromRepository: aRepository.
	packages := aRepository workingCopy packages asArray
		            asSortedCollection: [ :left :right |
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
