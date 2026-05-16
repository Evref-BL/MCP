"
Monitoring DTO for one MCP tool call. Active records have no finishedAt or duration yet. Completed records store status, timing, optional error class, optional outlier explanation, and bounded redacted input/output snapshots only when the call is trace-worthy. The raw input object is held transiently while the call is active and cleared when recording finishes.
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
		'summary',
		'outlierExplanation',
		'inputSnapshot',
		'outputSnapshot',
		'inputObject'
	],
	#category : 'MCP-Monitoring',
	#package : 'MCP',
	#tag : 'Monitoring'
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

{ #category : 'converting' }
MCPToolCallRecord >> asDictionary [

	^ {
		  (#id -> self id).
		  (#toolName -> self toolName).
		  (#startedAt -> self displayStartedAt).
		  (#durationMilliseconds -> self durationMilliseconds).
		  (#status -> self status).
		  (#errorClass -> self errorClass).
		  (#summary -> self summary).
		  (#outlierExplanation -> self outlierExplanation).
		  (#input -> self inputSnapshot).
		  (#output -> self outputSnapshot) } asDictionary
]

{ #category : 'displaying' }
MCPToolCallRecord >> displayDurationMilliseconds [

	self isRunning ifTrue: [ ^ '' ].
	^ self durationMilliseconds asString
]

{ #category : 'displaying' }
MCPToolCallRecord >> displayStartedAt [

	^ self startedAt
		  ifNil: [ '' ]
		  ifNotNil: [ :timestamp | timestamp asString ]
]

{ #category : 'displaying' }
MCPToolCallRecord >> displaySummary [

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

{ #category : 'private' }
MCPToolCallRecord >> inputObject [

	^ inputObject
]

{ #category : 'private' }
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

	^ self status = 'error' or: [ self outlierExplanation isEmpty not ]
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
MCPToolCallRecord >> outputSnapshot [

	^ outputSnapshot
]

{ #category : 'accessing' }
MCPToolCallRecord >> outputSnapshot: anObject [

	outputSnapshot := anObject
]

{ #category : 'accessing' }
MCPToolCallRecord >> startedAt [

	^ startedAt
]

{ #category : 'accessing' }
MCPToolCallRecord >> startedAt: aTimestamp [

	startedAt := aTimestamp
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
