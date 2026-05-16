"
Result DTO returned by edit-repository operation=push. It reports repository metadata, remote names, and branch/head state after the push.
"
Class {
	#name : 'MCPRepositoryPushResult',
	#superclass : 'Object',
	#instVars : [
		'repositoryInfo',
		'packageInfos',
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

	^ {
		  (#repository -> self repositoryInfo asDictionary).
		  (#packages
		   ->
		   (self packageInfos
			    collect: [ :each | each asDictionary ]
			    as: Array)).
		  (#packageNames -> self repositoryInfo packageNames).
		  (#remoteNames -> self remoteNames).
		  (#branchName -> self branchName).
		  (#headDescription -> self headDescription).
		  (#repositoryLocation -> self repositoryInfo location) }
		  asDictionary
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

	repositoryInfo := MCPRepositoryInfo fromRepository: aRepository.
	packageInfos := self packageInfosFromRepository: aRepository.
	remoteNames := repositoryInfo remoteNames.
	branchName := repositoryInfo branchName.
	headDescription := repositoryInfo headDescription.
	^ self
]

{ #category : 'accessing' }
MCPRepositoryPushResult >> packageInfos [

	^ packageInfos ifNil: [ #(  ) ]
]

{ #category : 'private' }
MCPRepositoryPushResult >> packageInfosFromRepository: aRepository [

	| packages |
	packages := aRepository workingCopy packages asArray
		            asSortedCollection: [ :left :right |
		            left name asString <= right name asString ].
	^ packages collect: [ :each |
		  MCPRepositoryPackageInfo fromPackage: each ]
]

{ #category : 'accessing' }
MCPRepositoryPushResult >> remoteNames [

	^ remoteNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryPushResult >> repositoryInfo [

	^ repositoryInfo
]
