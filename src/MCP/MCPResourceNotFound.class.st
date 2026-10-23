"
I am raised when resources/read names a URI no registered resource or resource template answers for.

The spec gives resource-not-found its own JSON-RPC code, -32002, rather than folding it into invalid params, and asks for the URI in the error data so a client can say which one failed.
"
Class {
	#name : 'MCPResourceNotFound',
	#superclass : 'JRPCError',
	#instVars : [
		'uri'
	],
	#category : 'MCP-Errors',
	#package : 'MCP',
	#tag : 'Errors'
}

{ #category : 'accessing' }
MCPResourceNotFound class >> errorCode [

	^ -32002
]

{ #category : 'instance creation' }
MCPResourceNotFound class >> signalForUri: aUri [

	^ self new
		  uri: aUri;
		  signal: 'Resource not found: ' , aUri asString
]

{ #category : 'converting' }
MCPResourceNotFound >> asJRPCResponseWithId: anInteger [

	^ JRPCErrorResponseObject
		  id: anInteger
		  error: (JRPCErrorObject
				   code: self class errorCode
				   message: 'Resource not found'
				   data: { (#uri -> self uri asString) } asDictionary)
]

{ #category : 'accessing' }
MCPResourceNotFound >> uri [

	^ uri
]

{ #category : 'accessing' }
MCPResourceNotFound >> uri: anObject [

	uri := anObject
]
