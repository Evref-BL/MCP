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

{ #category : 'defaults' }
MCPToolListChangeHistoryEntries class >> toolName [

	^ 'history_entry_list'
]

{ #category : 'private - execution' }
MCPToolListChangeHistoryEntries >> commandForRequest: changeHistoryRequest [

	^ MCPListChangeHistoryEntriesCommand
		  tool: self
		  request: changeHistoryRequest
]

{ #category : 'defaults' }
MCPToolListChangeHistoryEntries >> defaultDescription [

	^ 'List granular entries from the current Pharo image change history or a selected .ombu file. Use history_file_list to locate files, and history_entry_apply or history_entry_revert only when previewing or performing recovery changes.'
]

{ #category : 'defaults' }
MCPToolListChangeHistoryEntries >> defaultInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (self
					   schemaPropertyNamed: 'historyFilePath'
					   type: 'string'
					   description:
						   'Optional path to a .ombu change history file. Omit to inspect the current image change history.').
				  (self
					   integerSchemaPropertyNamed: 'limit'
					   description:
						   'Maximum number of entries to return. Use 0 to request counts only.'
					   default: 100).
				  (self
					   integerSchemaPropertyNamed: 'offset'
					   description:
						   'Zero-based pagination offset after filtering and ordering.'
					   default: 0).
				  (self
					   booleanSchemaPropertyNamed: 'newestFirst'
					   description:
						   'Return newest entries first instead of oldest first.'
					   default: false).
				  (self
					   booleanSchemaPropertyNamed: 'codeChangesOnly'
					   description:
						   'Include only entries that represent code changes.'
					   default: false) };
		  required: #(  );
		  additionalProperties: false;
		  yourself
]

{ #category : 'defaults' }
MCPToolListChangeHistoryEntries >> defaultOutputSchema [

	| entriesProperty |
	entriesProperty := self
		                   changeHistoryEntryArraySchemaNamed: 'entries'
		                   description:
		                   'Change history entries returned by this tool.'.
	^ self
		  standardOutputSchemaForDataProperties: {
				  (self
					   schemaPropertyNamed: 'action'
					   type: 'string'
					   description:
					   'The change history action that produced this result.').
				  (self
					   schemaPropertyNamed: 'historyFilePath'
					   type: 'string'
					   description: 'The history file inspected.').
				  entriesProperty.
				  (self
					   integerSchemaPropertyNamed: 'totalCount'
					   description: 'Total matching entry count before pagination.').
				  (self
					   integerSchemaPropertyNamed: 'limit'
					   description: 'Pagination limit used by this tool.').
				  (self
					   integerSchemaPropertyNamed: 'offset'
					   description: 'Pagination offset used by this tool.').
				  (self
					   booleanSchemaPropertyNamed: 'newestFirst'
					   description: 'Whether entries were ordered newest first.').
				  (self
					   booleanSchemaPropertyNamed: 'codeChangesOnly'
					   description: 'Whether entries were filtered to code changes.').
				  (self
					   schemaPropertyNamed: 'headReference'
					   type: 'string'
					   description: 'The history log head reference when known.') }
		  required: #( 'action' )
]

{ #category : 'defaults' }
MCPToolListChangeHistoryEntries >> defaultTitle [

	^ 'List Change History Entries'
]

{ #category : 'private - request' }
MCPToolListChangeHistoryEntries >> parsedRequestFromToolRequest: request [

	^ MCPChangeHistoryListEntriesRequest fromRequest: request tool: self
]
