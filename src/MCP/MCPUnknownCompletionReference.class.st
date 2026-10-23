"
I am raised when completion/complete names something the server cannot complete.

That is an unknown prompt name, an unknown resource template URI, or a reference type the protocol does not define. The spec answers all of them as invalid params.
"
Class {
	#name : 'MCPUnknownCompletionReference',
	#superclass : 'JRPCInvalidParameters',
	#instVars : [
		'reference'
	],
	#category : 'MCP-Errors',
	#package : 'MCP',
	#tag : 'Errors'
}

{ #category : 'instance creation' }
MCPUnknownCompletionReference class >> signalFor: aReference [

	^ self new
		  reference: aReference;
		  signal: 'Cannot complete reference: ' , aReference printString
]

{ #category : 'converting' }
MCPUnknownCompletionReference >> asJRPCResponseWithId: anInteger [

	| response |
	response := super asJRPCResponseWithId: anInteger.
	response error data: { (#ref -> self reference printString) } asDictionary.
	^ response
]

{ #category : 'accessing' }
MCPUnknownCompletionReference >> reference [

	^ reference
]

{ #category : 'accessing' }
MCPUnknownCompletionReference >> reference: anObject [

	reference := anObject
]
