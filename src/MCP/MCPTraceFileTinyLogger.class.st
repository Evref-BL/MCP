"
TinyLogger file sink that writes one raw JSON trace record per line.
"
Class {
	#name : 'MCPTraceFileTinyLogger',
	#superclass : 'TinyFileLogger',
	#category : 'MCP-Monitoring',
	#package : 'MCP',
	#tag : 'Monitoring'
}

{ #category : 'accessing' }
MCPTraceFileTinyLogger class >> kind [

	^ 'mcpTraceFile'
]

{ #category : 'logging' }
MCPTraceFileTinyLogger >> record: aString [

	self fileStreamDo: [ :stream |
			stream
				nextPutAll: aString;
				nextPutAll: self newLine ]
]
