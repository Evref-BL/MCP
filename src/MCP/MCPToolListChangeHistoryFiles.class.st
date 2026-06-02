"
Concrete history_file_list tool. It lists image change-history .ombu files through MCPToolChangeHistory.
"
Class {
	#name : 'MCPToolListChangeHistoryFiles',
	#superclass : 'MCPToolChangeHistory',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolListChangeHistoryFiles class >> toolName [

	^ 'history_file_list'
]

{ #category : 'private - execution' }
MCPToolListChangeHistoryFiles >> commandForRequest: changeHistoryRequest [

	^ MCPListChangeHistoryLogsCommand
		  tool: self
		  request: changeHistoryRequest
]

{ #category : 'defaults' }
MCPToolListChangeHistoryFiles >> defaultDescription [

	^ 'List Pharo image change history .ombu files. Use history_entry_list to inspect entries, and history_entry_apply or history_entry_revert only when previewing or performing recovery changes.'
]

{ #category : 'defaults' }
MCPToolListChangeHistoryFiles >> defaultInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (self
					   booleanSchemaPropertyNamed: 'includeEntryCounts'
					   description:
						   'Whether to open each history file and count entries. Disable for a faster filesystem-only listing.'
					   default: true).
				  (self
					   schemaPropertyNamed: 'directoryPath'
					   type: 'string'
					   description:
						   'Optional directory to scan for .ombu change history files. Omit to scan the current image change history directory.') };
		  required: #(  );
		  additionalProperties: false;
		  yourself
]

{ #category : 'defaults' }
MCPToolListChangeHistoryFiles >> defaultOutputSchema [

	| filesProperty |
	filesProperty := self
		                 schemaPropertyNamed: 'files'
		                 type: 'array'
		                 description:
		                 'Change history files returned by this tool.'.
	filesProperty items: self changeHistoryLogSchemaProperty.
	^ self
		  standardOutputSchemaForDataProperties: {
				  (self
					   schemaPropertyNamed: 'action'
					   type: 'string'
					   description:
					   'The change history action that produced this result.').
				  (self
					   schemaPropertyNamed: 'currentLogPath'
					   type: 'string'
					   description: 'The current image change history file path.').
				  (self
					   schemaPropertyNamed: 'directoryPath'
					   type: 'string'
					   description: 'The directory scanned.').
				  filesProperty }
		  required: #( 'action' )
]

{ #category : 'defaults' }
MCPToolListChangeHistoryFiles >> defaultTitle [

	^ 'List Change History Files'
]

{ #category : 'private - request' }
MCPToolListChangeHistoryFiles >> parsedRequestFromToolRequest: request [

	^ MCPChangeHistoryListLogsRequest fromRequest: request tool: self
]

{ #category : 'validating' }
MCPToolListChangeHistoryFiles >> validateRequest: request [

	^ self
]
