"
A backend that records each tool call. It numbers the calls, and finishes each record with its duration, status, error details and output size against a budget; its subclasses say where the records go.
"
Class {
	#name : 'MCPRecordingObservabilityBackend',
	#superclass : 'MCPObservabilityBackend',
	#instVars : [
		'lastCallId',
		'outputByteBudget'
	],
	#category : 'MCP-Observability',
	#package : 'MCP',
	#tag : 'Observability'
}

{ #category : 'testing' }
MCPRecordingObservabilityBackend class >> isAbstract [

	^ self == MCPRecordingObservabilityBackend
]

{ #category : 'private - budgets' }
MCPRecordingObservabilityBackend >> byteCountOf: anObject [
	"The size of an object written as JSON, as a client receives it."

	anObject ifNil: [ ^ 0 ].
	^ ([ STONJSON toString: anObject ]
		   on: Error
		   do: [ :ignored | anObject asString ]) utf8Encoded size
]

{ #category : 'private - budgets' }
MCPRecordingObservabilityBackend >> byteCountOfResult: aToolResult error: anError [
	"What the call answered: its result, or the error that stopped it."

	aToolResult ifNotNil: [ ^ self byteCountOf: aToolResult asJRPCJSON ].
	anError ifNil: [ ^ 0 ].
	^ self byteCountOf: (self errorSummaryFor: anError)
]

{ #category : 'private - defaults' }
MCPRecordingObservabilityBackend >> defaultOutputBudgetBytes [

	^ 32 * 1024
]

{ #category : 'private - records' }
MCPRecordingObservabilityBackend >> finishRecord: aRecord result: aToolResult error: anError at: finishedAt [

	aRecord
		finishAt: finishedAt
		durationMilliseconds: (finishedAt - aRecord startedAt) asMilliSeconds
		status: (self statusForResult: aToolResult error: anError).
	self recordErrorDetailsFor: aRecord result: aToolResult error: anError.
	self recordOutputBudgetFor: aRecord result: aToolResult error: anError
]

{ #category : 'testing' }
MCPRecordingObservabilityBackend >> isNoop [

	^ false
]

{ #category : 'private - records' }
MCPRecordingObservabilityBackend >> newRecordFor: aToolName input: inputObject dispatchPath: dispatchPath [

	^ (MCPToolCallRecord id: self nextCallId toolName: aToolName asString startedAt: DateAndTime now)
		  inputObject: inputObject;
		  inputByteCount: (self byteCountOf: inputObject);
		  dispatchPath: dispatchPath asString;
		  yourself
]

{ #category : 'private' }
MCPRecordingObservabilityBackend >> nextCallId [
	"Calls are numbered from 1, in the order they start. The slot is filled here rather than in initialize because a backend that existed before this class was loaded keeps serving calls with it unset."

	^ lastCallId := (lastCallId ifNil: [ 0 ]) + 1
]

{ #category : 'accessing' }
MCPRecordingObservabilityBackend >> outputBudgetBytes [
	"A backend that existed before this class was loaded keeps serving calls with this slot unset."

	^ outputByteBudget ifNil: [ self defaultOutputBudgetBytes ]
]

{ #category : 'accessing' }
MCPRecordingObservabilityBackend >> outputBudgetBytes: anInteger [

	outputByteBudget := anInteger
]

{ #category : 'private - budgets' }
MCPRecordingObservabilityBackend >> outputBudgetExplanationForByteCount: byteCount [

	byteCount <= self outputBudgetBytes ifTrue: [ ^ '' ].
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Output ';
				  print: byteCount;
				  nextPutAll: ' bytes exceeds budget ';
				  print: self outputBudgetBytes;
				  nextPutAll: ' bytes; consider pagination, handles, or summary-first output' ]
]

{ #category : 'private - budgets' }
MCPRecordingObservabilityBackend >> recordOutputBudgetFor: aRecord result: aToolResult error: anError [

	| byteCount explanation |
	byteCount := self byteCountOfResult: aToolResult error: anError.
	explanation := self outputBudgetExplanationForByteCount: byteCount.
	aRecord
		outputByteCount: byteCount;
		approximateOutputTokenCount: byteCount + 3 // 4;
		outputBudgetBytes: self outputBudgetBytes;
		outputBudgetExceeded: explanation isNotEmpty;
		outputBudgetExplanation: explanation
]

{ #category : 'private' }
MCPRecordingObservabilityBackend >> statusForResult: aToolResult error: anError [

	anError ifNotNil: [ ^ 'error' ].
	aToolResult ifNil: [ ^ 'error' ].
	^ aToolResult isError
		  ifTrue: [ 'error' ]
		  ifFalse: [ 'ok' ]
]
