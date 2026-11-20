"
Shared base of class_create and class_update.

The class is changed through the MCPClassCommand operations.
"
Class {
	#name : 'MCPToolClassMutation',
	#superclass : 'MCPToolMutation',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolClassMutation class >> groupName [

	^ self classesGroupName
]

{ #category : 'metadata' }
MCPToolClassMutation >> additionalKeywords [

	^ #( 'class' 'refactor' 'refactoring' )
]

{ #category : 'private - arguments' }
MCPToolClassMutation >> classCommentIn: request [
	"The comment as the caller wrote it, nil when it gave none. It is text, so it is not trimmed, and null clears it."

	| value |
	value := request argumentNamed: 'comment' ifAbsent: [ ^ nil ].
	^ value ifNil: [ '' ] ifNotNil: [ value asString ]
]

{ #category : 'private - schema' }
MCPToolClassMutation >> layoutSchemaProperty [

	^ self
		  schemaPropertyNamed: 'layout'
		  type: 'string'
		  description: 'Layout class, a subclass of AbstractLayout such as VariableLayout.'
]
