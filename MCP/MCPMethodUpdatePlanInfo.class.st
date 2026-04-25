"
DTO for the edit-method update action selected from an update request before the action is applied. It records the selected update action and the request context used for validation and error reporting.
"
Class {
	#name : 'MCPMethodUpdatePlanInfo',
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
MCPMethodUpdatePlanInfo class >> operation: anOperation requestedContext: aDictionary [

	^ self new
		  operation: anOperation;
		  requestedContext: aDictionary;
		  yourself
]

{ #category : 'converting' }
MCPMethodUpdatePlanInfo >> asDictionary [

	^ {
		  (#operation -> self operation).
		  (#requestedContext -> self requestedContext) } asDictionary
]

{ #category : 'accessing' }
MCPMethodUpdatePlanInfo >> operation [

	^ operation
]

{ #category : 'accessing' }
MCPMethodUpdatePlanInfo >> operation: aString [

	operation := aString
]

{ #category : 'accessing' }
MCPMethodUpdatePlanInfo >> requestedContext [

	^ requestedContext ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
MCPMethodUpdatePlanInfo >> requestedContext: aDictionary [

	requestedContext := aDictionary ifNil: [ Dictionary new ]
]
