"
Concrete history_entry_list tool. It lists granular change-history entries from the current image or a selected .ombu file through MCPToolChangeHistory.
"
Class {
	#name : 'MCPToolListChangeHistoryEntries',
	#superclass : 'MCPToolChangeHistory',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolListChangeHistoryEntries class >> toolName [

	^ 'history_entry_list'
]

{ #category : 'metadata' }
MCPToolListChangeHistoryEntries >> annotations [

	^ MCPStructureToolAnnotations readOnly
]

{ #category : 'metadata' }
MCPToolListChangeHistoryEntries >> buildInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: self historyLocationInputProperties , {
					  self offsetInputProperty.
					  (self booleanSchemaPropertyNamed: 'newestFirst' description: 'List the most recent entries first.' default: false).
					  (self
						   booleanSchemaPropertyNamed: 'codeChangesOnly'
						   description: 'Leave out everything that is not a class or method change.'
						   default: false) };
		  required: #(  );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - execution' }
MCPToolListChangeHistoryEntries >> commandForRequest: changeHistoryRequest [

	^ MCPListChangeHistoryEntriesCommand tool: self request: changeHistoryRequest
]

{ #category : 'defaults' }
MCPToolListChangeHistoryEntries >> defaultEntryLimit [

	^ 25
]

{ #category : 'metadata' }
MCPToolListChangeHistoryEntries >> description [

	^ 'List granular entries from the current Pharo image change history or a selected .ombu file. Use history_file_list to locate files, and history_entry_apply or history_entry_revert only when previewing or performing recovery changes.'
]

{ #category : 'private - request' }
MCPToolListChangeHistoryEntries >> parsedRequestFromToolRequest: request [

	^ MCPChangeHistoryListEntriesRequest fromRequest: request tool: self
]

{ #category : 'metadata' }
MCPToolListChangeHistoryEntries >> title [

	^ 'List Change History Entries'
]
