"
An event stream that has nothing to wait for before keeping its connection alive, and looks often, so a test sees its keep-alive at once.
"
Class {
	#name : 'MCPEventStreamKeepingAliveAtOnce',
	#superclass : 'MCPEventStream',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'writing' }
MCPEventStreamKeepingAliveAtOnce >> keepAliveInterval [

	^ 0 seconds
]

{ #category : 'writing' }
MCPEventStreamKeepingAliveAtOnce >> pollInterval [

	^ 1 milliSecond
]
