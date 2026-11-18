"
Tests for the sentence the answers of package_search, class_search, class_get, method_search and repository_change_list end with when the image lost changes to the packages or classes they are about, naming history_lost_change_list.

Each test runs with a change history of its own, in a memory directory, as MCPToolLostChangesTest does: the session in progress starts from a save point, and a lost session is a log file of its own whose first entry follows the same save point, written while a monitor on it records what the test changes. The test then takes those changes back out of the image without logging them, as a crash or a stop without saving leaves the image.
"
Class {
	#name : 'MCPLostChangeNoticeTest',
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
MCPLostChangeNoticeTest class >> shouldLogWithEpicea [
	"These tests record changes in a change history of their own and read them back."

	^ true
]

{ #category : 'private - classes' }
MCPLostChangeNoticeTest >> addedClassName [
	"A class a lost session added."

	^ 'MCPLostChangeNoticeTempAdded'
]

{ #category : 'private - asserting' }
MCPLostChangeNoticeTest >> assertNoticeAboutSavedClass [

	self assert:
		((self summaryOf: 'class_get' with: { (#name -> self savedClassName) }) endsWith:
			 (self noticeOfOneChangeTo: self savedClassName))
]

{ #category : 'private - classes' }
MCPLostChangeNoticeTest >> createLoggedClassNamed: aClassName [
	"As createClassNamed:superclassName:slots:classSlots: does, but logged, as a lost session adding a class logs it."

	| builder |
	builder := Object << aClassName asSymbol.
	builder package: self generatedPackageName.
	builder tag: self generatedTagName.
	^ builder install
]

{ #category : 'private - asserting' }
MCPLostChangeNoticeTest >> denyNoticeAboutSavedClass [

	self summariesAboutSavedClass do: [ :each | self deny: (each includesSubstring: 'history_lost_change_list') description: each ]
]

{ #category : 'private - history' }
MCPLostChangeNoticeTest >> inSessionLoggedTo: aLog do: aBlock [

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
MCPLostChangeNoticeTest >> inSessionNamed: aName do: aBlock [
	"Run aBlock in a session started from the same save as the session in progress, logged to a file of its own."

	^ self inSessionLoggedTo: (self logNamed: aName startingAt: savePoint) do: aBlock
]

{ #category : 'private - history' }
MCPLostChangeNoticeTest >> logNamed: aName startingAt: aReference [
	"A session's log, whose first entry follows aReference: the save the session started from."

	| log |
	log := EpLog newWithStore: (OmBlockFileStore named: aName inDirectory: historyDirectory).
	log addEntryWith: EpSessionStart new tags: [ :tags | tags at: EpLog priorReferenceKey put: aReference ].
	^ log
]

{ #category : 'private - history' }
MCPLostChangeNoticeTest >> loseAMethod [
	"The saved class, to which a session stopped without saving added a method the image lacks."

	| class |
	class := self savedClass.
	self inSessionNamed: 'lost' do: [ class compile: 'rescuedValue ^ 42' classified: 'accessing' ].
	self removeSelector: #rescuedValue from: class.
	^ class
]

{ #category : 'private - asserting' }
MCPLostChangeNoticeTest >> noticeOfOneChangeTo: aName [
	"The sentence an answer ends with when the image lost one change to aName, after the space that separates it."

	^ String streamContents: [ :stream |
		  stream << ' Since its last save, the image lost 1 change to ' << aName << ': history_lost_change_list lists it.' ]
]

{ #category : 'private - classes' }
MCPLostChangeNoticeTest >> savedClass [
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
MCPLostChangeNoticeTest >> savedClassName [
	"A class the image had when it was saved."

	^ 'MCPLostChangeNoticeTempSaved'
]

{ #category : 'running' }
MCPLostChangeNoticeTest >> setUp [
	"The memory file system is one for the whole image, so each test has a directory of its own in it."

	super setUp.
	originalMonitor := EpMonitor current.
	originalMonitorWasEnabled := originalMonitor isEnabled.
	originalMonitor disable.
	historyDirectory := (FileSystem memory / ('mcp-lost-change-notice-test-' , UUID new asString36)) ensureCreateDirectory.
	savePoint := OmReference globalName: 'saved' localName: '2'.
	tempMonitor := EpMonitor newWithLog: (self logNamed: 'current' startingAt: savePoint).
	EpMonitor current: tempMonitor.
	tempMonitor enable
]

{ #category : 'private - calling' }
MCPLostChangeNoticeTest >> summariesAboutSavedClass [
	"What package_search, class_search, class_get and method_search answer about the saved class and its package."

	^ {
		  (self summaryOf: 'package_search' with: { (#name -> self generatedPackageName) }).
		  (self summaryOf: 'class_search' with: { (#package -> self generatedPackageName) }).
		  (self summaryOf: 'class_get' with: { (#name -> self savedClassName) }).
		  (self summaryOf: 'method_search' with: { (self searchScope: { (#packages -> { self generatedPackageName }) }) }) }
]

{ #category : 'private - calling' }
MCPLostChangeNoticeTest >> summaryOf: aToolName with: someArguments [

	^ self summaryFrom: (self callToolNamed: aToolName withArguments: someArguments asDictionary)
]

{ #category : 'running' }
MCPLostChangeNoticeTest >> tearDown [

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
MCPLostChangeNoticeTest >> testClassGetSaysWhatTheClassLostOnEveryPage [

	self loseAMethod.
	#( 0 1 ) do: [ :offset |
			self assert: ((self summaryOf: 'class_get' with: {
						  (#name -> self savedClassName).
						  (#offset -> offset) }) endsWith: (self noticeOfOneChangeTo: self savedClassName)) ]
]

{ #category : 'tests' }
MCPLostChangeNoticeTest >> testClassSearchSaysWhatThePackageOfItsClassesLost [
	"A class the lost session added is in no list: the package of the classes listed counts it."

	| class |
	class := self savedClass.
	self inSessionNamed: 'lost' do: [
			self createLoggedClassNamed: self addedClassName.
			class compile: 'rescuedValue ^ 42' classified: 'accessing' ].
	self removeClassNamed: self addedClassName.
	self removeSelector: #rescuedValue from: class.
	self assert:
		((self summaryOf: 'class_search' with: { (#package -> self generatedPackageName) }) endsWith:
			 (String streamContents: [ :stream |
					  stream << ' Since its last save, the image lost 2 changes to ' << self generatedPackageName
					  << ': history_lost_change_list lists them.' ]))
]

{ #category : 'tests' }
MCPLostChangeNoticeTest >> testMethodSearchScopedToPackagesOrClassesSaysWhatTheyLost [
	"Each package and class the scope names that lost the change is named, and the change counts once. A search its scope does not narrow is about no package or class."

	self loseAMethod.
	self assert:
		((self summaryOf: 'method_search' with: { (self searchScope: { (#packages -> { self generatedPackageName }) }) }) endsWith:
			 (self noticeOfOneChangeTo: self generatedPackageName)).
	self assert:
		((self summaryOf: 'method_search' with: { (self searchScope: { (#classes -> { (self savedClassName , ' class') }) }) })
			 endsWith: (self noticeOfOneChangeTo: self savedClassName)).
	self assert: ((self summaryOf: 'method_search' with: { (self searchScope: {
					   (#packages -> { self generatedPackageName }).
					   (#classes -> { self savedClassName }) }) }) endsWith: (self noticeOfOneChangeTo:
				  (String streamContents: [ :stream | stream << self generatedPackageName << ' and ' << self savedClassName ]))).
	self deny:
		((self summaryOf: 'method_search' with: { (#selector -> 'rescuedValue') }) includesSubstring: 'history_lost_change_list')
]

{ #category : 'tests' }
MCPLostChangeNoticeTest >> testPackageSearchSaysWhatThePackageLost [
	"In every run of the lost-changes eval, the agent's first call was package_search on the package, and nothing in the answer said the work on it was gone."

	self loseAMethod.
	self assert: ((self summaryOf: 'package_search' with: { (#name -> self generatedPackageName) }) endsWith:
			 (self noticeOfOneChangeTo: self generatedPackageName))
]

{ #category : 'tests' }
MCPLostChangeNoticeTest >> testReadsEarlierSessionsOncePerImageSession [
	"Once a session is over its file no longer changes, so the first answer reads it and the next ones compare the image with what it read."

	self loseAMethod.
	self assertNoticeAboutSavedClass.
	(historyDirectory / 'lost.ombu') delete.
	self assertNoticeAboutSavedClass
]

{ #category : 'tests' }
MCPLostChangeNoticeTest >> testRepositoryChangeListSaysWhatItsPackagesLost [
	"The image matches the repository's files and git sees no change: what the image lost is on neither side."

	| repository |
	self loseAMethod.
	repository := IceLibgitRepository new.
	repository name: 'MCP Lost Change Notice Repository'.
	repository location: FileLocator imageDirectory.
	repository workingCopy addPackageNamed: self generatedPackageName.
	self
		assert: (MCPToolListRepositoryChanges new summaryForChangesOf: repository imageModifiedPackages: #(  ) modifiedPaths: #(  ))
		equals:
			'Repository MCP Lost Change Notice Repository has no uncommitted changes: the image matches its files and git sees none.'
			, (self noticeOfOneChangeTo: self generatedPackageName)
]

{ #category : 'tests' }
MCPLostChangeNoticeTest >> testSaysNothingOfAChangeTheImageReplacedSince [
	"Where the image changed the element since its save, it went on without the lost change: history_lost_change_list lists it as a conflict, and the other answers leave it to that list."

	| class |
	class := self savedClass.
	self inSessionNamed: 'lost' do: [ class compile: 'value ^ 1' classified: 'accessing' ].
	self withoutEpiceaDuring: [ class compile: 'value ^ 0' classified: 'accessing' ].
	class compile: 'value ^ 2' classified: 'accessing'.
	self assert:
		(((self dataFrom: (self callToolNamed: 'history_lost_change_list' withArguments: Dictionary new)) at: #changes) first
			 includesKey: #conflict).
	self denyNoticeAboutSavedClass
]

{ #category : 'tests' }
MCPLostChangeNoticeTest >> testSaysNothingOfWhatTheSessionInProgressRemoved [
	"Removing what a lost session added puts the element back as it was saved, which comparing it with the image cannot tell from losing it. The history of the session in progress tells, whether it changed the element before the answer that read it or after."

	| class |
	class := self savedClass.
	self inSessionNamed: 'lost' do: [
			class compile: 'first ^ 1' classified: 'accessing'.
			class compile: 'second ^ 2' classified: 'accessing' ].
	self removeSelector: #first from: class.
	self removeSelector: #second from: class.
	class compile: 'first ^ 3' classified: 'accessing'.
	class removeSelector: #first.
	self assertNoticeAboutSavedClass.
	class compile: 'second ^ 4' classified: 'accessing'.
	class removeSelector: #second.
	self denyNoticeAboutSavedClass
]

{ #category : 'tests' }
MCPLostChangeNoticeTest >> testSaysNothingOnceRestored [

	self loseAMethod.
	self assertNoticeAboutSavedClass.
	self callToolNamed: 'history_lost_change_restore' withArguments: Dictionary new.
	self denyNoticeAboutSavedClass
]

{ #category : 'tests' }
MCPLostChangeNoticeTest >> testSaysNothingOnceTheImageIsSaved [
	"A save without quitting logs a snapshot, the save point from then on: the image saved went on without what earlier sessions lost."

	self loseAMethod.
	self assertNoticeAboutSavedClass.
	tempMonitor sessionSnapshot.
	self denyNoticeAboutSavedClass
]

{ #category : 'tests' }
MCPLostChangeNoticeTest >> testSaysNothingWhenTheImageLostNothing [
	"No session ran since the save, or the image holds what one changed: the answers read as they would without a history."

	| class |
	class := self savedClass.
	self denyNoticeAboutSavedClass.
	self inSessionNamed: 'held' do: [ class compile: 'heldValue ^ 1' classified: 'accessing' ].
	self denyNoticeAboutSavedClass
]
