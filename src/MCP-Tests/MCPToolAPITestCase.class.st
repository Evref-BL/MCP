"
Common base class for tests that exercise MCP tools through their public API.
"
Class {
	#name : 'MCPToolAPITestCase',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'testing' }
MCPToolAPITestCase class >> isAbstract [

	^ self = MCPToolAPITestCase or: [ super isAbstract ]
]

{ #category : 'private - results' }
MCPToolAPITestCase >> assertResult: aResult refusesArgumentsSaying: aString [
	"Arguments a tool refuses come back as a tool result for the model to correct, saying what is wrong, without the stack that found it."

	| summary |
	summary := self summaryFrom: aResult.
	self assert: (self resultIndicatesError: aResult) description: summary.
	self assert: (summary beginsWith: 'Invalid arguments for ') description: summary.
	self assert: (summary includesSubstring: aString) description: summary.
	self deny: ((self errorFrom: aResult) includesKey: #stackTrace)
]

{ #category : 'private - calling' }
MCPToolAPITestCase >> callDiscoveredToolNamed: aToolName withArguments: someArguments [

	^ self callRawToolNamed: 'tool_call' withArguments: {
			  (#name -> aToolName).
			  (#arguments -> someArguments) } asDictionary
]

{ #category : 'private - calling' }
MCPToolAPITestCase >> callRawToolNamed: aToolName withArguments: someArguments [

	^ self mcpWithoutObservabilityExport rpcToolCall: aToolName withParams: someArguments
]

{ #category : 'private - calling' }
MCPToolAPITestCase >> callToolNamed: aToolName withArguments: someArguments [

	| mcp |
	mcp := self mcpWithoutObservabilityExport.
	(mcp toolRegistry isToolAdvertisedNamed: aToolName) ifTrue: [ ^ self callRawToolNamed: aToolName withArguments: someArguments ].
	^ self callDiscoveredToolNamed: aToolName withArguments: someArguments
]

{ #category : 'private - results' }
MCPToolAPITestCase >> dataFrom: aResult [

	| structuredContent |
	structuredContent := self structuredContentFrom: aResult.
	self deny: (self resultIndicatesError: aResult) description: (self summaryFrom: aResult).
	^ structuredContent at: #data
]

{ #category : 'private - results' }
MCPToolAPITestCase >> entryForReference: aReference in: methods [

	^ methods
		  detect: [ :each |
				  | reference |
				  reference := String streamContents: [ :stream |
						               stream nextPutAll: (each at: #class).
						               (each at: #side ifAbsent: [ 'instance' ]) = 'class' ifTrue: [ stream nextPutAll: ' class' ].
						               stream
							               nextPutAll: '>>';
							               nextPutAll: (each at: #selector) ].
				  reference = aReference ]
		  ifNone: [ self fail: 'Missing method ' , aReference ]
]

{ #category : 'private - results' }
MCPToolAPITestCase >> errorFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #error
]

{ #category : 'private - compatibility' }
MCPToolAPITestCase >> expectedRefactoringWarningCauseClassNames [

	^ #( 'RBBreakingChangeChecksFailedWarning' 'RBRefactoringWarning' )
]

{ #category : 'private - compatibility' }
MCPToolAPITestCase >> expectedSyntaxErrorNoticeClassName [

	^ (self class environment
		   at: #OCSyntaxErrorNotice
		   ifAbsent: [ self class environment at: #RBSyntaxErrorNotice ifAbsent: [ self class environment at: #MCPSyntaxError ] ]) name
		  asString
]

{ #category : 'private - compatibility' }
MCPToolAPITestCase >> expectedUndeclaredVariableNoticeClassNames [

	^ #( 'OCUndeclaredVariableWarning' 'OCUndeclaredVariableNotice' 'OCCompilationError' )
]

{ #category : 'private - results' }
MCPToolAPITestCase >> inputPropertyNamesFor: aTool [

	^ aTool inputSchema properties collect: [ :each | each name ]
]

{ #category : 'private - fixtures' }
MCPToolAPITestCase >> packageSearchFixtureEntries [
	"What package_search's project filter keeps of the fixture project's packages."

	| tool |
	tool := MCPToolSearchPackages new.
	^ tool
		  queryEntriesForRequest:
		  (MCPToolRequest tool: tool arguments: { (#project -> self packageSearchFixtureProjectName) } asDictionary)
		  scopeQuery: (MCPPackageScopeQueryTestDouble new
				   projectRegistrations: { (self packageSearchFixtureRegistrationLoadedInImage: true) };
				   yourself)
]

{ #category : 'private - fixtures' }
MCPToolAPITestCase >> packageSearchFixturePackageNames [

	^ #( 'MCP-Tests-Resources' 'MCP-Tests-RunResources' )
]

{ #category : 'private - fixtures' }
MCPToolAPITestCase >> packageSearchFixtureProjectName [

	^ 'MCPPackageSearchFixture'
]

{ #category : 'private - fixtures' }
MCPToolAPITestCase >> packageSearchFixtureRegistrationLoadedInImage: aBoolean [

	^ MCPPackageSearchProjectRegistrationFixture
		  projectName: self packageSearchFixtureProjectName
		  packageNames: self packageSearchFixturePackageNames
		  loadedInImage: aBoolean
]

{ #category : 'private - results' }
MCPToolAPITestCase >> referencesOf: methodEntries [

	^ methodEntries collect: [ :each | MCPToolSearchMethods new methodEntryLabel: each ] as: Array
]

{ #category : 'private - results' }
MCPToolAPITestCase >> resultIndicatesError: aResult [
	"isError travels beside the structured content, not inside it."

	^ aResult at: #isError ifAbsent: [ false ]
]

{ #category : 'support' }
MCPToolAPITestCase >> searchScope: scopeAssociations [

	^ #scope -> scopeAssociations asDictionary
]

{ #category : 'private - calling' }
MCPToolAPITestCase >> searchScope: scopeAssociations side: aSideName [
	"Which sides to sweep lives in the scope, beside the entities it narrows."

	^ #scope -> (scopeAssociations , { (#side -> aSideName) }) asDictionary
]

{ #category : 'private - results' }
MCPToolAPITestCase >> structuredContentFrom: aResult [

	^ aResult at: #structuredContent
]

{ #category : 'private - results' }
MCPToolAPITestCase >> summaryFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #summary
]

{ #category : 'private - results' }
MCPToolAPITestCase >> summaryOf: aTool forArguments: arguments page: page [
	"The summary aTool gives a call with these arguments that found page, built without running the search."

	| request |
	request := aTool requestFromToolCallArguments: arguments.
	^ aTool successSummaryForRequest: request scopeQuery: (aTool scopeQueryFromRequest: request) page: page
]

{ #category : 'private - calling' }
MCPToolAPITestCase >> testReferenceForMethod: aCompiledMethod [

	^ String streamContents: [ :stream |
		  stream << aCompiledMethod methodClass name asString << '>>#' << aCompiledMethod selector asString ]
]

{ #category : 'private - results' }
MCPToolAPITestCase >> textFrom: aResult [
	"The text a caller reads: the summary, then the data as lines."

	^ (aResult at: #content) first at: #text
]

{ #category : 'support' }
MCPToolAPITestCase >> toolRegistry [

	^ self mcpWithoutObservabilityExport toolRegistry
]

{ #category : 'private - parsing' }
MCPToolAPITestCase >> unvalidatedToolRequestForTool: aTool arguments: someArguments [

	^ MCPToolRequest new
		  tool: aTool;
		  arguments: someArguments asDictionary;
		  yourself
]

{ #category : 'private - results' }
MCPToolAPITestCase >> warningsFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #warnings ifAbsent: [ #(  ) ]
]
