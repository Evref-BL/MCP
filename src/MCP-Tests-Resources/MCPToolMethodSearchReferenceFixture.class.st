"
Fixture class that references methods and classes for method-search tests.
"
Class {
	#name : 'MCPToolMethodSearchReferenceFixture',
	#superclass : 'Object',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'testing' }
MCPToolMethodSearchReferenceFixture class >> MCPToolMethodSearchReferenceTarget [

	^ 'class-selector-target'
]

{ #category : 'testing' }
MCPToolMethodSearchReferenceFixture class >> classSendShared [

	^ self sharedTarget
]

{ #category : 'testing' }
MCPToolMethodSearchReferenceFixture class >> referenceExtensionTarget [

	^ MCPToolMethodSearchReferenceTarget
]

{ #category : 'testing' }
MCPToolMethodSearchReferenceFixture class >> sendExistingClassNamedSelector [

	^ self MCPToolMethodSearchReferenceTarget
]

{ #category : 'testing' }
MCPToolMethodSearchReferenceFixture class >> sharedTarget [

	^ 'class-target'
]

{ #category : 'testing' }
MCPToolMethodSearchReferenceFixture >> MCPToolMethodSearchReferenceTarget [

	^ 'instance-selector-target'
]

{ #category : 'testing' }
MCPToolMethodSearchReferenceFixture >> instanceSendShared [

	^ self sharedTarget
]

{ #category : 'testing' }
MCPToolMethodSearchReferenceFixture >> referenceExtensionTarget [

	^ MCPToolMethodSearchReferenceTarget new
]

{ #category : 'testing' }
MCPToolMethodSearchReferenceFixture >> sendExistingClassNamedSelector [

	^ self MCPToolMethodSearchReferenceTarget
]

{ #category : 'testing' }
MCPToolMethodSearchReferenceFixture >> sharedTarget [

	^ 'instance-target'
]
