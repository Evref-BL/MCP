"
Shared implementation for change-history selection tools. It keeps apply and revert entry selection, preview, confirmation, and result shaping consistent across concrete tools.
"
Class {
	#name : 'MCPToolChangeHistoryOperation',
	#superclass : 'MCPToolChangeHistory',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
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

{ #category : 'metadata' }
MCPToolChangeHistoryOperation >> buildInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: self selectionInputProperties;
		  required: #(  );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - specs' }
MCPToolChangeHistoryOperation >> changeHistoryToolSpec [

	self subclassResponsibility
]

{ #category : 'metadata' }
MCPToolChangeHistoryOperation >> description [

	^ self changeHistoryToolSpec at: #description
]

{ #category : 'private - results' }
MCPToolChangeHistoryOperation >> keysStatedInSummary [
	"The summary already reads 'Previewed apply for 3 applicable changes from 5 selected history entries.'"

	^ #( action performed performedCount previewCount selectedCount )
]

{ #category : 'private - request' }
MCPToolChangeHistoryOperation >> parsedRequestFromToolRequest: request [

	^ MCPChangeHistorySelectionRequest fromRequest: request tool: self operation: self actionName
]

{ #category : 'private - schema' }
MCPToolChangeHistoryOperation >> selectionInputProperties [

	^ self historyLocationInputProperties , {
		  (self
			   integerArraySchemaNamed: 'indexes'
			   description: 'The entries to act on, by the one-based index history_entry_list prints.'
			   itemDescription: 'Entry index.').
		  (self integerSchemaPropertyNamed: 'startIndex' description: 'Act on a range of entries, starting at this one-based index.').
		  (self integerSchemaPropertyNamed: 'endIndex' description: 'Last one-based index of that range.').
		  (self
			   integerSchemaPropertyNamed: 'latestCount'
			   description: 'Act on this many of the most recent entries instead of naming them.').
		  (self
			   booleanSchemaPropertyNamed: 'codeChangesOnly'
			   description: 'Leave out everything that is not a class or method change.'
			   default: true).
		  (self
			   booleanSchemaPropertyNamed: 'confirm'
			   description: 'False lists what would happen and changes nothing; true carries it out.'
			   default: false) }
]

{ #category : 'metadata' }
MCPToolChangeHistoryOperation >> title [

	^ self changeHistoryToolSpec at: #title
]
