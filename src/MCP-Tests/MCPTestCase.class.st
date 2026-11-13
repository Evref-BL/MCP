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
MCPTestCase >> builtInToolClasses [

	^ MCPTool concreteSubclasses select: [ :toolClass | toolClass isBuiltIn ]
]

{ #category : 'private - classes' }
MCPTestCase >> classNamed: aClassName [

	^ Smalltalk globals at: aClassName asSymbol
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

{ #category : 'private - compatibility' }
MCPTestCase >> coverageIsAvailable [
	"Pharo 11 brought CoverageCollector. Before it, MCP has no coverage to report."

	^ self class environment includesKey: #CoverageCollector
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
	"An extension protocol only makes the method an extension when the package it names exists, so it is created on demand. The method is formatted the way the tools format it, with the formatter of its class's package."

	self withoutEpiceaDuring: [
			| method selector |
			(aProtocol beginsWith: '*') ifTrue: [ self packageOrganizer ensurePackage: aProtocol allButFirst ].
			selector := aBehavior compile: aMethodSource classified: aProtocol.
			method := aBehavior >> selector.
			aBehavior compile: (method ast formattedCodeIn: aBehavior) classified: method protocol ]
]

{ #category : 'private - compatibility' }
MCPTestCase >> expectedRefactoringFailureCauseClassName [

	^ self refactoringsRefuseBreakingChanges
		  ifTrue: [ 'RBRefactoringFailure' ]
		  ifFalse: [ 'RBRefactoringError' ]
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

{ #category : 'private - observability' }
MCPTestCase >> mcpWithoutObservabilityExport [

	^ MCP new
		  observabilityExportDirectory: nil;
		  useContentAndStructuredContentToolResponses;
		  yourself
]

{ #category : 'private - compatibility' }
MCPTestCase >> refactoringsRefuseBreakingChanges [
	"Before Pharo 12, a refactoring that would break code fails a precondition, which forcing does not get past, and moving a slot stops on the methods that use it while it is between classes. From 12 on, the refactoring raises a warning that forcing gets past."

	^ self class environment includesKey: #RBRefactoringFailure
]

{ #category : 'private - classes' }
MCPTestCase >> removeClassNamed: aClassName [

	| classSymbol |
	classSymbol := aClassName asSymbol.
	self withoutEpiceaDuring: [
		(Smalltalk globals includesKey: classSymbol) ifTrue: [ (Smalltalk globals at: classSymbol) removeFromSystem ] ].
	self removeGeneratedPackagesIfEmpty
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

{ #category : 'private - execution' }
MCPTestCase >> withoutEpiceaDuring: aBlock [

	| value |
	EpMonitor disableDuring: [ value := aBlock value ].
	^ value
]

{ #category : 'private - compatibility' }
MCPTestCase >> worldStepsTheTranscriptGlobal [
	"Before Pharo 12, the world loop steps the Transcript global, which is the recorder while an evaluation runs. From 12 on, it steps the transcript of the tools."

	^ (WorldState >> #runStepMethodsIn:) literals anySatisfy: [ :each | each isVariableBinding and: [ each key = #Transcript ] ]
]
