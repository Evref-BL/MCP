Class {
	#name : 'MCPToolFindChangeHistoryEntries',
	#superclass : 'MCPToolManageChangeHistory',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolFindChangeHistoryEntries class >> toolName [

	^ 'history_entry_list'
]

{ #category : 'private - execution' }
MCPToolFindChangeHistoryEntries >> commandForRequest: changeHistoryRequest [

	^ MCPListChangeHistoryEntriesCommand
		  tool: self
		  request: changeHistoryRequest
]

{ #category : 'defaults' }
MCPToolFindChangeHistoryEntries >> defaultDescription [

	^ 'List granular entries from the current Pharo image change history or a selected .ombu file. Use history_file_list to locate files, and history_entry_apply or history_entry_revert only when previewing or performing recovery changes.'
]

{ #category : 'defaults' }
MCPToolFindChangeHistoryEntries >> defaultInputSchema [

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
MCPToolFindChangeHistoryEntries >> defaultOutputSchema [

	| entriesProperty |
	entriesProperty := self
		                   changeHistoryEntryArraySchemaNamed: 'entries'
		                   description:
		                   'Change history entries returned by this tool.'.
	^ self
		  standardOutputSchemaForDataProperties: {
				  (self
					   schemaPropertyNamed: 'operation'
					   type: 'string'
					   description:
					   'The change history operation that produced this result.').
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
		  required: #( 'operation' )
]

{ #category : 'defaults' }
MCPToolFindChangeHistoryEntries >> defaultTitle [

	^ 'List Change History Entries'
]

{ #category : 'private - request' }
MCPToolFindChangeHistoryEntries >> parsedRequestFromToolRequest: request [

	^ MCPChangeHistoryListEntriesRequest fromRequest: request tool: self
]

{ #category : 'validating' }
MCPToolFindChangeHistoryEntries >> validateRequest: request [

	^ self
]
