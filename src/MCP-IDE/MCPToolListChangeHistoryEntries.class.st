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
						   schemaPropertyNamed: 'class'
						   type: 'string'
						   description: 'List only the entries that change this class or its methods, named exactly, as Foo or Foo class.').
					  (self targetSideSchemaPropertyDescribedAs: 'Which side of the class, or of the selector''s classes, the entries change.').
					  (self
						   schemaPropertyNamed: 'selector'
						   type: 'string'
						   description:
							   'List only the entries that change methods of this selector, named exactly, or of one method written as Class>>selector.').
					  (self integerSchemaPropertyNamed: 'startIndex' description: 'List from this one-based index.').
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

{ #category : 'private - entries' }
MCPToolListChangeHistoryEntries >> changeFilterFor: request [
	"A block telling whether an event changes what class, side and selector name, read as method_get reads them: a selector written as Class>>selector names its class and side, and a class written as Foo class names its side."

	| selector |
	selector := request stringArgumentNamed: 'selector'.
	^ (MCPMethodReference fromString: selector)
		  ifNil: [
				  MCPImageLookup
					  className: (request stringArgumentNamed: 'class')
					  side: (request stringArgumentNamed: 'side')
					  do: [ :className :isClassSide :isSideGiven |
					  self changeFilterForClassNamed: className side: isClassSide selector: selector ] ]
		  ifNotNil: [ :reference |
		  self changeFilterForClassNamed: reference className side: reference classSide selector: reference selector ]
]

{ #category : 'private - entries' }
MCPToolListChangeHistoryEntries >> changeFilterForClassNamed: aClassNameOrNil side: isClassSide selector: aSelectorOrNil [
	"The side narrows a class or a selector; with neither, every event is listed."

	(aClassNameOrNil isNil and: [ aSelectorOrNil isNil ]) ifTrue: [ ^ [ :event | true ] ].
	^ [ :event |
	  (MCPChangeHistoryEntryInfo fromEvent: event) changesClassNamed: aClassNameOrNil side: isClassSide selector: aSelectorOrNil ]
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

	^ 'List granular entries from the current Pharo image change history or a selected .ombu file, all of them or those that change one class or method. Use history_file_list to locate files, and history_entry_apply or history_entry_revert, which take the indexes listed here, only to recover changes.'
]

{ #category : 'private - entries' }
MCPToolListChangeHistoryEntries >> entryPairsFrom: aLog for: request [
	"The entries of aLog the request lists, as pairs of their one-based index and the entry, the oldest first unless newestFirst. startIndex and endIndex keep a range of indexes, and class, side and selector the entries that change what they name."

	| codeChangesOnly endIndex isListed pairs startIndex |
	codeChangesOnly := request booleanArgumentNamed: 'codeChangesOnly'.
	startIndex := (request integerArgumentNamed: 'startIndex') ifNil: [ 1 ].
	endIndex := (request integerArgumentNamed: 'endIndex') ifNil: [ SmallInteger maxVal ].
	isListed := self changeFilterFor: request.
	pairs := OrderedCollection new.
	aLog entries doWithIndex: [ :entry :index |
			((index between: startIndex and: endIndex) and: [
				 (codeChangesOnly not or: [ entry content isCodeChange ]) and: [ isListed value: entry content ] ]) ifTrue: [
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
