"
Concrete history_entry_list tool. It lists granular change-history entries from the current image or a selected .ombu file through MCPToolChangeHistory.
"
Class {
	#name : 'MCPToolListChangeHistoryEntries',
	#superclass : 'MCPToolChangeHistory',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolListChangeHistoryEntries class >> toolName [

	^ 'history_entry_list'
]

{ #category : 'metadata' }
MCPToolListChangeHistoryEntries >> annotations [

	^ MCPStructureToolAnnotations readOnly
]

{ #category : 'metadata' }
MCPToolListChangeHistoryEntries >> buildInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: self historyLocationInputProperties , {
					  self offsetInputProperty.
					  (self booleanSchemaPropertyNamed: 'newestFirst' description: 'List the most recent entries first.' default: false).
					  (self
						   booleanSchemaPropertyNamed: 'codeChangesOnly'
						   description: 'Leave out everything that is not a class or method change.'
						   default: false) };
		  required: #(  );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - execution' }
MCPToolListChangeHistoryEntries >> commandForRequest: request [
	"The reading of the history file the request names, else of the session in progress."

	^ MCPListChangeHistoryEntriesCommand
		  directoryPath: (request stringArgumentNamed: 'directoryPath')
		  historyFile: (request stringArgumentNamed: 'historyFile')
		  codeChangesOnly: (request booleanArgumentNamed: 'codeChangesOnly')
		  newestFirst: (request booleanArgumentNamed: 'newestFirst')
]

{ #category : 'private - execution' }
MCPToolListChangeHistoryEntries >> dataFor: request [

	| data operation page |
	operation := self commandForRequest: request.
	page := MCPPaginationResult
		        fromEntries: operation execute
		        limit: self defaultPageLimit
		        offset: (request integerArgumentNamed: 'offset').
	data := Dictionary new.
	operation historyFileName ifNotNil: [ :fileName | data at: #historyFile put: fileName ].
	data at: #entries put: (page entries
			 collect: [ :pair | (MCPChangeHistoryEntryInfo fromEntry: pair second index: pair first log: operation log) asDictionary ]
			 as: Array).
	page nextOffset ifNotNil: [ :offset | data at: #nextOffset put: offset ].
	^ data
]

{ #category : 'metadata' }
MCPToolListChangeHistoryEntries >> defaultPageLimit [

	^ 25
]

{ #category : 'metadata' }
MCPToolListChangeHistoryEntries >> description [

	^ 'List granular entries from the current Pharo image change history or a selected .ombu file. Use history_file_list to locate files, and history_entry_apply or history_entry_revert only when previewing or performing recovery changes.'
]

{ #category : 'private - results' }
MCPToolListChangeHistoryEntries >> successSummaryForData: data [

	^ self listedSummaryForCount: (data at: #entries) size noun: 'change history entry' data: data
]

{ #category : 'metadata' }
MCPToolListChangeHistoryEntries >> title [

	^ 'List Change History Entries'
]
