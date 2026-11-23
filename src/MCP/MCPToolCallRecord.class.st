"
Observability DTO for one MCP tool call. Active records have no finishedAt duration yet. Completed records store status, timing, compact output-budget metadata, optional error class, optional outlier explanation, and bounded redacted input/output snapshots only when the call is trace-worthy. The raw input object is held transiently while the call is active and cleared when recording finishes. A record knows the image session its call started in: saving the image saves the calls running, and every start of the saved image finishes them again.
"
Class {
	#name : 'MCPToolCallRecord',
	#superclass : 'Object',
	#instVars : [
		'id',
		'toolName',
		'startedAt',
		'finishedAt',
		'durationMilliseconds',
		'status',
		'errorClass',
		'errorKind',
		'errorCode',
		'causeClass',
		'schemaViolationKeywords',
		'schemaViolationCount',
		'summary',
		'outlierExplanation',
		'inputSnapshot',
		'outputSnapshot',
		'inputObject',
		'outputByteCount',
		'approximateOutputTokenCount',
		'outputBudgetBytes',
		'outputBudgetExceeded',
		'outputBudgetExplanation',
		'dispatchPath',
		'inputByteCount',
		'imageSession'
	],
	#category : 'MCP-Observability',
	#package : 'MCP',
	#tag : 'Observability'
}

{ #category : 'instance creation' }
MCPToolCallRecord class >> id: anInteger toolName: aToolName startedAt: startTimestamp [

	^ self new
		  id: anInteger;
		  toolName: aToolName;
		  startedAt: startTimestamp;
		  status: 'running';
		  yourself
]

{ #category : 'accessing' }
MCPToolCallRecord >> approximateOutputTokenCount [

	^ approximateOutputTokenCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
MCPToolCallRecord >> approximateOutputTokenCount: anInteger [

	approximateOutputTokenCount := anInteger
]

{ #category : 'converting' }
MCPToolCallRecord >> asDictionary [

	^ {
		  (#id -> self id).
		  (#tool -> self toolName).
		  (#dispatchPath -> self dispatchPath).
		  (#startedAt -> self displayStartedAt).
		  (#durationMilliseconds -> self durationMilliseconds).
		  (#status -> self status).
		  (#errorClass -> self errorClass).
		  (#errorKind -> self errorKind).
		  (#errorCode -> self errorCode).
		  (#causeClass -> self causeClass).
		  (#schemaViolationKeywords -> self schemaViolationKeywords).
		  (#schemaViolationCount -> self schemaViolationCount).
		  (#summary -> self summary).
		  (#eventKinds -> self eventKinds).
		  (#outlierExplanation -> self outlierExplanation).
		  (#inputBytes -> self inputByteCount).
		  (#outputBytes -> self outputByteCount).
		  (#approximateOutputTokens -> self approximateOutputTokenCount).
		  (#outputBudgetBytes -> self outputBudgetBytes).
		  (#outputBudgetExceeded -> self outputBudgetExceeded).
		  (#outputBudgetExplanation -> self outputBudgetExplanation).
		  (#input -> self inputSnapshot).
		  (#output -> self outputSnapshot) } asDictionary
]

{ #category : 'accessing' }
MCPToolCallRecord >> causeClass [

	^ causeClass ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPToolCallRecord >> causeClass: aString [

	causeClass := aString
]

{ #category : 'accessing' }
MCPToolCallRecord >> dispatchPath [

	^ dispatchPath ifNil: [ 'direct' ]
]

{ #category : 'accessing' }
MCPToolCallRecord >> dispatchPath: aString [

	dispatchPath := aString
]

{ #category : 'displaying' }
MCPToolCallRecord >> displayDurationMilliseconds [

	self isRunning ifTrue: [ ^ '' ].
	^ self durationMilliseconds asString
]

{ #category : 'displaying' }
MCPToolCallRecord >> displayStartedAt [

	^ self startedAt ifNil: [ '' ] ifNotNil: [ :timestamp | timestamp asString ]
]

{ #category : 'displaying' }
MCPToolCallRecord >> displaySummary [

	self outputBudgetExplanation isEmpty ifFalse: [ ^ self outputBudgetExplanation ].
	self outlierExplanation isEmpty ifFalse: [ ^ self outlierExplanation ].
	self summary isEmpty ifFalse: [ ^ self summary ].
	^ self errorClass
]

{ #category : 'accessing' }
MCPToolCallRecord >> durationMilliseconds [

	^ durationMilliseconds ifNil: [ 0 ]
]

{ #category : 'accessing' }
MCPToolCallRecord >> durationMilliseconds: anInteger [

	durationMilliseconds := anInteger
]

{ #category : 'accessing' }
MCPToolCallRecord >> errorClass [

	^ errorClass ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPToolCallRecord >> errorClass: aString [

	errorClass := aString
]

{ #category : 'accessing' }
MCPToolCallRecord >> errorCode [

	^ errorCode ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPToolCallRecord >> errorCode: aString [

	errorCode := aString
]

{ #category : 'accessing' }
MCPToolCallRecord >> errorKind [

	^ errorKind ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPToolCallRecord >> errorKind: aString [

	errorKind := aString
]

{ #category : 'accessing' }
MCPToolCallRecord >> eventKinds [

	^ Array streamContents: [ :stream |
			  self status = 'error' ifTrue: [ stream nextPut: 'error' ].
			  self outputBudgetExceeded ifTrue: [ stream nextPut: 'output_budget_exceeded' ].
			  self outlierExplanation ifNotEmpty: [ :ignored | stream nextPut: 'duration_outlier' ] ]
]

{ #category : 'recording' }
MCPToolCallRecord >> finishAt: finishTimestamp durationMilliseconds: milliseconds status: statusString [

	self finishedAt: finishTimestamp.
	self durationMilliseconds: milliseconds.
	self status: statusString
]

{ #category : 'accessing' }
MCPToolCallRecord >> finishedAt [

	^ finishedAt
]

{ #category : 'accessing' }
MCPToolCallRecord >> finishedAt: aTimestamp [

	finishedAt := aTimestamp
]

{ #category : 'accessing' }
MCPToolCallRecord >> id [

	^ id
]

{ #category : 'accessing' }
MCPToolCallRecord >> id: anInteger [

	id := anInteger
]

{ #category : 'accessing' }
MCPToolCallRecord >> imageSession [
	"The image session the call started in, or nil when the record was made without one."

	^ imageSession
]

{ #category : 'accessing' }
MCPToolCallRecord >> imageSession: aSession [

	imageSession := aSession
]

{ #category : 'accessing' }
MCPToolCallRecord >> inputByteCount [

	^ inputByteCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
MCPToolCallRecord >> inputByteCount: anInteger [

	inputByteCount := anInteger
]

{ #category : 'accessing' }
MCPToolCallRecord >> inputObject [

	^ inputObject
]

{ #category : 'accessing' }
MCPToolCallRecord >> inputObject: anObject [

	inputObject := anObject
]

{ #category : 'accessing' }
MCPToolCallRecord >> inputSnapshot [

	^ inputSnapshot
]

{ #category : 'accessing' }
MCPToolCallRecord >> inputSnapshot: anObject [

	inputSnapshot := anObject
]

{ #category : 'testing' }
MCPToolCallRecord >> isRunning [

	^ self finishedAt isNil
]

{ #category : 'testing' }
MCPToolCallRecord >> isTraceWorthy [

	^ self eventKinds isNotEmpty
]

{ #category : 'accessing' }
MCPToolCallRecord >> outlierExplanation [

	^ outlierExplanation ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPToolCallRecord >> outlierExplanation: aString [

	outlierExplanation := aString
]

{ #category : 'accessing' }
MCPToolCallRecord >> outputBudgetBytes [

	^ outputBudgetBytes ifNil: [ 0 ]
]

{ #category : 'accessing' }
MCPToolCallRecord >> outputBudgetBytes: anInteger [

	outputBudgetBytes := anInteger
]

{ #category : 'testing' }
MCPToolCallRecord >> outputBudgetExceeded [

	^ outputBudgetExceeded ifNil: [ false ]
]

{ #category : 'accessing' }
MCPToolCallRecord >> outputBudgetExceeded: aBoolean [

	outputBudgetExceeded := aBoolean
]

{ #category : 'accessing' }
MCPToolCallRecord >> outputBudgetExplanation [

	^ outputBudgetExplanation ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPToolCallRecord >> outputBudgetExplanation: aString [

	outputBudgetExplanation := aString
]

{ #category : 'accessing' }
MCPToolCallRecord >> outputByteCount [

	^ outputByteCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
MCPToolCallRecord >> outputByteCount: anInteger [

	outputByteCount := anInteger
]

{ #category : 'accessing' }
MCPToolCallRecord >> outputSnapshot [

	^ outputSnapshot
]

{ #category : 'accessing' }
MCPToolCallRecord >> outputSnapshot: anObject [

	outputSnapshot := anObject
]

{ #category : 'accessing' }
MCPToolCallRecord >> schemaViolationCount [

	^ schemaViolationCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
MCPToolCallRecord >> schemaViolationCount: anInteger [

	schemaViolationCount := anInteger
]

{ #category : 'accessing' }
MCPToolCallRecord >> schemaViolationKeywords [

	^ schemaViolationKeywords ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPToolCallRecord >> schemaViolationKeywords: aCollection [

	schemaViolationKeywords := aCollection ifNil: [ #(  ) ] ifNotNil: [ aCollection asArray ]
]

{ #category : 'accessing' }
MCPToolCallRecord >> startedAt [

	^ startedAt
]

{ #category : 'accessing' }
MCPToolCallRecord >> startedAt: aTimestamp [

	startedAt := aTimestamp
]

{ #category : 'testing' }
MCPToolCallRecord >> startedInAnEarlierImageSession [
	"Whether the call started before the image last started: the image was saved while it ran, and this start of the saved image goes on with it. A record made without its image session started in this one, as far as anyone can tell."

	^ imageSession isNotNil and: [ imageSession ~~ Smalltalk session ]
]

{ #category : 'accessing' }
MCPToolCallRecord >> status [

	^ status ifNil: [ 'running' ]
]

{ #category : 'accessing' }
MCPToolCallRecord >> status: aString [

	status := aString
]

{ #category : 'accessing' }
MCPToolCallRecord >> summary [

	^ summary ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPToolCallRecord >> summary: aString [

	summary := aString
]

{ #category : 'accessing' }
MCPToolCallRecord >> toolName [

	^ toolName
]

{ #category : 'accessing' }
MCPToolCallRecord >> toolName: aString [

	toolName := aString
]
