"
A span processor whose flush waits until it is opened, for at most ten seconds: a collector that does not answer.
"
Class {
	#name : 'MCPOpenTelemetryHangingSpanProcessor',
	#superclass : 'OTSimpleSpanProcessor',
	#instVars : [
		'gate',
		'entered'
	],
	#category : 'MCP-OpenTelemetry-Tests',
	#package : 'MCP-OpenTelemetry-Tests'
}

{ #category : 'flushing' }
MCPOpenTelemetryHangingSpanProcessor >> forceFlush [

	entered := true.
	gate waitTimeoutSeconds: 10.
	^ super forceFlush
]

{ #category : 'initialization' }
MCPOpenTelemetryHangingSpanProcessor >> initialize [

	super initialize.
	gate := Semaphore new.
	entered := false
]

{ #category : 'accessing' }
MCPOpenTelemetryHangingSpanProcessor >> open [

	gate signal
]

{ #category : 'testing' }
MCPOpenTelemetryHangingSpanProcessor >> wasEntered [

	^ entered
]
