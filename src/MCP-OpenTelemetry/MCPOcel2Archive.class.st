"
The OCEL 2.0 JSON form of the call graph's log, the exchange format of object-centric process mining (objectTypes, eventTypes, objects, events). An event type is a tool, an object id is its type and its value joined by a colon. It writes a MCPOcelLog, and reads a file back as MCPOcelRecordedSpan: those of this archive with all they carry, those of other tools with the tool as the event type, and a session and a client from the objects of those types.
"
Class {
	#name : 'MCPOcel2Archive',
	#superclass : 'Object',
	#category : 'MCP-OpenTelemetry',
	#package : 'MCP-OpenTelemetry'
}

{ #category : 'writing' }
MCPOcel2Archive class >> attributeNamed: aName value: aValue [

	^ Dictionary new
		  at: 'name' put: aName;
		  at: 'value' put: aValue;
		  yourself
]

{ #category : 'writing' }
MCPOcel2Archive class >> eventEntryFor: anEvent [

	| attributes relationships |
	attributes := OrderedCollection new.
	attributes add: (self attributeNamed: 'end_time' value: anEvent finishedAt printString).
	attributes add: (self attributeNamed: 'status' value: (anEvent isError
				  ifTrue: [ 'error' ]
				  ifFalse: [ 'ok' ])).
	anEvent dispatchPath ifNotNil: [ :path | attributes add: (self attributeNamed: 'dispatch_path' value: path) ].
	anEvent parentId ifNotNil: [ :id | attributes add: (self attributeNamed: 'parent_id' value: id) ].
	relationships := OrderedCollection new.
	anEvent objects keysAndValuesDo: [ :type :ids |
			ids do: [ :id |
					relationships add: (Dictionary new
							 at: 'objectId' put: (self objectIdOf: id type: type);
							 at: 'qualifier' put: type;
							 yourself) ] ].
	^ Dictionary new
		  at: 'id' put: anEvent id;
		  at: 'type' put: anEvent activity;
		  at: 'time' put: anEvent startedAt printString;
		  at: 'attributes' put: attributes asArray;
		  at: 'relationships' put: relationships asArray;
		  yourself
]

{ #category : 'writing' }
MCPOcel2Archive class >> eventTypeEntryFor: anActivity [

	^ Dictionary new
		  at: 'name' put: anActivity;
		  at: 'attributes' put: (#( 'end_time' 'status' 'dispatch_path' 'parent_id' ) collect: [ :name |
						   Dictionary new
							   at: 'name' put: name;
							   at: 'type' put: (name = 'end_time'
									    ifTrue: [ 'time' ]
									    ifFalse: [ 'string' ]);
							   yourself ]);
		  yourself
]

{ #category : 'reading' }
MCPOcel2Archive class >> isOcelRoot: aRoot [
	"What tells an OCEL 2.0 file from a file of spans: it has events and objects."

	^ aRoot isDictionary and: [ (aRoot includesKey: 'events') and: [ aRoot includesKey: 'objects' ] ]
]

{ #category : 'writing' }
MCPOcel2Archive class >> jsonFor: aLog [
	"The file text of this log."

	| events |
	events := aLog events.
	^ STONJSON toStringPretty: (Dictionary new
			   at: 'objectTypes' put: (aLog objectTypes collect: [ :type | self objectTypeEntryFor: type ] as: Array);
			   at: 'eventTypes'
			   put:
				   ((events collect: #activity as: Set) asSortedCollection collect: [ :activity | self eventTypeEntryFor: activity ] as: Array);
			   at: 'objects' put: (self objectEntriesOf: aLog);
			   at: 'events' put: (events collect: [ :event | self eventEntryFor: event ] as: Array);
			   yourself)
]

{ #category : 'writing' }
MCPOcel2Archive class >> objectEntriesOf: aLog [

	| entries |
	entries := OrderedCollection new.
	aLog objectTypes do: [ :type |
			(aLog objectIdsOfType: type) do: [ :id |
					entries add: (Dictionary new
							 at: 'id' put: (self objectIdOf: id type: type);
							 at: 'type' put: type;
							 at: 'attributes' put: Array new;
							 at: 'relationships' put: Array new;
							 yourself) ] ].
	^ entries asArray
]

{ #category : 'writing' }
MCPOcel2Archive class >> objectIdOf: aValue type: aType [
	"An id is unique in the file whatever the type: a tool and a client could have the same name."

	^ aType , ':' , aValue
]

{ #category : 'writing' }
MCPOcel2Archive class >> objectTypeEntryFor: aType [

	^ Dictionary new
		  at: 'name' put: aType;
		  at: 'attributes' put: Array new;
		  yourself
]

{ #category : 'reading' }
MCPOcel2Archive class >> spanFrom: anEvent objectTypes: typeOfObject [
	"The tool is the type of the event. A session and a client are the first objects of those types it relates to, as their value without the type this archive puts before it."

	| values attributes start |
	values := Dictionary new.
	(anEvent at: 'attributes' ifAbsent: [ #(  ) ]) do: [ :each | values at: (each at: 'name') put: (each at: 'value') ].
	start := DateAndTime fromString: (anEvent at: 'time').
	attributes := OrderedDictionary new.
	attributes at: 'gen_ai.tool.name' put: (anEvent at: 'type').
	values at: 'dispatch_path' ifPresent: [ :path | attributes at: 'pharo.mcp.dispatch_path' put: path ].
	{
		('session' -> 'session.id').
		('client' -> 'pharo.mcp.client.name') } do: [ :each |
			(self valueOfFirstObjectOfType: each key in: anEvent objectTypes: typeOfObject) ifNotNil: [ :value |
				attributes at: each value put: value ] ].
	^ MCPOcelRecordedSpan new
		  name: 'tools/call ' , (anEvent at: 'type')
		  spanId: (anEvent at: 'id')
		  parentSpanId: (values at: 'parent_id' ifAbsent: [ nil ])
		  startTime: start
		  endTime: (values at: 'end_time' ifPresent: [ :end | DateAndTime fromString: end ] ifAbsent: [ start ])
		  status: (MCPOcelSpanArchive statusFrom: (values at: 'status' ifAbsent: [ 'unset' ]))
		  attributes: attributes;
		  yourself
]

{ #category : 'reading' }
MCPOcel2Archive class >> spansFromRoot: aRoot [
	"The events of an OCEL 2.0 file, as spans."

	| typeOfObject |
	typeOfObject := Dictionary new.
	(aRoot at: 'objects') do: [ :object | typeOfObject at: (object at: 'id') put: (object at: 'type') ].
	^ (aRoot at: 'events') collect: [ :event | self spanFrom: event objectTypes: typeOfObject ]
]

{ #category : 'reading' }
MCPOcel2Archive class >> valueOfFirstObjectOfType: aType in: anEvent objectTypes: typeOfObject [

	(anEvent at: 'relationships' ifAbsent: [ #(  ) ]) do: [ :relationship |
			| id |
			id := relationship at: 'objectId'.
			(typeOfObject at: id ifAbsent: [ nil ]) = aType ifTrue: [ ^ id withoutPrefix: aType , ':' ] ].
	^ nil
]
