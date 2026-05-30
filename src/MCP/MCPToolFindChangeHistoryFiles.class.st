Class {
	#name : 'MCPToolFindChangeHistoryFiles',
	#superclass : 'MCPToolManageChangeHistory',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolFindChangeHistoryFiles class >> toolName [

	^ 'find-change-history-files'
]

{ #category : 'private - execution' }
MCPToolFindChangeHistoryFiles >> commandForRequest: changeHistoryRequest [

	^ MCPListChangeHistoryLogsCommand
		  tool: self
		  request: changeHistoryRequest
]

{ #category : 'defaults' }
MCPToolFindChangeHistoryFiles >> defaultDescription [

	^ 'List Pharo image change history .ombu files. Use find-change-history-entries to inspect entries, and manage-change-history only when previewing or performing apply/revert.'
]

{ #category : 'defaults' }
MCPToolFindChangeHistoryFiles >> defaultInputSchema [

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
MCPToolFindChangeHistoryFiles >> defaultOutputSchema [

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
					   schemaPropertyNamed: 'operation'
					   type: 'string'
					   description:
					   'The change history operation that produced this result.').
				  (self
					   schemaPropertyNamed: 'currentLogPath'
					   type: 'string'
					   description: 'The current image change history file path.').
				  (self
					   schemaPropertyNamed: 'directoryPath'
					   type: 'string'
					   description: 'The directory scanned.').
				  filesProperty }
		  required: #( 'operation' )
]

{ #category : 'defaults' }
MCPToolFindChangeHistoryFiles >> defaultTitle [

	^ 'Find Change History Files'
]

{ #category : 'private - request' }
MCPToolFindChangeHistoryFiles >> parsedRequestFromToolRequest: request [

	^ MCPChangeHistoryListLogsRequest fromRequest: request tool: self
]

{ #category : 'validating' }
MCPToolFindChangeHistoryFiles >> validateRequest: request [

	^ self
]
