"
Concrete history_file_list tool. It lists image change-history .ombu files through MCPToolChangeHistory.
"
Class {
	#name : 'MCPToolListChangeHistoryFiles',
	#superclass : 'MCPToolChangeHistory',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
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

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (self
					   schemaPropertyNamed: 'directoryPath'
					   type: 'string'
					   description: 'Directory holding the .ombu files. Defaults to this image''s own history directory.').
				  self offsetInputProperty };
		  required: #(  );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - execution' }
MCPToolListChangeHistoryFiles >> commandForRequest: request [
	"The listing of the directory the request names, else of the one holding this image's history."

	^ MCPListChangeHistoryLogsCommand directoryPath: (request stringArgumentNamed: 'directoryPath')
]

{ #category : 'private - execution' }
MCPToolListChangeHistoryFiles >> dataFor: request [

	| data operation page |
	operation := self commandForRequest: request.
	page := MCPPaginationResult
		        fromEntries: operation execute
		        limit: self defaultPageLimit
		        offset: (request integerArgumentNamed: 'offset').
	data := Dictionary new.
	data at: #files put: (page entries
			 collect: [ :each | (MCPChangeHistoryLogInfo fromFileReference: each isCurrent: (operation isCurrentFile: each)) asDictionary ]
			 as: Array).
	page nextOffset ifNotNil: [ :offset | data at: #nextOffset put: offset ].
	^ data
]

{ #category : 'metadata' }
MCPToolListChangeHistoryFiles >> defaultPageLimit [

	^ 25
]

{ #category : 'metadata' }
MCPToolListChangeHistoryFiles >> description [

	^ 'List Pharo image change history .ombu files. Use history_entry_list to inspect entries. Use apply/revert only for recovery previews or changes.'
]

{ #category : 'private - results' }
MCPToolListChangeHistoryFiles >> entryNameKeys [
	"A row is a file."

	^ #( file )
]

{ #category : 'private - results' }
MCPToolListChangeHistoryFiles >> successSummaryForData: data [

	^ self listedSummaryForCount: (data at: #files) size noun: 'change history file' data: data
]

{ #category : 'metadata' }
MCPToolListChangeHistoryFiles >> title [

	^ 'List Change History Files'
]
