"
Tests for the OpenTelemetry observability backend.

Each test runs against its own tracer, meter and logger providers so nothing reaches the providers the image is configured with, and so the spans and measurements the backend emits can be read back. The global providers are restored afterwards.
"
Class {
	#name : 'MCPOpenTelemetryObservabilityBackendTest',
	#superclass : 'TestCase',
	#instVars : [
		'backend',
		'exporter',
		'loggerProvider',
		'meterProvider',
		'metricReader',
		'previousLoggerProvider',
		'previousMeterProvider',
		'previousTracerProvider',
		'tracerProvider',
		'measurements'
	],
	#category : 'MCP-OpenTelemetry-Tests',
	#package : 'MCP-OpenTelemetry-Tests'
}

{ #category : 'private' }
MCPOpenTelemetryObservabilityBackendTest >> attributeNamed: aName in: aSnapshot [

	^ aSnapshot attributes at: aName ifAbsent: [ nil ]
]

{ #category : 'private' }
MCPOpenTelemetryObservabilityBackendTest >> errorToolResult [

	^ MCPStructureErrorToolResult
		  content: { {
				  (#type -> 'text').
				  (#text -> 'boom') } asDictionary }
		  structuredContent: { (#error -> {
				   (#errorCode -> 'repositoryNotFound').
				   (#errorClass -> 'MCPCommandError') } asDictionary) } asDictionary
]

{ #category : 'private' }
MCPOpenTelemetryObservabilityBackendTest >> measurementNamed: aName [

	^ self measurements detect: [ :each | each instrument name = aName ] ifNone: [ nil ]
]

{ #category : 'private' }
MCPOpenTelemetryObservabilityBackendTest >> measurements [
	"Collected once, since a reader hands its measurements over on collection."

	measurements ifNotNil: [ ^ measurements ].
	measurements := metricReader collect.
	^ measurements
]

{ #category : 'running' }
MCPOpenTelemetryObservabilityBackendTest >> setUp [

	super setUp.
	previousTracerProvider := OTTracerProvider current.
	previousMeterProvider := OTMeterProvider current.
	previousLoggerProvider := OTLoggerProvider current.
	exporter := MCPOpenTelemetryRecordingSpanExporter new.
	metricReader := OTInMemoryMetricReader new.
	tracerProvider := OTTracerProvider new
		                  addSpanProcessor: (OTSimpleSpanProcessor new exporter: exporter);
		                  yourself.
	meterProvider := OTMeterProvider new
		                 addMetricReader: metricReader;
		                 yourself.
	loggerProvider := OTLoggerProvider new.
	OTTracerProvider current: tracerProvider.
	OTMeterProvider current: meterProvider.
	OTLoggerProvider current: loggerProvider.
	backend := MCPOpenTelemetryObservabilityBackend new
]

{ #category : 'private' }
MCPOpenTelemetryObservabilityBackendTest >> startToolCall [

	^ backend
		  recordToolCallStart: #method_compile
		  input: { (#class -> 'Object') } asDictionary
		  dispatchPath: 'tools/call'
		  context: Dictionary new
]

{ #category : 'private' }
MCPOpenTelemetryObservabilityBackendTest >> successToolResult [

	^ MCPStructureCallToolResult content: { {
			  (#type -> 'text').
			  (#text -> 'ok') } asDictionary }
]

{ #category : 'running' }
MCPOpenTelemetryObservabilityBackendTest >> tearDown [

	{
		tracerProvider.
		meterProvider.
		loggerProvider } do: [ :each |
			each ifNotNil: [
					[ each shutdown ]
						on: Error
						do: [ :ignored | nil ] ] ].
	OTTracerProvider current: previousTracerProvider.
	OTMeterProvider current: previousMeterProvider.
	OTLoggerProvider current: previousLoggerProvider.
	super tearDown
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testBackendIsNotTheNoopOne [

	self deny: backend isNoop.
	self assert: backend statusText equals: 'Observability exported through OpenTelemetry'
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testDisabledBackendStartsNoCallAndExportsNothing [

	backend disable.
	self deny: backend enabled.
	self assert: self startToolCall isNil.
	self assert: exporter snapshots isEmpty
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testFailedToolCallCountsAnErrorMetricCarryingTheErrorDetails [

	| attributes record |
	record := self startToolCall.
	backend recordToolCallFinish: record result: self errorToolResult error: nil.
	self deny: (self measurementNamed: 'mcp.tool.errors') isNil.
	attributes := (self measurementNamed: 'mcp.tool.errors') attributes.
	self assert: (attributes at: 'mcp.error.code' ifAbsent: [ nil ]) equals: 'repositoryNotFound'.
	self assert: (attributes at: 'error.type' ifAbsent: [ nil ]) equals: 'MCPCommandError'
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testFailedToolCallMarksTheSpanAsAnError [

	| record snapshot |
	record := self startToolCall.
	backend recordToolCallFinish: record result: self errorToolResult error: nil.
	snapshot := exporter onlySnapshot.
	self assert: snapshot status equals: OTSpan error.
	self assert: (self attributeNamed: 'mcp.status' in: snapshot) equals: 'error'.
	self assert: (self attributeNamed: 'mcp.error.code' in: snapshot) equals: 'repositoryNotFound'.
	self assert: (self attributeNamed: 'error.type' in: snapshot) equals: 'MCPCommandError'.
	self assert: (self attributeNamed: 'mcp.error.kind' in: snapshot) equals: 'domain'.
	self assert: record eventKinds equals: #( 'error' )
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testOutputBeyondTheBudgetIsFlaggedOnTheSpanAndTheRecord [

	| record snapshot |
	backend outputBudgetBytes: 1.
	record := self startToolCall.
	backend recordToolCallFinish: record result: self successToolResult error: nil.
	snapshot := exporter onlySnapshot.
	self assert: (self attributeNamed: 'mcp.output_budget.exceeded' in: snapshot).
	self assert: record outputBudgetExceeded.
	self assert: record outputBudgetBytes equals: 1.
	self assert: (record outputBudgetExplanation includesSubstring: 'exceeds budget 1 bytes').
	self assert: record eventKinds equals: #( 'output_budget_exceeded' ).
	self assert: (snapshot events anySatisfy: [ :each | each name = 'mcp.output_budget_exceeded' ])
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testOutputBudgetExplanationNamesTheBudgetOnlyWhenExceeded [

	backend outputBudgetBytes: 100.
	self assert: (backend outputBudgetExplanationForByteCount: 100) isEmpty.
	self
		assert: (backend outputBudgetExplanationForByteCount: 101)
		equals: 'Output 101 bytes exceeds budget 100 bytes; consider pagination, handles, or summary-first output'
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testSessionLifecycleGoesThroughTheLogRecordBuilderAndFlushes [
	"The session events build a log record and force a flush on all three
	providers, so this fails if any of that surface moves."

	backend recordSessionStartFor: nil.
	backend recordSessionEndFor: nil.
	self assert: exporter snapshots isEmpty description: 'Session events are logs, not spans.'
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testStatusDistinguishesErrorsFromResults [

	self assert: (backend statusForResult: self successToolResult error: nil) equals: 'ok'.
	self assert: (backend statusForResult: self errorToolResult error: nil) equals: 'error'.
	self assert: (backend statusForResult: nil error: nil) equals: 'error'.
	self assert: (backend statusForResult: self successToolResult error: Error new) equals: 'error'
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testToolCallExportsASpanDescribingTheCall [

	| record snapshot |
	record := self startToolCall.
	backend recordToolCallFinish: record result: self successToolResult error: nil.
	snapshot := exporter onlySnapshot.
	self assert: snapshot name equals: 'mcp.tool_call'.
	self assert: snapshot status equals: OTSpan ok.
	self assert: (self attributeNamed: 'mcp.call.id' in: snapshot) equals: record id.
	self assert: (self attributeNamed: 'mcp.tool.name' in: snapshot) equals: 'method_compile'.
	self assert: (self attributeNamed: 'mcp.dispatch_path' in: snapshot) equals: 'tools/call'.
	self assert: (self attributeNamed: 'mcp.status' in: snapshot) equals: 'ok'.
	self deny: (self attributeNamed: 'mcp.output_budget.exceeded' in: snapshot).
	self assert: (self attributeNamed: 'mcp.input.bytes' in: snapshot) > 0
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testToolCallRecordsCallDurationAndSizeMetrics [

	| record |
	record := self startToolCall.
	backend recordToolCallFinish: record result: self successToolResult error: nil.
	#( 'mcp.tool.calls' 'mcp.tool.duration' 'mcp.tool.input.size' 'mcp.tool.output.size' ) do: [ :name |
		self deny: (self measurementNamed: name) isNil description: 'The backend should have recorded ' , name ].
	self assert: (self measurementNamed: 'mcp.tool.calls') value equals: 1.
	self assert: (self measurementNamed: 'mcp.tool.errors') isNil description: 'A successful call must not count as an error.'
]
