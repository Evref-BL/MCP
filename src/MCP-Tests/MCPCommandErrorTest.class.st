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
		{ #trait. 'ZooDiet'. #InvalidTrait. 'ZooDiet is not a trait.' }.
		{ #sharedPool. 'ZooLion'. #InvalidSharedPool. 'ZooLion is not a shared pool: a pool is a subclass of SharedPool.' }.
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
			         MCPCommandError signalClassRemovalBlocked: 'Did not remove ZooLion: 1 method refers to it.' details: {
					         (#classes -> #( 'ZooLion' )).
					         (#forceSupported -> true) } asDictionary ].
	details := error structuredDetails.
	self assert: error errorCode equals: #ClassRemovalBlocked.
	self assert: error messageText equals: 'Did not remove ZooLion: 1 method refers to it.'.
	self assert: (details at: #classes) equals: #( 'ZooLion' ).
	self assert: (details at: #forceSupported)
]

{ #category : 'tests' }
MCPCommandErrorTest >> testAClassSideAgainstSideInstanceIsAConflict [

	| details error |
	error := self capture: [ MCPCommandError signalClassSideConflict: 'ZooLion class' baseName: 'ZooLion' side: 'instance' ].
	details := error structuredDetails.
	self assert: error errorCode equals: #ClassSideConflict.
	self
		assert: error messageText
		equals: 'ZooLion class names the class side, but side is instance. Pass class ZooLion, with side class or instance.'.
	self assert: (details at: #class) equals: 'ZooLion'.
	self assert: (details at: #name) equals: 'ZooLion class'.
	self assert: (details at: #side) equals: 'instance'
]

{ #category : 'tests' }
MCPCommandErrorTest >> testAClassSideGivenToAWholeClassToolSaysWhatToName [

	{
		('class_remove'
		 ->
		 'ZooAnimal class is the class side of ZooAnimal, and goes only with its class. Name ZooAnimal to remove the class, or use method_remove with side class to remove class-side methods.').
		('class_update'
		 ->
		 'ZooAnimal class is the class side of ZooAnimal. class_update changes the whole class: name ZooAnimal, and use classSlots for class-side slots.').
		('class_create'
		 ->
		 'ZooAnimal class is the class side of ZooAnimal, which class_create makes with the class. Name ZooAnimal, and give class-side slots in classSlots.') }
		do: [ :each |
				| details error |
				error := self capture: [ MCPCommandError signalClassSideNamed: 'ZooAnimal class' baseName: 'ZooAnimal' for: each key ].
				details := error structuredDetails.
				self assert: error errorCode equals: #ClassSideNamed.
				self assert: error messageText equals: each value.
				self assert: (details at: #class) equals: 'ZooAnimal'.
				self assert: (details at: #name) equals: 'ZooAnimal class' ]
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
	error := self capture: [ MCPCommandError signalClassNameIsAList: '{"ZooAnimal","ZooLion"}' scope: nil details: #(  ) ].
	details := error structuredDetails.
	self assert: error errorCode equals: #ClassNameIsAList.
	self
		assert: error messageText
		equals: '{"ZooAnimal","ZooLion"} is a list written as one string, not a class name. Pass several names as an array of strings.'.
	self assert: (details at: #name) equals: '{"ZooAnimal","ZooLion"}'.
	self deny: (details includesKey: #scope)
]

{ #category : 'tests' }
MCPCommandErrorTest >> testAMethodSourceHeaderCarriesTheHeaderItsClassAndSide [

	| details error |
	error := self capture: [
			         MCPCommandError
				         signalMethodSourceHeader: 'ZooAnimal >> #dailyRation'
				         message: 'The source begins with ZooAnimal >> #dailyRation.'
				         className: 'ZooLion'
				         side: 'instance' ].
	details := error structuredDetails.
	self assert: error errorCode equals: #MethodSourceHeader.
	self assert: error messageText equals: 'The source begins with ZooAnimal >> #dailyRation.'.
	self assert: (details at: #header) equals: 'ZooAnimal >> #dailyRation'.
	self assert: (details at: #class) equals: 'ZooLion'.
	self assert: (details at: #side) equals: 'instance'
]

{ #category : 'tests' }
MCPCommandErrorTest >> testAMissingCompileTargetSaysHowToMakeIt [

	| error |
	error := self capture: [ MCPCommandError signalMissingCompileTarget: 'ZooAviary' suggestions: #(  ) ].
	self assert: error errorCode equals: #ClassNotFound.
	self assert: error messageText equals: 'Class ZooAviary does not exist. Create it with class_create, then compile into it.'.
	self assert: (error structuredDetails at: #class) equals: 'ZooAviary'.
	error := self capture: [ MCPCommandError signalMissingCompileTarget: 'ZooAvairy' suggestions: #( 'ZooAviary' ) ].
	self
		assert: error messageText
		equals: 'Class ZooAvairy does not exist. Did you mean: ZooAviary. If it is a new class, create it with class_create first.'.
	self assert: (error structuredDetails at: #suggestions) equals: #( 'ZooAviary' )
]

{ #category : 'tests' }
MCPCommandErrorTest >> testASkippedScopeEntryNamesTheKeyThatSkippedIt [

	self
		assert: (MCPCommandError
				 textForMissing: 'ZooTigr'
				 role: #class
				 scope: 'scope.classes'
				 skipped: true
				 suggestions: #( 'ZooTiger' 'ZooTapir' ))
		equals: 'Class ZooTigr does not exist, so scope.classes skipped it. Did you mean: ZooTiger, ZooTapir.'.
	self
		assert: (MCPCommandError
				 textForNotAClass: 'Transcript'
				 role: #class
				 scope: 'scope.classes'
				 skipped: true)
		equals: 'Transcript is a global variable, not a class, so scope.classes skipped it.'.
	self
		assert: (MCPCommandError
				 textForMissing: 'Zoo-Animls'
				 role: #package
				 scope: 'scope.packages'
				 skipped: true
				 suggestions: #( 'Zoo-Animals' ))
		equals: 'Package Zoo-Animls does not exist, so scope.packages skipped it. Did you mean: Zoo-Animals.'.
	self
		assert: (MCPCommandError textForClassNameIsAList: '["ZooAnimal","ZooLion"]' scope: 'scope.classes' skipped: true)
		equals:
		'["ZooAnimal","ZooLion"] is a list written as one string, not a class name, so scope.classes skipped it. Pass several names as an array of strings.'
]

{ #category : 'tests' }
MCPCommandErrorTest >> testAStrictScopeEntryNamesItsKeyAsItRefuses [

	| details error |
	error := self capture: [
			         MCPCommandError
				         signalMissing: 'ZooTigr'
				         role: #class
				         scope: 'scope.hierarchyOf'
				         suggestions: #( 'ZooTiger' )
				         details: #(  ) ].
	details := error structuredDetails.
	self assert: error messageText equals: 'Class ZooTigr, in scope.hierarchyOf, does not exist. Did you mean: ZooTiger.'.
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
		'Class MCPCommandErrorTestExisting already exists. Change it with class_update {"name": "MCPCommandErrorTestExisting", ...}. class_get shows it.'.
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
	self
		assert: (details at: #message)
		equals: 'Method MCPToolGetMethodTestTarget>>yourself does not exist. MCPToolGetMethodTestTarget inherits Object>>yourself.'
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
