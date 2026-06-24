"
I decide which registered MCP tools are advertised directly through tools/list for one MCP server instance.

The default policy follows each tool registration's default exposure. Supplying staticToolNames: switches to an explicit static surface; all other registered tools remain discoverable through tool_call.
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

	^ self new
]

{ #category : 'instance creation' }
MCPToolExposurePolicy class >> staticToolNames: aCollection [

	^ self new
		  staticToolNames: aCollection;
		  yourself
]

{ #category : 'tools' }
MCPToolExposurePolicy >> exposureForTool: aTool [

	^ self exposureForToolRegistration: (MCPToolRegistry
			   registrationForTool: aTool
			   ifAbsent: [ ^ 'discoverable' ])
]

{ #category : 'tools' }
MCPToolExposurePolicy >> exposureForToolRegistration: aToolRegistration [

	^ (self isStaticToolRegistration: aToolRegistration)
		  ifTrue: [ 'static' ]
		  ifFalse: [ 'discoverable' ]
]

{ #category : 'testing' }
MCPToolExposurePolicy >> hasExplicitStaticToolNames [

	^ staticToolNames notNil
]

{ #category : 'testing' }
MCPToolExposurePolicy >> isStaticTool: aToolName [

	^ self isStaticToolRegistration:
		  (MCPToolRegistry
			   registrationNamed: aToolName
			   ifAbsent: [ ^ false ])
]

{ #category : 'testing' }
MCPToolExposurePolicy >> isStaticToolRegistration: aToolRegistration [

	self hasExplicitStaticToolNames ifTrue: [
		^ staticToolNames includes: aToolRegistration name ].
	^ aToolRegistration isStaticByDefault
]

{ #category : 'accessing' }
MCPToolExposurePolicy >> staticToolNames [

	^ staticToolNames ifNil: [ MCPToolRegistry defaultStaticToolNames ]
]

{ #category : 'accessing' }
MCPToolExposurePolicy >> staticToolNames: aCollection [

	| normalized unknown |
	normalized := (aCollection collect: [ :each | each asString ])
		              asArray.
	unknown := normalized reject: [ :each |
		           MCPToolRegistry includesToolNamed: each ].
	unknown ifNotEmpty: [
			Error signal:
				'Unknown MCP tool(s) in exposure policy: ' , unknown printString ].
	staticToolNames := normalized
]
