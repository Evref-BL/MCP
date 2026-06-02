"
Configures which public MCP-Pharo tools are advertised directly through tools/list. Public tools not listed as static remain discoverable through the tool catalog.
"
Class {
	#name : 'MCPToolExposurePolicy',
	#superclass : 'Object',
	#instVars : [
		'staticToolNames'
	],
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'instance creation' }
MCPToolExposurePolicy class >> allStatic [

	^ self staticToolNames: MCPToolRegistry publicToolNames
]

{ #category : 'instance creation' }
MCPToolExposurePolicy class >> default [

	^ self staticToolNames: MCPToolRegistry defaultStaticToolNames
]

{ #category : 'instance creation' }
MCPToolExposurePolicy class >> staticToolNames: aCollection [

	^ self new
		  staticToolNames: aCollection;
		  yourself
]

{ #category : 'tools' }
MCPToolExposurePolicy >> exposureForTool: aTool [

	^ (self isStaticTool: aTool name)
		  ifTrue: [ 'static' ]
		  ifFalse: [ 'discoverable' ]
]

{ #category : 'testing' }
MCPToolExposurePolicy >> isStaticTool: aToolName [

	^ self staticToolNames includes: aToolName asString
]

{ #category : 'accessing' }
MCPToolExposurePolicy >> staticToolNames [

	^ staticToolNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPToolExposurePolicy >> staticToolNames: aCollection [

	| normalized unknown |
	normalized := aCollection collect: [ :each | each asString ].
	unknown := normalized reject: [ :each |
		           MCPToolRegistry includesToolNamed: each ].
	unknown ifNotEmpty: [
			Error signal: 'Unknown MCP tool(s) in exposure policy: '
				, unknown asArray printString ].
	staticToolNames := normalized asOrderedCollection
]
