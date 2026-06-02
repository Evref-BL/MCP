"
Concrete history_entry_revert tool. It previews or confirms reverting selected Pharo change-history entries through MCPToolChangeHistoryOperation.
"
Class {
	#name : 'MCPToolRevertChangeHistoryEntries',
	#superclass : 'MCPToolChangeHistoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolRevertChangeHistoryEntries class >> toolName [

	^ 'history_entry_revert'
]

{ #category : 'private - specs' }
MCPToolRevertChangeHistoryEntries >> changeHistoryToolSpec [

	^ {
		  (#title -> 'Revert Change History Entries').
		  (#description
		   ->
		   'Preview or confirm reverting selected Pharo change history entries from the current image. Set confirm=true to perform the previewed changes.').
		  (#action -> 'revertEntries') } asDictionary
]
