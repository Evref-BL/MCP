"
Shared implementation for change-history selection tools. It checks the entries the request names, reads the history they come from, applies or reverts them through MCPChangeHistorySelectionCommand, and describes the selected entries and the changes made, so apply and revert select, act and answer alike. A subclass says whether it reverts.
"
Class {
	#name : 'MCPToolChangeHistoryOperation',
	#superclass : 'MCPToolChangeHistory',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'private - actions' }
MCPToolChangeHistoryOperation >> actionName [

	^ self changeHistoryToolSpec at: #action
]

{ #category : 'private - results' }
MCPToolChangeHistoryOperation >> addEntriesOf: aSelection in: aLog to: data [
	"The entries aSelection took from aLog, each saying why it changes nothing when it made no change of its own, and the changes it made, each under the index of the entry it comes from and with the source it changes, with how many of each."

	| changedIndexes changes selectedEntries |
	changedIndexes := aSelection previewPairs collect: [ :pair | pair first ] as: Set.
	selectedEntries := aSelection selectedPairs collect: [ :pair |
			                   | entry |
			                   entry := MCPChangeHistoryEntryInfo fromEntry: pair second index: pair first log: aLog.
			                   (changedIndexes includes: pair first) ifFalse: [
				                   entry changesNothingBecause: (self reasonEntryChangesNothing: pair in: aSelection) ].
			                   entry ].
	changes := aSelection previewPairs collect: [ :pair |
		           MCPChangeHistoryEntryInfo fromPreviewedChange: pair second index: pair first ].
	data at: #selectedEntries put: (selectedEntries collect: [ :each | each asDictionary ] as: Array).
	data at: #changes put: (changes collect: [ :each | each asDictionary ] as: Array).
	data at: #selectedCount put: selectedEntries size.
	data at: #selectedCodeChangeCount put: (selectedEntries count: [ :each | each isCodeChange ]).
	data at: #changeCount put: changes size
]

{ #category : 'metadata' }
MCPToolChangeHistoryOperation >> buildInputSchema [

	^ MCPStructureInputSchema
		  properties: {
				  self directoryPathSchemaProperty.
				  self historyFileSchemaProperty.
				  (self
					   arraySchemaNamed: 'indexes'
					   itemType: 'integer'
					   description: 'The entries to act on, by the one-based index history_entry_list prints.'
					   itemDescription: 'Entry index.') }
		  required: #( 'indexes' )
]

{ #category : 'private - specs' }
MCPToolChangeHistoryOperation >> changeHistoryToolSpec [

	self subclassResponsibility
]

{ #category : 'private - validation' }
MCPToolChangeHistoryOperation >> checkArguments: request [
	"The schema requires indexes, but an empty list names no entry, and an index counts from one."

	| indexes |
	indexes := request arrayArgumentNamed: 'indexes'.
	indexes ifEmpty: [
			self
				signalInvalidSelection: 'indexes must name at least one entry, by the index history_entry_list prints.'
				details: Dictionary new ].
	indexes do: [ :each |
			each > 0 ifFalse: [
					self signalInvalidSelection: 'indexes must contain only positive integers.' details: {
							(#argumentName -> 'indexes').
							(#actualValue -> each) } asDictionary ] ]
]

{ #category : 'private - execution' }
MCPToolChangeHistoryOperation >> dataFor: request [
	"Check the selection, read the history it comes from, and apply or revert the entries it takes. Epicea carries out the changes it previews, so the preview is both what the call does and what the answer shows."

	| data logAndFileName selection |
	self checkArguments: request.
	logAndFileName := self logAndFileNameFor: request.
	selection := self selectionFor: request in: logAndFileName first.
	selection performPreviewLog: selection execute.
	data := Dictionary new.
	data at: #action put: self actionName.
	logAndFileName second ifNotNil: [ :fileName | data at: #historyFile put: fileName ].
	data at: #selectionCriteria put: (self selectionCriteriaFrom: request).
	self addEntriesOf: selection in: logAndFileName first to: data.
	^ data
]

{ #category : 'metadata' }
MCPToolChangeHistoryOperation >> description [

	^ self changeHistoryToolSpec at: #description
]

{ #category : 'private - results' }
MCPToolChangeHistoryOperation >> keysStatedInSummary [
	"The summary already reads 'Applied 3 changes from 5 selected history entries.'"

	^ #( action changeCount selectedCount )
]

{ #category : 'private - results' }
MCPToolChangeHistoryOperation >> reasonEntryChangesNothing: aPair in: aSelection [
	"Why Epicea's preview holds no change of a selected entry's own: a later change to the same element overrides it, it is no code change, or the image already is as the entry would leave it."

	^ aSelection overridingIndexes
		  at: aPair first
		  ifPresent: [ :index | String streamContents: [ :stream | stream << 'overridden by entry ' << index printString ] ]
		  ifAbsent: [
				  aPair second content isCodeChange
					  ifTrue: [ self changeHistoryToolSpec at: #unchangedReason ]
					  ifFalse: [ 'not a code change' ] ]
]

{ #category : 'private - results' }
MCPToolChangeHistoryOperation >> redundantKeys [
	"selectionCriteria is the request read back."

	^ super redundantKeys , #( selectionCriteria )
]

{ #category : 'private - actions' }
MCPToolChangeHistoryOperation >> reverts [
	"Whether the tool reverts the entries it selects rather than applies them."

	^ self actionName = 'revert'
]

{ #category : 'private - results' }
MCPToolChangeHistoryOperation >> selectionCriteriaFrom: request [
	"The selection as the caller gave it."

	^ { (#indexes -> (request arrayArgumentNamed: 'indexes')) } asDictionary
]

{ #category : 'private - execution' }
MCPToolChangeHistoryOperation >> selectionFor: request in: aLog [
	"The operation that selects the entries of aLog the request names, and applies or reverts them."

	^ MCPChangeHistorySelectionCommand revert: self reverts log: aLog indexes: (request arrayArgumentNamed: 'indexes')
]

{ #category : 'private - validation' }
MCPToolChangeHistoryOperation >> signalInvalidSelection: aMessage details: aDictionary [

	MCPCommandError signalErrorCode: #ChangeHistoryInvalidSelection message: aMessage details: aDictionary
]

{ #category : 'private - results' }
MCPToolChangeHistoryOperation >> successSummaryForData: data [
	"'Applied 3 changes from 5 selected history entries.' A selected entry that made no change says why in the answer."

	^ String streamContents: [ :stream |
			  stream << (self changeHistoryToolSpec at: #pastTense) << ' ' << (self textForCount: (data at: #changeCount) noun: 'change')
			  << ' from ' << (self textForCount: (data at: #selectedCount) noun: 'selected history entry') << '.' ]
]

{ #category : 'metadata' }
MCPToolChangeHistoryOperation >> title [

	^ self changeHistoryToolSpec at: #title
]
