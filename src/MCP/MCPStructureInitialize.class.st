"
MCP protocol structure returned by initialize.

It carries protocol version, advertised server capabilities, serverInfo identity, and optional infrastructure metadata.
"
Class {
	#name : 'MCPStructureInitialize',
	#superclass : 'Object',
	#instVars : [
		'protocolVersion',
		'capabilities',
		'serverInfo',
		'metadata'
	],
	#category : 'MCP-Structure',
	#package : 'MCP',
	#tag : 'Structure'
}

{ #category : 'accessing' }
MCPStructureInitialize >> asJRPCJSON [

	| dic |
	dic := {
		       (#capabilities -> self capabilities asJRPCJSON).
		       (#protocolVersion -> self protocolVersion asJRPCJSON).
		       (#serverInfo -> self serverInfo asJRPCJSON) } asDictionary.
	self metadata ifNotNil: [
		dic at: #_meta put: self metadata asJRPCJSON ].
	^ dic
]

{ #category : 'accessing' }
MCPStructureInitialize >> capabilities [

	^ capabilities
]

{ #category : 'accessing' }
MCPStructureInitialize >> capabilities: anObject [

	capabilities := anObject
]

{ #category : 'accessing' }
MCPStructureInitialize >> metadata [

	^ metadata
]

{ #category : 'accessing' }
MCPStructureInitialize >> metadata: anObject [

	metadata := anObject
]

{ #category : 'accessing' }
MCPStructureInitialize >> protocolVersion [

	^ protocolVersion
]

{ #category : 'accessing' }
MCPStructureInitialize >> protocolVersion: anObject [

	protocolVersion := anObject
]

{ #category : 'accessing' }
MCPStructureInitialize >> serverInfo [

	^ serverInfo
]

{ #category : 'accessing' }
MCPStructureInitialize >> serverInfo: anObject [

	serverInfo := anObject
]
