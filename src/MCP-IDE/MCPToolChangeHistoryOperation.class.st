"
Shared implementation for change-history selection tools. It checks the selection the request names, reads the history it comes from, previews it through MCPChangeHistorySelectionCommand and carries it out when confirmed, and describes the selected and previewed entries, so apply and revert select, preview, confirm and answer alike. A subclass says whether it reverts.
"
Class {
	#name : 'MCPToolChangeHistoryOperation',
	#superclass : 'MCPToolChangeHistory',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolChangeHistoryOperation class >> isAbstract [

	^ self = MCPToolChangeHistoryOperation
]

{ #category : 'private - actions' }
MCPToolChangeHistoryOperation >> actionName [

	^ self changeHistoryToolSpec at: #action
]

{ #category : 'metadata' }
MCPToolChangeHistoryOperation >> buildInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: self selectionInputProperties;
		  required: #(  );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - results' }
MCPToolChangeHistoryOperation >> changeCountTextForData: data [
	"How many previewed changes were performed once confirmed, else how many the preview holds."

	^ (data at: #performed)
		  ifTrue: [ self textForCount: (data at: #performedCount) noun: 'previewed change' ]
		  ifFalse: [ self textForCount: (data at: #previewCount) noun: 'applicable change' ]
]

{ #category : 'private - specs' }
MCPToolChangeHistoryOperation >> changeHistoryToolSpec [

	self subclassResponsibility
]

{ #category : 'private - validation' }
MCPToolChangeHistoryOperation >> checkArguments: request [
	"A selection names entries by positive index, by a range given in order, or by a count of the latest ones, and names at least one of them."

	| endIndex indexes latestCount startIndex |
	indexes := request arrayArgumentNamed: 'indexes'.
	indexes do: [ :each |
			each > 0 ifFalse: [
					self signalInvalidSelection: 'indexes must contain only positive integers.' details: {
							(#argumentName -> 'indexes').
							(#actualValue -> each) } asDictionary ] ].
	startIndex := self positiveIntegerArgumentNamed: 'startIndex' in: request.
	endIndex := self positiveIntegerArgumentNamed: 'endIndex' in: request.
	latestCount := self positiveIntegerArgumentNamed: 'latestCount' in: request.
	(startIndex isNil and: [ endIndex isNil ]) ifFalse: [
			(startIndex isNil or: [ endIndex isNil ]) ifTrue: [
					self signalInvalidSelection: 'startIndex and endIndex must be provided together for range selection.' details: {
							(#startIndex -> startIndex).
							(#endIndex -> endIndex) } asDictionary ].
			startIndex > endIndex ifTrue: [
					self signalInvalidSelection: 'startIndex must be less than or equal to endIndex.' details: {
							(#startIndex -> startIndex).
							(#endIndex -> endIndex) } asDictionary ] ].
	(indexes isEmpty and: [ startIndex isNil and: [ latestCount isNil ] ]) ifTrue: [
			self
				signalInvalidSelection: 'Provide at least one selection criterion: indexes, startIndex/endIndex, or latestCount.'
				details: Dictionary new ]
]

{ #category : 'private - execution' }
MCPToolChangeHistoryOperation >> dataFor: request [

	| data log logAndFileName performedCount previewEntries previewLog selectedEntries selection |
	self checkArguments: request.
	logAndFileName := self logAndFileNameFor: request.
	log := logAndFileName first.
	selection := self selectionFor: request in: log.
	previewLog := selection execute.
	performedCount := (request booleanArgumentNamed: 'confirm')
		                  ifTrue: [ selection performPreviewLog: previewLog ]
		                  ifFalse: [ 0 ].
	selectedEntries := selection selectedPairs collect: [ :pair |
		                   MCPChangeHistoryEntryInfo fromEntry: pair second index: pair first log: log ].
	previewEntries := previewLog entries collectWithIndex: [ :entry :index |
		                  MCPChangeHistoryEntryInfo fromEntry: entry index: index log: previewLog ].
	data := Dictionary new.
	data at: #action put: self actionName.
	logAndFileName second ifNotNil: [ :fileName | data at: #historyFile put: fileName ].
	data at: #selectionCriteria put: (self selectionCriteriaFrom: request).
	data at: #selectedEntries put: (selectedEntries collect: [ :each | each asDictionary ] as: Array).
	data at: #previewEntries put: (previewEntries collect: [ :each | each asDictionary ] as: Array).
	data at: #selectedCount put: selectedEntries size.
	data at: #selectedCodeChangeCount put: (selectedEntries count: [ :each | each isCodeChange ]).
	data at: #skippedNonCodeChangeCount put: selection skippedNonCodeChangeCount.
	data at: #previewCount put: previewEntries size.
	data at: #performed put: (request booleanArgumentNamed: 'confirm').
	data at: #performedCount put: performedCount.
	^ data
]

{ #category : 'metadata' }
MCPToolChangeHistoryOperation >> description [

	^ self changeHistoryToolSpec at: #description
]

{ #category : 'private - results' }
MCPToolChangeHistoryOperation >> keysStatedInSummary [
	"The summary already reads 'Previewed apply for 3 applicable changes from 5 selected history entries.'"

	^ #( action performed performedCount previewCount selectedCount )
]

{ #category : 'private - validation' }
MCPToolChangeHistoryOperation >> positiveIntegerArgumentNamed: anArgumentName in: request [
	"The argument, nil when the caller left it out. The schema has checked that it is an integer; an entry index or a count must also be positive."

	^ (request integerArgumentNamed: anArgumentName) ifNotNil: [ :value |
			  value > 0 ifFalse: [
					  self signalInvalidSelection: anArgumentName , ' must be a positive integer.' details: {
							  (#argumentName -> anArgumentName).
							  (#actualValue -> value) } asDictionary ].
			  value ]
]

{ #category : 'private - execution' }
MCPToolChangeHistoryOperation >> rangeFrom: request [
	"The indexes of the range the request names, as an interval: a range that runs past the last entry fails at the first index missing, without being built in full."

	^ (request integerArgumentNamed: 'startIndex')
		  ifNil: [ #(  ) ]
		  ifNotNil: [ :startIndex | startIndex to: (request integerArgumentNamed: 'endIndex') ]
]

{ #category : 'private - results' }
MCPToolChangeHistoryOperation >> redundantKeys [
	"selectionCriteria is the request read back."

	^ super redundantKeys , #( selectionCriteria )
]

{ #category : 'private - actions' }
MCPToolChangeHistoryOperation >> reverts [
	"Whether the tool reverts the entries it selects rather than applies them."

	^ self subclassResponsibility
]

{ #category : 'private - results' }
MCPToolChangeHistoryOperation >> selectionCriteriaFrom: request [
	"The selection as the caller gave it."

	| criteria |
	criteria := Dictionary new.
	(request arrayArgumentNamed: 'indexes') ifNotEmpty: [ :values | criteria at: #indexes put: values ].
	(request integerArgumentNamed: 'startIndex') ifNotNil: [ :startIndex |
			criteria at: #startIndex put: startIndex.
			criteria at: #endIndex put: (request integerArgumentNamed: 'endIndex') ].
	(request integerArgumentNamed: 'latestCount') ifNotNil: [ :value | criteria at: #latestCount put: value ].
	criteria at: #codeChangesOnly put: (request booleanArgumentNamed: 'codeChangesOnly').
	^ criteria
]

{ #category : 'private - execution' }
MCPToolChangeHistoryOperation >> selectionFor: request in: aLog [
	"The operation that selects the entries of aLog the request names, and previews or carries out applying or reverting them."

	^ MCPChangeHistorySelectionCommand
		  revert: self reverts
		  log: aLog
		  indexes: (request arrayArgumentNamed: 'indexes')
		  range: (self rangeFrom: request)
		  latestCount: (request integerArgumentNamed: 'latestCount')
		  codeChangesOnly: (request booleanArgumentNamed: 'codeChangesOnly')
]

{ #category : 'private - schema' }
MCPToolChangeHistoryOperation >> selectionInputProperties [

	^ self historyLocationInputProperties , {
		  (self
			   integerArraySchemaNamed: 'indexes'
			   description: 'The entries to act on, by the one-based index history_entry_list prints.'
			   itemDescription: 'Entry index.').
		  (self integerSchemaPropertyNamed: 'startIndex' description: 'Act on a range of entries, starting at this one-based index.').
		  (self integerSchemaPropertyNamed: 'endIndex' description: 'Last one-based index of that range.').
		  (self
			   integerSchemaPropertyNamed: 'latestCount'
			   description: 'Act on this many of the most recent entries instead of naming them.').
		  (self
			   booleanSchemaPropertyNamed: 'codeChangesOnly'
			   description: 'Leave out everything that is not a class or method change.'
			   default: true).
		  (self
			   booleanSchemaPropertyNamed: 'confirm'
			   description: 'False lists what would happen and changes nothing; true carries it out.'
			   default: false) }
]

{ #category : 'private - validation' }
MCPToolChangeHistoryOperation >> signalInvalidSelection: aMessage details: aDictionary [

	MCPCommandError signalErrorCode: #ChangeHistoryInvalidSelection message: aMessage details: aDictionary
]

{ #category : 'private - results' }
MCPToolChangeHistoryOperation >> successSummaryForData: data [
	"'Previewed apply for 3 applicable changes from 5 selected history entries.' A confirmed call says Performed instead, and counts the previewed changes it carried out."

	| verb |
	verb := (data at: #performed)
		        ifTrue: [ 'Performed ' ]
		        ifFalse: [ 'Previewed ' ].
	^ String streamContents: [ :stream |
			  stream << verb << (data at: #action) << ' for ' << (self changeCountTextForData: data) << ' from '
			  << (self textForCount: (data at: #selectedCount) noun: 'selected history entry') << '.' ]
]

{ #category : 'metadata' }
MCPToolChangeHistoryOperation >> title [

	^ self changeHistoryToolSpec at: #title
]
