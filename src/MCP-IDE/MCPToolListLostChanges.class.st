"
Concrete history_lost_change_list tool. It lists the changes the sessions since the image's last save made and the image lacks, the last change to each element with the source restoring it installs, a page at a time.

The tool is discoverable, not advertised, so the answers about a package or class the image lost changes to name it, with the sentence noticeForPackagesNamed:classesNamed: writes.
"
Class {
	#name : 'MCPToolListLostChanges',
	#superclass : 'MCPToolLostChanges',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'notices' }
MCPToolListLostChanges class >> noticeForPackagesNamed: somePackageNames classesNamed: someClassNames [
	"The sentence that says the image lost changes to some of those packages or classes since its last save, naming this tool, or nil when it lost none. A change counts once, whether of a package or of a class named. An answer must never fail for it, so a history that cannot be read says nothing."

	| lostByName |
	lostByName := [ MCPSessionLostChanges current lostChangesToPackagesNamed: somePackageNames classesNamed: someClassNames ]
		              on: Error
		              do: [ ^ nil ].
	lostByName ifEmpty: [ ^ nil ].
	^ self
		  noticeOf: (lostByName flatCollect: [ :each | each value ]) asIdentitySet size
		  changesTo: (lostByName collect: [ :each | each key ])
]

{ #category : 'private - notices' }
MCPToolListLostChanges class >> noticeOf: aCount changesTo: someNames [
	"Since its last save, the image lost 4 changes to Zoo-Core: history_lost_change_list lists them. The tool is named, not how to reach it: whether it is listed or found through the catalog is the server's setting."

	^ String streamContents: [ :stream |
			  stream << 'Since its last save, the image lost ' << aCount printString << (aCount = 1
				   ifTrue: [ ' change' ]
				   ifFalse: [ ' changes' ]) << ' to ' << (MCPCommandError joinedNames: someNames upTo: 3) << ': ' << self toolName
			  << ' lists ' << (aCount = 1
				   ifTrue: [ 'it.' ]
				   ifFalse: [ 'them.' ]) ]
]

{ #category : 'notices' }
MCPToolListLostChanges class >> summary: aSummary notingLostChangesToPackagesNamed: somePackageNames classesNamed: someClassNames [
	"aSummary, followed by the sentence that says what the image lost of those packages and classes since its last save, when it lost something. An answer about code that looks complete is where an agent learns that the work on it is not."

	^ (self
		   noticeForPackagesNamed: (MCPScopeQuery distinctNamesAmong: (somePackageNames select: [ :each | each isNotNil ]))
		   classesNamed: (MCPScopeQuery distinctNamesAmong: (someClassNames select: [ :each | each isNotNil ])))
		  ifNil: [ aSummary ]
		  ifNotNil: [ :notice |
				  String streamContents: [ :stream |
						  stream
							  << aSummary;
							  space;
							  << notice ] ]
]

{ #category : 'metadata' }
MCPToolListLostChanges class >> toolName [

	^ 'history_lost_change_list'
]

{ #category : 'metadata' }
MCPToolListLostChanges >> annotations [

	^ MCPStructureToolAnnotations readOnly
]

{ #category : 'metadata' }
MCPToolListLostChanges >> buildInputSchema [

	^ MCPStructureInputSchema properties: { self offsetInputProperty } required: #(  )
]

{ #category : 'private - execution' }
MCPToolListLostChanges >> dataFor: request from: aLostChangeQuery [

	| data lostChanges page |
	lostChanges := aLostChangeQuery lostChanges.
	page := MCPPaginationResult
		        fromEntries: lostChanges
		        limit: self defaultPageLimit
		        offset: (request integerArgumentNamed: 'offset').
	data := Dictionary new.
	data at: #changes put: (page entries collect: [ :each | each asDictionary ] as: Array).
	data at: #lostCount put: lostChanges size.
	data at: #alreadyInImageCount put: aLostChangeQuery changes size - lostChanges size.
	data at: #sessions put: aLostChangeQuery sessionNames.
	page nextOffset ifNotNil: [ :offset | data at: #nextOffset put: offset ].
	^ data
]

{ #category : 'metadata' }
MCPToolListLostChanges >> defaultPageLimit [
	"A change carries its source, so a page holds fewer of them than of names."

	^ 25
]

{ #category : 'metadata' }
MCPToolListLostChanges >> description [

	^ 'List what earlier sessions changed since the image was last saved and the image lacks, as a crash or a stop without saving leaves it: the last change to each method, class and class comment, with what history_lost_change_restore installs for it.'
]

{ #category : 'private - results' }
MCPToolListLostChanges >> keysStatedInSummary [
	"The summary reads 'Listed 25 of 40 lost changes, from 2 sessions since the image was last saved. The image already holds 3 more. Next page: offset 25.'"

	^ #( lostCount alreadyInImageCount nextOffset )
]

{ #category : 'private - results' }
MCPToolListLostChanges >> successSummaryForData: data [
	"How many changes are lost, of how many sessions since the save, and how many more the image holds already, which says the history was read even when nothing is lost."

	| listedCount lostCount sessionsText |
	(data at: #sessions) ifEmpty: [ ^ 'No session ran since the image was last saved, so it lost nothing.' ].
	sessionsText := self textForCount: (data at: #sessions) size noun: 'session'.
	lostCount := data at: #lostCount.
	lostCount = 0 ifTrue: [
			^ String streamContents: [ :stream |
				  stream << 'Nothing is lost: the image holds every change of the ' << sessionsText << ' since it was last saved.' ] ].
	listedCount := (data at: #changes) size.
	^ String streamContents: [ :stream |
			  stream << 'Listed '.
			  listedCount < lostCount ifTrue: [
					  stream
						  print: listedCount;
						  << ' of ' ].
			  stream << (self textForCount: lostCount noun: 'lost change') << ', from ' << sessionsText
			  << ' since the image was last saved.'.
			  (data at: #alreadyInImageCount) > 0 ifTrue: [
				  stream << ' The image already holds ' << (data at: #alreadyInImageCount) printString << ' more.' ].
			  data at: #nextOffset ifPresent: [ :offset | stream << ' Next page: offset ' << offset printString << '.' ] ]
]

{ #category : 'metadata' }
MCPToolListLostChanges >> title [

	^ 'List Lost Changes'
]
