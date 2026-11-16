"
Concrete repository_reload tool. It loads the packages this image has from the files on disk, which is what an image needs after the checkout moved underneath it.
"
Class {
	#name : 'MCPToolReloadRepository',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolReloadRepository class >> toolName [

	^ 'repository_reload'
]

{ #category : 'metadata' }
MCPToolReloadRepository >> additionalKeywords [
	"The words an agent reaches for after moving the checkout from a shell."

	^ super additionalKeywords , #( 'reload' 'stale' 'checkout' 'switch' 'pull' 'branch' )
]

{ #category : 'private - results' }
MCPToolReloadRepository >> dataForPackageNames: packageNames [

	^ self dataKeepingNonEmpty: { (#packages -> packageNames asArray) }
]

{ #category : 'private - errors' }
MCPToolReloadRepository >> failureSummaryPrefixFor: request [

	^ 'Failed to reload repository: '
]

{ #category : 'private - execution' }
MCPToolReloadRepository >> mutateWith: request [
	"Load the packages the image has from the checkout's files, replacing what the image holds of them, and adopt the HEAD commit."

	| packageNames repository |
	^ self
		  executeOperationFor: request
		  work: [
				  | steps |
				  repository := self repositoryFor: request.
				  steps := MCPRepositoryCommand new.
				  packageNames := steps sortedStringsFrom: (repository workingCopy loadedPackages collect: [ :each | each name ]).
				  steps loadLoadedPackagesFromDiskIn: repository ]
		  successResult: [ :warnings |
				  self
					  successResultText: (String streamContents: [ :stream |
							   stream << 'Reloaded repository ' << repository name << ' from its files, ' << (self headPhraseFor: repository) << '.' ])
					  data: (self dataForPackageNames: packageNames)
					  warnings: warnings ]
]

{ #category : 'private - specs' }
MCPToolReloadRepository >> repositoryToolSpec [

	^ {
		  (#title -> 'Reload Repository').
		  (#description
		   ->
		   'Load the packages this image has from the repository files on disk, replacing image-side changes, and align the image with the repository HEAD. Use after switching branch, pulling or any other checkout change made outside the image.').
		  (#action -> 'reload') } asDictionary
]
