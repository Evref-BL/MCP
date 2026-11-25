"
The revert side of the change-history selection, as its spec describes it.
"
Class {
	#name : 'MCPToolRevertChangeHistoryEntries',
	#superclass : 'MCPToolChangeHistoryOperation',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolRevertChangeHistoryEntries class >> toolName [

	^ 'history_entry_revert'
]

{ #category : 'private - specs' }
MCPToolRevertChangeHistoryEntries >> changeHistoryToolSpec [

	^ {
		  (#title -> 'Revert Change History Entries').
		  (#description
		   ->
		   'Revert change history entries, chosen by index, from the current image. Reverting an entry undoes its change: reverting a method removal restores the method, and reverting an addition removes it. The answer shows the source of each method it changed, before and after, and says why a selected entry changed nothing. Find the indexes with history_entry_list, which filters by class.').
		  (#action -> 'revert').
		  (#pastTense -> 'Reverted').
		  (#unchangedReason -> 'already reverted in the image') } asDictionary
]

{ #category : 'testing' }
MCPToolRevertChangeHistoryEntries >> changesCode [

	^ true
]
