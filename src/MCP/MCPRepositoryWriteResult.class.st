"
Result DTO for writing repository image changes to files.

It reports the repository, package state, package names written by the operation, package names that remain modified, and the number of low-level changes considered.
"
Class {
	#name : 'MCPRepositoryWriteResult',
	#superclass : 'Object',
	#instVars : [
		'repositoryInfo',
		'packageInfos',
		'writtenPackageNames',
		'modifiedPackageNames',
		'changeCount'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPRepositoryWriteResult class >> repository: aRepository writtenPackageNames: writtenNames changeCount: anInteger [

	| repositoryInfo |
	repositoryInfo := MCPRepositoryInfo fromRepository: aRepository.
	^ self new
		  repositoryInfo: repositoryInfo;
		  packageInfos:
			  (aRepository workingCopy packages collect: [ :each |
					   MCPRepositoryPackageInfo fromPackage: each ]);
		  writtenPackageNames: writtenNames;
		  modifiedPackageNames: repositoryInfo modifiedPackageNames;
		  changeCount: anInteger;
		  yourself
]

{ #category : 'converting' }
MCPRepositoryWriteResult >> asDictionary [

	^ {
		  (#repository -> self repositoryInfo asDictionary).
		  (#packages
		   ->
		   (self packageInfos
			    collect: [ :each | each asDictionary ]
			    as: Array)).
		  (#writtenPackageNames -> self writtenPackageNames).
		  (#modifiedPackageNames -> self modifiedPackageNames).
		  (#changeCount -> self changeCount) } asDictionary
]

{ #category : 'accessing' }
MCPRepositoryWriteResult >> changeCount [

	^ changeCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
MCPRepositoryWriteResult >> changeCount: anInteger [

	changeCount := anInteger
]

{ #category : 'accessing' }
MCPRepositoryWriteResult >> modifiedPackageNames [

	^ modifiedPackageNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryWriteResult >> modifiedPackageNames: aCollection [

	modifiedPackageNames := aCollection ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryWriteResult >> packageInfos [

	^ packageInfos ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryWriteResult >> packageInfos: aCollection [

	packageInfos := aCollection ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryWriteResult >> repositoryInfo [

	^ repositoryInfo
]

{ #category : 'accessing' }
MCPRepositoryWriteResult >> repositoryInfo: aRepositoryInfo [

	repositoryInfo := aRepositoryInfo
]

{ #category : 'accessing' }
MCPRepositoryWriteResult >> writtenPackageNames [

	^ writtenPackageNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryWriteResult >> writtenPackageNames: aCollection [

	writtenPackageNames := aCollection ifNil: [ #(  ) ]
]
