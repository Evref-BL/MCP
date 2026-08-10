Class {
	#name : 'MCPMethodSearchImageScopeQueryTestDouble',
	#superclass : 'MCPCompiledMethodScopeQuery',
	#instVars : [
		'behaviors'
	],
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'private - scope' }
MCPMethodSearchImageScopeQueryTestDouble >> allMethods [

	self error: 'Image-scope implementor lookup should use behaviors instead of scanning all methods.'
]

{ #category : 'private - scope' }
MCPMethodSearchImageScopeQueryTestDouble >> allMethodsDo: aBlock [

	self error: 'Image-scope implementor lookup should use behaviors instead of scanning all methods.'
]

{ #category : 'accessing' }
MCPMethodSearchImageScopeQueryTestDouble >> behaviors [

	^ behaviors ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPMethodSearchImageScopeQueryTestDouble >> behaviors: aCollection [

	behaviors := aCollection
]
