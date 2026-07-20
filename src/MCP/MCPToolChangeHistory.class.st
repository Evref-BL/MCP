"
Shared implementation for change-history tools.

The public API talks about change history rather than Epicea or Ombu; the implementation uses Epicea logs and .ombu files behind the scenes.
"
Class {
	#name : 'MCPToolChangeHistory',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolChangeHistory class >> groupName [

	^ self historyGroupName
]

{ #category : 'testing' }
MCPToolChangeHistory class >> isAbstract [

	^ self = MCPToolChangeHistory
]

{ #category : 'metadata' }
MCPToolChangeHistory >> additionalKeywords [

	^ #( 'history' 'change' 'epicea' 'ombu' 'recover' )
]

{ #category : 'private - schema' }
MCPToolChangeHistory >> changeHistoryEntryArraySchemaNamed: propertyName description: propertyDescription [

	| property |
	property := self
		            schemaPropertyNamed: propertyName
		            type: 'array'
		            description: propertyDescription.
	property items: self changeHistoryEntrySchemaProperty.
	^ property
]

{ #category : 'private - schema' }
MCPToolChangeHistory >> changeHistoryEntrySchemaProperty [

	^ MCPStructureProperties new
		  type: 'object';
		  description: 'Change history entry.';
		  properties: {
				  (self
					   integerSchemaPropertyNamed: 'index'
					   description: 'One-based entry index.').
				  (self
					   schemaPropertyNamed: 'eventClassName'
					   type: 'string'
					   description: 'Event class name.').
				  (self
					   schemaPropertyNamed: 'summary'
					   type: 'string'
					   description: 'Specific entry summary.').
				  (self
					   stringEnumSchemaPropertyNamed: 'entryKind'
					   description: 'Entry kind.'
					   values: #( 'code' 'session' 'other' )
					   default: 'code').
				  (self
					   schemaPropertyNamed: 'time'
					   type: 'string'
					   description: 'Entry time.').
				  (self
					   schemaPropertyNamed: 'triggerReference'
					   type: 'string'
					   description: 'Trigger reference.').
				  (self
					   schemaPropertyNamed: 'packageName'
					   type: 'string'
					   description: 'Package name.').
				  (self
					   schemaPropertyNamed: 'behaviorName'
					   type: 'string'
					   description: 'Class or trait name.').
				  (self
					   booleanSchemaPropertyNamed: 'classSide'
					   description: 'Whether method is class-side.').
				  (self
					   schemaPropertyNamed: 'selector'
					   type: 'string'
					   description: 'Method selector.').
				  (self
					   schemaPropertyNamed: 'protocol'
					   type: 'string'
					   description: 'Method protocol.') };
		  required: #( 'index' 'eventClassName' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - schema' }
MCPToolChangeHistory >> changeHistoryLogSchemaProperty [

	^ MCPStructureProperties new
		  type: 'object';
		  description: 'Change history file.';
		  properties: {
				  (self
					   schemaPropertyNamed: 'fileName'
					   type: 'string'
					   description: 'File name.').
				  (self
					   booleanSchemaPropertyNamed: 'exists'
					   description: 'False when listed file is missing.').
				  (self
					   integerSchemaPropertyNamed: 'fileSize'
					   description: 'File size in bytes.').
				  (self
					   schemaPropertyNamed: 'modificationTime'
					   type: 'string'
					   description: 'Modification time.').
				  (self
					   booleanSchemaPropertyNamed: 'isCurrent'
					   description: 'True for current image history file.') };
		  required: #( 'fileName' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - execution' }
MCPToolChangeHistory >> commandForRequest: changeHistoryRequest [

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
		message:
		'Unsupported change history action: '
		, changeHistoryRequest operation
		details: {
				(#action -> changeHistoryRequest operation).
				(#supportedActions
				 -> #( 'listFiles' 'listEntries' 'applyEntries' 'revertEntries' )) }
				asDictionary
]

{ #category : 'executing' }
MCPToolChangeHistory >> executeWithRequest: request [

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
				  error
					  mcpCommandErrorDo: [ :commandError |
							  self
								  errorResultText: commandError messageText
								  details: commandError structuredDetails ]
					  otherwise: [ :toolError | self errorResultFor: toolError ] ]
]

{ #category : 'private - schema' }
MCPToolChangeHistory >> integerArraySchemaNamed: aName description: aDescription itemDescription: anItemDescription [

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
MCPToolChangeHistory >> shouldSaveImageAfterSuccessfulExecutionForResult: aResult [

	| data |
	data := self
		        successfulStructuredDataFromResult: aResult
		        ifAbsent: [ ^ false ].
	^ (data at: #performed ifAbsent: [ false ]) == true and: [
		  (data at: #performedCount ifAbsent: [ 0 ]) > 0 ]
]

{ #category : 'private - results' }
MCPToolChangeHistory >> successSummaryForData: data operation: operation [

	| action selectedCount performedCount previewCount |
	operation = 'listFiles' ifTrue: [
			^ 'Listed ' , (data at: #files ifAbsent: [ #(  ) ]) size asString
			  , ' change history files.' ].
	operation = 'listEntries' ifTrue: [
			^ String streamContents: [ :stream |
					  stream
						  nextPutAll: 'Listed ';
						  print: (data at: #entries ifAbsent: [ #(  ) ]) size;
						  nextPutAll: ' change history entries'.
					  data at: #nextOffset ifPresent: [ :offset |
							  stream
								  nextPutAll: '. More available at offset ';
								  print: offset ].
					  stream nextPut: $. ] ].
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
