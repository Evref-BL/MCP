"
I describe one registered MCP tool.

The registry owns registrations so a tool can be instantiated once and reused. The registration carries catalog metadata that belongs to registration time, such as the public group and default exposure. Server-specific exposure policy remains outside the tool and registration.
"
Class {
	#name : 'MCPToolRegistration',
	#superclass : 'Object',
	#instVars : [
		'tool',
		'groupName',
		'defaultExposure'
	],
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'instance creation' }
MCPToolRegistration class >> tool: aTool groupName: aGroupName defaultExposure: anExposure [

	^ self new
		  initializeTool: aTool
		  groupName: aGroupName
		  defaultExposure: anExposure
]

{ #category : 'constants' }
MCPToolRegistration class >> validExposureNames [

	^ #( 'static' 'discoverable' )
]

{ #category : 'accessing' }
MCPToolRegistration >> defaultExposure [

	^ defaultExposure
]

{ #category : 'accessing' }
MCPToolRegistration >> groupName [

	^ groupName
]

{ #category : 'initialization' }
MCPToolRegistration >> initializeTool: aTool groupName: aGroupName defaultExposure: anExposure [

	tool := aTool.
	groupName := aGroupName asString.
	defaultExposure := anExposure asString.
	(self class validExposureNames includes: defaultExposure) ifFalse: [
		Error signal: 'Unknown MCP tool exposure: ' , defaultExposure ]
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
