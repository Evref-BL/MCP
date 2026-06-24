"
Concrete history_entry_apply tool. It previews or confirms applying selected Pharo change-history entries through MCPToolChangeHistoryOperation.
"
Class {
	#name : 'MCPToolApplyChangeHistoryEntries',
	#superclass : 'MCPToolChangeHistoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolApplyChangeHistoryEntries class >> toolName [

	^ 'history_entry_apply'
]

{ #category : 'private - specs' }
MCPToolApplyChangeHistoryEntries >> changeHistoryToolSpec [

	^ {
		  (#title -> 'Apply Change History Entries').
		  (#description
		   ->
		   'Preview or confirm applying selected Pharo change history entries to the current image. Set confirm=true to perform the previewed changes.').
		  (#action -> 'applyEntries') } asDictionary
]
