"
Shared implementation for change-history tools.

The public API talks about change history rather than Epicea or Ombu; the implementation uses Epicea logs and .ombu files behind the scenes.
"
Class {
	#name : 'MCPToolChangeHistory',
	#superclass : 'MCPTool',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
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

{ #category : 'private - execution' }
MCPToolChangeHistory >> commandForRequest: changeHistoryRequest [

	changeHistoryRequest operation = 'listFiles' ifTrue: [
		^ MCPListChangeHistoryLogsCommand tool: self request: changeHistoryRequest ].
	changeHistoryRequest operation = 'listEntries' ifTrue: [
		^ MCPListChangeHistoryEntriesCommand tool: self request: changeHistoryRequest ].
	(#( 'applyEntries' 'revertEntries' ) includes: changeHistoryRequest operation) ifTrue: [
		^ MCPChangeHistorySelectionCommand tool: self request: changeHistoryRequest ].
	MCPCommandError
		signalErrorCode: #UnsupportedChangeHistoryAction
		message: 'Unsupported change history action: ' , changeHistoryRequest operation
		details: {
				(#action -> changeHistoryRequest operation).
				(#supportedActions -> #( 'listFiles' 'listEntries' 'applyEntries' 'revertEntries' )) } asDictionary
]

{ #category : 'executing' }
MCPToolChangeHistory >> executeWithRequest: request [

	^ self
		  executeParsedRequestFrom: request
		  do: [ :changeHistoryRequest |
				  | data result |
				  result := (self commandForRequest: changeHistoryRequest) execute.
				  data := result asDictionary.
				  self successResultText: (self successSummaryForData: data operation: changeHistoryRequest operation) data: data ]
		  onError: [ :error :ignored |
				  error
					  mcpCommandErrorDo: [ :commandError |
					  self errorResultText: commandError messageText details: commandError structuredDetails ]
					  otherwise: [ :toolError | self errorResultFor: toolError ] ]
]

{ #category : 'private - schema' }
MCPToolChangeHistory >> historyLocationInputProperties [
	"Which .ombu file the entries come from. One definition, shared by every change-history tool."

	^ {
		  (self
			   schemaPropertyNamed: 'directoryPath'
			   type: 'string'
			   description: 'Directory holding the .ombu files. Defaults to this image''s own history directory.').
		  (self
			   schemaPropertyNamed: 'historyFile'
			   type: 'string'
			   description: 'One .ombu file in that directory, named as history_file_list prints it. Defaults to the session in progress.') }
]

{ #category : 'private - schema' }
MCPToolChangeHistory >> integerArraySchemaNamed: aName description: aDescription itemDescription: anItemDescription [

	| itemsProperty |
	itemsProperty := MCPStructureProperties new
		                 type: 'integer';
		                 description: anItemDescription;
		                 yourself.
	^ (self schemaPropertyNamed: aName type: 'array' description: aDescription)
		  items: itemsProperty;
		  yourself
]

{ #category : 'private - results' }
MCPToolChangeHistory >> keysStatedInSummary [
	"The summary already says how many entries, and the offset the next page starts at."

	^ #( nextOffset )
]

{ #category : 'private - results' }
MCPToolChangeHistory >> redundantKeys [
	"An entry's summary prints its event class around its behavior and selector, which the entry already names."

	^ #( summary )
]

{ #category : 'private - results' }
MCPToolChangeHistory >> successSummaryForData: data operation: operation [

	| action selectedCount performedCount previewCount |
	operation = 'listFiles' ifTrue: [
		^ 'Listed ' , (self textForCount: (data at: #files ifAbsent: [ #(  ) ]) size noun: 'change history file') , '.' ].
	operation = 'listEntries' ifTrue: [
			^ String streamContents: [ :stream |
					  stream
						  nextPutAll: 'Listed ';
						  nextPutAll: (self
								   textForCount: (data at: #entries ifAbsent: [ #(  ) ]) size
								   noun: 'change history entry').
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
						^ 'Performed ' , action , ' for ' , (self textForCount: performedCount noun: 'previewed change') , ' from '
						  , (self textForCount: selectedCount noun: 'selected history entry') , '.' ]
				ifFalse: [
						previewCount := data at: #previewCount ifAbsent: [ 0 ].
						^ 'Previewed ' , action , ' for ' , (self textForCount: previewCount noun: 'applicable change') , ' from '
						  , (self textForCount: selectedCount noun: 'selected history entry') , '.' ] ].
	^ 'Change history operation completed.'
]
