"
Tests for history_lost_change_list and history_lost_change_restore.

Each test runs with a change history of its own, in a memory directory: the session in progress starts from a save point, and a lost session is a log file of its own whose first entry follows the same save point, written while a monitor on it records what the test changes. The test then takes those changes back out of the image without logging them, as a crash or a stop without saving leaves the image.
"
Class {
	#name : 'MCPToolLostChangesTest',
	#superclass : 'MCPToolAPITestCase',
	#instVars : [
		'originalMonitor',
		'originalMonitorWasEnabled',
		'tempMonitor',
		'historyDirectory',
		'savePoint'
	],
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'testing' }
MCPToolLostChangesTest class >> shouldLogWithEpicea [
	"These tests record changes in a change history of their own and recover them from it."

	^ true
]

{ #category : 'private - classes' }
MCPToolLostChangesTest >> addedClassName [
	"A class a lost session added."

	^ 'MCPToolLostChangesTempAdded'
]

{ #category : 'private - classes' }
MCPToolLostChangesTest >> createLoggedClassNamed: aClassName [
	"As createClassNamed:superclassName:slots:classSlots: does, but logged, as a lost session adding a class logs it."

	| builder |
	builder := Object << aClassName asSymbol.
	builder package: self generatedPackageName.
	builder tag: self generatedTagName.
	builder slots: #( #rescued ).
	^ builder install
]

{ #category : 'private - history' }
MCPToolLostChangesTest >> inSessionLoggedTo: aLog do: aBlock [

	| monitor |
	tempMonitor disable.
	monitor := EpMonitor newWithLog: aLog.
	EpMonitor current: monitor.
	monitor enable.
	[ aBlock value ] ensure: [
			monitor disable.
			aLog store flush.
			EpMonitor current: tempMonitor.
			tempMonitor enable ]
]

{ #category : 'private - history' }
MCPToolLostChangesTest >> inSessionNamed: aName do: aBlock [
	"Run aBlock in a session started from the same save as the session in progress, logged to a file of its own."

	^ self inSessionNamed: aName startingAt: savePoint do: aBlock
]

{ #category : 'private - history' }
MCPToolLostChangesTest >> inSessionNamed: aName startingAt: aReference do: aBlock [

	^ self inSessionLoggedTo: (self logNamed: aName startingAt: aReference) do: aBlock
]

{ #category : 'private - calling' }
MCPToolLostChangesTest >> list [

	^ self callToolNamed: 'history_lost_change_list' withArguments: Dictionary new
]

{ #category : 'private - history' }
MCPToolLostChangesTest >> logNamed: aName startingAt: aReference [
	"A session's log, whose first entry follows aReference: the save the session started from."

	| log |
	log := EpLog newWithStore: (OmBlockFileStore named: aName inDirectory: historyDirectory).
	log addEntryWith: EpSessionStart new tags: [ :tags | tags at: EpLog priorReferenceKey put: aReference ].
	^ log
]

{ #category : 'private - history' }
MCPToolLostChangesTest >> methodDefinitionOf: aSelector returning: anInteger [
	"A method of the saved class as Epicea records it, without compiling it."

	^ (RGMethodDefinition className: self savedClassName selector: aSelector isMetaSide: false)
		  sourceCode: (String streamContents: [ :stream | stream << aSelector << ' ^ ' << anInteger printString ]);
		  protocol: #accessing;
		  yourself
]

{ #category : 'private - calling' }
MCPToolLostChangesTest >> restore: someArguments [

	^ self callToolNamed: 'history_lost_change_restore' withArguments: someArguments asDictionary
]

{ #category : 'private - classes' }
MCPToolLostChangesTest >> savedClass [
	"The class the image had at its save, with one method, created without logging it."

	| class |
	class := self
		         createClassNamed: self savedClassName
		         superclassName: 'Object'
		         slots: #(  )
		         classSlots: #(  ).
	self withoutEpiceaDuring: [ class compile: 'value ^ 0' classified: 'accessing' ].
	^ class
]

{ #category : 'private - classes' }
MCPToolLostChangesTest >> savedClassName [
	"A class the image had when it was saved."

	^ 'MCPToolLostChangesTempSaved'
]

{ #category : 'running' }
MCPToolLostChangesTest >> setUp [
	"The memory file system is one for the whole image, so each test has a directory of its own in it."

	super setUp.
	originalMonitor := EpMonitor current.
	originalMonitorWasEnabled := originalMonitor isEnabled.
	originalMonitor disable.
	historyDirectory := (FileSystem memory / ('mcp-lost-changes-test-' , UUID new asString36)) ensureCreateDirectory.
	savePoint := OmReference globalName: 'saved' localName: '2'.
	tempMonitor := EpMonitor newWithLog: (self logNamed: 'current' startingAt: savePoint).
	EpMonitor current: tempMonitor.
	tempMonitor enable
]

{ #category : 'running' }
MCPToolLostChangesTest >> tearDown [

	tempMonitor ifNotNil: [ tempMonitor disable ].
	originalMonitor ifNotNil: [
			EpMonitor current: originalMonitor.
			originalMonitorWasEnabled ifTrue: [ originalMonitor enable ] ].
	historyDirectory ifNotNil: [ historyDirectory ensureDeleteAll ].
	self removeClassNamed: self addedClassName.
	self removeClassNamed: self savedClassName.
	super tearDown
]

{ #category : 'tests' }
MCPToolLostChangesTest >> testAClassRemovedTakesItsMethodsWithIt [
	"Changing a method and then removing its class leaves one change: the class removed."

	| changes class |
	class := self savedClass.
	self inSessionNamed: 'lost' do: [
			class compile: 'value ^ 1' classified: 'accessing'.
			class removeFromSystem ].
	class := self savedClass.
	changes := (self dataFrom: self list) at: #changes.
	self assert: (changes collect: [ :each | each at: #element ]) equals: { self savedClassName }.
	self assert: (changes first at: #change) equals: 'class removed'.
	self restore: #(  ).
	self deny: (Smalltalk globals includesKey: self savedClassName asSymbol)
]

{ #category : 'tests' }
MCPToolLostChangesTest >> testAFileCutShortIsReadUpToWhereItBreaks [
	"A crash can cut the last entry short. What comes before it is still listed, and a warning says the rest is not."

	| class result stream |
	class := self savedClass.
	self inSessionNamed: 'lost' do: [ class compile: 'value ^ 1' classified: 'accessing' ].
	self withoutEpiceaDuring: [ class compile: 'value ^ 0' classified: 'accessing' ].
	stream := ZnCharacterWriteStream on: (historyDirectory / 'lost.ombu') binaryWriteStream encoding: #utf8.
	[
		stream setToEnd.
		stream nextPutAll: 'OmEntry { #tags : { #prior : OmRef' ] ensure: [ stream close ].
	result := self list.
	self assert: ((self dataFrom: result) at: #changes) size equals: 1.
	self assert: ((self warningsFrom: result) first beginsWith:
			 'lost.ombu could not be read past its entry 2, so the changes it records after it are not listed: ')
]

{ #category : 'tests' }
MCPToolLostChangesTest >> testAMethodWhoseClassIsMissingIsNotRestored [

	| result |
	self
		inSessionNamed: 'lost'
		do: [ (self createLoggedClassNamed: self addedClassName) compile: 'rescued ^ rescued' classified: 'accessing' ].
	self removeClassNamed: self addedClassName.
	result := self restore: { (#elements -> { (self addedClassName , '>>rescued') }) }.
	self assert: (self resultIndicatesError: result).
	self assert: (self summaryFrom: result) equals: (String streamContents: [ :stream |
				 stream << 'Restored no lost change.' << String lf << self addedClassName << '>>rescued: Its class ' << self addedClassName
				 << ' is not in the image.' ])
]

{ #category : 'tests' }
MCPToolLostChangesTest >> testANameNoLostChangeHasIsNotRestored [

	| result |
	result := self restore: { (#elements -> #( 'Nowhere>>nothing' )) }.
	self assert: (self resultIndicatesError: result).
	self assert: (self summaryFrom: result) equals: (String streamContents: [ :stream |
			 stream << 'Restored no lost change.' << String lf << 'Nowhere>>nothing: No session since the image was last saved changed it.' ])
]

{ #category : 'tests' }
MCPToolLostChangesTest >> testCountsWhatTheImageAlreadyHolds [
	"Loading the code again, or the session in progress, may have made a lost change already: it is not listed, but counted, so the answer still says the history was read."

	| class result |
	class := self savedClass.
	self inSessionNamed: 'lost' do: [ class compile: 'value ^ 1' classified: 'accessing' ].
	result := self list.
	self
		assert: (self summaryFrom: result)
		equals: 'Nothing is lost: the image holds every change of the 1 session since it was last saved.'.
	self assert: ((self dataFrom: result) at: #alreadyInImageCount) equals: 1
]

{ #category : 'tests' }
MCPToolLostChangesTest >> testLeavesOutSessionsOfAnotherSave [

	| class result |
	class := self savedClass.
	self
		inSessionNamed: 'other'
		startingAt: (OmReference globalName: 'saved' localName: '1')
		do: [ class compile: 'otherValue ^ 1' classified: 'accessing' ].
	self removeSelector: #otherValue from: class.
	result := self list.
	self assert: (self summaryFrom: result) equals: 'No session ran since the image was last saved, so it lost nothing.'
]

{ #category : 'tests' }
MCPToolLostChangesTest >> testLeavesOutWhatALoadChanged [
	"The files a load loaded hold what it changed, so that is not work lost. A Pharo that logs loads logs each change with the load as its trigger."

	| load loadClass lostLog |
	loadClass := self class environment at: #EpMonticelloVersionsLoad ifAbsent: [ ^ self skip: 'This Pharo does not log loads.' ].
	self savedClass.
	lostLog := self logNamed: 'lost' startingAt: savePoint.
	"Sent by name: the class is not in every Pharo."
	load := lostLog addEntryWith: (loadClass perform: #versionNames: with: #( 'MCP-Tests-Generated-1' )) tags: [ :tags |  ].
	lostLog
		addEntryWith: (EpMethodAddition method: (self methodDefinitionOf: #loadedValue returning: 1))
		tags: [ :tags | tags at: EpLog triggererReferenceKey put: (lostLog referenceTo: load) ].
	lostLog addEntryWith: (EpMethodAddition method: (self methodDefinitionOf: #rescuedValue returning: 2)) tags: [ :tags |  ].
	lostLog store flush.
	self
		assert: (((self dataFrom: self list) at: #changes) collect: [ :each | each at: #element ])
		equals: { (self savedClassName , '>>rescuedValue') }
]

{ #category : 'tests' }
MCPToolLostChangesTest >> testListsAndRestoresALargeHistoryQuickly [
	"Previews over 2,530 history entries took 15 minutes. A lost session of 1,000 entries, 25 versions of 40 methods, is read once, into one change per method."

	| class listed lostLog restored selectors start |
	self timeLimit: 2 minutes.
	class := self savedClass.
	selectors := (1 to: 40) collect: [ :index |
		             (String streamContents: [ :stream | stream << 'value' << index printString ]) asSymbol ].
	self withoutEpiceaDuring: [
		selectors do: [ :each | class compile: (self methodDefinitionOf: each returning: 0) sourceCode classified: 'accessing' ] ].
	lostLog := self logNamed: 'lost' startingAt: savePoint.
	1 to: 25 do: [ :version |
			selectors do: [ :each |
					lostLog
						addEntryWith: (EpMethodModification
								 oldMethod: (self methodDefinitionOf: each returning: version - 1)
								 newMethod: (self methodDefinitionOf: each returning: version))
						tags: [ :tags |  ] ] ].
	lostLog store flush.
	start := Time millisecondClockValue.
	listed := self list.
	self assert: (Time millisecondsSince: start) < 10000.
	start := Time millisecondClockValue.
	restored := self restore: #(  ).
	self assert: (Time millisecondsSince: start) < 30000.
	self
		assert: (self summaryFrom: listed)
		equals: 'Listed 25 of 40 lost changes, from 1 session since the image was last saved. Next page: offset 25.'.
	self assert: (self summaryFrom: restored) equals: 'Restored 40 lost changes.'.
	self assert: (class >> #value40) sourceCode equals: 'value40 ^ 25'
]

{ #category : 'tests' }
MCPToolLostChangesTest >> testListsTheLastChangeToEachElementAcrossSessions [
	"Every session since the save starts from it, so the last session written has the last word."

	| change class data |
	class := self savedClass.
	self inSessionNamed: 'lost-1' do: [
			class compile: 'value ^ 1' classified: 'accessing'.
			class compile: 'value ^ 2' classified: 'accessing' ].
	self inSessionNamed: 'lost-2' do: [ class compile: 'value ^ 3' classified: 'accessing' ].
	self withoutEpiceaDuring: [ class compile: 'value ^ 0' classified: 'accessing' ].
	data := self dataFrom: self list.
	self assert: (data at: #sessions) equals: #( 'lost-1.ombu' 'lost-2.ombu' ).
	self assert: (data at: #changes) size equals: 1.
	change := (data at: #changes) first.
	self assert: (change at: #change) equals: 'method modified'.
	self assert: (change at: #source) equals: 'value ^ 3'
]

{ #category : 'tests' }
MCPToolLostChangesTest >> testListsWhatASessionStoppedWithoutSavingAdded [

	| change class data result |
	class := self savedClass.
	self inSessionNamed: 'lost' do: [ class compile: 'rescuedValue ^ 42' classified: 'rescuing' ].
	self removeSelector: #rescuedValue from: class.
	result := self list.
	data := self dataFrom: result.
	self assert: (self summaryFrom: result) equals: 'Listed 1 lost change, from 1 session since the image was last saved.'.
	self assert: (data at: #sessions) equals: #( 'lost.ombu' ).
	change := (data at: #changes) first.
	self assert: (change at: #element) equals: self savedClassName , '>>rescuedValue'.
	self assert: (change at: #change) equals: 'method added'.
	self assert: (change at: #protocol) equals: 'rescuing'.
	self assert: (change at: #source) equals: 'rescuedValue ^ 42'.
	self deny: (change includesKey: #conflict)
]

{ #category : 'tests' }
MCPToolLostChangesTest >> testNothingIsLostOnceTheImageIsSaved [
	"A save without quitting logs a snapshot in the session in progress, the save point from then on: the image saved went on without what earlier sessions lost."

	| class |
	class := self savedClass.
	self inSessionNamed: 'lost' do: [ class compile: 'rescuedValue ^ 42' classified: 'rescuing' ].
	self removeSelector: #rescuedValue from: class.
	self assert: ((self dataFrom: self list) at: #lostCount) equals: 1.
	tempMonitor sessionSnapshot.
	self assert: (self summaryFrom: self list) equals: 'No session ran since the image was last saved, so it lost nothing.'
]

{ #category : 'tests' }
MCPToolLostChangesTest >> testReadsTheSavedSessionPastItsSave [
	"The session that saved went on in its own file: what it wrote before the save is in the image, what it wrote after is lost."

	| class data savedLog |
	class := self savedClass.
	savedLog := self logNamed: 'saved' startingAt: (OmReference globalName: 'older' localName: '7').
	self inSessionLoggedTo: savedLog do: [
			class compile: 'savedValue ^ 1' classified: 'accessing'.
			class compile: 'rescuedValue ^ 2' classified: 'accessing' ].
	self removeSelector: #savedValue from: class.
	self removeSelector: #rescuedValue from: class.
	data := self dataFrom: self list.
	self assert: (data at: #sessions) equals: #( 'saved.ombu' ).
	self assert: ((data at: #changes) collect: [ :each | each at: #element ]) equals: { (self savedClassName , '>>rescuedValue') }
]

{ #category : 'tests' }
MCPToolLostChangesTest >> testRefusesAChangeTheImageMadeSinceItsSave [
	"Restoring would discard what the session in progress made: the list shows both, restore refuses unless forced."

	| change class result |
	class := self savedClass.
	self inSessionNamed: 'lost' do: [ class compile: 'value ^ 1' classified: 'accessing' ].
	self withoutEpiceaDuring: [ class compile: 'value ^ 0' classified: 'accessing' ].
	class compile: 'value ^ 2' classified: 'accessing'.
	change := ((self dataFrom: self list) at: #changes) first.
	self assert: (change at: #conflict) equals: 'The image changed it since it was saved: restoring discards that change.'.
	self assert: (change at: #inImage) equals: 'value ^ 2'.
	result := self restore: #(  ).
	self assert: (self resultIndicatesError: result).
	self assert: (self summaryFrom: result) equals: (String streamContents: [ :stream |
				 stream << 'Restored no lost change.' << String lf << self savedClassName
				 << '>>value: The image changed it since it was saved: force restores it anyway, discarding that change.' ]).
	self assert: (class >> #value) sourceCode equals: 'value ^ 2'.
	result := self restore: { (#force -> true) }.
	self assert: (self summaryFrom: result) equals: 'Restored 1 lost change.'.
	self assert: (class >> #value) sourceCode equals: 'value ^ 1'
]

{ #category : 'tests' }
MCPToolLostChangesTest >> testRefusesBringingBackWhatTheImageRemovedSince [
	"Removing what a lost session added leaves the image as it was saved, and only the history of the session in progress tells that from a loss: restoring would bring back what was removed, so it is refused unless forced."

	| class |
	class := self savedClass.
	self inSessionNamed: 'lost' do: [ class compile: 'rescuedValue ^ 42' classified: 'accessing' ].
	self removeSelector: #rescuedValue from: class.
	class compile: 'rescuedValue ^ 7' classified: 'accessing'.
	class removeSelector: #rescuedValue.
	self
		assert: (((self dataFrom: self list) at: #changes) first at: #conflict)
		equals: 'The image removed it since it was saved: restoring brings it back.'.
	self assert: (self resultIndicatesError: (self restore: #(  ))).
	self deny: (class includesSelector: #rescuedValue)
]

{ #category : 'tests' }
MCPToolLostChangesTest >> testRestoresARemoval [

	| class data result |
	class := self savedClass.
	self inSessionNamed: 'lost' do: [ class removeSelector: #value ].
	self withoutEpiceaDuring: [ class compile: 'value ^ 0' classified: 'accessing' ].
	data := self dataFrom: self list.
	self assert: ((data at: #changes) first at: #change) equals: 'method removed'.
	result := self restore: #(  ).
	self assert: (self summaryFrom: result) equals: 'Restored 1 lost change.'.
	self deny: (class includesSelector: #value)
]

{ #category : 'tests' }
MCPToolLostChangesTest >> testRestoresEveryLostChangeInAnOrderThatWorks [
	"The class added is defined before its comment is set and its method compiled, whatever order they were made in."

	| added class data result |
	class := self savedClass.
	self inSessionNamed: 'lost' do: [
			added := self createLoggedClassNamed: self addedClassName.
			class compile: 'value ^ 1' classified: 'accessing'.
			added compile: 'rescued ^ rescued' classified: 'accessing'.
			added comment: 'A class a lost session added.' ].
	self removeClassNamed: self addedClassName.
	self withoutEpiceaDuring: [ class compile: 'value ^ 0' classified: 'accessing' ].
	result := self restore: #(  ).
	data := self dataFrom: result.
	self assert: (self summaryFrom: result) equals: 'Restored 4 lost changes.'.
	self assert: ((data at: #restored) collect: [ :each | (each at: #element) -> (each at: #change) ]) equals: {
			(self addedClassName -> 'class added').
			(self addedClassName -> 'comment changed').
			(self savedClassName , '>>value' -> 'method modified').
			(self addedClassName , '>>rescued' -> 'method added') }.
	added := self classNamed: self addedClassName.
	self assert: (added hasSlotNamed: #rescued).
	self assert: added comment equals: 'A class a lost session added.'.
	self assert: (added >> #rescued) sourceCode equals: 'rescued ^ rescued'.
	self assert: (class >> #value) sourceCode equals: 'value ^ 1'.
	self
		assert: (self summaryFrom: self list)
		equals: 'Nothing is lost: the image holds every change of the 1 session since it was last saved.'
]

{ #category : 'tests' }
MCPToolLostChangesTest >> testRestoresOnlyTheElementsNamed [
	"An element is named as the list writes it, give or take blanks and a #."

	| class result |
	class := self savedClass.
	self inSessionNamed: 'lost' do: [
			class compile: 'first ^ 1' classified: 'accessing'.
			class compile: 'second ^ 2' classified: 'accessing' ].
	self removeSelector: #first from: class.
	self removeSelector: #second from: class.
	result := self restore: { (#elements -> { (self savedClassName , ' >> #first') }) }.
	self assert: (self summaryFrom: result) equals: 'Restored 1 lost change.'.
	self assert: (class includesSelector: #first).
	self deny: (class includesSelector: #second)
]

{ #category : 'tests' }
MCPToolLostChangesTest >> testSaysWhatTheImageAlreadyHolds [

	| class result |
	class := self savedClass.
	self inSessionNamed: 'lost' do: [ class compile: 'value ^ 1' classified: 'accessing' ].
	result := self restore: { (#elements -> { (self savedClassName , '>>value') }) }.
	self deny: (self resultIndicatesError: result).
	self
		assert: (self summaryFrom: result)
		equals:
		(String streamContents: [ :stream |
			 stream << 'Nothing to restore: the image already holds ' << self savedClassName << '>>value.' ])
]

{ #category : 'tests' }
MCPToolLostChangesTest >> testTheToolsAreFoundButNotAdvertised [
	"Recovering is rare, so the tools wait in the history group for a search that names it."

	| found |
	found := ((self dataFrom:
		           (self callToolNamed: 'tool_search' withArguments: { (#query -> 'lost changes after a crash') } asDictionary)) at:
		          #tools) collect: [ :each | each at: #name ].
	#( 'history_lost_change_list' 'history_lost_change_restore' ) do: [ :name |
			| tool |
			tool := self toolRegistry toolNamed: name ifAbsent: [ self fail: name ].
			self assert: (found includes: name).
			self assert: tool groupName equals: MCPTool historyGroupName.
			self deny: (self toolRegistry isToolAdvertisedNamed: name) ]
]

{ #category : 'tests' }
MCPToolLostChangesTest >> testTheToolsTakeWhatTheyNeed [
	"No confirm: the list is the preview, and a restore acts. Nor a history directory: what is lost is defined by this image's own save."

	self assert: (MCPToolListLostChanges new inputSchema properties collect: [ :each | each name ] as: Array) equals: #( 'offset' ).
	self
		assert: (MCPToolRestoreLostChanges new inputSchema properties collect: [ :each | each name ] as: Array)
		equals: #( 'elements' 'force' )
]
