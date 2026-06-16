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

	| dataProperties entriesProperty |
	entriesProperty := self
		                   changeHistoryEntryArraySchemaNamed: 'entries'
		                   description:
		                   'Change history entries returned by tool.'.
	dataProperties := {
		                  (self
			                   schemaPropertyNamed: 'action'
			                   type: 'string'
			                   description:
			                   'The change history action produced result.').
		                  (self
			                   schemaPropertyNamed: 'historyFilePath'
			                   type: 'string'
			                   description: 'The history file inspected.').
		                  entriesProperty.
		                  (self
			                   integerSchemaPropertyNamed: 'totalCount'
			                   description:
			                   'Total matching entry count before pagination.').
		                  (self
			                   integerSchemaPropertyNamed: 'returnedCount'
			                   description:
			                   'Number of entries returned in this response.').
		                  (self
			                   integerSchemaPropertyNamed: 'omittedCount'
			                   description:
			                   'Number of matching entries omitted from this response.').
		                  (self
			                   integerSchemaPropertyNamed: 'limit'
			                   description: 'Pagination limit used by tool.').
		                  (self
			                   integerSchemaPropertyNamed: 'offset'
			                   description: 'Pagination offset used by tool.').
		                  (self
			                   booleanSchemaPropertyNamed: 'hasMore'
			                   description:
			                   'Whether another page is available after this response.').
		                  (self
			                   booleanSchemaPropertyNamed: 'newestFirst'
			                   description:
			                   'Whether entries ordered newest first.').
		                  (self
			                   booleanSchemaPropertyNamed: 'codeChangesOnly'
			                   description:
			                   'Whether entries filtered code changes.').
		                  (self
			                   schemaPropertyNamed: 'headReference'
			                   type: 'string'
			                   description:
			                   'The history log head reference when known.') }.
	^ self
		  standardOutputSchemaForDataProperties: dataProperties
		  required:
			  #( 'action' 'historyFilePath' 'entries' 'totalCount' 'returnedCount'
			     'omittedCount' 'limit' 'offset' 'hasMore' 'newestFirst'
			     'codeChangesOnly' )
]

{ #category : 'defaults' }
MCPToolListChangeHistoryEntries >> defaultTitle [

	^ 'List Change History Entries'
]

{ #category : 'private - request' }
MCPToolListChangeHistoryEntries >> parsedRequestFromToolRequest: request [

	^ MCPChangeHistoryListEntriesRequest fromRequest: request tool: self
]
