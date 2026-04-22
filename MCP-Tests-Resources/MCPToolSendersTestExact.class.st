Class {
	#name : 'MCPToolSendersTestExact',
	#superclass : 'Object',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'testing' }
MCPToolSendersTestExact class >> MCPToolSendersTestExtensionTarget [

	^ 'class-selector-target'
]

{ #category : 'testing' }
MCPToolSendersTestExact class >> classSendShared [

	^ self sharedTarget
]

{ #category : 'testing' }
MCPToolSendersTestExact class >> referenceExtensionTarget [

	^ MCPToolSendersTestExtensionTarget
]

{ #category : 'testing' }
MCPToolSendersTestExact class >> sendExistingClassNamedSelector [

	^ self MCPToolSendersTestExtensionTarget
]

{ #category : 'testing' }
MCPToolSendersTestExact class >> sharedTarget [

	^ 'class-target'
]

{ #category : 'testing' }
MCPToolSendersTestExact >> MCPToolSendersTestExtensionTarget [

	^ 'instance-selector-target'
]

{ #category : 'testing' }
MCPToolSendersTestExact >> instanceSendShared [

	^ self sharedTarget
]

{ #category : 'testing' }
MCPToolSendersTestExact >> referenceExtensionTarget [

	^ MCPToolSendersTestExtensionTarget new
]

{ #category : 'testing' }
MCPToolSendersTestExact >> sendExistingClassNamedSelector [

	^ self MCPToolSendersTestExtensionTarget
]

{ #category : 'testing' }
MCPToolSendersTestExact >> sharedTarget [

	^ 'instance-target'
]
