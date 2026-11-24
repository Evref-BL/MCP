"
One tool call of an object-centric event log (OCEL): the activity is the tool called, and the event relates to the objects it involves, by object type: the tool called, and the tool that dispatched the call when one did (type 'tool', the central object), the session it belongs to ('session') and the client that made it ('client'). It is read from the span of the call, whose id it keeps.
"
Class {
	#name : 'MCPOcelEvent',
	#superclass : 'Object',
	#instVars : [
		'id',
		'activity',
		'startedAt',
		'finishedAt',
		'isError',
		'dispatchPath',
		'parentId',
		'depth',
		'objects'
	],
	#category : 'MCP-OpenTelemetry',
	#package : 'MCP-OpenTelemetry'
}

{ #category : 'accessing' }
MCPOcelEvent >> activity [

	^ activity
]

{ #category : 'accessing' }
MCPOcelEvent >> activity: aString [

	activity := aString
]

{ #category : 'objects' }
MCPOcelEvent >> addObject: anId ofType: aType [

	| ids |
	ids := self objects at: aType ifAbsentPut: [ OrderedCollection new ].
	(ids includes: anId) ifFalse: [ ids add: anId ]
]

{ #category : 'accessing' }
MCPOcelEvent >> depth [

	^ depth ifNil: [ 0 ]
]

{ #category : 'accessing' }
MCPOcelEvent >> depth: anInteger [

	depth := anInteger
]

{ #category : 'accessing' }
MCPOcelEvent >> dispatchPath [

	^ dispatchPath
]

{ #category : 'accessing' }
MCPOcelEvent >> dispatchPath: aString [

	dispatchPath := aString
]

{ #category : 'accessing' }
MCPOcelEvent >> durationMilliseconds [
	"How long the call took, 0 when it has no end."

	^ (startedAt isNil or: [ finishedAt isNil ])
		  ifTrue: [ 0 ]
		  ifFalse: [ (finishedAt - startedAt) asMilliSeconds ]
]

{ #category : 'accessing' }
MCPOcelEvent >> finishedAt [

	^ finishedAt
]

{ #category : 'accessing' }
MCPOcelEvent >> finishedAt: aDateAndTime [

	finishedAt := aDateAndTime
]

{ #category : 'accessing' }
MCPOcelEvent >> id [

	^ id
]

{ #category : 'accessing' }
MCPOcelEvent >> id: aString [

	id := aString
]

{ #category : 'objects' }
MCPOcelEvent >> involvesObjectType: aType [

	^ (self objectIdsOfType: aType) isNotEmpty
]

{ #category : 'accessing' }
MCPOcelEvent >> isError [

	^ isError == true
]

{ #category : 'accessing' }
MCPOcelEvent >> isError: aBoolean [

	isError := aBoolean
]

{ #category : 'objects' }
MCPOcelEvent >> objectIdsOfType: aType [

	^ self objects at: aType ifAbsent: [ #(  ) ]
]

{ #category : 'objects' }
MCPOcelEvent >> objects [
	"The ids of the objects the event involves, by object type."

	^ objects ifNil: [ objects := Dictionary new ]
]

{ #category : 'accessing' }
MCPOcelEvent >> parentId [

	^ parentId
]

{ #category : 'accessing' }
MCPOcelEvent >> parentId: aString [

	parentId := aString
]

{ #category : 'accessing' }
MCPOcelEvent >> startedAt [

	^ startedAt
]

{ #category : 'accessing' }
MCPOcelEvent >> startedAt: aDateAndTime [

	startedAt := aDateAndTime
]
