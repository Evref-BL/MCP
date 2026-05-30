Class {
	#name : 'MCPToolApplyChangeHistoryEntries',
	#superclass : 'MCPToolChangeHistorySelectionOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolApplyChangeHistoryEntries class >> toolName [

	^ 'history_entry_apply'
]

{ #category : 'private - operations' }
MCPToolApplyChangeHistoryEntries >> changeHistoryOperationSpec [

	^ {
		  (#title -> 'Apply Change History Entries').
		  (#description
		   ->
		   'Preview or confirm applying selected Pharo change history entries to the current image. Set confirm=true to perform the previewed changes.').
		  (#operation -> 'applyEntries') } asDictionary
]
