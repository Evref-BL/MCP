"
TinyLogger file sink that writes one JSON record per line.
"
Class {
	#name : 'MCPJSONLineFileTinyLogger',
	#superclass : 'TinyFileLogger',
	#category : 'MCP-Monitoring',
	#package : 'MCP',
	#tag : 'Monitoring'
}

{ #category : 'accessing' }
MCPJSONLineFileTinyLogger class >> kind [

	^ 'mcpJSONLineFile'
]

{ #category : 'logging' }
MCPJSONLineFileTinyLogger >> record: aString [

	self fileStreamDo: [ :stream |
			stream
				nextPutAll: aString;
				nextPutAll: self newLine ]
]
