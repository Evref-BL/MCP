"
OpenTelemetry observability backend for MCP.

This class lives in the optional MCP-OpenTelemetry package so MCP core can remain free of OpenTelemetry dependencies.
"
Class {
	#name : 'MCPOpenTelemetryObservabilityBackend',
	#superclass : 'MCPObservabilityBackend',
	#instVars : [
		'enabled',
		'tracer',
		'meter',
		'logger',
		'nextCallId',
		'inputSizeHistogram',
		'outputSizeHistogram',
		'outputBudgetExceededCounter',
		'recordsById',
		'outputBudgetBytes',
		'operationDurationHistogram'
	],
	#category : 'MCP-OpenTelemetry',
	#package : 'MCP-OpenTelemetry'
}

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> argumentNamesIn: inputObject [
	"The names of the arguments a call was given, sorted, without their values."

	inputObject isDictionary ifFalse: [ ^ #(  ) ].
	^ ((inputObject keys collect: [ :each | each asString ] as: Array) select: [ :each | self isReportableName: each ]) sort
]

{ #category : 'private - budgets' }
MCPOpenTelemetryObservabilityBackend >> defaultOutputBudgetBytes [

	^ 32 * 1024
]

{ #category : 'activation' }
MCPOpenTelemetryObservabilityBackend >> disable [

	enabled := false
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
MCPOpenTelemetryObservabilityBackend >> endSpan: span withAttributes: attributes record: aRecord at: finishedAt [
	"Instrumentation leaves a successful span's status unset. A failed one is marked without a description, because the conventions would put the error message there and a message is a value."

	span ifNil: [ ^ nil ].
	attributes do: [ :each | span attributeAt: each key put: each value ].
	aRecord outputBudgetExceeded ifTrue: [ span addEventNamed: 'pharo.mcp.output_budget_exceeded' attributes: #(  ) ].
	aRecord status = 'error' ifTrue: [ span setStatus: OTSpan error description: '' ].
	span end: finishedAt
]

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> errorTypeFor: anError [
	"error.type as the conventions for MCP spell it: the JSON-RPC code of a protocol error, and tool_error for a call answered with a result that reports one."

	(anError isNotNil and: [ anError mcpIsProtocolError ]) ifFalse: [ ^ 'tool_error' ].
	^ [ (anError asJRPCResponseWithId: nil) error code printString ]
		  on: Error
		  do: [ :error | '_OTHER' ]
]

{ #category : 'private - spans' }
MCPOpenTelemetryObservabilityBackend >> finishAttributesFor: aRecord error: anError errorType: errorType [
	"What is known once a call is answered: sizes, and for a failure its kind. An exception is named by its nearest class in Pharo or MCP, and never by its message or stack."

	| attributes |
	attributes := OrderedCollection new.
	attributes
		add: 'pharo.mcp.input.bytes' -> aRecord inputByteCount;
		add: 'pharo.mcp.output.bytes' -> aRecord outputByteCount;
		add: 'pharo.mcp.output.tokens.approx' -> aRecord approximateOutputTokenCount;
		add: 'pharo.mcp.output_budget.exceeded' -> aRecord outputBudgetExceeded.
	errorType ifNil: [ ^ attributes asArray ].
	attributes add: 'error.type' -> errorType.
	aRecord errorKind ifNotEmpty: [ :kind | attributes add: 'pharo.mcp.error.kind' -> kind ].
	(aRecord errorCode isNotEmpty and: [ self isReportableName: aRecord errorCode ]) ifTrue: [
		attributes add: 'pharo.mcp.error.code' -> aRecord errorCode ].
	aRecord schemaViolationCount > 0 ifTrue: [
		attributes add: 'pharo.mcp.error.schema.violation_count' -> aRecord schemaViolationCount ].
	anError ifNotNil: [ attributes add: 'pharo.mcp.exception.type' -> (self reportableClassNameOf: anError class) ].
	^ attributes asArray
]

{ #category : 'private - records' }
MCPOpenTelemetryObservabilityBackend >> finishRecord: aRecord result: aToolResult error: anError at: finishedAt [

	| duration statusString |
	duration := (finishedAt - aRecord startedAt) asMilliSeconds.
	statusString := self statusForResult: aToolResult error: anError.
	aRecord finishAt: finishedAt durationMilliseconds: duration status: statusString.
	self recordErrorDetailsFor: aRecord result: aToolResult error: anError.
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
	inputSizeHistogram := self meter histogramNamed: 'pharo.mcp.tool.input.size' unit: 'By' description: 'MCP tool-call input size'.
	^ inputSizeHistogram
]

{ #category : 'testing' }
MCPOpenTelemetryObservabilityBackend >> isNoop [

	^ false
]

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> isReportableName: aString [
	"A name the caller chose leaves the image only when it reads as an identifier, so a value put where a name belongs is never exported."

	^ aString size <= 64 and: [ aString matchesRegex: '[A-Za-z_][A-Za-z0-9_-]*' ]
]

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> isReportablePackageName: aName [

	^ #( 'Kernel' 'Collections' 'MCP' ) anySatisfy: [ :prefix | aName = prefix or: [ aName beginsWith: prefix , '-' ] ]
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

{ #category : 'private - instruments' }
MCPOpenTelemetryObservabilityBackend >> operationDurationHistogram [

	operationDurationHistogram ifNotNil: [ ^ operationDurationHistogram ].
	operationDurationHistogram := self meter
		                              histogramNamed: 'mcp.server.operation.duration'
		                              unit: 's'
		                              description: 'MCP request duration as observed on the receiver'.
	^ operationDurationHistogram
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
		                               counterNamed: 'pharo.mcp.tool.output_budget.exceeded'
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
	outputSizeHistogram := self meter
		                       histogramNamed: 'pharo.mcp.tool.output.size'
		                       unit: 'By'
		                       description: 'MCP tool-call output size'.
	^ outputSizeHistogram
]

{ #category : 'private - spans' }
MCPOpenTelemetryObservabilityBackend >> parentContextIn: contextDictionary [
	"The caller's trace context, which travels in the request's _meta under the unprefixed W3C keys (SEP-414), or the current context when the request carries none. A malformed one is ignored rather than allowed to fail the call."

	| meta |
	meta := contextDictionary at: #meta ifAbsent: [ nil ].
	(meta isDictionary and: [ meta isNotEmpty ]) ifFalse: [ ^ OpenTelemetry currentContext ].
	^ [ OpenTelemetry textMapPropagator extract: OpenTelemetry currentContext from: meta ]
		  on: Error
		  do: [ :error | OpenTelemetry currentContext ]
]

{ #category : 'private - spans' }
MCPOpenTelemetryObservabilityBackend >> protocolVersionIn: contextDictionary [
	"The protocol version a modern request declares in its _meta; a legacy one declares it only at initialize, which this call does not see."

	| meta |
	meta := contextDictionary at: #meta ifAbsent: [ ^ nil ].
	meta isDictionary ifFalse: [ ^ nil ].
	^ meta at: MCP modernProtocolVersionKey ifAbsent: [ nil ]
]

{ #category : 'private - metrics' }
MCPOpenTelemetryObservabilityBackend >> recordMetricsForRecord: aRecord errorType: errorType [

	| attributes |
	attributes := OrderedCollection new.
	attributes
		add: 'mcp.method.name' -> 'tools/call';
		add: 'gen_ai.tool.name' -> aRecord toolName;
		add: 'gen_ai.operation.name' -> 'execute_tool'.
	errorType ifNotNil: [ attributes add: 'error.type' -> errorType ].
	attributes := attributes asArray.
	self operationDurationHistogram record: aRecord durationMilliseconds / 1000.0 attributes: attributes.
	self inputSizeHistogram record: aRecord inputByteCount attributes: attributes.
	self outputSizeHistogram record: aRecord outputByteCount attributes: attributes.
	aRecord outputBudgetExceeded ifTrue: [ self outputBudgetExceededCounter add: 1 attributes: attributes ]
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

	| errorType finishedAt span |
	^ self withoutFailingTheCall: [
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
			  errorType := aRecord status = 'error'
				               ifTrue: [ self errorTypeFor: anError ]
				               ifFalse: [ nil ].
			  self recordMetricsForRecord: aRecord errorType: errorType.
			  self
				  endSpan: span
				  withAttributes: (self finishAttributesFor: aRecord error: anError errorType: errorType)
				  record: aRecord
				  at: finishedAt.
			  ^ aRecord ]
]

{ #category : 'recording' }
MCPOpenTelemetryObservabilityBackend >> recordToolCallStart: aToolName input: inputObject dispatchPath: dispatchPath context: contextDictionary [

	| record span |
	^ self withoutFailingTheCall: [
			  self enabled ifFalse: [ ^ nil ].
			  record := MCPToolCallRecord id: self nextCallId toolName: aToolName asString startedAt: DateAndTime now.
			  record inputObject: inputObject.
			  record inputByteCount: (inputObject ifNil: [ 0 ] ifNotNil: [ self sizeInBytesForObject: inputObject ]).
			  record dispatchPath: dispatchPath asString.
			  span := (self tracer spanBuilderNamed: 'tools/call ' , record toolName)
				          kind: OTSpan server;
				          inContext: (self parentContextIn: contextDictionary);
				          attributes: (self startAttributesFor: record input: inputObject context: contextDictionary);
				          startSpan.
			  self recordsById at: record id put: span.
			  ^ record ]
]

{ #category : 'private' }
MCPOpenTelemetryObservabilityBackend >> recordsById [

	recordsById ifNotNil: [ ^ recordsById ].
	recordsById := Dictionary new.
	^ recordsById
]

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> reportableClassNameOf: aClass [
	"The nearest class, from aClass up, that Pharo's kernel or collections or MCP defines, so that no class of the user's leaves the image under its own name."

	| class |
	class := aClass.
	[ class isNotNil ] whileTrue: [
			(self isReportablePackageName: class package name) ifTrue: [ ^ class name asString ].
			class := class superclass ].
	^ '_OTHER'
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

{ #category : 'private - spans' }
MCPOpenTelemetryObservabilityBackend >> startAttributesFor: aRecord input: inputObject context: contextDictionary [
	"The attributes known when a call starts, set before the span starts so a sampler sees them. They follow the OpenTelemetry conventions for MCP where those name the fact, and say nothing the caller passed but argument names."

	| attributes tool |
	attributes := OrderedCollection new.
	attributes
		add: 'mcp.method.name' -> 'tools/call';
		add: 'gen_ai.tool.name' -> aRecord toolName;
		add: 'gen_ai.operation.name' -> 'execute_tool';
		add: 'network.transport' -> 'tcp';
		add: 'network.protocol.name' -> 'http';
		add: 'pharo.mcp.dispatch_path' -> aRecord dispatchPath.
	(self protocolVersionIn: contextDictionary) ifNotNil: [ :version | attributes add: 'mcp.protocol.version' -> version ].
	(self argumentNamesIn: inputObject) ifNotEmpty: [ :names | attributes add: 'pharo.mcp.argument.names' -> names ].
	tool := contextDictionary at: #tool ifAbsent: [ nil ].
	(self unknownArgumentNamesIn: inputObject for: tool) ifNotEmpty: [ :names |
		attributes add: 'pharo.mcp.argument.unknown_names' -> names ].
	^ attributes asArray
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

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> unknownArgumentNamesIn: inputObject for: aTool [
	"The argument names a call was given that its tool's schema does not declare: what agents expect a tool to take."

	| known |
	aTool ifNil: [ ^ #(  ) ].
	known := [ aTool inputSchema properties collect: [ :each | each name asString ] as: Set ]
		         on: Error
		         do: [ :error | ^ #(  ) ].
	^ (self argumentNamesIn: inputObject) reject: [ :each | known includes: each ]
]

{ #category : 'private' }
MCPOpenTelemetryObservabilityBackend >> updateEventKindsForRecord: aRecord [

	| kinds |
	kinds := OrderedCollection new.
	aRecord status = 'error' ifTrue: [ kinds add: 'error' ].
	aRecord outputBudgetExceeded ifTrue: [ kinds add: 'output_budget_exceeded' ].
	aRecord eventKinds: kinds asArray
]

{ #category : 'private - recording' }
MCPOpenTelemetryObservabilityBackend >> withoutFailingTheCall: aBlock [
	"Recording is never a reason for a tool call to fail: whatever goes wrong while recording, warnings included, is dropped, and the call goes on unrecorded."

	^ aBlock
		  on: Error , Warning
		  do: [ :exception | exception return: nil ]
]
