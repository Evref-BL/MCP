"
DTO for the edit-method update action selected from an update request before the action is applied. It records the selected update action and the request context used for validation and error reporting.
"
Class {
	#name : 'MCPMethodUpdatePlanInfo',
	#superclass : 'Object',
	#instVars : [
		'requestedContext',
		'updateAction'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPMethodUpdatePlanInfo class >> updateAction: anUpdateAction requestedContext: aDictionary [

	^ self new
		  updateAction: anUpdateAction;
		  requestedContext: aDictionary;
		  yourself
]

{ #category : 'converting' }
MCPMethodUpdatePlanInfo >> asDictionary [

	^ {
		  (#updateAction -> self updateAction).
		  (#requestedContext -> self requestedContext) } asDictionary
]

{ #category : 'accessing' }
MCPMethodUpdatePlanInfo >> requestedContext [

	^ requestedContext ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
MCPMethodUpdatePlanInfo >> requestedContext: aDictionary [

	requestedContext := aDictionary ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
MCPMethodUpdatePlanInfo >> updateAction [

	^ updateAction
]

{ #category : 'accessing' }
MCPMethodUpdatePlanInfo >> updateAction: anObject [

	updateAction := anObject
]
