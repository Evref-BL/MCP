"
OpenTelemetry observability backend for MCP.

This class lives in the optional MCP-OpenTelemetry package so MCP core can remain free of OpenTelemetry dependencies.
"
Class {
	#name : 'MCPOpenTelemetryObservabilityBackend',
	#superclass : 'MCPNoopObservabilityBackend',
	#instVars : [
		'enabled',
		'tracer',
		'meter',
		'logger',
		'nextCallId',
		'callCounter',
		'errorCounter',
		'durationHistogram',
		'inputSizeHistogram',
		'outputSizeHistogram',
		'outputBudgetExceededCounter',
		'recordsById',
		'outputBudgetBytes'
	],
	#category : 'MCP-OpenTelemetry',
	#package : 'MCP-OpenTelemetry'
}

{ #category : 'private - metrics' }
MCPOpenTelemetryObservabilityBackend >> attributesForRecord: aRecord [

	^ {
		  ('tool.name' -> aRecord toolName).
		  ('mcp.dispatch_path' -> aRecord dispatchPath).
		  ('mcp.status' -> aRecord status) }
]

{ #category : 'private - instruments' }
MCPOpenTelemetryObservabilityBackend >> callCounter [

	callCounter ifNotNil: [ ^ callCounter ].
	callCounter := self meter counterNamed: 'mcp.tool.calls' unit: '1' description: 'MCP tool calls'.
	^ callCounter
]

{ #category : 'private - budgets' }
MCPOpenTelemetryObservabilityBackend >> defaultOutputBudgetBytes [

	^ 32 * 1024
]

{ #category : 'activation' }
MCPOpenTelemetryObservabilityBackend >> disable [

	enabled := false
]

{ #category : 'private - instruments' }
MCPOpenTelemetryObservabilityBackend >> durationHistogram [

	durationHistogram ifNotNil: [ ^ durationHistogram ].
	durationHistogram := self meter histogramNamed: 'mcp.tool.duration' unit: 'ms' description: 'MCP tool-call duration'.
	^ durationHistogram
]

{ #category : 'private - logging' }
MCPOpenTelemetryObservabilityBackend >> emitEventNamed: eventName body: bodyString [

	self enabled ifFalse: [ ^ nil ].
	self logger logRecordBuilder
		eventName: eventName;
		body: bodyString;
		emit
]

{ #category : 'activation' }
MCPOpenTelemetryObservabilityBackend >> enable [

	enabled := true
]

{ #category : 'accessing' }
MCPOpenTelemetryObservabilityBackend >> enabled [

	^ enabled ifNil: [ true ]
]

{ #category : 'accessing' }
MCPOpenTelemetryObservabilityBackend >> enabled: aBoolean [

	aBoolean
		ifTrue: [ self enable ]
		ifFalse: [ self disable ]
]

{ #category : 'private - spans' }
MCPOpenTelemetryObservabilityBackend >> endSpan: span withRecord: aRecord error: anError at: finishedAt [

	| attributes |
	span ifNil: [ ^ nil ].
	attributes := self attributesForRecord: aRecord.
	self
		enrichSpan: span
		withRecord: aRecord
		attributes: attributes
		error: anError.
	span end: finishedAt
]

{ #category : 'private - spans' }
MCPOpenTelemetryObservabilityBackend >> enrichSpan: span withRecord: aRecord attributes: attributes error: anError [

	span
		attributeAt: 'mcp.call.id' put: aRecord id;
		attributeAt: 'mcp.tool.name' put: aRecord toolName;
		attributeAt: 'mcp.dispatch_path' put: aRecord dispatchPath;
		attributeAt: 'mcp.status' put: aRecord status;
		attributeAt: 'mcp.input.bytes' put: aRecord inputByteCount;
		attributeAt: 'mcp.output.bytes' put: aRecord outputByteCount;
		attributeAt: 'mcp.output.tokens.approx' put: aRecord approximateOutputTokenCount;
		attributeAt: 'mcp.output_budget.exceeded' put: aRecord outputBudgetExceeded.
	aRecord outputBudgetExceeded ifTrue: [ span addEventNamed: 'mcp.output_budget_exceeded' attributes: attributes ].
	anError ifNotNil: [
			span
				attributeAt: 'error.type' put: anError class name asString;
				setStatus: OTSpan error description: anError description;
				recordException: anError ].
	aRecord status = 'ok' ifTrue: [ span setStatus: OTSpan ok description: '' ]
]

{ #category : 'private - metrics' }
MCPOpenTelemetryObservabilityBackend >> errorAttributesForRecord: aRecord baseAttributes: attributes [

	^ attributes copyWith: 'error.type' -> aRecord errorClass
]

{ #category : 'private' }
MCPOpenTelemetryObservabilityBackend >> errorClassNameFor: anError [

	anError ifNil: [ ^ '' ].
	^ anError class name asString
]

{ #category : 'private - instruments' }
MCPOpenTelemetryObservabilityBackend >> errorCounter [

	errorCounter ifNotNil: [ ^ errorCounter ].
	errorCounter := self meter counterNamed: 'mcp.tool.errors' unit: '1' description: 'MCP tool-call errors'.
	^ errorCounter
]

{ #category : 'private - records' }
MCPOpenTelemetryObservabilityBackend >> finishRecord: aRecord result: aToolResult error: anError at: finishedAt [

	| duration statusString |
	duration := (finishedAt - aRecord startedAt) asMilliSeconds.
	statusString := self statusForResult: aToolResult error: anError.
	aRecord finishAt: finishedAt durationMilliseconds: duration status: statusString.
	aRecord errorClass: (self errorClassNameFor: anError).
	self recordOutputBudgetFor: aRecord result: aToolResult error: anError.
	aRecord inputObject: nil.
	self updateEventKindsForRecord: aRecord
]

{ #category : 'actions' }
MCPOpenTelemetryObservabilityBackend >> forceFlush [

	OTTracerProvider current forceFlush.
	OTMeterProvider current forceFlush.
	OTLoggerProvider current forceFlush
]

{ #category : 'initialization' }
MCPOpenTelemetryObservabilityBackend >> initialize [

	super initialize.
	enabled := true.
	nextCallId := 0.
	recordsById := Dictionary new.
	outputBudgetBytes := self defaultOutputBudgetBytes
]

{ #category : 'private - instruments' }
MCPOpenTelemetryObservabilityBackend >> inputSizeHistogram [

	inputSizeHistogram ifNotNil: [ ^ inputSizeHistogram ].
	inputSizeHistogram := self meter histogramNamed: 'mcp.tool.input.size' unit: 'By' description: 'MCP tool-call input size'.
	^ inputSizeHistogram
]

{ #category : 'testing' }
MCPOpenTelemetryObservabilityBackend >> isNoop [

	^ false
]

{ #category : 'accessing' }
MCPOpenTelemetryObservabilityBackend >> logger [

	logger ifNotNil: [ ^ logger ].
	logger := OTLoggerProvider current loggerNamed: 'mcp-pharo'.
	^ logger
]

{ #category : 'accessing' }
MCPOpenTelemetryObservabilityBackend >> meter [

	meter ifNotNil: [ ^ meter ].
	meter := OTMeterProvider current meterNamed: 'mcp-pharo'.
	^ meter
]

{ #category : 'private' }
MCPOpenTelemetryObservabilityBackend >> nextCallId [

	nextCallId := (nextCallId ifNil: [ 0 ]) + 1.
	^ nextCallId
]

{ #category : 'private - budgets' }
MCPOpenTelemetryObservabilityBackend >> outputBudgetBytes [

	^ outputBudgetBytes ifNil: [ self defaultOutputBudgetBytes ]
]

{ #category : 'private - budgets' }
MCPOpenTelemetryObservabilityBackend >> outputBudgetBytes: anInteger [

	outputBudgetBytes := anInteger
]

{ #category : 'private - instruments' }
MCPOpenTelemetryObservabilityBackend >> outputBudgetExceededCounter [

	outputBudgetExceededCounter ifNotNil: [ ^ outputBudgetExceededCounter ].
	outputBudgetExceededCounter := self meter
		                               counterNamed: 'mcp.tool.output_budget.exceeded'
		                               unit: '1'
		                               description: 'MCP tool calls exceeding output budget'.
	^ outputBudgetExceededCounter
]

{ #category : 'private - budgets' }
MCPOpenTelemetryObservabilityBackend >> outputBudgetExplanationForByteCount: byteCount [

	byteCount <= self outputBudgetBytes ifTrue: [ ^ '' ].
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Output ';
				  print: byteCount;
				  nextPutAll: ' bytes exceeds budget ';
				  print: self outputBudgetBytes;
				  nextPutAll: ' bytes; consider pagination, handles, or summary-first output' ]
]

{ #category : 'private - instruments' }
MCPOpenTelemetryObservabilityBackend >> outputSizeHistogram [

	outputSizeHistogram ifNotNil: [ ^ outputSizeHistogram ].
	outputSizeHistogram := self meter histogramNamed: 'mcp.tool.output.size' unit: 'By' description: 'MCP tool-call output size'.
	^ outputSizeHistogram
]

{ #category : 'private - metrics' }
MCPOpenTelemetryObservabilityBackend >> recordMetricsForRecord: aRecord attributes: attributes [

	self callCounter add: 1 attributes: attributes.
	self durationHistogram record: aRecord durationMilliseconds attributes: attributes.
	self inputSizeHistogram record: aRecord inputByteCount attributes: attributes.
	self outputSizeHistogram record: aRecord outputByteCount attributes: attributes.
	aRecord outputBudgetExceeded ifTrue: [ self outputBudgetExceededCounter add: 1 attributes: attributes ].
	aRecord status = 'error' ifTrue: [
		self errorCounter add: 1 attributes: (self errorAttributesForRecord: aRecord baseAttributes: attributes) ]
]

{ #category : 'private - budgets' }
MCPOpenTelemetryObservabilityBackend >> recordOutputBudgetFor: aRecord result: aToolResult error: anError [

	| byteCount explanation |
	byteCount := self sizeInBytesForToolResult: aToolResult error: anError.
	explanation := self outputBudgetExplanationForByteCount: byteCount.
	aRecord outputByteCount: byteCount.
	aRecord approximateOutputTokenCount: byteCount + 3 // 4.
	aRecord outputBudgetBytes: self outputBudgetBytes.
	aRecord outputBudgetExceeded: explanation isNotEmpty.
	aRecord outputBudgetExplanation: explanation
]

{ #category : 'recording' }
MCPOpenTelemetryObservabilityBackend >> recordSessionEndFor: anMCP [

	self emitEventNamed: 'mcp.session.end' body: 'MCP session ended'.
	self forceFlush
]

{ #category : 'recording' }
MCPOpenTelemetryObservabilityBackend >> recordSessionStartFor: anMCP [

	self emitEventNamed: 'mcp.session.start' body: 'MCP session started'
]

{ #category : 'recording' }
MCPOpenTelemetryObservabilityBackend >> recordToolCallFinish: aRecord result: aToolResult error: anError [

	| attributes finishedAt span |
	aRecord ifNil: [ ^ nil ].
	span := self recordsById removeKey: aRecord id ifAbsent: [ nil ].
	self enabled ifFalse: [
			span ifNotNil: [ span end: DateAndTime now ].
			aRecord inputObject: nil.
			^ aRecord ].
	finishedAt := DateAndTime now.
	self
		finishRecord: aRecord
		result: aToolResult
		error: anError
		at: finishedAt.
	attributes := self attributesForRecord: aRecord.
	self recordMetricsForRecord: aRecord attributes: attributes.
	self
		endSpan: span
		withRecord: aRecord
		error: anError
		at: finishedAt.
	^ aRecord
]

{ #category : 'recording' }
MCPOpenTelemetryObservabilityBackend >> recordToolCallStart: aToolName input: inputObject dispatchPath: dispatchPath context: contextDictionary [

	| attributes record span |
	self enabled ifFalse: [ ^ nil ].
	record := MCPToolCallRecord id: self nextCallId toolName: aToolName asString startedAt: DateAndTime now.
	record inputObject: inputObject.
	record inputByteCount: (inputObject ifNil: [ 0 ] ifNotNil: [ self sizeInBytesForObject: inputObject ]).
	record dispatchPath: dispatchPath asString.
	attributes := {
		              ('tool.name' -> record toolName).
		              ('mcp.dispatch_path' -> record dispatchPath) }.
	span := (self tracer spanBuilderNamed: 'mcp.tool_call')
		        attributes: attributes;
		        startSpan.
	self recordsById at: record id put: span.
	^ record
]

{ #category : 'private' }
MCPOpenTelemetryObservabilityBackend >> recordsById [

	recordsById ifNotNil: [ ^ recordsById ].
	recordsById := Dictionary new.
	^ recordsById
]

{ #category : 'actions' }
MCPOpenTelemetryObservabilityBackend >> shutdown [

	self forceFlush
]

{ #category : 'private' }
MCPOpenTelemetryObservabilityBackend >> sizeInBytesForObject: anObject [

	| jsonString |
	anObject ifNil: [ ^ 0 ].
	jsonString := [ STONJSON toString: anObject ]
		              on: Error
		              do: [ :ignored | anObject asString ].
	^ jsonString utf8Encoded size
]

{ #category : 'private' }
MCPOpenTelemetryObservabilityBackend >> sizeInBytesForToolResult: aToolResult error: anError [

	aToolResult ifNotNil: [ ^ self sizeInBytesForObject: aToolResult asJRPCJSON ].
	anError ifNil: [ ^ 0 ].
	^ self sizeInBytesForObject: {
			  (#errorClass -> anError class name asString).
			  (#message -> (anError messageText ifNil: [ anError asString ])) } asDictionary
]

{ #category : 'private' }
MCPOpenTelemetryObservabilityBackend >> statusForResult: aToolResult error: anError [

	anError ifNotNil: [ ^ 'error' ].
	aToolResult ifNil: [ ^ 'error' ].
	^ aToolResult isError
		  ifTrue: [ 'error' ]
		  ifFalse: [ 'ok' ]
]

{ #category : 'displaying' }
MCPOpenTelemetryObservabilityBackend >> statusText [

	^ 'Observability exported through OpenTelemetry'
]

{ #category : 'accessing' }
MCPOpenTelemetryObservabilityBackend >> tracer [

	tracer ifNotNil: [ ^ tracer ].
	tracer := OTTracerProvider current tracerNamed: 'mcp-pharo'.
	^ tracer
]

{ #category : 'private' }
MCPOpenTelemetryObservabilityBackend >> updateEventKindsForRecord: aRecord [

	| kinds |
	kinds := OrderedCollection new.
	aRecord status = 'error' ifTrue: [ kinds add: 'error' ].
	aRecord outputBudgetExceeded ifTrue: [ kinds add: 'output_budget_exceeded' ].
	aRecord eventKinds: kinds asArray
]
