"
Previews and applies selected image change history entries using Epicea's apply preview machinery.
"
Class {
	#name : 'MCPChangeHistorySelectionCommand',
	#superclass : 'MCPChangeHistoryCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'private - selection' }
MCPChangeHistorySelectionCommand >> addIndexSelectionsTo: pairs fromLog: aLog [

	request indexes do: [ :index |
		pairs add: {
				index.
				(self entryAtIndex: index inLog: aLog) } ].
	^ pairs
]

{ #category : 'private - selection' }
MCPChangeHistorySelectionCommand >> addLatestSelectionTo: pairs fromLog: aLog [

	| allPairs selected start |
	request latestCount ifNil: [ ^ pairs ].
	allPairs := self entryPairsFromLog: aLog.
	request codeChangesOnly ifTrue: [
		allPairs := allPairs select: [ :pair |
			            self isCodeChangeEntry: pair second ] ].
	allPairs ifEmpty: [ ^ pairs ].
	start := allPairs size - request latestCount + 1 max: 1.
	selected := allPairs copyFrom: start to: allPairs size.
	pairs addAll: selected.
	^ pairs
]

{ #category : 'private - selection' }
MCPChangeHistorySelectionCommand >> addRangeSelectionTo: pairs fromLog: aLog [

	request hasRangeSelection ifFalse: [ ^ pairs ].
	request startIndex to: request endIndex do: [ :index |
		pairs add: {
				index.
				(self entryAtIndex: index inLog: aLog) } ].
	^ pairs
]

{ #category : 'private - selection' }
MCPChangeHistorySelectionCommand >> addReferenceSelectionsTo: pairs fromLog: aLog [

	request entryReferences do: [ :reference |
		pairs add: (self entryPairForReference: reference inLog: aLog) ].
	^ pairs
]

{ #category : 'execution' }
MCPChangeHistorySelectionCommand >> applyOrRevertEntries [

	| logAndPath log path rawPairs selectedPairs previewLog performedCount |
	logAndPath := self logAndPathForRequest.
	log := logAndPath first.
	path := logAndPath second.
	rawPairs := self rawSelectedEntryPairsFrom: log.
	selectedPairs := self selectedEntryPairsFromRawPairs: rawPairs.
	previewLog := self
		              previewLogForSelectedEntryPairs: selectedPairs
		              fromLog: log.
	performedCount := request confirm
		                  ifTrue: [ self performPreviewLog: previewLog ]
		                  ifFalse: [ 0 ].
	^ self
		  resultForLog: log
		  path: path
		  rawPairs: rawPairs
		  selectedPairs: selectedPairs
		  previewLog: previewLog
		  performed: request confirm
		  performedCount: performedCount
]

{ #category : 'private - entries' }
MCPChangeHistorySelectionCommand >> entryAtIndex: anIndex inLog: aLog [

	(anIndex between: 1 and: aLog entries size) ifFalse: [
		MCPCommandError
			signalErrorCode: #ChangeHistoryEntryNotFound
			message:
			'Change history entry index ' , anIndex asString
			, ' does not exist.'
			details: {
					(#index -> anIndex).
					(#entryCount -> aLog entries size) } asDictionary ].
	^ aLog entries at: anIndex
]

{ #category : 'private - result' }
MCPChangeHistorySelectionCommand >> entryInfosFromLog: aLog [

	^ aLog entries collectWithIndex: [ :entry :index |
		  MCPChangeHistoryEntryInfo fromEntry: entry index: index log: aLog ]
]

{ #category : 'private - result' }
MCPChangeHistorySelectionCommand >> entryInfosFromPairs: pairs log: aLog [

	^ pairs collect: [ :pair |
		  MCPChangeHistoryEntryInfo
			  fromEntry: pair second
			  index: pair first
			  log: aLog ]
]

{ #category : 'private - references' }
MCPChangeHistorySelectionCommand >> entryPairForReference: aReferenceString inLog: aLog [

	| normalized |
	normalized := aReferenceString asString.
	aLog entries doWithIndex: [ :entry :index |
		((self referenceCandidatesForEntry: entry inLog: aLog) includes:
			 normalized) ifTrue: [
			^ {
				  index.
				  entry } ] ].
	MCPCommandError
		signalErrorCode: #ChangeHistoryEntryNotFound
		message:
		'Change history entry reference ' , normalized , ' does not exist.'
		details: { (#entryReference -> normalized) } asDictionary
]

{ #category : 'private - entries' }
MCPChangeHistorySelectionCommand >> entryPairsFromLog: aLog [

	| pairs |
	pairs := OrderedCollection new.
	aLog entries doWithIndex: [ :entry :index |
		pairs add: {
				index.
				entry } ].
	^ pairs
]

{ #category : 'execution' }
MCPChangeHistorySelectionCommand >> execute [

	(#( 'applyEntries' 'revertEntries' ) includes: request operation)
		ifTrue: [ ^ self applyOrRevertEntries ].
	MCPCommandError
		signalErrorCode: #UnsupportedChangeHistoryOperation
		message: 'Unsupported change history selection operation.'
		details: { (#operation -> request operation) } asDictionary
]

{ #category : 'private - result' }
MCPChangeHistorySelectionCommand >> headReferenceStringForLog: aLog [

	^ self referenceStringFor: ([ aLog headReference ]
			   on: Error
			   do: [ :error | nil ])
]

{ #category : 'private - log' }
MCPChangeHistorySelectionCommand >> logAndPathForRequest [

	request historyFilePath ifNil: [ ^ self currentLogAndPath ].
	^ self logAndPathFromFilePath: request historyFilePath
]

{ #category : 'private - apply' }
MCPChangeHistorySelectionCommand >> performPreviewLog: aPreviewLog [

	| entries factory |
	entries := aPreviewLog entries.
	entries ifEmpty: [ ^ 0 ].
	factory := EpLogBrowserOperationFactory new
		           logBrowserModel:
			           (EpLogBrowserPresenter newWithLog: aPreviewLog);
		           entries: entries;
		           errorHandlerBlock: [ :error | error signal ];
		           yourself.
	request isRevertOperation
		ifTrue: [ factory revertCodeChangesInPreviewMode ]
		ifFalse: [ factory applyCodeChanges ].
	^ entries size
]

{ #category : 'private - preview' }
MCPChangeHistorySelectionCommand >> previewLogForSelectedEntryPairs: selectedPairs fromLog: aLog [

	| factory |
	selectedPairs ifEmpty: [ ^ EpLog newWithEvents: #(  ) ].
	factory := EpLogBrowserOperationFactory new
		           logBrowserModel: (EpLogBrowserPresenter newWithLog: aLog);
		           entries: (selectedPairs collect: [ :pair | pair second ]);
		           errorHandlerBlock: [ :error | error signal ];
		           yourself.
	request isRevertOperation ifTrue: [ ^ factory newRevertPreviewLog ].
	^ factory newApplyPreviewLog
]

{ #category : 'private - selection' }
MCPChangeHistorySelectionCommand >> rawSelectedEntryPairsFrom: aLog [

	| pairs |
	pairs := OrderedCollection new.
	self addIndexSelectionsTo: pairs fromLog: aLog.
	self addReferenceSelectionsTo: pairs fromLog: aLog.
	self addRangeSelectionTo: pairs fromLog: aLog.
	self addLatestSelectionTo: pairs fromLog: aLog.
	^ self uniqueSortedPairsFrom: pairs
]

{ #category : 'private - references' }
MCPChangeHistorySelectionCommand >> referenceCandidatesForEntry: anEntry inLog: aLog [

	| reference |
	reference := [ aLog referenceTo: anEntry ]
		             on: Error
		             do: [ :error | nil ].
	reference ifNil: [ ^ #(  ) ].
	^ Array streamContents: [ :stream |
			  (self referenceStringFor: reference) ifNotNil: [ :value |
				  stream nextPut: value ].
			  reference globalName ifNotNil: [ :value |
				  stream nextPut: value asString ].
			  reference localName ifNotNil: [ :value |
				  stream nextPut: value asString ] ]
]

{ #category : 'private - result' }
MCPChangeHistorySelectionCommand >> resultForLog: aLog path: path rawPairs: rawPairs selectedPairs: selectedPairs previewLog: previewLog performed: performedFlag performedCount: anInteger [

	^ MCPChangeHistorySelectionResult
		  action: request action
		  historyFilePath: path
		  selectionCriteria: request selectionCriteria
		  selectedEntries:
		  (self entryInfosFromPairs: selectedPairs log: aLog)
		  previewEntries: (self entryInfosFromLog: previewLog)
		  skippedNonCodeChangeCount: rawPairs size - selectedPairs size
		  performed: performedFlag
		  performedCount: anInteger
		  headReference: (self headReferenceStringForLog: aLog)
]

{ #category : 'private - selection' }
MCPChangeHistorySelectionCommand >> selectedEntryPairsFromRawPairs: rawPairs [

	request codeChangesOnly ifFalse: [ ^ rawPairs ].
	^ rawPairs select: [ :pair | self isCodeChangeEntry: pair second ]
]

{ #category : 'private - selection' }
MCPChangeHistorySelectionCommand >> uniqueSortedPairsFrom: pairs [

	| byIndex |
	byIndex := Dictionary new.
	pairs do: [ :pair | byIndex at: pair first ifAbsentPut: [ pair ] ].
	^ byIndex values asArray sort: [ :left :right |
		  left first < right first ]
]
