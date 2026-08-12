"
Abstract base for repository result DTOs. It owns shared repository snapshot helpers used by concrete repository tool results while leaving each result class responsible for its own public payload shape.
"
Class {
	#name : 'MCPRepositoryResult',
	#superclass : 'MCPResult',
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'testing' }
MCPRepositoryResult class >> isAbstract [

	^ self = MCPRepositoryResult
]

{ #category : 'converting' }
MCPRepositoryResult >> branchHeadDictionary [

	| data |
	data := Dictionary new.
	self branchName ifNotEmpty: [ :name | data at: #branchName put: name ].
	self headDescription ifNotEmpty: [ :description | data at: #headDescription put: description ].
	^ data
]

{ #category : 'accessing' }
MCPRepositoryResult >> branchName [

	^ ''
]

{ #category : 'accessing' }
MCPRepositoryResult >> headDescription [

	^ ''
]

{ #category : 'private' }
MCPRepositoryResult >> packageInfosFromRepository: aRepository [

	^ (aRepository workingCopy packages asArray sort: [ :left :right | left name asString <= right name asString ]) collect: [ :each |
		  MCPRepositoryPackageInfo fromPackage: each ]
]

{ #category : 'private' }
MCPRepositoryResult >> repositoryInfoFromRepository: aRepository [

	^ MCPRepositoryInfo fromRepository: aRepository
]
