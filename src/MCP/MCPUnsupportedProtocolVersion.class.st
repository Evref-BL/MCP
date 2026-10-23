"
I am raised when a request names a protocol version this server does not implement.

The 2026-07-28 revision has no negotiation handshake: every request declares its own version and the server accepts or rejects it on its own. A version the server does not implement is answered with this error, carrying the versions it does support so the client can retry with one of them.

Legacy requests, the ones that open with initialize, never reach me: under those revisions the server answers a version it supports and lets the client decide, which is what onInitialize: does.
"
Class {
	#name : 'MCPUnsupportedProtocolVersion',
	#superclass : 'JRPCError',
	#instVars : [
		'requestedVersion'
	],
	#category : 'MCP-Errors',
	#package : 'MCP',
	#tag : 'Errors'
}

{ #category : 'accessing' }
MCPUnsupportedProtocolVersion class >> errorCode [
	"Allocated to the specification from the JSON-RPC server-error range."

	^ -32022
]

{ #category : 'instance creation' }
MCPUnsupportedProtocolVersion class >> signalRequested: aVersion [

	^ self new
		  requestedVersion: aVersion;
		  signal: 'Unsupported protocol version: ' , aVersion asString
]

{ #category : 'converting' }
MCPUnsupportedProtocolVersion >> asJRPCResponseWithId: anInteger [

	^ JRPCErrorResponseObject
		  id: anInteger
		  error: (JRPCErrorObject
				   code: self class errorCode
				   message: 'Unsupported protocol version'
				   data: {
						   (#supported -> MCP supportedProtocolVersions).
						   (#requested -> self requestedVersion asString) } asDictionary)
]

{ #category : 'accessing' }
MCPUnsupportedProtocolVersion >> requestedVersion [

	^ requestedVersion
]

{ #category : 'accessing' }
MCPUnsupportedProtocolVersion >> requestedVersion: anObject [

	requestedVersion := anObject
]
