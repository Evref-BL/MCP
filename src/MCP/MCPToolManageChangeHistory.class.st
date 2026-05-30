"
MCP tool for inspecting and later recovering code changes recorded in the image change history.

The public API intentionally talks about change history rather than Epicea or Ombu. The implementation uses Epicea logs and .ombu files behind the scenes.
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

{ #category : 'icons' }
MCPToolManageChangeHistory class >> toolIconSpec [

	^ MCPToolIconSpec named: #recoverLostChanges
]

{ #category : 'defaults' }
MCPToolManageChangeHistory class >> toolName [

	^ 'history_entry_operation'
]

{ #category : 'private - operations' }
MCPToolManageChangeHistory >> canonicalOperationNames [

	^ (self operationSpecifications collect: [ :each | each at: #name ])
		  asArray
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
	self signalUnsupportedOperation: changeHistoryRequest operation
]

{ #category : 'defaults' }
MCPToolManageChangeHistory >> defaultDescription [

	^ 'List and inspect Pharo image change history, then preview or perform applying or reverting selected history entries. Use operation=listFiles to find .ombu history files, operation=listEntries to inspect granular entries, operation=applyEntries to apply selected entries to the current image, and operation=revertEntries to revert selected entries from the current image.'
]

{ #category : 'defaults' }
MCPToolManageChangeHistory >> defaultInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  self operationSchemaProperty.
				  (self
					   booleanSchemaPropertyNamed: 'includeEntryCounts'
					   description:
						   'For operation=listFiles, whether to open each history file and count entries. Disable for a faster filesystem-only listing.'
					   default: true).
				  (self
					   schemaPropertyNamed: 'directoryPath'
					   type: 'string'
					   description:
						   'For operation=listFiles, optional directory to scan for .ombu change history files. Omit to scan the current image change history directory.').
				  (self
					   schemaPropertyNamed: 'historyFilePath'
					   type: 'string'
					   description:
						   'Optional path to a .ombu change history file. Omit to inspect or change from the current image change history.').
				  (self
					   integerSchemaPropertyNamed: 'limit'
					   description:
						   'For operation=listEntries, maximum number of entries to return. Use 0 to request counts only.'
					   default: 100).
				  (self
					   integerSchemaPropertyNamed: 'offset'
					   description:
						   'For operation=listEntries, zero-based pagination offset after filtering and ordering.'
					   default: 0).
				  (self
					   booleanSchemaPropertyNamed: 'newestFirst'
					   description:
						   'For operation=listEntries, return newest entries first instead of oldest first.'
					   default: false).
				  (self
					   booleanSchemaPropertyNamed: 'codeChangesOnly'
					   description:
						   'For operation=listEntries, operation=applyEntries, and operation=revertEntries, include or select only entries that represent code changes. The default is false for listEntries and true for applyEntries/revertEntries.').
				  (self
					   integerArraySchemaNamed: 'indexes'
					   description:
						   'For operation=applyEntries and operation=revertEntries, one-based entry indexes returned by listEntries to select.'
					   itemDescription: 'A one-based change history entry index.').
				  (self
					   stringArraySchemaNamed: 'entryReferences'
					   description:
						   'For operation=applyEntries and operation=revertEntries, entry references returned by listEntries. Short, global, and local reference strings are accepted.'
					   itemDescription: 'A change history entry reference string.').
				  (self
					   integerSchemaPropertyNamed: 'startIndex'
					   description:
						   'For operation=applyEntries and operation=revertEntries, first one-based entry index in an inclusive range. Must be provided with endIndex.').
				  (self
					   integerSchemaPropertyNamed: 'endIndex'
					   description:
						   'For operation=applyEntries and operation=revertEntries, last one-based entry index in an inclusive range. Must be provided with startIndex.').
				  (self
					   integerSchemaPropertyNamed: 'latestCount'
					   description:
						   'For operation=applyEntries and operation=revertEntries, select the latest N entries from the chosen history. When codeChangesOnly=true, selects the latest N code changes.').
				  (self
					   booleanSchemaPropertyNamed: 'confirm'
					   description:
						   'For operation=applyEntries and operation=revertEntries, false previews the selected changes and true performs the previewed changes.'
					   default: false) };
		  required: #( 'operation' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'defaults' }
MCPToolManageChangeHistory >> defaultOutputSchema [

	| filesProperty entriesProperty selectedEntriesProperty previewEntriesProperty |
	filesProperty := self
		                 schemaPropertyNamed: 'files'
		                 type: 'array'
		                 description:
		                 'Change history files returned by operation=listFiles.'.
	filesProperty items: self changeHistoryLogSchemaProperty.
	entriesProperty := self
		                   changeHistoryEntryArraySchemaNamed: 'entries'
		                   description:
		                   'Change history entries returned by operation=listEntries.'.
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
					   schemaPropertyNamed: 'operation'
					   type: 'string'
					   description:
					   'The change history operation that produced this result.').
				  (self
					   schemaPropertyNamed: 'action'
					   type: 'string'
					   description:
					   'For operation=applyEntries and operation=revertEntries, the performed or previewed action: apply or revert.').
				  (self
					   schemaPropertyNamed: 'currentLogPath'
					   type: 'string'
					   description: 'The current image change history file path.').
				  (self
					   schemaPropertyNamed: 'directoryPath'
					   type: 'string'
					   description: 'The directory scanned by operation=listFiles.').
				  filesProperty.
				  (self
					   schemaPropertyNamed: 'historyFilePath'
					   type: 'string'
					   description: 'The history file inspected or selected from.').
				  entriesProperty.
				  (self
					   integerSchemaPropertyNamed: 'totalCount'
					   description: 'Total matching entry count before pagination.').
				  (self
					   integerSchemaPropertyNamed: 'limit'
					   description: 'Pagination limit used by operation=listEntries.').
				  (self
					   integerSchemaPropertyNamed: 'offset'
					   description:
					   'Pagination offset used by operation=listEntries.').
				  (self
					   booleanSchemaPropertyNamed: 'newestFirst'
					   description:
					   'Whether operation=listEntries ordered entries newest first.').
				  (self
					   booleanSchemaPropertyNamed: 'codeChangesOnly'
					   description:
					   'Whether entries were filtered or selected to code changes.').
				  (self
					   schemaPropertyNamed: 'selectionCriteria'
					   type: 'object'
					   description:
					   'The selection criteria used by operation=applyEntries or operation=revertEntries.').
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
					   'Whether operation=applyEntries or operation=revertEntries performed the previewed changes.').
				  (self
					   integerSchemaPropertyNamed: 'performedCount'
					   description:
					   'Number of previewed current-image changes performed.').
				  (self
					   schemaPropertyNamed: 'headReference'
					   type: 'string'
					   description: 'The history log head reference when known.') }
		  required: #( 'operation' )
]

{ #category : 'defaults' }
MCPToolManageChangeHistory >> defaultTitle [

	^ 'Manage Change History'
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

{ #category : 'private - request' }
MCPToolManageChangeHistory >> operationFromRequest: request [

	| operation specification |
	operation := request stringArgumentNamed: 'operation'.
	operation ifNil: [
		MCPInvalidToolInput
			signalMissingRequiredArgumentNamed: 'operation'
			forTool: self ].
	specification := self operationSpecifications
		                 detect: [ :each | (each at: #name) = operation ]
		                 ifNone: [
		                 self signalUnsupportedOperation: operation ].
	^ specification at: #name
]

{ #category : 'private - operations' }
MCPToolManageChangeHistory >> operationNameListText [

	| operationNames |
	operationNames := self canonicalOperationNames.
	^ String streamContents: [ :stream |
		  operationNames doWithIndex: [ :each :index |
			  index > 1 ifTrue: [
				  index = operationNames size
					  ifTrue: [
						  operationNames size > 2
							  ifTrue: [ stream nextPutAll: ', or ' ]
							  ifFalse: [ stream nextPutAll: ' or ' ] ]
					  ifFalse: [ stream nextPutAll: ', ' ] ].
			  stream nextPutAll: each ] ]
]

{ #category : 'private - schema' }
MCPToolManageChangeHistory >> operationSchemaProperty [

	^ (self
		   schemaPropertyNamed: 'operation'
		   type: 'string'
		   description:
			   'Selects the change history action to execute. Supported values are '
			   , self operationNameListText , '.')
		  enum: self canonicalOperationNames;
		  yourself
]

{ #category : 'private - operations' }
MCPToolManageChangeHistory >> operationSpecificationNamed: anOperationName [

	^ self operationSpecifications
		  detect: [ :each | (each at: #name) = anOperationName ]
		  ifNone: [ self signalUnsupportedOperation: anOperationName ]
]

{ #category : 'private - operations' }
MCPToolManageChangeHistory >> operationSpecifications [

	^ {
		  {
			  (#name -> 'listFiles').
			  (#requiredProperties -> #(  )).
			  (#description
			   ->
			   'List .ombu change history files from directoryPath or the current image change history directory.') }
			  asDictionary.
		  {
			  (#name -> 'listEntries').
			  (#requiredProperties -> #(  )).
			  (#description
			   ->
			   'List granular entries from the current image change history or from historyFilePath.') }
			  asDictionary.
		  {
			  (#name -> 'applyEntries').
			  (#requiredProperties -> #(  )).
			  (#description
			   ->
			   'Preview or confirm applying selected history entries to the current image. Set confirm=true to perform the previewed changes.') }
			  asDictionary.
		  {
			  (#name -> 'revertEntries').
			  (#requiredProperties -> #(  )).
			  (#description
			   ->
			   'Preview or confirm reverting selected history entries from the current image. Set confirm=true to perform the previewed changes.') }
			  asDictionary }
]

{ #category : 'private - operations' }
MCPToolManageChangeHistory >> operationValidationErrorMessage [

	^ 'operation must be one of ' , self operationNameListText , '.'
]

{ #category : 'private - request' }
MCPToolManageChangeHistory >> parsedRequestFromToolRequest: request [

	| operation |
	operation := self operationFromRequest: request.
	self
		validateRequiredPropertiesForOperation: operation
		inRequest: request.
	operation = 'listFiles' ifTrue: [
		^ MCPChangeHistoryListLogsRequest fromRequest: request tool: self ].
	operation = 'listEntries' ifTrue: [
		^ MCPChangeHistoryListEntriesRequest fromRequest: request tool: self ].
	(#( 'applyEntries' 'revertEntries' ) includes: operation) ifTrue: [
		^ MCPChangeHistorySelectionRequest
			  fromRequest: request
			  tool: self
			  operation: operation ].
	self signalUnsupportedOperation: operation
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

{ #category : 'private - operations' }
MCPToolManageChangeHistory >> signalUnsupportedOperation: operationName [

	MCPCommandError
		signalErrorCode: #UnsupportedChangeHistoryOperation
		message: self operationValidationErrorMessage
		details: {
				(#operation -> operationName).
				(#supportedOperations -> self canonicalOperationNames) }
				asDictionary
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

{ #category : 'validating' }
MCPToolManageChangeHistory >> validateRequest: request [

	| operation |
	operation := self operationFromRequest: request.
	self
		validateRequiredPropertiesForOperation: operation
		inRequest: request
]

{ #category : 'private - request' }
MCPToolManageChangeHistory >> validateRequiredPropertiesForOperation: operation inRequest: request [

	| specification |
	specification := self operationSpecificationNamed: operation.
	(specification at: #requiredProperties ifAbsent: [ #(  ) ]) do: [
		:each |
		(request argumentNamed: each ifAbsent: [ nil ]) ifNil: [
			MCPInvalidToolInput
				signalMissingRequiredArgumentNamed: each
				forTool: self ] ]
]
