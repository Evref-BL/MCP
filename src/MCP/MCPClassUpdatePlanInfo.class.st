"
DTO for the class update action selected from an update request before the action is applied.

It records the selected update action and the request context used for validation and error reporting.
"
Class {
	#name : 'MCPClassUpdatePlanInfo',
	#superclass : 'Object',
	#instVars : [
		'requestedContext',
		'updateAction'
	],
	#category : 'MCP-DTOs',
	#package : 'MCP',
	#tag : 'DTOs'
}

{ #category : 'instance creation' }
MCPClassUpdatePlanInfo class >> updateAction: anUpdateAction requestedContext: aDictionary [

	^ self new
		  updateAction: anUpdateAction;
		  requestedContext: aDictionary;
		  yourself
]

{ #category : 'converting' }
MCPClassUpdatePlanInfo >> asDictionary [

	^ {
		  (#updateAction -> self updateAction).
		  (#requestedContext -> self requestedContext) } asDictionary
]

{ #category : 'accessing' }
MCPClassUpdatePlanInfo >> requestedContext [

	^ requestedContext ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
MCPClassUpdatePlanInfo >> requestedContext: aDictionary [

	requestedContext := aDictionary ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
MCPClassUpdatePlanInfo >> updateAction [

	^ updateAction
]

{ #category : 'accessing' }
MCPClassUpdatePlanInfo >> updateAction: anObject [

	updateAction := anObject
]
