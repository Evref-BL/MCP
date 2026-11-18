"
Concrete repository_change_list tool.

It reports what the image holds that its files do not, and what the checkout holds that its last commit does not, through MCPToolRepositoryOperation without writing files.
"
Class {
	#name : 'MCPToolListRepositoryChanges',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolListRepositoryChanges class >> toolName [

	^ 'repository_change_list'
]

{ #category : 'metadata' }
MCPToolListRepositoryChanges >> additionalKeywords [

	^ super additionalKeywords , #( 'diff' 'status' 'change' 'modified' 'dirty' 'committed' 'uncommitted' 'unsaved' )
]

{ #category : 'metadata' }
MCPToolListRepositoryChanges >> annotations [

	^ MCPStructureToolAnnotations readOnly
]

{ #category : 'private - results' }
MCPToolListRepositoryChanges >> dataForImageModifiedPackages: packageNames modifiedPaths: paths [
	"The two layers apart: the packages whose contents in the image differ from the checkout's files, which is what an export would change, and the files git sees changed in the checkout."

	^ self dataKeepingNonEmpty: {
			  (#imageModifiedPackages -> packageNames).
			  (#modifiedPaths -> paths) }
]

{ #category : 'metadata' }
MCPToolListRepositoryChanges >> defaultExposure [

	^ 'static'
]

{ #category : 'private - errors' }
MCPToolListRepositoryChanges >> failureSummaryPrefixFor: request [

	^ 'Failed to list repository changes: '
]

{ #category : 'private - execution' }
MCPToolListRepositoryChanges >> mutateWith: request [
	"Compare each package Iceberg marks modified with the checkout's files and read the checkout's git status, writing nothing."

	| imageModifiedPackageNames modifiedPaths repository |
	^ self
		  executeOperationFor: request
		  work: [
				  | steps |
				  repository := self repositoryFor: request.
				  steps := MCPRepositoryWorkingCopyCommand new.
				  imageModifiedPackageNames := steps imageDifferingPackageNamesFor: repository.
				  modifiedPaths := steps modifiedPathsFromGitStatusIn: repository ]
		  successResult: [ :warnings |
				  self
					  successResultText:
					  (self summaryForChangesOf: repository imageModifiedPackages: imageModifiedPackageNames modifiedPaths: modifiedPaths)
					  data: (self dataForImageModifiedPackages: imageModifiedPackageNames modifiedPaths: modifiedPaths)
					  warnings: warnings ]
]

{ #category : 'private - specs' }
MCPToolListRepositoryChanges >> repositoryToolSpec [

	^ {
		  (#title -> 'List Repository Changes').
		  (#description
		   ->
		   'List what a registered repository has changed, on both sides and without writing anything. It names the packages whose contents in the image differ from the checkout''s files, which is what an export would change, and the files git sees changed in the checkout.').
		  (#action -> 'diff') } asDictionary
]

{ #category : 'private - results' }
MCPToolListRepositoryChanges >> summaryForChangesOf: aRepository imageModifiedPackages: packageNames modifiedPaths: paths [
	"Whether either side holds something its last commit does not, and what the image lost of the repository's packages since its last save, which neither side holds."

	^ MCPToolListLostChanges
		  summary: (String streamContents: [ :stream |
					   stream << 'Repository ' << aRepository name << ((packageNames isNotEmpty or: [ paths isNotEmpty ])
						    ifTrue: [ ' has uncommitted changes.' ]
						    ifFalse: [ ' has no uncommitted changes: the image matches its files and git sees none.' ]) ])
		  notingLostChangesToPackagesNamed: (self packageNamesRegisteredIn: aRepository)
		  classesNamed: #(  )
]
