"
Abstract command for tool-catalog operations that need the current exposure policy.
"
Class {
	#name : 'MCPToolCatalogCommand',
	#superclass : 'MCPToolRequestCommand',
	#instVars : [
		'toolExposurePolicy'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'testing' }
MCPToolCatalogCommand class >> isAbstract [

	^ self == MCPToolCatalogCommand
]

{ #category : 'instance creation' }
MCPToolCatalogCommand class >> tool: aTool request: aRequest toolExposurePolicy: aToolExposurePolicy [

	^ self new
		initializeTool: aTool request: aRequest;
		toolExposurePolicy: aToolExposurePolicy;
		yourself
]

{ #category : 'accessing' }
MCPToolCatalogCommand >> toolExposurePolicy [

	^ toolExposurePolicy ifNil: [ MCPToolExposurePolicy default ]
]

{ #category : 'accessing' }
MCPToolCatalogCommand >> toolExposurePolicy: aToolExposurePolicy [

	toolExposurePolicy := aToolExposurePolicy ifNil: [
		MCPToolExposurePolicy default ]
]
