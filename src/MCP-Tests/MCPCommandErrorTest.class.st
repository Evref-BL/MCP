"
Tests structured command error payloads and JSON-RPC conversion.
"
Class {
	#name : 'MCPCommandErrorTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPCommandErrorTest >> capture: aBlock [

	^ [
		  aBlock value.
		  self fail: 'Expected MCPCommandError' ]
		  on: MCPCommandError
		  do: [ :error | error ]
]

{ #category : 'tests' }
MCPCommandErrorTest >> testAClassOfTheWrongKindSaysWhatKindIsNeeded [

	{
		{ #trait. 'EvalUnits'. #InvalidTrait. 'EvalUnits is not a trait.' }.
		{ #sharedPool. 'EvalStockItem'. #InvalidSharedPool. 'EvalStockItem is not a shared pool: a pool is a subclass of SharedPool.' }.
		{ #layoutClass. 'Object'. #InvalidLayoutClass. 'Object is not a layout class: name a subclass of AbstractLayout, such as VariableLayout.' }.
		{ #critiqueRule. 'Object'. #InvalidCritiqueRule. 'Object is not a critique rule class.' }.
		{ #rewriteRule. 'Object'. #RewriteRuleClassHasNoPatterns. 'Object is not a rewrite rule. Name a subclass of ReNodeRewriteRule.' } }
		do: [ :each |
				| error |
				error := self capture: [ MCPCommandError signalWrongKind: each second role: each first details: { (#class -> 'MCPNewClass') } ].
				self assert: error errorCode equals: each third.
				self assert: error messageText equals: each fourth.
				self assert: (error structuredDetails at: #class) equals: 'MCPNewClass' ]
]

{ #category : 'tests' }
MCPCommandErrorTest >> testAClassRemovalBlockCarriesItsDetails [

	| details error |
	error := self capture: [
			         MCPCommandError signalClassRemovalBlocked: 'Did not remove EvalRect: 1 method refers to it.' details: {
					         (#classes -> #( 'EvalRect' )).
					         (#forceSupported -> true) } asDictionary ].
	details := error structuredDetails.
	self assert: error errorCode equals: #ClassRemovalBlocked.
	self assert: error messageText equals: 'Did not remove EvalRect: 1 method refers to it.'.
	self assert: (details at: #classes) equals: #( 'EvalRect' ).
	self assert: (details at: #forceSupported)
]

{ #category : 'tests' }
MCPCommandErrorTest >> testAClassSideAgainstSideInstanceIsAConflict [

	| details error |
	error := self capture: [
		         MCPCommandError signalClassSideConflict: 'EvalStockItem class' baseName: 'EvalStockItem' side: 'instance' ].
	details := error structuredDetails.
	self assert: error errorCode equals: #ClassSideConflict.
	self
		assert: error messageText
		equals: 'EvalStockItem class names the class side, but side is instance. Pass class EvalStockItem, with side class or instance.'.
	self assert: (details at: #class) equals: 'EvalStockItem'.
	self assert: (details at: #name) equals: 'EvalStockItem class'.
	self assert: (details at: #side) equals: 'instance'
]

{ #category : 'tests' }
MCPCommandErrorTest >> testAClassSideGivenToAWholeClassToolSaysWhatToName [

	{
		('class_remove'
		 ->
		 'EvalShape class is the class side of EvalShape, and goes only with its class. Name EvalShape to remove the class, or use method_remove with side class to remove class-side methods.').
		('class_update'
		 ->
		 'EvalShape class is the class side of EvalShape. class_update changes the whole class: name EvalShape, and use classSlots for class-side slots.').
		('class_create'
		 ->
		 'EvalShape class is the class side of EvalShape, which class_create makes with the class. Name EvalShape, and give class-side slots in classSlots.') }
		do: [ :each |
				| details error |
				error := self capture: [ MCPCommandError signalClassSideNamed: 'EvalShape class' baseName: 'EvalShape' for: each key ].
				details := error structuredDetails.
				self assert: error errorCode equals: #ClassSideNamed.
				self assert: error messageText equals: each value.
				self assert: (details at: #class) equals: 'EvalShape'.
				self assert: (details at: #name) equals: 'EvalShape class' ]
]

{ #category : 'tests' }
MCPCommandErrorTest >> testAGlobalVariableKeepsItsName [

	| error |
	error := self capture: [ MCPCommandError signalGlobalAlreadyExistsNamed: 'Transcript' ].
	self assert: error errorCode equals: #GlobalAlreadyExists.
	self assert: error messageText equals: 'Transcript already names a global variable. Choose another class name.'.
	self assert: (error structuredDetails at: #class) equals: 'Transcript'
]

{ #category : 'tests' }
MCPCommandErrorTest >> testAListInOneNameIsRefusedSayingToPassAnArray [

	| details error |
	error := self capture: [ MCPCommandError signalClassNameIsAList: '{"EvalShape","EvalRect"}' scope: nil details: #(  ) ].
	details := error structuredDetails.
	self assert: error errorCode equals: #ClassNameIsAList.
	self
		assert: error messageText
		equals: '{"EvalShape","EvalRect"} is a list written as one string, not a class name. Pass several names as an array of strings.'.
	self assert: (details at: #name) equals: '{"EvalShape","EvalRect"}'.
	self deny: (details includesKey: #scope)
]

{ #category : 'tests' }
MCPCommandErrorTest >> testAMethodSourceHeaderCarriesTheHeaderItsClassAndSide [

	| details error |
	error := self capture: [
			         MCPCommandError
				         signalMethodSourceHeader: 'EvalShape >> #area'
				         message: 'The source begins with EvalShape >> #area.'
				         className: 'EvalRectangle'
				         side: 'instance' ].
	details := error structuredDetails.
	self assert: error errorCode equals: #MethodSourceHeader.
	self assert: error messageText equals: 'The source begins with EvalShape >> #area.'.
	self assert: (details at: #header) equals: 'EvalShape >> #area'.
	self assert: (details at: #class) equals: 'EvalRectangle'.
	self assert: (details at: #side) equals: 'instance'
]

{ #category : 'tests' }
MCPCommandErrorTest >> testAMissingCompileTargetSaysHowToMakeIt [

	| error |
	error := self capture: [ MCPCommandError signalMissingCompileTarget: 'EvalSpike' suggestions: #(  ) ].
	self assert: error errorCode equals: #ClassNotFound.
	self assert: error messageText equals: 'Class EvalSpike does not exist. Create it with class_create, then compile into it.'.
	self assert: (error structuredDetails at: #class) equals: 'EvalSpike'.
	error := self capture: [ MCPCommandError signalMissingCompileTarget: 'EvalSpkie' suggestions: #( 'EvalSpike' ) ].
	self
		assert: error messageText
		equals: 'Class EvalSpkie does not exist. Did you mean: EvalSpike. If it is a new class, create it with class_create first.'.
	self assert: (error structuredDetails at: #suggestions) equals: #( 'EvalSpike' )
]

{ #category : 'tests' }
MCPCommandErrorTest >> testASkippedScopeEntryNamesTheKeyThatSkippedIt [

	self
		assert: (MCPCommandError
				 textForMissing: 'EvalRect'
				 role: #class
				 scope: 'scope.classes'
				 skipped: true
				 suggestions: #( 'EvalRectangle' 'EvalCircle' ))
		equals: 'Class EvalRect does not exist, so scope.classes skipped it. Did you mean: EvalRectangle, EvalCircle.'.
	self
		assert: (MCPCommandError
				 textForNotAClass: 'Transcript'
				 role: #class
				 scope: 'scope.classes'
				 skipped: true)
		equals: 'Transcript is a global variable, not a class, so scope.classes skipped it.'.
	self
		assert: (MCPCommandError
				 textForMissing: 'Eval-Txt'
				 role: #package
				 scope: 'scope.packages'
				 skipped: true
				 suggestions: #( 'Eval-Text' ))
		equals: 'Package Eval-Txt does not exist, so scope.packages skipped it. Did you mean: Eval-Text.'.
	self
		assert: (MCPCommandError textForClassNameIsAList: '["EvalShape","EvalRect"]' scope: 'scope.classes' skipped: true)
		equals:
		'["EvalShape","EvalRect"] is a list written as one string, not a class name, so scope.classes skipped it. Pass several names as an array of strings.'
]

{ #category : 'tests' }
MCPCommandErrorTest >> testAStrictScopeEntryNamesItsKeyAsItRefuses [

	| details error |
	error := self capture: [
			         MCPCommandError
				         signalMissing: 'EvalRect'
				         role: #class
				         scope: 'scope.hierarchyOf'
				         suggestions: #( 'EvalRectangle' )
				         details: #(  ) ].
	details := error structuredDetails.
	self assert: error messageText equals: 'Class EvalRect, in scope.hierarchyOf, does not exist. Did you mean: EvalRectangle.'.
	self assert: (details at: #scope) equals: 'scope.hierarchyOf'.
	error := self capture: [
			         MCPCommandError
				         signalNotAClass: 'Transcript'
				         role: #class
				         scope: 'scope.classes'
				         details: #(  ) ].
	self assert: error errorCode equals: #NotAClass.
	self assert: error messageText equals: 'Transcript, in scope.classes, is a global variable, not a class.'.
	self assert: (error structuredDetails at: #scope) equals: 'scope.classes'
]

{ #category : 'tests' }
MCPCommandErrorTest >> testClassAlreadyExistsErrorCarriesClassName [

	| details error |
	error := self capture: [ MCPCommandError signalClassAlreadyExistsNamed: 'MCPCommandErrorTestExisting' ].
	details := error structuredDetails.
	self assert: error errorCode equals: #ClassAlreadyExists.
	self assert: (details at: #class) equals: 'MCPCommandErrorTestExisting'.
	self
		assert: (details at: #message)
		equals:
		'Class MCPCommandErrorTestExisting already exists. Change it with class_update, through tool_call when class_update is not in your list: tool_call {"name": "class_update", "arguments": {"name": "MCPCommandErrorTestExisting", ...}}. class_get shows it.'.
	self deny: (details includesKey: #guidance)
]

{ #category : 'tests' }
MCPCommandErrorTest >> testEachRoleOpensWithItsNounAndAnswersItsCode [

	{
		{ #class. 'Class'. #ClassNotFound. #class }.
		{ #superclass. 'Superclass'. #SuperclassNotFound. #superclass }.
		{ #trait. 'Trait'. #TraitNotFound. #trait }.
		{ #sharedPool. 'Shared pool'. #SharedPoolNotFound. #sharedPool }.
		{ #layoutClass. 'Layout class'. #LayoutClassNotFound. #layout }.
		{ #critiqueRule. 'Critique rule'. #CritiqueRuleNotFound. #ruleClass }.
		{ #rewriteRule. 'Rewrite rule'. #RewriteRuleNotFound. #ruleClass }.
		{ #package. 'Package'. #PackageNotFound. #package } } do: [ :each |
			| details error |
			error := self capture: [
					         MCPCommandError
						         signalMissing: 'Zzqxw'
						         role: each first
						         scope: nil
						         suggestions: #(  )
						         details: { (#class -> 'MCPNewClass') } ].
			details := error structuredDetails.
			self assert: error errorCode equals: each third.
			self assert: error messageText equals: each second , ' Zzqxw does not exist.'.
			self assert: (details at: each fourth) equals: 'Zzqxw'.
			self assert: (details at: #suggestions) equals: #(  ).
			self deny: (details includesKey: #scope) ]
]

{ #category : 'tests' }
MCPCommandErrorTest >> testMissingClassErrorCarriesStructuredDetails [

	| details error suggestions |
	error := self capture: [
			         MCPCommandError
				         signalMissing: 'MCPCommandErrorTestMissing'
				         role: #class
				         scope: nil
				         suggestions: #( 'MCPCommandErrorTest' )
				         details: #(  ) ].
	details := error structuredDetails.
	suggestions := details at: #suggestions.
	self assert: error errorCode equals: #ClassNotFound.
	self assert: (details at: #errorClass) equals: 'MCPCommandError'.
	self assert: (details at: #errorCode) equals: 'ClassNotFound'.
	self assert: (details at: #class) equals: 'MCPCommandErrorTestMissing'.
	self deny: (details includesKey: #scope).
	self assert: suggestions equals: #( 'MCPCommandErrorTest' ).
	self assert: (details at: #message) equals: 'Class MCPCommandErrorTestMissing does not exist. Did you mean: MCPCommandErrorTest.'
]

{ #category : 'tests' }
MCPCommandErrorTest >> testMissingMethodErrorCarriesClassSideAndSelector [

	| details error |
	error := self capture: [
			         MCPCommandError
				         signalMissingMethod: 'mcpDefinitelyMissingSelectorForErrorTest'
				         in: (self classNamed: 'MCPToolGetMethodTestTarget') classSide ].
	details := error structuredDetails.
	self assert: error errorCode equals: #MethodNotFound.
	self assert: (details at: #errorClass) equals: 'MCPCommandError'.
	self assert: (details at: #errorCode) equals: 'MethodNotFound'.
	self assert: (details at: #class) equals: 'MCPToolGetMethodTestTarget'.
	self assert: (details at: #side) equals: 'class'.
	self assert: (details at: #selector) equals: 'mcpDefinitelyMissingSelectorForErrorTest'.
	self assert: details keys asSet equals: #( errorClass errorCode message class side selector ) asSet.
	self
		assert: (details at: #message)
		equals: 'Method MCPToolGetMethodTestTarget class>>mcpDefinitelyMissingSelectorForErrorTest does not exist.'
]

{ #category : 'tests' }
MCPCommandErrorTest >> testMissingMethodErrorSuggestsFirstExactSuperclassMatch [

	| details error suggestions |
	error := self capture: [ MCPCommandError signalMissingMethod: 'yourself' in: (self classNamed: 'MCPToolGetMethodTestTarget') ].
	details := error structuredDetails.
	suggestions := details at: #suggestions.
	self assert: error errorCode equals: #MethodNotFound.
	self assert: suggestions size equals: 1.
	self assert: (suggestions first at: #class) equals: 'Object'.
	self assert: (suggestions first at: #side) equals: 'instance'.
	self assert: (suggestions first at: #selector) equals: 'yourself'.
	self assert: ((details at: #message) includesSubstring: 'Exact matches: Object>>yourself')
]

{ #category : 'tests' }
MCPCommandErrorTest >> testMissingMethodErrorSuggestsOnlyExactOppositeSideAndSuperclassMatches [

	| details error suggestions |
	error := self capture: [
		         MCPCommandError signalMissingMethod: 'readClassSide' in: (self classNamed: 'MCPToolGetMethodTestTarget') ].
	details := error structuredDetails.
	suggestions := details at: #suggestions.
	self assert: error errorCode equals: #MethodNotFound.
	self assert: suggestions size equals: 1.
	self assert: (suggestions first at: #class) equals: 'MCPToolGetMethodTestTarget'.
	self assert: (suggestions first at: #side) equals: 'class'.
	self assert: (suggestions first at: #selector) equals: 'readClassSide'.
	self assert: ((details at: #message) includesSubstring: 'Exact matches: MCPToolGetMethodTestTarget class>>readClassSide')
]

{ #category : 'tests' }
MCPCommandErrorTest >> testMissingPackageErrorCarriesPackageName [

	| details error suggestions |
	error := self capture: [ MCPImageLookup packageNamed: 'MCP-Tests-Missing' ].
	details := error structuredDetails.
	suggestions := details at: #suggestions.
	self assert: error errorCode equals: #PackageNotFound.
	self assert: (details at: #errorClass) equals: 'MCPCommandError'.
	self assert: (details at: #errorCode) equals: 'PackageNotFound'.
	self assert: (details at: #package) equals: 'MCP-Tests-Missing'.
	self deny: (details includesKey: #scope).
	self assert: suggestions size <= 5.
	self assert: ((details at: #message) beginsWith: 'Package MCP-Tests-Missing does not exist.')
]

{ #category : 'tests' }
MCPCommandErrorTest >> testMissingSuperclassErrorCarriesSuperclassName [

	| details error |
	error := self capture: [
		         MCPImageLookup classNamed: 'MCPMissingSuperclass' role: #superclass details: { (#class -> 'MCPNewClass') } ].
	details := error structuredDetails.
	self assert: error errorCode equals: #SuperclassNotFound.
	self assert: (details at: #class) equals: 'MCPNewClass'.
	self assert: (details at: #superclass) equals: 'MCPMissingSuperclass'.
	self assert: (details includesKey: #suggestions).
	self assert: ((details at: #message) beginsWith: 'Superclass MCPMissingSuperclass does not exist.')
]

{ #category : 'tests' }
MCPCommandErrorTest >> testMissingTagErrorCarriesTagAndClassName [

	| details error |
	error := self capture: [
		         MCPCommandError signalMissingTag: 'MissingTag' packageName: 'MCP-Tests' forClassNamed: 'MCPCommandErrorTestTarget' ].
	details := error structuredDetails.
	self assert: error errorCode equals: #TagNotFound.
	self assert: (details at: #class) equals: 'MCPCommandErrorTestTarget'.
	self assert: (details at: #package) equals: 'MCP-Tests'.
	self assert: (details at: #tag) equals: 'MissingTag'
]
