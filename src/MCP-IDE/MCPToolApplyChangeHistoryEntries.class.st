"
Concrete history_entry_apply tool. It applies selected Pharo change-history entries through MCPToolChangeHistoryOperation.
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
		   'Apply change history entries, chosen by index, to the current image. Applying an entry makes its change again: applying a method removal removes the method. The answer shows the source of each method it changed, before and after, and says why a selected entry changed nothing. Find the indexes with history_entry_list, which filters by class and selector.').
		  (#action -> 'apply').
		  (#pastTense -> 'Applied').
		  (#unchangedReason -> 'already applied in the image') } asDictionary
]

{ #category : 'private - actions' }
MCPToolApplyChangeHistoryEntries >> reverts [

	^ false
]
