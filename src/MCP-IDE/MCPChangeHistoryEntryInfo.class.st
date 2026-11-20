"
Structured metadata for one entry in image change history.
"
Class {
	#name : 'MCPChangeHistoryEntryInfo',
	#superclass : 'Object',
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
		'protocol',
		'sourceBefore',
		'sourceAfter',
		'noChangeReason'
	],
	#category : 'MCP-IDE-DTOs',
	#package : 'MCP-IDE',
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
		  initializeEventFieldsFrom: anEvent;
		  yourself
]

{ #category : 'instance creation' }
MCPChangeHistoryEntryInfo class >> fromPreviewedChange: aCodeChange index: anInteger [
	"A change a preview holds, under the index of the selected entry it comes from, with the source it changes."

	^ self new
		  initializeFromPreviewedChange: aCodeChange index: anInteger;
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

	self addBehaviorChangeInfoFrom: aMethodChange.
	selector := self stringFrom: aMethodChange methodAffectedSelector.
	protocol := self stringFrom: aMethodChange methodAffectedProtocol
]

{ #category : 'private - converting' }
MCPChangeHistoryEntryInfo >> addOutcomeTo: data [
	"What applying or reverting the entry does: the source of the method before and after, or why it changes nothing."

	sourceBefore ifNotNil: [ data at: #sourceBefore put: sourceBefore ].
	sourceAfter ifNotNil: [ data at: #sourceAfter put: sourceAfter ].
	noChangeReason ifNotNil: [ data at: #changesNothing put: noChangeReason ]
]

{ #category : 'adding' }
MCPChangeHistoryEntryInfo >> addPackageNameFrom: aPackageOrTagChange [

	packageName := self stringFrom: aPackageOrTagChange packageName
]

{ #category : 'adding' }
MCPChangeHistoryEntryInfo >> addSourceAfter: aString [

	sourceAfter := aString
]

{ #category : 'adding' }
MCPChangeHistoryEntryInfo >> addSourceBefore: aString [

	sourceBefore := aString
]

{ #category : 'converting' }
MCPChangeHistoryEntryInfo >> asDictionary [
	"behavior names the class, and side says a change was on its class side, as everywhere else a method is named; the name Epicea keeps, with its class suffix, stays for matching."

	| data |
	data := Dictionary new.
	index ifNotNil: [ data at: #index put: index ].
	eventClassName ifNotNil: [ data at: #eventClass put: eventClassName ].
	(summary isNotNil and: [ summary ~= ('an ' , eventClassName) ]) ifTrue: [ data at: #summary put: summary ].
	entryKind ifNotNil: [ data at: #entryKind put: entryKind ].
	time ifNotNil: [ data at: #time put: time ].
	triggerReference ifNotNil: [ data at: #triggerReference put: triggerReference ].
	packageName ifNotNil: [ data at: #package put: packageName ].
	behaviorName ifNotNil: [ data at: #behavior put: self instanceSideBehaviorName ].
	classSide == true ifTrue: [ data at: #side put: 'class' ].
	selector ifNotNil: [ data at: #selector put: selector ].
	protocol ifNotNil: [ data at: #protocol put: protocol ].
	self addOutcomeTo: data.
	^ data
]

{ #category : 'testing' }
MCPChangeHistoryEntryInfo >> changesClassNamed: aClassName [
	"Whether the entry changes the class so named, on either side: its definition, its comment, or one of its methods or protocols. An entry that names no class changes none."

	^ behaviorName isNotNil and: [ self instanceSideBehaviorName = aClassName ]
]

{ #category : 'adding' }
MCPChangeHistoryEntryInfo >> changesNothingBecause: aString [
	"Say why the entry, though selected, changes nothing."

	noChangeReason := aString
]

{ #category : 'private' }
MCPChangeHistoryEntryInfo >> classSideFromBehaviorName: aString [
	"Whether Epicea's name for a behavior names a class side: Foo class, or TFoo classTrait for a trait."

	aString ifNil: [ ^ nil ].
	^ MCPImageLookup namesClassSide: aString
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
MCPChangeHistoryEntryInfo >> initializeFromPreviewedChange: aCodeChange index: anInteger [

	index := anInteger.
	self initializeEventFieldsFrom: aCodeChange.
	aCodeChange mcpAddSourcesTo: self
]

{ #category : 'private - initialization' }
MCPChangeHistoryEntryInfo >> initializeTimeFromEntry: anEntry log: aLog [

	time := (aLog timeAt: anEntry ifAbsent: [ nil ]) ifNotNil: [ :value | value asString ]
]

{ #category : 'private - initialization' }
MCPChangeHistoryEntryInfo >> initializeTriggerReferenceFromEntry: anEntry log: aLog [

	triggerReference := nil.
	aLog
		triggererReferenceOf: anEntry
		ifPresent: [ :aReference | triggerReference := self stringFromReference: aReference ]
		ifAbsent: [ ]
]

{ #category : 'private' }
MCPChangeHistoryEntryInfo >> instanceSideBehaviorName [
	"Epicea's name for the behavior without the class or classTrait a class-side change carries."

	^ MCPImageLookup baseNameOf: behaviorName
]

{ #category : 'accessing' }
MCPChangeHistoryEntryInfo >> isCodeChange [

	^ isCodeChange
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
