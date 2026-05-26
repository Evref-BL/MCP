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

	^ (self isStaticTool: aTool)
		  ifTrue: [ 'static' ]
		  ifFalse: [ 'discoverable' ]
]

{ #category : 'testing' }
MCPToolExposurePolicy >> isStaticTool: aToolOrName [

	^ self staticToolNames includes: (self toolNameFor: aToolOrName)
]

{ #category : 'accessing' }
MCPToolExposurePolicy >> staticToolNames [

	^ staticToolNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPToolExposurePolicy >> staticToolNames: aCollection [

	| normalized unknown |
	normalized := aCollection collect: [ :each | self toolNameFor: each ].
	unknown := normalized reject: [ :each |
		           MCPToolRegistry includesToolNamed: each ].
	unknown ifNotEmpty: [
			Error signal: 'Unknown MCP tool(s) in exposure policy: '
				, unknown asArray printString ].
	staticToolNames := normalized asOrderedCollection
]

{ #category : 'private' }
MCPToolExposurePolicy >> toolNameFor: aToolOrName [

	(aToolOrName isString or: [ aToolOrName isSymbol ]) ifTrue: [
		^ aToolOrName asString ].
	(aToolOrName isBehavior and: [ aToolOrName inheritsFrom: MCPTool ])
		ifTrue: [ ^ aToolOrName toolName ].
	^ aToolOrName name
]
