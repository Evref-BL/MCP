"
Result DTO returned by edit-repository operation=verifyIdentity. It reports the repository snapshot that matched the caller's expected identity fields.
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

	^ {
		  (#repository -> self repositoryInfo asDictionary).
		  (#packages
		   ->
		   (self packageInfos
			    collect: [ :each | each asDictionary ]
			    as: Array)).
		  (#packageNames -> self repositoryInfo packageNames).
		  (#modifiedPackageNames -> self repositoryInfo modifiedPackageNames).
		  (#checkedFields -> self checkedFields).
		  (#matched -> self matched).
		  (#branchName -> self repositoryInfo branchName).
		  (#headDescription -> self repositoryInfo headDescription).
		  (#repositoryLocation -> self repositoryInfo location) }
		  asDictionary
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
		            asSortedCollection: [ :left :right |
		            left name asString <= right name asString ].
	^ packages collect: [ :each |
		  MCPRepositoryPackageInfo fromPackage: each ]
]

{ #category : 'accessing' }
MCPRepositoryVerifyIdentityResult >> repositoryInfo [

	^ repositoryInfo
]
