"
Concrete repository_reload tool. It loads the packages this image has from the files on disk, which is what an image needs after the checkout moved underneath it.
"
Class {
	#name : 'MCPToolReloadRepository',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
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

{ #category : 'private - specs' }
MCPToolReloadRepository >> repositoryToolSpec [

	^ {
		  (#title -> 'Reload Repository').
		  (#description
		   -> 'Load the packages this image has from the repository files on disk, replacing image-side changes, and align the image with the repository HEAD. Use after switching branch, pulling or any other checkout change made outside the image.').
		  (#action -> 'reload').
		  (#requestClass -> MCPRepositoryReloadRequest).
		  (#commandClass -> MCPReloadRepositoryCommand) } asDictionary
]
