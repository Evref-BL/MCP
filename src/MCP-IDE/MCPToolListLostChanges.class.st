"
Concrete history_lost_change_list tool. It lists the changes the sessions since the image's last save made and the image lacks, the last change to each element with the source restoring it installs, a page at a time.
"
Class {
	#name : 'MCPToolListLostChanges',
	#superclass : 'MCPToolLostChanges',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

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

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: { self offsetInputProperty };
		  required: #(  );
		  additionalProperties: false;
		  yourself
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
