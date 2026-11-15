"
Loads the packages the image has from the repository files on disk and aligns the image with the repository HEAD.
"
Class {
	#name : 'MCPReloadRepositoryCommand',
	#superclass : 'MCPRepositoryCommand',
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'executing' }
MCPReloadRepositoryCommand >> execute [

	| packageNames repository result |
	^ self
		  executeRepositoryAction: 'reload'
		  work: [
				  repository := self request repository.
				  packageNames := self sortedStringsFrom: (repository workingCopy loadedPackages collect: [ :each | each name ]).
				  self loadLoadedPackagesFromDiskIn: repository.
				  result := MCPRepositoryReloadResult repository: repository packageNames: packageNames ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText: (String streamContents: [ :stream |
							   stream << 'Reloaded repository ' << result repositoryInfo name << ' from its files, '
							   << (self headPhraseFor: repository) << '.' ])
					  data: (self tool dataForRepositoryResult: result)
					  warnings: warningMessages ]
		  failureSummary: [ :error | 'Failed to reload repository: ' , (error messageText ifNil: [ error asString ]) ]
]
