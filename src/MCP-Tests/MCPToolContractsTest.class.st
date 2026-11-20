"
Tests what holds across the tools rather than for one of them: their names, icons, schemas and descriptions, how they are registered and advertised, how their answers read, and the protocol requests the server answers beside the tool calls.
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
MCPToolContractsTest >> addUnimplementedResponsibilitiesOf: aBehavior among: selectors to: issues [

	selectors do: [ :selector |
			(aBehavior lookupSelector: selector) ifNotNil: [ :method |
					(selector ~= #subclassResponsibility and: [ self methodSendsSubclassResponsibility: method ]) ifTrue: [
							issues add: (String streamContents: [ :stream |
										 stream << aBehavior instanceSide name << (aBehavior isMeta
											  ifTrue: [ ' class #' ]
											  ifFalse: [ ' instance #' ]) << selector << ' inherited from ' << method methodClass name ]) ] ] ]
]

{ #category : 'private' }
MCPToolContractsTest >> assertNamesAMissingClassAlike: aCase [
	"aCase is one row of missingClassCases. The whole answer is read for leaks, structured content included, since a client may show either."

	| answer call result text |
	result := self callToolNamed: aCase first withArguments: aCase second asDictionary.
	text := self textFrom: result.
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

{ #category : 'private' }
MCPToolContractsTest >> mcpClassesInPackageTagNamed: aTagName [
	"A tag says what kind of class this is, not which of MCP's packages it lives in, and since the split they live in two."

	^ ((self builtInPackageNames flatCollect: [ :each | (self packageOrganizer packageNamed: each asSymbol) definedClasses ])
		   select: [ :each | each packageTagName asString = aTagName ]) asArray
]

{ #category : 'private' }
MCPToolContractsTest >> mcpMethodsReferringTo: aLiteral [
	"The methods of MCP's loaded packages that hold aLiteral. A method that sends a selector holds it, unless the virtual machine special-cases that selector, so only these need parsing to find the sends."

	^ self mcpPackageNames flatCollect: [ :name |
		  (self packageOrganizer packageNamed: name) methods select: [ :each | each refersToLiteral: aLiteral ] ]
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
		('method_remove' -> { (#selector -> 'probe') }) } do: [ :each |
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
					(#query -> 'Zzqxw').
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

{ #category : 'private' }
MCPToolContractsTest >> scopePropertyNamed: aPropertyName inTool: aTool [

	^ ((self inputPropertyNamed: 'scope' inTool: aTool) extraProperties at: #properties) detect: [ :each |
		  each name = aPropertyName ]
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

	(self class environment at: #Halt) signal: 'mcp processor halt test'
]

{ #category : 'private' }
MCPToolContractsTest >> summaryOfTool: aToolName with: someAssociations [

	| result |
	result := self callToolNamed: aToolName withArguments: someAssociations asDictionary.
	self deny: (self resultIndicatesError: result) description: (self summaryFrom: result).
	^ self summaryFrom: result
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
	MCPToolRegistry default toolGroups do: [ :group |
			group value do: [ :toolClass | self assert: toolClass new groupName equals: group key ].
			groupedToolClasses addAll: group value ].
	autoRegisteredToolClasses := MCPTool concreteSubclasses select: [ :toolClass | toolClass shouldAutoRegister ].
	self assert: groupedToolClasses asSet equals: autoRegisteredToolClasses asSet
]

{ #category : 'tests' }
MCPToolContractsTest >> testBuiltInToolsProvideCatalogMetadata [

	| validExposures |
	validExposures := #( 'static' 'discoverable' ).
	self toolRegistry tools select: [ :tool | self isBuiltIn: tool class ] thenDo: [ :tool |
			self assert: (self builtInGroupNames includes: tool groupName).
			self assert: tool groupName equals: tool class groupName.
			self assert: (validExposures includes: tool defaultExposure).
			self assert: (#( true nil ) includes: tool annotations readOnlyHint).
			self assert: tool keywords isNotEmpty ]
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
	result := server rpcToolCall: 'package_search' withParams: { (#query -> 'MCP') } asDictionary.
	self assert: ((self dataFrom: result) at: #packages) isNotEmpty.
	self should: [ server rpcToolCall: 'no_such_tool' withParams: Dictionary new ] raise: JRPCNonExistentHandler
]

{ #category : 'tests' }
MCPToolContractsTest >> testCountedNounsReadAsEnglish [

	| tool |
	tool := MCPToolGetClass new.
	self assert: (tool textForCount: 1 noun: 'change history entry') equals: '1 change history entry'.
	self assert: (tool textForCount: 2 noun: 'change history entry') equals: '2 change history entries'.
	self assert: (tool textForCount: 2 noun: 'class') equals: '2 classes'.
	self assert: (tool textForCount: 2 noun: 'match') equals: '2 matches'.
	self assert: (tool textForCount: 2 noun: 'method') equals: '2 methods'
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
	"A host may let a model call only the tools its list holds, so a tool the instructions name must be one tools/list shows, or they send the model where it cannot go. The default server gives the Pharo workflow; a server advertising only the catalog tools leaves it out and still says how to reach the rest; one advertising only the workflow's tools gives it and says nothing of the catalog; a server advertising neither has nothing to say, and neither answer carries instructions."

	| catalogOnly withoutCatalog workflowOnly |
	catalogOnly := self mcpWithoutObservabilityExport
		               advertiseTools: #( 'tool_search' 'tool_get' 'tool_call' );
		               yourself.
	workflowOnly := self mcpWithoutObservabilityExport
		                advertiseTools: #( 'class_search' 'method_search' 'method_get' 'method_compile' 'test_run' );
		                yourself.
	withoutCatalog := self mcpWithoutObservabilityExport
		                  advertiseTools: #( 'method_get' );
		                  yourself.
	self assert: (self mcpWithoutObservabilityExport discoveryInstructions includesSubstring: MCP pharoCodeInstructions).
	self deny: (catalogOnly discoveryInstructions includesSubstring: MCP pharoCodeInstructions).
	self assert: (workflowOnly discoveryInstructions includesSubstring: MCP pharoCodeInstructions).
	self assert: withoutCatalog discoveryInstructions isNil.
	self deny: (withoutCatalog rpcServerDiscover includesKey: #instructions).
	self deny: ((withoutCatalog onInitialize: nil) asJRPCJSON includesKey: #instructions).
	{
		self mcpWithoutObservabilityExport.
		catalogOnly.
		workflowOnly } do: [ :server |
			| named |
			named := (server discoveryInstructions substrings: ' ,.;:()') select: [ :each | each includes: $_ ].
			self deny: named isEmpty.
			self assertEmpty: (named reject: [ :each | server advertisedToolNames includes: each ]) ]
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
MCPToolContractsTest >> testEntryFieldQuotingEscapesEmbeddedQuotes [

	| contentText entry |
	entry := Dictionary new
		         at: #label put: 'says "hi" there';
		         at: #name put: 'Plain';
		         yourself.
	contentText := MCPToolGetClass new contentTextForStructuredContent: (Dictionary new
		               at: #summary put: 'Summary.';
		               at: #data put: (Dictionary new
				                at: #entries put: { entry };
				                yourself);
		               yourself).
	self assert: (contentText includesSubstring: 'label="says \"hi\" there"').
	self assert: (contentText includesSubstring: 'name=Plain')
]

{ #category : 'tests' }
MCPToolContractsTest >> testEntryFieldsWithSeparatorsAreQuoted [

	| contentText result |
	result := self callToolNamed: 'method_search' withArguments: {
		          (#protocol -> 'meta filtering').
		          (self searchScope: { (#classes -> #( 'MCPToolMethodSearchTestTarget' )) } side: 'class') } asDictionary.
	contentText := (result at: #content) first at: #text.
	self deny: (self resultIndicatesError: result).
	self assert: (contentText includesSubstring: 'protocol="meta filtering"')
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
MCPToolContractsTest >> testEveryToolTitleReadsItsNameVerbFirstInTitleCase [
	"A client shows the title in place of the name, so the title must lead with the action the name ends on, and read as a title. Another project names its tools its own way."

	| offenders |
	offenders := self toolRegistry tools
		             select: [ :tool |
				             | words |
				             words := tool title substrings.
				             (self isBuiltIn: tool class) and: [
					             words first ~= (tool name substrings: '_') last capitalized or: [
						             words anySatisfy: [ :word | word first isUppercase not ] ] ] ]
		             thenCollect: [ :tool | tool name ].
	self assertEmpty: offenders
]

{ #category : 'tests' }
MCPToolContractsTest >> testExternalToolFixtureIsNotBuiltIn [
	"Two separate facts about the same fixture. It is not built in, so MCP's naming, grouping and icon conventions are not asked of it; and it answers false to discovery, which is its own doing rather than a consequence of the package it sits in."

	self assert: (MCPTool concreteSubclasses includes: MCPExternalTestTool).
	self deny: (self isBuiltIn: MCPExternalTestTool).
	self deny: MCPExternalTestTool shouldAutoRegister.
	self deny: (self builtInToolClasses includes: MCPExternalTestTool).
	self deny: (self builtInGroupNames includes: MCPExternalTestTool groupName)
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
	response := (self mcpWithoutObservabilityExport onInitialize: nil) asJRPCJSON.
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
	response := (self mcpWithoutObservabilityExport onInitialize: nil) asJRPCJSON.
	serverInfo := response at: #serverInfo.
	self assert: (serverInfo includesKey: #icons).
	self deny: (serverInfo at: #icons) isEmpty.
	icon := (serverInfo at: #icons) first.
	self assert: icon equals: expectedIcon
]

{ #category : 'tests' }
MCPToolContractsTest >> testInitializeAdvertisesSupportedPharoVersions [

	| metadata pharo response runtimeVersion serverInfo |
	response := (self mcpWithoutObservabilityExport onInitialize: nil) asJRPCJSON.
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
MCPToolContractsTest >> testLineFeedTextReadsAsABlock [
	"Text the server writes ends its lines with LF, and reads as a block as text ending them with CR does."

	| contentText |
	contentText := MCPToolGetClass new contentTextForStructuredContent: (Dictionary new
			                at: #summary put: 'Summary.';
			                at: #data put: {
					                (#text -> (String lf join: #( 'one' 'two' ))).
					                (#name -> 'Plain') } asDictionary;
			                yourself).
	self assert: contentText lines equals: #( 'Summary.' 'name: Plain' 'text:' 'one' 'two' )
]

{ #category : 'tests' }
MCPToolContractsTest >> testListOfMultiLineValuesReadsOneValueAtATime [
	"A list whose values have lines of their own gives each value its own lines, every one of them indented as an item of the list, so no value runs into the next."

	| lines |
	lines := (String streamContents: [ :stream |
			          MCPToolGetClass new
				          entriesTextOn: stream
				          for: {
						          (String lf join: #( 'first' '   detail' )).
						          'second' }
				          labelled: 'values'
				          indent: '  ' ]) lines.
	self assert: lines equals: #( '' '  values:' '    first' '       detail' '    second' ).
	lines := (String streamContents: [ :stream |
			          MCPToolGetClass new
				          entriesTextOn: stream
				          for: #( 'one' 'two' )
				          labelled: 'values'
				          indent: '' ]) lines.
	self assert: lines equals: #( '' 'values: [one, two]' )
]

{ #category : 'tests' }
MCPToolContractsTest >> testListsKeepAFieldWhenSayingItOnceWouldEmptyARow [
	"Rows that differ in nothing on their line keep their fields, or the list would read as blank lines."

	| lines |
	lines := (String streamContents: [ :stream |
			          MCPToolSearchMethodReferences new
				          entriesTextOn: stream
				          for: {
						          { (#kind -> 'senders') } asDictionary.
						          { (#kind -> 'senders') } asDictionary }
				          labelled: 'rows'
				          indent: '' ]) lines.
	self assert: lines equals: #( '' 'rows:' '  kind=senders' '  kind=senders' )
]

{ #category : 'tests' }
MCPToolContractsTest >> testListsSayAFieldEveryRowSharesOnce [
	"A field the request fixed is the same on every row, so the list says it once beside its name and the rows keep what tells them apart."

	| lines |
	lines := (String streamContents: [ :stream |
			          MCPToolSearchMethodReferences new
				          entriesTextOn: stream
				          for: {
						          {
							          (#kind -> 'senders').
							          (#rank -> 1) } asDictionary.
						          {
							          (#kind -> 'senders').
							          (#rank -> 2) } asDictionary }
				          labelled: 'rows'
				          indent: '' ]) lines.
	self assert: lines equals: #( '' 'rows (each kind=senders):' '  rank=1' '  rank=2' )
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
	"An image that loads MCP's tests serves MCP too, so a fixture that names itself and forgot to answer false would be in the catalog of every server in that image. Classes a test generates are left out of the sweep: they exist to be discovered and removed again."

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
MCPToolContractsTest >> testMethodRecordsReadAsMethodReferences [

	| contentText result |
	result := self callToolNamed: 'method_search' withArguments: {
		          (self searchScope: { (#classes -> #( 'MCPToolMethodSearchTestTarget' )) }) } asDictionary.
	contentText := (result at: #content) first at: #text.
	self deny: (self resultIndicatesError: result).
	self assert: (contentText includesSubstring: 'MCPToolMethodSearchTestTarget>>alphaNeedleSelector').
	self assert: (contentText includesSubstring: 'MCPToolMethodSearchTestTarget class>>classNeedleSelector').
	self deny: (contentText includesSubstring: 'className=').
	self deny: (contentText includesSubstring: 'classSide=')
]

{ #category : 'tests' }
MCPToolContractsTest >> testMethodToolTraitOwnsSharedMethodHelpers [

	| methodToolClasses sharedSelectors |
	methodToolClasses := {
		                     MCPToolGetMethod.
		                     MCPToolMethodMutation.
		                     MCPToolMethodSearch.
		                     MCPToolRewriteMethods.
		                     MCPToolRemoveMethods.
		                     MCPToolRunCritiques }.
	sharedSelectors := #( behaviorNamed:classSide: classNameAndSideOf:do: classReferenceNameFor:classSide:
	                      methodReferenceForBehavior:selector: methodReferenceForClassName:selector:isClassSide:
	                      methodScopeQueryFromRequest: requestedClassNameIn: requestedClassSideIn: ).
	methodToolClasses do: [ :toolClass |
			self assert: (toolClass withAllSuperclasses anySatisfy: [ :each | each traits includes: TMCPMethodTool ]).
			sharedSelectors do: [ :selector |
					| implementingClass |
					implementingClass := toolClass whichClassIncludesSelector: selector.
					self assert: implementingClass isNotNil.
					self assert: (implementingClass >> selector) origin equals: TMCPMethodTool ] ]
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

	| compileMethodTool getClassTool getMethodTool removeClassesTool removeMethodsTool rewriteMethodsTool updateMethodTool |
	getClassTool := MCPToolGetClass new.
	getMethodTool := MCPToolGetMethod new.
	compileMethodTool := MCPToolCompileMethod new.
	updateMethodTool := MCPToolUpdateMethod new.
	rewriteMethodsTool := MCPToolRewriteMethods new.
	removeClassesTool := MCPToolRemoveClasses new.
	removeMethodsTool := MCPToolRemoveMethods new.
	self assert: ((self inputPropertyNamed: 'offset' inTool: getClassTool) extraProperties at: #default) equals: 0.
	self assert: ((self inputPropertyNamed: 'side' inTool: getMethodTool) extraProperties at: #default) equals: 'instance'.
	self
		assert: ((self inputPropertyNamed: 'includeVariableDetails' inTool: getMethodTool) extraProperties at: #default)
		equals: false.
	self assert: ((self inputPropertyNamed: 'side' inTool: updateMethodTool) extraProperties at: #default) equals: 'instance'.
	self assert: ((self inputPropertyNamed: 'format' inTool: compileMethodTool) extraProperties at: #default).
	self assert: ((self inputPropertyNamed: 'force' inTool: updateMethodTool) extraProperties at: #default) equals: false.
	self assert: ((self inputPropertyNamed: 'format' inTool: updateMethodTool) extraProperties at: #default).
	self assert: ((self inputPropertyNamed: 'confirm' inTool: rewriteMethodsTool) extraProperties at: #default) equals: false.
	self assert: ((self scopePropertyNamed: 'side' inTool: rewriteMethodsTool) extraProperties at: #default) equals: 'both'.
	self assert: ((self inputPropertyNamed: 'force' inTool: removeClassesTool) extraProperties at: #default) equals: false.
	self assert: ((self inputPropertyNamed: 'side' inTool: removeMethodsTool) extraProperties at: #default) equals: 'instance'.
	self
		assert: ((self inputPropertyNamed: 'superclass' inTool: MCPToolCreateClass new) extraProperties at: #default)
		equals: 'Object'.
	self assert: ((self inputPropertyNamed: 'tag' inTool: MCPToolCreateClass new) extraProperties at: #default) equals: ''.
	self
		assert: ((self inputPropertyNamed: 'queryMode' inTool: MCPToolSearchMethodSource new) extraProperties at: #default)
		equals: 'substring'
]

{ #category : 'tests' }
MCPToolContractsTest >> testProjectMethodsDoNotHandleMessageNotUnderstoodAsControlFlow [

	| offendingMethods rule |
	rule := MCPMessageNotUnderstoodHandlerRule new.
	offendingMethods := (self mcpMethodsReferringTo: #on:do:) select: [ :method |
		                    method sendNodes anySatisfy: [ :sendNode | rule isMessageNotUnderstoodHandlerSend: sendNode ] ].
	self assert: offendingMethods isEmpty description: ('Methods handling MessageNotUnderstood: {1}' format:
			 { (offendingMethods collect: [ :method | method printString ] as: Array) printString })
]

{ #category : 'tests' }
MCPToolContractsTest >> testProjectMethodsDoNotSendReflectiveProtocolChecks [

	| forbiddenSelector offendingMethods |
	forbiddenSelector := MCPRespondsToUsageRule forbiddenSelector.
	offendingMethods := (self mcpMethodsReferringTo: forbiddenSelector) select: [ :method |
		                    method sendNodes anySatisfy: [ :sendNode | sendNode selector = forbiddenSelector ] ].
	self assert: offendingMethods isEmpty description: ('Methods sending {1}: {2}' format: {
				 forbiddenSelector.
				 (offendingMethods collect: [ :method | method printString ] as: Array) printString })
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
	"The public surface is capped at twenty: the catalogue, the classes and their packages, the methods, running and critiquing code, and moving the image's changes to the checkout."

	| discoverableToolNames expectedAdvertisedToolNames registry toolNames |
	registry := self toolRegistry.
	toolNames := (self mcpWithoutObservabilityExport rpcToolsList at: #tools) collect: [ :each | each at: #name ].
	expectedAdvertisedToolNames := #( 'tool_search' 'tool_get' 'tool_call' 'class_search' 'class_get' 'class_create' 'class_update'
	                                  'class_remove' 'package_search' 'method_search' 'method_source_search' 'method_reference_search'
	                                  'method_get' 'method_compile' 'method_remove' 'evaluate' 'test_run' 'critique_run'
	                                  'repository_change_list' 'repository_export' ).
	discoverableToolNames := registry toolNames difference: registry advertisedToolNames.
	self assert: expectedAdvertisedToolNames size equals: 20.
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
	self assert: propertyNames equals: #( 'scope' 'query' 'tag' 'offset' ) asSet.
	result := mcp rpcToolCall: 'class_search' withParams: { (self searchScope: {
				           (#classes -> #( 'MCPToolContractsTest' )).
				           (#packages -> #( 'MCP-Tests' )) }) } asDictionary.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests' }
MCPToolContractsTest >> testRecordListsCarryTheirLabel [

	| lines result |
	result := self
		          callToolNamed: 'class_search'
		          withArguments: { (self searchScope: { (#subclassesOf -> #( 'MCPToolMutation' )) }) } asDictionary.
	lines := ((result at: #content) first at: #text) lines.
	self deny: (self resultIndicatesError: result).
	self assert: (lines first includesSubstring: 'in the subclasses of MCPToolMutation').
	self assert: (lines second beginsWith: 'classes').
	self assert: (lines third beginsWith: '  ')
]

{ #category : 'tests' }
MCPToolContractsTest >> testRecordsLeadWithTheirName [
	"A record opens with what it names, bare, rather than spending a field on it, and its name is what tells it from the others."

	| lines |
	lines := (((self
		            callToolNamed: 'class_search'
		            withArguments:
		            { (self searchScope: { (#classes -> #( 'MCPToolHierarchyTestMid' 'MCPToolGetClass' )) }) } asDictionary) at:
		           #content) first at: #text) lines.
	self assert: (lines includes: 'classes:').
	self assert: (lines anySatisfy: [ :each | each beginsWith: '  MCPToolGetClass package=MCP-IDE' ]).
	self assert: (lines anySatisfy: [ :each | each beginsWith: '  MCPToolHierarchyTestMid package=MCP-Tests-Resources' ]).
	self deny: (lines anySatisfy: [ :each | each includesSubstring: 'class=' ]).
	lines := (((self callToolNamed: 'package_search' withArguments: { (#query -> 'MCP-Tests-Resources') } asDictionary) at: #content)
		          first at: #text) lines.
	self assert: (lines includes: '  MCP-Tests-Resources').
	self deny: (lines anySatisfy: [ :each | each includesSubstring: 'package=' ]).
	lines := (MCPToolListChangeHistoryFiles new contentTextForStructuredContent: (Dictionary new
			           at: #summary put: 'Listed 2 change history files.';
			           at: #data put: { (#files -> {
						            {
							            (#file -> 'a.ombu').
							            (#isCurrent -> true) } asDictionary.
						            {
							            (#file -> 'b.ombu').
							            (#isCurrent -> true) } asDictionary }) } asDictionary;
			           yourself)) lines.
	self assert: lines equals: #( 'Listed 2 change history files.' 'files (each isCurrent=true):' '  a.ombu' '  b.ombu' )
]

{ #category : 'tests' }
MCPToolContractsTest >> testRequestedToolIconsAreSelected [

	self
		assert: MCPToolGetClass toolIconSpec cacheKey
		equals: (MCPToolIconSpec baseIconNamed: #class badgeIconNamed: #inspect) cacheKey.
	self
		assert: MCPToolSearchMethodSource toolIconSpec cacheKey
		equals: (MCPToolIconSpec baseIconNamed: #page leftBadgeIconNamed: #workspace rightBadgeIconNamed: #search) cacheKey.
	self
		assert: MCPToolSearchMethodReferences toolIconSpec cacheKey
		equals: (MCPToolIconSpec baseIconNamed: #page leftBadgeIconNamed: #references rightBadgeIconNamed: #search) cacheKey.
	self
		assert: MCPToolUpdateMethod toolIconSpec cacheKey
		equals: (MCPToolIconSpec baseIconNamed: #page badgeIconNamed: #edit) cacheKey.
	self
		assert: MCPToolUpdateClass toolIconSpec cacheKey
		equals: (MCPToolIconSpec baseIconNamed: #class badgeIconNamed: #edit) cacheKey.
	self
		assert: MCPToolListChangeHistoryEntries toolIconSpec cacheKey
		equals: (MCPToolIconSpec baseIconNamed: #history leftBadgeIconNamed: #changeUpdate rightBadgeIconNamed: #browse) cacheKey.
	self
		assert: MCPToolCaptureScreen toolIconSpec cacheKey
		equals: (MCPToolIconSpec baseIconNamed: #window badgeIconNamed: #smallScreenshot) cacheKey.
	self
		assert: MCPToolRunTests toolIconSpec cacheKey
		equals: (MCPToolIconSpec baseIconNamed: #testRunner badgeIconNamed: #play) cacheKey
]

{ #category : 'tests' }
MCPToolContractsTest >> testRpcToolCallCatchesUnhandledHaltFromTool [

	| mcp result text tool |
	tool := MCPHaltingTestTool new.
	mcp := self mcpWithoutObservabilityExport.
	mcp addTool: tool.
	result := mcp rpcToolCall: tool name withParams: Dictionary new.
	text := self textFrom: result.
	self assert: (result at: #isError).
	self assert: (text includesSubstring: 'Tool halting_test_tool failed (Halt)').
	self assert: (text includesSubstring: 'mcp tool halt test')
]

{ #category : 'tests - validation' }
MCPToolContractsTest >> testRpcToolCallRefusesAMissingRequiredArgument [

	self
		assertResult: (self callToolNamed: 'evaluate' withArguments: Dictionary new)
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
		assertResult: (self callToolNamed: 'evaluate' withArguments: {
					 (#code -> '1 + 1').
					 (#unexpected -> true) } asDictionary)
		refusesArgumentsSaying: 'unexpected is not accepted here; expected one of '
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchSummaryCountsOneInTheSingular [

	self
		assert: (self summaryOfTool: 'class_search' with: { (self searchScope: { (#classes -> #( 'MCPToolHierarchyTestMid' )) }) })
		equals: '1 class in MCPToolHierarchyTestMid.'.
	self
		assert: (self summaryOfTool: 'class_search' with: { (#query -> 'MCPToolHierarchyTestMid') })
		equals: '1 class matches in the image.'.
	self
		assert: (self summaryOfTool: 'method_search' with: {
					 (self searchScope: { (#classes -> #( 'MCPToolMethodSearchTestTarget' )) }).
					 (#query -> 'classNeedleSelector') })
		equals: '1 method matches in MCPToolMethodSearchTestTarget.'
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchSummaryLeavesOutANameOnlyWhereItIsMissing [
	"A name given under two kinds of scope entry may exist as one and not the other: the summary names it where it exists, and the warning where it does not."

	| result |
	result := self callToolNamed: 'class_search' withArguments: { (self searchScope: {
				           (#packages -> #( 'MCPToolHierarchyTestMid' )).
				           (#classes -> #( 'MCPToolHierarchyTestMid' )) }) } asDictionary.
	self assert: (self summaryFrom: result) equals: '1 class in MCPToolHierarchyTestMid.'.
	self assert: (self warningsFrom: result) size equals: 1.
	self assert: ((self warningsFrom: result) first includesSubstring: 'Package MCPToolHierarchyTestMid').
	result := self callToolNamed: 'method_search' withArguments: {
			          (self searchScope: {
					           (#packages -> #( 'MCP-Tests-Resources' )).
					           (#hierarchyOf -> #( 'MCP-Tests-Resources' )) }).
			          (#query -> 'classNeedleSelector') } asDictionary.
	self assert: (self summaryFrom: result) equals: '1 method matches in package MCP-Tests-Resources.'.
	self assert: (self warningsFrom: result) size equals: 1.
	self assert: ((self warningsFrom: result) first includesSubstring: 'Class MCP-Tests-Resources')
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchSummaryLeavesOutANameThatDoesNotExist [
	"The warning names a missing name; the summary says where the search did look."

	| result |
	result := self
		          callToolNamed: 'class_search'
		          withArguments:
		          { (self searchScope: { (#classes -> #( 'MCPToolHierarchyTestMid' 'MCPNoSuchSummaryClass' )) }) } asDictionary.
	self assert: (self summaryFrom: result) equals: '1 class in MCPToolHierarchyTestMid.'.
	self assert: (self warningsFrom: result) size equals: 1.
	self assert: ((self warningsFrom: result) first includesSubstring: 'MCPNoSuchSummaryClass').
	result := self callToolNamed: 'method_search' withArguments: {
			          (self searchScope: { (#classes -> #( 'MCPNoSuchSummaryClass' )) }).
			          (#query -> 'size') } asDictionary.
	self assert: (self summaryFrom: result) equals: 'No methods match: the scope names nothing that exists.'.
	self assert: ((self warningsFrom: result) first includesSubstring: 'MCPNoSuchSummaryClass')
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchSummaryNamesTheScopeItSearched [
	"A summary says where the search looked, in words, rather than which arguments the scope was given."

	self
		assert: (self
				 summaryOfTool: 'class_search'
				 with: { (self searchScope: { (#classes -> #( 'MCPToolHierarchyTestBase' 'MCPToolHierarchyTestMid' )) }) })
		equals: '2 classes in MCPToolHierarchyTestBase and MCPToolHierarchyTestMid.'.
	self
		assert:
		(self summaryOfTool: 'class_search' with: { (self searchScope: { (#subclassesOf -> #( 'MCPToolHierarchyTestBase' )) }) })
		equals: '2 classes in the subclasses of MCPToolHierarchyTestBase.'.
	self
		assert: (self summaryOfTool: 'class_search' with: { (#query -> 'MCPToolHierarchyTest') })
		equals: '3 classes match in the image.'.
	self
		assert: (self
				 summaryOfTool: 'method_search'
				 with: { (self searchScope: { (#classes -> #( 'MCPToolMethodSearchTestTarget' )) } side: 'class') })
		equals: '2 methods in MCPToolMethodSearchTestTarget, class side.'.
	self
		assert: (self summaryOfTool: 'class_search' with: { (self searchScope: {
						  (#packages -> #( 'MCP-Tests-Resources-Extensions' )).
						  (#classes -> #( 'MCPToolHierarchyTestMid' )) }) })
		equals: ('{1} classes in package MCP-Tests-Resources-Extensions and MCPToolHierarchyTestMid.' format:
				 { (1 + (self packageOrganizer packageNamed: 'MCP-Tests-Resources-Extensions') classes size) })
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchSummarySaysWhenNothingMatched [

	self
		assert: (self summaryOfTool: 'class_search' with: { (#query -> 'MCPNoClassIsNamedLikeThisAnywhere') })
		equals: 'No classes match in the image.'.
	self
		assert:
		(self summaryOfTool: 'class_search' with: { (self searchScope: { (#subclassesOf -> #( 'MCPToolHierarchyTestChild' )) }) })
		equals: 'No classes in the subclasses of MCPToolHierarchyTestChild.'
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchSummarySaysWhereTheNextPageStarts [

	| arguments result total |
	arguments := { (self searchScope: { (#packages -> #( 'MCP-IDE' )) }) }.
	result := self callToolNamed: 'method_search' withArguments: arguments asDictionary.
	total := ((self dataFrom: result) at: #pagination) at: #totalCount.
	self assert: total > 50.
	self
		assert: (self summaryFrom: result)
		equals: ('25 of {1} methods in package MCP-IDE. Next page: offset 25, or narrow the search.' format: { total }).
	self
		assert: (self summaryOfTool: 'method_search' with: arguments , { (#offset -> 25) })
		equals: ('25 of {1} methods in package MCP-IDE. Next page: offset 50, or narrow the search.' format: { total }).
	self
		assert: (self summaryOfTool: 'method_search' with: arguments , { (#offset -> (total + 5)) })
		equals: ('No methods from offset {1}; {2} methods in package MCP-IDE.' format: {
					 (total + 5).
					 total })
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
		               MCPToolSearchMethodReferences new }.
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
	text := self textFrom: (self
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
	self assert: toolNames asSet equals: #( 'tool_search' 'tool_get' 'tool_call' 'class_search' ) asSet
]

{ #category : 'tests' }
MCPToolContractsTest >> testServerInitializationLeavesIconCacheEmpty [

	MCPStructureIcon resetCaches.
	self mcpWithoutObservabilityExport.
	self assert: MCPStructureIcon iconCache size equals: 0
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
MCPToolContractsTest >> testToolIconSpecsAreDerivedFromToolNames [
	"Among MCP's own tools, an icon is read from the name and never picked by hand, so they stay consistent without anyone choosing. A tool from another package cannot be spelled out of MCP's vocabulary, so it is left to declare its own."

	| builtIn |
	builtIn := MCPTool withAllSubclasses select: [ :each | self isBuiltIn: each ].
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
	self assert: MCPStructureIcon iconCache size equals: 1
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
	names := registry tools collect: [ :each | each class toolName ].
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
	text := self textFrom: result.
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
	text := self textFrom: result.
	self assert: (result includesKey: #content).
	self deny: (result includesKey: #structuredContent).
	self assert: (text includesSubstring: 'class_search - ')
]

{ #category : 'tests' }
MCPToolContractsTest >> testToolsDoNotResumeRefactoringWarnings [
	"A refactoring warning reports a change that breaks something: resuming it at the boundary would apply a mutation that force did not authorize."

	self deny: RBRefactoringWarning new mcpResumesAtToolBoundary.
	self assert: MCPToolNestedNotification new mcpResumesAtToolBoundary
]

{ #category : 'tests' }
MCPToolContractsTest >> testToolsListAdvertisesToolContracts [

	| tools |
	tools := MCP new rpcToolsList at: #tools.
	self assert: tools isNotEmpty.
	tools do: [ :tool | self assert: tool keys asSet equals: #( name title description annotations inputSchema ) asSet ]
]

{ #category : 'private' }
MCPToolContractsTest >> unimplementedResponsibilitiesForConcreteMCPClasses [
	"A concrete class leaves a responsibility unimplemented when the method it answers for a selector sends subclassResponsibility. That method is in its lookup chain, so only the selectors of the chains' methods that send it are looked up."

	| behaviors issues selectors |
	behaviors := ((self builtInPackageNames flatCollect: [ :name | (self packageOrganizer packageNamed: name) definedClasses ])
		              reject: [ :each | each isTrait or: [ each isAbstract ] ]) flatCollect: [ :each |
		             Array with: each with: each class ].
	selectors := IdentitySet new.
	(behaviors flatCollect: [ :each | each withAllSuperclasses ]) asIdentitySet do: [ :behavior |
		behavior methods do: [ :method | (method sendsSelector: #subclassResponsibility) ifTrue: [ selectors add: method selector ] ] ].
	issues := OrderedCollection new.
	behaviors do: [ :each | self addUnimplementedResponsibilitiesOf: each among: selectors to: issues ].
	^ issues asArray sort
]
