"
Shared implementation for focused change-history tools. The public API talks about change history rather than Epicea or Ombu; the implementation uses Epicea logs and .ombu files behind the scenes.
"
Class {
	#name : 'MCPToolManageChangeHistory',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolManageChangeHistory class >> isAbstract [

	^ self = MCPToolManageChangeHistory
]

{ #category : 'private - schema' }
MCPToolManageChangeHistory >> changeHistoryEntryArraySchemaNamed: propertyName description: propertyDescription [

	| property |
	property := self
		            schemaPropertyNamed: propertyName
		            type: 'array'
		            description: propertyDescription.
	property items: self changeHistoryEntrySchemaProperty.
	^ property
]

{ #category : 'private - schema' }
MCPToolManageChangeHistory >> changeHistoryEntrySchemaProperty [

	^ MCPStructureProperties new
		  type: 'object';
		  description: 'Structured metadata for one change history entry.';
		  properties: {
				  (self
					   integerSchemaPropertyNamed: 'index'
					   description:
						   'The one-based entry index in the source history log.').
				  (self
					   schemaPropertyNamed: 'reference'
					   type: 'string'
					   description:
						   'A short entry reference accepted by entryReferences.').
				  (self
					   schemaPropertyNamed: 'globalName'
					   type: 'string'
					   description: 'The global entry reference name when available.').
				  (self
					   schemaPropertyNamed: 'localName'
					   type: 'string'
					   description: 'The local entry reference name when available.').
				  (self
					   schemaPropertyNamed: 'eventClassName'
					   type: 'string'
					   description: 'The Epicea event class name.').
				  (self
					   schemaPropertyNamed: 'summary'
					   type: 'string'
					   description: 'A printable event summary.').
				  (self
					   booleanSchemaPropertyNamed: 'isCodeChange'
					   description: 'Whether the entry represents a code change.').
				  (self
					   schemaPropertyNamed: 'time'
					   type: 'string'
					   description: 'The entry timestamp when available.').
				  (self
					   schemaPropertyNamed: 'triggerReference'
					   type: 'string'
					   description: 'The triggerer entry reference when available.').
				  (self
					   schemaPropertyNamed: 'packageName'
					   type: 'string'
					   description: 'The affected package name when available.').
				  (self
					   schemaPropertyNamed: 'behaviorName'
					   type: 'string'
					   description:
						   'The affected behavior or class name when available.').
				  (self
					   booleanSchemaPropertyNamed: 'classSide'
					   description:
						   'Whether the affected behavior is class-side when known.').
				  (self
					   schemaPropertyNamed: 'selector'
					   type: 'string'
					   description: 'The affected selector when available.').
				  (self
					   schemaPropertyNamed: 'protocol'
					   type: 'string'
					   description: 'The affected method protocol when available.') };
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - schema' }
MCPToolManageChangeHistory >> changeHistoryLogSchemaProperty [

	^ MCPStructureProperties new
		  type: 'object';
		  description: 'Structured metadata for one change history file.';
		  properties: {
				  (self
					   schemaPropertyNamed: 'path'
					   type: 'string'
					   description: 'The absolute file path.').
				  (self
					   schemaPropertyNamed: 'fileName'
					   type: 'string'
					   description: 'The history file basename.').
				  (self
					   schemaPropertyNamed: 'storeName'
					   type: 'string'
					   description: 'The Epicea store name, currently the file name.').
				  (self
					   booleanSchemaPropertyNamed: 'exists'
					   description: 'Whether the file exists.').
				  (self
					   integerSchemaPropertyNamed: 'fileSize'
					   description: 'The file size in bytes when known.').
				  (self
					   schemaPropertyNamed: 'modificationTime'
					   type: 'string'
					   description: 'The file modification time when known.').
				  (self
					   integerSchemaPropertyNamed: 'entriesCount'
					   description:
						   'The number of history entries when includeEntryCounts=true and the file can be loaded.').
				  (self
					   schemaPropertyNamed: 'headReference'
					   type: 'string'
					   description:
						   'The head entry reference when includeEntryCounts=true and the file can be loaded.').
				  (self
					   booleanSchemaPropertyNamed: 'isCurrent'
					   description:
						   'Whether this file is the current image change history file.').
				  (self
					   schemaPropertyNamed: 'loadError'
					   type: 'string'
					   description:
						   'The load error text when includeEntryCounts=true and the file cannot be loaded.') };
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - execution' }
MCPToolManageChangeHistory >> commandForRequest: changeHistoryRequest [

	changeHistoryRequest operation = 'listFiles' ifTrue: [
		^ MCPListChangeHistoryLogsCommand
			  tool: self
			  request: changeHistoryRequest ].
	changeHistoryRequest operation = 'listEntries' ifTrue: [
		^ MCPListChangeHistoryEntriesCommand
			  tool: self
			  request: changeHistoryRequest ].
	(#( 'applyEntries' 'revertEntries' ) includes:
		 changeHistoryRequest operation) ifTrue: [
		^ MCPChangeHistorySelectionCommand
			  tool: self
			  request: changeHistoryRequest ].
	MCPCommandError
		signalErrorCode: #UnsupportedChangeHistoryAction
		message: 'Unsupported change history action: ' , changeHistoryRequest operation
		details: {
				(#action -> changeHistoryRequest operation).
				(#supportedActions
				 -> #( 'listFiles' 'listEntries' 'applyEntries' 'revertEntries' )) }
				asDictionary

]

{ #category : 'executing' }
MCPToolManageChangeHistory >> executeWithRequest: request [

	^ self
		  executeParsedRequestFrom: request
		  do: [ :changeHistoryRequest |
			  | data result |
			  result := (self commandForRequest: changeHistoryRequest) execute.
			  data := result asDictionary.
			  self
				  successResultText: (self
						   successSummaryForData: data
						   operation: changeHistoryRequest operation)
				  data: data ]
		  onError: [ :error :ignored |
			  (error isKindOf: MCPCommandError)
				  ifTrue: [
					  self
						  errorResultText: error messageText
						  details: error structuredDetails ]
				  ifFalse: [ self errorResultFor: error ] ]
]

{ #category : 'private - schema' }
MCPToolManageChangeHistory >> integerArraySchemaNamed: aName description: aDescription itemDescription: anItemDescription [

	| itemsProperty |
	itemsProperty := MCPStructureProperties new
		                 type: 'integer';
		                 description: anItemDescription;
		                 yourself.
	^ (self
		   schemaPropertyNamed: aName
		   type: 'array'
		   description: aDescription)
		  items: itemsProperty;
		  yourself
]

{ #category : 'testing' }
MCPToolManageChangeHistory >> shouldSaveImageAfterSuccessfulExecutionForResult: aResult [

	| data structuredContent |
	(aResult isError or: [ aResult structuredContent isNil ]) ifTrue: [
		^ false ].
	structuredContent := aResult structuredContent.
	data := structuredContent at: #data ifAbsent: [ ^ false ].
	^ (data at: #performed ifAbsent: [ false ]) = true and: [
		  (data at: #performedCount ifAbsent: [ 0 ]) > 0 ]
]

{ #category : 'private - results' }
MCPToolManageChangeHistory >> successSummaryForData: data operation: operation [

	| action selectedCount performedCount previewCount |
	operation = 'listFiles' ifTrue: [
		^ 'Listed ' , (data at: #files ifAbsent: [ #(  ) ]) size asString
		  , ' change history files.' ].
	operation = 'listEntries' ifTrue: [
		^ 'Listed ' , (data at: #entries ifAbsent: [ #(  ) ]) size asString
		  , ' of ' , (data at: #totalCount ifAbsent: [ 0 ]) asString
		  , ' matching change history entries.' ].
	(#( 'applyEntries' 'revertEntries' ) includes: operation) ifTrue: [
		action := data at: #action ifAbsent: [ 'apply' ].
		selectedCount := data at: #selectedCount ifAbsent: [ 0 ].
		(data at: #performed ifAbsent: [ false ])
			ifTrue: [
				performedCount := data at: #performedCount ifAbsent: [ 0 ].
				^ 'Performed ' , action , ' for ' , performedCount asString
				  , ' previewed changes from ' , selectedCount asString
				  , ' selected history entries.' ]
			ifFalse: [
				previewCount := data at: #previewCount ifAbsent: [ 0 ].
				^ 'Previewed ' , action , ' for ' , previewCount asString
				  , ' applicable changes from ' , selectedCount asString
				  , ' selected history entries.' ] ].
	^ 'Change history operation completed.'
]
