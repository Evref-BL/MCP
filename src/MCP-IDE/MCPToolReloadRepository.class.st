"
Concrete repository_reload tool. It loads the packages this image has from the files on disk, which is what an image needs after the checkout moved underneath it. When the image has none of the packages the repository registers, it loads nothing and says so, naming them.
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
					  successResultText: (self summaryForReloadOf: repository packageNames: packageNames)
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

{ #category : 'private - results' }
MCPToolReloadRepository >> summaryForReloadOf: aRepository packageNames: packageNames [
	"Reload reloads only the packages the image has. When the image has none of those the repository registers, it loaded nothing: say so, and name what the repository registers."

	| registeredNames |
	packageNames ifNotEmpty: [
			^ String streamContents: [ :stream |
				  stream << 'Reloaded repository ' << aRepository name << ' from its files, ' << (self headPhraseFor: aRepository) << '.' ] ].
	registeredNames := MCPRepositoryCommand new sortedStringsFrom: aRepository workingCopy packageNames.
	^ String streamContents: [ :stream |
			  registeredNames
				  ifEmpty: [
						  stream << 'Repository ' << aRepository name
						  << ' has no packages, so reload loaded nothing. Add them with repository_update addPackages.' ]
				  ifNotEmpty: [
						  stream << 'None of the packages repository ' << aRepository name << ' registers is in the image: '
						  << (', ' join: registeredNames)
						  <<
						  '. Reload reloads only the packages the image has, so it loaded nothing; it does not load a package only the checkout holds.' ] ]
]
