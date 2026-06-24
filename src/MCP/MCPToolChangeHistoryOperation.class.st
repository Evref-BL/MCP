"
Shared implementation for change-history selection tools. It keeps apply and revert entry selection, preview, confirmation, and result shaping consistent across concrete tools.
"
Class {
	#name : 'MCPToolChangeHistoryOperation',
	#superclass : 'MCPToolChangeHistory',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolChangeHistoryOperation class >> isAbstract [

	^ self = MCPToolChangeHistoryOperation
]

{ #category : 'private - actions' }
MCPToolChangeHistoryOperation >> actionName [

	^ self changeHistoryToolSpec at: #action
]

{ #category : 'private - specs' }
MCPToolChangeHistoryOperation >> changeHistoryToolSpec [

	self subclassResponsibility
]

{ #category : 'metadata' }
MCPToolChangeHistoryOperation >> description [

	^ self changeHistoryToolSpec at: #description
]

{ #category : 'metadata' }
MCPToolChangeHistoryOperation >> inputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: self selectionInputProperties;
		  required: #(  );
		  additionalProperties: false;
		  yourself
]

{ #category : 'metadata' }
MCPToolChangeHistoryOperation >> outputSchema [

	| previewEntriesProperty selectedEntriesProperty |
	selectedEntriesProperty := self
		                           changeHistoryEntryArraySchemaNamed:
		                           'selectedEntries'
		                           description: 'Selected source entries.'.
	previewEntriesProperty := self
		                          changeHistoryEntryArraySchemaNamed:
		                          'previewEntries'
		                          description:
		                          'Previewed current-image changes.'.
	^ self
		  standardOutputSchemaForDataProperties: {
				  (self
					   schemaPropertyNamed: 'action'
					   type: 'string'
					   description: 'apply or revert.').
				  (self
					   schemaPropertyNamed: 'historyFileName'
					   type: 'string'
					   description: 'Selected history file name.').
				  (self
					   schemaPropertyNamed: 'selectionCriteria'
					   type: 'object'
					   description: 'Normalized selection criteria.').
				  selectedEntriesProperty.
				  previewEntriesProperty.
				  (self
					   integerSchemaPropertyNamed: 'selectedCount'
					   description: 'Selected source entries.').
				  (self
					   integerSchemaPropertyNamed: 'selectedCodeChangeCount'
					   description: 'Selected code changes.').
				  (self
					   integerSchemaPropertyNamed: 'skippedNonCodeChangeCount'
					   description: 'Skipped non-code entries.').
				  (self
					   integerSchemaPropertyNamed: 'previewCount'
					   description: 'Previewed changes.').
				  (self
					   booleanSchemaPropertyNamed: 'performed'
					   description: 'Whether changes were performed.').
				  (self
					   integerSchemaPropertyNamed: 'performedCount'
					   description: 'Performed changes.') }
		  required:
			  #( 'action' 'selectionCriteria' 'selectedEntries'
			     'previewEntries' 'selectedCount' 'selectedCodeChangeCount'
			     'skippedNonCodeChangeCount' 'previewCount' 'performed'
			     'performedCount' )
]

{ #category : 'private - request' }
MCPToolChangeHistoryOperation >> parsedRequestFromToolRequest: request [

	^ MCPChangeHistorySelectionRequest
		  fromRequest: request
		  tool: self
		  operation: self actionName
]

{ #category : 'private - schema' }
MCPToolChangeHistoryOperation >> selectionInputProperties [

	^ {
		  (self
			   schemaPropertyNamed: 'directoryPath'
			   type: 'string'
			   description: 'Optional .ombu directory.').
		  (self
			   schemaPropertyNamed: 'historyFileName'
			   type: 'string'
			   description: 'Optional .ombu file name from history_file_list.').
		  (self
			   integerArraySchemaNamed: 'indexes'
			   description:
			   'One-based entry indexes returned by history_entry_list.'
			   itemDescription: 'Entry index.').
		  (self
			   integerSchemaPropertyNamed: 'startIndex'
			   description: 'First one-based entry index in range.').
		  (self
			   integerSchemaPropertyNamed: 'endIndex'
			   description: 'Last one-based entry index in range.').
		  (self
			   integerSchemaPropertyNamed: 'latestCount'
			   description: 'Select latest N entries.').
		  (self
			   booleanSchemaPropertyNamed: 'codeChangesOnly'
			   description: 'Select only code changes.'
			   default: true).
		  (self
			   booleanSchemaPropertyNamed: 'confirm'
			   description: 'False previews; true performs.'
			   default: false) }
]

{ #category : 'metadata' }
MCPToolChangeHistoryOperation >> title [

	^ self changeHistoryToolSpec at: #title
]
