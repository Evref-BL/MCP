"
Tests method creation and update tools, including critique handling.
"
Class {
	#name : 'MCPToolMethodMutationTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'private - calling' }
MCPToolMethodMutationTest >> aroundToolCall: aBlock [

	^ self withoutEpiceaDuring: aBlock
]

{ #category : 'private' }
MCPToolMethodMutationTest >> assertCompileForClassName: aClassName methodSource: aMethodSource protocol: aProtocol returnsSingleCritiqueRuleClass: aRuleClassName titledLike: aSubstring [

	| critique critiques data result |
	result := self callToolWith: (self
			           compileArgumentsForClassName: aClassName
			           classSide: false
			           methodSource: aMethodSource
			           protocol: aProtocol).
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	critiques := data at: #critiques.
	self assert: critiques class equals: Array.
	self assert: critiques size equals: 1.
	critique := critiques first.
	self assert: (critique at: #ruleClass) equals: aRuleClassName.
	self assert: ((critique at: #title) includesSubstring: aSubstring).
	self assert: (critique at: #description) isString.
	self deny: (critique at: #description) isEmpty
]

{ #category : 'private' }
MCPToolMethodMutationTest >> assertSuccessDataHasMethodShape: data [

	#( selector className classSide packageName isExtension protocol
	   source side action updateAction oldSelector newSelector
	   oldProtocol newProtocol ) do: [ :key |
		self deny: (data includesKey: key) ].
	(data includesKey: #changeKind) ifTrue: [
			self assert:
				(#( 'created' 'replaced' ) includes: (data at: #changeKind)) ]
]

{ #category : 'private - calling' }
MCPToolMethodMutationTest >> callToolWith: someArguments [

	| arguments request result tool toolClass |
	arguments := someArguments copy.
	arguments removeKey: #action ifAbsent: [ ].
	toolClass := (arguments includesKey: #source)
		             ifTrue: [ MCPToolCompileMethod ]
		             ifFalse: [
				             (arguments includesKey: #newSelector)
					             ifTrue: [ MCPToolUpdateMethodSelector ]
					             ifFalse: [ MCPToolUpdateMethodProtocol ] ].
	tool := toolClass new.
	request := tool requestFromToolCallArguments: arguments.
	result := tool executeWithRequest: request.
	^ result asJRPCJSON
]

{ #category : 'private' }
MCPToolMethodMutationTest >> classChangeArguments [

	^ {
		  (#action -> 'update').
		  (#className -> 'MCPToolMethodMutationTestTarget').
		  (#classSide -> true).
		  (#selector -> self classProtocolSelector asString).
		  (#protocol -> 'instance creation') } asDictionary
]

{ #category : 'private' }
MCPToolMethodMutationTest >> classProtocolSelector [

	^ #classProtocolTarget
]

{ #category : 'private' }
MCPToolMethodMutationTest >> classRenameArguments [

	^ {
		  (#action -> 'update').
		  (#className -> 'MCPToolMethodMutationTestTarget').
		  (#classSide -> true).
		  (#selector -> self classSelector asString).
		  (#newSelector -> self renamedClassSelector asString) }
		  asDictionary
]

{ #category : 'private' }
MCPToolMethodMutationTest >> classSelector [

	^ ('build' , 'Value:') asSymbol
]

{ #category : 'private' }
MCPToolMethodMutationTest >> compileArgumentsForClassName: aClassName classSide: aBoolean methodSource: aMethodSource protocol: aProtocol [

	^ {
		  (#action -> 'create').
		  (#className -> aClassName).
		  (#classSide -> aBoolean).
		  (#source -> aMethodSource).
		  (#protocol -> aProtocol) } asDictionary
]

{ #category : 'private' }
MCPToolMethodMutationTest >> createRenameScopeFixtureClassNamed: aClassName packageName: aPackageName [

	self withoutEpiceaDuring: [
			| builder |
			builder := Object << aClassName asSymbol.
			builder package: aPackageName.
			builder install ]
]

{ #category : 'private' }
MCPToolMethodMutationTest >> extensionChangeArguments [

	^ {
		  (#action -> 'update').
		  (#className -> 'MCPToolMethodMutationTestTarget').
		  (#classSide -> false).
		  (#selector -> self extensionProtocolSelector asString).
		  (#protocol -> 'tests') } asDictionary
]

{ #category : 'private' }
MCPToolMethodMutationTest >> extensionProtocolSelector [

	^ #extensionProtocolTarget
]

{ #category : 'private' }
MCPToolMethodMutationTest >> instanceChangeArguments [

	^ {
		  (#action -> 'update').
		  (#className -> 'MCPToolMethodMutationTestTarget').
		  (#classSide -> false).
		  (#selector -> self instanceProtocolSelector asString).
		  (#protocol -> 'accessing') } asDictionary
]

{ #category : 'private' }
MCPToolMethodMutationTest >> instanceProtocolSelector [

	^ #instanceProtocolTarget
]

{ #category : 'private' }
MCPToolMethodMutationTest >> instanceRenameArguments [

	^ {
		  (#action -> 'update').
		  (#className -> 'MCPToolMethodMutationTestTarget').
		  (#classSide -> false).
		  (#selector -> self instanceSelector asString).
		  (#newSelector -> self renamedInstanceSelector asString).
		  (#permutation -> #( 2 1 )) } asDictionary
]

{ #category : 'private' }
MCPToolMethodMutationTest >> instanceSelector [

	^ ('combine:' , 'with:') asSymbol
]

{ #category : 'private' }
MCPToolMethodMutationTest >> mcpPackageNames [

	^ #( 'BaselineOfMCP' 'MCP' 'MCP-UI' 'MCP-UI-Tests' 'MCP-Tests' 'MCP-Tests-Resources' 'MCP-Tests-Resources-Extensions' )
]

{ #category : 'private' }
MCPToolMethodMutationTest >> methodDefinitionsInPackageNamed: packageName [

	^ (MCPackage named: packageName) snapshot definitions select: [
		  :definition | definition isMethodDefinition ]
]

{ #category : 'private' }
MCPToolMethodMutationTest >> methodSourceLineFeedOffenderNameFor: aMethodDefinition [

	^ aMethodDefinition className asString
	  , (aMethodDefinition classIsMeta
			   ifTrue: [ ' class>>' ]
			   ifFalse: [ '>>' ]) , aMethodDefinition selector asString
]

{ #category : 'private' }
MCPToolMethodMutationTest >> methodSourceLineFeedOffenders [

	| offenders |
	offenders := Array streamContents: [ :stream |
			             self mcpPackageNames do: [ :packageName |
					             self
						             methodSourceLineFeedOffendersInPackageNamed:
						             packageName
						             do: [ :offender | stream nextPut: offender ] ] ].
	^ offenders sort
]

{ #category : 'private' }
MCPToolMethodMutationTest >> methodSourceLineFeedOffendersInPackageNamed: packageName do: aBlock [

	(self methodDefinitionsInPackageNamed: packageName) do: [ :definition |
			(definition source includes: Character lf) ifTrue: [
				aBlock value:
					(self methodSourceLineFeedOffenderNameFor: definition) ] ]
]

{ #category : 'private' }
MCPToolMethodMutationTest >> renamedClassSelector [

	^ ('make' , 'Value:') asSymbol
]

{ #category : 'private' }
MCPToolMethodMutationTest >> renamedInstanceSelector [

	^ ('with:' , 'combine:') asSymbol
]

{ #category : 'private' }
MCPToolMethodMutationTest >> restoreFixtureMethods [

	self
		removeSelector: #instanceAnswer
		from: MCPToolMethodMutationTestTarget.
	self
		removeSelector: #classAnswer
		from: MCPToolMethodMutationTestTarget classSide.
	self
		removeSelector: #multilineAnswer
		from: MCPToolMethodMutationTestTarget.
	self
		removeSelector: #multilineStringAnswer
		from: MCPToolMethodMutationTestTarget.
	self
		removeSelector: #uglyAnswer
		from: MCPToolMethodMutationTestTarget.
	self
		removeSelector: self instanceSelector
		from: MCPToolMethodMutationTestTarget.
	self
		removeSelector: self renamedInstanceSelector
		from: MCPToolMethodMutationTestTarget.
	self
		removeSelector: self classSelector
		from: MCPToolMethodMutationTestTarget classSide.
	self
		removeSelector: self renamedClassSelector
		from: MCPToolMethodMutationTestTarget classSide.
	self
		removeSelector: self instanceProtocolSelector
		from: MCPToolMethodMutationTestTarget.
	self
		removeSelector: self classProtocolSelector
		from: MCPToolMethodMutationTestTarget classSide.
	self
		removeSelector: self extensionProtocolSelector
		from: MCPToolMethodMutationTestTarget.
	self
		removeSelector: #callInstanceTarget
		from: MCPToolMethodMutationTestSender.
	self
		removeSelector: #callClassTarget
		from: MCPToolMethodMutationTestSender.
	self
		ensureMethodSource:
		'combine: first with: second ^ first , ''-'' , second'
		protocol: 'tests'
		on: MCPToolMethodMutationTestTarget.
	self
		ensureMethodSource: 'buildValue: aString ^ ''Class-'' , aString'
		protocol: 'tests'
		on: MCPToolMethodMutationTestTarget classSide.
	self
		ensureMethodSource: 'instanceProtocolTarget ^ 41'
		protocol: 'tests'
		on: MCPToolMethodMutationTestTarget.
	self
		ensureMethodSource: 'classProtocolTarget ^ 7'
		protocol: 'tests'
		on: MCPToolMethodMutationTestTarget classSide.
	self
		ensureMethodSource: 'extensionProtocolTarget ^ 99'
		protocol: '*MCP-Tests-Resources-Extensions'
		on: MCPToolMethodMutationTestTarget.
	self
		ensureMethodSource:
		'callInstanceTarget ^ MCPToolMethodMutationTestTarget new combine: ''first'' with: ''second'''
		protocol: 'tests'
		on: MCPToolMethodMutationTestSender.
	self
		ensureMethodSource:
		'callClassTarget ^ MCPToolMethodMutationTestTarget buildValue: ''value'''
		protocol: 'tests'
		on: MCPToolMethodMutationTestSender
]

{ #category : 'running' }
MCPToolMethodMutationTest >> setUp [

	super setUp.
	self
		removeSelector: #combine:with:separator:
		from: MCPToolMethodMutationTestTarget.
	self
		removeSelector: #buildValue:prefix:
		from: MCPToolMethodMutationTestTarget classSide.
	self restoreFixtureMethods
]

{ #category : 'running' }
MCPToolMethodMutationTest >> tearDown [

	self
		removeSelector: #combine:with:separator:
		from: MCPToolMethodMutationTestTarget.
	self
		removeSelector: #buildValue:prefix:
		from: MCPToolMethodMutationTestTarget classSide.
	self restoreFixtureMethods.
	super tearDown
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testAddArgumentsUpdatesClassSideSenders [

	| data result senderSource |
	result := self callToolWith: {
			          (#action -> 'update').
			          (#className -> 'MCPToolMethodMutationTestTarget').
			          (#classSide -> true).
			          (#selector -> 'buildValue:').
			          (#newSelector -> 'buildValue:prefix:').
			          (#argumentNames -> #( 'aString' 'prefix' )).
			          (#argumentValueExpressions -> #( 'nil' )) } asDictionary.
	data := self dataFrom: result.
	senderSource := (MCPToolMethodMutationTestSender >> #callClassTarget)
		                sourceCode.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert:
		(MCPToolMethodMutationTestTarget classSide includesSelector:
			 #buildValue:prefix:).
	self assert: (senderSource includesSubstring: 'prefix: nil').
	self
		assert: MCPToolMethodMutationTestSender new callClassTarget
		equals: 'Class-value'
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testAddArgumentsUpdatesSendersAndReportsAction [

	| data result senderSource targetSource |
	result := self callToolWith: {
			          (#action -> 'update').
			          (#className -> 'MCPToolMethodMutationTestTarget').
			          (#classSide -> false).
			          (#selector -> 'combine:with:').
			          (#newSelector -> 'combine:with:separator:').
			          (#argumentNames -> #( 'first' 'second' 'separator' )).
			          (#argumentValueExpressions
			           -> (Array with: (String streamContents: [ :stream |
							             stream
								             nextPut: $';
								             nextPut: $|;
								             nextPut: $' ]))) } asDictionary.
	data := self dataFrom: result.
	targetSource := (MCPToolMethodMutationTestTarget
	                 >> #combine:with:separator:) sourceCode.
	senderSource := (MCPToolMethodMutationTestSender
	                 >> #callInstanceTarget) sourceCode.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (targetSource includesSubstring: 'separator: separator').
	self assert: (senderSource includesSubstring: 'separator: ''|''').
	self
		assert: MCPToolMethodMutationTestSender new callInstanceTarget
		equals: 'first-second'
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testChangeProtocolReturnsStructuredErrorWhenMethodIsMissing [

	| error result structured |
	self
		removeSelector: self instanceProtocolSelector
		from: MCPToolMethodMutationTestTarget.
	result := self callToolWith: self instanceChangeArguments.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #action) equals: 'update'.
	self assert: (error at: #updateAction) equals: 'changeProtocol'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'MethodNotFound'.
	self
		assert: (error at: #className)
		equals: 'MCPToolMethodMutationTestTarget'.
	self assert: (error at: #classSide) equals: false.
	self
		assert: (error at: #selector)
		equals: self instanceProtocolSelector asString.
	self assert: (error at: #protocol) equals: 'accessing'.
	self
		assert: error keys asSet
		equals:
			#( action updateAction errorClass errorCode message className
			   classSide selector protocol ) asSet
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testChangesClassSideMethodProtocol [

	| data result |
	result := self callToolWith: self classChangeArguments.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: (MCPToolMethodMutationTestTarget classSide
			 >> self classProtocolSelector) protocol name asString
		equals: 'instance creation'.
	self assertSuccessDataHasMethodShape: data.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testChangesInstanceSideMethodProtocol [

	| data result |
	result := self callToolWith: self instanceChangeArguments.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert:
			(MCPToolMethodMutationTestTarget >> self instanceProtocolSelector)
				protocol name asString
		equals: 'accessing'.
	self assertSuccessDataHasMethodShape: data.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testChangingExtensionMethodProtocolUpdatesPackageMetadata [

	| data result |
	result := self callToolWith: self extensionChangeArguments.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert:
			(MCPToolMethodMutationTestTarget >> self extensionProtocolSelector)
				protocol name asString
		equals: 'tests'.
	self assertSuccessDataHasMethodShape: data
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCollectionStyleCritiquesProvideAutomaticChanges [

	| samples |
	samples := {
		           {
			           #nilOnlyConditionalProbe:.
			           'nilOnlyConditionalProbe: value ^ value ifNil: [ nil ] ifNotNil: [ :present | present asString ]'.
			           MCPNilOnlyConditionalRule }.
		           {
			           #dictionaryAtIfPresentProbe:.
			           'dictionaryAtIfPresentProbe: dictionary | result | result := OrderedCollection new. (dictionary at: #name ifAbsent: [ nil ]) ifNotNil: [ :value | result add: value ]. ^ result'.
			           MCPDictionaryAtIfPresentRule }.
		           {
			           #selectSizeProbe:.
			           'selectSizeProbe: collection ^ (collection select: [ :each | each odd ]) size'.
			           MCPSelectSizeCountRule }.
		           {
			           #filteredEmptinessProbe:.
			           'filteredEmptinessProbe: collection ^ (collection select: [ :each | each odd ]) isEmpty'.
			           MCPFilteredEmptinessRule }.
		           {
			           #filterThenCollectProbe:.
			           'filterThenCollectProbe: collection ^ (collection select: [ :each | each odd ]) collect: [ :each | each asString ]'.
			           MCPFilterThenCollectRule }.
		           {
			           #collectionThenDoProbe:.
			           'collectionThenDoProbe: collection | sum | sum := 0. (collection select: [ :each | each odd ]) do: [ :each | sum := sum + each ]. ^ sum'.
			           MCPCollectionThenDoRule }.
		           {
			           #sortedCollectionConversionProbe:.
			           'sortedCollectionConversionProbe: collection ^ collection asSortedCollection asArray'.
			           MCPSortedCollectionConversionRule } }.
	samples do: [ :sample |
			| change critique method ruleClass selector source |
			selector := sample first.
			source := sample second.
			ruleClass := sample third.
			self removeSelector: selector from: MCPToolGetMethodTestTarget.
			[
				self
					ensureMethodSource: source
					protocol: 'tests'
					on: MCPToolGetMethodTestTarget.
				method := MCPToolGetMethodTestTarget >> selector.
				critique := method critiques
					            detect: [ :each | each rule class = ruleClass ]
					            ifNone: [
					            self fail: 'Expected critique from ' , ruleClass name ].
				self assert: critique providesChange.
				change := critique change.
				self assert:
					(change class name asString includesSubstring: 'AddMethodChange') ]
				ensure: [
				self removeSelector: selector from: MCPToolGetMethodTestTarget ] ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileAcceptsExplicitSelfReturnInBranch [

	| critiques data result selector target |
	selector := #selfReturnInBranchProbe:.
	self removeSelector: selector from: MCPToolMethodMutationTestTarget.
	[
		result := self callToolWith: (self
				           compileArgumentsForClassName: 'MCPToolMethodMutationTestTarget'
				           classSide: false
				           methodSource: 'selfReturnInBranchProbe: aBoolean aBoolean ifTrue: [ ^ self ]. ^ 1'
				           protocol: 'tests').
		self assert: ((self structuredContentFrom: result) at: #status) equals: 'ok'.
		data := self dataFrom: result.
		critiques := data at: #critiques ifAbsent: [ #(  ) ].
		self assert: critiques equals: #(  ).
		target := MCPToolMethodMutationTestTarget new.
		self assert: (target selfReturnInBranchProbe: true) identicalTo: target.
		self assert: (target selfReturnInBranchProbe: false) equals: 1 ] ensure: [
		self removeSelector: selector from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileAllowsExplicitlyReturnedBlock [

	| result selector |
	selector := #returnedBlockProbe.
	self removeSelector: selector from: MCPToolMethodMutationTestTarget.
	[
		result := self callToolWith: (self
			compileArgumentsForClassName: 'MCPToolMethodMutationTestTarget'
			classSide: false
			methodSource: 'returnedBlockProbe ^ [ 1 ]'
			protocol: 'tests').
		self deny: (result at: #isError ifAbsent: [ false ]).
		self assert: MCPToolMethodMutationTestTarget new returnedBlockProbe value equals: 1 ]
		ensure: [ self removeSelector: selector from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileBlocksDeadBlockBeforeInstallation [

	| critique critiques error result selector |
	selector := #deadBlockProbe.
	self removeSelector: selector from: MCPToolMethodMutationTestTarget.
	result := self callToolWith: (self
		compileArgumentsForClassName: 'MCPToolMethodMutationTestTarget'
		classSide: false
		methodSource: 'deadBlockProbe [ self error: ''never run'' ]'
		protocol: 'tests').
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorCode) equals: 'CompileBlockedByCritiques'.
	critiques := error at: #critiques.
	self assert: critiques size equals: 1.
	critique := critiques first.
	self assert: (critique at: #ruleClass) equals: 'ReDeadBlockRule'.
	self deny: (MCPToolMethodMutationTestTarget includesSelector: selector)
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileCanReplaceMethodOnToolClass [

	| data method result |
	method := MCPHaltingTestTool >> #title.
	result := self callToolNamed: 'method_compile' withArguments: {
			          (#className -> 'MCPHaltingTestTool').
			          (#source -> method sourceCode).
			          (#protocol -> method protocol name asString) }
			          asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #changeKind) equals: 'replaced'
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileDefaultsToInstanceSideWhenClassSideIsOmitted [

	| data result |
	result := self callToolWith: {
			          (#action -> 'create').
			          (#className -> 'MCPToolMethodMutationTestTarget').
			          (#source -> 'instanceAnswer ^ 42').
			          (#protocol -> 'tests') } asDictionary.
	data := self dataFrom: result.
	self
		assert: MCPToolMethodMutationTestTarget new instanceAnswer
		equals: 42.
	self deny:
		(MCPToolMethodMutationTestTarget classSide includesSelector:
			 #instanceAnswer).
	self assertSuccessDataHasMethodShape: data.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileMethodReportsCreatedChangeKind [

	| data result selector |
	selector := #directCreateProbe.
	self removeSelector: selector from: MCPToolMethodMutationTestTarget.
	[
		result := self callToolNamed: 'method_compile' withArguments: {
				          (#className -> 'MCPToolMethodMutationTestTarget').
				          (#source -> 'directCreateProbe ^ 11').
				          (#protocol -> 'tests') } asDictionary.
		data := self dataFrom: result.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self
			assert: (self summaryFrom: result)
			equals:
			'Created MCPToolMethodMutationTestTarget>>directCreateProbe.'.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self assert: (data at: #changeKind) equals: 'created'.
		self assertSuccessDataHasMethodShape: data.
		self
			assert: MCPToolMethodMutationTestTarget new directCreateProbe
			equals: 11 ] ensure: [
		self removeSelector: selector from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileMethodReportsReplacedChangeKind [

	| data result selector |
	selector := #directReplaceProbe.
	self
		ensureMethodSource: 'directReplaceProbe ^ 1'
		protocol: 'tests'
		on: MCPToolMethodMutationTestTarget.
	[
		result := self callToolNamed: 'method_compile' withArguments: {
				          (#className -> 'MCPToolMethodMutationTestTarget').
				          (#source -> 'directReplaceProbe ^ 2').
				          (#protocol -> 'tests') } asDictionary.
		data := self dataFrom: result.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self
			assert: (self summaryFrom: result)
			equals:
			'Replaced MCPToolMethodMutationTestTarget>>directReplaceProbe.'.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self assert: (data at: #changeKind) equals: 'replaced'.
		self assertSuccessDataHasMethodShape: data.
		self
			assert: MCPToolMethodMutationTestTarget new directReplaceProbe
			equals: 2 ] ensure: [
		self removeSelector: selector from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsAllowlistedEquivalentSuperclassMethodCritique [

	| selector |
	selector := #hierarchyTarget.
	self removeSelector: selector from: MCPToolHierarchyTestChild.
	[
		self
			assertCompileForClassName: 'MCPToolHierarchyTestChild'
			methodSource: 'hierarchyTarget ^ ''base-target'''
			protocol: 'tests'
			returnsSingleCritiqueRuleClass: 'ReEquivalentSuperclassMethodsRule'
			titledLike: 'Methods equivalently defined in superclass' ] ensure: [
		self removeSelector: selector from: MCPToolHierarchyTestChild ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsAllowlistedExcessiveArgumentsCritique [

	| selector |
	selector := #argumentHeavyMethod:with:with:with:with:.
	self removeSelector: selector from: MCPToolMethodMutationTestTarget.
	[
		self
			assertCompileForClassName: 'MCPToolMethodMutationTestTarget'
			methodSource:
			'argumentHeavyMethod: first with: second with: third with: fourth with: fifth ^ first + second + third + fourth + fifth'
			protocol: 'tests'
			returnsSingleCritiqueRuleClass: 'ReExcessiveArgumentsRule'
			titledLike: 'Excessive number of arguments' ] ensure: [
		self removeSelector: selector from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsAllowlistedMissingSuperSendsCritique [

	self removeSelector: #initialize from: MCPToolHierarchyTestBase.
	self removeSelector: #initialize from: MCPToolHierarchyTestChild.
	[
		self
			ensureMethodSource: 'initialize super initialize. ^ 1'
			protocol: 'initialization'
			on: MCPToolHierarchyTestBase.
		self
			assertCompileForClassName: 'MCPToolHierarchyTestChild'
			methodSource: 'initialize 2 + 3'
			protocol: 'initialization'
			returnsSingleCritiqueRuleClass: 'ReMissingSuperSendsRule'
			titledLike: 'Missing super sends' ] ensure: [
			self removeSelector: #initialize from: MCPToolHierarchyTestBase.
			self removeSelector: #initialize from: MCPToolHierarchyTestChild ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsAllowlistedNotOptimizedIfCritique [

	| selector |
	selector := #notOptimizedIf.
	self removeSelector: selector from: MCPToolGetMethodTestTarget.
	[
		self
			assertCompileForClassName: 'MCPToolGetMethodTestTarget'
			methodSource: 'notOptimizedIf [ true ] ifTrue: [ ^ 1 ]. ^ 2'
			protocol: 'tests'
			returnsSingleCritiqueRuleClass: 'ReNotOptimizedIfRule'
			titledLike: 'ifTrue:' ] ensure: [
		self removeSelector: selector from: MCPToolGetMethodTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsAllowlistedNotOptimizedIfNilCritique [

	| selector |
	selector := #notOptimizedIfNil.
	self removeSelector: selector from: MCPToolGetMethodTestTarget.
	[
		self
			assertCompileForClassName: 'MCPToolGetMethodTestTarget'
			methodSource: 'notOptimizedIfNil [ nil ] ifNil: [ ^ 1 ]. ^ 2'
			protocol: 'tests'
			returnsSingleCritiqueRuleClass: 'ReNotOptimizedIfNilRule'
			titledLike: 'ifNil:' ] ensure: [
		self removeSelector: selector from: MCPToolGetMethodTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsAllowlistedReturnInEnsureCritique [

	| selector |
	selector := #returnInEnsure.
	self removeSelector: selector from: MCPToolMethodMutationTestTarget.
	[
		self
			assertCompileForClassName: 'MCPToolMethodMutationTestTarget'
			methodSource: 'returnInEnsure [ 1 ] ensure: [ ^ 2 ]'
			protocol: 'tests'
			returnsSingleCritiqueRuleClass: 'ReReturnInEnsureRule'
			titledLike: 'return in an ensure:' ] ensure: [
		self removeSelector: selector from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsAllowlistedUnaryAccessingWithoutReturnCritique [

	| selector |
	selector := #counterValue.
	self removeSelector: selector from: MCPToolGetMethodTestTarget.
	[
		self
			assertCompileForClassName: 'MCPToolGetMethodTestTarget'
			methodSource: 'counterValue instanceCounter + 1'
			protocol: 'accessing'
			returnsSingleCritiqueRuleClass:
			'ReUnaryAccessingMethodWithoutReturnRule'
			titledLike: 'without explicit return' ] ensure: [
		self removeSelector: selector from: MCPToolGetMethodTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsAllowlistedWarningCritiques [

	| selector |
	selector := #shadowedCounter:.
	self removeSelector: selector from: MCPToolGetMethodTestTarget.
	[
		self
			assertCompileForClassName: 'MCPToolGetMethodTestTarget'
			methodSource:
			'shadowedCounter: value | instanceCounter | instanceCounter := value. ^ instanceCounter + 1'
			protocol: 'tests'
			returnsSingleCritiqueRuleClass: 'ReTempVarOverridesInstVarRule'
			titledLike: 'Outer variable shadowed' ] ensure: [
		self removeSelector: selector from: MCPToolGetMethodTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsCollectionThenDoCritique [

	| selector |
	selector := #collectionThenDoProbe:.
	self removeSelector: selector from: MCPToolGetMethodTestTarget.
	[
		self
			assertCompileForClassName: 'MCPToolGetMethodTestTarget'
			methodSource:
			'collectionThenDoProbe: collection | sum | sum := 0. (collection select: [ :each | each odd ]) do: [ :each | sum := sum + each ]. ^ sum'
			protocol: 'tests'
			returnsSingleCritiqueRuleClass: 'MCPCollectionThenDoRule'
			titledLike: MCPCollectionThenDoRule ruleName ] ensure: [
		self removeSelector: selector from: MCPToolGetMethodTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsErrorSeverityCritiquesOnly [

	| critique critiques data result |
	result := self callToolWith: (self
			           compileArgumentsForClassName:
			           'MCPToolMethodMutationTestTarget'
			           classSide: false
			           methodSource: 'instanceProtocolTarget ^ True = true'
			           protocol: 'tests').
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	critiques := data at: #critiques.
	self assert: critiques class equals: Array.
	self assert: critiques size equals: 1.
	critique := critiques first.
	self assert: (critique at: #ruleClass) equals: 'ReUsesTrueRule'.
	self assert: ((critique at: #title) includesSubstring:
			 'Uses True/False instead of true/false').
	self assert: (critique at: #description) isString.
	self deny: (critique at: #description) isEmpty.
	self assert: (critique includesKey: #start).
	self assert: (critique includesKey: #stop).
	self assert: (critique at: #start) isInteger.
	self assert: (critique at: #stop) isInteger.
	self assert: (critique at: #start) < (critique at: #stop)
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsFilterThenCollectCritique [

	| selector |
	selector := #filterThenCollectProbe:.
	self removeSelector: selector from: MCPToolGetMethodTestTarget.
	[
		self
			assertCompileForClassName: 'MCPToolGetMethodTestTarget'
			methodSource:
			'filterThenCollectProbe: collection ^ (collection select: [ :each | each odd ]) collect: [ :each | each asString ]'
			protocol: 'tests'
			returnsSingleCritiqueRuleClass: 'MCPFilterThenCollectRule'
			titledLike: MCPFilterThenCollectRule ruleName ] ensure: [
		self removeSelector: selector from: MCPToolGetMethodTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsFilteredEmptinessCritique [

	| selector |
	selector := #filteredEmptinessProbe:.
	self removeSelector: selector from: MCPToolGetMethodTestTarget.
	[
		self
			assertCompileForClassName: 'MCPToolGetMethodTestTarget'
			methodSource:
			'filteredEmptinessProbe: collection ^ (collection select: [ :each | each odd ]) isEmpty'
			protocol: 'tests'
			returnsSingleCritiqueRuleClass: 'MCPFilteredEmptinessRule'
			titledLike: MCPFilteredEmptinessRule ruleName ] ensure: [
		self removeSelector: selector from: MCPToolGetMethodTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsMessageNotUnderstoodHandlerCritique [

	| selector |
	selector := #messageNotUnderstoodProbe:.
	self removeSelector: selector from: MCPToolGetMethodTestTarget.
	[
		self
			assertCompileForClassName: 'MCPToolGetMethodTestTarget'
			methodSource:
			'messageNotUnderstoodProbe: anObject ^ [ anObject class ] on: MessageNotUnderstood do: [ :ignored | nil ]'
			protocol: 'tests'
			returnsSingleCritiqueRuleClass:
			'MCPMessageNotUnderstoodHandlerRule'
			titledLike: MCPMessageNotUnderstoodHandlerRule ruleName ] ensure: [
		self removeSelector: selector from: MCPToolGetMethodTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsNilOnlyConditionalCritique [

	| selector |
	selector := #nilOnlyConditionalProbe:.
	self removeSelector: selector from: MCPToolGetMethodTestTarget.
	[
		self
			assertCompileForClassName: 'MCPToolGetMethodTestTarget'
			methodSource:
			'nilOnlyConditionalProbe: value ^ value ifNil: [ nil ] ifNotNil: [ :present | present asString ]'
			protocol: 'tests'
			returnsSingleCritiqueRuleClass: 'MCPNilOnlyConditionalRule'
			titledLike: MCPNilOnlyConditionalRule ruleName ] ensure: [
		self removeSelector: selector from: MCPToolGetMethodTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsRedundantExplicitSelfReturnCritique [

	| selector |
	selector := #redundantSelfReturnProbe.
	self removeSelector: selector from: MCPToolMethodMutationTestTarget.
	[
		self
			assertCompileForClassName: 'MCPToolMethodMutationTestTarget'
			methodSource: 'redundantSelfReturnProbe ^ self'
			protocol: 'tests'
			returnsSingleCritiqueRuleClass: 'MCPRedundantExplicitSelfReturnRule'
			titledLike: MCPRedundantExplicitSelfReturnRule ruleName ]
		ensure: [ self removeSelector: selector from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsRespondsToUsageCritique [

	| selector |
	selector := #respondsToProbe:.
	self removeSelector: selector from: MCPToolGetMethodTestTarget.
	[
		self
			assertCompileForClassName: 'MCPToolGetMethodTestTarget'
			methodSource:
			'respondsToProbe: anObject ^ anObject respondsTo: #size'
			protocol: 'tests'
			returnsSingleCritiqueRuleClass: 'MCPRespondsToUsageRule'
			titledLike: MCPRespondsToUsageRule ruleName ] ensure: [
		self removeSelector: selector from: MCPToolGetMethodTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsSelectSizeCountCritique [

	| selector |
	selector := #selectSizeProbe:.
	self removeSelector: selector from: MCPToolGetMethodTestTarget.
	[
		self
			assertCompileForClassName: 'MCPToolGetMethodTestTarget'
			methodSource:
			'selectSizeProbe: collection ^ (collection select: [ :each | each odd ]) size'
			protocol: 'tests'
			returnsSingleCritiqueRuleClass: 'MCPSelectSizeCountRule'
			titledLike: MCPSelectSizeCountRule ruleName ] ensure: [
		self removeSelector: selector from: MCPToolGetMethodTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsSortedCollectionConversionCritique [

	| selector |
	selector := #sortedCollectionConversionProbe:.
	self removeSelector: selector from: MCPToolGetMethodTestTarget.
	[
		self
			assertCompileForClassName: 'MCPToolGetMethodTestTarget'
			methodSource:
			'sortedCollectionConversionProbe: collection ^ collection asSortedCollection asArray'
			protocol: 'tests'
			returnsSingleCritiqueRuleClass: 'MCPSortedCollectionConversionRule'
			titledLike: MCPSortedCollectionConversionRule ruleName ] ensure: [
		self removeSelector: selector from: MCPToolGetMethodTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsStructuredCommandErrorForSyntaxError [

	| error result structured |
	self
		removeSelector: #brokenMethod
		from: MCPToolMethodMutationTestTarget.
	result := self callToolWith: (self
			           compileArgumentsForClassName:
			           'MCPToolMethodMutationTestTarget'
			           classSide: false
			           methodSource: 'brokenMethod ^ 1 +'
			           protocol: 'tests').
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #action) equals: 'compile'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'CompileSyntaxError'.
	self
		assert: (error at: #className)
		equals: 'MCPToolMethodMutationTestTarget'.
	self assert: (error at: #classSide) equals: false.
	self assert: (error at: #protocol) equals: 'tests'.
	self assert: (error includesKey: #position).
	self deny: (error includesKey: #variableName).
	self deny:
		(MCPToolMethodMutationTestTarget includesSelector: #brokenMethod)
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsStructuredCommandErrorForUndeclaredVariable [

	| error result structured |
	self
		removeSelector: #brokenMethod
		from: MCPToolMethodMutationTestTarget.
	result := self callToolWith: (self
			           compileArgumentsForClassName:
			           'MCPToolMethodMutationTestTarget'
			           classSide: false
			           methodSource: 'brokenMethod ^ missingVar'
			           protocol: 'tests').
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #action) equals: 'compile'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self
		assert: (error at: #errorCode)
		equals: 'CompileUndeclaredVariable'.
	self assert:
		(self expectedUndeclaredVariableNoticeClassNames includes:
			 (error at: #causeClass)).
	self
		assert: (error at: #className)
		equals: 'MCPToolMethodMutationTestTarget'.
	self assert: (error at: #classSide) equals: false.
	self assert: (error at: #protocol) equals: 'tests'.
	self assert: (error at: #selector) equals: 'brokenMethod'.
	self assert: (error at: #variableName) equals: 'missingVar'.
	self assert: (error at: #position) equals: 16.
	self assert: ((error at: #message) includesSubstring: 'missingVar').
	self deny:
		(MCPToolMethodMutationTestTarget includesSelector: #brokenMethod)
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompilesClassSideMethod [

	| data result |
	result := self callToolWith: (self
			           compileArgumentsForClassName:
			           'MCPToolMethodMutationTestTarget'
			           classSide: true
			           methodSource: 'classAnswer ^ 7'
			           protocol: 'tests').
	data := self dataFrom: result.
	self assert: MCPToolMethodMutationTestTarget classAnswer equals: 7.
	self
		assert:
			(MCPToolMethodMutationTestTarget classSide >> #classAnswer)
				protocol name
		equals: #tests.
	self assertSuccessDataHasMethodShape: data.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompilesInstanceSideMethod [

	| data result |
	result := self callToolWith: (self
			           compileArgumentsForClassName:
			           'MCPToolMethodMutationTestTarget'
			           classSide: false
			           methodSource: 'instanceAnswer ^ 42'
			           protocol: 'tests').
	data := self dataFrom: result.
	self
		assert: MCPToolMethodMutationTestTarget new instanceAnswer
		equals: 42.
	self
		assert:
		(MCPToolMethodMutationTestTarget >> #instanceAnswer) protocol name
		equals: #tests.
	self assertSuccessDataHasMethodShape: data.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testMCPPackageMethodSourcesDoNotContainLineFeeds [

	| offenders |
	offenders := self methodSourceLineFeedOffenders.
	self
		assert: offenders isEmpty
		description: 'MCP method source must not contain Character lf: '
			, offenders printString
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testMethodFormatterUsesScopedMaximumLineLength [

	| compiledMethod formatter originalMaximum |
	compiledMethod := self class >> #testMethodFormatterUsesScopedMaximumLineLength.
	originalMaximum := EFFormatter maxLineLength.
	formatter := MCPToolCompileMethod new formatterForMethod: compiledMethod.
	self assert: formatter maxLineLength equals: 130.
	self assert: EFFormatter maxLineLength equals: originalMaximum
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testMethodToolSchemasDeclareExpectedInputs [

	| classSideProperty createPropertyNames protocolPropertyNames selectorPropertyNames |
	createPropertyNames := MCPToolCompileMethod new inputSchema
		                       properties collect: [ :each | each name ].
	selectorPropertyNames := MCPToolUpdateMethodSelector new inputSchema properties
		                         collect: [ :each | each name ].
	protocolPropertyNames := MCPToolUpdateMethodProtocol new inputSchema properties
		                         collect: [ :each | each name ].
	classSideProperty := MCPToolCompileMethod new inputSchema properties
		                     detect: [ :each | each name = 'classSide' ].
	self
		assert: createPropertyNames asArray
		equals: #( 'className' 'classSide' 'source' 'protocol' ).
	self
		assert: selectorPropertyNames asArray
		equals: #( 'className' 'classSide' 'force' 'selector' 'newSelector'
			   'permutation' 'argumentNames' 'argumentValueExpressions'
			   'packageNames' 'classNames' 'hierarchyClassNames' ).
	self
		assert: protocolPropertyNames asArray
		equals: #( 'className' 'classSide' 'force' 'selector' 'protocol' ).
	self assert: MCPToolCompileMethod new inputSchema required asSet
		equals: #( 'className' 'source' 'protocol' ) asSet.
	self assert: MCPToolUpdateMethodSelector new inputSchema required asSet
		equals: #( 'className' 'selector' 'newSelector' ) asSet.
	self assert: MCPToolUpdateMethodProtocol new inputSchema required asSet
		equals: #( 'className' 'selector' 'protocol' ) asSet.
	self assert: (classSideProperty extraProperties at: #default)
		equals: false
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testNormalizesLineEndingsBeforeCompilation [

	| normalizedSource source |
	source := 'multilineAnswer' , String lf , '| value |' , String lf
	          , 'value := 41.' , String lf , '^ value + 1'.
	self callToolWith: (self
			 compileArgumentsForClassName: 'MCPToolMethodMutationTestTarget'
			 classSide: false
			 methodSource: source
			 protocol: 'tests').
	normalizedSource := (MCPToolMethodMutationTestTarget
	                     >> #multilineAnswer) sourceCode.
	self deny: (normalizedSource includes: Character lf).
	self assert: (normalizedSource includes: Character cr).
	self
		assert: MCPToolMethodMutationTestTarget new multilineAnswer
		equals: 42
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testNormalizesLineFeedStringLiteralBeforeCompilation [

	| literal normalizedSource source |
	source := 'multilineStringAnswer' , String lf , '^ ''line one'
	          , String lf , 'line two'''.
	[
		self callToolWith: (self
				 compileArgumentsForClassName: 'MCPToolMethodMutationTestTarget'
				 classSide: false
				 methodSource: source
				 protocol: 'tests').
		normalizedSource := (MCPToolMethodMutationTestTarget
		                     >> #multilineStringAnswer) sourceCode.
		literal := MCPToolMethodMutationTestTarget new multilineStringAnswer.
		self deny: (normalizedSource includes: Character lf).
		self deny: (literal includes: Character lf).
		self assert: (normalizedSource includes: Character cr).
		self assert: (literal includes: Character cr).
		self assert: literal equals: 'line one' , String cr , 'line two' ]
		ensure: [
				self
					removeSelector: #multilineStringAnswer
					from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testReformatsMethod [

	| reformattedSource result source |
	source := 'uglyAnswer   ^   1+2'.
	result := self callToolWith: (self
			           compileArgumentsForClassName: 'MCPToolMethodMutationTestTarget'
			           classSide: false
			           methodSource: source
			           protocol: 'tests').
	reformattedSource := (MCPToolMethodMutationTestTarget >> #uglyAnswer) sourceCode.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (reformattedSource includesSubstring: '1 + 2').
	self assert: MCPToolMethodMutationTestTarget new uglyAnswer equals: 3
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testRemoveArgumentsFailsWhenRemovedArgumentIsReferenced [

	| error newSelector oldSelector result structured |
	oldSelector := ('referencedRemove:' , 'unused:') asSymbol.
	newSelector := #referencedRemove:.
	[
		self
			ensureMethodSource:
			'referencedRemove: first unused: ignored ^ ignored'
			protocol: 'tests'
			on: MCPToolMethodMutationTestTarget.
		result := self callToolWith: {
				          (#action -> 'update').
				          (#className -> 'MCPToolMethodMutationTestTarget').
				          (#classSide -> false).
				          (#selector -> oldSelector asString).
				          (#newSelector -> newSelector asString) } asDictionary.
		structured := self structuredContentFrom: result.
		error := self errorFrom: result.
		self assert: (result at: #isError).
		self assert: (structured at: #status) equals: 'error'.
		self assert: (error at: #action) equals: 'update'.
		self assert: (error at: #updateAction) equals: 'removeArguments'.
		self
			assert: (error at: #className)
			equals: 'MCPToolMethodMutationTestTarget'.
		self assert: (error at: #selector) equals: oldSelector asString.
		self assert: (error at: #newSelector) equals: newSelector asString.
		self assert:
			(MCPToolMethodMutationTestTarget includesSelector: oldSelector).
		self deny:
			(MCPToolMethodMutationTestTarget includesSelector: newSelector) ]
		ensure: [
				self
					removeSelector: oldSelector
					from: MCPToolMethodMutationTestTarget.
				self
					removeSelector: newSelector
					from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testRemoveArgumentsUpdatesSendersAndReportsAction [

	| data newSelector oldSelector result senderSource |
	oldSelector := ('keep:' , 'unused:') asSymbol.
	newSelector := #keep:.
	[
		self
			ensureMethodSource: 'keep: first unused: ignored ^ first'
			protocol: 'tests'
			on: MCPToolMethodMutationTestTarget.
		self
			ensureMethodSource:
			'callRemoveArgumentTarget ^ MCPToolMethodMutationTestTarget new keep: ''value'' unused: ''ignored'''
			protocol: 'tests'
			on: MCPToolMethodMutationTestSender.
		result := self callToolWith: {
				          (#action -> 'update').
				          (#className -> 'MCPToolMethodMutationTestTarget').
				          (#classSide -> false).
				          (#selector -> oldSelector asString).
				          (#newSelector -> newSelector asString) } asDictionary.
		data := self dataFrom: result.
		senderSource := (MCPToolMethodMutationTestSender
		                 >> #callRemoveArgumentTarget) sourceCode.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self deny:
			(MCPToolMethodMutationTestTarget includesSelector: oldSelector).
		self assert:
			(MCPToolMethodMutationTestTarget includesSelector: newSelector).
		self deny: (senderSource includesSubstring: 'unused:').
		self
			assert:
			MCPToolMethodMutationTestSender new callRemoveArgumentTarget
			equals: 'value' ] ensure: [
			self
				removeSelector: oldSelector
				from: MCPToolMethodMutationTestTarget.
			self
				removeSelector: newSelector
				from: MCPToolMethodMutationTestTarget.
			self
				removeSelector: #callRemoveArgumentTarget
				from: MCPToolMethodMutationTestSender ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testRenameCanLimitRefactoringToNamedClasses [

	self withRenameScopeFixturesDo: [ :fixtures |
			| data result senderAClass senderASource senderBClass senderBSource targetAClass targetBClass |
			result := self callToolWith: {
					          (#action -> 'update').
					          (#className -> (fixtures at: #targetAClassName)).
					          (#classSide -> false).
					          (#selector -> 'scopeSharedTarget').
					          (#newSelector -> 'scopedSharedTarget').
					          (#classNames -> {
						           (fixtures at: #targetAClassName).
						           (fixtures at: #senderAClassName) }) } asDictionary.
			data := self dataFrom: result.
			targetAClass := Smalltalk globals at:
				                (fixtures at: #targetAClassName) asSymbol.
			targetBClass := Smalltalk globals at:
				                (fixtures at: #targetBClassName) asSymbol.
			senderAClass := Smalltalk globals at:
				                (fixtures at: #senderAClassName) asSymbol.
			senderBClass := Smalltalk globals at:
				                (fixtures at: #senderBClassName) asSymbol.
			self deny: (result at: #isError ifAbsent: [ false ]).
			self deny: (targetAClass includesSelector: #scopeSharedTarget).
			self assert: (targetAClass includesSelector: #scopedSharedTarget).
			self assert: (targetBClass includesSelector: #scopeSharedTarget).
			self deny: (targetBClass includesSelector: #scopedSharedTarget).
			self assert: senderAClass new callScopedTarget equals: 'A'.
			self assert: senderBClass new callScopedTarget equals: 'B'.
			senderASource := (senderAClass >> #callScopedTarget) sourceCode.
			senderBSource := (senderBClass >> #callScopedTarget) sourceCode.
			self assert:
				(senderASource includesSubstring: 'scopedSharedTarget').
			self assert: (senderBSource includesSubstring: 'scopeSharedTarget').
			self deny: (senderBSource includesSubstring: 'scopedSharedTarget').
			self assertSuccessDataHasMethodShape: data ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testRenameCanLimitRefactoringToNamedPackages [

	self withRenameScopeFixturesDo: [ :fixtures |
			| data result senderAClass senderASource senderBClass senderBSource targetAClass targetBClass |
			result := self callToolWith: {
					          (#action -> 'update').
					          (#className -> (fixtures at: #targetAClassName)).
					          (#classSide -> false).
					          (#selector -> 'scopeSharedTarget').
					          (#newSelector -> 'scopedSharedTarget').
					          (#packageNames -> { (fixtures at: #packageAName) }) }
					          asDictionary.
			data := self dataFrom: result.
			targetAClass := Smalltalk globals at:
				                (fixtures at: #targetAClassName) asSymbol.
			targetBClass := Smalltalk globals at:
				                (fixtures at: #targetBClassName) asSymbol.
			senderAClass := Smalltalk globals at:
				                (fixtures at: #senderAClassName) asSymbol.
			senderBClass := Smalltalk globals at:
				                (fixtures at: #senderBClassName) asSymbol.
			self deny: (result at: #isError ifAbsent: [ false ]).
			self deny: (targetAClass includesSelector: #scopeSharedTarget).
			self assert: (targetAClass includesSelector: #scopedSharedTarget).
			self assert: (targetBClass includesSelector: #scopeSharedTarget).
			self deny: (targetBClass includesSelector: #scopedSharedTarget).
			self assert: senderAClass new callScopedTarget equals: 'A'.
			self assert: senderBClass new callScopedTarget equals: 'B'.
			senderASource := (senderAClass >> #callScopedTarget) sourceCode.
			senderBSource := (senderBClass >> #callScopedTarget) sourceCode.
			self assert:
				(senderASource includesSubstring: 'scopedSharedTarget').
			self assert: (senderBSource includesSubstring: 'scopeSharedTarget').
			self deny: (senderBSource includesSubstring: 'scopedSharedTarget').
			self assertSuccessDataHasMethodShape: data ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testRenameKeepsRenamedMethodCallable [

	| newSelector oldSelector result target |
	oldSelector := ('uglyRename:' , 'with:') asSymbol.
	newSelector := ('with:' , 'uglyRename:') asSymbol.
	[
		self
			ensureMethodSource:
			'uglyRename: first with: second ^ first , ''-'' , second'
			protocol: 'tests'
			on: MCPToolMethodMutationTestTarget.
		result := self callToolWith: {
				          (#action -> 'update').
				          (#className -> 'MCPToolMethodMutationTestTarget').
				          (#classSide -> false).
				          (#selector -> oldSelector asString).
				          (#newSelector -> newSelector asString).
				          (#permutation -> #( 2 1 )) } asDictionary.
		target := MCPToolMethodMutationTestTarget new.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self deny:
			(MCPToolMethodMutationTestTarget includesSelector: oldSelector).
		self assert:
			(MCPToolMethodMutationTestTarget includesSelector: newSelector).
		self
			assert: (target perform: newSelector with: 'right' with: 'left')
			equals: 'left-right' ] ensure: [
			self
				removeSelector: oldSelector
				from: MCPToolMethodMutationTestTarget.
			self
				removeSelector: newSelector
				from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testRenameReturnsStructuredErrorWhenMethodIsMissing [

	| error result structured |
	self
		removeSelector: self instanceSelector
		from: MCPToolMethodMutationTestTarget.
	result := self callToolWith: self instanceRenameArguments.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #action) equals: 'update'.
	self assert: (error at: #updateAction) equals: 'rename'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'MethodNotFound'.
	self
		assert: (error at: #className)
		equals: 'MCPToolMethodMutationTestTarget'.
	self assert: (error at: #classSide) equals: false.
	self
		assert: (error at: #selector)
		equals: self instanceSelector asString.
	self
		assert: (error at: #newSelector)
		equals: self renamedInstanceSelector asString.
	self assert: (error at: #permutation) equals: #( 2 1 ).
	self
		assert: error keys asSet
		equals:
			#( action updateAction errorClass errorCode message className
			   classSide selector newSelector permutation ) asSet
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testRenameReturnsStructuredErrorWhenScopeRequiresClassNames [

	| arguments |
	arguments := self instanceRenameArguments copy.
	arguments removeKey: #action ifAbsent: [ ].
	arguments at: #scope put: 'classes'.
	self
		should: [
				self
					callDiscoveredToolNamed: 'method_selector_update'
					withArguments: arguments ]
		raise: JRPCInvalidParameters
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testRenameReturnsStructuredErrorWhenScopedPackageIsMissing [

	| error result structured |
	result := self callToolWith: (self instanceRenameArguments copy
			           at: #packageNames put: #( 'DefinitelyMissingPackage' );
			           yourself).
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #action) equals: 'update'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'PackageNotFound'.
	self
		assert: (error at: #packageName)
		equals: 'DefinitelyMissingPackage'.
	self
		assert: (error at: #selector)
		equals: self instanceSelector asString.
	self
		assert: (error at: #newSelector)
		equals: self renamedInstanceSelector asString
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testRenameUpdatesSendersAndPermutesArguments [

	| senderSource |
	self callToolWith: self instanceRenameArguments.
	self
		assert: MCPToolMethodMutationTestSender new callInstanceTarget
		equals: 'first-second'.
	senderSource := (MCPToolMethodMutationTestSender
	                 >> #callInstanceTarget) sourceCode.
	self assert:
		(senderSource includesSubstring:
			 'with: ''second'' combine: ''first''')
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testRenamesClassSideMethodWithDefaultPermutation [

	| data result |
	result := self callToolWith: self classRenameArguments.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny:
		(MCPToolMethodMutationTestTarget classSide includesSelector:
			 self classSelector).
	self assert:
		(MCPToolMethodMutationTestTarget classSide includesSelector:
			 self renamedClassSelector).
	self
		assert: MCPToolMethodMutationTestSender new callClassTarget
		equals: 'Class-value'.
	self assertSuccessDataHasMethodShape: data.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testRenamesInstanceMethodAndReturnsStructuredData [

	| data result |
	result := self callToolWith: self instanceRenameArguments.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny: (MCPToolMethodMutationTestTarget includesSelector:
			 self instanceSelector).
	self assert: (MCPToolMethodMutationTestTarget includesSelector:
			 self renamedInstanceSelector).
	self assertSuccessDataHasMethodShape: data.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'private - calling' }
MCPToolMethodMutationTest >> toolName [

	self shouldNotImplement
]

{ #category : 'private' }
MCPToolMethodMutationTest >> withRenameScopeFixturesDo: aBlock [

	| fixtures packageAName packageBName senderAClassName senderBClassName targetAClassName targetBClassName |
	packageAName := 'MCP-Tests-MethodMutationScope-A'.
	packageBName := 'MCP-Tests-MethodMutationScope-B'.
	targetAClassName := 'MCPToolMethodMutationScopeTargetA'.
	targetBClassName := 'MCPToolMethodMutationScopeTargetB'.
	senderAClassName := 'MCPToolMethodMutationScopeSenderA'.
	senderBClassName := 'MCPToolMethodMutationScopeSenderB'.
	{
		targetAClassName.
		targetBClassName.
		senderAClassName.
		senderBClassName } do: [ :eachName |
		self removeClassNamed: eachName ].
	{
		packageAName.
		packageBName } do: [ :eachName | self removePackageNamed: eachName ].
	[
		self
			createRenameScopeFixtureClassNamed: targetAClassName
			packageName: packageAName.
		self
			createRenameScopeFixtureClassNamed: targetBClassName
			packageName: packageBName.
		self
			createRenameScopeFixtureClassNamed: senderAClassName
			packageName: packageAName.
		self
			createRenameScopeFixtureClassNamed: senderBClassName
			packageName: packageBName.
		self
			ensureMethodSource: 'scopeSharedTarget ^ ''A'''
			protocol: 'tests'
			on: (Smalltalk globals at: targetAClassName asSymbol).
		self
			ensureMethodSource: 'scopeSharedTarget ^ ''B'''
			protocol: 'tests'
			on: (Smalltalk globals at: targetBClassName asSymbol).
		self
			ensureMethodSource:
			'callScopedTarget ^ MCPToolMethodMutationScopeTargetA new scopeSharedTarget'
			protocol: 'tests'
			on: (Smalltalk globals at: senderAClassName asSymbol).
		self
			ensureMethodSource:
			'callScopedTarget ^ MCPToolMethodMutationScopeTargetB new scopeSharedTarget'
			protocol: 'tests'
			on: (Smalltalk globals at: senderBClassName asSymbol).
		fixtures := {
			            (#packageAName -> packageAName).
			            (#packageBName -> packageBName).
			            (#targetAClassName -> targetAClassName).
			            (#targetBClassName -> targetBClassName).
			            (#senderAClassName -> senderAClassName).
			            (#senderBClassName -> senderBClassName) } asDictionary.
		aBlock value: fixtures ] ensure: [
			{
				targetAClassName.
				targetBClassName.
				senderAClassName.
				senderBClassName } do: [ :eachName |
				self removeClassNamed: eachName ].
			{
				packageAName.
				packageBName } do: [ :eachName |
				self removePackageNamed: eachName ] ]
]
