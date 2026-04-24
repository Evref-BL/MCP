Class {
	#name : 'MCPToolEditMethodTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'private - calling' }
MCPToolEditMethodTest >> aroundToolCall: aBlock [

	^ self withoutEpiceaDuring: aBlock
]

{ #category : 'private' }
MCPToolEditMethodTest >> assertCompileForClassName: aClassName methodSource: aMethodSource protocol: aProtocol returnsSingleCritiqueRuleClass: aRuleClassName titledLike: aSubstring [

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
MCPToolEditMethodTest >> assertSuccessDataHasMethodShape: data [

	self
		assert: data keys asSet
		equals:
			#( 'selector' 'className' 'side' 'packageName' 'isExtension'
			   'protocol' 'source' ) asSet.
	self assert: (data at: #className) isString.
	self assert: (data at: #selector) isString.
	self assert:
		((data at: #side) = 'instance' or: [ (data at: #side) = 'class' ]).
	self assert: (data at: #packageName) isString.
	self assert:
		((data at: #isExtension) = true or: [
			 (data at: #isExtension) = false ]).
	self assert: (data at: #protocol) isString.
	self assert: (data at: #source) isString.
	self deny: (data at: #source) isEmpty
]

{ #category : 'private' }
MCPToolEditMethodTest >> classChangeArguments [

	^ {
		  (#operation -> 'changeProtocol').
		  (#className -> 'MCPToolEditMethodTestTarget').
		  (#classSide -> true).
		  (#selector -> self classProtocolSelector asString).
		  (#protocol -> 'instance creation') } asDictionary
]

{ #category : 'private' }
MCPToolEditMethodTest >> classProtocolSelector [

	^ #classProtocolTarget
]

{ #category : 'private' }
MCPToolEditMethodTest >> classRenameArguments [

	^ {
		  (#operation -> 'rename').
		  (#className -> 'MCPToolEditMethodTestTarget').
		  (#classSide -> true).
		  (#selector -> self classSelector asString).
		  (#newSelector -> self renamedClassSelector asString) }
		  asDictionary
]

{ #category : 'private' }
MCPToolEditMethodTest >> classSelector [

	^ ('build' , 'Value:') asSymbol
]

{ #category : 'private' }
MCPToolEditMethodTest >> compileArgumentsForClassName: aClassName classSide: aBoolean methodSource: aMethodSource protocol: aProtocol [

	^ {
		  (#operation -> 'compile').
		  (#className -> aClassName).
		  (#classSide -> aBoolean).
		  (#methodSource -> aMethodSource).
		  (#protocol -> aProtocol) } asDictionary
]

{ #category : 'private' }
MCPToolEditMethodTest >> createRenameScopeFixtureClassNamed: aClassName packageName: aPackageName [

	self withoutEpiceaDuring: [
		| builder |
		builder := Object << aClassName asSymbol.
		builder package: aPackageName.
		builder install ]
]

{ #category : 'private' }
MCPToolEditMethodTest >> extensionChangeArguments [

	^ {
		  (#operation -> 'changeProtocol').
		  (#className -> 'MCPToolEditMethodTestTarget').
		  (#classSide -> false).
		  (#selector -> self extensionProtocolSelector asString).
		  (#protocol -> 'tests') } asDictionary
]

{ #category : 'private' }
MCPToolEditMethodTest >> extensionProtocolSelector [

	^ #extensionProtocolTarget
]

{ #category : 'private' }
MCPToolEditMethodTest >> instanceChangeArguments [

	^ {
		  (#operation -> 'changeProtocol').
		  (#className -> 'MCPToolEditMethodTestTarget').
		  (#classSide -> false).
		  (#selector -> self instanceProtocolSelector asString).
		  (#protocol -> 'accessing') } asDictionary
]

{ #category : 'private' }
MCPToolEditMethodTest >> instanceProtocolSelector [

	^ #instanceProtocolTarget
]

{ #category : 'private' }
MCPToolEditMethodTest >> instanceRenameArguments [

	^ {
		  (#operation -> 'rename').
		  (#className -> 'MCPToolEditMethodTestTarget').
		  (#classSide -> false).
		  (#selector -> self instanceSelector asString).
		  (#newSelector -> self renamedInstanceSelector asString).
		  (#permutation -> #( 2 1 )) } asDictionary
]

{ #category : 'private' }
MCPToolEditMethodTest >> instanceSelector [

	^ ('combine:' , 'with:') asSymbol
]

{ #category : 'private' }
MCPToolEditMethodTest >> renamedClassSelector [

	^ ('make' , 'Value:') asSymbol
]

{ #category : 'private' }
MCPToolEditMethodTest >> renamedInstanceSelector [

	^ ('with:' , 'combine:') asSymbol
]

{ #category : 'private' }
MCPToolEditMethodTest >> restoreFixtureMethods [

	self
		removeSelector: #instanceAnswer
		from: MCPToolEditMethodTestTarget.
	self
		removeSelector: #classAnswer
		from: MCPToolEditMethodTestTarget classSide.
	self
		removeSelector: #multilineAnswer
		from: MCPToolEditMethodTestTarget.
	self removeSelector: #uglyAnswer from: MCPToolEditMethodTestTarget.
	self
		removeSelector: self instanceSelector
		from: MCPToolEditMethodTestTarget.
	self
		removeSelector: self renamedInstanceSelector
		from: MCPToolEditMethodTestTarget.
	self
		removeSelector: self classSelector
		from: MCPToolEditMethodTestTarget classSide.
	self
		removeSelector: self renamedClassSelector
		from: MCPToolEditMethodTestTarget classSide.
	self
		removeSelector: self instanceProtocolSelector
		from: MCPToolEditMethodTestTarget.
	self
		removeSelector: self classProtocolSelector
		from: MCPToolEditMethodTestTarget classSide.
	self
		removeSelector: self extensionProtocolSelector
		from: MCPToolEditMethodTestTarget.
	self
		removeSelector: #callInstanceTarget
		from: MCPToolEditMethodTestSender.
	self
		removeSelector: #callClassTarget
		from: MCPToolEditMethodTestSender.
	self
		ensureMethodSource:
		'combine: first with: second ^ first , ''-'' , second'
		protocol: 'tests'
		on: MCPToolEditMethodTestTarget.
	self
		ensureMethodSource: 'buildValue: aString ^ ''Class-'' , aString'
		protocol: 'tests'
		on: MCPToolEditMethodTestTarget classSide.
	self
		ensureMethodSource: 'instanceProtocolTarget ^ 41'
		protocol: 'tests'
		on: MCPToolEditMethodTestTarget.
	self
		ensureMethodSource: 'classProtocolTarget ^ 7'
		protocol: 'tests'
		on: MCPToolEditMethodTestTarget classSide.
	self
		ensureMethodSource: 'extensionProtocolTarget ^ 99'
		protocol: '*MCP-Tests-Resources-Extensions'
		on: MCPToolEditMethodTestTarget.
	self
		ensureMethodSource:
		'callInstanceTarget ^ MCPToolEditMethodTestTarget new combine: ''first'' with: ''second'''
		protocol: 'tests'
		on: MCPToolEditMethodTestSender.
	self
		ensureMethodSource:
		'callClassTarget ^ MCPToolEditMethodTestTarget buildValue: ''value'''
		protocol: 'tests'
		on: MCPToolEditMethodTestSender
]

{ #category : 'running' }
MCPToolEditMethodTest >> setUp [

	super setUp.
	self restoreFixtureMethods
]

{ #category : 'running' }
MCPToolEditMethodTest >> tearDown [

	self restoreFixtureMethods.
	super tearDown
]

{ #category : 'tests' }
MCPToolEditMethodTest >> testChangeProtocolReturnsStructuredErrorWhenMethodIsMissing [

	| error result structured |
	self
		removeSelector: self instanceProtocolSelector
		from: MCPToolEditMethodTestTarget.
	result := self callToolWith: self instanceChangeArguments.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #operation) equals: 'changeProtocol'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'MethodNotFound'.
	self
		assert: (error at: #className)
		equals: 'MCPToolEditMethodTestTarget'.
	self assert: (error at: #classSide) equals: false.
	self
		assert: (error at: #selector)
		equals: self instanceProtocolSelector asString.
	self assert: (error at: #protocol) equals: 'accessing'.
	self
		assert: error keys asSet
		equals:
			#( operation errorClass errorCode message className classSide
			   selector protocol ) asSet
]

{ #category : 'tests' }
MCPToolEditMethodTest >> testChangesClassSideMethodProtocol [

	| data result |
	result := self callToolWith: self classChangeArguments.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert:
			(MCPToolEditMethodTestTarget classSide
			 >> self classProtocolSelector) protocol name asString
		equals: 'instance creation'.
	self assertSuccessDataHasMethodShape: data.
	self
		assert: (data at: #className)
		equals: 'MCPToolEditMethodTestTarget'.
	self assert: (data at: #side) equals: 'class'.
	self
		assert: (data at: #selector)
		equals: self classProtocolSelector asString.
	self assert: (data at: #protocol) equals: 'instance creation'.
	self assert: (data at: #isExtension) equals: false
]

{ #category : 'tests' }
MCPToolEditMethodTest >> testChangesInstanceSideMethodProtocol [

	| data result |
	result := self callToolWith: self instanceChangeArguments.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert:
			(MCPToolEditMethodTestTarget >> self instanceProtocolSelector)
				protocol name asString
		equals: 'accessing'.
	self assertSuccessDataHasMethodShape: data.
	self
		assert: (data at: #className)
		equals: 'MCPToolEditMethodTestTarget'.
	self assert: (data at: #side) equals: 'instance'.
	self
		assert: (data at: #selector)
		equals: self instanceProtocolSelector asString.
	self assert: (data at: #protocol) equals: 'accessing'.
	self assert: (data at: #isExtension) equals: false
]

{ #category : 'tests' }
MCPToolEditMethodTest >> testChangingExtensionMethodProtocolUpdatesPackageMetadata [

	| data result |
	result := self callToolWith: self extensionChangeArguments.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert:
			(MCPToolEditMethodTestTarget >> self extensionProtocolSelector)
				protocol name asString
		equals: 'tests'.
	self assertSuccessDataHasMethodShape: data.
	self
		assert: (data at: #className)
		equals: 'MCPToolEditMethodTestTarget'.
	self assert: (data at: #side) equals: 'instance'.
	self
		assert: (data at: #selector)
		equals: self extensionProtocolSelector asString.
	self assert: (data at: #protocol) equals: 'tests'.
	self assert: ((data at: #source) includesSubstring:
			 self extensionProtocolSelector asString)
]

{ #category : 'tests' }
MCPToolEditMethodTest >> testCompileDefaultsToInstanceSideWhenClassSideIsOmitted [

	| data result |
	result := self callToolWith: {
			          (#operation -> 'compile').
			          (#className -> 'MCPToolEditMethodTestTarget').
			          (#methodSource -> 'instanceAnswer ^ 42').
			          (#protocol -> 'tests') } asDictionary.
	data := self dataFrom: result.
	self
		assert: MCPToolEditMethodTestTarget new instanceAnswer
		equals: 42.
	self deny: (MCPToolEditMethodTestTarget classSide includesSelector:
			 #instanceAnswer).
	self assertSuccessDataHasMethodShape: data.
	self assert: (data at: #side) equals: 'instance'
]

{ #category : 'tests' }
MCPToolEditMethodTest >> testCompileReturnsAllowlistedExcessiveArgumentsCritique [

	| selector |
	selector := #argumentHeavyMethod:with:with:with:with:.
	self removeSelector: selector from: MCPToolEditMethodTestTarget.
	[
	self
		assertCompileForClassName: 'MCPToolEditMethodTestTarget'
		methodSource:
		'argumentHeavyMethod: first with: second with: third with: fourth with: fifth ^ first + second + third + fourth + fifth'
		protocol: 'tests'
		returnsSingleCritiqueRuleClass: 'ReExcessiveArgumentsRule'
		titledLike: 'Excessive number of arguments' ] ensure: [
		self removeSelector: selector from: MCPToolEditMethodTestTarget ]
]

{ #category : 'tests' }
MCPToolEditMethodTest >> testCompileReturnsAllowlistedMissingSuperSendsCritique [

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
MCPToolEditMethodTest >> testCompileReturnsAllowlistedReturnInEnsureCritique [

	| selector |
	selector := #returnInEnsure.
	self removeSelector: selector from: MCPToolEditMethodTestTarget.
	[
	self
		assertCompileForClassName: 'MCPToolEditMethodTestTarget'
		methodSource: 'returnInEnsure [ 1 ] ensure: [ ^ 2 ]'
		protocol: 'tests'
		returnsSingleCritiqueRuleClass: 'ReReturnInEnsureRule'
		titledLike: 'return in an ensure:' ] ensure: [
		self removeSelector: selector from: MCPToolEditMethodTestTarget ]
]

{ #category : 'tests' }
MCPToolEditMethodTest >> testCompileReturnsAllowlistedUnaryAccessingWithoutReturnCritique [

	| selector |
	selector := #counterValue.
	self removeSelector: selector from: MCPToolInspectMethodTestTarget.
	[
	self
		assertCompileForClassName: 'MCPToolInspectMethodTestTarget'
		methodSource: 'counterValue instanceCounter + 1'
		protocol: 'accessing'
		returnsSingleCritiqueRuleClass:
		'ReUnaryAccessingMethodWithoutReturnRule'
		titledLike: 'without explicit return' ] ensure: [
		self removeSelector: selector from: MCPToolInspectMethodTestTarget ]
]

{ #category : 'tests' }
MCPToolEditMethodTest >> testCompileReturnsAllowlistedWarningCritiques [

	| selector |
	selector := #shadowedCounter:.
	self removeSelector: selector from: MCPToolInspectMethodTestTarget.
	[
	self
		assertCompileForClassName: 'MCPToolInspectMethodTestTarget'
		methodSource:
		'shadowedCounter: value | instanceCounter | instanceCounter := value. ^ instanceCounter + 1'
		protocol: 'tests'
		returnsSingleCritiqueRuleClass: 'ReTempVarOverridesInstVarRule'
		titledLike: 'Outer variable shadowed' ] ensure: [
		self removeSelector: selector from: MCPToolInspectMethodTestTarget ]
]

{ #category : 'tests' }
MCPToolEditMethodTest >> testCompileReturnsErrorSeverityCritiquesOnly [

	| critique critiques data result |
	result := self callToolWith: (self
			           compileArgumentsForClassName:
			           'MCPToolEditMethodTestTarget'
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
MCPToolEditMethodTest >> testCompileReturnsStructuredCommandErrorForUndeclaredVariable [

	| error result structured |
	self removeSelector: #brokenMethod from: MCPToolEditMethodTestTarget.
	result := self callToolWith: (self
			           compileArgumentsForClassName:
			           'MCPToolEditMethodTestTarget'
			           classSide: false
			           methodSource: 'brokenMethod ^ missingVar'
			           protocol: 'tests').
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #operation) equals: 'compile'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self
		assert: (error at: #errorCode)
		equals: 'CompileUndeclaredVariable'.
	self
		assert: (error at: #causeClass)
		equals: 'OCUndeclaredVariableWarning'.
	self
		assert: (error at: #className)
		equals: 'MCPToolEditMethodTestTarget'.
	self assert: (error at: #classSide) equals: false.
	self assert: (error at: #protocol) equals: 'tests'.
	self assert: (error at: #selector) equals: 'brokenMethod'.
	self assert: (error at: #variableName) equals: 'missingVar'.
	self assert: (error at: #position) equals: 16.
	self assert: ((error at: #message) includesSubstring: 'missingVar').
	self deny:
		(MCPToolEditMethodTestTarget includesSelector: #brokenMethod)
]

{ #category : 'tests' }
MCPToolEditMethodTest >> testCompilesClassSideMethod [

	| data result |
	result := self callToolWith: (self
			           compileArgumentsForClassName:
			           'MCPToolEditMethodTestTarget'
			           classSide: true
			           methodSource: 'classAnswer ^ 7'
			           protocol: 'tests').
	data := self dataFrom: result.
	self assert: MCPToolEditMethodTestTarget classAnswer equals: 7.
	self
		assert:
		(MCPToolEditMethodTestTarget classSide >> #classAnswer) protocol
			name
		equals: #tests.
	self assertSuccessDataHasMethodShape: data.
	self
		assert: (data at: #className)
		equals: 'MCPToolEditMethodTestTarget'.
	self assert: (data at: #side) equals: 'class'.
	self assert: (data at: #selector) equals: 'classAnswer'.
	self assert: (data at: #protocol) equals: 'tests'.
	self assert: (data at: #isExtension) equals: false
]

{ #category : 'tests' }
MCPToolEditMethodTest >> testCompilesInstanceSideMethod [

	| data result |
	result := self callToolWith: (self
			           compileArgumentsForClassName:
			           'MCPToolEditMethodTestTarget'
			           classSide: false
			           methodSource: 'instanceAnswer ^ 42'
			           protocol: 'tests').
	data := self dataFrom: result.
	self
		assert: MCPToolEditMethodTestTarget new instanceAnswer
		equals: 42.
	self
		assert:
		(MCPToolEditMethodTestTarget >> #instanceAnswer) protocol name
		equals: #tests.
	self assertSuccessDataHasMethodShape: data.
	self
		assert: (data at: #className)
		equals: 'MCPToolEditMethodTestTarget'.
	self assert: (data at: #side) equals: 'instance'.
	self assert: (data at: #selector) equals: 'instanceAnswer'.
	self assert: (data at: #protocol) equals: 'tests'.
	self assert: (data at: #isExtension) equals: false
]

{ #category : 'tests' }
MCPToolEditMethodTest >> testNormalizesLineEndingsBeforeCompilation [

	| normalizedSource source |
	source := 'multilineAnswer' , String lf , '| value |' , String lf
	          , 'value := 41.' , String lf , '^ value + 1'.
	self callToolWith: (self
			 compileArgumentsForClassName: 'MCPToolEditMethodTestTarget'
			 classSide: false
			 methodSource: source
			 protocol: 'tests').
	normalizedSource := (MCPToolEditMethodTestTarget >> #multilineAnswer)
		                    sourceCode.
	self deny: (normalizedSource includes: Character lf).
	self assert: (normalizedSource includes: Character cr).
	self
		assert: MCPToolEditMethodTestTarget new multilineAnswer
		equals: 42
]

{ #category : 'tests' }
MCPToolEditMethodTest >> testReformatsMethod [

	| data reformattedSource result source |
	source := 'uglyAnswer   ^   1+2'.
	result := self callToolWith: (self
			           compileArgumentsForClassName:
			           'MCPToolEditMethodTestTarget'
			           classSide: false
			           methodSource: source
			           protocol: 'tests').
	data := self dataFrom: result.
	reformattedSource := (MCPToolEditMethodTestTarget >> #uglyAnswer)
		                     sourceCode.
	self assert: (data at: #source) equals: reformattedSource.
	self assert: (reformattedSource includesSubstring: '1 + 2').
	self assert: MCPToolEditMethodTestTarget new uglyAnswer equals: 3
]

{ #category : 'tests' }
MCPToolEditMethodTest >> testRenameCanLimitRefactoringToNamedClasses [

	self withRenameScopeFixturesDo: [ :fixtures |
		| data result senderAClass senderASource senderBClass senderBSource targetAClass targetBClass |
		result := self callToolWith: {
				          (#operation -> 'rename').
				          (#className -> (fixtures at: #targetAClassName)).
				          (#classSide -> false).
				          (#selector -> 'scopeSharedTarget').
				          (#newSelector -> 'scopedSharedTarget').
				          (#scope -> 'classes').
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
		self assert: (senderASource includesSubstring: 'scopedSharedTarget').
		self assert: (senderBSource includesSubstring: 'scopeSharedTarget').
		self deny: (senderBSource includesSubstring: 'scopedSharedTarget').
		self assertSuccessDataHasMethodShape: data.
		self assert: (data at: #selector) equals: 'scopedSharedTarget'.
		self
			assert: (data at: #packageName)
			equals: (fixtures at: #packageAName) ]
]

{ #category : 'tests' }
MCPToolEditMethodTest >> testRenameCanLimitRefactoringToNamedPackages [

	self withRenameScopeFixturesDo: [ :fixtures |
		| data result senderAClass senderASource senderBClass senderBSource targetAClass targetBClass |
		result := self callToolWith: {
				          (#operation -> 'rename').
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
		self assert: (senderASource includesSubstring: 'scopedSharedTarget').
		self assert: (senderBSource includesSubstring: 'scopeSharedTarget').
		self deny: (senderBSource includesSubstring: 'scopedSharedTarget').
		self assertSuccessDataHasMethodShape: data.
		self assert: (data at: #selector) equals: 'scopedSharedTarget'.
		self
			assert: (data at: #packageName)
			equals: (fixtures at: #packageAName) ]
]

{ #category : 'tests' }
MCPToolEditMethodTest >> testRenameReturnsFormattedSourceForRenamedMethod [

	| data newSelector oldSelector renamedSource result |
	oldSelector := ('uglyRename:' , 'with:') asSymbol.
	newSelector := ('with:' , 'uglyRename:') asSymbol.
	[
	self
		ensureMethodSource:
		'uglyRename: first  with:second ^first,''-'',second'
		protocol: 'tests'
		on: MCPToolEditMethodTestTarget.
	result := self callToolWith: {
			          (#operation -> 'rename').
			          (#className -> 'MCPToolEditMethodTestTarget').
			          (#classSide -> false).
			          (#selector -> oldSelector asString).
			          (#newSelector -> newSelector asString).
			          (#permutation -> #( 2 1 )) } asDictionary.
	data := self dataFrom: result.
	renamedSource := (MCPToolEditMethodTestTarget >> newSelector)
		                 sourceCode.
	self assert: (data at: #source) equals: renamedSource.
	self assert:
		(renamedSource includesSubstring: 'with: second uglyRename: first').
	self assert:
		(renamedSource includesSubstring: '^ first , ''-'' , second') ]
		ensure: [
			self removeSelector: oldSelector from: MCPToolEditMethodTestTarget.
			self removeSelector: newSelector from: MCPToolEditMethodTestTarget ]
]

{ #category : 'tests' }
MCPToolEditMethodTest >> testRenameReturnsStructuredErrorWhenMethodIsMissing [

	| error result structured |
	self
		removeSelector: self instanceSelector
		from: MCPToolEditMethodTestTarget.
	result := self callToolWith: self instanceRenameArguments.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #operation) equals: 'rename'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'MethodNotFound'.
	self
		assert: (error at: #className)
		equals: 'MCPToolEditMethodTestTarget'.
	self assert: (error at: #classSide) equals: false.
	self
		assert: (error at: #selector)
		equals: self instanceSelector asString.
	self
		assert: (error at: #newSelector)
		equals: self renamedInstanceSelector asString.
	self
		assert: error keys asSet
		equals:
			#( operation errorClass errorCode message className classSide
			   selector newSelector ) asSet
]

{ #category : 'tests' }
MCPToolEditMethodTest >> testRenameReturnsStructuredErrorWhenScopeRequiresClassNames [

	self
		should: [
			self callToolWith: (self instanceRenameArguments copy
					 at: #scope put: 'classes';
					 yourself) ]
		raise: JRPCInvalidParameters
]

{ #category : 'tests' }
MCPToolEditMethodTest >> testRenameReturnsStructuredErrorWhenScopedPackageIsMissing [

	| error result structured |
	result := self callToolWith: (self instanceRenameArguments copy
			           at: #packageNames put: #( 'DefinitelyMissingPackage' );
			           yourself).
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #operation) equals: 'rename'.
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
MCPToolEditMethodTest >> testRenameUpdatesSendersAndPermutesArguments [

	| senderSource |
	self callToolWith: self instanceRenameArguments.
	self
		assert: MCPToolEditMethodTestSender new callInstanceTarget
		equals: 'first-second'.
	senderSource := (MCPToolEditMethodTestSender >> #callInstanceTarget)
		                sourceCode.
	self assert:
		(senderSource includesSubstring:
			 'with: ''second'' combine: ''first''')
]

{ #category : 'tests' }
MCPToolEditMethodTest >> testRenamesClassSideMethodWithDefaultPermutation [

	| data result |
	result := self callToolWith: self classRenameArguments.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny: (MCPToolEditMethodTestTarget classSide includesSelector:
			 self classSelector).
	self assert:
		(MCPToolEditMethodTestTarget classSide includesSelector:
			 self renamedClassSelector).
	self
		assert: MCPToolEditMethodTestSender new callClassTarget
		equals: 'Class-value'.
	self assertSuccessDataHasMethodShape: data.
	self
		assert: (data at: #className)
		equals: 'MCPToolEditMethodTestTarget'.
	self assert: (data at: #side) equals: 'class'.
	self
		assert: (data at: #selector)
		equals: self renamedClassSelector asString.
	self assert: (data at: #protocol) equals: 'tests'.
	self assert: (data at: #isExtension) equals: false
]

{ #category : 'tests' }
MCPToolEditMethodTest >> testRenamesInstanceMethodAndReturnsStructuredData [

	| data result |
	result := self callToolWith: self instanceRenameArguments.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny:
		(MCPToolEditMethodTestTarget includesSelector: self instanceSelector).
	self assert: (MCPToolEditMethodTestTarget includesSelector:
			 self renamedInstanceSelector).
	self assertSuccessDataHasMethodShape: data.
	self
		assert: (data at: #className)
		equals: 'MCPToolEditMethodTestTarget'.
	self assert: (data at: #side) equals: 'instance'.
	self
		assert: (data at: #selector)
		equals: self renamedInstanceSelector asString.
	self assert: (data at: #protocol) equals: 'tests'.
	self assert: (data at: #isExtension) equals: false
]

{ #category : 'tests' }
MCPToolEditMethodTest >> testToolRequiresOperationAndClassNameInSchema [

	| classSideProperty |
	classSideProperty := MCPToolEditMethod new inputSchema properties
		                     detect: [ :each | each name = 'classSide' ].
	self
		assert: MCPToolEditMethod new inputSchema required asSet
		equals: #( 'operation' 'className' ) asSet.
	self
		assert: (classSideProperty extraProperties at: #default)
		equals: false
]

{ #category : 'private - calling' }
MCPToolEditMethodTest >> toolName [

	^ 'edit-method'
]

{ #category : 'private' }
MCPToolEditMethodTest >> withRenameScopeFixturesDo: aBlock [

	| fixtures packageAName packageBName senderAClassName senderBClassName targetAClassName targetBClassName |
	packageAName := 'MCP-Tests-EditMethodScope-A'.
	packageBName := 'MCP-Tests-EditMethodScope-B'.
	targetAClassName := 'MCPToolEditMethodScopeTargetA'.
	targetBClassName := 'MCPToolEditMethodScopeTargetB'.
	senderAClassName := 'MCPToolEditMethodScopeSenderA'.
	senderBClassName := 'MCPToolEditMethodScopeSenderB'.
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
		'callScopedTarget ^ MCPToolEditMethodScopeTargetA new scopeSharedTarget'
		protocol: 'tests'
		on: (Smalltalk globals at: senderAClassName asSymbol).
	self
		ensureMethodSource:
		'callScopedTarget ^ MCPToolEditMethodScopeTargetB new scopeSharedTarget'
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
			packageBName } do: [ :eachName | self removePackageNamed: eachName ] ]
]
