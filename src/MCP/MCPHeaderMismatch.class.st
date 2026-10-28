"
I am raised when a modern request's HTTP headers do not agree with its body.

The 2026-07-28 revision mirrors selected body fields into headers so that load balancers, gateways and observability tooling can route and inspect a request without parsing it. That only holds if the two always agree: a proxy acting on the header while the server acts on the body is the vulnerability the rule exists to close. So a header that is missing, malformed, or different from the body is refused rather than reconciled.
"
Class {
	#name : 'MCPHeaderMismatch',
	#superclass : 'JRPCError',
	#instVars : [
		'detail'
	],
	#category : 'MCP-Errors',
	#package : 'MCP',
	#tag : 'Errors'
}

{ #category : 'accessing' }
MCPHeaderMismatch class >> errorCode [

	^ -32020
]

{ #category : 'instance creation' }
MCPHeaderMismatch class >> signalMissing: aHeaderName [

	^ self signalWithDetail:
		  (String streamContents: [ :stream | stream << 'Header mismatch: ' << aHeaderName << ' is required and was not sent.' ])
]

{ #category : 'instance creation' }
MCPHeaderMismatch class >> signalName: aHeaderName header: aHeaderValue doesNotMatch: aBodyValue [

	^ self signalWithDetail: (String streamContents: [ :stream |
				   stream << 'Header mismatch: ' << aHeaderName << ' header value ' << aHeaderValue printString
				   << ' does not match body value ' << aBodyValue printString << '.' ])
]

{ #category : 'instance creation' }
MCPHeaderMismatch class >> signalWithDetail: aDescription [

	^ self new
		  detail: aDescription;
		  signal: aDescription
]

{ #category : 'converting' }
MCPHeaderMismatch >> asJRPCResponseWithId: anInteger [

	^ JRPCErrorResponseObject
		  id: anInteger
		  error: (JRPCErrorObject code: self class errorCode message: self detail)
]

{ #category : 'accessing' }
MCPHeaderMismatch >> detail [

	^ detail
]

{ #category : 'accessing' }
MCPHeaderMismatch >> detail: anObject [

	detail := anObject
]
