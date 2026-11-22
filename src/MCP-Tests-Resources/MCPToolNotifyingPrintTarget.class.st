"
A value whose printing signals a notification that the boundary around a tool call refuses to resume, and prints the answer it got.
"
Class {
	#name : 'MCPToolNotifyingPrintTarget',
	#superclass : 'Object',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'printing' }
MCPToolNotifyingPrintTarget >> printOn: aStream [

	aStream
		nextPutAll: 'printed after ';
		print: MCPToolRefusedNotification signal
]
