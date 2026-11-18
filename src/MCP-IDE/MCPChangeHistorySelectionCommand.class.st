"
Selects change history entries of a log by index, by range and by a count of the latest ones, and previews what applying or reverting them would change using Epicea's apply preview machinery.

execute answers the preview log, and selectedPairs, previewPairs, overridingIndexes and skippedNonCodeChangeCount then say what it selected, which entry each previewed change comes from, and why the others change nothing. performPreviewLog: carries the preview out.
"
Class {
	#name : 'MCPChangeHistorySelectionCommand',
	#superclass : 'MCPCommand',
	#instVars : [
		'revert',
		'indexes',
		'range',
		'latestCount',
		'codeChangesOnly',
		'log',
		'previewPairs',
		'overridingIndexes',
		'rawSelectedPairs'
	],
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPChangeHistorySelectionCommand class >> revert: revertBoolean log: aLog indexes: someIndexes range: rangeIndexes latestCount: aCountOrNil codeChangesOnly: codeChangesOnlyBoolean [
	"The entries of aLog at someIndexes and rangeIndexes, then the latest aCountOrNil of them, keeping the code changes only when codeChangesOnlyBoolean."

	^ self new
		  revert: revertBoolean;
		  log: aLog;
		  indexes: someIndexes;
		  range: rangeIndexes;
		  latestCount: aCountOrNil;
		  codeChangesOnly: codeChangesOnlyBoolean;
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

{ #category : 'private - preview' }
MCPChangeHistorySelectionCommand >> change: aChange overrides: anotherChange [
	"Whether aChange leaves nothing of anotherChange to preview, as EpLatestCodeChangeFilter reads it."

	^ aChange isCodeChange and: [ aChange doesOverride: anotherChange ]
]

{ #category : 'accessing' }
MCPChangeHistorySelectionCommand >> codeChangesOnly: aBoolean [

	codeChangesOnly := aBoolean
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

{ #category : 'executing' }
MCPChangeHistorySelectionCommand >> execute [
	"Select the entries, and answer the log that previews applying or reverting them. performPreviewLog: carries it out."

	rawSelectedPairs := self rawSelectedEntryPairsFrom: log.
	self previewSelectedPairs.
	^ EpLog newWithEvents: (previewPairs collect: [ :pair | pair second ] as: Array)
]

{ #category : 'accessing' }
MCPChangeHistorySelectionCommand >> indexes: someIndexes [

	indexes := someIndexes
]

{ #category : 'private - entries' }
MCPChangeHistorySelectionCommand >> isCodeChangeEntry: anEntry [

	^ anEntry content isCodeChange
]

{ #category : 'accessing' }
MCPChangeHistorySelectionCommand >> latestCount: aCountOrNil [

	latestCount := aCountOrNil
]

{ #category : 'accessing' }
MCPChangeHistorySelectionCommand >> log: aLog [

	log := aLog
]

{ #category : 'accessing' }
MCPChangeHistorySelectionCommand >> overridingIndexes [
	"The selected entries execute found overridden by a later change to the same element, from the index of each to the index of the entry that overrides it."

	^ overridingIndexes
]

{ #category : 'executing' }
MCPChangeHistorySelectionCommand >> performPreviewLog: aPreviewLog [
	"Carry out the changes aPreviewLog previews, as execute answered it. Answer how many."

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
MCPChangeHistorySelectionCommand >> previewPairs [
	"The changes execute previewed, in the order performPreviewLog: carries them out, as pairs of the one-based index of the selected entry each comes from and the change."

	^ previewPairs
]

{ #category : 'private - preview' }
MCPChangeHistorySelectionCommand >> previewSelectedPairs [
	"Preview the selected entries as EpLogBrowserOperationFactory>>newApplyPreviewLog and newRevertPreviewLog do, keeping what Epicea's preview log drops: the index of the entry each previewed change comes from, and the entry that overrides each of the others. A change is overridden by a later change to the same element, later in the order the entries are carried out: oldest first for an apply, newest first for a revert. A change left is previewed only as far as it would change the image."

	| ordered |
	previewPairs := OrderedCollection new.
	overridingIndexes := Dictionary new.
	ordered := revert
		           ifTrue: [ self selectedPairs reversed ]
		           ifFalse: [ self selectedPairs ].
	ordered doWithIndex: [ :pair :position |
			| change |
			change := pair second content.
			change isCodeChange ifTrue: [
					(ordered size to: position + 1 by: -1)
						detect: [ :laterPosition | self change: (ordered at: laterPosition) second content overrides: change ]
						ifFound: [ :laterPosition | overridingIndexes at: pair first put: (ordered at: laterPosition) first ]
						ifNone: [
								previewPairs addAll: ((self previewedChangesOf: change) collect: [ :each |
											 {
												 pair first.
												 each } ]) ] ] ]
]

{ #category : 'private - preview' }
MCPChangeHistorySelectionCommand >> previewedChangesOf: aCodeChange [
	"What applying aCodeChange, or reverting it, would change in the image, as Epicea previews it."

	^ (revert
		   ifTrue: [ aCodeChange asRevertedCodeChange ]
		   ifFalse: [ aCodeChange ]) previewedApplyEvents
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

	^ self selectedEntryPairsFromRawPairs: rawSelectedPairs
]

{ #category : 'accessing' }
MCPChangeHistorySelectionCommand >> skippedNonCodeChangeCount [
	"How many selected entries execute left out for not being code changes."

	^ rawSelectedPairs size - self selectedPairs size
]

{ #category : 'private - selection' }
MCPChangeHistorySelectionCommand >> uniqueSortedPairsFrom: pairs [

	| byIndex |
	byIndex := Dictionary new.
	pairs do: [ :pair | byIndex at: pair first ifAbsentPut: [ pair ] ].
	^ byIndex values asArray sort: [ :left :right | left first < right first ]
]
