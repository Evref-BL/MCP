"
Selects change history entries by index, by range and by a count of the latest ones, previews what applying or reverting them would change using Epicea's apply preview machinery, and carries it out when confirmed.

execute answers the preview log; log, historyFileName, selectedPairs, skippedNonCodeChangeCount and performedCount then say what was selected and done.
"
Class {
	#name : 'MCPChangeHistorySelectionCommand',
	#superclass : 'MCPChangeHistoryCommand',
	#instVars : [
		'revert',
		'directoryPath',
		'historyFile',
		'indexes',
		'range',
		'latestCount',
		'codeChangesOnly',
		'confirm',
		'log',
		'historyFileName',
		'selectedPairs',
		'skippedNonCodeChangeCount',
		'performedCount'
	],
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPChangeHistorySelectionCommand class >> revert: revertBoolean directoryPath: aPathString historyFile: aFileName indexes: someIndexes range: rangeIndexes latestCount: aCountOrNil codeChangesOnly: codeChangesOnlyBoolean confirm: confirmBoolean [
	"aPathString and aFileName name a .ombu file, or are nil for the session in progress. The entries are those at someIndexes and rangeIndexes, then the latest aCountOrNil of them."

	^ self new
		  revert: revertBoolean;
		  directoryPath: aPathString;
		  historyFile: aFileName;
		  indexes: someIndexes;
		  range: rangeIndexes;
		  latestCount: aCountOrNil;
		  codeChangesOnly: codeChangesOnlyBoolean;
		  confirm: confirmBoolean;
		  yourself
]

{ #category : 'private - selection' }
MCPChangeHistorySelectionCommand >> addEntriesAt: someIndexes to: pairs fromLog: aLog [

	someIndexes do: [ :index |
			pairs add: {
					index.
					(self entryAtIndex: index inLog: aLog) } ].
	^ pairs
]

{ #category : 'private - selection' }
MCPChangeHistorySelectionCommand >> addLatestSelectionTo: pairs fromLog: aLog [

	| allPairs selected start |
	latestCount ifNil: [ ^ pairs ].
	allPairs := self entryPairsFromLog: aLog.
	codeChangesOnly ifTrue: [ allPairs := allPairs select: [ :pair | self isCodeChangeEntry: pair second ] ].
	allPairs ifEmpty: [ ^ pairs ].
	start := allPairs size - latestCount + 1 max: 1.
	selected := allPairs copyFrom: start to: allPairs size.
	pairs addAll: selected.
	^ pairs
]

{ #category : 'accessing' }
MCPChangeHistorySelectionCommand >> codeChangesOnly: aBoolean [

	codeChangesOnly := aBoolean
]

{ #category : 'accessing' }
MCPChangeHistorySelectionCommand >> confirm: aBoolean [

	confirm := aBoolean
]

{ #category : 'accessing' }
MCPChangeHistorySelectionCommand >> directoryPath: aPathString [

	directoryPath := aPathString
]

{ #category : 'private - entries' }
MCPChangeHistorySelectionCommand >> entryAtIndex: anIndex inLog: aLog [

	(anIndex between: 1 and: aLog entries size) ifFalse: [
			MCPCommandError
				signalErrorCode: #ChangeHistoryEntryNotFound
				message:
				(String streamContents: [ :stream | stream << 'Change history entry index ' << anIndex asString << ' does not exist.' ])
				details: {
						(#index -> anIndex).
						(#entryCount -> aLog entries size) } asDictionary ].
	^ aLog entries at: anIndex
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
	"Select the entries, preview what applying or reverting them would change, and carry that out when confirmed. Answer the preview log."

	| logAndFileName previewLog rawPairs |
	logAndFileName := self logAndFileNameFromDirectoryPath: directoryPath fileName: historyFile.
	log := logAndFileName first.
	historyFileName := logAndFileName second.
	rawPairs := self rawSelectedEntryPairsFrom: log.
	selectedPairs := self selectedEntryPairsFromRawPairs: rawPairs.
	skippedNonCodeChangeCount := rawPairs size - selectedPairs size.
	previewLog := self previewLogForSelectedEntryPairs: selectedPairs fromLog: log.
	performedCount := confirm
		                  ifTrue: [ self performPreviewLog: previewLog ]
		                  ifFalse: [ 0 ].
	^ previewLog
]

{ #category : 'accessing' }
MCPChangeHistorySelectionCommand >> historyFile: aFileName [

	historyFile := aFileName
]

{ #category : 'accessing' }
MCPChangeHistorySelectionCommand >> historyFileName [
	"The name of the file execute selected the entries from, nil when the session in progress has none."

	^ historyFileName
]

{ #category : 'accessing' }
MCPChangeHistorySelectionCommand >> indexes: someIndexes [

	indexes := someIndexes
]

{ #category : 'accessing' }
MCPChangeHistorySelectionCommand >> latestCount: aCountOrNil [

	latestCount := aCountOrNil
]

{ #category : 'accessing' }
MCPChangeHistorySelectionCommand >> log [
	"The log execute selected the entries from."

	^ log
]

{ #category : 'private - apply' }
MCPChangeHistorySelectionCommand >> performPreviewLog: aPreviewLog [

	| entries factory |
	entries := aPreviewLog entries.
	entries ifEmpty: [ ^ 0 ].
	factory := EpLogBrowserOperationFactory new
		           logBrowserModel: (EpLogBrowserPresenter newWithLog: aPreviewLog);
		           entries: entries;
		           errorHandlerBlock: [ :error | error signal ];
		           yourself.
	revert
		ifTrue: [ factory revertCodeChangesInPreviewMode ]
		ifFalse: [ factory applyCodeChanges ].
	^ entries size
]

{ #category : 'accessing' }
MCPChangeHistorySelectionCommand >> performedCount [
	"How many previewed changes execute carried out: none unless confirmed."

	^ performedCount
]

{ #category : 'private - preview' }
MCPChangeHistorySelectionCommand >> previewLogForSelectedEntryPairs: somePairs fromLog: aLog [

	| factory |
	somePairs ifEmpty: [ ^ EpLog newWithEvents: #(  ) ].
	factory := EpLogBrowserOperationFactory new
		           logBrowserModel: (EpLogBrowserPresenter newWithLog: aLog);
		           entries: (somePairs collect: [ :pair | pair second ]);
		           errorHandlerBlock: [ :error | error signal ];
		           yourself.
	revert ifTrue: [ ^ factory newRevertPreviewLog ].
	^ factory newApplyPreviewLog
]

{ #category : 'accessing' }
MCPChangeHistorySelectionCommand >> range: someIndexes [

	range := someIndexes
]

{ #category : 'private - selection' }
MCPChangeHistorySelectionCommand >> rawSelectedEntryPairsFrom: aLog [

	| pairs |
	pairs := OrderedCollection new.
	self addEntriesAt: indexes to: pairs fromLog: aLog.
	self addEntriesAt: range to: pairs fromLog: aLog.
	self addLatestSelectionTo: pairs fromLog: aLog.
	^ self uniqueSortedPairsFrom: pairs
]

{ #category : 'accessing' }
MCPChangeHistorySelectionCommand >> revert: aBoolean [

	revert := aBoolean
]

{ #category : 'private - selection' }
MCPChangeHistorySelectionCommand >> selectedEntryPairsFromRawPairs: rawPairs [

	codeChangesOnly ifFalse: [ ^ rawPairs ].
	^ rawPairs select: [ :pair | self isCodeChangeEntry: pair second ]
]

{ #category : 'accessing' }
MCPChangeHistorySelectionCommand >> selectedPairs [
	"The selected entries execute previewed, as pairs of their one-based index and the entry, in index order."

	^ selectedPairs
]

{ #category : 'accessing' }
MCPChangeHistorySelectionCommand >> skippedNonCodeChangeCount [
	"How many selected entries execute left out for not being code changes."

	^ skippedNonCodeChangeCount
]

{ #category : 'private - selection' }
MCPChangeHistorySelectionCommand >> uniqueSortedPairsFrom: pairs [

	| byIndex |
	byIndex := Dictionary new.
	pairs do: [ :pair | byIndex at: pair first ifAbsentPut: [ pair ] ].
	^ byIndex values asArray sort: [ :left :right | left first < right first ]
]
