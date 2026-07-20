"
Concrete history_entry_list tool. It lists granular change-history entries from the current image or a selected .ombu file through MCPToolChangeHistory.
"
Class {
	#name : 'MCPToolListChangeHistoryEntries',
	#superclass : 'MCPToolChangeHistory',
	#category : 'MCP-Tools',
	#package : 'MCP',
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
		  properties: {
				  (self
					   schemaPropertyNamed: 'directoryPath'
					   type: 'string'
					   description: 'Optional .ombu directory.').
				  (self
					   schemaPropertyNamed: 'historyFileName'
					   type: 'string'
					   description:
						   'Optional .ombu file name from history_file_list.').
				  (self
					   integerSchemaPropertyNamed: 'limit'
					   description: 'Maximum entries.'
					   default: self defaultEntryLimit).
				  (self
					   integerSchemaPropertyNamed: 'offset'
					   description: 'Pagination offset.'
					   default: 0).
				  (self
					   booleanSchemaPropertyNamed: 'newestFirst'
					   description: 'Return newest entries first.'
					   default: false).
				  (self
					   booleanSchemaPropertyNamed: 'codeChangesOnly'
					   description: 'Include only code changes.'
					   default: false) };
		  required: #(  );
		  additionalProperties: false;
		  yourself
]

{ #category : 'metadata' }
MCPToolListChangeHistoryEntries >> buildOutputSchema [

	| entriesProperty |
	entriesProperty := self
		                   changeHistoryEntryArraySchemaNamed: 'entries'
		                   description: 'Change history entries.'.
	^ self
		  standardOutputSchemaForDataProperties: {
				  (self
					   schemaPropertyNamed: 'historyFileName'
					   type: 'string'
					   description: 'Inspected history file name.').
				  entriesProperty.
				  (self
					   integerSchemaPropertyNamed: 'nextOffset'
					   description: 'Next page offset.') }
		  required: #( 'entries' )
]

{ #category : 'private - execution' }
MCPToolListChangeHistoryEntries >> commandForRequest: changeHistoryRequest [

	^ MCPListChangeHistoryEntriesCommand
		  tool: self
		  request: changeHistoryRequest
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
