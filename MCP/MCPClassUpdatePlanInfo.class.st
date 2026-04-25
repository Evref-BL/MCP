"
DTO for the edit-class update action selected from an update request before the action is applied. It records the selected update action and the request context used for validation and error reporting.
"
Class {
	#name : 'MCPClassUpdatePlanInfo',
	#superclass : 'Object',
	#instVars : [
		'operation',
		'requestedContext'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPClassUpdatePlanInfo class >> operation: anOperation requestedContext: aDictionary [

	^ self new
		  operation: anOperation;
		  requestedContext: aDictionary;
		  yourself
]

{ #category : 'converting' }
MCPClassUpdatePlanInfo >> asDictionary [

	^ {
		  (#operation -> self operation).
		  (#requestedContext -> self requestedContext) } asDictionary
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
