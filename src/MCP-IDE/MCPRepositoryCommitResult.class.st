"
Result DTO returned by repository_commit. It names what the commit at HEAD holds, as git show lists its files: the registered packages those files belong to, and the files that belong to none, such as .project or a file written by hand.
"
Class {
	#name : 'MCPRepositoryCommitResult',
	#superclass : 'MCPRepositorySnapshotResult',
	#instVars : [
		'packageNames',
		'otherFiles'
	],
	#category : 'MCP-IDE-Results',
	#package : 'MCP-IDE',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPRepositoryCommitResult class >> repository: aRepository [

	^ self new
		  initializeSnapshotFromRepository: aRepository;
		  yourself
]

{ #category : 'converting' }
MCPRepositoryCommitResult >> asDictionary [

	| data |
	data := Dictionary new.
	self packageNames ifNotEmpty: [ :names | data at: #packages put: names ].
	self otherFiles ifNotEmpty: [ :paths | data at: #otherFiles put: paths ].
	^ data
]

{ #category : 'accessing' }
MCPRepositoryCommitResult >> otherFiles [

	^ otherFiles ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryCommitResult >> otherFiles: aCollection [

	otherFiles := aCollection asArray
]

{ #category : 'accessing' }
MCPRepositoryCommitResult >> packageNames [

	^ packageNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryCommitResult >> packageNames: aCollection [

	packageNames := aCollection asArray
]
