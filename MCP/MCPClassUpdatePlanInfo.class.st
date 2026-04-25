"
DTO for the edit-class update action selected from an update request before the action is applied. It records the internal operation name, the narrow command class that will execute it, and the request context used for validation and error reporting.
"
Class {
	#name : 'MCPClassUpdatePlanInfo',
	#superclass : 'Object',
	#instVars : [
		'operation',
		'commandClassName',
		'requestedContext'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPClassUpdatePlanInfo class >> operation: anOperation commandClassName: aCommandClassName requestedContext: aDictionary [

	^ self new
		  operation: anOperation;
		  commandClassName: aCommandClassName;
		  requestedContext: aDictionary;
		  yourself
]

{ #category : 'converting' }
MCPClassUpdatePlanInfo >> asDictionary [

	^ {
		  (#operation -> self operation).
		  (#commandClassName -> self commandClassName).
		  (#requestedContext -> self requestedContext) } asDictionary
]

{ #category : 'accessing' }
MCPClassUpdatePlanInfo >> commandClassName [

	^ commandClassName
]

{ #category : 'accessing' }
MCPClassUpdatePlanInfo >> commandClassName: aString [

	commandClassName := aString
]

{ #category : 'accessing' }
MCPClassUpdatePlanInfo >> operation [

	^ operation
]

{ #category : 'accessing' }
MCPClassUpdatePlanInfo >> operation: aString [

	operation := aString
]

{ #category : 'accessing' }
MCPClassUpdatePlanInfo >> requestedContext [

	^ requestedContext ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
MCPClassUpdatePlanInfo >> requestedContext: aDictionary [

	requestedContext := aDictionary ifNil: [ Dictionary new ]
]
