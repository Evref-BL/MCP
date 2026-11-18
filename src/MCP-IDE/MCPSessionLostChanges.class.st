"
What the image running now lost since its last save, read once per image session.

MCPLostChangeQuery reads the files of the sessions since the save, which are over and no longer change, so a reading holds while the image session goes on, logging to the same file, and until the image is saved without quitting, which moves the save point. The log announces each entry it adds: a snapshot says the image was saved, and a code change that the image went on without the lost change to its element, so nothing is read again until a save. What the image holds is compared with the reading at each call.

The reading is indexed by package and by class, so an answer about either says at little cost whether the image lost changes to it.
"
Class {
	#name : 'MCPSessionLostChanges',
	#superclass : 'Object',
	#instVars : [
		'session',
		'log',
		'file',
		'query',
		'changesByPackageName',
		'changesByClassName',
		'wasSaved'
	],
	#classInstVars : [
		'current'
	],
	#category : 'MCP-IDE-Queries',
	#package : 'MCP-IDE',
	#tag : 'Queries'
}

{ #category : 'instance creation' }
MCPSessionLostChanges class >> current [
	"The lost changes of the session in progress, read again only when the reading kept no longer holds for it."

	| file log |
	EpMonitor hasCurrent ifFalse: [
			MCPCommandError
				signalErrorCode: #ChangeHistoryUnavailable
				message: 'No current Pharo change history monitor is available.'
				details: Dictionary new ].
	EpMonitor current sessionStore flush.
	log := EpMonitor current log.
	file := log store writingFileReference.
	(current isNotNil and: [ current isReadingOf: log file: file ]) ifTrue: [ ^ current ].
	^ current := self log: log file: file
]

{ #category : 'instance creation' }
MCPSessionLostChanges class >> log: anEpLog file: aFileReference [
	"The lost changes of the session that logs to aFileReference through anEpLog, read now, before anything shares them."

	^ self new
		  setLog: anEpLog file: aFileReference;
		  yourself
]

{ #category : 'private - indexing' }
MCPSessionLostChanges >> changesByClassName [
	"A class's changes are those to its definition and comment and to its methods, on either side."

	^ changesByClassName ifNil: [ changesByClassName := query changes groupedBy: [ :each | each affectedClassName ] ]
]

{ #category : 'private - indexing' }
MCPSessionLostChanges >> changesByPackageName [

	^ changesByPackageName ifNil: [ changesByPackageName := query changes groupedBy: [ :each | each packageName ] ]
]

{ #category : 'announcement handling' }
MCPSessionLostChanges >> entryAdded: anEntryAdded [
	"A save without quitting moves the save point, so this reading no longer holds. A change the session makes to an element tells the reading that the image went on without the lost change to it."

	| event |
	event := anEntryAdded entry content.
	event mcpIsImageSave ifTrue: [ wasSaved := true ].
	query ifNotNil: [ query noteChangeInSessionInProgress: event ]
]

{ #category : 'testing' }
MCPSessionLostChanges >> isReadingOf: anEpLog file: aFileReference [
	"Whether this reading still holds for the session in progress: the same image session, logging to the same file, which has not saved the image since."

	^ session == Smalltalk session and: [ log == anEpLog and: [ file = aFileReference and: [ wasSaved not ] ] ]
]

{ #category : 'accessing' }
MCPSessionLostChanges >> lostChangesToPackagesNamed: somePackageNames classesNamed: someClassNames [
	"Each of those packages and classes the image lost changes to, in the order given, with those changes: the ones the image lacks and has not replaced since its save, compared with it now."

	| changesByName |
	changesByName := (somePackageNames collect: [ :each | each -> (self changesByPackageName at: each ifAbsent: [ #(  ) ]) ])
	                 , (someClassNames collect: [ :each | each -> (self changesByClassName at: each ifAbsent: [ #(  ) ]) ]).
	^ (changesByName collect: [ :each | each key -> (each value select: [ :change | change isLostWithoutConflict ]) ]) reject: [
		  :each | each value isEmpty ]
]

{ #category : 'accessing' }
MCPSessionLostChanges >> query [
	"The reading itself, which history_lost_change_list and history_lost_change_restore answer from."

	^ query
]

{ #category : 'initialization' }
MCPSessionLostChanges >> setLog: anEpLog file: aFileReference [
	"The log says when an entry is added, so a save is seen when its snapshot is logged, without reading the file again. Listening starts before the reading, so a save during it is not missed."

	session := Smalltalk session.
	log := anEpLog.
	file := aFileReference.
	wasSaved := false.
	anEpLog announcer weak when: EpEntryAdded send: #entryAdded: to: self.
	query := MCPLostChangeQuery log: anEpLog file: aFileReference.
	query changes
]
