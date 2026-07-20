"
Pure visibility policy for MCP tool registrations. It applies tool defaults unless configured with an explicit static tool-name set or to expose every registration statically. Registry lookup and configuration validation remain the responsibility of MCPToolRegistry.
"
Class {
	#name : 'MCPToolExposurePolicy',
	#superclass : 'Object',
	#instVars : [
		'staticToolNames',
		'exposeAllTools'
	],
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'instance creation' }
MCPToolExposurePolicy class >> allStatic [

	^ self new
		  exposeAllTools;
		  yourself
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

{ #category : 'accessing' }
MCPToolExposurePolicy >> explicitStaticToolNames [

	^ staticToolNames
]

{ #category : 'configuration' }
MCPToolExposurePolicy >> exposeAllTools [

	exposeAllTools := true.
	staticToolNames := nil
]

{ #category : 'testing' }
MCPToolExposurePolicy >> exposesAllTools [

	^ exposeAllTools
]

{ #category : 'accessing' }
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
MCPToolExposurePolicy >> initialize [

	super initialize.
	exposeAllTools := false
]

{ #category : 'testing' }
MCPToolExposurePolicy >> isStaticToolRegistration: aToolRegistration [

	self exposesAllTools ifTrue: [ ^ true ].
	self hasExplicitStaticToolNames ifTrue: [ ^ staticToolNames includes: aToolRegistration name ].
	^ aToolRegistration isStaticByDefault
]

{ #category : 'accessing' }
MCPToolExposurePolicy >> staticToolNames: aCollection [

	staticToolNames := (aCollection collect: [ :each | each asString ]) asArray.
	exposeAllTools := false
]
