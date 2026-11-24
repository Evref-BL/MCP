"
The span context of the parent of a MCPOcelRecordedSpan: only its span id is known.
"
Class {
	#name : 'MCPOcelRecordedSpanContext',
	#superclass : 'Object',
	#instVars : [
		'spanId'
	],
	#category : 'MCP-OpenTelemetry',
	#package : 'MCP-OpenTelemetry'
}

{ #category : 'accessing' }
MCPOcelRecordedSpanContext >> spanId [

	^ spanId
]

{ #category : 'accessing' }
MCPOcelRecordedSpanContext >> spanId: anId [

	spanId := anId
]
