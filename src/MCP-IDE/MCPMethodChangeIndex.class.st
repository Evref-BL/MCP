"
Where the changes to each method are in one change history file, and the versions of a method read from them. It keeps the numbers of the entries that changed each method, oldest first, so that the versions of one method are read from its own entries alone. Reading every entry of the file instead would parse each of them at every query, since a log keeps the entries it has read only weakly.

An index reads each entry once. An update reads what was written since the last one; a log now written to another file, as the session in progress is after a restart, is read again from its start. It also keeps the entry the file's first entry follows, which is where the session before it left off.
"
Class {
	#name : 'MCPMethodChangeIndex',
	#superclass : 'Object',
	#instVars : [
		'globalName',
		'count',
		'numbersByMethod',
		'priorOfFirstEntry',
		'log'
	],
	#category : 'MCP-IDE-Queries',
	#package : 'MCP-IDE',
	#tag : 'Queries'
}

{ #category : 'private - reading' }
MCPMethodChangeIndex >> add: anEntry of: aLog [

	| change number |
	number := self numberOf: anEntry in: aLog.
	count := count max: number.
	number = 1 ifTrue: [ priorOfFirstEntry := aLog priorReferenceAt: anEntry ].
	change := anEntry content.
	change isEpMethodChange ifFalse: [ ^ self ].
	(numbersByMethod
		 at: (self keyForBehaviorNamed: change behaviorAffectedName selector: change methodAffectedSelector)
		 ifAbsentPut: [ OrderedCollection new ]) add: number
]

{ #category : 'private - reading' }
MCPMethodChangeIndex >> add: aVersion to: versions following: isNextEntry [
	"Add aVersion to versions. isNextEntry says that its entry is the one right after the last version's, and two such entries may be one change: a compile and the change that formats it, as method_compile logs them, make one version; a move to another protocol and the removal after it, as Pharo 11 logs a removal, are the removal alone."

	(isNextEntry and: [ versions isNotEmpty ]) ifTrue: [
			(versions last isFormattedBy: aVersion) ifTrue: [ ^ versions last adoptFormattingOf: aVersion ].
			(versions last isProtocolStepOf: aVersion) ifTrue: [ versions removeLast ] ].
	versions add: aVersion
]

{ #category : 'accessing' }
MCPMethodChangeIndex >> count [
	"How many entries of the file the index has read."

	^ count
]

{ #category : 'private - reading' }
MCPMethodChangeIndex >> entriesOf: aLog after: aNumber do: aBlock [
	"Each entry of aLog numbered past aNumber, newest first."

	aLog priorEntriesFromHeadDo: [ :entry |
			(self numberOf: entry in: aLog) > aNumber ifFalse: [ ^ self ].
			aBlock value: entry ]
]

{ #category : 'private - reading' }
MCPMethodChangeIndex >> entryNumbered: aNumber do: aBlock [

	log entryFor: (OmReference globalName: globalName localName: aNumber printString) ifPresent: aBlock ifAbsent: [ ]
]

{ #category : 'accessing' }
MCPMethodChangeIndex >> globalName [
	"The name of the file the index reads, the one its entries' references carry."

	^ globalName
]

{ #category : 'initialization' }
MCPMethodChangeIndex >> initialize [

	super initialize.
	count := 0.
	numbersByMethod := Dictionary new.
	priorOfFirstEntry := OmNullReference uniqueInstance
]

{ #category : 'private - reading' }
MCPMethodChangeIndex >> keyForBehaviorNamed: aBehaviorName selector: aSelector [
	"Foo>>bar or Foo class>>bar, the behavior named as Epicea names it."

	^ String streamContents: [ :stream | stream << aBehaviorName << '>>' << aSelector ]
]

{ #category : 'private - reading' }
MCPMethodChangeIndex >> numberOf: anEntry in: aLog [

	^ (aLog referenceTo: anEntry) localName asInteger
]

{ #category : 'accessing' }
MCPMethodChangeIndex >> numbersOfChangesToBehaviorNamed: aBehaviorName selector: aSelector [
	"The numbers of the entries that changed the method, oldest first."

	^ numbersByMethod at: (self keyForBehaviorNamed: aBehaviorName selector: aSelector) ifAbsent: [ #(  ) ]
]

{ #category : 'accessing' }
MCPMethodChangeIndex >> priorOfFirstEntry [
	"The reference the file's first entry names as the entry it follows, a null one when there is none or the index has not read it. In a session's file, it is the entry of the session before at which the image was last saved."

	^ priorOfFirstEntry
]

{ #category : 'private' }
MCPMethodChangeIndex >> resetFor: aLog [
	"Start over on the file aLog writes now."

	globalName := aLog store globalName.
	count := 0.
	numbersByMethod := Dictionary new.
	priorOfFirstEntry := OmNullReference uniqueInstance
]

{ #category : 'updating' }
MCPMethodChangeIndex >> updateFrom: aLog [
	"Read the entries of aLog's file that the index has not read yet. The first reading goes through the file in order, which is faster than following each entry back to the one before it; an update follows the entries back from the newest to the last one read."

	| head newEntries |
	log := aLog.
	aLog store globalName = globalName ifFalse: [ self resetFor: aLog ].
	head := aLog headReference.
	head isNull ifTrue: [ ^ self ].
	head localName asInteger < count ifTrue: [ self resetFor: aLog ].
	count = 0 ifTrue: [ ^ aLog entriesDo: [ :entry | self add: entry of: aLog ] ].
	newEntries := OrderedCollection new.
	self entriesOf: aLog after: count do: [ :entry | newEntries addFirst: entry ].
	newEntries do: [ :entry | self add: entry of: aLog ]
]

{ #category : 'querying' }
MCPMethodChangeIndex >> versionsOfBehaviorNamed: aBehaviorName selector: aSelector upTo: lastNumber [
	"The versions of the method in the entries up to lastNumber, oldest first."

	| versions previousNumber |
	versions := OrderedCollection new.
	previousNumber := 0.
	(self numbersOfChangesToBehaviorNamed: aBehaviorName selector: aSelector) do: [ :number |
			number <= lastNumber ifTrue: [
					self entryNumbered: number do: [ :entry |
							self
								add: (MCPMethodVersionInfo fromChange: entry content time: (log timeAt: entry ifAbsent: [ nil ]))
								to: versions
								following: number = (previousNumber + 1).
							previousNumber := number ] ] ].
	^ versions
]
