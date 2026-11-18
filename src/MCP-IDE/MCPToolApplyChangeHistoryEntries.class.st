"
Concrete history_entry_apply tool. It previews or confirms applying selected Pharo change-history entries through MCPToolChangeHistoryOperation.
"
Class {
	#name : 'MCPToolApplyChangeHistoryEntries',
	#superclass : 'MCPToolChangeHistoryOperation',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
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
		   'Preview or confirm applying selected Pharo change history entries to the current image. Applying an entry makes its change again: applying a method removal removes the method. The answer shows the source of each method it changes, before and after. Set confirm=true to perform the previewed changes.').
		  (#action -> 'apply').
		  (#unchangedReason -> 'already applied in the image') } asDictionary
]

{ #category : 'private - actions' }
MCPToolApplyChangeHistoryEntries >> reverts [

	^ false
]
