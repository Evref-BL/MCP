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

	^ self callRawToolNamed: 'dispatch-tool' withArguments: {
			  (#toolName -> aToolName).
			  (#arguments -> someArguments) } asDictionary
]

{ #category : 'private - calling' }
MCPToolAPITestCase >> callRawToolNamed: aToolName withArguments: someArguments [

	^ self aroundToolCall: [
		  MCP new rpcToolCall: aToolName withParams: someArguments ]
]

{ #category : 'private - calling' }
MCPToolAPITestCase >> callToolNamed: aToolName withArguments: someArguments [

	| dispatchArguments dispatchToolName |
	(MCPToolRegistry isStaticTool: aToolName) ifTrue: [
		^ self callRawToolNamed: aToolName withArguments: someArguments ].
	dispatchToolName := self
		                    dispatchToolNameFor: aToolName
		                    arguments: someArguments.
	dispatchArguments := self
		                     dispatchArgumentsForToolNamed: aToolName
		                     arguments: someArguments.
	^ self callRawToolNamed: 'dispatch-tool' withArguments: {
			  (#toolName -> dispatchToolName).
			  (#arguments -> dispatchArguments) } asDictionary
]

{ #category : 'private - results' }
MCPToolAPITestCase >> dataFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #data
]

{ #category : 'private - calling' }
MCPToolAPITestCase >> dispatchArgumentsForToolNamed: aToolName arguments: someArguments [

	| normalized |
	normalized := someArguments
		              ifNil: [ Dictionary new ]
		              ifNotNil: [ someArguments copy ].
	({ 'edit-repository'. 'manage-change-history'. 'run-tests' }
		 includes: aToolName) ifTrue: [
			normalized removeKey: #operation ifAbsent: [ ].
			normalized removeKey: 'operation' ifAbsent: [ ] ].
	^ normalized
]

{ #category : 'private - calling' }
MCPToolAPITestCase >> dispatchToolNameFor: aToolName arguments: someArguments [

	| operation repositoryToolNames changeHistoryToolNames |
	operation := self
		             argumentNamed: 'operation'
		             in: someArguments
		             default: 'run'.
	aToolName = 'run-tests' ifTrue: [
			^ operation = 'coverage'
				  ifTrue: [ 'run-test-coverage' ]
				  ifFalse: [ 'run-test-batch' ] ].
	aToolName = 'manage-change-history' ifTrue: [
			changeHistoryToolNames := {
				                          ('listFiles'
				                           -> 'list-change-history-files').
				                          ('listEntries'
				                           -> 'list-change-history-entries').
				                          ('applyEntries'
				                           -> 'apply-change-history-entries').
				                          ('revertEntries'
				                           -> 'revert-change-history-entries') }
				                          asDictionary.
			^ changeHistoryToolNames at: operation ifAbsent: [ aToolName ] ].
	aToolName = 'edit-repository' ifTrue: [
			repositoryToolNames := {
				                       ('create' -> 'create-repository').
				                       ('attach' -> 'attach-repository').
				                       ('update' -> 'update-repository').
				                       ('verifyIdentity' -> 'verify-repository').
				                       ('diff' -> 'diff-repository').
				                       ('export' -> 'export-repository').
				                       ('commit' -> 'commit-repository').
				                       ('adoptHead' -> 'adopt-repository-head').
				                       ('fetch' -> 'fetch-repository').
				                       ('pull' -> 'pull-repository').
				                       ('push' -> 'push-repository').
				                       ('createBranch'
				                        -> 'create-repository-branch').
				                       ('switchBranch'
				                        -> 'switch-repository-branch') }
				                       asDictionary.
			^ repositoryToolNames at: operation ifAbsent: [ aToolName ] ].
	^ aToolName
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

	^ (self structuredContentFrom: aResult) at: #warnings
]
