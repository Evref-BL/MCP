"
The versions of one method that the image's change history records, oldest first and numbered from 1, so that a number keeps naming the same version while the session goes on. method_version_list lists them and method_restore installs one.

They come from the session in progress and from the earlier sessions it continues. A session's first entry follows the entry of the session before at which the image was last saved: that file's entries up to it are part of the image's history, and its own first entry leads further back. The changes after that entry are lost ones, which the image never had. The query follows that chain through the directory of the session in progress, as long as the earlier files it reads stay under a size limit, so that the first query stays short.

Each file is read once into an MCPMethodChangeIndex, and only the entries of the method asked for are read again. The class keeps the indexes: the session in progress's, brought up to date at each query, and the earlier files', which no longer change.
"
Class {
	#name : 'MCPMethodVersionQuery',
	#superclass : 'Object',
	#instVars : [
		'log',
		'directory'
	],
	#classInstVars : [
		'sessionIndex',
		'lock',
		'earlierIndexes'
	],
	#category : 'MCP-IDE-Queries',
	#package : 'MCP-IDE',
	#tag : 'Queries'
}

{ #category : 'private - indexes' }
MCPMethodVersionQuery class >> critical: aBlock [
	"Tool calls run in processes of their own, and two may read the indexes at once."

	lock ifNil: [ lock := Mutex new ].
	^ lock critical: aBlock
]

{ #category : 'private - indexes' }
MCPMethodVersionQuery class >> earlierIndexOf: aFileReference [
	"The index of an earlier session's file. The file no longer changes, so it is read once."

	^ self critical: [
			  earlierIndexes ifNil: [ earlierIndexes := Dictionary new ].
			  earlierIndexes at: aFileReference ifAbsentPut: [
					  MCPMethodChangeIndex new
						  updateFrom: (EpLog freshFromFile: aFileReference);
						  yourself ] ]
]

{ #category : 'private - indexes' }
MCPMethodVersionQuery class >> earlierSessionsSizeLimit [
	"How many bytes of earlier sessions' files a query reads. Each file is read once, but the first query reads all of them besides the session in progress, so the limit keeps that one short."

	^ 2 * 1024 * 1024
]

{ #category : 'instance creation' }
MCPMethodVersionQuery class >> inCurrentSession [
	"The history the image's change history monitor keeps, written out first so that its last entries are read, with the earlier sessions in the directory it writes to. An image without a monitor keeps none."

	| store |
	EpMonitor hasCurrent ifFalse: [ ^ self onLog: nil directory: nil ].
	EpMonitor current sessionStore flush.
	store := EpMonitor current log store.
	^ self onLog: EpMonitor current log directory: (store writingFileReference ifNotNil: [ :file | file parent ])
]

{ #category : 'private - indexes' }
MCPMethodVersionQuery class >> indexOfSession: aLog [
	"The index of the session in progress, brought up to date. The class keeps one: a query over another log, as a test makes, replaces it, and drops the earlier sessions' indexes, which belonged to the other one's chain."

	^ self critical: [
			  (sessionIndex isNil or: [ sessionIndex key ~~ aLog store ]) ifTrue: [
					  sessionIndex := aLog store -> MCPMethodChangeIndex new.
					  earlierIndexes := Dictionary new ].
			  sessionIndex value updateFrom: aLog.
			  sessionIndex value ]
]

{ #category : 'instance creation' }
MCPMethodVersionQuery class >> onLog: anEpLogOrNil directory: aDirectoryOrNil [
	"A query over that history, where nil stands for an image that keeps none. The earlier sessions it continues are looked for in aDirectoryOrNil, and none when it is nil."

	^ self new
		  setLog: anEpLogOrNil directory: aDirectoryOrNil;
		  yourself
]

{ #category : 'private - history' }
MCPMethodVersionQuery >> indexesDo: aBlock [
	"aBlock gets the index of each file versions come from, newest first, with the number of its last entry that is the image's: the session in progress whole, then each earlier session up to the entry the one after it follows, while the earlier files read stay under the size limit."

	| file index reference size |
	index := self class indexOfSession: log.
	aBlock value: index value: index count.
	directory ifNil: [ ^ self ].
	size := 0.
	reference := index priorOfFirstEntry.
	[ reference isNull ] whileFalse: [
			file := OmFileStore fileReferenceForStoreNamed: reference globalName inDirectory: directory.
			file exists ifFalse: [ ^ self ].
			size := size + file size.
			size > self class earlierSessionsSizeLimit ifTrue: [ ^ self ].
			index := self class earlierIndexOf: file.
			aBlock value: index value: reference localName asInteger.
			reference := index priorOfFirstEntry ]
]

{ #category : 'initialization' }
MCPMethodVersionQuery >> setLog: anEpLogOrNil directory: aDirectoryOrNil [

	log := anEpLogOrNil.
	directory := aDirectoryOrNil
]

{ #category : 'querying' }
MCPMethodVersionQuery >> versionsOf: aBehavior selector: aSelector [
	"Every version of the method the history records, oldest first and numbered from 1: the earlier sessions', then this session's."

	| versions |
	log ifNil: [ ^ #(  ) ].
	versions := OrderedCollection new.
	self indexesDo: [ :index :lastNumber |
		versions addAllFirst: (index versionsOfBehaviorNamed: aBehavior name selector: aSelector upTo: lastNumber) ].
	versions doWithIndex: [ :each :number | each number: number ].
	^ versions asArray
]
