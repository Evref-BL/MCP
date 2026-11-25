"
One line of an MCP server's local log: its message, and the record of the tool call it is about, if it is about one. The message is what is shown and exported; the record is what relates the line to the call's metrics and trace, so nothing has to read them back out of the message.
"
Class {
	#name : 'MCPLogEntry',
	#superclass : 'Object',
	#instVars : [
		'message',
		'call'
	],
	#category : 'MCP-Observability',
	#package : 'MCP',
	#tag : 'Observability'
}

{ #category : 'instance creation' }
MCPLogEntry class >> message: aString call: aRecord [

	^ self new setMessage: aString call: aRecord
]

{ #category : 'accessing' }
MCPLogEntry >> call [
	"The MCPToolCallRecord of the call this line is about, or nil for a line about none, such as 'Observability cleared'."

	^ call
]

{ #category : 'accessing' }
MCPLogEntry >> message [

	^ message
]

{ #category : 'printing' }
MCPLogEntry >> printOn: aStream [

	aStream nextPutAll: message
]

{ #category : 'initialization' }
MCPLogEntry >> setMessage: aString call: aRecord [

	message := aString.
	call := aRecord
]

{ #category : 'accessing' }
MCPLogEntry >> toolName [

	^ call ifNotNil: [ :record | record toolName ]
]
