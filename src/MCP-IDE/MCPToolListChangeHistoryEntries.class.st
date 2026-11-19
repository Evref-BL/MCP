"
Lists the changes one log records.
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

	^ MCPStructureInputSchema
		  properties: {
				  self directoryPathSchemaProperty.
				  self historyFileSchemaProperty.
				  (self
					   schemaPropertyNamed: 'class'
					   type: 'string'
					   description:
					   'List only the entries that change this class, named exactly: its definition, its comment, and its methods on either side.').
				  self offsetInputProperty.
				  (self booleanSchemaPropertyNamed: 'newestFirst' description: 'List the most recent entries first.' default: false).
				  (self
					   booleanSchemaPropertyNamed: 'codeChangesOnly'
					   description: 'Leave out everything that is not a class or method change.'
					   default: false) }
		  required: #(  )
]

{ #category : 'private - entries' }
MCPToolListChangeHistoryEntries >> changeFilterFor: request [
	"A block telling whether an event changes the class the request names, on either side. Foo class names Foo, as every class name is read; with no class, every event is listed."

	^ (request stringArgumentNamed: 'class') ifNil: [ [ :event | true ] ] ifNotNil: [ :name |
			  | className |
			  className := MCPImageLookup baseNameOf: name.
			  [ :event | (MCPChangeHistoryEntryInfo fromEvent: event) changesClassNamed: className ] ]
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

	^ 'List granular entries from the current Pharo image change history or a selected .ombu file, all of them or every change to one class. Use history_file_list to locate files, and history_entry_apply or history_entry_revert, which take the indexes listed here, only to recover changes.'
]

{ #category : 'private - entries' }
MCPToolListChangeHistoryEntries >> entryPairsFrom: aLog for: request [
	"The entries of aLog the request lists, as pairs of their one-based index and the entry, the oldest first unless newestFirst. class keeps the entries that change the class it names."

	| codeChangesOnly isListed pairs |
	codeChangesOnly := request booleanArgumentNamed: 'codeChangesOnly'.
	isListed := self changeFilterFor: request.
	pairs := OrderedCollection new.
	aLog entries doWithIndex: [ :entry :index |
			((codeChangesOnly not or: [ entry content isCodeChange ]) and: [ isListed value: entry content ]) ifTrue: [
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
