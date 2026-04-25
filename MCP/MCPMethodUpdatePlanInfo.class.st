"
DTO describing the internal update action selected for an edit-method update request before the action is executed.
"
Class {
	#name : 'MCPMethodUpdatePlanInfo',
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
MCPMethodUpdatePlanInfo class >> operation: anOperation commandClassName: aCommandClassName requestedContext: aDictionary [

	^ self new
		  operation: anOperation;
		  commandClassName: aCommandClassName;
		  requestedContext: aDictionary;
		  yourself
]

{ #category : 'converting' }
MCPMethodUpdatePlanInfo >> asDictionary [

	^ {
		  (#operation -> self operation).
		  (#commandClassName -> self commandClassName).
		  (#requestedContext -> self requestedContext) } asDictionary
]

{ #category : 'accessing' }
MCPMethodUpdatePlanInfo >> commandClassName [

	^ commandClassName
]

{ #category : 'accessing' }
MCPMethodUpdatePlanInfo >> commandClassName: aString [

	commandClassName := aString
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
