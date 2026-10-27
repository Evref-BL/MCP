"
One patch over a class's instance-side or class-side slots.

Every other part of a class definition is replaced by value, because it holds no state: setting traits or shared pools to a new list loses nothing. Slots hold the instance's values, so a replace cannot tell a rename from a remove-plus-add, and the two differ in whether the value survives. They are patched instead.

Patching also spares the caller a read: naming one slot to add needs nothing else, where replacing the list needs the whole current list, and a stale one silently drops what the caller did not know about.
"
Class {
	#name : 'MCPSlotDelta',
	#superclass : 'Object',
	#instVars : [
		'added',
		'removed',
		'renamed',
		'pulledUp',
		'pushedDown',
		'replacement'
	],
	#category : 'MCP-IDE-Requests',
	#package : 'MCP-IDE',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPSlotDelta class >> fromRequest: aToolRequest named: aPropertyName [
	"Answer the delta the request carries under aPropertyName, or nil when it carries none."

	| supplied |
	supplied := aToolRequest argumentNamed: aPropertyName ifAbsent: [ ^ nil ].
	^ self new initializeFrom: supplied in: aToolRequest
]

{ #category : 'accessing' }
MCPSlotDelta >> added [

	^ added ifNil: [ #(  ) ]
]

{ #category : 'printing' }
MCPSlotDelta >> asContextValue [
	"What the requested context reports for this delta: the parts the caller asked for, and nothing else."

	| context |
	context := Dictionary new.
	self hasReplacement ifTrue: [ context at: #replace put: self replacement ].
	self added ifNotEmpty: [ context at: #add put: self added ].
	self removed ifNotEmpty: [ context at: #remove put: self removed ].
	self renamed ifNotEmpty: [ context at: #rename put: self renamed ].
	self pulledUp ifNotEmpty: [ context at: #pullUp put: self pulledUp ].
	self pushedDown ifNotEmpty: [ context at: #pushDown put: self pushedDown ].
	^ context
]

{ #category : 'testing' }
MCPSlotDelta >> hasReplacement [

	^ replacement isNotNil
]

{ #category : 'initialization' }
MCPSlotDelta >> initializeFrom: aDictionary in: aToolRequest [

	added := aToolRequest stringCollectionArgumentNamed: 'add' in: aDictionary.
	removed := aToolRequest stringCollectionArgumentNamed: 'remove' in: aDictionary.
	pulledUp := aToolRequest stringCollectionArgumentNamed: 'pullUp' in: aDictionary.
	pushedDown := aToolRequest stringCollectionArgumentNamed: 'pushDown' in: aDictionary.
	replacement := (aToolRequest valueNamed: 'replace' in: aDictionary ifAbsent: [ nil ]) ifNotNil: [ :value |
		               aToolRequest stringCollectionFrom: value ].
	renamed := self renamesFrom: (aToolRequest valueNamed: 'rename' in: aDictionary ifAbsent: [ nil ])
]

{ #category : 'testing' }
MCPSlotDelta >> isEmpty [

	^ self hasReplacement not and: [
			  self added isEmpty and: [
				  self removed isEmpty and: [ self renamed isEmpty and: [ self pulledUp isEmpty and: [ self pushedDown isEmpty ] ] ] ] ]
]

{ #category : 'accessing' }
MCPSlotDelta >> pulledUp [

	^ pulledUp ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPSlotDelta >> pushedDown [

	^ pushedDown ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPSlotDelta >> removed [

	^ removed ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPSlotDelta >> renamed [

	^ renamed ifNil: [ OrderedDictionary new ]
]

{ #category : 'initialization' }
MCPSlotDelta >> renamesFrom: aDictionaryOrNil [

	aDictionaryOrNil ifNil: [ ^ OrderedDictionary new ].
	^ aDictionaryOrNil keys inject: OrderedDictionary new into: [ :renames :key |
			  renames
				  at: key asString put: (aDictionaryOrNil at: key) asString;
				  yourself ]
]

{ #category : 'accessing' }
MCPSlotDelta >> replacement [

	^ replacement
]
