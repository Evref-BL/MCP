"
Common base class for tests that exercise MCP tools through their public API.
"
Class {
	#name : 'MCPToolAPITestCase',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolAPITestCase class >> isAbstract [

	^ self = MCPToolAPITestCase or: [ super isAbstract ]
]

{ #category : 'private - calling' }
MCPToolAPITestCase >> argumentNamed: anArgumentName in: aDictionary default: defaultValue [

	aDictionary ifNil: [ ^ defaultValue ].
	^ aDictionary
		  at: anArgumentName asSymbol
		  ifAbsent: [
		  aDictionary at: anArgumentName asString ifAbsent: [ defaultValue ] ]
]

{ #category : 'private - calling' }
MCPToolAPITestCase >> aroundToolCall: aBlock [

	^ aBlock value
]

{ #category : 'private - calling' }
MCPToolAPITestCase >> callDiscoveredToolNamed: aToolName withArguments: someArguments [

	^ self callRawToolNamed: 'tool_call' withArguments: {
			  (#toolName -> aToolName).
			  (#arguments -> someArguments) } asDictionary
]

{ #category : 'private - calling' }
MCPToolAPITestCase >> callRawToolNamed: aToolName withArguments: someArguments [

	^ self aroundToolCall: [
			  self mcpWithoutObservabilityExport
				  rpcToolCall: aToolName
				  withParams: someArguments ]
]

{ #category : 'private - calling' }
MCPToolAPITestCase >> callToolNamed: aToolName withArguments: someArguments [

	(MCPToolRegistry isStaticTool: aToolName) ifTrue: [
		^ self callRawToolNamed: aToolName withArguments: someArguments ].
	^ self
		  callDiscoveredToolNamed: aToolName
		  withArguments: someArguments
]

{ #category : 'private - results' }
MCPToolAPITestCase >> dataFrom: aResult [

	self
		deny: ((self structuredContentFrom: aResult)
				 at: #isError
				 ifAbsent: [ false ])
		description: (self summaryFrom: aResult).
	^ (self structuredContentFrom: aResult) at: #data
]

{ #category : 'private - results' }
MCPToolAPITestCase >> errorFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #error
]

{ #category : 'private - compatibility' }
MCPToolAPITestCase >> expectedRefactoringWarningCauseClassNames [

	^ #( 'RBBreakingChangeChecksFailedWarning'
	     'RBRefactoringWarning' )
]

{ #category : 'private - compatibility' }
MCPToolAPITestCase >> expectedSyntaxErrorNoticeClassName [

	^ PharoCompatibility syntaxErrorNoticeClassName
]

{ #category : 'private - compatibility' }
MCPToolAPITestCase >> expectedUndeclaredVariableNoticeClassNames [

	^ #( 'OCUndeclaredVariableWarning' 'OCUndeclaredVariableNotice'
	     'OCCompilationError' )
]

{ #category : 'private - parsing' }
MCPToolAPITestCase >> parsedRequestForTool: aTool arguments: someArguments [

	^ aTool parsedRequestFromToolRequest:
		  (self
			   unvalidatedToolRequestForTool: aTool
			   arguments: someArguments)
]

{ #category : 'support' }
MCPToolAPITestCase >> searchScope: scopeAssociations [

	^ #scope -> scopeAssociations asDictionary
]

{ #category : 'private - results' }
MCPToolAPITestCase >> structuredContentFrom: aResult [

	^ aResult at: #structuredContent
]

{ #category : 'private - results' }
MCPToolAPITestCase >> summaryFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #summary
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

	^ (self structuredContentFrom: aResult)
		  at: #warnings
		  ifAbsent: [ #(  ) ]
]
