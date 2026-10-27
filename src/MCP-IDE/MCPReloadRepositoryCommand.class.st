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

	| beforeInfo repository result |
	^ self
		  executeRepositoryAction: 'reload'
		  work: [
				  repository := self request repository.
				  beforeInfo := MCPRepositoryInfo fromRepository: repository.
				  self loadLoadedPackagesFromDiskIn: repository.
				  result := MCPRepositoryReloadResult repositoryBefore: beforeInfo after: repository ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText: 'Reloaded repository ' , result repositoryInfo name , ' from its files.'
					  data: (self tool dataForRepositoryResult: result)
					  warnings: warningMessages ]
		  failureSummary: [ :error | 'Failed to reload repository: ' , (error messageText ifNil: [ error asString ]) ]
]
