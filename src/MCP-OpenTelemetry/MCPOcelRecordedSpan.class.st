"
A span read back from a file, with what a MCPOcelLog reads of a span snapshot: so that traces exported from an image can be kept, shared and loaded into the call graph of another.
"
Class {
	#name : 'MCPOcelRecordedSpan',
	#superclass : 'Object',
	#instVars : [
		'name',
		'spanId',
		'parentSpanId',
		'startTime',
		'endTime',
		'attributes',
		'status'
	],
	#category : 'MCP-OpenTelemetry',
	#package : 'MCP-OpenTelemetry'
}

{ #category : 'accessing' }
MCPOcelRecordedSpan >> attributes [

	^ attributes
]

{ #category : 'accessing' }
MCPOcelRecordedSpan >> endTime [

	^ endTime
]

{ #category : 'accessing' }
MCPOcelRecordedSpan >> name [

	^ name
]

{ #category : 'initialization' }
MCPOcelRecordedSpan >> name: aString spanId: anId parentSpanId: aParentId startTime: aStart endTime: anEnd status: aStatus attributes: aDictionary [

	name := aString.
	spanId := anId.
	parentSpanId := aParentId.
	startTime := aStart.
	endTime := anEnd.
	status := aStatus.
	attributes := aDictionary
]

{ #category : 'accessing' }
MCPOcelRecordedSpan >> parentSpanContext [
	"nil for a root call."

	^ parentSpanId ifNotNil: [ :id |
			  MCPOcelRecordedSpanContext new
				  spanId: id;
				  yourself ]
]

{ #category : 'accessing' }
MCPOcelRecordedSpan >> spanId [

	^ spanId
]

{ #category : 'accessing' }
MCPOcelRecordedSpan >> startTime [

	^ startTime
]

{ #category : 'accessing' }
MCPOcelRecordedSpan >> status [

	^ status
]
