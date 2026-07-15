"
Tests MCP HTTP response behavior without opening a network listener.
"
Class {
	#name : 'MCPHTTPServerTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Server',
	#package : 'MCP-Tests',
	#tag : 'Server'
}

{ #category : 'private' }
MCPHTTPServerTest >> responseForMethod: method [

	| request |
	request := ZnRequest method: method url: ZnUrl new.
	^ MCPHTTPServer new answer: request with: ZnResponse new
]

{ #category : 'tests' }
MCPHTTPServerTest >> testGetResponseIsExplicitlyEmpty [

	| response |
	response := self responseForMethod: #GET.

	self assert: response code equals: 405.
	self assert: (response headers at: #'Content-Length') equals: '0'
]

{ #category : 'tests' }
MCPHTTPServerTest >> testUnsupportedMethodResponseIsExplicitlyEmpty [

	| response |
	response := self responseForMethod: #DELETE.

	self assert: response code equals: 405.
	self assert: (response headers at: #'Content-Length') equals: '0'
]
