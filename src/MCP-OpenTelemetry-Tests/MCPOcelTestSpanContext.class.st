"
The span context of a MCPOcelTestSpan's parent: only the id of the parent's span, which is all a MCPOcelLog reads.
"
Class {
	#name : 'MCPOcelTestSpanContext',
	#superclass : 'Object',
	#instVars : [
		'spanId'
	],
	#category : 'MCP-OpenTelemetry-Tests',
	#package : 'MCP-OpenTelemetry-Tests'
}

{ #category : 'accessing' }
MCPOcelTestSpanContext >> spanId [

	^ spanId
]

{ #category : 'accessing' }
MCPOcelTestSpanContext >> spanId: aString [

	spanId := aString
]
