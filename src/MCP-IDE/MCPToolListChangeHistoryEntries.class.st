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
					  (self
						   integerSchemaPropertyNamed: 'startIndex'
						   description: 'List from this one-based index, as history_entry_apply and history_entry_revert take it.').
					  (self integerSchemaPropertyNamed: 'endIndex' description: 'Last one-based index to list.').
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
MCPToolListChangeHistoryEntries >> dataFor: request [

	| data log logAndFileName page |
	logAndFileName := self logAndFileNameFor: request.
	log := logAndFileName first.
	page := MCPPaginationResult
		        fromEntries: (self entryPairsFrom: log for: request)
		        limit: self defaultPageLimit
		        offset: (request integerArgumentNamed: 'offset').
	data := Dictionary new.
	logAndFileName second ifNotNil: [ :fileName | data at: #historyFile put: fileName ].
	data at: #entries put: (page entries
			 collect: [ :pair | (MCPChangeHistoryEntryInfo fromEntry: pair second index: pair first log: log) asDictionary ]
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

{ #category : 'private - entries' }
MCPToolListChangeHistoryEntries >> entryPairsFrom: aLog for: request [
	"The entries of aLog the request lists, as pairs of their one-based index and the entry, the oldest first unless newestFirst. startIndex and endIndex keep the range of indexes the other history tools take."

	| codeChangesOnly endIndex pairs startIndex |
	codeChangesOnly := request booleanArgumentNamed: 'codeChangesOnly'.
	startIndex := (request integerArgumentNamed: 'startIndex') ifNil: [ 1 ].
	endIndex := (request integerArgumentNamed: 'endIndex') ifNil: [ SmallInteger maxVal ].
	pairs := OrderedCollection new.
	aLog entries doWithIndex: [ :entry :index |
			((index between: startIndex and: endIndex) and: [ codeChangesOnly not or: [ entry content isCodeChange ] ]) ifTrue: [
					pairs add: {
							index.
							entry } ] ].
	(request booleanArgumentNamed: 'newestFirst') ifTrue: [ ^ pairs reversed asOrderedCollection ].
	^ pairs
]

{ #category : 'private - results' }
MCPToolListChangeHistoryEntries >> successSummaryForData: data [

	^ self listedSummaryForCount: (data at: #entries) size noun: 'change history entry' data: data
]

{ #category : 'metadata' }
MCPToolListChangeHistoryEntries >> title [

	^ 'List Change History Entries'
]
