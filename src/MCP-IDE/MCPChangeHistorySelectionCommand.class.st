"
Selects change history entries of a log by index, and previews what applying or reverting them would change using Epicea's apply preview machinery.

execute answers the preview log, and selectedPairs, previewPairs and overridingIndexes then say what it selected, which entry each previewed change comes from, and why the others change nothing. performPreviewLog: carries the preview out.
"
Class {
	#name : 'MCPChangeHistorySelectionCommand',
	#superclass : 'MCPCommand',
	#instVars : [
		'revert',
		'indexes',
		'log',
		'previewPairs',
		'overridingIndexes',
		'selectedPairs'
	],
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPChangeHistorySelectionCommand class >> revert: revertBoolean log: aLog indexes: someIndexes [
	"The entries of aLog at someIndexes, to apply, or to revert when revertBoolean."

	^ self new
		  revert: revertBoolean;
		  log: aLog;
		  indexes: someIndexes;
		  yourself
]

{ #category : 'private - selection' }
MCPChangeHistorySelectionCommand >> addEntriesAt: someIndexes to: pairs fromLog: aLog [
	"The log reads every entry each time it is asked for them, so it is asked once."

	| entries |
	entries := aLog entries.
	someIndexes do: [ :index |
			pairs add: {
					index.
					(self entryAtIndex: index among: entries) } ].
	^ pairs
]

{ #category : 'private - preview' }
MCPChangeHistorySelectionCommand >> change: aChange overrides: anotherChange [
	"Whether aChange leaves nothing of anotherChange to preview, as EpLatestCodeChangeFilter reads it."

	^ aChange isCodeChange and: [ aChange doesOverride: anotherChange ]
]

{ #category : 'private - entries' }
MCPChangeHistorySelectionCommand >> entryAtIndex: anIndex among: someEntries [

	(anIndex between: 1 and: someEntries size) ifFalse: [
			MCPCommandError
				signalErrorCode: #ChangeHistoryEntryNotFound
				message:
				(String streamContents: [ :stream | stream << 'Change history entry index ' << anIndex asString << ' does not exist.' ])
				details: {
						(#index -> anIndex).
						(#entryCount -> someEntries size) } asDictionary ].
	^ someEntries at: anIndex
]

{ #category : 'executing' }
MCPChangeHistorySelectionCommand >> execute [
	"Select the entries, and answer the log that previews applying or reverting them. performPreviewLog: carries it out."

	selectedPairs := self selectedEntryPairsFrom: log.
	self previewSelectedPairs.
	^ EpLog newWithEvents: (previewPairs collect: [ :pair | pair second ] as: Array)
]

{ #category : 'accessing' }
MCPChangeHistorySelectionCommand >> indexes: someIndexes [

	indexes := someIndexes
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
MCPChangeHistorySelectionCommand >> revert: aBoolean [

	revert := aBoolean
]

{ #category : 'private - selection' }
MCPChangeHistorySelectionCommand >> selectedEntryPairsFrom: aLog [

	^ self uniqueSortedPairsFrom: (self addEntriesAt: indexes to: OrderedCollection new fromLog: aLog)
]

{ #category : 'accessing' }
MCPChangeHistorySelectionCommand >> selectedPairs [
	"The selected entries execute previewed, as pairs of their one-based index and the entry, in index order."

	^ selectedPairs
]

{ #category : 'private - selection' }
MCPChangeHistorySelectionCommand >> uniqueSortedPairsFrom: pairs [

	| byIndex |
	byIndex := Dictionary new.
	pairs do: [ :pair | byIndex at: pair first ifAbsentPut: [ pair ] ].
	^ byIndex values asArray sort: [ :left :right | left first < right first ]
]
