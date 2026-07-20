"
Per-server visibility policy for one MCPToolRegistry. By default it respects each tool's default exposure; users can replace the static tool-name set without changing tool metadata or another registry.
"
Class {
	#name : 'MCPToolExposurePolicy',
	#superclass : 'Object',
	#instVars : [
		'staticToolNames',
		'toolRegistry'
	],
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'instance creation' }
MCPToolExposurePolicy class >> allStatic [

	| policy |
	policy := self default.
	policy staticToolNames: policy toolRegistry publicToolNames.
	^ policy
]

{ #category : 'instance creation' }
MCPToolExposurePolicy class >> default [

	^ self forRegistry: MCPToolRegistry new
]

{ #category : 'instance creation' }
MCPToolExposurePolicy class >> forRegistry: aToolRegistry [

	^ self new initializeToolRegistry: aToolRegistry
]

{ #category : 'instance creation' }
MCPToolExposurePolicy class >> staticToolNames: aCollection [

	^ self default
		  staticToolNames: aCollection;
		  yourself
]

{ #category : 'tools' }
MCPToolExposurePolicy >> exposureForTool: aTool [

	^ self exposureForToolRegistration: (self toolRegistry registrationForTool: aTool ifAbsent: [ ^ 'discoverable' ])
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

{ #category : 'initialization' }
MCPToolExposurePolicy >> initializeToolRegistry: aToolRegistry [

	toolRegistry := aToolRegistry
]

{ #category : 'testing' }
MCPToolExposurePolicy >> isStaticTool: aToolName [

	^ self isStaticToolRegistration: (self toolRegistry registrationNamed: aToolName ifAbsent: [ ^ false ])
]

{ #category : 'testing' }
MCPToolExposurePolicy >> isStaticToolRegistration: aToolRegistration [

	self hasExplicitStaticToolNames ifTrue: [
		^ staticToolNames includes: aToolRegistration name ].
	^ aToolRegistration isStaticByDefault
]

{ #category : 'accessing' }
MCPToolExposurePolicy >> staticToolNames [

	^ staticToolNames ifNil: [ self toolRegistry staticToolNames ]
]

{ #category : 'accessing' }
MCPToolExposurePolicy >> staticToolNames: aCollection [

	| normalized unknown |
	normalized := (aCollection collect: [ :each | each asString ]) asArray.
	unknown := normalized reject: [ :each | self toolRegistry includesToolNamed: each ].
	unknown ifNotEmpty: [ Error signal: 'Unknown MCP tool(s) in exposure policy: ' , unknown printString ].
	staticToolNames := normalized
]

{ #category : 'accessing' }
MCPToolExposurePolicy >> toolRegistry [

	^ toolRegistry ifNil: [ toolRegistry := MCPToolRegistry new ]
]
