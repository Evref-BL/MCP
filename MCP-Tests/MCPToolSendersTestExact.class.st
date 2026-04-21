Class {
	#name : 'MCPToolSendersTestExact',
	#superclass : 'Object',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'testing' }
MCPToolSendersTestExact class >> classSendShared [

	^ self sharedTarget
]

{ #category : 'testing' }
MCPToolSendersTestExact class >> sharedTarget [

	^ 'class-target'
]

{ #category : 'testing' }
MCPToolSendersTestExact >> instanceSendShared [

	^ self sharedTarget
]

{ #category : 'testing' }
MCPToolSendersTestExact >> sharedTarget [

	^ 'instance-target'
]
