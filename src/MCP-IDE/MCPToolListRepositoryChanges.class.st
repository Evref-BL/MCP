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

{ #category : 'private - specs' }
MCPToolListRepositoryChanges >> repositoryToolSpec [

	^ {
		  (#title -> 'List Repository Changes').
		  (#description
		   ->
		   'List what a registered repository has changed, on both sides and without writing anything: the packages the image has changed since they were last written to the checkout, which is what an export would write, and the files git sees changed in the checkout.').
		  (#action -> 'diff').
		  (#requestClass -> MCPRepositoryDiffRequest).
		  (#commandClass -> MCPRepositoryDiffCommand) } asDictionary
]
