"
Tests shared MCP tool contracts and catalog metadata.
"
Class {
	#name : 'MCPToolContractsTest',
	#superclass : 'MCPToolAPITestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPToolContractsTest >> addSelfSentNotImplementedCritiquesFrom: aMethod using: aRule to: issues [

	aRule check: aMethod forCritiquesDo: [ :critique |
			issues add: (String streamContents: [ :stream |
						 stream
							 nextPutAll: aMethod methodClass name asString;
							 nextPutAll: '>>';
							 nextPutAll: aMethod selector asString.
						 critique tinyHint ifNotNil: [ :hint |
								 stream
									 space;
									 nextPutAll: hint asString ] ]) ]
]

{ #category : 'private' }
MCPToolContractsTest >> addUnimplementedResponsibilitiesFor: aClass behavior: aBehavior side: sideName to: issues [

	aBehavior allSelectors do: [ :selector |
			| method |
			selector = #subclassResponsibility ifFalse: [
					method := aBehavior lookupSelector: selector.
					(method isNotNil and: [ self methodSendsSubclassResponsibility: method ]) ifTrue: [
							issues add: (String streamContents: [ :stream |
										 stream
											 nextPutAll: aClass name asString;
											 space;
											 nextPutAll: sideName;
											 nextPutAll: ' #';
											 nextPutAll: selector asString;
											 nextPutAll: ' inherited from ';
											 nextPutAll: method methodClass name asString ]) ] ] ]
]

{ #category : 'private' }
MCPToolContractsTest >> assertNamesAMissingClassAlike: aCase [
	"aCase is one row of missingClassCases. The whole answer is read for leaks, structured content included, since a client may show either."

	| answer call result text |
	result := self callToolNamed: aCase first withArguments: aCase second asDictionary.
	text := self firstTextFromToolResult: result.
	answer := STONJSON toString: result.
	call := [
		        '{1} {2}: {3}' format: {
				        aCase first.
				        aCase second printString.
				        answer } ].
	aCase third
		ifNil: [
				self deny: (self resultIndicatesError: result) description: call.
				self assert: ((self warningsFrom: result) anySatisfy: [ :each | each beginsWith: aCase fourth ]) description: call ]
		ifNotNil: [ :code |
				self assert: (self resultIndicatesError: result) description: call.
				self assert: ((self errorFrom: result) at: #errorCode) equals: code.
				self assert: (text beginsWith: aCase fourth) description: call ].
	self missingClassLeaks do: [ :each | self deny: (answer includesSubstring: each) description: call ]
]

{ #category : 'private' }
MCPToolContractsTest >> assertUsesSupportedSchemaDialect: aValue [

	| supportedKeywords |
	supportedKeywords := #( 'additionalProperties' 'default' 'description' 'enum' 'items' 'maximum' 'minItems' 'minLength'
	                        'minimum' 'properties' 'required' 'type' ).
	aValue isDictionary ifTrue: [
			aValue keysDo: [ :key | self assert: (supportedKeywords includes: key asString) ].
			aValue keysAndValuesDo: [ :key :nestedValue |
					key asString = 'properties'
						ifTrue: [ nestedValue valuesDo: [ :schema | self assertUsesSupportedSchemaDialect: schema ] ]
						ifFalse: [ self assertUsesSupportedSchemaDialect: nestedValue ] ].
			^ self ].
	(aValue isCollection and: [ aValue isString not ]) ifTrue: [
		aValue do: [ :nestedValue | self assertUsesSupportedSchemaDialect: nestedValue ] ]
]

{ #category : 'private' }
MCPToolContractsTest >> camelCaseWordsIn: aString [
	"The words in a description that are spelled like an argument name, so a caller would read them as one."

	^ (aString substrings: ' ,.;:()[]{}''"/<>#*-') select: [ :each |
			  (each allSatisfy: [ :character | character isLetter ]) and: [
				  each first isLowercase and: [ each anySatisfy: [ :character | character isUppercase ] ] ] ]
]

{ #category : 'private' }
MCPToolContractsTest >> classMutationToolClasses [

	^ {
		  MCPToolCreateClass.
		  MCPToolUpdateClass }
]

{ #category : 'private' }
MCPToolContractsTest >> collectSchemaNames: names descriptions: texts from: aDictionary [

	aDictionary at: #description ifPresent: [ :each | texts add: each ].
	aDictionary at: #properties ifPresent: [ :properties |
			properties keysAndValuesDo: [ :key :value |
					names add: key asString.
					self collectSchemaNames: names descriptions: texts from: value ] ].
	aDictionary
		at: #items
		ifPresent: [ :items | items isDictionary ifTrue: [ self collectSchemaNames: names descriptions: texts from: items ] ]
]

{ #category : 'private - evaluate' }
MCPToolContractsTest >> evaluate: aString within: seconds [
	"The answer of an evaluation with a time limit, as a call gets it: once it has answered, what it deferred runs, as the server runs it after the response. Through test_run a test runs inside a call of its own, which would otherwise hold what the evaluation deferred until the whole run has answered."

	| actions result |
	actions := OrderedCollection new.
	result := self evaluate: aString within: seconds deferringInto: actions.
	actions do: [ :each | each value ].
	^ result
]

{ #category : 'private - evaluate' }
MCPToolContractsTest >> evaluate: aString within: seconds deferringInto: actions [
	"The answer of an evaluation with a time limit, as a call gets it, leaving in actions what the call deferred until after its response."

	^ MCPPostResponseActions value: actions during: [
			  self callDiscoveredToolNamed: 'evaluate' withArguments: {
					  (#code -> aString).
					  (#timeoutSeconds -> seconds) } asDictionary ]
]

{ #category : 'private - evaluate' }
MCPToolContractsTest >> evaluateBriefly: aString [
	"The answer to an evaluation of aString with the tests' short limit, once what it deferred has run, as the server runs it after the response."

	| actions result |
	actions := OrderedCollection new.
	result := self evaluateBriefly: aString deferringInto: actions.
	actions do: [ :each | each value ].
	^ result
]

{ #category : 'private - evaluate' }
MCPToolContractsTest >> evaluateBriefly: aString deferringInto: actions [
	"The answer to an evaluation of aString with the tests' short limit, leaving in actions what the call deferred until after its response."

	| tool |
	tool := MCPToolEvaluate new.
	^ MCPPostResponseActions value: actions during: [
			  tool answerFor:
				  (MCPEvaluateCommand code: aString timeLimit: self stopLimitSeconds previewLimit: tool resultPreviewCharacterLimit) execute ]
]

{ #category : 'private' }
MCPToolContractsTest >> firstTextFromToolResult: aResult [

	^ (aResult at: #content) first at: #text
]

{ #category : 'private - evaluate' }
MCPToolContractsTest >> fullGarbageCollections [
	"How many full collections the VM has made since it started."

	^ Smalltalk vm parameterAt: 7
]

{ #category : 'private' }
MCPToolContractsTest >> handleJSON: aJSONString [

	^ self mcpWithoutObservabilityExport server messageProcessor handleJSON: aJSONString
]

{ #category : 'private' }
MCPToolContractsTest >> inputPropertyNamed: aPropertyName inTool: aTool [

	^ aTool inputSchema properties detect: [ :each | each name = aPropertyName ]
]

{ #category : 'private - evaluate' }
MCPToolContractsTest >> liveProcessesNamed: aString [

	^ Process allInstances select: [ :each | each name = aString and: [ each isTerminated not ] ]
]

{ #category : 'private' }
MCPToolContractsTest >> mcpClassesInPackageTagNamed: aTagName [
	"A tag says what kind of class this is, not which of MCP's packages it lives in, and since the split they live in two."

	^ ((MCPTool builtInPackageNames flatCollect: [ :each | (self packageOrganizer packageNamed: each asSymbol) definedClasses ])
		   select: [ :each | each packageTagName asString = aTagName ]) asArray
]

{ #category : 'private' }
MCPToolContractsTest >> methodSendsSubclassResponsibility: aCompiledMethod [

	(aCompiledMethod sendsSelector: #subclassResponsibility) ifFalse: [ ^ false ].
	aCompiledMethod ast nodesDo: [ :node | (node isMessage and: [ node selector = #subclassResponsibility ]) ifTrue: [ ^ true ] ].
	^ false
]

{ #category : 'private' }
MCPToolContractsTest >> missingClassCases [
	"Every argument that takes a class, each naming the missing class Zzqxw: the tool, its arguments, the code it answers, or nil for a scope that skips the entry with a warning, and how the text opens."

	| cases rename target |
	target := self missingClassTargetName.
	rename := {
		          (#selector -> 'probe').
		          (#newSelector -> 'probeRenamed') }.
	cases := OrderedCollection new.
	{
		('method_compile' -> { (#source -> 'probe ^ 1') }).
		('method_get' -> { (#selector -> 'probe') }).
		('method_update' -> rename).
		('method_remove' -> { (#selector -> 'probe') }).
		('method_equivalent_search' -> { (#selector -> 'probe') }) } do: [ :each |
			cases add: {
					each key.
					({ (#class -> 'Zzqxw') } , each value).
					'ClassNotFound'.
					'Class Zzqxw' } ].
	{
		('class_get' -> #(  )).
		('class_update' -> { (#comment -> 'Never set.') }).
		('class_remove' -> #(  )) } do: [ :each |
			cases add: {
					each key.
					({ (#name -> 'Zzqxw') } , each value).
					'ClassNotFound'.
					'Class Zzqxw' } ].
	{
		#( #superclass 'Zzqxw' 'SuperclassNotFound' 'Superclass Zzqxw' ).
		#( #traits #( 'Zzqxw' ) 'TraitNotFound' 'Trait Zzqxw' ).
		#( #sharedPools #( 'Zzqxw' ) 'SharedPoolNotFound' 'Shared pool Zzqxw' ).
		#( #layout 'Zzqxw' 'LayoutClassNotFound' 'Layout class Zzqxw' ) } do: [ :each |
			cases add: {
					'class_create'.
					{
						(#name -> self missingClassNewClassName).
						(#package -> self generatedPackageName).
						(each first -> each second) }.
					each third.
					each fourth }.
			cases add: {
					'class_update'.
					{
						(#name -> target).
						(each first -> each second) }.
					each third.
					each fourth } ].
	cases
		add: {
				'class_get'.
				{
					(#name -> target).
					(#upToSuperclass -> 'Zzqxw') }.
				'SuperclassNotFound'.
				'Superclass Zzqxw' };
		add: {
				'test_run'.
				{ (#classes -> #( 'Zzqxw' )) }.
				'ClassNotFound'.
				'Class Zzqxw' };
		add: {
				'test_run'.
				{ (#methods -> #( 'Zzqxw>>#testProbe' )) }.
				'ClassNotFound'.
				'Class Zzqxw' };
		add: {
				'critique_run'.
				{
					(#ruleClasses -> #( 'Zzqxw' )).
					(self searchScope: { (#classes -> { target }) }) }.
				'CritiqueRuleNotFound'.
				'Critique rule Zzqxw' };
		add: {
				'method_rewrite'.
				{
					(#ruleClasses -> #( 'Zzqxw' )).
					(self searchScope: { (#classes -> { target }) }) }.
				'RewriteRuleNotFound'.
				'Rewrite rule Zzqxw' };
		add: {
				'method_reference_search'.
				{
					(#name -> 'Zzqxw').
					(#kind -> 'class') }.
				'ClassNotFound'.
				'Class Zzqxw' };
		add: {
				'debug_watch'.
				{
					(#method -> 'Zzqxw>>probe').
					(#run -> '1') }.
				'ClassNotFound'.
				'Class Zzqxw' }.
	#( #classes #hierarchyOf ) do: [ :each |
			cases add: {
					'method_update'.
					({ (#class -> target) } , rename , { (self searchScope: { (each -> #( 'Zzqxw' )) }) }).
					'ClassNotFound'.
					'Class Zzqxw' } ].
	#( 'method_search' 'class_search' ) do: [ :tool |
			#( #classes #hierarchyOf #superclassesOf #subclassesOf ) do: [ :each |
					cases add: {
							tool.
							{ (self searchScope: { (each -> #( 'Zzqxw' )) }) }.
							nil.
							'Class Zzqxw' } ] ].
	^ cases asArray
]

{ #category : 'private' }
MCPToolContractsTest >> missingClassLeaks [
	"How a lookup made outside MCPImageLookup used to show through: Pharo's own lookup errors, and the internal labels scopes once had."

	^ #( 'SystemEnvironment' 'key #' 'KeyNotFound' 'hierarchyClasses' 'parentClasses' 'subclassClasses' 'class scope' 'classes scope' )
]

{ #category : 'private' }
MCPToolContractsTest >> missingClassNewClassName [

	^ 'MCPToolContractsNeverMadeClass'
]

{ #category : 'private' }
MCPToolContractsTest >> missingClassTargetName [
	"A class the missing-class cases change or read beside the missing one, made by the test so that a case that went through would change nothing else."

	^ 'MCPToolContractsMissingClassTarget'
]

{ #category : 'private - evaluate' }
MCPToolContractsTest >> notStartedTextHeldBy: processes [
	"The text of an evaluation that never started within 1 s, while these processes held the priority evaluations run at."

	| tool |
	tool := MCPToolEvaluate new.
	^ tool contentTextForStructuredContent: (Dictionary new
			   at: #summary put: (tool notStartedMessageFor: 1);
			   at: #error put: (tool notStartedDetailsFor: processes within: 1);
			   yourself)
]

{ #category : 'private - evaluate' }
MCPToolContractsTest >> processesNamed: aString [
	"Terminated or not, as long as something still holds them."

	^ Process allInstances select: [ :each | each name = aString ]
]

{ #category : 'private' }
MCPToolContractsTest >> scopePropertyNamed: aPropertyName inTool: aTool [

	^ ((self inputPropertyNamed: 'scope' inTool: aTool) extraProperties at: #properties) detect: [ :each |
		  each name = aPropertyName ]
]

{ #category : 'private' }
MCPToolContractsTest >> searchedToolNamesFor: aQuery [

	| data |
	data := self dataFrom: (self callToolNamed: 'tool_search' withArguments: { (#query -> aQuery) } asDictionary).
	^ (data at: #tools) collect: [ :each | each at: #name ]
]

{ #category : 'private' }
MCPToolContractsTest >> selfSentNotImplementedCritiquesForMCPMethods [

	| issues package rule |
	rule := ReSelfSentNotImplementedRule new.
	package := self packageOrganizer packageNamed: #MCP.
	issues := OrderedCollection new.
	package definedClasses do: [ :class |
			class localMethods do: [ :method | self addSelfSentNotImplementedCritiquesFrom: method using: rule to: issues ].
			class class localMethods do: [ :method | self addSelfSentNotImplementedCritiquesFrom: method using: rule to: issues ] ].
	^ issues asArray sort
]

{ #category : 'private' }
MCPToolContractsTest >> signalHaltForMCPMessageProcessorTest [

	(Smalltalk globals at: #Halt) signal: 'mcp processor halt test'
]

{ #category : 'private - evaluate' }
MCPToolContractsTest >> stopLimitSeconds [
	"The time limit of an evaluation a test lets stop: the command takes a fraction of a second, which the tool's schema does not, so these tests wait a fifth of what a whole second would cost."

	^ 0.2
]

{ #category : 'private - evaluate' }
MCPToolContractsTest >> stoppedEarlyResultOf: aString bounds: aBlock [
	"The answer to an evaluation of aString with a limit of 30 s, by a command whose bounds aBlock sets. What the call deferred runs once it has answered, as the server runs it after the response."

	| actions command result tool |
	tool := MCPToolEvaluate new.
	command := MCPEvaluateCommandStoppingEarly code: aString timeLimit: 30 previewLimit: tool resultPreviewCharacterLimit.
	aBlock value: command.
	actions := OrderedCollection new.
	result := MCPPostResponseActions value: actions during: [ tool answerFor: command execute ].
	actions do: #value.
	^ result
]

{ #category : 'private - evaluate' }
MCPToolContractsTest >> stoppedText: aString [
	"A text that must be the answer to a stop at the tests' limit."

	^ self stoppedText: aString after: self stopLimitSeconds
]

{ #category : 'private - evaluate' }
MCPToolContractsTest >> stoppedText: aString after: seconds [
	"A text that must be the answer to a stop at a limit of seconds."

	self assert: (aString lines first: 2) equals: {
			('Evaluation stopped after ' , seconds printString , ' s, its time limit.').
			'What it changed before then stays changed.' }.
	^ aString
]

{ #category : 'private - evaluate' }
MCPToolContractsTest >> stoppedTextOf: aResult [
	"The text of an evaluation's answer that must be a stop at the tests' limit."

	self assert: aResult isError.
	^ self stoppedText: aResult content first text
]

{ #category : 'private - evaluate' }
MCPToolContractsTest >> stoppedTextUnwindingBrieflyOf: aString deferringInto: actions [
	"The text of an evaluation of aString that must be stopped at the tests' limit, by a command that waits briefly rather than 5 s for the stopped code to unwind, leaving in actions what the call deferred until after its response. A test whose stopped code unwinds slowly waits that bound in full."

	| command tool |
	tool := MCPToolEvaluate new.
	command := MCPEvaluateCommandUnwindingBriefly
		           code: aString
		           timeLimit: self stopLimitSeconds
		           previewLimit: tool resultPreviewCharacterLimit.
	^ self stoppedTextOf: (MCPPostResponseActions value: actions during: [ tool answerFor: command execute ])
]

{ #category : 'tests' }
MCPToolContractsTest >> testAOneWordToolShowsItsActionIconAlone [
	"evaluate names no domain, so it shows #go, its action's icon, and no badge."

	self assert: (MCPToolIconSpec forToolName: 'evaluate') cacheKey equals: (MCPToolIconSpec named: #go) cacheKey.
	self assert: MCPToolEvaluate toolIconSpec cacheKey equals: (MCPToolIconSpec named: #go) cacheKey
]

{ #category : 'tests' }
MCPToolContractsTest >> testAToolDecidesForItselfWhetherDiscoveryServesIt [
	"Loading the package is the opt-in, so the only knob left is the tool's own answer. A fixture that answers false stays out, a subclass inherits that answer, and overriding it back serves the subclass under the name it inherits."

	| className registry toolClass |
	self deny: (MCPToolRegistry default includesToolNamed: MCPExternalTestTool toolName).
	className := 'MCPAutoRegisterExternalToolFixture'.
	self
		createClassNamed: className
		superclassName: MCPExternalTestTool name
		slots: #(  )
		classSlots: #(  ).
	[
		toolClass := self classNamed: className.
		self deny: toolClass shouldAutoRegister.
		self
			ensureMethodSource: 'shouldAutoRegister

	^ true'
			protocol: 'testing'
			on: toolClass classSide.
		registry := MCPToolRegistry default.
		self assert: toolClass shouldAutoRegister.
		self assert: (registry includesToolNamed: MCPExternalTestTool toolName).
		self deny: (registry isToolAdvertisedNamed: MCPExternalTestTool toolName) ] ensure: [ self removeClassNamed: className ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testAdvertisingAToolClassRegistersItFirst [
	"A class says its own tool name, so naming one that is not in the catalog yet registers it instead of failing on order."

	| server |
	server := self mcpWithoutObservabilityExport.
	self deny: (server toolNames includes: MCPExternalTestTool toolName).
	server advertiseTools: { MCPExternalTestTool }.
	self assert: (server toolNames includes: MCPExternalTestTool toolName).
	self assert: server advertisedToolNames equals: { MCPExternalTestTool toolName }
]

{ #category : 'tests' }
MCPToolContractsTest >> testAdvertisingAcceptsSymbolsAsWellAsStrings [
	"A Symbol never equals the String a tool answers for its name, so the advertised set has to hold Strings."

	| server |
	server := self mcpWithoutObservabilityExport.
	server advertiseTools: #( #tool_search #tool_get ).
	self assert: server advertisedToolNames asSet equals: #( 'tool_search' 'tool_get' ) asSet
]

{ #category : 'tests' }
MCPToolContractsTest >> testAdvertisingAllToolsAdvertisesEveryRegisteredTool [

	| registry |
	registry := MCPToolRegistry default.
	registry advertiseAllTools.
	self assert: registry advertisedToolNames asSet equals: registry toolNames asSet
]

{ #category : 'tests' }
MCPToolContractsTest >> testAdvertisingOverridesToolDefault [

	| registry tool |
	registry := MCPToolRegistry default.
	tool := registry toolNamed: 'method_update' ifAbsent: [ self fail ].
	registry advertiseTools: (registry advertisedToolNames copyWith: tool name).
	self assert: tool defaultExposure equals: 'discoverable'.
	self assert: (registry isToolAdvertisedNamed: tool name)
]

{ #category : 'tests' }
MCPToolContractsTest >> testAdvertisingRejectsUnknownToolNames [

	self should: [ self mcpWithoutObservabilityExport advertiseTools: #( 'tool_search' 'not-a-tool' ) ] raise: Error
]

{ #category : 'tests' }
MCPToolContractsTest >> testAllToolSchemasUseSupportedDialect [

	self builtInToolClasses do: [ :toolClass | self assertUsesSupportedSchemaDialect: toolClass new inputSchema asJRPCJSON ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testAllToolsHavePngIconsWithDataUris [

	self builtInToolClasses do: [ :toolClass |
			| icon icons |
			icons := toolClass new icons.
			self deny: icons isEmpty.
			icon := icons first.
			self assert: icon mimeType equals: 'image/png'.
			self assert: (icon src beginsWith: 'data:image/png;base64,').
			self assert: icon sizes size equals: 1.
			self assert: (icon sizes first includesSubstring: 'x') ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testArgumentValueClassesUseSpecOrDeltaSuffixes [
	"A tool reads its arguments from MCPToolRequest, the one request class. What a tool builds from them to resolve or apply is a spec or a delta, kept under Specs."

	| invalidNames specClasses suffixes |
	specClasses := self mcpClassesInPackageTagNamed: 'Specs'.
	suffixes := #( 'Spec' 'Delta' ).
	invalidNames := specClasses reject: [ :each | suffixes anySatisfy: [ :suffix | each name asString endsWith: suffix ] ].
	self assert: (self mcpClassesInPackageTagNamed: 'Requests') asArray equals: { MCPToolRequest }.
	self assert: specClasses isNotEmpty.
	self assert: invalidNames isEmpty
]

{ #category : 'tests' }
MCPToolContractsTest >> testBrowseIconToolGroupsKeepRelatedToolsTogether [

	| autoRegisteredToolClasses groupedToolClasses |
	groupedToolClasses := OrderedCollection new.
	MCPTool toolGroups do: [ :group |
			group value do: [ :toolClass | self assert: toolClass new groupName equals: group key ].
			groupedToolClasses addAll: group value ].
	autoRegisteredToolClasses := MCPTool concreteSubclasses select: [ :toolClass | toolClass shouldAutoRegister ].
	self assert: groupedToolClasses asSet equals: autoRegisteredToolClasses asSet
]

{ #category : 'tests' }
MCPToolContractsTest >> testBuiltInToolsProvideCatalogMetadata [

	| validExposures |
	validExposures := #( 'static' 'discoverable' ).
	self toolRegistry tools select: [ :tool | tool class isBuiltIn ] thenDo: [ :tool |
			self assert: (MCPTool builtInGroupNames includes: tool groupName).
			self assert: tool groupName equals: tool class groupName.
			self assert: (validExposures includes: tool defaultExposure).
			self assert: (#( true nil ) includes: tool annotations readOnlyHint).
			self assert: tool keywords isNotEmpty ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testCallToolInvokesDiscoverableToolAfterStaticConfiguration [

	| data result server |
	server := self mcpWithoutObservabilityExport.
	server advertiseTools: #( 'tool_search' 'tool_get' 'tool_call' ).
	result := server rpcToolCall: 'tool_call' withParams: {
			          (#name -> 'package_search').
			          (#arguments -> {
				           (#name -> 'MCP') } asDictionary) } asDictionary.
	data := self dataFrom: result.
	self assert: (data at: #packages) isNotEmpty.
	self assert: ((data at: #packages) allSatisfy: [ :each | (each at: #package) includesSubstring: 'MCP' ])
]

{ #category : 'tests' }
MCPToolContractsTest >> testCallToolInvokesTargetToolThroughServerPath [

	| data result |
	result := self callToolNamed: 'tool_call' withArguments: {
			          (#name -> 'package_search').
			          (#arguments -> {
				           (#name -> 'MCP') } asDictionary) } asDictionary.
	data := self dataFrom: result.
	self assert: (data at: #packages) isNotEmpty.
	self assert: ((data at: #packages) allSatisfy: [ :each | (each at: #package) includesSubstring: 'MCP' ])
]

{ #category : 'tests - validation' }
MCPToolContractsTest >> testCallToolPreservesNestedValidationViolations [

	| error result violations |
	result := self callToolNamed: 'tool_call' withArguments: {
			          (#name -> 'method_reference_search').
			          (#arguments -> { (#name -> '') } asDictionary) } asDictionary.
	error := self errorFrom: result.
	violations := error at: #violations.
	self assert: (error at: #tool) equals: 'method_reference_search'.
	self assert: violations size equals: 1.
	self assert: (violations first at: #keyword) equals: #required.
	self assert: (violations first at: #expected) equals: 'name'
]

{ #category : 'tests' }
MCPToolContractsTest >> testCaptureScreenHasAccurateNameAndSchemas [

	| inputPropertyNames tool |
	tool := MCPToolCaptureScreen new.
	inputPropertyNames := tool inputSchema properties collect: [ :each | each name ].
	self assert: tool name equals: 'screen_capture'.
	self assert: tool inputSchema required equals: #(  ).
	self assert: inputPropertyNames equals: #( 'window' )
]

{ #category : 'tests' }
MCPToolContractsTest >> testCaptureScreenPackagesTheFormAsImageContent [

	| data imageContent imageJSON result |
	result := MCPToolCaptureScreen new
		          resultForCaptureOf: (Morph new
				           extent: 2 @ 3;
				           yourself)
		          window: nil.
	data := result structuredContent at: #data.
	imageContent := result content second.
	imageJSON := imageContent asJRPCJSON.
	self assert: (data at: #target) equals: 'world'.
	self assert: (data at: #width) equals: 2.
	self assert: (data at: #height) equals: 3.
	self assert: imageContent mimeType equals: 'image/png'.
	self assert: imageContent data isNotEmpty.
	self assert: (imageJSON at: #type) equals: 'image'.
	self assert: (imageJSON at: #mimeType) equals: 'image/png'
]

{ #category : 'tests' }
MCPToolContractsTest >> testCatalogToolsUseOwningRegistry [

	| registry |
	registry := MCPToolRegistry default.
	#( 'tool_search' 'tool_get' ) do: [ :toolName |
			| tool |
			tool := registry toolNamed: toolName ifAbsent: [ self fail ].
			self assert: tool toolRegistry == registry ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testClassMutationToolsHaveAccurateNamesAndRequiredArguments [

	| createTool slotsSchema updatePropertyNames updateTool |
	createTool := MCPToolCreateClass new.
	updateTool := MCPToolUpdateClass new.
	self assert: createTool name equals: 'class_create'.
	self assert: updateTool name equals: 'class_update'.
	"The superclass is optional and defaults to Object."
	self assert: createTool inputSchema required asSet equals: #( 'name' 'package' ) asSet.
	self assert: updateTool inputSchema required asSet equals: #( 'name' ) asSet.
	updatePropertyNames := updateTool inputSchema properties collect: [ :each | each name ].
	#( 'newName' 'superclass' 'package' 'tag' 'comment' 'slots' 'classSlots' 'traits' 'sharedVariables' 'sharedPools' 'layout'
	   'force' ) do: [ :each | self assert: (updatePropertyNames includes: each) ].
	#( 'operation' 'slotAction' 'slot' 'newSlot' 'side' ) do: [ :each | self deny: (updatePropertyNames includes: each) ].
	"Slots are patched, so their argument is a delta rather than a list."
	slotsSchema := (updateTool inputSchema asJRPCJSON at: #properties) at: 'slots'.
	self assert: (slotsSchema at: #type) equals: 'object'.
	self assert: (slotsSchema at: #properties) keys asSet equals: #( 'add' 'remove' 'rename' 'pullUp' 'pushDown' 'replace' ) asSet
]

{ #category : 'tests' }
MCPToolContractsTest >> testClassToolSchemaDescriptionsExplainRecategorizationAndReplacementSemantics [

	| tool layoutDescription packageDescription sharedPoolsDescription sharedVariablesDescription slotsSchema tagDescription traitsDescription |
	tool := MCPToolUpdateClass new.
	packageDescription := (self inputPropertyNamed: 'package' inTool: tool) description.
	tagDescription := (self inputPropertyNamed: 'tag' inTool: tool) description.
	traitsDescription := (self inputPropertyNamed: 'traits' inTool: tool) description.
	sharedVariablesDescription := (self inputPropertyNamed: 'sharedVariables' inTool: tool) description.
	sharedPoolsDescription := (self inputPropertyNamed: 'sharedPools' inTool: tool) description.
	layoutDescription := (self inputPropertyNamed: 'layout' inTool: tool) description.
	"Moving and retagging are different changes, and package says how to ask for the second one."
	self assert: (packageDescription includesSubstring: 'tag alone').
	self assert: (tagDescription includesSubstring: 'package').
	"The stateless collections are replaced by value, and say so."
	self assert: (traitsDescription includesSubstring: 'empty array').
	"A trait is used by the whole class, so traits says it covers the class side too."
	self assert: (traitsDescription includesSubstring: 'class side').
	self assert: (sharedVariablesDescription includesSubstring: 'empty array').
	self assert: (sharedPoolsDescription includesSubstring: 'empty array').
	self assert: (sharedPoolsDescription includesSubstring: 'Shared pools').
	self assert: (layoutDescription includesSubstring: 'AbstractLayout').
	"Slots are patched, and each part of the patch says what it does."
	slotsSchema := (tool inputSchema asJRPCJSON at: #properties) at: 'slots'.
	self
		assert: (((slotsSchema at: #properties) at: 'rename') at: #description)
		equals: 'Slots to rename, as current name to new name. Values are migrated and references updated.'.
	self assert: ((((slotsSchema at: #properties) at: 'replace') at: #description) includesSubstring: 'Prefer add and remove')
]

{ #category : 'tests' }
MCPToolContractsTest >> testClassToolTraitOwnsSharedClassHelpers [

	| classToolClasses sharedSelectors |
	classToolClasses := {
		                    MCPToolSearchClasses.
		                    MCPToolGetClass } , self classMutationToolClasses , { MCPToolRemoveClasses }.
	sharedSelectors := #( resolvedClassNamed: sortedClassesByName: ).
	classToolClasses do: [ :toolClass |
			self assert: (toolClass withAllSuperclasses anySatisfy: [ :each | each traits includes: TMCPClassTool ]).
			sharedSelectors do: [ :selector | self assert: (toolClass lookupSelector: selector) origin equals: TMCPClassTool ] ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testCompileMethodAnswersItsSummaryAsText [

	| text |
	text := self firstTextFromToolResult: (self callToolNamed: 'method_compile' withArguments: {
				          (#class -> MCPToolContractsTest name).
				          (#protocol -> 'tests - fixtures').
				          (#source -> 'mcpPlainTextContentFixture

	^ 42') } asDictionary).
	self assert: text equals: 'Created MCPToolContractsTest>>mcpPlainTextContentFixture.'.
	MCPToolContractsTest removeSelector: #mcpPlainTextContentFixture
]

{ #category : 'tests' }
MCPToolContractsTest >> testConcreteMCPClassesHaveNoUnimplementedResponsibilities [

	| issues |
	issues := self unimplementedResponsibilitiesForConcreteMCPClasses.
	self
		assert: issues isEmpty
		description: (String streamContents: [ :stream | issues do: [ :each | stream nextPutAll: each ] separatedBy: [ stream cr ] ])
]

{ #category : 'tests' }
MCPToolContractsTest >> testConfiguredDiscoverableToolsAreDirectlyCallable [

	| server result |
	server := self mcpWithoutObservabilityExport.
	server advertiseTools: #( 'tool_search' 'tool_get' 'tool_call' ).
	self deny: (server toolsList includesKey: 'package_search').
	result := server rpcToolCall: 'package_search' withParams: { (#name -> 'MCP') } asDictionary.
	self assert: ((self dataFrom: result) at: #packages) isNotEmpty.
	self should: [ server rpcToolCall: 'no_such_tool' withParams: Dictionary new ] raise: JRPCNonExistentHandler
]

{ #category : 'tests' }
MCPToolContractsTest >> testDebuggerToolsAreDiscoverableOnly [

	| debugNames advertisedToolNames |
	debugNames := #( 'debug_search' 'debug_watch' ).
	advertisedToolNames := self toolRegistry advertisedToolNames.
	debugNames do: [ :each |
			self deny: (advertisedToolNames includes: each).
			self assert: (self toolRegistry toolNames includes: each) ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testDefaultProfileUsesDefaultToolRegistry [

	| server |
	server := MCP new.
	self assert: (server toolRegistry includesToolNamed: MCPToolSearchTools toolName).
	self assert: (server advertisedToolNames includes: MCPToolSearchClasses toolName)
]

{ #category : 'tests' }
MCPToolContractsTest >> testDefaultToolRegistryRegistersBuiltInTools [

	| registry |
	registry := MCPToolRegistry default.
	self assert: (registry includesToolNamed: MCPToolSearchTools toolName).
	self assert: (registry advertisedToolNames includes: MCPToolSearchClasses toolName)
]

{ #category : 'tests' }
MCPToolContractsTest >> testDescriberAndResultClassesUseInfoOrResultSuffixes [

	| describerClasses invalidNames suffixes |
	describerClasses := (self mcpClassesInPackageTagNamed: 'DTOs') , (self mcpClassesInPackageTagNamed: 'Results').
	describerClasses := describerClasses reject: [ :each | each isAbstract ].
	suffixes := #( 'Result' 'Info' ).
	invalidNames := describerClasses reject: [ :each | suffixes anySatisfy: [ :suffix | each name asString endsWith: suffix ] ].
	self assert: describerClasses isNotEmpty.
	self assert: invalidNames isEmpty
]

{ #category : 'tests' }
MCPToolContractsTest >> testDiscoveryInstructionsNameOnlyAdvertisedTools [
	"A host may let a model call only the tools its list holds, so a tool the instructions name must be one tools/list shows, or they send the model where it cannot go."

	| server named |
	server := self mcpWithoutObservabilityExport.
	named := (server discoveryInstructions substrings: ' ,.;:()') select: [ :each | each includes: $_ ].
	self deny: named isEmpty.
	self assertEmpty: (named reject: [ :each | server advertisedToolNames includes: each ])
]

{ #category : 'tests' }
MCPToolContractsTest >> testDiscoveryUsesConfiguredAdvertisedTools [

	| createContract metadataByName result searchContract server |
	server := self mcpWithoutObservabilityExport.
	server advertiseTools: #( 'tool_search' 'tool_get' 'tool_call' 'repository_search' ).
	result := server rpcToolCall: 'tool_search' withParams: { (#query -> 'repository') } asDictionary.
	metadataByName := (((self dataFrom: result) at: #tools) collect: [ :each | (each at: #name) -> each ]) asDictionary.
	self assert: (metadataByName includesKey: 'repository_search').
	self assert: (metadataByName includesKey: 'repository_create').
	searchContract := (self dataFrom: (server rpcToolCall: 'tool_get' withParams: { (#name -> 'repository_search') } asDictionary))
		                  at: #tool.
	createContract := (self dataFrom: (server rpcToolCall: 'tool_get' withParams: { (#name -> 'repository_create') } asDictionary))
		                  at: #tool.
	"pageSize is there for the one that answers pages and absent from the one that does not."
	self
		assert: searchContract keys asSet
		equals: #( name description group exposure annotations keywords inputSchema pageSize ) asSet.
	self assert: createContract keys asSet equals: #( name description group exposure annotations keywords inputSchema ) asSet.
	self assert: (searchContract at: #exposure) equals: 'static'.
	self assert: ((searchContract at: #annotations) at: #readOnlyHint).
	self assert: (createContract at: #exposure) equals: 'discoverable'.
	self deny: ((createContract at: #annotations) includesKey: #readOnlyHint)
]

{ #category : 'tests' }
MCPToolContractsTest >> testEmptyListOfTargetsIsRejectedAsInput [
	"A list whose values are all blank names nothing either, though it has items."

	self
		assertResult: (self callToolNamed: 'method_get' withArguments: {
					 (#class -> 'MCPTool').
					 (#selector -> #(  )) } asDictionary)
		refusesArgumentsSaying: 'selector names nothing to act on; give at least one value that is not blank.'.
	self
		assertResult: (self callToolNamed: 'method_get' withArguments: {
					 (#class -> 'MCPTool').
					 (#selector -> #( '' '  ' )) } asDictionary)
		refusesArgumentsSaying: 'selector names nothing to act on'
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateAnswersBeforeASlowUnwindEnds [
	"An ensure block may take as long as it likes. The answer waits for it only so long, says it was still running, and puts the Transcript back itself."

	| actions milliseconds text transcript |
	self timeLimit: 30 seconds.
	MCPEvaluateTestProbe reset.
	transcript := Smalltalk globals at: #Transcript.
	actions := OrderedCollection new.
	[
		milliseconds := Time millisecondsToRun: [
				                text := self
					                        stoppedTextUnwindingBrieflyOf:
					                        '[ [ true ] whileTrue ] ensure: [ MCPEvaluateTestProbe holdUntilReleased ]'
					                        deferringInto: actions ].
		self assert: (Smalltalk globals at: #Transcript) identicalTo: transcript ] ensure: [
			actions do: #value.
			MCPEvaluateTestProbe release.
			MCPEvaluateTestProbe holder ifNotNil: [ :holder | self waitUntilEnded: holder ] ].
	self assert: (text lines at: 3) equals: 'Its ensure blocks were still running when this answer was sent.'.
	self assert: milliseconds < 15000
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateAnswersThePrintStringAsItsWholeText [
	"The envelope around a one-line answer cost more than the answer."

	self
		assert: (self firstTextFromToolResult:
				 (self callDiscoveredToolNamed: 'evaluate' withArguments: { (#code -> '3 + 4') } asDictionary))
		equals: '7'
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateAnswersWhenAFailingCodesEnsureBlockEndsItsProcess [
	"A failure is answered once the code's process has unwound, so an ensure block that ends that process leaves no value and no failure to answer."

	| result |
	result := self
		          callDiscoveredToolNamed: 'evaluate'
		          withArguments: { (#code -> '[ 1/0 ] ensure: [ Processor activeProcess terminate ]') } asDictionary.
	self assert: (self resultIndicatesError: result).
	self
		assert: (self firstTextFromToolResult: result)
		equals: 'Evaluation ended the process running it, so it has no value to answer.'
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateAnswersWhenTheCodeEndsItsOwnProcess [
	"The process that ends is the one the code runs in, not the one that answers."

	| result |
	result := self
		          callDiscoveredToolNamed: 'evaluate'
		          withArguments: { (#code -> 'Processor activeProcess terminate') } asDictionary.
	self assert: (self resultIndicatesError: result).
	self
		assert: (self firstTextFromToolResult: result)
		equals: 'Evaluation ended the process running it, so it has no value to answer.'
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateAnswersWhileAForkHoldsItsPriority [
	"A fork computing at the evaluator's priority may keep the process that terminates the evaluator from ever running, so the answer waits for the termination only so long. The test then waits for its own stopping process, which ends only once the evaluator has."

	self timeLimit: 30 seconds.
	self underEitherPreemptionRuleDo: [ :yields |
			| actions before milliseconds |
			before := self liveProcessesNamed: 'evaluate stop'.
			actions := OrderedCollection new.
			[
				milliseconds := Time millisecondsToRun: [
						                self
							                stoppedTextUnwindingBrieflyOf:
							                '[ [ true ] whileTrue ] forkAt: Processor activePriority named: ''mcp-evaluate-hog-probe''. [ true ] whileTrue'
							                deferringInto: actions ] ] ensure: [
					actions do: #value.
					(self liveProcessesNamed: 'mcp-evaluate-hog-probe') do: [ :each | each terminate ] ].
			((self liveProcessesNamed: 'evaluate stop') copyWithoutAll: before) do: [ :each | self waitUntilEnded: each ].
			self assert: milliseconds < 15000 ]
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateCatchesHaltAsRuntimeFailure [

	| result text |
	result := self
		          callDiscoveredToolNamed: 'evaluate'
		          withArguments: { (#code -> 'Halt signal: ''mcp halt test''') } asDictionary.
	text := self firstTextFromToolResult: result.
	self assert: (result at: #isError).
	self assert: (text includesSubstring: 'failed during execution').
	self assert: (text includesSubstring: 'Halt').
	self assert: (text includesSubstring: 'mcp halt test')
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateFailureTextNamesSuggestionsAndFrames [

	| lines text |
	text := self firstTextFromToolResult: (self
			         callDiscoveredToolNamed: 'evaluate'
			         withArguments: { (#code -> 'OrderedCollection new adAll: #( 1 2 3 )') } asDictionary).
	lines := text lines.
	self assert: (lines anySatisfy: [ :each | each beginsWith: 'Did you mean: addAll:' ]).
	self assert: (lines reject: [ :each | each beginsWith: '   ' ]) last equals: 'UndefinedObject>>DoIt'.
	self deny: (text includesSubstring: '"errorClass"')
]

{ #category : 'tests' }
MCPToolContractsTest >> testEvaluateIsMarkedAsAdvancedEscapeHatch [

	| description |
	self assert: (MCPToolEvaluate new asJRPCJSON at: #name) equals: 'evaluate'.
	description := MCPToolEvaluate new description.
	self assert: (description includesSubstring: 'escape hatch').
	self assert: (description includesSubstring: 'arbitrary Smalltalk code')
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateLeavesTheProcessesItForkedRunning [
	"Forking is how longer work runs, so a stop leaves alone what the code forked."

	self timeLimit: 30 seconds.
	[
		self stoppedTextOf: (self evaluateBriefly:
				 '[ (Delay forSeconds: 30) wait ] forkAt: Processor userBackgroundPriority named: ''mcp-evaluate-fork-probe''. [ true ] whileTrue').
		self denyEmpty: (self liveProcessesNamed: 'mcp-evaluate-fork-probe') ] ensure: [
		(self liveProcessesNamed: 'mcp-evaluate-fork-probe') do: [ :each | each terminate ] ]
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateLetsASaveFinish [
	"Stopped between the snapshot and the restart of the listener that follows it, a save would leave the image without its listener. Neither process is resumed, so nothing is saved."

	| command other saving |
	command := MCPEvaluateCommand code: 'Smalltalk saveSession' timeLimit: 1 previewLimit: 100.
	saving := Process
		          forContext: (Context
				           sender: nil
				           receiver: SessionManager default
				           method: SessionManager >> #snapshot:andQuit:
				           arguments: #( true false ))
		          priority: Processor userBackgroundPriority.
	other := Process
		         forContext: (Context
				          sender: nil
				          receiver: SessionManager default
				          method: SessionManager >> #currentSession
				          arguments: #(  ))
		         priority: Processor userBackgroundPriority.
	self assert: (command isSaving: saving).
	self deny: (command isSaving: other)
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateLetsNotificationsUseTheirDefaultAction [

	| data result |
	result := self
		          callDiscoveredToolNamed: 'evaluate'
		          withArguments: { (#code -> 'MCPToolDefaultActionNotification signal') } asDictionary.
	data := self dataFrom: result.
	self deny: (result includesKey: #isError).
	self assert: (data at: #resultClassName) equals: 'ByteSymbol'.
	self assert: (data at: #resultPrintString) equals: '#mcpDefaultAction'
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateLooksAtTheMemoryOnlyOnceTheCodeHasStarted [
	"Before the code has started, whatever grows the image is not the code, so only the time limit stops it. A bound below any growth stands for one the image passed. Code that has ended is never stopped."

	| command tool unstarted |
	tool := MCPToolEvaluate new.
	command := MCPEvaluateCommandStoppingEarly code: '3 + 4' timeLimit: self stopLimitSeconds previewLimit: 100.
	command memoryGrowthLimit: -1024 * 1024 * 1024.
	unstarted := [ 3 + 4 ] newProcess.
	self
		assert: (tool stopSummaryFor: (command watch: unstarted until: Semaphore new started: [ false ]) of: command)
		equals: 'Evaluation stopped after ' , self stopLimitSeconds printString , ' s, its time limit.'.
	self assert: ((tool stopSummaryFor: (command watch: unstarted until: Semaphore new started: [ true ]) of: command) beginsWith:
			 'Evaluation stopped: the image''s memory grew by more than ').
	self assert: (command
			 watch: unstarted
			 until: (Semaphore new
					  signal;
					  yourself)
			 started: [ true ]) isNil
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateNamesAFrameOnOneLineByItsClassAndMethod [
	"Every Pharo names a frame so; before 14, Pharo printed a block's frame with the block's source, over as many lines as it has."

	| tool |
	tool := MCPToolEvaluate new.
	self assert: (tool frameNameFor: thisContext) equals: 'MCPToolContractsTest>>testEvaluateNamesAFrameOnOneLineByItsClassAndMethod'.
	self
		assert: [ tool frameNameFor: thisContext ] value
		equals: '[ ] in MCPToolContractsTest>>testEvaluateNamesAFrameOnOneLineByItsClassAndMethod'.
	self
		assert: (tool frameNameFor: (Context
					  sender: nil
					  receiver: 3
					  method: Object >> #printString
					  arguments: #(  )))
		equals: 'SmallInteger(Object)>>printString'
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateNotStartedTextTellsAnEvaluationFromAFork [
	"A process named after the tool is an earlier evaluation, which ends at its own limit; any other at the priority evaluations run at was forked by one, and has no limit."

	| evaluation fork lines summary |
	evaluation := [ 1 ] newProcess
		              name: 'evaluate';
		              yourself.
	fork := [ 2 ] newProcess
		        name: 'mcp-fork-probe';
		        yourself.
	summary := 'Evaluation did not start within 1 s, its time limit; none of it ran.'.
	lines := (self notStartedTextHeldBy: {
			          evaluation.
			          fork }) lines.
	self assert: (lines first: 2) equals: {
			summary.
			'Holding the priority evaluations run at:' }.
	self assert: ((lines at: 3) beginsWith: 'an earlier evaluation, in ').
	self assert: ((lines at: 4) beginsWith: 'a process an evaluation forked, named mcp-fork-probe, in ').
	self assert: (lines allButFirst: 4) equals: #( 'An earlier evaluation stops at its own time limit; call again after it.'
		   'A fork has no time limit; while it computes, evaluations may not start.'
		   'If it never ends, only an image restart ends it, losing what was not saved.'
		   'Fork long work at Processor userBackgroundPriority, below evaluations.' ).
	lines := (self notStartedTextHeldBy: { evaluation }) lines.
	self assert: lines size equals: 4.
	self assert: (lines at: 3) equals: 'an earlier evaluation, in ' , (MCPToolEvaluate new frameNameFor: evaluation suspendedContext).
	self assert: lines last equals: 'An earlier evaluation stops at its own time limit; call again after it.'.
	self assert: (self notStartedTextHeldBy: #(  )) lines equals: {
			summary.
			'No other process holds the priority evaluations run at,'.
			'so code at a higher priority, such as another call, kept the processor.' }
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateOmitsTruncationFieldsForSmallResults [

	| data |
	data := self dataFrom:
		        (self callDiscoveredToolNamed: 'evaluate' withArguments: { (#code -> '#( 1 2 3 )') } asDictionary).
	self deny: (data includesKey: #truncated).
	self deny: (data includesKey: #resultSize)
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateQueuesPostResponseActionsOfTheCall [
	"The code runs in a process of its own, and what it defers must still wait for the response of the call that ran it."

	| actions result |
	actions := OrderedCollection new.
	result := MCPPostResponseActions value: actions during: [
			          self
				          callDiscoveredToolNamed: 'evaluate'
				          withArguments: { (#code -> 'MCPPostResponseActions value add: [ 1 ]. #queued') } asDictionary ].
	self assert: (self firstTextFromToolResult: result) equals: '#queued'.
	self assert: actions size equals: 1
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateReportsTheFailingSourceLine [
	"A character offset makes a caller count through its own source to find the mistake."

	| error result |
	result := self callDiscoveredToolNamed: 'evaluate' withArguments: { (#code -> '| s |
s := WriteStream on: String new.
s << cr.
s contents') } asDictionary.
	self compilerReadsUndeclaredNamesAsNil ifTrue: [ ^ self assert: (result at: #isError) ].
	error := self errorFrom: result.
	self assert: (error at: #line) equals: 3.
	self assert: (error at: #sourceLine) equals: 's << cr.'
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateReportsTruncationAndCollectionSize [
	"A cut preview used to end in a marker and nothing else, so the caller could not tell whether two or two hundred kilobytes were missing."

	| data |
	data := self dataFrom:
		        (self
			         callDiscoveredToolNamed: 'evaluate'
			         withArguments: { (#code -> '(1 to: 40000) asOrderedCollection') } asDictionary).
	self assert: (data at: #truncated).
	self assert: (data at: #resultSize) equals: 40000.
	self
		assert: (data at: #resultPrintString) size
		equals: ((1 to: 40000) asOrderedCollection printStringLimitedTo: MCPToolEvaluate new resultPreviewCharacterLimit) size
]

{ #category : 'tests' }
MCPToolContractsTest >> testEvaluateRequiresCodeInSchema [

	self assert: (MCPToolEvaluate new inputSchema required includes: 'code')
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateResumesNotificationsSignaledByADefaultAction [
	"A default action may signal a notification of its own, and a handler is suspended while its block runs: Deprecation>>defaultAction logs, logging signals DeprecationPerformedNotification, and that second notification used to escape and fail the call."

	| data result |
	result := self
		          callDiscoveredToolNamed: 'evaluate'
		          withArguments: { (#code -> 'MCPToolNestedNotification signal') } asDictionary.
	data := self dataFrom: result.
	self deny: (result includesKey: #isError).
	self assert: (data at: #resultPrintString) equals: '''nested-mcpDefaultAction'''
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateReturnsCompilationFailureInformation [

	| result text |
	result := self callDiscoveredToolNamed: 'evaluate' withArguments: { (#code -> '1 +') } asDictionary.
	text := self firstTextFromToolResult: result.
	self assert: (result at: #isError).
	self assert: (text includesSubstring: 'failed during compilation').
	self assert: (text includesSubstring: self expectedSyntaxErrorNoticeClassName).
	self assert: (text includesSubstring: 'Line 1')
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateReturnsRuntimeFailureInformation [

	| result text |
	result := self callDiscoveredToolNamed: 'evaluate' withArguments: { (#code -> 'Error signal: ''boom''') } asDictionary.
	text := self firstTextFromToolResult: result.
	self assert: (result at: #isError).
	self assert: (text includesSubstring: 'failed during execution').
	self assert: (text includesSubstring: 'boom').
	self assert: ((text lines reject: [ :each | each beginsWith: '   ' ]) last includesSubstring: 'UndefinedObject>>DoIt')
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateRunsJustBelowTheCallingProcess [
	"Only a process above the code can take the processor back from code that computes, so the code runs one priority below the call."

	self
		assert: (self firstTextFromToolResult:
				 (self callDiscoveredToolNamed: 'evaluate' withArguments: { (#code -> 'Processor activePriority') } asDictionary))
		equals: (Processor activePriority - 1) printString
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateStackAndMemoryStopsSayWhy [
	"Each early stop names what the code passed and how far, and the stack's names what runs that deep."

	| command tool |
	tool := MCPToolEvaluate new.
	command := MCPEvaluateCommand code: '3 + 4' timeLimit: 30 previewLimit: 100.
	self
		assert: (tool stackStoppedMessageFor: command stackDepthLimit)
		equals: 'Evaluation stopped: its stack passed 1000000 frames, which an endless recursion does.'.
	self
		assert: (tool memoryStoppedMessageFor: command memoryGrowthLimit)
		equals: 'Evaluation stopped: the image''s memory grew by more than 4 GB while it ran.'.
	self
		assert: (tool memoryStoppedMessageFor: 16 * 1024 * 1024)
		equals: 'Evaluation stopped: the image''s memory grew by more than 16 MB while it ran.'
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateStackTraceStopsAtTheEvaluatedCode [
	"Below the outermost doIt every frame is compiler and dispatch scaffolding, identical on every failure."

	| error stackTrace |
	error := self errorFrom:
		         (self callDiscoveredToolNamed: 'evaluate' withArguments: { (#code -> '#( 1 2 3 ) do: [ :each | each frobnicate ]') } asDictionary).
	stackTrace := error at: #stackTrace.
	self assert: stackTrace last equals: 'UndefinedObject>>DoIt'.
	self deny: (stackTrace anySatisfy: [ :each | each includesSubstring: 'MCP' ]).
	self deny: (stackTrace anySatisfy: [ :each | each includesSubstring: 'OpalCompiler' ])
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateStopCollapsesARecursion [
	"A recursion fills every frame kept with one name. The fixture's name must not begin with MCP, whose frames are cut as the server's own, and it waits rather than computes, so the test grows no memory."

	| fixture result |
	self timeLimit: 30 seconds.
	fixture := self
		           createClassNamed: 'EvalStopRecursionFixture'
		           superclassName: 'Object'
		           slots: #(  )
		           classSlots: #(  ).
	result := [
		          self
			          ensureMethodSource: 'descend: n
	n = 0 ifTrue: [ ^ (Delay forSeconds: 60) wait ].
	^ self descend: n - 1'
			          protocol: 'fixture'
			          on: fixture.
		          self evaluateBriefly: 'EvalStopRecursionFixture new descend: 100' ] ensure: [
		          self removeClassNamed: 'EvalStopRecursionFixture' ].
	self assert: ((self stoppedTextOf: result) lines anySatisfy: [ :each |
			 (each beginsWith: 'EvalStopRecursionFixture>>descend:, at least ') and: [ each endsWith: ' times in a row' ] ])
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateStopCollectsGarbageAfterTheAnswer [
	"What a stopped evaluation grew is garbage once it ends. A full collection of a large heap takes seconds, so the process that stopped it collects only once the answer has gone out, which the call's post-response action tells it, and until then it waits."

	| actions before helpers |
	self timeLimit: 30 seconds.
	before := self liveProcessesNamed: 'evaluate stop'.
	actions := OrderedCollection new.
	self evaluateBriefly: '[ true ] whileTrue' deferringInto: actions.
	helpers := (self liveProcessesNamed: 'evaluate stop') copyWithoutAll: before.
	[
		self assert: actions size equals: 1.
		self assert: helpers size equals: 1.
		(Delay forMilliseconds: 100) wait.
		self deny: helpers first isTerminated ] ensure: [ actions do: #value ].
	self waitUntilEnded: helpers first.
	self assert: helpers first isTerminated
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateStopCollectsGarbageOnceTheCodeHasUnwound [
	"The answer may go out while the stopped code still unwinds, and what it grew stays reachable until it has, so the collection waits for the unwinding as well as for the answer."

	| actions before helpers collections |
	self timeLimit: 30 seconds.
	MCPEvaluateTestProbe reset.
	before := self liveProcessesNamed: 'evaluate stop'.
	actions := OrderedCollection new.
	[
		self
			stoppedTextUnwindingBrieflyOf: '[ [ true ] whileTrue ] ensure: [ MCPEvaluateTestProbe holdUntilReleased ]'
			deferringInto: actions.
		collections := self fullGarbageCollections.
		actions do: #value.
		self assert: self fullGarbageCollections equals: collections.
		helpers := (self liveProcessesNamed: 'evaluate stop') copyWithoutAll: before.
		self assert: helpers size equals: 1 ] ensure: [
			MCPEvaluateTestProbe release.
			MCPEvaluateTestProbe holder ifNotNil: [ :holder | self waitUntilEnded: holder ] ].
	self waitUntilEnded: helpers first.
	self assert: helpers first isTerminated.
	self assert: self fullGarbageCollections > collections
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateStopCollectsGarbageWhenTheAnswerNeverGoesOut [
	"A client that gave up leaves the answer unwritten, and what the call deferred unrun. The process that stopped the code waits for the answer only as long as the answer waits for the unwinding, then collects anyway, rather than keep itself and the garbage forever."

	| actions before collections helpers |
	self timeLimit: 30 seconds.
	before := self liveProcessesNamed: 'evaluate stop'.
	collections := self fullGarbageCollections.
	actions := OrderedCollection new.
	self stoppedTextUnwindingBrieflyOf: '[ true ] whileTrue' deferringInto: actions.
	helpers := (self liveProcessesNamed: 'evaluate stop') copyWithoutAll: before.
	self assert: helpers size equals: 1.
	self waitUntilEnded: helpers first.
	self assert: helpers first isTerminated.
	self assert: self fullGarbageCollections > collections
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateStoppedAnswersItsTranscript [
	"What the code wrote before it was stopped may be all that says how far it got. It comes last, after the recipe, as in every other answer, and the Transcript is put back."

	| previous result |
	self timeLimit: 30 seconds.
	previous := Smalltalk globals at: #Transcript.
	result := self evaluateBriefly: 'Transcript show: ''started''. [ true ] whileTrue'.
	self assert: (Smalltalk globals at: #Transcript) identicalTo: previous.
	self
		assert: ((self stoppedTextOf: result) lines last: 3)
		equals: #( 'A fork has no time limit, and at this priority it holds up no evaluation.'
			   'Transcript:' 'started' ).
	self assert: ((result structuredContent at: #error) at: #transcript) equals: 'started'
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateStoppedAnswersTheTranscriptAsItWasAtTheStop [
	"Once the call has stopped the code, what its unwinding writes or raises does not reach the answer."

	| result |
	self timeLimit: 30 seconds.
	result := self evaluateBriefly:
		          '[ Transcript show: ''before''. (Delay forSeconds: 10) wait ] ensure: [ Transcript show: ''cleanup''. 1/0 ]'.
	self stoppedTextOf: result.
	self assert: ((result structuredContent at: #error) at: #transcript) equals: 'before'
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateStoppedFramesCollapseARecursion [
	"A run of equal frame names is one line with its count, and the run that reaches the last frame kept, when the stack goes deeper, counts at least that many."

	| lines tool |
	tool := MCPToolEvaluate new.
	lines := tool collapsedFrameLines: (Array new: 20 withAll: 'EvalStopRecursionFixture>>descend:') deeper: true.
	self assert: lines equals: #( 'EvalStopRecursionFixture>>descend:, at least 20 times in a row' ).
	self assert: (tool collapsedFrameLines: #( 'a' 'b' 'b' 'c' 'b' ) deeper: false) equals: #( 'a' 'b, 2 times in a row'
	   'c' 'b' ).
	self assert: (tool collapsedFrameLines: #( 'a' 'b' ) deeper: true) equals: #( 'a' 'b' )
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateStoppedTextNamesTheLimitAndTheWayToRunLongerWork [
	"The answer names the limit the code reached, where it was, and the one way it recommends to run longer work. It does not offer to raise the limit: through a client that waits less, a raised limit loses the answer while the code goes on."

	| text tool |
	tool := MCPToolEvaluate new.
	text := tool contentTextForStructuredContent: (Dictionary new
			         at: #summary put: (tool stoppedMessageFor: 30);
			         at: #error put: (Dictionary new
					          at: #stoppedIn put: (tool collapsedFrameLines: (Array new: 20 withAll: 'EvalPayroll>>employees') deeper: true);
					          at: #hint put: tool longerWorkHintLines;
					          at: #timeoutSeconds put: 30;
					          yourself);
			         yourself).
	self assert: text equals: (String lf join: 'Evaluation stopped after 30 s, its time limit.
What it changed before then stays changed.
Stopped in:
EvalPayroll>>employees, at least 20 times in a row
Run longer work in a forked process that writes its result to a file:
[ | file result |
	file := FileLocator imageDirectory / ''result.txt''.
	file ensureDelete.
	result := [ "the work" ] on: Error do: [ :error | error description ].
	file writeStreamDo: [ :out | out print: result ] ]
		forkAt: Processor userBackgroundPriority
		named: ''result''
The file appears when the work ends; read it in a later call.
A fork has no time limit, and at this priority it holds up no evaluation.' lines).
	self deny: (text includesSubstring: 'timeoutSeconds')
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateStopsAComputingLoopUnderEitherPreemptionRule [
	"A loop that computes never yields, so only a process above it can take the processor back, whichever way the virtual machine requeues the process it preempts. The process that terminates the loop runs at the loop's priority, so the loop is taken off the run queue first, and has unwound under either rule by the time the answer goes.

	The limit is a second, not the tests' fifth of one: the stop must find the loop running, and a loaded machine does not promise to start it, or to reach it, in 0.2 s."

	self timeLimit: 30 seconds.
	self underEitherPreemptionRuleDo: [ :yields |
			| actions before evaluators lines milliseconds result rule |
			rule := 'With processPreemptionYields ' , yields printString.
			before := self processesNamed: 'evaluate'.
			actions := OrderedCollection new.
			[
				milliseconds := Time millisecondsToRun: [ result := self evaluate: '[ true ] whileTrue' within: 1 deferringInto: actions ].
				evaluators := (self processesNamed: 'evaluate') copyWithoutAll: before ] ensure: [ actions do: #value ].
			self assert: (self resultIndicatesError: result).
			lines := (self stoppedText: (self firstTextFromToolResult: result) after: 1) lines.
			self deny: (lines includes: 'Its ensure blocks were still running when this answer was sent.') description: rule.
			self assert: (lines includes: 'Stopped in:').
			self assert: (lines includes: 'UndefinedObject>>DoIt').
			self assert: evaluators size equals: 1.
			self waitUntilEnded: evaluators first.
			self assert: evaluators first isTerminated description: rule.
			self assert: milliseconds < 10000 ]
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateStopsAFailureWhoseEnsureBlockOutlastsTheLimit [
	"A failure is answered only once its ensure blocks have run, so one that waits past the limit is stopped there, like any other code."

	| result |
	self timeLimit: 30 seconds.
	result := self evaluateBriefly: '[ 1/0 ] ensure: [ (Delay forMilliseconds: 500) wait ]'.
	self assert: ((self stoppedTextOf: result) includesSubstring: 'Stopped in:')
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateStopsARecursionPastItsStackBound [
	"An endless recursion grows the image by GBs within its time limit, so the stack is looked at while the code runs, and the code is stopped once it passes a bound, long before the limit. The fixture waits at the bottom of a recursion just past a low bound, so the test grows no memory."

	| fixture lines milliseconds result |
	self timeLimit: 30 seconds.
	fixture := self
		           createClassNamed: 'EvalStopRecursionFixture'
		           superclassName: 'Object'
		           slots: #(  )
		           classSlots: #(  ).
	[
		self
			ensureMethodSource: 'descend: n
	n = 0 ifTrue: [ ^ (Delay forSeconds: 60) wait ].
	^ self descend: n - 1'
			protocol: 'fixture'
			on: fixture.
		milliseconds := Time millisecondsToRun: [
				                result := self
					                          stoppedEarlyResultOf: 'EvalStopRecursionFixture new descend: 2000'
					                          bounds: [ :command | command stackDepthLimit: 1000 ] ] ] ensure: [
		self removeClassNamed: 'EvalStopRecursionFixture' ].
	self assert: result isError.
	lines := (self textOfEvaluateResult: result) lines.
	self assert: (lines first: 2) equals: #( 'Evaluation stopped: its stack passed 1000 frames, which an endless recursion does.'
		   'What it changed before then stays changed.' ).
	self assert: (lines anySatisfy: [ :each | each beginsWith: 'EvalStopRecursionFixture>>descend:, at least ' ]).
	self assert: milliseconds < 10000
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateStopsAWaitAndRunsItsEnsureBlocks [
	"A stop unwinds the code as any termination does: its ensure blocks run, and the Transcript it was recording is put back."

	| result transcript |
	self timeLimit: 30 seconds.
	MCPEvaluateTestProbe reset.
	transcript := Smalltalk globals at: #Transcript.
	result := self evaluateBriefly: '[ (Delay forSeconds: 60) wait ] ensure: [ MCPEvaluateTestProbe noteEnsureRan ]'.
	self deny: ((self stoppedTextOf: result) includesSubstring: 'still running').
	self assert: MCPEvaluateTestProbe ensureRan.
	self assert: (Smalltalk globals at: #Transcript) identicalTo: transcript
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateStopsAWaitInACriticalSectionWithoutSignallingIt [
	"Terminated while it waits to enter a critical section, a process leaves without signalling the semaphore, which it never acquired, but only when terminated from where it waits: suspended first, it would signal on its way out and let a second process in. So a stop leaves a waiting evaluator waiting."

	| holder mutex |
	self timeLimit: 30 seconds.
	MCPEvaluateTestProbe reset.
	mutex := MCPEvaluateTestProbe mutex.
	holder := [ mutex critical: [ MCPEvaluateTestProbe holdUntilReleased ] ]
		          forkAt: Processor activePriority + 1
		          named: 'mcp-evaluate-mutex-holder-probe'.
	[
		self deny:
			((self stoppedTextOf: (self evaluateBriefly: 'MCPEvaluateTestProbe mutex critical: [ #entered ]')) includesSubstring:
				 'still running').
		self deny: mutex isSignaled description: 'The stopped evaluation signalled a semaphore it never acquired.' ] ensure: [
			MCPEvaluateTestProbe release.
			self waitUntilEnded: holder ].
	self assert: holder isTerminated.
	self assert: mutex isSignaled.
	mutex wait.
	self deny: mutex isSignaled description: 'The semaphore admits a second process.'
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateStopsAnEndlessRecursionWithinASecondOrTwo [
	"payroll #3's recursion grew the image by more than a GB a second until its time limit, and stopping a stack that deep took longer than the limit. Its stack passes the bound within a fraction of a second, so it is stopped long before the limit, having grown the image by a few hundred MB."

	| fixture milliseconds result |
	self timeLimit: 30 seconds.
	fixture := self
		           createClassNamed: 'EvalStopRecursionFixture'
		           superclassName: 'Object'
		           slots: #(  )
		           classSlots: #(  ).
	[
		self
			ensureMethodSource: 'employees
	^ self employees sorted'
			protocol: 'fixture'
			on: fixture.
		milliseconds := Time millisecondsToRun: [ result := self evaluate: 'EvalStopRecursionFixture new employees' within: 30 ] ]
		ensure: [ self removeClassNamed: 'EvalStopRecursionFixture' ].
	self assert: (self resultIndicatesError: result).
	self
		assert: (self firstTextFromToolResult: result) lines first
		equals: 'Evaluation stopped: its stack passed 1000000 frames, which an endless recursion does.'.
	self assert: milliseconds < 10000
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateStopsCodeThatCatchesEveryException [
	"A limit that signals is caught by the first handler that takes every exception, and the code carries on. Terminating a process signals nothing."

	| milliseconds result |
	self timeLimit: 30 seconds.
	milliseconds := Time millisecondsToRun: [
		                result := self evaluateBriefly: '[ [ true ] whileTrue ] on: Exception do: [ :e | [ true ] whileTrue ]' ].
	self deny: ((self stoppedTextOf: result) includesSubstring: 'still running').
	self assert: milliseconds < 10000
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateStopsCodeThatKeepsMoreMemoryThanItsBound [
	"Code that keeps what it allocates without recursing passes no stack bound, so the image's memory backs the stack up. The bound is set low and the code keeps 64 MB, then waits, so the test allocates no GBs. A collection beforehand keeps garbage freed meanwhile from hiding the growth."

	| lines milliseconds result |
	self timeLimit: 30 seconds.
	Smalltalk garbageCollect.
	milliseconds := Time millisecondsToRun: [
			                result := self
				                          stoppedEarlyResultOf:
				                          '| kept | kept := (1 to: 8) collect: [ :each | ByteArray new: 8 * 1024 * 1024 ]. (Delay forSeconds: 60) wait. kept size'
				                          bounds: [ :command | command memoryGrowthLimit: 16 * 1024 * 1024 ] ].
	self assert: result isError.
	lines := (self textOfEvaluateResult: result) lines.
	self assert: (lines first: 2) equals: #( 'Evaluation stopped: the image''s memory grew by more than 16 MB while it ran.'
		   'What it changed before then stays changed.' ).
	self assert: (lines includes: 'Stopped in:').
	self assert: milliseconds < 10000
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateThatNeverStartedSaysSo [
	"Whether an evaluation behind a computing process ever gets a turn depends on how the virtual machine schedules processes of one priority, so the double leaves it unstarted, as if it never did."

	| command error holder result |
	self timeLimit: 30 seconds.
	holder := [ [ true ] whileTrue ] forkAt: Processor activePriority - 1 named: 'mcp-evaluate-holder-probe'.
	[
		command := MCPEvaluateCommandNeverStarting code: '3 + 4' timeLimit: self stopLimitSeconds previewLimit: 100.
		result := MCPToolEvaluate new answerFor: command execute ] ensure: [ holder terminate ].
	error := result structuredContent at: #error.
	self assert: result isError.
	self
		assert: (result structuredContent at: #summary)
		equals: 'Evaluation did not start within ' , self stopLimitSeconds printString , ' s, its time limit; none of it ran.'.
	self assert: ((error at: #heldBy) anySatisfy: [ :each |
			 each beginsWith: 'a process an evaluation forked, named mcp-evaluate-holder-probe, in ' ]).
	self assert: (error at: #timeoutSeconds) equals: self stopLimitSeconds.
	self assert: command evaluator isTerminated
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateTimeoutSecondsIsAnIntegerFromOneToSixHundred [
	"A limit of 0 would stop the code before it ran, and one above ten minutes would let an evaluation nobody waits for any more cost more. The description says what a limit longer than the client waits costs."

	| property tool |
	tool := MCPToolEvaluate new.
	property := self inputPropertyNamed: 'timeoutSeconds' inTool: tool.
	self assert: property type equals: 'integer'.
	self assert: (property extraProperties at: #default) equals: 30.
	self assert: (property extraProperties at: #minimum) equals: 1.
	self assert: (property extraProperties at: #maximum) equals: 600.
	self assert: (property description includesSubstring: 'loses the answer').
	self assert: tool inputSchema required equals: #( 'code' ).
	self
		assertResult: (self callDiscoveredToolNamed: 'evaluate' withArguments: {
					 (#code -> '1').
					 (#timeoutSeconds -> 0) } asDictionary)
		refusesArgumentsSaying: 'timeoutSeconds must be at least 1, not 0.'.
	self
		assert: ((tool requestFromToolCallArguments: {
					  (#code -> '1').
					  (#timeoutSeconds -> 3600) } asDictionary) integerArgumentNamed: 'timeoutSeconds')
		equals: 600
]

{ #category : 'tests' }
MCPToolContractsTest >> testEvaluateToolPointsAtTheToolCatalog [
	"evaluate is where an agent lands when it believes no dedicated tool exists, so its description has to name the way out."

	| tool |
	tool := self toolRegistry toolNamed: 'evaluate' ifAbsent: [ self fail: 'Missing evaluate tool' ].
	self assert: (tool description includesSubstring: 'tool_search')
]

{ #category : 'tests' }
MCPToolContractsTest >> testEveryAdvertisedToolSaysWhatItDoesWithinACatalogLine [
	"A host that lists tools one line each, as OpenCode's code mode does, shows the first 120 characters of a description. A first sentence longer than that is cut before it has said what the tool is for."

	| offenders |
	offenders := self toolRegistry advertisedTools reject: [ :tool |
			             | description |
			             description := tool description.
			             ((description includesSubstring: '. ')
				              ifTrue: [ description copyFrom: 1 to: (description indexOfSubCollection: '. ') ]
				              ifFalse: [ description ]) size <= 120 ].
	self assertEmpty: (offenders collect: [ :each | each name ])
]

{ #category : 'tests' }
MCPToolContractsTest >> testEveryPagingToolSaysHowBigAPageIs [
	"A page carries nextOffset when another one exists and never says how large it was, so a caller that wants to know has only the contract to read. A tool that takes an offset has to answer there."

	| registry silent |
	registry := self toolRegistry.
	silent := registry tools
		          select: [ :tool |
		          (tool inputSchema properties anySatisfy: [ :each | each name = 'offset' ]) and: [ tool defaultPageLimit isNil ] ]
		          thenCollect: [ :tool | tool name ].
	self assertEmpty: silent.
	registry tools do: [ :tool |
			tool defaultPageLimit ifNotNil: [ :pageSize |
					self assert: pageSize > 0.
					self assert: ((registry contractForTool: tool) at: #pageSize) equals: pageSize ] ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testEveryToolHasAnIconOfItsOwn [
	"An icon two tools share marks neither of them. Another project's tools are its own to keep apart, and loading one must not fail this."

	| byIcon shared |
	byIcon := Dictionary new.
	self builtInToolClasses do: [ :each |
		(byIcon at: each toolIconSpec cacheKey ifAbsentPut: [ OrderedCollection new ]) add: each toolName ].
	shared := byIcon values select: [ :each | each size > 1 ] thenCollect: [ :each | each sorted ].

	self assert: shared asArray equals: #(  )
]

{ #category : 'tests' }
MCPToolContractsTest >> testEveryToolNameMapsToAKnownDomainAndAction [
	"A name that misses the maps gets the generic tools-and-arrow icon, which says nothing. A new tool either reuses a word the maps know or adds one; a name of one word is an action alone. This is MCP's own vocabulary: a tool another project ships cannot be spelled out of it, and says what it looks like itself."

	| unmapped |
	unmapped := self builtInToolClasses
		            reject: [ :each |
				            | parts |
				            parts := each toolName substrings: '_'.
				            (parts size = 1 or: [ MCPToolIconSpec domainIconMap includesKey: parts first ]) and: [
					            MCPToolIconSpec actionIconMap includesKey: parts last ] ]
		            thenCollect: [ :each | each toolName ].

	self assert: unmapped asArray sorted equals: #(  )
]

{ #category : 'tests' }
MCPToolContractsTest >> testEveryToolNamesAMissingClassAlike [
	"Every argument that takes a class says a missing one in the same words: the noun of the role the name had, then the name, with that role's code, or a warning naming the scope key that skipped it. None shows how a lookup is made."

	| target |
	target := self
		          createClassNamed: self missingClassTargetName
		          superclassName: 'Object'
		          slots: #(  )
		          classSlots: #(  ).
	self withoutEpiceaDuring: [ target compile: 'probe ^ 1' classified: 'probing' ].
	[ self missingClassCases do: [ :each | self assertNamesAMissingClassAlike: each ] ] ensure: [
			self removeClassNamed: self missingClassNewClassName.
			self removeClassNamed: self missingClassTargetName ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testExternalToolFixtureIsNotBuiltIn [
	"Two separate facts about the same fixture. It is not built in, so MCP's naming, grouping and icon conventions are not asked of it; and it answers false to discovery, which is its own doing rather than a consequence of the package it sits in."

	self assert: (MCPTool concreteSubclasses includes: MCPExternalTestTool).
	self deny: MCPExternalTestTool isBuiltIn.
	self deny: MCPExternalTestTool shouldAutoRegister.
	self deny: (self builtInToolClasses includes: MCPExternalTestTool).
	self deny: (MCPTool builtInGroupNames includes: MCPExternalTestTool groupName)
]

{ #category : 'tests' }
MCPToolContractsTest >> testGetClassHasAccurateNameAndRequiredArguments [

	| inputPropertyNames tool |
	tool := MCPToolGetClass new.
	inputPropertyNames := tool inputSchema properties collect: [ :each | each name ].
	self assert: tool name equals: 'class_get'.
	self assert: tool inputSchema required asSet equals: #( 'name' ) asSet.
	self assert: (inputPropertyNames includes: 'includeComment')
]

{ #category : 'tests' }
MCPToolContractsTest >> testGetMethodHasAccurateNameAndRequiredArguments [

	| propertyNames |
	propertyNames := MCPToolGetMethod new inputSchema properties collect: [ :each | each name ].
	self assert: MCPToolGetMethod new name equals: 'method_get'.
	self assert: MCPToolGetMethod new inputSchema required asSet equals: #( 'selector' ) asSet.
	self assert: (propertyNames includes: 'class').
	self assert: (propertyNames includes: 'selector').
	self assert: (propertyNames includes: 'side').
	self assert: (propertyNames includes: 'includeVariableDetails')
]

{ #category : 'tests' }
MCPToolContractsTest >> testGetToolReturnsSchemaForCatalogTool [

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
	self assert: inputProperties asSet equals: #( 'name' 'location' 'packages' 'subdirectory' ) asSet.
	self assert: ((contract at: #inputSchema) at: #required) asArray equals: #( 'name' ).
	getToolPropertyNames := MCPToolGetTool new inputSchema properties collect: [ :each | each name ].
	self assert: getToolPropertyNames equals: #( 'name' )
]

{ #category : 'tests - validation' }
MCPToolContractsTest >> testHandleJSONAnswersMissingRequiredArgumentsAsAToolError [
	"Arguments a tool's schema refuses are for the model to correct, so they come back as a tool result naming the argument, not as a protocol error a client may keep to itself."

	| response |
	response := self handleJSON:
		            '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"tool_call","arguments":{"name":"evaluate","arguments":{}}}}'.
	self deny: (response includesSubstring: '"code":-32602').
	self assert: (response includesSubstring: '"isError":true').
	self assert: (response includesSubstring: 'Invalid arguments for evaluate. code is required.')
]

{ #category : 'tests - validation' }
MCPToolContractsTest >> testHandleJSONAnswersToolCallArgumentsItRefusesAsAToolError [
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
MCPToolContractsTest >> testHandleJSONReturnsInternalErrorForUnhandledHalt [

	| handler processor response |
	processor := MCPMessageProcessor new.
	"What the answer says about the image is withheld unless a server asks for it, and this test is about what it says."
	processor includesErrorData: true.
	handler := MCPMessageSendHandler new
		           receiver: self;
		           methodName: 'mcp/test-halt';
		           messageSelector: #signalHaltForMCPMessageProcessorTest;
		           yourself.
	processor addHandler: handler.
	response := processor handleJSON: '{"jsonrpc":"2.0","id":1,"method":"mcp/test-halt"}'.
	self assert: (response includesSubstring: '"code":-32603').
	self assert: (response includesSubstring: 'Halt').
	self assert: (response includesSubstring: 'mcp processor halt test')
]

{ #category : 'tests' }
MCPToolContractsTest >> testHandleJSONReturnsMethodNotFoundForUnknownTool [

	| response |
	response := self handleJSON: '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"does-not-exist","arguments":{}}}'.
	self assert: (response includesSubstring: '"code":-32601').
	self assert: (response includesSubstring: '"message":"The method does not exist / is not available."')
]

{ #category : 'tests' }
MCPToolContractsTest >> testImageContentSerializesNativeMCPImageBlock [

	| content json |
	content := MCPStructureImageContent data: 'abc123' mimeType: 'image/png'.
	json := content asJRPCJSON.
	self assert: (json at: #type) equals: 'image'.
	self assert: (json at: #data) equals: 'abc123'.
	self assert: (json at: #mimeType) equals: 'image/png'
]

{ #category : 'tests' }
MCPToolContractsTest >> testInitializeAdvertisesOnlyWhatTheServerHas [
	"A capability promises the methods of a domain. Prompts are not advertised because the server holds none, and nothing is advertised that the transport could not honour: the stream carries list_changed, so that is declared, while subscribe is not."

	| capabilities response |
	response := (self mcpWithoutObservabilityExport
		             onInitialize: nil
		             capabilities: nil
		             clientInfo: nil
		             websiteUrl: nil) asJRPCJSON.
	capabilities := response at: #capabilities.
	self assert: ((capabilities at: #tools) at: #listChanged).
	self assert: ((capabilities at: #resources) at: #listChanged).
	self deny: ((capabilities at: #resources) includesKey: #subscribe).
	self deny: (capabilities includesKey: #prompts)
]

{ #category : 'tests' }
MCPToolContractsTest >> testInitializeAdvertisesPharoServerIcon [

	| expectedIcon icon response serverInfo |
	expectedIcon := (MCPStructureIcon pngIconNamed: #pharo) asJRPCJSON.
	response := (self mcpWithoutObservabilityExport
		             onInitialize: nil
		             capabilities: nil
		             clientInfo: nil
		             websiteUrl: nil) asJRPCJSON.
	serverInfo := response at: #serverInfo.
	self assert: (serverInfo includesKey: #icons).
	self deny: (serverInfo at: #icons) isEmpty.
	icon := (serverInfo at: #icons) first.
	self assert: icon equals: expectedIcon
]

{ #category : 'tests' }
MCPToolContractsTest >> testInitializeAdvertisesSupportedPharoVersions [

	| metadata pharo response runtimeVersion serverInfo |
	response := (self mcpWithoutObservabilityExport
		             onInitialize: nil
		             capabilities: nil
		             clientInfo: nil
		             websiteUrl: nil) asJRPCJSON.
	serverInfo := response at: #serverInfo.
	self deny: (serverInfo includesKey: #_meta).
	self assert: (response includesKey: #_meta).
	metadata := response at: #_meta.
	self assert: (metadata includesKey: #'io.github.evref-bl/pharo').
	pharo := metadata at: #'io.github.evref-bl/pharo'.
	self assert: (pharo at: #supportedMajorVersions) equals: #( 10 11 12 13 14 15 ).
	self assert: (pharo at: #supportedLauncherVersions) equals: #( '100' '110' '120' '130' '140' '150' ).
	runtimeVersion := pharo at: #runtimeVersion.
	self assert: runtimeVersion isString.
	self deny: runtimeVersion isEmpty
]

{ #category : 'tests' }
MCPToolContractsTest >> testInitializeResponseSerializesSupportedPharoVersions [

	| response |
	response := self handleJSON:
		            '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{},"websiteUrl":null}}'.
	self assert: (response includesSubstring: '"result"').
	self assert: (response includesSubstring: '"_meta"').
	self assert: (response includesSubstring: '"io.github.evref-bl/pharo"').
	self assert: (response includesSubstring: '"supportedMajorVersions":[10,11,12,13,14,15]').
	self assert: (response includesSubstring: '"supportedLauncherVersions":["100","110","120","130","140","150"]').
	self assert: (response includesSubstring: '"runtimeVersion":"')
]

{ #category : 'tests' }
MCPToolContractsTest >> testInputSchemaJSONHasCompactTopLevelShape [

	| schema |
	schema := MCPToolSearchMethods new inputSchema asJRPCJSON.
	self assert: (schema keys collect: [ :key | key asString ] as: Set) equals: #( 'type' 'properties' 'additionalProperties' ) asSet.
	self assert: (schema at: #additionalProperties) equals: false
]

{ #category : 'tests' }
MCPToolContractsTest >> testMCPAddToolRefreshesAdvertisedTools [

	| server |
	server := MCP new.
	server advertiseAllTools.
	self deny: (server advertisedToolNames includes: MCPHaltingTestTool toolName).
	server addTool: MCPHaltingTestTool.
	self assert: (server toolRegistry includesToolNamed: MCPHaltingTestTool toolName).
	self assert: (server advertisedToolNames includes: MCPHaltingTestTool toolName)
]

{ #category : 'tests' }
MCPToolContractsTest >> testMCPAddToolsAnswersTheAddedTools [

	| added server |
	server := MCP new.
	added := server addTools: { MCPHaltingTestTool }.
	self assert: added size equals: 1.
	self assert: added first class equals: MCPHaltingTestTool.
	self assert: (server toolRegistry includesToolNamed: MCPHaltingTestTool toolName)
]

{ #category : 'tests' }
MCPToolContractsTest >> testMCPMethodsHaveImplementedSelfAndSuperSends [

	| issues |
	issues := self selfSentNotImplementedCritiquesForMCPMethods.
	self
		assert: issues isEmpty
		description: (String streamContents: [ :stream | issues do: [ :each | stream nextPutAll: each ] separatedBy: [ stream cr ] ])
]

{ #category : 'tests' }
MCPToolContractsTest >> testMCPRemoveToolRefreshesAdvertisedTools [

	| server |
	server := MCP new.
	server advertiseAllTools.
	server addTool: MCPHaltingTestTool.
	self assert: (server advertisedToolNames includes: MCPHaltingTestTool toolName).
	server removeTool: MCPHaltingTestTool toolName.
	self deny: (server toolRegistry includesToolNamed: MCPHaltingTestTool toolName).
	self deny: (server advertisedToolNames includes: MCPHaltingTestTool toolName)
]

{ #category : 'tests' }
MCPToolContractsTest >> testMCPsOwnTestFixturesAreNotServed [
	"MCP's default group loads its own tests, so a fixture that names itself and forgot to answer false would be in the catalog of every server in the image. Classes a test generates are left out of the sweep: they exist to be discovered and removed again."

	| served |
	served := Set new.
	{
		MCPToolRegistry.
		MCPResourceRegistry.
		MCPPromptRegistry } do: [ :registryClass |
			registryClass default autoRegisteringClasses do: [ :each |
					| packageName |
					packageName := each package name asString.
					((packageName beginsWith: 'MCP') and: [
						 (packageName includesSubstring: 'Tests') and: [ packageName ~= self generatedPackageName ] ]) ifTrue: [
						served add: each name ] ] ].
	self assert: served asArray sorted equals: #(  )
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testMessageNotUnderstoodSuggestsNearMissSelectors [
	"Thirty-five failures in a day of real use were guesses at an API; the receiver knows which selectors the guess resembles."

	| error |
	error := self errorFrom: (self
			         callDiscoveredToolNamed: 'evaluate'
			         withArguments: { (#code -> 'OrderedCollection new adAll: #( 1 2 3 )') } asDictionary).
	self assert: (error at: #suggestedSelectors) first equals: 'addAll:'
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testMessageNotUnderstoodSuggestsNothingForAnUnrelatedSelector [
	"Pharo's corrector answers its closest candidates whatever their distance; suggesting those would be worse than saying nothing."

	| error |
	error := self errorFrom: (self
			         callDiscoveredToolNamed: 'evaluate'
			         withArguments: { (#code -> 'OrderedCollection new frobnicate') } asDictionary).
	self deny: (error includesKey: #suggestedSelectors)
]

{ #category : 'tests' }
MCPToolContractsTest >> testMessageProcessorRegistersInheritedMCPHandlersForSubclass [

	| processor request response server |
	server := MCPSubclassHandlerTestServer new.
	processor := MCPMessageProcessor new.
	processor addHandlersFromPragmasIn: server.
	request := JRPCRequestObject id: 1 method: 'tools/list' params: Dictionary new.
	response := processor handleJRPCRequestObject: request.
	self assert: response class equals: JRPCSuccessResponseObject
]

{ #category : 'tests' }
MCPToolContractsTest >> testMessageProcessorUsesSubclassJRPCHandlerOverride [

	| processor request response result server |
	server := MCPSubclassHandlerTestServer new.
	processor := MCPMessageProcessor new.
	processor addHandlersFromPragmasIn: server.
	request := JRPCRequestObject id: 1 method: 'ping' params: Dictionary new.
	response := processor handleJRPCRequestObject: request.
	result := response result.
	self assert: response class equals: JRPCSuccessResponseObject.
	self assert: (result at: #source) equals: 'subclass'
]

{ #category : 'tests' }
MCPToolContractsTest >> testMethodMetadataSearchDescriptionPointsToSpecializedReferenceTools [

	| description protocolDescription selectorDescription tool |
	tool := MCPToolSearchMethods new.
	description := tool description.
	self assert: (description includesSubstring: 'method_source_search').
	self assert: (description includesSubstring: 'method_reference_search').
	selectorDescription := (self inputPropertyNamed: 'selector' inTool: tool) description.
	protocolDescription := (self inputPropertyNamed: 'protocol' inTool: tool) description.
	self assert: (selectorDescription includesSubstring: 'selector').
	self assert: (protocolDescription includesSubstring: 'protocol')
]

{ #category : 'tests' }
MCPToolContractsTest >> testMethodMetadataSearchHasAccurateNameAndSchema [

	| propertyNames schema scopeProperty scopePropertyNames |
	schema := MCPToolSearchMethods new inputSchema.
	propertyNames := schema properties collect: [ :each | each name ].
	scopeProperty := schema properties detect: [ :each | each name = 'scope' ].
	scopePropertyNames := (scopeProperty extraProperties at: #properties) collect: [ :each | each name ].
	self assert: MCPToolSearchMethods new name equals: 'method_search'.
	self assert: schema required equals: #(  ).
	self assert: propertyNames asSet equals: #( 'scope' 'selector' 'protocol' 'offset' ) asSet.
	self assert: (scopeProperty extraProperties at: #additionalProperties) equals: false.
	self
		assert: scopePropertyNames asSet
		equals: #( 'classes' 'packages' 'superclassesOf' 'subclassesOf' 'hierarchyOf' 'side' ) asSet
]

{ #category : 'tests' }
MCPToolContractsTest >> testMethodMetadataSearchListsMethodsForExistingClassScope [

	| data methods result selectors |
	result := self
		          callToolNamed: 'method_search'
		          withArguments: { (self searchScope: { (#classes -> #( 'MCPToolMethodSearchTestTarget' )) }) } asDictionary.
	data := (result at: #structuredContent) at: #data.
	methods := data at: #methods.
	selectors := methods collect: [ :each | each at: #selector ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: methods isNotEmpty.
	self assert: (selectors includes: 'alphaNeedleSelector').
	self assert: (selectors includes: 'classNeedleSelector')
]

{ #category : 'tests' }
MCPToolContractsTest >> testMethodMetadataSearchReturnsWarningResultForMissingClass [

	| data result warnings |
	result := self
		          callToolNamed: 'method_search'
		          withArguments: { (self searchScope: { (#classes -> #( 'MCPDefinitelyMissingMethodSearchClass' )) }) } asDictionary.
	data := self dataFrom: result.
	warnings := self warningsFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny: (self resultIndicatesError: result).
	self assert: (data at: #methods) isEmpty.
	self assert: warnings size equals: 1.
	self assert: (warnings first includesSubstring: 'MCPDefinitelyMissingMethodSearchClass').
	self assert: (warnings first includesSubstring: 'does not exist, so ').
	self assert: (warnings first includesSubstring: 'Did you mean')
]

{ #category : 'tests' }
MCPToolContractsTest >> testMethodMutationToolsHaveAccurateNamesAndRequiredArguments [

	| createPropertyNames createTool updatePropertyNames updateTool |
	createTool := MCPToolCompileMethod new.
	updateTool := MCPToolUpdateMethod new.
	createPropertyNames := createTool inputSchema properties collect: [ :each | each name ].
	updatePropertyNames := updateTool inputSchema properties collect: [ :each | each name ].
	self assert: createTool name equals: 'method_compile'.
	self assert: updateTool name equals: 'method_update'.
	self assert: createTool inputSchema required asSet equals: #( 'class' 'source' ) asSet.
	self assert: updateTool inputSchema required asSet equals: #( 'class' 'selector' ) asSet.
	self assert: updateTool atLeastOneInputProperties asSet equals: #( 'protocol' 'newSelector' ) asSet.
	self assert: createPropertyNames asSet equals: #( 'class' 'side' 'protocol' 'source' 'force' ) asSet.
	self
		assert: updatePropertyNames asSet
		equals:
		#( 'arguments' 'argumentValueExpressions' 'class' 'force' 'newSelector' 'permutation' 'protocol' 'scope' 'selector' 'side' )
			asSet
]

{ #category : 'tests' }
MCPToolContractsTest >> testMethodToolTraitOwnsSharedMethodHelpers [

	| methodToolClasses sharedSelectors |
	methodToolClasses := {
		                     MCPToolGetMethod.
		                     MCPToolMethodMutation.
		                     MCPToolMethodSearch.
		                     MCPToolRewriteMethods.
		                     MCPToolRemoveMethods }.
	sharedSelectors := #( selectorStringFromRequest: behaviorNamed:classSide: methodReferenceForBehavior:selector:
	                      methodReferenceForClassName:selector:isClassSide: methodScopeQueryFromRequest: ).
	methodToolClasses do: [ :toolClass |
			self assert: (toolClass withAllSuperclasses anySatisfy: [ :each | each traits includes: TMCPMethodTool ]).
			sharedSelectors do: [ :selector |
					| implementingClass |
					implementingClass := toolClass whichClassIncludesSelector: selector.
					self assert: implementingClass isNotNil.
					self assert: (implementingClass >> selector) origin equals: TMCPMethodTool ] ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testMutationDescriptionsExplainForceWarningBehavior [

	| methodForceDescription |
	methodForceDescription := (self inputPropertyNamed: 'force' inTool: MCPToolUpdateMethod new) description.
	self assert: (methodForceDescription includesSubstring: 'refactoring warnings').
	self assert: (methodForceDescription includesSubstring: 'stopping')
]

{ #category : 'tests' }
MCPToolContractsTest >> testMutationToolSchemasAdvertiseRenameScopeConditions [

	| classUpdateInputSchema classUpdatePropertyNames selectorInputSchema selectorPropertyNames |
	classUpdateInputSchema := MCPToolUpdateClass new inputSchema.
	selectorInputSchema := MCPToolUpdateMethod new inputSchema.
	classUpdatePropertyNames := classUpdateInputSchema properties collect: [ :each | each name ].
	selectorPropertyNames := selectorInputSchema properties collect: [ :each | each name ].
	"A class rename takes the whole image, so it offers no scope. It does offer force, because the slot patch it shares a tool with raises refactoring warnings."
	self deny: (classUpdatePropertyNames includes: 'scope').
	self assert: (classUpdatePropertyNames includes: 'force').
	self deny: (classUpdatePropertyNames includes: 'packages').
	self deny: (classUpdatePropertyNames includes: 'classes').
	self deny: (classUpdatePropertyNames includes: 'hierarchyClasses').
	self assert: (selectorPropertyNames includes: 'scope').
	#( 'packages' 'classes' 'hierarchyClasses' ) do: [ :each | self deny: (selectorPropertyNames includes: each) ].
	self assert: (classUpdateInputSchema asJRPCJSON at: #additionalProperties) equals: false.
	self assert: (selectorInputSchema asJRPCJSON at: #additionalProperties) equals: false
]

{ #category : 'tests' }
MCPToolContractsTest >> testNewToolRegistryStartsEmpty [

	| registry |
	registry := MCPToolRegistry new.
	self assert: registry toolNames isEmpty.
	self assert: registry advertisedToolNames isEmpty
]

{ #category : 'tests' }
MCPToolContractsTest >> testNoDescriptionNamesAnArgumentThatDoesNotExist [
	"Renaming an argument used to leave its old name behind in the prose that referenced it, which reads as an instruction to send an argument the schema then rejects. Every argument-shaped word a description uses must be an argument that tool really has."

	| offenders |
	offenders := OrderedCollection new.
	MCPToolRegistry default tools do: [ :tool |
			| names texts |
			names := Set new.
			texts := OrderedCollection new.
			tool description ifNotNil: [ :each | texts add: each ].
			self collectSchemaNames: names descriptions: texts from: tool inputSchema asJRPCJSON.
			texts do: [ :text |
					(self camelCaseWordsIn: text) do: [ :word |
						(names includes: word) ifFalse: [
							offenders add: (String streamContents: [ :stream | stream << tool name << ' names ' << word ]) ] ] ] ].
	self assertEmpty: offenders
]

{ #category : 'tests' }
MCPToolContractsTest >> testNoToolParsesItsRequestOrBuildsACommand [
	"A tool reads its arguments from the request it is given, and does its work or asks an operation for it. The hooks that parsed a request into an object of its own and built a command from that object stay gone, with the names the call flow had before them."

	#( #parsedRequestFromToolRequest: #commandForRequest: #toolRequestFromRequest: #querySpecFromRequest: #methodQueryParametersFromRequest:
	   #refactoringScopeParametersFromRequest: #refactoringModelForScopeParameters:anchoredAtBehavior: ) do: [ :selector |
		self deny: (MCPTool withAllSubclasses anySatisfy: [ :each | each includesSelector: selector ]) description: selector ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testOnlyToolsCanKeepSomeOfThemDiscoverable [

	| server |
	server := MCP onlyTools: {
			          MCPExternalTestTool.
			          MCPToolSearchTools }.
	server advertiseTools: { MCPExternalTestTool }.
	self assert: server toolRegistry toolNames asSet equals: {
			MCPExternalTestTool toolName.
			MCPToolSearchTools toolName } asSet.
	self assert: server advertisedToolNames asSet equals: { MCPExternalTestTool toolName } asSet.
	self deny: ((server rpcToolsList at: #tools) anySatisfy: [ :each | (each at: #name) = MCPToolSearchTools toolName ])
]

{ #category : 'tests' }
MCPToolContractsTest >> testOnlyToolsRegistersExactlyThoseTools [

	| server |
	server := MCP onlyTools: { MCPExternalTestTool }.
	self assert: server toolRegistry toolNames asSet equals: { MCPExternalTestTool toolName } asSet.
	self assert: server advertisedToolNames asSet equals: { MCPExternalTestTool toolName } asSet
]

{ #category : 'tests' }
MCPToolContractsTest >> testOperationsHoldNeitherTheToolNorItsRequest [
	"An operation takes plain arguments and answers what it found or did. Reading the request and writing the answer belong to the tool that runs it."

	MCPCommand allSubclasses do: [ :operation |
		self deny: (#( 'tool' 'request' ) anySatisfy: [ :name | operation allInstVarNames includes: name ]) description: operation name ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testOptionalToolArgumentsAdvertiseDefaultsWhenAvailable [

	| getClassTool getMethodTool removeClassesTool removeMethodsTool rewriteMethodsTool updateMethodTool |
	getClassTool := MCPToolGetClass new.
	getMethodTool := MCPToolGetMethod new.
	updateMethodTool := MCPToolUpdateMethod new.
	rewriteMethodsTool := MCPToolRewriteMethods new.
	removeClassesTool := MCPToolRemoveClasses new.
	removeMethodsTool := MCPToolRemoveMethods new.
	self assert: ((self inputPropertyNamed: 'includeComment' inTool: getClassTool) extraProperties at: #default) equals: false.
	self assert: ((self inputPropertyNamed: 'subclassDepth' inTool: getClassTool) extraProperties at: #default) equals: 0.
	self assert: ((self inputPropertyNamed: 'side' inTool: getMethodTool) extraProperties at: #default) equals: 'instance'.
	self
		assert: ((self inputPropertyNamed: 'includeVariableDetails' inTool: getMethodTool) extraProperties at: #default)
		equals: false.
	self assert: ((self inputPropertyNamed: 'side' inTool: updateMethodTool) extraProperties at: #default) equals: 'instance'.
	self assert: ((self inputPropertyNamed: 'force' inTool: updateMethodTool) extraProperties at: #default) equals: false.
	self assert: ((self inputPropertyNamed: 'confirm' inTool: rewriteMethodsTool) extraProperties at: #default) equals: false.
	self assert: ((self scopePropertyNamed: 'side' inTool: rewriteMethodsTool) extraProperties at: #default) equals: 'both'.
	self assert: ((self inputPropertyNamed: 'force' inTool: removeClassesTool) extraProperties at: #default) equals: false.
	self assert: ((self inputPropertyNamed: 'side' inTool: removeMethodsTool) extraProperties at: #default) equals: 'instance'
]

{ #category : 'tests' }
MCPToolContractsTest >> testProjectMethodsDoNotHandleMessageNotUnderstoodAsControlFlow [

	| methods offendingMethods rule |
	rule := MCPMessageNotUnderstoodHandlerRule new.
	methods := #( 'MCP' 'MCP-Tests' ) flatCollect: [ :packageName | (self packageOrganizer packageNamed: packageName) methods ].
	offendingMethods := methods select: [ :method |
		                    method sendNodes anySatisfy: [ :sendNode | rule isMessageNotUnderstoodHandlerSend: sendNode ] ].
	self assert: offendingMethods isEmpty description: ('Methods handling MessageNotUnderstood: {1}' format:
			 { (offendingMethods collect: [ :method | method printString ] as: Array) printString })
]

{ #category : 'tests' }
MCPToolContractsTest >> testProjectMethodsDoNotSendReflectiveProtocolChecks [

	| forbiddenSelector methods offendingMethods |
	forbiddenSelector := MCPRespondsToUsageRule forbiddenSelector.
	methods := #( 'MCP' 'MCP-Tests' ) flatCollect: [ :packageName | (self packageOrganizer packageNamed: packageName) methods ].
	offendingMethods := methods select: [ :method |
		                    method sendNodes anySatisfy: [ :sendNode | sendNode selector = forbiddenSelector ] ].
	self assert: offendingMethods isEmpty description: ('Methods sending {1}: {2}' format: {
				 forbiddenSelector.
				 (offendingMethods collect: [ :method | method printString ] as: Array) printString })
]

{ #category : 'tests' }
MCPToolContractsTest >> testPromptsGetReturnsInvalidParamsWhenPromptIsUnknown [

	| response |
	response := self handleJSON: '{"jsonrpc":"2.0","id":1,"method":"prompts/get","params":{"name":"missing"}}'.
	self assert: (response includesSubstring: '"code":-32602').
	self assert: (response includesSubstring: '"message":"Invalid method parameter(s)."')
]

{ #category : 'tests' }
MCPToolContractsTest >> testPromptsListReturnsEmptyPromptList [

	| response |
	response := self handleJSON: '{"jsonrpc":"2.0","id":1,"method":"prompts/list"}'.
	self assert: (response includesSubstring: '"result":{"prompts":[]}')
]

{ #category : 'tests' }
MCPToolContractsTest >> testProtocolVersionNegotiation [

	self assert: (MCP negotiatedProtocolVersionFor: '2025-06-18') equals: '2025-06-18'.
	self assert: (MCP negotiatedProtocolVersionFor: '1900-01-01') equals: MCP latestLegacyProtocolVersion
]

{ #category : 'tests' }
MCPToolContractsTest >> testQueryScopeDescriptionsExplainScopeSemantics [

	| classScope methodScope scopePropertyNames selectedNames |
	classScope := self inputPropertyNamed: 'scope' inTool: MCPToolSearchClasses new.
	methodScope := self inputPropertyNamed: 'scope' inTool: MCPToolSearchMethods new.
	scopePropertyNames := (classScope extraProperties at: #properties) collect: [ :each | each name ].
	"One wording for every tool, saying both how entries combine and what omitting the scope means."
	self assert: methodScope description equals: classScope description.
	self assert: (classScope description includesSubstring: 'Omitted').
	self assert: (classScope extraProperties at: #additionalProperties) equals: false.
	self assert: (methodScope extraProperties at: #additionalProperties) equals: false.
	self assert: scopePropertyNames asSet equals: #( 'classes' 'packages' 'superclassesOf' 'subclassesOf' 'hierarchyOf' ) asSet.
	self
		assert: ((methodScope extraProperties at: #properties) collect: [ :each | each name ] as: Set)
		equals: scopePropertyNames asSet , #( 'side' ) asSet.
	"Every entry says what it selects, since a scope nobody can read is a scope nobody narrows."
	selectedNames := (methodScope extraProperties at: #properties) select: [ :each | each description isEmptyOrNil ].
	self assertEmpty: (selectedNames collect: [ :each | each name ])
]

{ #category : 'tests' }
MCPToolContractsTest >> testRPCAdvertisesTheAdvertisedSurfaceOnly [
	"The public surface is capped at fifteen: the catalogue, the classes, the methods, and running code."

	| discoverableToolNames expectedAdvertisedToolNames registry toolNames |
	registry := self toolRegistry.
	toolNames := (self mcpWithoutObservabilityExport rpcToolsList at: #tools) collect: [ :each | each at: #name ].
	expectedAdvertisedToolNames := #( 'tool_search' 'tool_get' 'tool_call' 'class_search' 'class_get' 'class_create' 'class_remove'
	                                  'method_search' 'method_source_search' 'method_reference_search' 'method_get' 'method_compile'
	                                  'method_remove' 'evaluate' 'test_run' ).
	discoverableToolNames := registry toolNames difference: registry advertisedToolNames.
	self assert: expectedAdvertisedToolNames size equals: 15.
	self assert: toolNames asSet equals: registry advertisedToolNames asSet.
	self assert: registry advertisedToolNames asSet equals: expectedAdvertisedToolNames asSet.
	discoverableToolNames do: [ :each | self deny: (toolNames includes: each) ].
	self assert: (registry toolNames includes: 'method_update').
	self deny: (toolNames includes: 'method_update')
]

{ #category : 'tests' }
MCPToolContractsTest >> testRPCAdvertisesToolsInRegistryOrder [
	"Clients cache tools/list and feed it to a model, so the order has to be the registry's and has to hold across calls."

	| first second mcp |
	mcp := self mcpWithoutObservabilityExport.
	first := (mcp rpcToolsList at: #tools) collect: [ :each | each at: #name ].
	second := (mcp rpcToolsList at: #tools) collect: [ :each | each at: #name ].
	self assert: first asArray equals: mcp advertisedToolNames.
	self assert: first asArray equals: second asArray
]

{ #category : 'tests' }
MCPToolContractsTest >> testRPCRefreshesCachedToolMetadata [

	| mcp propertyNames result toolDefinition toolDefinitions |
	mcp := self mcpWithoutObservabilityExport.
	mcp toolsList: Dictionary new.
	toolDefinitions := mcp rpcToolsList at: #tools.
	toolDefinition := toolDefinitions detect: [ :each | (each at: #name) = 'class_search' ].
	propertyNames := ((toolDefinition at: #inputSchema) at: #properties) keys asSet.
	self assert: propertyNames equals: #( 'scope' 'name' 'package' 'tag' 'offset' ) asSet.
	result := mcp rpcToolCall: 'class_search' withParams: { (self searchScope: {
				           (#classes -> #( 'MCPToolContractsTest' )).
				           (#packages -> #( 'MCP-Tests' )) }) } asDictionary.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests' }
MCPToolContractsTest >> testReadScreenHasAccurateNameAndSchemas [

	| depthProperty inputPropertyNames tool |
	tool := MCPToolReadScreen new.
	inputPropertyNames := tool inputSchema properties collect: [ :each | each name ].
	depthProperty := self inputPropertyNamed: 'depth' inTool: tool.
	self assert: tool name equals: 'screen_read'.
	self assert: tool inputSchema required equals: #(  ).
	self assert: inputPropertyNames equals: #( 'window' 'depth' ).
	self assert: (depthProperty extraProperties at: #default) equals: tool defaultDepth.
	self assert: (depthProperty extraProperties at: #maximum) equals: tool maximumDepth
]

{ #category : 'tests' }
MCPToolContractsTest >> testRemoveClassHasAccurateNameAndRequiredArguments [

	self assert: MCPToolRemoveClasses new name equals: 'class_remove'.
	self assert: MCPToolRemoveClasses new inputSchema required asSet equals: #( 'name' ) asSet
]

{ #category : 'tests' }
MCPToolContractsTest >> testRemoveMethodsHasAccurateNameAndRequiredArguments [

	self assert: MCPToolRemoveMethods new name equals: 'method_remove'.
	self assert: MCPToolRemoveMethods new inputSchema required asSet equals: #( 'class' 'selector' ) asSet
]

{ #category : 'tests' }
MCPToolContractsTest >> testRepositoryCreateAndUpdateRequiredArguments [

	| createPropertyNames updatePropertyNames |
	createPropertyNames := MCPToolCreateRepository new inputSchema properties collect: [ :each | each name ].
	updatePropertyNames := MCPToolUpdateRepository new inputSchema properties collect: [ :each | each name ].
	self assert: MCPToolCreateRepository new name equals: 'repository_create'.
	self assert: MCPToolAttachRepository new name equals: 'repository_attach'.
	self assert: MCPToolUpdateRepository new name equals: 'repository_update'.
	self assert: MCPToolCreateRepository new inputSchema required asArray equals: #( 'name' ).
	self assert: MCPToolAttachRepository new inputSchema required asArray equals: #( 'name' 'location' ).
	self assert: MCPToolUpdateRepository new inputSchema required asArray equals: #( 'name' ).
	#( 'name' 'location' 'subdirectory' 'packages' ) do: [ :each | self assert: (createPropertyNames includes: each) ].
	#( 'name' 'location' 'subdirectory' 'packages' 'addPackages' 'removePackages' ) do: [ :each |
		self assert: (updatePropertyNames includes: each) ].
	self deny: (createPropertyNames includes: 'operation').
	self deny: (updatePropertyNames includes: 'operation')
]

{ #category : 'tests' }
MCPToolContractsTest >> testRequestedToolIconsAreSelected [

	MCPStructureIcon resetCaches.
	self
		assert: MCPToolGetClass new icons first asJRPCJSON
		equals: (MCPStructureIcon compositeBaseIconNamed: #class badgeIconNamed: #inspect) asJRPCJSON.
	self
		assert: MCPToolSearchMethodSource new icons first asJRPCJSON
		equals: (MCPStructureIcon compositeBaseIconNamed: #page leftBadgeIconNamed: #workspace rightBadgeIconNamed: #search) asJRPCJSON.
	self
		assert: MCPToolSearchMethodReferences new icons first asJRPCJSON
		equals: (MCPStructureIcon compositeBaseIconNamed: #page leftBadgeIconNamed: #references rightBadgeIconNamed: #search) asJRPCJSON.
	self
		assert: MCPToolUpdateMethod new icons first asJRPCJSON
		equals: (MCPStructureIcon compositeBaseIconNamed: #page badgeIconNamed: #edit) asJRPCJSON.
	self
		assert: MCPToolUpdateClass new icons first asJRPCJSON
		equals: (MCPStructureIcon compositeBaseIconNamed: #class badgeIconNamed: #edit) asJRPCJSON.
	self
		assert: MCPToolListChangeHistoryEntries new icons first asJRPCJSON
		equals:
		(MCPStructureIcon compositeBaseIconNamed: #history leftBadgeIconNamed: #changeUpdate rightBadgeIconNamed: #browse) asJRPCJSON.
	self
		assert: MCPToolRunTestCoverage new icons first asJRPCJSON
		equals:
		(MCPStructureIcon compositeBaseIconNamed: #testRunner leftBadgeIconNamed: #processBrowser rightBadgeIconNamed: #play) asJRPCJSON.
	self
		assert: MCPToolCaptureScreen new icons first asJRPCJSON
		equals: (MCPStructureIcon compositeBaseIconNamed: #window badgeIconNamed: #smallScreenshot) asJRPCJSON.
	self
		assert: MCPToolRunTests new icons first asJRPCJSON
		equals: (MCPStructureIcon compositeBaseIconNamed: #testRunner badgeIconNamed: #play) asJRPCJSON.
	self assert: MCPToolEvaluate new icons first asJRPCJSON equals: (MCPStructureIcon pngIconNamed: #go) asJRPCJSON
]

{ #category : 'tests' }
MCPToolContractsTest >> testResourcesListAnswersTheRegisteredResources [

	| response |
	response := self handleJSON: '{"jsonrpc":"2.0","id":1,"method":"resources/list"}'.
	self assert: (response includesSubstring: '"resources":').
	self assert: (response includesSubstring: MCPImageMetadataResource resourceUri)
]

{ #category : 'tests' }
MCPToolContractsTest >> testResourcesReadAnswersResourceNotFoundWhenTheUriIsUnknown [
	"The spec gives resource-not-found its own code rather than folding it into invalid params, and asks for the URI in the error data."

	| response |
	response := self handleJSON: '{"jsonrpc":"2.0","id":1,"method":"resources/read","params":{"uri":"pharo://missing"}}'.
	self assert: (response includesSubstring: '"code":-32002').
	self assert: (response includesSubstring: '"message":"Resource not found"').
	self assert: (response includesSubstring: '"uri":"pharo://missing"')
]

{ #category : 'tests' }
MCPToolContractsTest >> testResourcesTemplatesListReturnsEmptyTemplateList [

	| response |
	response := self handleJSON: '{"jsonrpc":"2.0","id":1,"method":"resources/templates/list"}'.
	self assert: (response includesSubstring: '"result":{"resourceTemplates":[]}')
]

{ #category : 'tests' }
MCPToolContractsTest >> testRewriteMethodsIsMethodScopedCommandTool [

	self assert: MCPToolRewriteMethods superclass equals: MCPTool.
	self assert: (MCPToolRewriteMethods traits includes: TMCPMethodTool)
]

{ #category : 'tests' }
MCPToolContractsTest >> testRpcToolCallCatchesUnhandledHaltFromTool [

	| mcp result text tool |
	tool := MCPHaltingTestTool new.
	mcp := self mcpWithoutObservabilityExport.
	mcp addTool: tool.
	result := mcp rpcToolCall: tool name withParams: Dictionary new.
	text := self firstTextFromToolResult: result.
	self assert: (result at: #isError).
	self assert: (text includesSubstring: 'Tool halting-test-tool failed (Halt)').
	self assert: (text includesSubstring: 'mcp tool halt test')
]

{ #category : 'tests - validation' }
MCPToolContractsTest >> testRpcToolCallRefusesAMissingRequiredArgument [

	self
		assertResult: (self callDiscoveredToolNamed: 'evaluate' withArguments: Dictionary new)
		refusesArgumentsSaying: 'code is required.'
]

{ #category : 'tests - validation' }
MCPToolContractsTest >> testRpcToolCallRefusesAWrongArgumentType [

	self
		assertResult: (self callToolNamed: 'package_search' withArguments: { (#offset -> 'ten') } asDictionary)
		refusesArgumentsSaying: 'offset must be integer, not string.'
]

{ #category : 'tests - validation' }
MCPToolContractsTest >> testRpcToolCallRefusesAnInvalidNestedArrayItem [

	self
		assertResult:
		(self callToolNamed: 'test_run' withArguments: { (#methods -> { { (#selector -> 'testPasses') } asDictionary }) } asDictionary)
		refusesArgumentsSaying: 'methods[0] must be string, not object.'
]

{ #category : 'tests - validation' }
MCPToolContractsTest >> testRpcToolCallRefusesAnUnexpectedArgument [

	self
		assertResult: (self callDiscoveredToolNamed: 'evaluate' withArguments: {
					 (#code -> '1 + 1').
					 (#unexpected -> true) } asDictionary)
		refusesArgumentsSaying: 'unexpected is not accepted here; expected one of '
]

{ #category : 'tests' }
MCPToolContractsTest >> testRpcToolCallRejectsLegacyScopeArgument [

	self
		assertResult: (self callToolNamed: 'class_search' withArguments: { (#scope -> 'packages') } asDictionary)
		refusesArgumentsSaying: 'scope must be object, not string.'
]

{ #category : 'tests' }
MCPToolContractsTest >> testRunTestCoverageParsesCompactSelections [

	| command request tool |
	tool := MCPToolRunTestCoverage new.
	request := tool requestFromToolCallArguments: {
			           (#classes -> #( 'MCPToolContractsTest' )).
			           (#coverage -> { (#scope -> { (#classes -> #( 'MCPToolContractsTest' )) } asDictionary) } asDictionary) }
			           asDictionary.
	command := tool operationFor: request.
	command validateSelections.
	self assert: command coverageScope class equals: MCPCompiledMethodScopeQuery.
	self assert: command selections first class equals: MCPTestSelectionSpec.
	self assert: command selections first testClass equals: MCPToolContractsTest
]

{ #category : 'tests' }
MCPToolContractsTest >> testRunTestToolsHaveAccurateNamesAndRequiredArguments [

	| coverageInputProperties coverageInputProperty coverageTool inputPropertyNames timeoutDescription tool |
	tool := MCPToolRunTests new.
	self assert: tool name equals: 'test_run'.
	self assert: (tool inputSchema required ifNil: [ #(  ) ]) isEmpty.
	inputPropertyNames := tool inputSchema properties collect: [ :each | each name ].
	self assert: inputPropertyNames asSet equals: #( 'packages' 'classes' 'methods' 'timeoutSeconds' ) asSet.
	self deny: (inputPropertyNames includes: 'tests').
	self deny: (inputPropertyNames includes: 'timeoutMilliseconds').
	self deny: (inputPropertyNames includes: 'coverage').

	coverageTool := MCPToolRunTestCoverage new.
	self assert: coverageTool name equals: 'test_coverage_run'.
	self assert: coverageTool inputSchema required asSet equals: #( 'coverage' ) asSet.
	inputPropertyNames := coverageTool inputSchema properties collect: [ :each | each name ].
	self assert: inputPropertyNames asSet equals: #( 'packages' 'classes' 'methods' 'coverage' 'timeoutSeconds' ) asSet.
	self deny: (inputPropertyNames includes: 'tests').
	self deny: (inputPropertyNames includes: 'timeoutMilliseconds').
	coverageInputProperty := coverageTool inputSchema properties detect: [ :each | each name = 'coverage' ].
	coverageInputProperties := coverageInputProperty asJRPCJSON at: #properties.
	self assert: coverageInputProperties keys asSet equals: #( 'scope' 'includeCoveredMethods' 'methodLimit' ) asSet.

	timeoutDescription := [ :aTool |
	                      (aTool inputSchema properties detect: [ :each | each name = 'timeoutSeconds' ]) asJRPCJSON at: #description ].
	self assert: (timeoutDescription value: coverageTool) equals: (timeoutDescription value: tool).
	self deny: (coverageTool description includesSubstring: 'per-package')
]

{ #category : 'tests' }
MCPToolContractsTest >> testRunTestsKeepsPackagesAsPackageSelections [

	| command request selections testCases tool |
	tool := MCPToolRunTests new.
	request := tool requestFromToolCallArguments: { (#packages -> #( 'MCP-Tests' )) } asDictionary.
	command := tool operationFor: request.
	selections := command selections.
	self assert: selections size equals: 1.
	self assert: selections first isPackageSelection.
	self assert: selections first packageName equals: 'MCP-Tests'.
	self assert: selections first displayName equals: 'MCP-Tests'.
	self assert: selections first className equals: nil.
	self assert: selections first testMethodName equals: nil.
	command validateSelections.
	testCases := command testCasesFor: selections first.
	self assert: testCases isNotEmpty.
	self assert: (testCases noneSatisfy: [ :each | each class isAbstract ])
]

{ #category : 'tests' }
MCPToolContractsTest >> testRunTestsParsesCompactSelections [

	| command fixtureClassName request selections testMethodReference tool |
	tool := MCPToolRunTests new.
	fixtureClassName := MCPToolStructuredOutputTestTarget name asString.
	testMethodReference := self testReferenceForMethod: MCPToolStructuredOutputTestTarget >> #testPasses.
	request := tool requestFromToolCallArguments: {
			           (#classes -> { MCPToolContractsTest name asString }).
			           (#methods -> { testMethodReference }) } asDictionary.
	command := tool operationFor: request.
	command validateSelections.
	selections := command selections.
	self assert: selections size equals: 2.
	self assert: selections first className equals: MCPToolContractsTest name asString.
	self assert: selections first testMethodName equals: nil.
	self assert: selections second className equals: fixtureClassName.
	self assert: selections second testMethodName equals: #testPasses asString.
	self assert: selections second displayName equals: testMethodReference.
	self assert: selections first testClass equals: MCPToolContractsTest
]

{ #category : 'tests' }
MCPToolContractsTest >> testRunTestsParsesTimeoutSeconds [

	| request tool |
	tool := MCPToolRunTests new.
	request := tool requestFromToolCallArguments: {
			           (#classes -> #( 'MCPToolContractsTest' )).
			           (#timeoutSeconds -> 2) } asDictionary.
	self assert: (tool operationFor: request) timeoutMilliseconds equals: 2000
]

{ #category : 'tests' }
MCPToolContractsTest >> testRunTestsRejectsEmptySelection [

	| request tool |
	tool := MCPToolRunTests new.
	request := tool requestFromToolCallArguments: Dictionary new.
	self
		should: [ tool checkArguments: request ]
		raise: MCPInvalidToolInput
		whoseDescriptionIncludes: 'Name at least one package, class or method to run.'
		description: 'test_run requires at least one compact selection.'
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchClassesHasAccurateNameAndSchema [

	| propertyNames schema scopeProperty scopePropertyNames |
	schema := MCPToolSearchClasses new inputSchema.
	propertyNames := schema properties collect: [ :each | each name ].
	scopeProperty := schema properties detect: [ :each | each name = 'scope' ].
	scopePropertyNames := (scopeProperty extraProperties at: #properties) collect: [ :each | each name ].
	self assert: MCPToolSearchClasses new name equals: 'class_search'.
	self assert: schema required equals: #(  ).
	self assert: propertyNames asSet equals: #( 'scope' 'name' 'package' 'tag' 'offset' ) asSet.
	self assert: scopePropertyNames asSet equals: #( 'classes' 'packages' 'superclassesOf' 'subclassesOf' 'hierarchyOf' ) asSet
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchClassesListsClassesForExistingPackage [

	| classNames classes data result |
	result := self callToolNamed: 'class_search' withArguments: {
			          (self searchScope: { (#packages -> #( 'MCP-Tests' )) }) } asDictionary.
	data := (result at: #structuredContent) at: #data.
	classes := data at: #classes.
	classNames := classes collect: [ :each | each at: #class ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: classes isNotEmpty.
	self assert: (classNames includes: 'MCPToolMethodMutationTest')
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchClassesReturnsWarningResultForMissingPackage [

	| data result warnings |
	result := self
		          callToolNamed: 'class_search'
		          withArguments: { (self searchScope: { (#packages -> #( 'MCP-Definitely-Missing' )) }) } asDictionary.
	data := self dataFrom: result.
	warnings := self warningsFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny: (self resultIndicatesError: result).
	self assert: (data at: #classes) isEmpty.
	self assert: warnings size equals: 1.
	self assert: (warnings first includesSubstring: 'MCP-Definitely-Missing').
	self assert: (warnings first includesSubstring: 'does not exist, so ').
	self assert: (warnings first includesSubstring: 'Did you mean:')
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchPackagesHasAccurateNameAndSchema [

	| propertyNames schema |
	schema := MCPToolSearchPackages new inputSchema.
	propertyNames := schema properties collect: [ :each | each name ].
	self assert: MCPToolSearchPackages new name equals: 'package_search'.
	self assert: schema required equals: #(  ).
	self
		assert: propertyNames asSet
		equals: #( 'projects' 'packages' 'name' 'project' 'tag' 'offset' ) asSet
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchPackagesListsPackagesForExistingProject [

	| entries packageNames |
	entries := self packageSearchFixtureEntriesLoadedInImage: false.
	packageNames := entries collect: [ :each | each at: #package ].
	self assert: entries isNotEmpty.
	self assert: packageNames equals: self packageSearchFixturePackageNames.
	self assert: (entries allSatisfy: [ :each | (each at: #projects) = { self packageSearchFixtureProjectName } ])
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchPackagesReturnsErrorResultForMissingProject [

	| result text |
	result := self callToolNamed: 'package_search' withArguments: { (#projects -> #( 'DefinitelyMissingProject' )) } asDictionary.
	text := self firstTextFromToolResult: result.
	self assert: (result at: #isError).
	self assert: (text includesSubstring: 'Project DefinitelyMissingProject does not exist.').
	self deny: (text includesSubstring: 'Tool package_search failed')
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchRepositoriesHasAccurateNameAndSchema [

	| propertyNames schema |
	schema := MCPToolSearchRepositories new inputSchema.
	propertyNames := schema properties collect: [ :each | each name ].
	self assert: MCPToolSearchRepositories new name equals: 'repository_search'.
	self assert: schema required equals: #(  ).
	self
		assert: propertyNames asSet
		equals:
			#( 'isModified' 'isMissing' 'name' 'location' 'subdirectory' 'package' 'class' 'modifiedPackage'
			   'offset' ) asSet
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchToolPaginationSchemasAdvertiseBounds [
	"No search takes a limit any more; each answers a page of its own size, and a caller sets where it starts."

	MCPToolSearch concreteSubclasses do: [ :toolClass |
			| offsetProperty propertyNames tool |
			tool := toolClass new.
			propertyNames := tool inputSchema properties collect: [ :each | each name ] as: Set.
			offsetProperty := self inputPropertyNamed: 'offset' inTool: tool.
			self deny: (propertyNames includes: 'limit').
			self assert: (offsetProperty extraProperties at: #minimum) equals: 0.
			self deny: (offsetProperty extraProperties includesKey: #maximum).
			self assert: (offsetProperty extraProperties at: #default) equals: 0.
			self assert: tool defaultPageLimit > 0 ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchToolSchemasAdvertiseGroupedScopeProperties [

	| oldScopePropertyNames searchTools scopePropertyNames |
	oldScopePropertyNames := #( 'packages' 'classes' 'hierarchyClasses' 'subclassClasses' 'parentClasses' ).
	searchTools := {
		               MCPToolSearchClasses new.
		               MCPToolSearchMethods new.
		               MCPToolSearchMethodSource new.
		               MCPToolSearchMethodReferences new.
		               MCPToolSearchEquivalentMethods new }.
	searchTools do: [ :tool |
			| propertyNames scopeProperty |
			propertyNames := tool inputSchema properties collect: [ :each | each name ].
			scopeProperty := self inputPropertyNamed: 'scope' inTool: tool.
			scopePropertyNames := (scopeProperty extraProperties at: #properties) collect: [ :each | each name ].
			self assert: (propertyNames includes: 'scope').
			oldScopePropertyNames do: [ :each | self deny: (propertyNames includes: each) ].
			self
				assert: scopePropertyNames asSet
				equals: #( 'classes' 'packages' 'superclassesOf' 'subclassesOf' 'hierarchyOf' ) asSet , (tool class = MCPToolSearchClasses
						 ifTrue: [ Set new ]
						 ifFalse: [ #( 'side' ) asSet ]) ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchToolsAnswerEntriesAsLines [
	"A search answers rows under the name of the list they belong to, each naming its method the way Pharo does; the pagination block repeats what the summary already says in prose."

	| lines text |
	text := self firstTextFromToolResult: (self
			         callToolNamed: 'method_search'
			         withArguments: { (#scope -> { (#classes -> { 'MCPSelectorSuggestion' }) } asDictionary) } asDictionary).
	lines := text lines.
	self assert: (lines first includesSubstring: 'methods').
	self assert: ((lines second beginsWith: 'methods') and: [ lines second endsWith: ':' ]).
	self assert: ((lines allButFirst: 2) allSatisfy: [ :each | each includesSubstring: 'MCPSelectorSuggestion class>>' ]).
	self deny: (text includesSubstring: 'selector=').
	self deny: (text includesSubstring: 'pagination')
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchToolsAnswerPlainTextContent [
	"A catalog listing is read as prose, so the text block carries one line per tool instead of the canonical JSON. class_update is not advertised, which its line says."

	| lines result text |
	result := self callToolNamed: 'tool_search' withArguments: { (#query -> 'class slots') } asDictionary.
	text := self firstTextFromToolResult: result.
	lines := text lines.
	self assert: lines first equals: (self summaryFrom: result).
	self assert: (lines anySatisfy: [ :each | each beginsWith: 'class_update (not in the advertised list) - ' ]).
	self deny: (text includesSubstring: '"tools"')
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchToolsAnswersBestMatchesWhenNoToolMatchesEveryWord [
	"A query word boosts a tool, it never gates it out: this query used to answer nothing because no tool matches all four words."

	| names |
	names := self searchedToolNamesFor: 'class update modify slots'.
	self assert: names first equals: 'class_update'.
	self assert: (names includes: 'class_create')
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchToolsAnswersCatalogOverviewWhenNothingMatches [
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
MCPToolContractsTest >> testSearchToolsAnswersCatalogOverviewWithoutQuery [

	| result summary |
	result := self callToolNamed: 'tool_search' withArguments: Dictionary new.
	summary := self summaryFrom: result.
	self assert: ((self dataFrom: result) at: #tools) isEmpty.
	self assert: (summary includesSubstring: self toolRegistry tools size asString , ' tools in ').
	self assert: (summary includesSubstring: 'classes ')
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchToolsCapsResultsAtResultLimit [

	| result tools |
	result := self callToolNamed: 'tool_search' withArguments: { (#query -> 'class method repository') } asDictionary.
	tools := (self dataFrom: result) at: #tools.
	self assert: tools size equals: MCPToolSearchTools new resultLimit.
	self assert: ((self summaryFrom: result) includesSubstring: 'matching tools, best first')
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchToolsIncludesStaticSurface [

	| metadataByName result advertisedTool |
	result := self callToolNamed: 'tool_search' withArguments: { (#query -> 'classes') } asDictionary.
	metadataByName := (((self dataFrom: result) at: #tools) collect: [ :each | (each at: #name) -> each ]) asDictionary.
	self assert: (metadataByName includesKey: 'class_search').
	advertisedTool := self toolRegistry toolNamed: 'class_search' ifAbsent: [ self fail: 'Missing class_search tool' ].
	self assert: advertisedTool defaultExposure equals: 'static'
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchToolsKeywordsAreSingleSearchTerms [

	| evaluateTool searchTool |
	searchTool := MCPToolSearchTools new.
	evaluateTool := MCPToolEvaluate new.
	self assert: searchTool keywords asSet equals: #( 'tool' 'catalog' 'search' ) asSet.
	self assert: evaluateTool keywords asSet equals: #( 'image' 'evaluate' 'runtime' 'expression' 'smalltalk' 'code' ) asSet
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchToolsLetDescriptionsRefineRankingWithoutAdmittingTools [
	"'the' appears in most descriptions, so a word found only there must not turn a tool into a result, but it still ranks a tool that already matches."

	self assert: (self searchedToolNamesFor: 'frobnicate the widget') isEmpty.
	self assert: (self searchedToolNamesFor: 'rename a method everywhere') first equals: 'method_update'
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchToolsMatchesAgentGuidanceKeywords [

	| expectations |
	expectations := {
		                ('repo' -> 'repository_search').
		                ('identity' -> 'repository_identity_verify').
		                ('diff' -> 'repository_change_list').
		                ('stale' -> 'repository_reload').
		                ('SUnit' -> 'test_run').
		                ('coverage' -> 'test_coverage_run').
		                ('file' -> 'history_file_list').
		                ('entry' -> 'history_entry_list').
		                ('recover' -> 'history_entry_apply').
		                ('window' -> 'screen_capture').
		                ('display' -> 'screen_capture').
		                ('watch' -> 'debug_watch').
		                ('debugger' -> 'debug_search').
		                ('refactor' -> 'class_update').
		                ('refactoring' -> 'method_update') }.
	expectations do: [ :expectation |
			| names |
			names := (self toolRegistry toolsMatchingQuery: expectation key) collect: [ :each | each name ].
			self assert: (names includes: expectation value) ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchToolsMatchesPluralQueryTerms [

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
MCPToolContractsTest >> testSearchToolsMatchesSpecializedClassKeywords [
	"class_update answers for every part of a class definition, so the words that used to lead to a tool each must still lead to it."

	#( 'trait composition' 'metaclass trait' 'classvar' 'pooldictionary' 'weak layout' 'rename class' 'recategorize' ) do: [ :query |
		self assert: ((self searchedToolNamesFor: query) includes: 'class_update') ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchToolsRanksEveryToolFirstForItsOwnName [

	self toolRegistry tools do: [ :tool |
		self assert: (self toolRegistry toolsMatchingQuery: tool name) first name equals: tool name ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchToolsRanksMoreMatchedWordsFirst [

	self assert: (self searchedToolNamesFor: 'method source') first equals: 'method_source_search'.
	self assert: (self searchedToolNamesFor: 'method equivalent') first equals: 'method_equivalent_search'.
	self assert: (self searchedToolNamesFor: 'repository reload') first equals: 'repository_reload'
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchToolsReturnsDiscoverableMetadata [

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
	self assert: createRepositoryMetadata keys asSet equals: #( name description exposure ) asSet.
	self assert: (createRepositoryMetadata at: #exposure) equals: 'discoverable'
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchToolsUsesQueryOnlyContract [

	| propertyNames |
	propertyNames := MCPToolSearchTools new inputSchema properties collect: [ :each | each name ].
	self assert: propertyNames asArray equals: #( 'query' )
]

{ #category : 'tests' }
MCPToolContractsTest >> testSelectorSuggestionsPreferASharedPrefixOverACorrection [
	"A wrong guess usually keeps the prefix of the right selector, which no spelling distance recovers."

	self
		assert: (MCPSelectorSuggestion selectorsLike: #errorStackTraceForContextNamed: understoodBy: MCPTool) first
		equals: 'errorStackTraceForContext:'.
	self assert: (MCPSelectorSuggestion selectorsLike: #zzzzUnrelatedSelector understoodBy: MCPTool) isEmpty
]

{ #category : 'tests' }
MCPToolContractsTest >> testServerAdvertisingReadsTheRegistry [

	| server |
	server := self mcpWithoutObservabilityExport.
	self assert: server advertisedToolNames equals: server toolRegistry advertisedToolNames
]

{ #category : 'tests' }
MCPToolContractsTest >> testServerCanConfigureAdvertisedTools [

	| server toolNames |
	server := self mcpWithoutObservabilityExport.
	server advertiseTools: #( 'tool_search' 'tool_get' 'tool_call' 'class_search' ).
	toolNames := (server rpcToolsList at: #tools) collect: [ :each | each at: #name ].
	self assert: toolNames asSet equals: #( 'tool_search' 'tool_get' 'tool_call' 'class_search' ) asSet.
	self deny: (toolNames includes: 'class_name_update')
]

{ #category : 'tests' }
MCPToolContractsTest >> testServerInitializationLeavesIconCacheEmpty [

	MCPStructureIcon resetCaches.
	self mcpWithoutObservabilityExport.
	self assert: MCPStructureIcon cachedRenderedIconCount equals: 0
]

{ #category : 'tests' }
MCPToolContractsTest >> testServerWithNoToolsRegistersNone [

	| server |
	server := MCP onlyTools: #(  ).
	self assert: server toolRegistry toolNames isEmpty.
	self assert: server advertisedToolNames isEmpty.
	self assert: (server rpcToolsList at: #tools) isEmpty
]

{ #category : 'tests' }
MCPToolContractsTest >> testSingularSearchTermsUseGenericInflectionRules [

	| registry |
	registry := MCPToolRegistry new.
	self assert: (registry singularSearchTermFor: 'classes') equals: 'class'.
	self assert: (registry singularSearchTermFor: 'repositories') equals: 'repository'.
	self assert: (registry singularSearchTermFor: 'histories') equals: 'history'
]

{ #category : 'tests' }
MCPToolContractsTest >> testSpecializedClassAndMethodToolsAreDiscoverableOnly [

	| discoverableOnlyNames |
	discoverableOnlyNames := #( 'class_update' 'method_equivalent_search' 'test_coverage_run' ).
	discoverableOnlyNames do: [ :each |
			| tool |
			self assert: (self toolRegistry toolNames includes: each).
			self deny: (self toolRegistry advertisedToolNames includes: each).
			tool := self toolRegistry toolNamed: each ifAbsent: [ self fail: 'Missing tool ' , each ].
			self assert: tool defaultExposure equals: 'discoverable'.
			self assert: tool searchMetadata keys asSet equals: #( name description ) asSet ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testStringArrayItemDescriptionsStayUseful [

	| compactProperty usefulProperty |
	compactProperty := MCPToolSearchClasses new
		                   stringArraySchemaNamed: 'packages'
		                   description: 'Packages to search.'
		                   itemDescription: 'Package name.'.
	self deny: ((compactProperty asJRPCJSON at: #items) includesKey: #description).
	usefulProperty := self inputPropertyNamed: 'argumentValueExpressions' inTool: MCPToolUpdateMethod new.
	self assert: ((usefulProperty asJRPCJSON at: #items) at: #description) equals: 'Smalltalk expression.'
]

{ #category : 'tests' }
MCPToolContractsTest >> testTheServerDoesNotReachIntoTheImageTools [
	"MCP has to load without MCP-IDE, which is the whole point of the split: a project that wants the server and its own tools should not drag in the image tools it will never call. One reference from here to there, and a core-only load breaks. Its extensions to other projects' classes count too, which is where such a reference would hide."

	| imageTools offenders check |
	imageTools := 'MCP-IDE' asPackage definedClasses collect: [ :each | each instanceSide ] as: Set.
	offenders := OrderedCollection new.
	check := [ :method |
		         method literals do: [ :literal |
				         (literal isVariableBinding and: [ literal value isBehavior and: [ imageTools includes: literal value instanceSide ] ])
					         ifTrue: [
							         offenders add: (String streamContents: [ :stream |
									          stream << method methodClass name << '>>' << method selector << ' names ' << literal value name ]) ] ] ].
	'MCP' asPackage definedClasses do: [ :each |
			(each superclass ifNil: [ false ] ifNotNil: [ :superclass | imageTools includes: superclass instanceSide ]) ifTrue: [
				offenders add: (String streamContents: [ :stream | stream << each name << ' inherits from ' << each superclass name ]) ].
			{
				each.
				each class } do: [ :side | side methods do: [ :method | check value: method ] ] ].
	'MCP' asPackage extensionMethods do: [ :method | check value: method ].
	self assertEmpty: offenders
]

{ #category : 'tests' }
MCPToolContractsTest >> testToolAnnotationsSerializeStandardHints [

	| annotations |
	annotations := MCPStructureToolAnnotations new
		               title: 'Safe Update';
		               readOnlyHint: false;
		               destructiveHint: false;
		               idempotentHint: true;
		               openWorldHint: false;
		               yourself.
	self assert: annotations asJRPCJSON equals: {
			(#title -> 'Safe Update').
			(#destructiveHint -> false).
			(#idempotentHint -> true).
			(#openWorldHint -> false) } asDictionary
]

{ #category : 'tests' }
MCPToolContractsTest >> testToolCallsResumeNotificationsWithoutAToolOfTheirOwn [
	"Every Warning and Notification is an Exception, so the shared boundary resumes them for every tool instead of each tool needing a handler."

	| result server structured |
	server := MCP new.
	server advertiseAllTools.
	server useContentAndStructuredContentToolResponses.
	server addTool: MCPNotifyingTestTool.
	result := server rpcToolCall: MCPNotifyingTestTool toolName withParams: Dictionary new.
	structured := result at: #structuredContent.
	self deny: (result includesKey: #isError).
	self assert: ((structured at: #data) at: #resumedWith) equals: 'nested-mcpDefaultAction'
]

{ #category : 'tests' }
MCPToolContractsTest >> testToolGetTextCarriesOnlyWhatACallNeeds [
	"A contract is read to build a call. Its annotations, exposure, group and keywords stay in the data for whoever catalogs tools, and the text leaves them out; whether the tool is advertised is said once, in the summary."

	| contract lines result |
	result := self callToolNamed: 'tool_get' withArguments: { (#name -> 'repository_create') } asDictionary.
	lines := (self firstTextFromToolResult: result) lines.
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
	lines := (self firstTextFromToolResult: result) lines.
	self assert: lines first equals: 'Tool class_search.'.
	self assert: (lines includes: '  pageSize: ' , MCPToolSearchClasses new defaultPageLimit printString)
]

{ #category : 'tests' }
MCPToolContractsTest >> testToolIconSpecsAreDerivedFromToolNames [
	"Among MCP's own tools, an icon is read from the name and never picked by hand, so they stay consistent without anyone choosing. A tool from another package cannot be spelled out of MCP's vocabulary, so it is left to declare its own."

	| builtIn |
	builtIn := MCPTool withAllSubclasses select: [ :each | each isBuiltIn ].
	self assert: (builtIn count: [ :each | each class includesSelector: #toolIconSpec ]) equals: 1.
	self assert: (MCPTool class includesSelector: #toolIconSpec)
]

{ #category : 'tests' }
MCPToolContractsTest >> testToolIconsAreSharedByToolClass [

	| firstIcons secondIcons |
	MCPStructureIcon resetCaches.
	firstIcons := MCPToolSearchClasses new icons.
	secondIcons := MCPToolSearchClasses new icons.
	self assert: firstIcons identicalTo: secondIcons.
	self assert: firstIcons first identicalTo: secondIcons first.
	self assert: MCPStructureIcon cachedRenderedIconCount equals: 1
]

{ #category : 'tests' }
MCPToolContractsTest >> testToolNamesFollowPublicNamingConvention [

	| names |
	names := self builtInToolClasses collect: [ :toolClass | toolClass new name ].
	self assert: names asSet size equals: names size.
	names do: [ :name |
			| segments |
			self assert: name first isLetter.
			self assert: name equals: name asLowercase.
			segments := name splitOn: $_.
			self assert:
				(segments allSatisfy: [ :segment | segment isNotEmpty and: [ segment allSatisfy: [ :character | character isAlphaNumeric ] ] ]) ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testToolRegistryAcceptsAPluginTool [

	| added registry tool |
	registry := MCPToolRegistry new.
	added := registry addTool: MCPHaltingTestTool.
	tool := registry toolNamed: MCPHaltingTestTool toolName ifAbsent: [ self fail ].
	self assert: tool == added.
	self deny: (registry isToolAdvertisedNamed: tool name).
	self assert: ((registry toolGroups detect: [ :each | each key = tool groupName ] ifNone: [ self fail ]) value includes:
			 MCPHaltingTestTool)
]

{ #category : 'tests' }
MCPToolContractsTest >> testToolRegistryNamesUseClassSideMetadata [

	| names registry |
	registry := self toolRegistry.
	names := registry toolClasses collect: [ :each | each toolName ].
	self assert: registry toolNames equals: names.
	self assert: MCPToolSearchClasses toolName equals: 'class_search'.
	self assert: MCPToolCreateClass toolName equals: 'class_create'.
	self assert: MCPToolUpdateClass toolName equals: 'class_update'.
	self assert: MCPToolRunTests toolName equals: 'test_run'.
	self assert: MCPToolCompileMethod toolName equals: 'method_compile'.
	self assert: MCPToolUpdateMethod toolName equals: 'method_update'.
	self assert: MCPToolVerifyRepositoryIdentity toolName equals: 'repository_identity_verify'.
	self assert: MCPToolListRepositoryChanges toolName equals: 'repository_change_list'.
	self assert: MCPToolCreateRepository toolName equals: 'repository_create'.
	self assert: MCPToolAttachRepository toolName equals: 'repository_attach'.
	self assert: MCPToolUpdateRepository toolName equals: 'repository_update'.
	self assert: MCPToolExportRepository toolName equals: 'repository_export'.
	self assert: MCPToolCommitRepository toolName equals: 'repository_commit'.
	self assert: MCPToolReloadRepository toolName equals: 'repository_reload'.
	self assert: MCPToolAdoptRepositoryHead toolName equals: 'repository_head_adopt'.
	self assert: MCPToolListChangeHistoryFiles toolName equals: 'history_file_list'.
	self assert: MCPToolListChangeHistoryEntries toolName equals: 'history_entry_list'.
	self assert: MCPToolApplyChangeHistoryEntries toolName equals: 'history_entry_apply'.
	self assert: MCPToolRevertChangeHistoryEntries toolName equals: 'history_entry_revert'.
	self assert: MCPToolDebugSearch toolName equals: 'debug_search'.
	self assert: MCPToolDebugWatch toolName equals: 'debug_watch'
]

{ #category : 'tests' }
MCPToolContractsTest >> testToolRegistryRegistrationIsInstanceScoped [

	| firstRegistry secondRegistry |
	firstRegistry := MCPToolRegistry new.
	secondRegistry := MCPToolRegistry new.
	firstRegistry addTool: MCPHaltingTestTool.
	self assert: (firstRegistry includesToolNamed: MCPHaltingTestTool toolName).
	self deny: (secondRegistry includesToolNamed: MCPHaltingTestTool toolName)
]

{ #category : 'tests' }
MCPToolContractsTest >> testToolRegistryReusesRegisteredToolInstances [

	| first registry searchResults second |
	registry := MCPToolRegistry default.
	first := registry toolNamed: 'tool_search' ifAbsent: [ self fail ].
	second := registry toolNamed: 'tool_search' ifAbsent: [ self fail ].
	searchResults := registry toolsMatchingQuery: 'tool'.
	self assert: first == second.
	self assert: (searchResults detect: [ :each | each name = 'tool_search' ]) == first
]

{ #category : 'tests' }
MCPToolContractsTest >> testToolRegistryUsesDefaultExposureUntilStaticListProvided [

	| registry |
	registry := MCPToolRegistry default.
	self assert: (registry isToolAdvertisedNamed: 'tool_search').
	self deny: (registry isToolAdvertisedNamed: 'repository_search').
	registry advertiseTools: #( 'repository_search' ).
	self deny: (registry isToolAdvertisedNamed: 'tool_search').
	self assert: (registry isToolAdvertisedNamed: 'repository_search')
]

{ #category : 'tests' }
MCPToolContractsTest >> testToolResponsesCanReturnContentAndStructuredContent [

	| result server text |
	server := MCP new.
	server useContentAndStructuredContentToolResponses.
	result := server rpcToolCall: 'tool_search' withParams: { (#query -> 'classes') } asDictionary.
	text := self firstTextFromToolResult: result.
	self assert: (result includesKey: #content).
	self assert: (result includesKey: #structuredContent).
	self deny: (self resultIndicatesError: result).
	self assert: text lines first equals: ((result at: #structuredContent) at: #summary)
]

{ #category : 'tests' }
MCPToolContractsTest >> testToolResponsesCanReturnStructuredContentOnly [

	| result server |
	server := MCP new.
	server useStructuredContentOnlyToolResponses.
	result := server rpcToolCall: 'tool_search' withParams: { (#query -> 'classes') } asDictionary.
	self deny: (result includesKey: #content).
	self assert: (result includesKey: #structuredContent).
	self deny: (self resultIndicatesError: result).
	self assert: (((result at: #structuredContent) at: #data) includesKey: #tools)
]

{ #category : 'tests' }
MCPToolContractsTest >> testToolResponsesDefaultToContentOnly [

	| result text |
	result := MCP new rpcToolCall: 'tool_search' withParams: { (#query -> 'classes') } asDictionary.
	text := self firstTextFromToolResult: result.
	self assert: (result includesKey: #content).
	self deny: (result includesKey: #structuredContent).
	self assert: (text includesSubstring: 'class_search - ')
]

{ #category : 'tests' }
MCPToolContractsTest >> testToolSearchCountsOneToolInTheSingular [

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
MCPToolContractsTest >> testToolSearchMarksToolsNotAdvertised [
	"A client that calls only the tools it lists cannot call the others by their bare name, so their lines say they are not listed. Every client can reach them some way, so nothing says tool_call is the only one."

	| lines result server summary text |
	server := self mcpWithoutObservabilityExport.
	server advertiseTools: #( 'tool_search' 'tool_get' 'tool_call' 'repository_search' ).
	result := server rpcToolCall: 'tool_search' withParams: { (#query -> 'repository') } asDictionary.
	text := self firstTextFromToolResult: result.
	lines := text lines.
	summary := self summaryFrom: result.
	self assert: lines first equals: summary.
	self assert:
		(summary endsWith: ' Tools not in your list can be called by name, or through tool_call if your client only calls listed tools.').
	self assert: (lines anySatisfy: [ :each | each beginsWith: 'repository_search - ' ]).
	self assert: (lines anySatisfy: [ :each | each beginsWith: 'repository_create (not in the advertised list) - ' ]).
	self deny: (text includesSubstring: '(through tool_call)').
	self
		assert: ((((self dataFrom: result) at: #tools) detect: [ :each | (each at: #name) = 'repository_create' ]) at: #exposure)
		equals: 'discoverable'.
	server advertiseAllTools.
	result := server rpcToolCall: 'tool_search' withParams: { (#query -> 'repository') } asDictionary.
	text := self firstTextFromToolResult: result.
	self deny: (text includesSubstring: 'not in the advertised list').
	self deny: (text includesSubstring: 'Tools not in your list')
]

{ #category : 'tests' }
MCPToolContractsTest >> testToolsDoNotResumeRefactoringWarnings [
	"A refactoring warning reports a change that breaks something: resuming it at the boundary would apply a mutation that force did not authorize."

	self deny: (MCPToolRemoveClasses new shouldResumeNotification: RBRefactoringWarning new).
	self assert: (MCPToolEvaluate new shouldResumeNotification: MCPToolNestedNotification new)
]

{ #category : 'tests' }
MCPToolContractsTest >> testToolsOwnRegistryMetadata [

	| tool |
	tool := MCPToolEvaluate new.
	self assert: tool groupName equals: 'runtime'.
	self assert: tool defaultExposure equals: 'static'.
	self assert: tool annotations readOnlyHint equals: nil.
	self assert: (tool keywords includes: 'smalltalk')
]

{ #category : 'tests' }
MCPToolContractsTest >> testUnknownToolNameSuggestsCloseNames [

	| error result |
	result := self callToolNamed: 'tool_call' withArguments: { (#name -> 'method_serch') } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorCode) equals: 'ToolNotFound'.
	self assert: (error at: #tool) equals: 'method_serch'.
	self assert: ((error at: #suggestedTools) includes: 'method_source_search').
	self deny: (error includesKey: #stackTrace)
]

{ #category : 'private - evaluate' }
MCPToolContractsTest >> textOfEvaluateResult: aResult [
	"The text a call gets for an evaluation that failed."

	^ aResult content first text
]

{ #category : 'private - evaluate' }
MCPToolContractsTest >> underEitherPreemptionRuleDo: aBlock [
	"Whether a preempted process goes to the back of its run queue is a setting of the virtual machine, which an image keeps from whoever built it. It reaches the image file only on a save, which no test makes."

	| original |
	original := Smalltalk vm processPreemptionYields.
	[
		#( true false ) do: [ :yields |
				Smalltalk vm processPreemptionYields: yields.
				aBlock value: yields ] ] ensure: [ Smalltalk vm processPreemptionYields: original ]
]

{ #category : 'private' }
MCPToolContractsTest >> unimplementedResponsibilitiesForConcreteMCPClasses [

	| classes issues |
	classes := (MCPTool builtInPackageNames flatCollect: [ :name | (self packageOrganizer packageNamed: name) definedClasses ])
		           reject: [ :each | each isTrait ].
	issues := OrderedCollection new.
	classes do: [ :class |
			class isAbstract ifFalse: [
					self
						addUnimplementedResponsibilitiesFor: class
						behavior: class
						side: 'instance'
						to: issues.
					self
						addUnimplementedResponsibilitiesFor: class
						behavior: class class
						side: 'class'
						to: issues ] ].
	^ issues asArray sort
]

{ #category : 'private - evaluate' }
MCPToolContractsTest >> waitUntilEnded: aProcess [
	"Up to 5 s, for what a stopped evaluation left unwinding."

	| deadline |
	deadline := Time millisecondClockValue + 5000.
	[ aProcess isTerminated or: [ Time millisecondClockValue > deadline ] ] whileFalse: [ (Delay forMilliseconds: 50) wait ]
]
