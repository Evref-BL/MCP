"
MCP protocol structure returned by initialize.

It carries protocol version, advertised server capabilities, and serverInfo metadata.
"
Class {
	#name : 'MCPStructureInitialize',
	#superclass : 'Object',
	#instVars : [
		'protocolVersion',
		'capabilities',
		'serverInfo'
	],
	#category : 'MCP-Structure',
	#package : 'MCP',
	#tag : 'Structure'
}

{ #category : 'accessing' }
MCPStructureInitialize >> asJRPCJSON [

	^ {
		  (#capabilities -> self capabilities asJRPCJSON).
		  (#protocolVersion -> self protocolVersion asJRPCJSON).
		  (#serverInfo -> self serverInfo asJRPCJSON) } asDictionary
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
