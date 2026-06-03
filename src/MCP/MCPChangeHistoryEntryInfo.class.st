"
Structured metadata for one entry in image change history.
"
Class {
	#name : 'MCPChangeHistoryEntryInfo',
	#superclass : 'Object',
	#instVars : [
		'index',
		'reference',
		'globalName',
		'localName',
		'eventClassName',
		'summary',
		'isCodeChange',
		'time',
		'triggerReference',
		'packageName',
		'behaviorName',
		'classSide',
		'selector',
		'protocol'
	],
	#category : 'MCP-DTOs',
	#package : 'MCP',
	#tag : 'DTOs'
}

{ #category : 'instance creation' }
MCPChangeHistoryEntryInfo class >> fromEntry: anEntry index: anInteger log: aLog [

	^ self new
		  initializeFromEntry: anEntry index: anInteger log: aLog;
		  yourself
]

{ #category : 'instance creation' }
MCPChangeHistoryEntryInfo class >> fromEvent: anEvent [

	^ self new
		  initializeFromEvent: anEvent;
		  yourself
]

{ #category : 'adding' }
MCPChangeHistoryEntryInfo >> addBehaviorChangeInfoFrom: aBehaviorChange [

	self addCodeChangeInfoFrom: aBehaviorChange.
	self addBehaviorNameFrom: aBehaviorChange
]

{ #category : 'adding' }
MCPChangeHistoryEntryInfo >> addBehaviorNameFrom: aBehaviorChange [

	behaviorName := self stringFrom: aBehaviorChange behaviorAffectedName.
	classSide := self classSideFromBehaviorName: behaviorName
]

{ #category : 'adding' }
MCPChangeHistoryEntryInfo >> addCodeChangeInfoFrom: aCodeChange [

	packageName := self stringFrom: aCodeChange affectedPackageName
]

{ #category : 'adding' }
MCPChangeHistoryEntryInfo >> addMethodChangeInfoFrom: aMethodChange [

	self addCodeChangeInfoFrom: aMethodChange.
	self addBehaviorNameFrom: aMethodChange.
	selector := self stringFrom: aMethodChange methodAffectedSelector.
	protocol := self stringFrom: aMethodChange methodAffectedProtocol
]

{ #category : 'adding' }
MCPChangeHistoryEntryInfo >> addPackageChangeInfoFrom: aPackageChange [

	packageName := self stringFrom: aPackageChange packageName
]

{ #category : 'adding' }
MCPChangeHistoryEntryInfo >> addPackageTagChangeInfoFrom: aPackageTagChange [

	packageName := self stringFrom: aPackageTagChange packageName
]

{ #category : 'converting' }
MCPChangeHistoryEntryInfo >> asDictionary [

	^ {
		  (#index -> index).
		  (#reference -> reference).
		  (#globalName -> globalName).
		  (#localName -> localName).
		  (#eventClassName -> eventClassName).
		  (#summary -> summary).
		  (#isCodeChange -> isCodeChange).
		  (#time -> time).
		  (#triggerReference -> triggerReference).
		  (#packageName -> packageName).
		  (#behaviorName -> behaviorName).
		  (#classSide -> classSide).
		  (#selector -> selector).
		  (#protocol -> protocol) } asDictionary
]

{ #category : 'private' }
MCPChangeHistoryEntryInfo >> classSideFromBehaviorName: aString [

	aString ifNil: [ ^ nil ].
	^ aString endsWith: ' class'
]

{ #category : 'private - initialization' }
MCPChangeHistoryEntryInfo >> initializeEventFieldsFrom: anEvent [

	eventClassName := anEvent class name asString.
	summary := anEvent printString.
	isCodeChange := anEvent isCodeChange.
	isCodeChange ifTrue: [ anEvent mcpAddChangeHistoryInfoTo: self ]
]

{ #category : 'initialization' }
MCPChangeHistoryEntryInfo >> initializeFromEntry: anEntry index: anInteger log: aLog [

	index := anInteger.
	self initializeReferenceFieldsFrom: (aLog referenceTo: anEntry).
	self initializeEventFieldsFrom: anEntry content.
	self initializeTimeFromEntry: anEntry log: aLog.
	self initializeTriggerReferenceFromEntry: anEntry log: aLog
]

{ #category : 'initialization' }
MCPChangeHistoryEntryInfo >> initializeFromEvent: anEvent [

	self initializeEventFieldsFrom: anEvent
]

{ #category : 'private - initialization' }
MCPChangeHistoryEntryInfo >> initializeReferenceFieldsFrom: aReference [

	reference := self stringFromReference: aReference.
	globalName := self stringFrom: aReference globalName.
	localName := self stringFrom: aReference localName
]

{ #category : 'private - initialization' }
MCPChangeHistoryEntryInfo >> initializeTimeFromEntry: anEntry log: aLog [

	time := (aLog timeAt: anEntry ifAbsent: [ nil ]) ifNotNil: [ :value |
		        value asString ]
]

{ #category : 'private - initialization' }
MCPChangeHistoryEntryInfo >> initializeTriggerReferenceFromEntry: anEntry log: aLog [

	triggerReference := nil.
	aLog
		triggererReferenceOf: anEntry
		ifPresent: [ :aReference |
			triggerReference := self stringFromReference: aReference ]
		ifAbsent: [ ]
]

{ #category : 'accessing' }
MCPChangeHistoryEntryInfo >> isCodeChange [

	^ isCodeChange
]

{ #category : 'testing' }
MCPChangeHistoryEntryInfo >> isMethodChangeForSelector: aSelector inBehaviorNamed: aBehaviorName [

	^ selector = aSelector asString and: [ behaviorName = aBehaviorName ]
]

{ #category : 'private - converting' }
MCPChangeHistoryEntryInfo >> stringFrom: aValue [

	^ aValue ifNotNil: [ aValue asString ]
]

{ #category : 'private - converting' }
MCPChangeHistoryEntryInfo >> stringFromReference: aReference [

	aReference isNull ifTrue: [ ^ nil ].
	^ aReference shortName asString
]
