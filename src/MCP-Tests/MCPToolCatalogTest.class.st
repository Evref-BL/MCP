"
Tests tool_search, tool_get and tool_call: how a client finds a tool by what it does, reads its contract, and calls one the server does not advertise.
"
Class {
	#name : 'MCPToolCatalogTest',
	#superclass : 'MCPToolAPITestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPToolCatalogTest >> searchedToolNamesFor: aQuery [

	| data |
	data := self dataFrom: (self callToolNamed: 'tool_search' withArguments: { (#query -> aQuery) } asDictionary).
	^ (data at: #tools) collect: [ :each | each at: #name ]
]

{ #category : 'tests' }
MCPToolCatalogTest >> testCallToolInvokesDiscoverableToolAfterStaticConfiguration [

	| data result server |
	server := self mcpWithoutObservabilityExport.
	server advertiseTools: #( 'tool_search' 'tool_get' 'tool_call' ).
	result := server rpcToolCall: 'tool_call' withParams: {
			          (#name -> 'package_search').
			          (#arguments -> { (#query -> 'MCP') } asDictionary) } asDictionary.
	data := self dataFrom: result.
	self assert: (data at: #packages) isNotEmpty.
	self assert: ((data at: #packages) allSatisfy: [ :each | (each at: #package) includesSubstring: 'MCP' ])
]

{ #category : 'tests' }
MCPToolCatalogTest >> testCallToolInvokesTargetToolThroughServerPath [

	| data result |
	result := self callToolNamed: 'tool_call' withArguments: {
			          (#name -> 'package_search').
			          (#arguments -> { (#query -> 'MCP') } asDictionary) } asDictionary.
	data := self dataFrom: result.
	self assert: (data at: #packages) isNotEmpty.
	self assert: ((data at: #packages) allSatisfy: [ :each | (each at: #package) includesSubstring: 'MCP' ])
]

{ #category : 'tests' }
MCPToolCatalogTest >> testCallToolPreservesNestedValidationViolations [

	| error result violations |
	result := self callToolNamed: 'tool_call' withArguments: {
			          (#name -> 'method_reference_search').
			          (#arguments -> { (#query -> '') } asDictionary) } asDictionary.
	error := self errorFrom: result.
	violations := error at: #violations.
	self assert: (error at: #tool) equals: 'method_reference_search'.
	self assert: violations size equals: 1.
	self assert: (violations first at: #keyword) equals: #required.
	self assert: (violations first at: #expected) equals: 'query'
]

{ #category : 'tests' }
MCPToolCatalogTest >> testCatalogToolsUseOwningRegistry [

	| registry |
	registry := MCPToolRegistry default.
	#( 'tool_search' 'tool_get' ) do: [ :toolName |
			| tool |
			tool := registry toolNamed: toolName ifAbsent: [ self fail ].
			self assert: tool toolRegistry == registry ]
]

{ #category : 'tests' }
MCPToolCatalogTest >> testGetToolReturnsSchemaForCatalogTool [

	| contract getToolPropertyNames inputProperties result |
	result := self callToolNamed: 'tool_get' withArguments: { (#name -> 'repository_create') } asDictionary.
	contract := (self dataFrom: result) at: #tool.
	self assert: (contract at: #name) equals: 'repository_create'.
	self assert: contract keys asSet equals: #( name description group exposure annotations keywords inputSchema ) asSet.
	self assert: (contract at: #group) equals: 'repositories'.
	self assert: (contract at: #exposure) equals: 'discoverable'.
	self deny: ((contract at: #annotations) includesKey: #readOnlyHint).
	self assert: ((contract at: #keywords) includes: 'repo').
	inputProperties := ((contract at: #inputSchema) at: #properties) keys.
	self assert: inputProperties asSet equals: #( 'repository' 'location' 'packages' 'subdirectory' ) asSet.
	self assert: ((contract at: #inputSchema) at: #required) asArray equals: #( 'repository' ).
	getToolPropertyNames := MCPToolGetTool new inputSchema properties collect: [ :each | each name ].
	self assert: getToolPropertyNames equals: #( 'name' )
]

{ #category : 'tests' }
MCPToolCatalogTest >> testHandleJSONAnswersMissingRequiredArgumentsAsAToolError [
	"Arguments a tool's schema refuses are for the model to correct, so they come back as a tool result naming the argument, not as a protocol error a client may keep to itself."

	| response |
	response := self handleJSON:
		            '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"tool_call","arguments":{"name":"evaluate","arguments":{}}}}'.
	self deny: (response includesSubstring: '"code":-32602').
	self assert: (response includesSubstring: '"isError":true').
	self assert: (response includesSubstring: 'Invalid arguments for evaluate. code is required.')
]

{ #category : 'tests' }
MCPToolCatalogTest >> testHandleJSONAnswersToolCallArgumentsItRefusesAsAToolError [
	"tool_call checks its own arguments before it dispatches, and refuses them the same way."

	| response |
	response := self handleJSON:
		            '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"tool_call","arguments":{"toolName":"evaluate","arguments":{}}}}'.
	self deny: (response includesSubstring: '"code":-32602').
	self assert: (response includesSubstring: '"isError":true').
	self assert: (response includesSubstring: 'Invalid arguments for tool_call. name is required.').
	self assert: (response includesSubstring: 'toolName is not accepted here; expected one of arguments, name.')
]

{ #category : 'tests' }
MCPToolCatalogTest >> testSearchToolsAnswerPlainTextContent [
	"A catalog listing is read as prose, so the text block carries one line per tool instead of the canonical JSON. method_update is not advertised, which its line says."

	| lines result text |
	result := self callToolNamed: 'tool_search' withArguments: { (#query -> 'method signature') } asDictionary.
	text := self textFrom: result.
	lines := text lines.
	self assert: lines first equals: (self summaryFrom: result).
	self assert: (lines anySatisfy: [ :each | each beginsWith: 'method_update (not in the advertised list) - ' ]).
	self deny: (text includesSubstring: '"tools"')
]

{ #category : 'tests' }
MCPToolCatalogTest >> testSearchToolsAnswersBestMatchesWhenNoToolMatchesEveryWord [
	"A query word boosts a tool, it never gates it out: this query used to answer nothing because no tool matches all four words."

	| names |
	names := self searchedToolNamesFor: 'class update modify slots'.
	self assert: names first equals: 'class_update'.
	self assert: (names includes: 'class_create')
]

{ #category : 'tests' }
MCPToolCatalogTest >> testSearchToolsAnswersCatalogOverviewWhenNothingMatches [
	"Answering a bare zero is read as proof of absence, so a caller that matched nothing is told the size and vocabulary of the catalog instead."

	| result summary |
	result := self callToolNamed: 'tool_search' withArguments: { (#query -> 'frobnicate the widget') } asDictionary.
	summary := self summaryFrom: result.
	self assert: ((self dataFrom: result) at: #tools) isEmpty.
	self assert: (summary beginsWith: 'No tool matched. ').
	self assert: (summary includesSubstring: ' tools in ').
	self assert: (summary includesSubstring: 'classes ')
]

{ #category : 'tests' }
MCPToolCatalogTest >> testSearchToolsAnswersCatalogOverviewWithoutQuery [

	| result summary |
	result := self callToolNamed: 'tool_search' withArguments: Dictionary new.
	summary := self summaryFrom: result.
	self assert: ((self dataFrom: result) at: #tools) isEmpty.
	self assert: (summary includesSubstring: self toolRegistry tools size asString , ' tools in ').
	self assert: (summary includesSubstring: 'classes ')
]

{ #category : 'tests' }
MCPToolCatalogTest >> testSearchToolsCapsResultsAtResultLimit [

	| result tools |
	result := self callToolNamed: 'tool_search' withArguments: { (#query -> 'class method repository') } asDictionary.
	tools := (self dataFrom: result) at: #tools.
	self assert: tools size equals: MCPToolSearchTools new resultLimit.
	self assert: ((self summaryFrom: result) includesSubstring: 'matching tools, best first')
]

{ #category : 'tests' }
MCPToolCatalogTest >> testSearchToolsIncludesStaticSurface [

	| metadataByName result advertisedTool |
	result := self callToolNamed: 'tool_search' withArguments: { (#query -> 'classes') } asDictionary.
	metadataByName := (((self dataFrom: result) at: #tools) collect: [ :each | (each at: #name) -> each ]) asDictionary.
	self assert: (metadataByName includesKey: 'class_search').
	advertisedTool := self toolRegistry toolNamed: 'class_search' ifAbsent: [ self fail: 'Missing class_search tool' ].
	self assert: advertisedTool defaultExposure equals: 'static'
]

{ #category : 'tests' }
MCPToolCatalogTest >> testSearchToolsKeywordsAreSingleSearchTerms [

	| evaluateTool searchTool |
	searchTool := MCPToolSearchTools new.
	evaluateTool := MCPToolEvaluate new.
	self assert: searchTool keywords asSet equals: #( 'tool' 'tools' 'catalog' 'search' ) asSet.
	self assert: evaluateTool keywords asSet equals: #( 'evaluate' 'runtime' 'expression' 'smalltalk' 'code' ) asSet
]

{ #category : 'tests' }
MCPToolCatalogTest >> testSearchToolsLetDescriptionsRefineRankingWithoutAdmittingTools [
	"'the' appears in most descriptions, so a word found only there must not turn a tool into a result, but it still ranks a tool that already matches."

	self assert: (self searchedToolNamesFor: 'frobnicate the widget') isEmpty.
	self assert: (self searchedToolNamesFor: 'rename a method everywhere') first equals: 'method_update'
]

{ #category : 'tests' }
MCPToolCatalogTest >> testSearchToolsMatchesAgentGuidanceKeywords [

	| expectations |
	expectations := {
		                ('repo' -> 'repository_search').
		                ('identity' -> 'repository_identity_verify').
		                ('diff' -> 'repository_change_list').
		                ('stale' -> 'repository_reload').
		                ('SUnit' -> 'test_run').
		                ('file' -> 'history_file_list').
		                ('entry' -> 'history_entry_list').
		                ('recover' -> 'history_entry_apply').
		                ('window' -> 'screen_capture').
		                ('display' -> 'screen_capture').
		                ('watch' -> 'debug_watch').
		                ('debugger' -> 'debug_search').
		                ('refactor' -> 'class_update').
		                ('refactoring' -> 'method_update').
		                ('format' -> 'method_update') }.
	expectations do: [ :expectation |
			| names |
			names := (self toolRegistry toolsMatchingQuery: expectation key) collect: [ :each | each name ].
			self assert: (names includes: expectation value) ]
]

{ #category : 'tests' }
MCPToolCatalogTest >> testSearchToolsMatchesPluralQueryTerms [

	| expectations |
	expectations := {
		                ('classes' -> 'class_search').
		                ('repositories' -> 'repository_search').
		                ('traits' -> 'class_update').
		                ('variables' -> 'class_update').
		                ('refactorings' -> 'method_update') }.
	expectations do: [ :expectation |
			| names |
			names := (self toolRegistry toolsMatchingQuery: expectation key) collect: [ :each | each name ].
			self assert: (names includes: expectation value) ]
]

{ #category : 'tests' }
MCPToolCatalogTest >> testSearchToolsMatchesSpecializedClassKeywords [
	"class_update answers for every part of a class definition, so the words that used to lead to a tool each must still lead to it."

	#( 'trait composition' 'metaclass trait' 'classvar' 'pooldictionary' 'weak layout' 'rename class' 'recategorize' ) do: [ :query |
		self assert: ((self searchedToolNamesFor: query) includes: 'class_update') ]
]

{ #category : 'tests' }
MCPToolCatalogTest >> testSearchToolsRanksEveryToolFirstForItsOwnName [

	self toolRegistry tools do: [ :tool |
		self assert: (self toolRegistry toolsMatchingQuery: tool name) first name equals: tool name ]
]

{ #category : 'tests' }
MCPToolCatalogTest >> testSearchToolsRanksMoreMatchedWordsFirst [

	self assert: (self searchedToolNamesFor: 'method source') first equals: 'method_source_search'.
	self assert: (self searchedToolNamesFor: 'method version') first equals: 'method_version_list'.
	self assert: (self searchedToolNamesFor: 'repository reload') first equals: 'repository_reload'
]

{ #category : 'tests' }
MCPToolCatalogTest >> testSearchToolsReturnsDiscoverableMetadata [

	| createRepositoryMetadata data names result tools |
	result := self callToolNamed: 'tool_search' withArguments: { (#query -> 'repository') } asDictionary.
	data := self dataFrom: result.
	tools := data at: #tools.
	names := tools collect: [ :each | each at: #name ].
	self assert: (names includes: 'repository_search').
	self assert: (names includes: 'repository_create').
	self assert: (names includes: 'repository_attach').
	self assert: (names includes: 'repository_update').
	self assert: (names includes: 'repository_reload').
	self deny: (names includes: 'class_search').
	createRepositoryMetadata := tools detect: [ :each | (each at: #name) = 'repository_create' ].
	self assert: createRepositoryMetadata keys asSet equals: #( name description exposure arguments requiredArguments ) asSet.
	self assert: (createRepositoryMetadata at: #exposure) equals: 'discoverable'
]

{ #category : 'tests' }
MCPToolCatalogTest >> testSearchToolsUsesQueryOnlyContract [

	| propertyNames |
	propertyNames := MCPToolSearchTools new inputSchema properties collect: [ :each | each name ].
	self assert: propertyNames asArray equals: #( 'query' )
]

{ #category : 'tests' }
MCPToolCatalogTest >> testSingularSearchTermsUseGenericInflectionRules [

	| registry |
	registry := MCPToolRegistry new.
	self assert: (registry singularSearchTermFor: 'classes') equals: 'class'.
	self assert: (registry singularSearchTermFor: 'repositories') equals: 'repository'.
	self assert: (registry singularSearchTermFor: 'histories') equals: 'history'
]

{ #category : 'tests' }
MCPToolCatalogTest >> testToolGetOnAnUnknownNameSuggestsCloseNames [

	| error result |
	result := self callToolNamed: 'tool_get' withArguments: { (#name -> 'method_serch') } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorCode) equals: 'ToolNotFound'.
	self assert: ((error at: #suggestedTools) includes: 'method_source_search')
]

{ #category : 'tests' }
MCPToolCatalogTest >> testToolGetTextCarriesOnlyWhatACallNeeds [
	"A contract is read to build a call. Its annotations, exposure, group and keywords stay in the data for whoever catalogs tools, and the text leaves them out; whether the tool is advertised is said once, in the summary."

	| contract lines result |
	result := self callToolNamed: 'tool_get' withArguments: { (#name -> 'repository_create') } asDictionary.
	lines := (self textFrom: result) lines.
	self assert: lines first equals: 'Tool repository_create (not in the advertised list).'.
	self assert: lines second equals: 'tool:'.
	self assert: (lines includes: '  name: repository_create').
	self assert: (lines anySatisfy: [ :each | each beginsWith: '  description: ' ]).
	self assert: (lines includes: '  inputSchema:').
	#( '  annotations:' '  exposure:' '  group:' '  keywords:' ) do: [ :label |
		self deny: (lines anySatisfy: [ :each | each beginsWith: label ]) description: label ].
	contract := (self dataFrom: result) at: #tool.
	self assert: contract keys asSet equals: #( name description group exposure annotations keywords inputSchema ) asSet.
	result := self callToolNamed: 'tool_get' withArguments: { (#name -> 'class_search') } asDictionary.
	lines := (self textFrom: result) lines.
	self assert: lines first equals: 'Tool class_search.'.
	self assert: (lines includes: '  pageSize: ' , MCPToolSearchClasses new defaultPageLimit printString)
]

{ #category : 'tests' }
MCPToolCatalogTest >> testToolSearchCountsOneToolInTheSingular [

	| server |
	server := self mcpWithoutObservabilityExport
		          onlyTools: {
				          MCPToolSearchTools.
				          MCPToolEvaluate.
				          MCPToolGetClass.
				          MCPToolSearchClasses };
		          yourself.
	self
		assert: (self summaryFrom: (server rpcToolCall: 'tool_search' withParams: { (#query -> 'evaluate') } asDictionary))
		equals: '1 tool matched, best first.'.
	self
		assert: (self summaryFrom: (server rpcToolCall: 'tool_search' withParams: { (#query -> 'class') } asDictionary))
		equals: '2 tools matched, best first.'
]

{ #category : 'tests' }
MCPToolCatalogTest >> testToolSearchMarksToolsNotAdvertised [
	"A client that calls only the tools it lists cannot call the others by their bare name, so their lines say they are not listed. Once every tool is advertised, nothing is marked and no route is given."

	| lines result server summary text |
	server := self mcpWithoutObservabilityExport.
	server advertiseTools: #( 'tool_search' 'tool_get' 'tool_call' 'repository_search' ).
	result := server rpcToolCall: 'tool_search' withParams: { (#query -> 'repository') } asDictionary.
	text := self textFrom: result.
	lines := text lines.
	summary := self summaryFrom: result.
	self assert: lines first equals: summary.
	self assert: (lines anySatisfy: [ :each | each beginsWith: 'repository_search - ' ]).
	self assert: (lines anySatisfy: [ :each | each beginsWith: 'repository_create (not in the advertised list) - ' ]).
	self deny: (text includesSubstring: '(through tool_call)').
	self
		assert: ((((self dataFrom: result) at: #tools) detect: [ :each | (each at: #name) = 'repository_create' ]) at: #exposure)
		equals: 'discoverable'.
	server advertiseAllTools.
	result := server rpcToolCall: 'tool_search' withParams: { (#query -> 'repository') } asDictionary.
	text := self textFrom: result.
	self deny: (text includesSubstring: 'not in the advertised list').
	self deny: (text includesSubstring: 'not in your list').
	self deny: (text includesSubstring: 'Arguments:')
]

{ #category : 'tests' }
MCPToolCatalogTest >> testToolSearchNamesTheArgumentsOfAToolNotAdvertised [
	"A client has no schema for a tool outside its list, so that tool's line names its arguments, the required ones marked. A listed tool's line stays as it was: its schema is already in the client's list."

	| lines result server |
	server := self mcpWithoutObservabilityExport.
	server addTool: MCPExternalTestTool.
	server advertiseTools: #( 'tool_search' 'tool_call' ).
	result := server rpcToolCall: 'tool_search' withParams: { (#query -> 'tool external') } asDictionary.
	lines := (self textFrom: result) lines.
	self assert: (lines includes:
			 'tool_get (not in the advertised list) - Get a tool''s description and input schema by name. Arguments: name (required).').
	self assert: (lines includes:
			 'external_test_tool (not in the advertised list) - Test fixture for external MCP tool extensions. It takes no arguments.').
	self assert: (lines includes: 'tool_search - Search the whole tool catalog, best match first, including tools not in your list.').
	self
		assert: ((((self dataFrom: result) at: #tools) detect: [ :each | (each at: #name) = 'tool_get' ]) at: #requiredArguments)
		equals: #( 'name' )
]

{ #category : 'tests' }
MCPToolCatalogTest >> testToolSearchSendsAToolNotAdvertisedThroughToolCall [
	"A host may let a model call only the tools its own list holds, and the model cannot tell whether its host is one. The route every client has, tool_call, is the one the answer gives, for the tools marked as not advertised, shown with the first unlisted tool it lists."

	| result server summary unlisted |
	server := self mcpWithoutObservabilityExport.
	server advertiseTools: #( 'tool_search' 'tool_get' 'tool_call' 'repository_search' ).
	result := server rpcToolCall: 'tool_search' withParams: { (#query -> 'repository') } asDictionary.
	summary := self summaryFrom: result.
	unlisted := ((self dataFrom: result) at: #tools) detect: [ :each | (each at: #exposure) = 'discoverable' ].
	self assert: (summary endsWith:
			 ' Call a tool marked (not in the advertised list) through tool_call, with the arguments its line names: tool_call {"name": "'
			 , (unlisted at: #name) , '", "arguments": {...}}.').
	self deny: (summary includesSubstring: 'by name')
]

{ #category : 'tests' }
MCPToolCatalogTest >> testUnknownToolNameSuggestsCloseNames [

	| error result |
	result := self callToolNamed: 'tool_call' withArguments: { (#name -> 'method_serch') } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorCode) equals: 'ToolNotFound'.
	self assert: (error at: #tool) equals: 'method_serch'.
	self assert: ((error at: #suggestedTools) includes: 'method_source_search').
	self deny: (error includesKey: #stackTrace)
]
