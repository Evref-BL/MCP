"
Shared implementation for change-history tools.

The public API talks about change history rather than Epicea or Ombu; the implementation uses Epicea logs and .ombu files behind the scenes. A tool builds its operation from the request in commandForRequest:, describes what the operation answers with MCPChangeHistoryLogInfo and MCPChangeHistoryEntryInfo in dataFor:, and says what it found in successSummaryForData:.
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
MCPToolChangeHistory >> dataFor: request [
	"The data the answer carries, read from the image as the request asks."

	^ self subclassResponsibility
]

{ #category : 'executing' }
MCPToolChangeHistory >> executeWithRequest: request [
	"Every history tool answers the data it reads, under a sentence that says what it found."

	^ self
		  executeParsedRequestFrom: request
		  do: [ :arguments |
				  | data |
				  data := self dataFor: arguments.
				  self successResultText: (self successSummaryForData: data) data: data ]
		  onError: [ :error :arguments | self errorResultFor: error ]
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
MCPToolChangeHistory >> keyOrder [
	"index is the handle every history tool takes, so it leads, then what happened and when."

	^ #( index eventClass time )
]

{ #category : 'private - results' }
MCPToolChangeHistory >> keysStatedInSummary [
	"The summary already says how many entries, and the offset the next page starts at."

	^ #( nextOffset )
]

{ #category : 'private - results' }
MCPToolChangeHistory >> listedSummaryForCount: anInteger noun: aNoun data: data [
	"A page of files or entries says how many it holds and, when another follows, the offset it starts at: the text leaves nextOffset to this sentence."

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Listed ';
				  nextPutAll: (self textForCount: anInteger noun: aNoun);
				  nextPut: $..
			  data at: #nextOffset ifPresent: [ :offset |
					  stream
						  nextPutAll: ' Next page: offset ';
						  print: offset;
						  nextPut: $. ] ]
]

{ #category : 'private - results' }
MCPToolChangeHistory >> redundantKeys [
	"An entry's summary prints its event class around its behavior and selector, which the entry already names."

	^ #( summary )
]

{ #category : 'private - results' }
MCPToolChangeHistory >> successSummaryForData: data [
	"The sentence that says what the data holds."

	^ self subclassResponsibility
]
