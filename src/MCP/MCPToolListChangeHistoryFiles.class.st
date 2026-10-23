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
MCPToolListChangeHistoryFiles >> annotations [

	^ MCPStructureToolAnnotations readOnly
]

{ #category : 'metadata' }
MCPToolListChangeHistoryFiles >> buildInputSchema [

	| offsetProperty |
	offsetProperty := self integerSchemaPropertyNamed: 'offset' description: 'Pagination offset.' default: 0.
	offsetProperty minimum: 0.
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (self
					   schemaPropertyNamed: 'directoryPath'
					   type: 'string'
					   description: 'Optional .ombu directory. Default: current image history directory.').
				  offsetProperty };
		  required: #(  );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - execution' }
MCPToolListChangeHistoryFiles >> commandForRequest: changeHistoryRequest [

	^ MCPListChangeHistoryLogsCommand tool: self request: changeHistoryRequest
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
