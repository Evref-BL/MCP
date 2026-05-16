Class {
	#name : 'MCPToolFindMethodsReferenceFixture',
	#superclass : 'Object',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'testing' }
MCPToolFindMethodsReferenceFixture class >> MCPToolFindMethodsReferenceTarget [

	^ 'class-selector-target'
]

{ #category : 'testing' }
MCPToolFindMethodsReferenceFixture class >> classSendShared [

	^ self sharedTarget
]

{ #category : 'testing' }
MCPToolFindMethodsReferenceFixture class >> referenceExtensionTarget [

	^ MCPToolFindMethodsReferenceTarget
]

{ #category : 'testing' }
MCPToolFindMethodsReferenceFixture class >> sendExistingClassNamedSelector [

	^ self MCPToolFindMethodsReferenceTarget
]

{ #category : 'testing' }
MCPToolFindMethodsReferenceFixture class >> sharedTarget [

	^ 'class-target'
]

{ #category : 'testing' }
MCPToolFindMethodsReferenceFixture >> MCPToolFindMethodsReferenceTarget [

	^ 'instance-selector-target'
]

{ #category : 'testing' }
MCPToolFindMethodsReferenceFixture >> instanceSendShared [

	^ self sharedTarget
]

{ #category : 'testing' }
MCPToolFindMethodsReferenceFixture >> referenceExtensionTarget [

	^ MCPToolFindMethodsReferenceTarget new
]

{ #category : 'testing' }
MCPToolFindMethodsReferenceFixture >> sendExistingClassNamedSelector [

	^ self MCPToolFindMethodsReferenceTarget
]

{ #category : 'testing' }
MCPToolFindMethodsReferenceFixture >> sharedTarget [

	^ 'instance-target'
]
