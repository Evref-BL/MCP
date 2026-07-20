"
Registry entry wrapping one reusable MCPTool instance. Group and default exposure are delegated to the tool so registrations do not duplicate intrinsic metadata.
"
Class {
	#name : 'MCPToolRegistration',
	#superclass : 'Object',
	#instVars : [
		'tool'
	],
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'instance creation' }
MCPToolRegistration class >> tool: aTool [

	^ self new initializeTool: aTool
]

{ #category : 'accessing' }
MCPToolRegistration >> defaultExposure [

	^ self tool defaultExposure
]

{ #category : 'accessing' }
MCPToolRegistration >> groupName [

	^ self tool groupName
]

{ #category : 'initialization' }
MCPToolRegistration >> initializeTool: aTool [

	tool := aTool
]

{ #category : 'testing' }
MCPToolRegistration >> isStaticByDefault [

	^ self defaultExposure = 'static'
]

{ #category : 'accessing' }
MCPToolRegistration >> name [

	^ self tool name
]

{ #category : 'accessing' }
MCPToolRegistration >> tool [

	^ tool
]

{ #category : 'accessing' }
MCPToolRegistration >> toolClass [

	^ self tool class
]
