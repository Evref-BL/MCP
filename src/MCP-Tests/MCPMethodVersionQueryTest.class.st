"
Tests the versions MCPMethodVersionQuery reads from a history of the test's own: how they are numbered and what each keeps, a compile and the change that formats it counted as one, and the earlier sessions a session continues. The methods are compiled out of every history, and the test logs the changes it means.
"
Class {
	#name : 'MCPMethodVersionQueryTest',
	#superclass : 'MCPTestCase',
	#instVars : [
		'log',
		'target'
	],
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPMethodVersionQueryTest >> compile: aSource [
	"The target's method compiled from aSource, out of every history."

	^ self withoutEpiceaDuring: [ target >> (target compile: aSource classified: 'testing') ]
]

{ #category : 'private' }
MCPMethodVersionQueryTest >> log: anEvent [

	log addEntryWith: anEvent tags: [ :tags |  ]
]

{ #category : 'private' }
MCPMethodVersionQueryTest >> logAdditionOf: aSource [

	self log: (EpMethodAddition method: (self compile: aSource))
]

{ #category : 'private' }
MCPMethodVersionQueryTest >> logModificationTo: aSource [
	"Replace the target's method by aSource, logging the change from the method it had."

	| previous |
	previous := target >> #probe.
	self log: (EpMethodModification oldMethod: previous newMethod: (self compile: aSource))
]

{ #category : 'private' }
MCPMethodVersionQueryTest >> logRemoval [

	self log: (EpMethodRemoval method: target >> #probe).
	self removeSelector: #probe from: target
]

{ #category : 'running' }
MCPMethodVersionQueryTest >> setUp [

	super setUp.
	target := self
		          createClassNamed: self targetName
		          superclassName: 'Object'
		          slots: #(  )
		          classSlots: #(  ).
	log := EpLog newWithStore: OmMemoryStore new
]

{ #category : 'private' }
MCPMethodVersionQueryTest >> sourcesOf: versions [

	^ versions collect: [ :each | each source ] as: Array
]

{ #category : 'private' }
MCPMethodVersionQueryTest >> targetName [

	^ 'MCPMethodVersionQueryTestTarget'
]

{ #category : 'running' }
MCPMethodVersionQueryTest >> tearDown [

	self removeClassNamed: self targetName.
	super tearDown
]

{ #category : 'tests' }
MCPMethodVersionQueryTest >> testAChangeToACommentIsNotAFormatting [

	self logAdditionOf: 'probe "one" ^ 1'.
	self logModificationTo: 'probe "two" ^ 1'.
	self assert: self versions size equals: 2
]

{ #category : 'tests' }
MCPMethodVersionQueryTest >> testACompileAndTheChangeThatFormatsItAreOneVersion [
	"method_compile compiles the source it is given, then the same source formatted: one version, the formatted one, which the method was added as."

	| versions |
	self logAdditionOf: 'probe ^1+2'.
	self logModificationTo: 'probe

	^ 1 + 2'.
	versions := self versions.
	self assert: versions size equals: 1.
	self assert: versions first kind equals: 'added'.
	self assert: versions first source equals: 'probe

	^ 1 + 2'.
	self assert: versions first previousSource isNil
]

{ #category : 'tests' }
MCPMethodVersionQueryTest >> testAFormattedVersionIsNotFormattedAgain [
	"method_compile formats once: two formattings in a row are two calls."

	self logAdditionOf: 'probe ^1+2'.
	self logModificationTo: 'probe ^ 1 + 2'.
	self logModificationTo: 'probe

	^ 1 + 2'.
	self assert: self versions size equals: 2
]

{ #category : 'tests' }
MCPMethodVersionQueryTest >> testAFormattingAfterAnotherEntryIsAVersionOfItsOwn [
	"Only the change that follows a compile at once is method_compile's formatting."

	self logAdditionOf: 'probe ^1+2'.
	self log: (EpMethodAddition method: (self compile: 'other ^ 0')).
	self logModificationTo: 'probe

	^ 1 + 2'.
	self assert: (self versions collect: [ :each | each kind ] as: Array) equals: #( 'added' 'modified' )
]

{ #category : 'tests' }
MCPMethodVersionQueryTest >> testAModificationKeepsWhatItReplaced [

	| modification |
	self logAdditionOf: 'probe ^ 1'.
	self logModificationTo: 'probe ^ 2'.
	modification := self versions last.
	self assert: modification previousSource equals: 'probe ^ 1'.
	self assert: modification previousProtocol equals: 'testing'
]

{ #category : 'tests' }
MCPMethodVersionQueryTest >> testAMoveToAnotherProtocolIsAVersion [

	| before |
	self logAdditionOf: 'probe ^ 1'.
	before := (target >> #probe) asEpiceaRingDefinition.
	self log: (EpMethodModification
			 oldMethod: before
			 newMethod: (self withoutEpiceaDuring: [ target >> (target compile: 'probe ^ 1' classified: 'other') ])).
	self assert: (self versions collect: [ :each | each protocol ] as: Array) equals: #( 'testing' 'other' )
]

{ #category : 'tests' }
MCPMethodVersionQueryTest >> testAMoveToAnotherProtocolRightBeforeARemovalIsPartOfIt [
	"Pharo 11 logs a removal as two changes: the method filed as unclassified, then removed with the protocol it had. They make one version, the removal."

	| before versions |
	self logAdditionOf: 'probe ^ 1'.
	before := (target >> #probe) asEpiceaRingDefinition.
	self log: (EpMethodModification
			 oldMethod: before
			 newMethod: (self withoutEpiceaDuring: [ target >> (target compile: 'probe ^ 1' classified: Protocol unclassified) ])).
	self log: (EpMethodRemoval method: before).
	self removeSelector: #probe from: target.
	versions := self versions.
	self assert: (versions collect: [ :each | each kind ] as: Array) equals: #( 'added' 'removed' ).
	self assert: versions last protocol equals: 'testing'
]

{ #category : 'tests' }
MCPMethodVersionQueryTest >> testARemovalKeepsWhatItRemoved [

	| removal |
	self logAdditionOf: 'probe ^ 1'.
	self logRemoval.
	removal := self versions last.
	self assert: removal isRemoval.
	self assert: removal source equals: 'probe ^ 1'.
	self assert: removal protocol equals: 'testing'.
	self assert: removal previousSource equals: 'probe ^ 1'.
	self assert: removal previousProtocol equals: 'testing'
]

{ #category : 'tests' }
MCPMethodVersionQueryTest >> testASessionThatHasLoggedNothingYetFollowsWhereTheImageWasSaved [
	"Started again from a save, a session's file holds no entry until a change is made, and its log's head is the entry the image was saved at: the versions are the earlier session's. A session store needs a file system that says it is writable, which a memory one does not."

	| directory store session |
	directory := (FileLocator temp asFileReference / ('mcp-method-version-query-test-' , UUID new asString36)) ensureCreateDirectory.
	[
		store := OmSessionStore newWithBaseLocator: directory.
		session := EpLog newWithStore: store.
		session addEntryWith: (EpMethodAddition method: (self compile: 'probe ^ 1')) tags: [ :tags |  ].
		store
			flush;
			resetWithNextStoreName.
		self
			assert: (self sourcesOf: ((MCPMethodVersionQuery onLog: session directory: directory) versionsOf: target selector: #probe))
			equals: #( 'probe ^ 1' ) ] ensure: [ directory ensureDeleteAll ]
]

{ #category : 'tests' }
MCPMethodVersionQueryTest >> testAVersionHasTheTimeTheLogGivesIt [
	"Pharo 14 no longer writes the time of an entry; an older one does, and a version says it."

	| time |
	time := DateAndTime now.
	log addEntryWith: (EpMethodAddition method: (self compile: 'probe ^ 1')) tags: [ :tags | tags at: EpLog timeKey put: time ].
	self assert: self versions first time equals: time.
	self assert: (self versions first asDictionary at: #time) equals: time asString
]

{ #category : 'tests' }
MCPMethodVersionQueryTest >> testAnImageWithoutAHistoryHasNoVersions [

	self assert: ((MCPMethodVersionQuery onLog: nil directory: nil) versionsOf: target selector: #probe) isEmpty
]

{ #category : 'tests' }
MCPMethodVersionQueryTest >> testChangesLoggedSinceTheLastQueryAreRead [

	self logAdditionOf: 'probe ^ 1'.
	self assert: self versions size equals: 1.
	self logModificationTo: 'probe ^ 2'.
	self assert: (self sourcesOf: self versions) equals: #( 'probe ^ 1' 'probe ^ 2' )
]

{ #category : 'tests' }
MCPMethodVersionQueryTest >> testEarlierSessionsComeFirstUpToWhereTheImageWasSaved [
	"The session follows the earlier one's first entry, where the image was last saved: the change the earlier session made after it was lost, and is no version."

	| directory earlier session versions |
	directory := (FileSystem memory / ('mcp-method-version-query-test-' , UUID new asString36)) ensureCreateDirectory.
	earlier := EpLog newWithStore: (OmBlockFileStore named: 'earlier' inDirectory: directory).
	earlier addEntryWith: (EpMethodAddition method: (self compile: 'probe ^ 1')) tags: [ :tags |  ].
	earlier
		addEntryWith: (EpMethodModification oldMethod: target >> #probe newMethod: (self compile: 'probe ^ 2'))
		tags: [ :tags |  ].
	earlier store flush.
	session := EpLog newWithStore: (OmBlockFileStore named: 'session' inDirectory: directory).
	session
		addEntryWith: (EpMethodModification oldMethod: target >> #probe newMethod: (self compile: 'probe ^ 3'))
		tags: [ :tags | tags at: EpLog priorReferenceKey put: (earlier referenceTo: earlier entries first) ].
	session store flush.
	versions := (MCPMethodVersionQuery onLog: session directory: directory) versionsOf: target selector: #probe.
	self assert: (self sourcesOf: versions) equals: #( 'probe ^ 1' 'probe ^ 3' ).
	self assert: (versions collect: [ :each | each number ] as: Array) equals: #( 1 2 )
]

{ #category : 'tests' }
MCPMethodVersionQueryTest >> testTheOtherSideHasVersionsOfItsOwn [

	self logAdditionOf: 'probe ^ 1'.
	self log: (EpMethodAddition method:
			 (self withoutEpiceaDuring: [ target classSide >> (target classSide compile: 'probe ^ 2' classified: 'testing') ])).
	self assert: (self sourcesOf: self versions) equals: #( 'probe ^ 1' ).
	self
		assert: (self sourcesOf: ((MCPMethodVersionQuery onLog: log directory: nil) versionsOf: target classSide selector: #probe))
		equals: #( 'probe ^ 2' )
]

{ #category : 'tests' }
MCPMethodVersionQueryTest >> testTwoCompilesInARowAreTwoVersions [

	self logAdditionOf: 'probe ^ 1'.
	self logModificationTo: 'probe ^ 2'.
	self assert: (self sourcesOf: self versions) equals: #( 'probe ^ 1' 'probe ^ 2' )
]

{ #category : 'tests' }
MCPMethodVersionQueryTest >> testVersionsAreNumberedFromTheOldest [

	| versions |
	self logAdditionOf: 'probe ^ 1'.
	self logModificationTo: 'probe ^ 2'.
	self logRemoval.
	versions := self versions.
	self assert: (versions collect: [ :each | each number ] as: Array) equals: #( 1 2 3 ).
	self assert: (versions collect: [ :each | each kind ] as: Array) equals: #( 'added' 'modified' 'removed' ).
	self assert: (self sourcesOf: versions) equals: #( 'probe ^ 1' 'probe ^ 2' 'probe ^ 2' )
]

{ #category : 'private' }
MCPMethodVersionQueryTest >> versions [
	"The versions of the target's probe in the test's history."

	^ (MCPMethodVersionQuery onLog: log directory: nil) versionsOf: target selector: #probe
]
