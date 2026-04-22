Class {
	#name : 'MCPToolReferencesTestExact',
	#superclass : 'Object',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'testing' }
MCPToolReferencesTestExact class >> MCPToolReferencesTestExtensionTarget [

	^ 'class-selector-target'
]

{ #category : 'testing' }
MCPToolReferencesTestExact class >> classSendShared [

	^ self sharedTarget
]

{ #category : 'testing' }
MCPToolReferencesTestExact class >> referenceExtensionTarget [

	^ MCPToolReferencesTestExtensionTarget
]

{ #category : 'testing' }
MCPToolReferencesTestExact class >> sendExistingClassNamedSelector [

	^ self MCPToolReferencesTestExtensionTarget
]

{ #category : 'testing' }
MCPToolReferencesTestExact class >> sharedTarget [

	^ 'class-target'
]

{ #category : 'testing' }
MCPToolReferencesTestExact >> MCPToolReferencesTestExtensionTarget [

	^ 'instance-selector-target'
]

{ #category : 'testing' }
MCPToolReferencesTestExact >> instanceSendShared [

	^ self sharedTarget
]

{ #category : 'testing' }
MCPToolReferencesTestExact >> referenceExtensionTarget [

	^ MCPToolReferencesTestExtensionTarget new
]

{ #category : 'testing' }
MCPToolReferencesTestExact >> sendExistingClassNamedSelector [

	^ self MCPToolReferencesTestExtensionTarget
]

{ #category : 'testing' }
MCPToolReferencesTestExact >> sharedTarget [

	^ 'instance-target'
]
