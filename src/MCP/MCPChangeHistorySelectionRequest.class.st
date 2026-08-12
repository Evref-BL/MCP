"
Request for previewing or performing apply/revert operations over a selected subset of image change history entries.
"
Class {
	#name : 'MCPChangeHistorySelectionRequest',
	#superclass : 'Object',
	#instVars : [
		'operation',
		'directoryPath',
		'historyFileName',
		'indexes',
		'startIndex',
		'endIndex',
		'latestCount',
		'codeChangesOnly',
		'confirm'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPChangeHistorySelectionRequest class >> fromRequest: aRequest tool: aTool operation: operationName [

	^ self new
		  initializeFromRequest: aRequest operation: operationName;
		  yourself
]

{ #category : 'accessing' }
MCPChangeHistorySelectionRequest >> action [

	self isRevertOperation ifTrue: [ ^ 'revert' ].
	^ 'apply'
]

{ #category : 'accessing' }
MCPChangeHistorySelectionRequest >> codeChangesOnly [

	^ codeChangesOnly ifNil: [ true ]
]

{ #category : 'accessing' }
MCPChangeHistorySelectionRequest >> confirm [

	^ confirm ifNil: [ false ]
]

{ #category : 'accessing' }
MCPChangeHistorySelectionRequest >> directoryPath [

	^ directoryPath
]

{ #category : 'accessing' }
MCPChangeHistorySelectionRequest >> directoryPath: aString [

	directoryPath := aString
]

{ #category : 'accessing' }
MCPChangeHistorySelectionRequest >> endIndex [

	^ endIndex
]

{ #category : 'testing' }
MCPChangeHistorySelectionRequest >> hasRangeSelection [

	startIndex ifNotNil: [ ^ true ].
	endIndex ifNotNil: [ ^ true ].
	^ false
]

{ #category : 'testing' }
MCPChangeHistorySelectionRequest >> hasSelectionCriteria [

	^ self indexes notEmpty or: [ self hasRangeSelection or: [ self latestCount notNil ] ]
]

{ #category : 'accessing' }
MCPChangeHistorySelectionRequest >> historyFileName [

	^ historyFileName
]

{ #category : 'accessing' }
MCPChangeHistorySelectionRequest >> historyFileName: aString [

	historyFileName := aString
]

{ #category : 'accessing' }
MCPChangeHistorySelectionRequest >> indexes [

	^ indexes ifNil: [ #(  ) ]
]

{ #category : 'initialization' }
MCPChangeHistorySelectionRequest >> initializeFromRequest: aRequest operation: operationName [

	operation := operationName.
	directoryPath := aRequest stringArgumentNamed: 'directoryPath'.
	historyFileName := aRequest stringArgumentNamed: 'historyFileName'.
	indexes := self positiveIntegerCollectionArgumentNamed: 'indexes' fromRequest: aRequest.
	startIndex := self optionalPositiveIntegerArgumentNamed: 'startIndex' fromRequest: aRequest.
	endIndex := self optionalPositiveIntegerArgumentNamed: 'endIndex' fromRequest: aRequest.
	latestCount := self optionalPositiveIntegerArgumentNamed: 'latestCount' fromRequest: aRequest.
	codeChangesOnly := aRequest booleanArgumentNamed: 'codeChangesOnly' default: true.
	confirm := aRequest booleanArgumentNamed: 'confirm' default: false.
	self validateSelectionCriteria
]

{ #category : 'testing' }
MCPChangeHistorySelectionRequest >> isApplyOperation [

	^ self operation = 'applyEntries'
]

{ #category : 'testing' }
MCPChangeHistorySelectionRequest >> isRevertOperation [

	^ self operation = 'revertEntries'
]

{ #category : 'accessing' }
MCPChangeHistorySelectionRequest >> latestCount [

	^ latestCount
]

{ #category : 'accessing' }
MCPChangeHistorySelectionRequest >> operation [

	^ operation
]

{ #category : 'private' }
MCPChangeHistorySelectionRequest >> optionalPositiveIntegerArgumentNamed: argumentName fromRequest: aRequest [

	| value |
	(aRequest hasArgumentNamed: argumentName) ifFalse: [ ^ nil ].
	value := aRequest argumentNamed: argumentName ifAbsent: [ ^ nil ].
	(value isInteger and: [ value > 0 ]) ifFalse: [
			self signalInvalidSelection: argumentName , ' must be a positive integer.' details: {
					(#argumentName -> argumentName).
					(#actualValue -> value) } asDictionary ].
	^ value
]

{ #category : 'private' }
MCPChangeHistorySelectionRequest >> positiveIntegerCollectionArgumentNamed: argumentName fromRequest: aRequest [

	| values |
	values := aRequest arrayArgumentNamed: argumentName.
	^ (values collect: [ :each |
			   (each isInteger and: [ each > 0 ]) ifFalse: [
					   self signalInvalidSelection: argumentName , ' must contain only positive integers.' details: {
							   (#argumentName -> argumentName).
							   (#actualValue -> each) } asDictionary ].
			   each ]) asArray
]

{ #category : 'converting' }
MCPChangeHistorySelectionRequest >> selectionCriteria [

	| criteria |
	criteria := Dictionary new.
	self indexes ifNotEmpty: [ :values | criteria at: #indexes put: values ].
	self hasRangeSelection ifTrue: [
			criteria at: #startIndex put: self startIndex.
			criteria at: #endIndex put: self endIndex ].
	self latestCount ifNotNil: [ :value | criteria at: #latestCount put: value ].
	criteria at: #codeChangesOnly put: self codeChangesOnly.
	^ criteria
]

{ #category : 'private - validation' }
MCPChangeHistorySelectionRequest >> signalIncompleteRangeSelection [

	self signalInvalidSelection: 'startIndex and endIndex must be provided together for range selection.' details: {
			(#startIndex -> startIndex).
			(#endIndex -> endIndex) } asDictionary
]

{ #category : 'private' }
MCPChangeHistorySelectionRequest >> signalInvalidSelection: aMessage details: aDictionary [

	MCPCommandError signalErrorCode: #ChangeHistoryInvalidSelection message: aMessage details: aDictionary
]

{ #category : 'accessing' }
MCPChangeHistorySelectionRequest >> startIndex [

	^ startIndex
]

{ #category : 'validating' }
MCPChangeHistorySelectionRequest >> validateSelectionCriteria [

	self hasRangeSelection ifTrue: [
			startIndex ifNil: [ self signalIncompleteRangeSelection ].
			endIndex ifNil: [ self signalIncompleteRangeSelection ].
			startIndex > endIndex ifTrue: [
					self signalInvalidSelection: 'startIndex must be less than or equal to endIndex.' details: {
							(#startIndex -> startIndex).
							(#endIndex -> endIndex) } asDictionary ] ].
	self hasSelectionCriteria ifFalse: [
			self
				signalInvalidSelection: 'Provide at least one selection criterion: indexes, startIndex/endIndex, or latestCount.'
				details: Dictionary new ]
]
