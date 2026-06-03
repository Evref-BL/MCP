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

{ #category : 'defaults' }
MCPToolChangeHistoryOperation >> defaultDescription [

	^ self changeHistoryToolSpec at: #description
]

{ #category : 'defaults' }
MCPToolChangeHistoryOperation >> defaultInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: self selectionInputProperties;
		  required: #(  );
		  additionalProperties: false;
		  yourself
]

{ #category : 'defaults' }
MCPToolChangeHistoryOperation >> defaultOutputSchema [

	| previewEntriesProperty selectedEntriesProperty |
	selectedEntriesProperty := self
		                           changeHistoryEntryArraySchemaNamed:
		                           'selectedEntries'
		                           description:
		                           'The selected source history entries resolved from indexes, entryReferences, range, or latestCount.'.
	previewEntriesProperty := self
		                          changeHistoryEntryArraySchemaNamed:
		                          'previewEntries'
		                          description:
		                          'The current-image code changes Epicea would perform, or did perform, for the selected entries.'.
	^ self
		  standardOutputSchemaForDataProperties: {
				  (self
					   schemaPropertyNamed: 'action'
					   type: 'string'
					   description:
					   'The performed or previewed action: apply or revert.').
				  (self
					   schemaPropertyNamed: 'historyFilePath'
					   type: 'string'
					   description: 'The history file selected from.').
				  (self
					   schemaPropertyNamed: 'selectionCriteria'
					   type: 'object'
					   description: 'The selection criteria used by this tool.').
				  selectedEntriesProperty.
				  previewEntriesProperty.
				  (self
					   integerSchemaPropertyNamed: 'selectedCount'
					   description: 'Number of selected source history entries.').
				  (self
					   integerSchemaPropertyNamed: 'selectedCodeChangeCount'
					   description:
					   'Number of selected source entries that are code changes.').
				  (self
					   integerSchemaPropertyNamed: 'skippedNonCodeChangeCount'
					   description:
					   'Number of selected source entries skipped because codeChangesOnly=true.').
				  (self
					   integerSchemaPropertyNamed: 'previewCount'
					   description: 'Number of previewed current-image changes.').
				  (self
					   booleanSchemaPropertyNamed: 'performed'
					   description:
					   'Whether this tool performed the previewed changes.').
				  (self
					   integerSchemaPropertyNamed: 'performedCount'
					   description:
					   'Number of previewed current-image changes performed.').
				  (self
					   schemaPropertyNamed: 'headReference'
					   type: 'string'
					   description: 'The history log head reference when known.') }
		  required:
			  #( 'action' 'selectionCriteria' 'selectedEntries'
			     'previewEntries' 'selectedCount' 'selectedCodeChangeCount'
			     'skippedNonCodeChangeCount' 'previewCount' 'performed'
			     'performedCount' )

]

{ #category : 'defaults' }
MCPToolChangeHistoryOperation >> defaultTitle [

	^ self changeHistoryToolSpec at: #title
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
			   schemaPropertyNamed: 'historyFilePath'
			   type: 'string'
			   description:
			   'Optional path to a .ombu change history file. Omit to use the current image change history.').
		  (self
			   integerArraySchemaNamed: 'indexes'
			   description:
			   'One-based entry indexes returned by history_entry_list to select.'
			   itemDescription: 'A one-based change history entry index.').
		  (self
			   stringArraySchemaNamed: 'entryReferences'
			   description:
			   'Entry references returned by history_entry_list. Short, global, and local reference strings are accepted.'
			   itemDescription: 'A change history entry reference string.').
		  (self
			   integerSchemaPropertyNamed: 'startIndex'
			   description:
			   'First one-based entry index in an inclusive range. Must be provided with endIndex.').
		  (self
			   integerSchemaPropertyNamed: 'endIndex'
			   description:
			   'Last one-based entry index in an inclusive range. Must be provided with startIndex.').
		  (self
			   integerSchemaPropertyNamed: 'latestCount'
			   description:
			   'Select the latest N entries from the chosen history. When codeChangesOnly=true, selects the latest N code changes.').
		  (self
			   booleanSchemaPropertyNamed: 'codeChangesOnly'
			   description:
			   'Whether to select only entries that represent code changes.'
			   default: true).
		  (self
			   booleanSchemaPropertyNamed: 'confirm'
			   description:
			   'False previews the selected changes; true performs the previewed changes.'
			   default: false) }
]
