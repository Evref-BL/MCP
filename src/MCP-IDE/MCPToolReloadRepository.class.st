"
Concrete repository_reload tool. It loads the packages this image has from the files on disk, which is what an image needs after the checkout moved underneath it. When the image has none of the packages the repository registers, it loads nothing and says so, and says which of them the checkout holds.
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
	"Reload loads only the packages the image has. When the image has none of those the repository registers, it loaded nothing: say so, and say of each registered package whether the checkout holds it."

	| inCheckout registeredNames steps |
	packageNames ifNotEmpty: [
			^ String streamContents: [ :stream |
				  stream << 'Reloaded repository ' << aRepository name << ' from its files, ' << (self headPhraseFor: aRepository) << '.' ] ].
	steps := MCPRepositoryCommand new.
	registeredNames := steps sortedStringsFrom: (self packageNamesRegisteredIn: aRepository).
	registeredNames ifEmpty: [
			^ String streamContents: [ :stream |
					  stream << 'Repository ' << aRepository name
					  <<
					  ' has no packages, so reload loaded nothing. repository_update addPackages registers them, and reload then loads those the image has.' ] ].
	inCheckout := registeredNames select: [ :each | steps checkoutOf: aRepository holdsPackageNamed: each ].
	^ String streamContents: [ :stream |
			  stream << 'None of the packages repository ' << aRepository name
			  << ' registers is in the image, so reload loaded nothing: it loads only the packages the image has.'.
			  inCheckout ifNotEmpty: [
					  stream << ' ' << (', ' join: inCheckout) << (inCheckout size = 1
						   ifTrue: [ ' is' ]
						   ifFalse: [ ' are' ]) << ' in the checkout but not in the image.' ].
			  registeredNames
				  reject: [ :each | inCheckout includes: each ]
				  thenDo: [ :each | stream << ' ' << (self warningForPackageInNeitherImageNorCheckoutNamed: each) ] ]
]
