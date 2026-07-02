"
MCP tool for discarding all current changes from one registered Iceberg repository working copy.
"
Class {
	#name : 'MCPToolDiscardRepositoryChanges',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolDiscardRepositoryChanges class >> toolName [

	^ 'repository_change_discard'
]

{ #category : 'private - specs' }
MCPToolDiscardRepositoryChanges >> repositoryToolSpec [

	^ {
		  (#title -> 'Discard Repository Changes').
		  (#description
		   ->
		   'Discard all current changes in one registered Iceberg repository working copy. Use only when abandoning local changes.').
		  (#action -> 'discard').
		  (#requestClass -> MCPRepositoryDiscardRequest).
		  (#commandClass -> MCPDiscardRepositoryChangesCommand) } asDictionary
]
