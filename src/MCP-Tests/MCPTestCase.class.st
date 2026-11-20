"
Common base class for MCP SUnit tests.
"
Class {
	#name : 'MCPTestCase',
	#superclass : 'TestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'testing' }
MCPTestCase class >> isAbstract [

	^ self = MCPTestCase or: [ super isAbstract ]
]

{ #category : 'support' }
MCPTestCase >> builtInGroupNames [

	^ {
		  MCPTool classesGroupName.
		  MCPTool debuggingGroupName.
		  MCPTool historyGroupName.
		  MCPTool methodsGroupName.
		  MCPTool packagesGroupName.
		  MCPTool repositoriesGroupName.
		  MCPTool runtimeGroupName.
		  MCPTool testsGroupName.
		  MCPTool toolCatalogGroupName.
		  MCPTool uiGroupName }
]

{ #category : 'support' }
MCPTestCase >> builtInPackageNames [
	"The packages MCP ships tools in: the catalog that the server dispatches through, and the image tools beside it. A tool defined anywhere else belongs to whoever put it there, including MCP's own test fixtures."

	^ #( 'MCP' 'MCP-IDE' )
]

{ #category : 'support' }
MCPTestCase >> builtInToolClasses [

	^ MCPTool concreteSubclasses select: [ :toolClass | self isBuiltIn: toolClass ]
]

{ #category : 'private - errors' }
MCPTestCase >> capture: aBlock [

	^ [
		  aBlock value.
		  self fail: 'Expected MCPCommandError' ]
		  on: MCPCommandError
		  do: [ :error | error ]
]

{ #category : 'private - classes' }
MCPTestCase >> classNamed: aClassName [

	^ self class environment at: aClassName asSymbol
]

{ #category : 'private - compatibility' }
MCPTestCase >> compilerReadsUndeclaredNamesAsNil [
	"Before Pharo 12, a name nothing declares compiles in an evaluation, and reads as nil there as in a Playground. From 12 on, an evaluation that only reads it fails to compile."

	^ (self class environment includesKey: #OCUndeclaredVariableNotice) not
]

{ #category : 'private - compatibility' }
MCPTestCase >> compilerRefusesShadowingTemporaries [
	"Before Pharo 12, a temporary that shadows an instance variable does not compile. From 12 on, it compiles and a critique reports it."

	^ self class environment includesKey: #OCShadowVariableWarning
]

{ #category : 'private - compatibility' }
MCPTestCase >> compilerReportsReadOnlyAssignmentsAsSyntaxErrors [
	"Before Pharo 12, an assignment to an argument fails to compile without the compiler naming the read-only variable: Pharo 11 reports a syntax error, Pharo 10 a notification. From 12 on, the compiler names it."

	^ self class environment includesKey: #OCStoreIntoReadOnlyVariableError
]

{ #category : 'private - classes' }
MCPTestCase >> createClassNamed: aClassName superclassName: aSuperclassName slots: someSlots classSlots: someClassSlots [

	^ self withoutEpiceaDuring: [
			  | builder superclass |
			  superclass := self classNamed: aSuperclassName.
			  self packageOrganizer ensurePackage: self generatedPackageName.
			  builder := superclass << aClassName asSymbol.
			  builder package: self generatedPackageName.
			  builder tag: self generatedTagName.
			  builder slots: someSlots.
			  builder classSlots: someClassSlots.
			  builder install ]
]

{ #category : 'private - packages' }
MCPTestCase >> createGeneratedPackageManifestWithNarrowFormatter [
	"The image-wide default formatter can agree with a package's own, and then a formatter read from the wrong manifest goes unnoticed. This one wraps at 20 columns, which no default does."

	| manifest |
	manifest := self
		            createClassNamed: self generatedManifestClassName
		            superclassName: 'PackageManifest'
		            slots: #(  )
		            classSlots: #(  ).
	self withoutEpiceaDuring: [
			manifest classSide
				compile: 'formatter ^ EFFormatter new installNewContext: (EFContext new maxLineLength: 20)'
				classified: 'formatting' ].
	^ manifest
]

{ #category : 'private - methods' }
MCPTestCase >> ensureMethodSource: aMethodSource protocol: aProtocol on: aBehavior [
	"An extension protocol only makes the method an extension when the package it names exists, so it is created on demand. The method is formatted the way the tools format it, with the formatter of its class's package, and compiled only when aBehavior does not itself define it so, in that protocol: a copy from a trait is not its own."

	| source tree |
	tree := RBParser parseMethod: aMethodSource.
	source := tree formattedCodeIn: aBehavior.
	aBehavior compiledMethodAt: tree selector ifPresent: [ :method |
			(method isFromTrait not and: [ method sourceCode = source and: [ method protocolName asString = aProtocol asString ] ])
				ifTrue: [ ^ self ] ].
	self withoutEpiceaDuring: [
			(aProtocol beginsWith: '*') ifTrue: [ self packageOrganizer ensurePackage: aProtocol allButFirst ].
			aBehavior compile: source classified: aProtocol ]
]

{ #category : 'private - compatibility' }
MCPTestCase >> epiceaLeavesTestsOut [
	"Whether Epicea leaves out of the history what a test changes, unless the test says it logs with Epicea. Older Pharo versions log it."

	^ TestCase canUnderstand: #shouldLogWithEpicea
]

{ #category : 'private - compatibility' }
MCPTestCase >> expectedRefactoringFailureCauseClassName [

	^ self refactoringsRefuseBreakingChanges
		  ifTrue: [ 'RBRefactoringFailure' ]
		  ifFalse: [ 'RBRefactoringError' ]
]

{ #category : 'private - classes' }
MCPTestCase >> fixtureClassNames [
	"The classes a test generates, which tearDown removes, last first, so a subclass goes before its superclass."

	^ #(  )
]

{ #category : 'private - classes' }
MCPTestCase >> generatedExtensionPackageName [
	"For a generated method whose package differs from its class's, which is what makes it an extension."

	^ 'MCP-Tests-Generated-Extensions'
]

{ #category : 'private - classes' }
MCPTestCase >> generatedExtensionProtocol [

	^ '*' , self generatedExtensionPackageName
]

{ #category : 'private - classes' }
MCPTestCase >> generatedManifestClassName [

	^ 'ManifestMCPTestsGenerated'
]

{ #category : 'private - classes' }
MCPTestCase >> generatedPackageName [
	"Classes a test generates live outside the versioned packages. A class added to and removed from a versioned one leaves Iceberg holding that package modified, though the source it ends with is the source it started with."

	^ 'MCP-Tests-Generated'
]

{ #category : 'private - classes' }
MCPTestCase >> generatedTagName [

	^ 'Internal'
]

{ #category : 'private - rpc' }
MCPTestCase >> handleJSON: aJSONString [

	^ self mcpWithoutObservabilityExport server messageProcessor handleJSON: aJSONString
]

{ #category : 'support' }
MCPTestCase >> isBuiltIn: aToolClass [
	"A tool MCP ships, as against one another project defines: whose conventions it answers to, not whether it is served, which loading its package decides."

	^ self builtInPackageNames includes: aToolClass package name
]

{ #category : 'private - packages' }
MCPTestCase >> mcpPackageNames [
	"The packages the baseline names for this Pharo version that the image has loaded. The baseline's own package is not among them."

	^ BaselineOfMCP allPackageNames select: [ :name | self packageOrganizer hasPackage: name ]
]

{ #category : 'private - observability' }
MCPTestCase >> mcpWithoutObservabilityExport [

	^ MCP new
		  observabilityExportDirectory: nil;
		  useContentAndStructuredContentToolResponses;
		  yourself
]

{ #category : 'private - repositories' }
MCPTestCase >> newRepositoryNamed: aRepositoryName location: aFileReference packageNames: somePackageNames [

	| repository |
	repository := IceLibgitRepository new.
	repository name: aRepositoryName.
	repository location: aFileReference.
	somePackageNames do: [ :each | repository workingCopy addPackageNamed: each ].
	^ repository
]

{ #category : 'private - compatibility' }
MCPTestCase >> refactoringsRefuseBreakingChanges [
	"Before Pharo 12, a refactoring that would break code fails a precondition, which forcing does not get past, and moving a slot stops on the methods that use it while it is between classes. From 12 on, the refactoring raises a warning that forcing gets past."

	^ self class environment includesKey: #RBRefactoringFailure
]

{ #category : 'private - classes' }
MCPTestCase >> removeClassNamed: aClassName [
	"Removing the class may leave a generated package empty, which then goes too. Looking for an absent package costs a sweep of all of them, so nothing is looked for when there was no class to remove."

	self class environment at: aClassName asSymbol ifPresent: [ :class |
			self withoutEpiceaDuring: [ class removeFromSystem ].
			self removeGeneratedPackagesIfEmpty ]
]

{ #category : 'private - classes' }
MCPTestCase >> removeFixtureClasses [

	self fixtureClassNames reverseDo: [ :each | self removeClassNamed: each ]
]

{ #category : 'private - packages' }
MCPTestCase >> removeGeneratedPackageManifest [

	self removeClassNamed: self generatedManifestClassName
]

{ #category : 'private - classes' }
MCPTestCase >> removeGeneratedPackagesIfEmpty [
	"A package left behind with nothing in it is as much noise as a dirty one. An extension package holds methods and no classes, so both have to be gone."

	{
		self generatedPackageName.
		self generatedExtensionPackageName } do: [ :name |
			(self packageOrganizer hasPackage: name) ifTrue: [
					| package |
					package := self packageOrganizer packageNamed: name.
					(package definedClasses isEmpty and: [ package methods isEmpty ]) ifTrue: [ self removePackageNamed: name ] ] ]
]

{ #category : 'private - packages' }
MCPTestCase >> removePackageNamed: aPackageName [

	self withoutEpiceaDuring: [
		(self packageOrganizer hasPackage: aPackageName) ifTrue: [ self packageOrganizer removePackage: aPackageName ] ]
]

{ #category : 'private - methods' }
MCPTestCase >> removeSelector: aSelector from: aBehavior [

	self withoutEpiceaDuring: [ (aBehavior includesSelector: aSelector) ifTrue: [ aBehavior removeSelector: aSelector ] ]
]

{ #category : 'private - classes' }
MCPTestCase >> restoreClassNamed: originalName renamedTo: renamedName [
	"A fixture class a test renamed gets its name back, and a copy a failed test left under the new name beside it goes. So does either name a method or a rename, the restoring one included, left in Undeclared, so that every run starts as the first. The fixture and every reference to it are in the fixtures' package, so the rename reads that package rather than the whole image."

	| globals original renamed |
	globals := self class environment.
	original := originalName asSymbol.
	renamed := renamedName asSymbol.
	self withoutEpiceaDuring: [
			((globals includesKey: original) and: [ globals includesKey: renamed ]) ifTrue: [ (globals at: renamed) removeFromSystem ].
			((globals includesKey: renamed) and: [ (globals includesKey: original) not ]) ifTrue: [
					(ReRenameClassRefactoring
						 model: (RBNamespace onEnvironment: (RBBrowserEnvironment new forPackageNames: #( 'MCP-Tests-Resources' )))
						 rename: renamedName
						 to: originalName) execute ] ].
	{
		original.
		renamed } do: [ :each | Undeclared removeKey: each ifAbsent: [ nil ] ]
]

{ #category : 'running' }
MCPTestCase >> runCase [
	"A test runs with a change history of its own, empty, in memory and off: what the tools say from the history, a change the image lost or a method it removed, is then the test's, not whatever the image went through before the run. Where Epicea logs what a test changes as it logs any work, before Pharo 12, a fixture made and then removed without logging would read, after the image restarts without saving, as work it lost, so the image's monitor is off besides. A test that reads the history it writes logs to a monitor of its own."

	| imageMonitor directory |
	imageMonitor := EpMonitor current.
	directory := (FileSystem memory / ('mcp-test-history-' , UUID new asString36)) ensureCreateDirectory.
	EpMonitor current: (EpMonitor newWithLog: (EpLog newWithStore: (OmBlockFileStore named: 'test' inDirectory: directory))).
	[
		self epiceaLeavesTestsOut
			ifTrue: [ super runCase ]
			ifFalse: [ imageMonitor disableDuring: [ super runCase ] ] ] ensure: [
			EpMonitor current: imageMonitor.
			directory ensureDeleteAll ]
]

{ #category : 'running' }
MCPTestCase >> tearDown [

	self removeFixtureClasses.
	super tearDown
]

{ #category : 'private - repositories' }
MCPTestCase >> withRepositories: repositories do: aBlock [

	| previousRepositories registry |
	registry := IceRepository registry.
	previousRepositories := registry copy.
	[
		registry removeAll.
		registry addAll: repositories.
		aBlock value ] ensure: [
			registry removeAll.
			registry addAll: previousRepositories ]
]

{ #category : 'private - execution' }
MCPTestCase >> withoutEpiceaDuring: aBlock [

	| value |
	EpMonitor disableDuring: [ value := aBlock value ].
	^ value
]

{ #category : 'private - compatibility' }
MCPTestCase >> worldStepsTheTranscript [
	"Before Pharo 13, the world loop steps the Transcript, which is the recorder while an evaluation runs. From 13 on, it no longer does."

	^ WorldState >> #runStepMethodsIn: sendsSelector: #stepGlobal
]
