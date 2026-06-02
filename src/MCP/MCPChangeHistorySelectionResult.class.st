"
Structured result for previewing or applying selected image change history entries.
"
Class {
	#name : 'MCPChangeHistorySelectionResult',
	#superclass : 'Object',
	#instVars : [
		'historyFilePath',
		'selectionCriteria',
		'selectedEntries',
		'previewEntries',
		'selectedCount',
		'selectedCodeChangeCount',
		'skippedNonCodeChangeCount',
		'previewCount',
		'headReference',
		'action',
		'performed',
		'performedCount'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPChangeHistorySelectionResult class >> action: actionName historyFilePath: aPath selectionCriteria: criteriaDictionary selectedEntries: selectedEntryInfos previewEntries: previewEntryInfos skippedNonCodeChangeCount: skippedCount performed: performedFlag performedCount: performedEntryCount headReference: aReferenceString [

	^ self new
		  initializeAction: actionName
		  historyFilePath: aPath
		  selectionCriteria: criteriaDictionary
		  selectedEntries: selectedEntryInfos
		  previewEntries: previewEntryInfos
		  skippedNonCodeChangeCount: skippedCount
		  performed: performedFlag
		  performedCount: performedEntryCount
		  headReference: aReferenceString
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

	^ {
		  (#action -> action).
		  (#historyFilePath -> historyFilePath).
		  (#selectionCriteria -> selectionCriteria).
		  (#selectedEntries
		   -> (self entryDictionariesFrom: self selectedEntries)).
		  (#previewEntries
		   -> (self entryDictionariesFrom: self previewEntries)).
		  (#selectedCount -> selectedCount).
		  (#selectedCodeChangeCount -> selectedCodeChangeCount).
		  (#skippedNonCodeChangeCount -> skippedNonCodeChangeCount).
		  (#previewCount -> previewCount).
		  (#performed -> performed).
		  (#performedCount -> performedCount).
		  (#headReference -> headReference) } asDictionary
]

{ #category : 'converting' }
MCPChangeHistorySelectionResult >> entryDictionariesFrom: entryInfos [

	^ (entryInfos collect: [ :each | each asDictionary ]) asArray
]

{ #category : 'initialization' }
MCPChangeHistorySelectionResult >> initializeAction: actionName historyFilePath: aPath selectionCriteria: criteriaDictionary selectedEntries: selectedEntryInfos previewEntries: previewEntryInfos skippedNonCodeChangeCount: skippedCount performed: performedFlag performedCount: performedEntryCount headReference: aReferenceString [

	action := actionName.
	historyFilePath := aPath.
	selectionCriteria := criteriaDictionary ifNil: [ Dictionary new ].
	selectedEntries := selectedEntryInfos ifNil: [ #(  ) ].
	previewEntries := previewEntryInfos ifNil: [ #(  ) ].
	selectedCount := selectedEntries size.
	selectedCodeChangeCount := selectedEntries count: [ :each |
		                           (each asDictionary
			                            at: #isCodeChange
			                            ifAbsent: [ false ]) == true ].
	skippedNonCodeChangeCount := skippedCount ifNil: [ 0 ].
	previewCount := previewEntries size.
	performed := performedFlag.
	performedCount := performedEntryCount ifNil: [ 0 ].
	headReference := aReferenceString.
	^ self
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
