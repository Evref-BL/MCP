"
Previews and applies selected image change history entries using Epicea's apply preview machinery.
"
Class {
	#name : 'MCPChangeHistorySelectionCommand',
	#superclass : 'Object',
	#instVars : [
		'tool',
		'request'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPChangeHistorySelectionCommand class >> tool: aTool request: aRequest [

	^ self new
		  initializeTool: aTool request: aRequest;
		  yourself
]

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

{ #category : 'private - log' }
MCPChangeHistorySelectionCommand >> currentHistoryFileReference [

	| store lowLevel |
	EpMonitor hasCurrent ifFalse: [ ^ nil ].
	EpMonitor current sessionStore flush.
	store := EpMonitor current log store.
	(store respondsTo: #writingFileReference) ifTrue: [
		^ store writingFileReference ].
	(store respondsTo: #lowLevelFileStoreIfNone:) ifFalse: [ ^ nil ].
	lowLevel := store lowLevelFileStoreIfNone: [ nil ].
	(lowLevel notNil and: [ lowLevel respondsTo: #writingFileReference ])
		ifTrue: [ ^ lowLevel writingFileReference ].
	^ nil
]

{ #category : 'private - log' }
MCPChangeHistorySelectionCommand >> currentLogAndPath [

	| log currentFile path |
	EpMonitor hasCurrent ifFalse: [
		MCPCommandError
			signalErrorCode: #ChangeHistoryUnavailable
			message: 'No current Pharo change history monitor is available.'
			details: Dictionary new ].
	EpMonitor current sessionStore flush.
	log := EpMonitor current log.
	log refresh.
	currentFile := self currentHistoryFileReference.
	path := currentFile ifNotNil: [ currentFile fullName ].
	^ {
		  log.
		  path }
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

{ #category : 'initialization' }
MCPChangeHistorySelectionCommand >> initializeTool: aTool request: aRequest [

	tool := aTool.
	request := aRequest.
	^ self
]

{ #category : 'private - entries' }
MCPChangeHistorySelectionCommand >> isCodeChangeEntry: anEntry [

	| content |
	content := [ anEntry content ]
		           on: Error
		           do: [ :error | nil ].
	^ content notNil and: [
		  (content respondsTo: #isCodeChange) and: [ content isCodeChange ] ]
]

{ #category : 'private - log' }
MCPChangeHistorySelectionCommand >> logAndPathForRequest [

	request historyFilePath ifNil: [ ^ self currentLogAndPath ].
	^ self logAndPathFromFilePath: request historyFilePath
]

{ #category : 'private - log' }
MCPChangeHistorySelectionCommand >> logAndPathFromFilePath: aPathString [

	| file log |
	file := aPathString asFileReference.
	file exists ifFalse: [
		MCPCommandError
			signalErrorCode: #ChangeHistoryFileNotFound
			message: 'Change history file ' , aPathString , ' does not exist.'
			details: { (#historyFilePath -> aPathString) } asDictionary ].
	file isFile ifFalse: [
		MCPCommandError
			signalErrorCode: #ChangeHistoryPathNotFile
			message: 'Change history path ' , aPathString , ' is not a file.'
			details: { (#historyFilePath -> aPathString) } asDictionary ].
	log := [
	       | loadedLog |
	       loadedLog := EpLog freshFromFile: file.
	       loadedLog entries size.
	       loadedLog ]
		       on: Error
		       do: [ :error |
			       MCPCommandError
				       signalErrorCode: #ChangeHistoryFileUnreadable
				       message:
				       'Change history file ' , file fullName
				       , ' could not be loaded.'
				       details: {
						       (#historyFilePath -> file fullName).
						       (#causeClass -> error class name).
						       (#causeMessage
						        -> (error messageText ifNil: [ error asString ])) }
						       asDictionary ].
	^ {
		  log.
		  file fullName }
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

	| candidates reference |
	candidates := OrderedCollection new.
	reference := [ aLog referenceTo: anEntry ]
		             on: Error
		             do: [ :error | nil ].
	reference ifNotNil: [
		(self referenceStringFor: reference) ifNotNil: [ :value |
			candidates add: value ].
		(self stringValueFrom: reference selector: #globalName) ifNotNil: [
			:value | candidates add: value ].
		(self stringValueFrom: reference selector: #localName) ifNotNil: [
			:value | candidates add: value ] ].
	^ candidates asArray
]

{ #category : 'private - references' }
MCPChangeHistorySelectionCommand >> referenceStringFor: aReference [

	aReference ifNil: [ ^ nil ].
	(aReference respondsTo: #shortName) ifTrue: [
		^ aReference shortName asString ].
	^ aReference asString
]

{ #category : 'accessing' }
MCPChangeHistorySelectionCommand >> request [

	^ request
]

{ #category : 'private - result' }
MCPChangeHistorySelectionCommand >> resultForLog: aLog path: path rawPairs: rawPairs selectedPairs: selectedPairs previewLog: previewLog performed: performedFlag performedCount: anInteger [

	^ MCPChangeHistorySelectionResult
		  operation: request operation
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

{ #category : 'private - references' }
MCPChangeHistorySelectionCommand >> stringValueFrom: anObject selector: aSelector [

	(anObject notNil and: [ anObject respondsTo: aSelector ]) ifFalse: [
		^ nil ].
	^ [
	  (anObject perform: aSelector)
		  ifNil: [ nil ]
		  ifNotNil: [ :value | value asString ] ]
		  on: Error
		  do: [ :error | nil ]
]

{ #category : 'accessing' }
MCPChangeHistorySelectionCommand >> tool [

	^ tool
]

{ #category : 'private - selection' }
MCPChangeHistorySelectionCommand >> uniqueSortedPairsFrom: pairs [

	| byIndex |
	byIndex := Dictionary new.
	pairs do: [ :pair | byIndex at: pair first ifAbsentPut: [ pair ] ].
	^ (byIndex values asSortedCollection: [ :left :right |
		   left first < right first ]) asArray
]
