Class {
	#name : 'MCPToolRevertChangeHistoryEntries',
	#superclass : 'MCPToolChangeHistorySelectionOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolRevertChangeHistoryEntries class >> toolName [

	^ 'history_entry_revert'
]

{ #category : 'private - operations' }
MCPToolRevertChangeHistoryEntries >> changeHistoryOperationSpec [

	^ {
		  (#title -> 'Revert Change History Entries').
		  (#description
		   ->
		   'Preview or confirm reverting selected Pharo change history entries from the current image. Set confirm=true to perform the previewed changes.').
		  (#operation -> 'revertEntries') } asDictionary
]
