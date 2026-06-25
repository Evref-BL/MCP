"
Structured metadata for one entry in image change history.
"
Class {
	#name : 'MCPChangeHistoryEntryInfo',
	#superclass : 'MCPDataTransferObject',
	#instVars : [
		'index',
		'eventClassName',
		'summary',
		'isCodeChange',
		'entryKind',
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

	| data |
	data := Dictionary new.
	index ifNotNil: [ data at: #index put: index ].
	eventClassName ifNotNil: [
		data at: #eventClassName put: eventClassName ].
	(summary notNil and: [ summary ~= ('an ' , eventClassName) ])
		ifTrue: [ data at: #summary put: summary ].
	entryKind ifNotNil: [ data at: #entryKind put: entryKind ].
	time ifNotNil: [ data at: #time put: time ].
	triggerReference ifNotNil: [
		data at: #triggerReference put: triggerReference ].
	packageName ifNotNil: [ data at: #packageName put: packageName ].
	behaviorName ifNotNil: [ data at: #behaviorName put: behaviorName ].
	classSide ifNotNil: [ data at: #classSide put: classSide ].
	selector ifNotNil: [ data at: #selector put: selector ].
	protocol ifNotNil: [ data at: #protocol put: protocol ].
	^ data
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
	isCodeChange
		ifTrue: [ anEvent mcpAddChangeHistoryInfoTo: self ]
		ifFalse: [ entryKind := anEvent mcpChangeHistoryEntryKind ]
]

{ #category : 'initialization' }
MCPChangeHistoryEntryInfo >> initializeFromEntry: anEntry index: anInteger log: aLog [

	index := anInteger.
	self initializeEventFieldsFrom: anEntry content.
	self initializeTimeFromEntry: anEntry log: aLog.
	self initializeTriggerReferenceFromEntry: anEntry log: aLog
]

{ #category : 'initialization' }
MCPChangeHistoryEntryInfo >> initializeFromEvent: anEvent [

	self initializeEventFieldsFrom: anEvent
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
