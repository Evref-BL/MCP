"
Structured result for previewing or applying selected image change history entries.
"
Class {
	#name : 'MCPChangeHistorySelectionResult',
	#superclass : 'MCPResult',
	#instVars : [
		'historyFileName',
		'selectionCriteria',
		'selectedEntries',
		'previewEntries',
		'selectedCount',
		'selectedCodeChangeCount',
		'skippedNonCodeChangeCount',
		'previewCount',
		'action',
		'performed',
		'performedCount'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPChangeHistorySelectionResult class >> action: actionName historyFileName: fileName selectionCriteria: criteriaDictionary selectedEntries: selectedEntryInfos previewEntries: previewEntryInfos skippedNonCodeChangeCount: skippedCount performed: performedFlag performedCount: performedEntryCount [

	^ self new
		  initializeAction: actionName
		  historyFileName: fileName
		  selectionCriteria: criteriaDictionary
		  selectedEntries: selectedEntryInfos
		  previewEntries: previewEntryInfos
		  skippedNonCodeChangeCount: skippedCount
		  performed: performedFlag
		  performedCount: performedEntryCount
]

{ #category : 'accessing' }
MCPChangeHistorySelectionResult >> action [

	^ action
]

{ #category : 'accessing' }
MCPChangeHistorySelectionResult >> action: anObject [

	action := anObject
]

{ #category : 'converting' }
MCPChangeHistorySelectionResult >> asDictionary [

	| data |
	data := Dictionary new.
	data at: #action put: action.
	historyFileName ifNotNil: [
		data at: #historyFileName put: historyFileName ].
	data at: #selectionCriteria put: selectionCriteria.
	data
		at: #selectedEntries
		put: (self entryDictionariesFrom: self selectedEntries).
	data
		at: #previewEntries
		put: (self entryDictionariesFrom: self previewEntries).
	data at: #selectedCount put: selectedCount.
	data at: #selectedCodeChangeCount put: selectedCodeChangeCount.
	data at: #skippedNonCodeChangeCount put: skippedNonCodeChangeCount.
	data at: #previewCount put: previewCount.
	data at: #performed put: performed.
	data at: #performedCount put: performedCount.
	^ data
]

{ #category : 'converting' }
MCPChangeHistorySelectionResult >> entryDictionariesFrom: entryInfos [

	^ (entryInfos collect: [ :each | each asDictionary ]) asArray
]

{ #category : 'accessing' }
MCPChangeHistorySelectionResult >> historyFileName: aString [

	historyFileName := aString
]

{ #category : 'initialization' }
MCPChangeHistorySelectionResult >> initializeAction: actionName historyFileName: fileName selectionCriteria: criteriaDictionary selectedEntries: selectedEntryInfos previewEntries: previewEntryInfos skippedNonCodeChangeCount: skippedCount performed: performedFlag performedCount: performedEntryCount [

	action := actionName.
	historyFileName := fileName.
	selectionCriteria := criteriaDictionary ifNil: [ Dictionary new ].
	selectedEntries := selectedEntryInfos ifNil: [ #(  ) ].
	previewEntries := previewEntryInfos ifNil: [ #(  ) ].
	selectedCount := selectedEntries size.
	selectedCodeChangeCount := selectedEntries count: [ :each |
		                           each isCodeChange ].
	skippedNonCodeChangeCount := skippedCount ifNil: [ 0 ].
	previewCount := previewEntries size.
	performed := performedFlag.
	performedCount := performedEntryCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
MCPChangeHistorySelectionResult >> performed [

	^ performed
]

{ #category : 'accessing' }
MCPChangeHistorySelectionResult >> performed: anObject [

	performed := anObject
]

{ #category : 'accessing' }
MCPChangeHistorySelectionResult >> performedCount [

	^ performedCount
]

{ #category : 'accessing' }
MCPChangeHistorySelectionResult >> performedCount: anObject [

	performedCount := anObject
]

{ #category : 'accessing' }
MCPChangeHistorySelectionResult >> previewEntries [

	^ previewEntries ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPChangeHistorySelectionResult >> selectedEntries [

	^ selectedEntries ifNil: [ #(  ) ]
]
