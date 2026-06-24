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

{ #category : 'metadata' }
MCPToolListChangeHistoryFiles class >> toolName [

	^ 'history_file_list'
]

{ #category : 'metadata' }
MCPToolListChangeHistoryFiles >> buildInputSchema [

	| limitProperty offsetProperty |
	limitProperty := self
		                 integerSchemaPropertyNamed: 'limit'
		                 description: 'Maximum files.'
		                 default: self defaultFileLimit.
	limitProperty
		minimum: 0;
		maximum: self maximumFileLimit.
	offsetProperty := self
		                  integerSchemaPropertyNamed: 'offset'
		                  description: 'Pagination offset.'
		                  default: 0.
	offsetProperty minimum: 0.
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (self
					   schemaPropertyNamed: 'directoryPath'
					   type: 'string'
					   description:
						   'Optional .ombu directory. Default: current image history directory.').
				  limitProperty.
				  offsetProperty };
		  required: #(  );
		  additionalProperties: false;
		  yourself
]

{ #category : 'metadata' }
MCPToolListChangeHistoryFiles >> buildOutputSchema [

	| filesProperty |
	filesProperty := self
		                 schemaPropertyNamed: 'files'
		                 type: 'array'
		                 description: 'Change history files.'.
	filesProperty items: self changeHistoryLogSchemaProperty.
	^ self
		  standardOutputSchemaForDataProperties: { filesProperty }
		  required: #( 'files' )
]

{ #category : 'private - execution' }
MCPToolListChangeHistoryFiles >> commandForRequest: changeHistoryRequest [

	^ MCPListChangeHistoryLogsCommand
		  tool: self
		  request: changeHistoryRequest
]

{ #category : 'defaults' }
MCPToolListChangeHistoryFiles >> defaultFileLimit [

	^ 25
]

{ #category : 'metadata' }
MCPToolListChangeHistoryFiles >> description [

	^ 'List Pharo image change history .ombu files. Use history_entry_list to inspect entries. Use apply/revert only for recovery previews or changes.'
]

{ #category : 'defaults' }
MCPToolListChangeHistoryFiles >> maximumFileLimit [

	^ 100
]

{ #category : 'private - request' }
MCPToolListChangeHistoryFiles >> parsedRequestFromToolRequest: request [

	^ MCPChangeHistoryListLogsRequest fromRequest: request tool: self
]

{ #category : 'metadata' }
MCPToolListChangeHistoryFiles >> title [

	^ 'List Change History Files'
]
