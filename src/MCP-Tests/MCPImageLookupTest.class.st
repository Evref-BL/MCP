"
Tests how MCPImageLookup reads a class name, the side it may name, and what it says of a name that names no class of the kind asked for.
"
Class {
	#name : 'MCPImageLookupTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPImageLookupTest >> capture: aBlock [

	^ [
		  aBlock value.
		  self fail: 'Expected MCPCommandError' ]
		  on: MCPCommandError
		  do: [ :error | error ]
]

{ #category : 'tests' }
MCPImageLookupTest >> testAClassOfTheRightKindIsAnswered [

	| pool |
	pool := SharedPool allSubclasses
		        detect: [ :each | each isAbstract not ]
		        ifNone: [ ^ self skip: 'This image has no shared pool.' ].
	self assert: (MCPImageLookup classNamed: pool name role: #sharedPool details: #(  )) equals: pool.
	self assert: (MCPImageLookup classNamed: 'VariableLayout' role: #layoutClass details: #(  )) equals: VariableLayout.
	self
		assert: (MCPImageLookup traitNamed: 'TMCPToolMethodSearchFixture classTrait' details: #(  ))
		equals: (self classNamed: 'TMCPToolMethodSearchFixture').
	self assert: (MCPImageLookup classNamed: 'Object' role: #superclass details: #(  )) equals: Object
]

{ #category : 'tests' }
MCPImageLookupTest >> testAClassOfTheWrongKindIsRefused [

	| error |
	error := self capture: [
		         MCPImageLookup classNamed: 'MCPToolGetMethodTestTarget' role: #sharedPool details: { (#class -> 'MCPNewClass') } ].
	self assert: error errorCode equals: #InvalidSharedPool.
	self assert: error messageText equals: 'MCPToolGetMethodTestTarget is not a shared pool: a pool is a subclass of SharedPool.'.
	self assert: (error structuredDetails at: #sharedPool) equals: 'MCPToolGetMethodTestTarget'.
	error := self capture: [ MCPImageLookup classNamed: 'Object' role: #layoutClass details: #(  ) ].
	self assert: error errorCode equals: #InvalidLayoutClass.
	self assert: error messageText equals: 'Object is not a layout class: name a subclass of AbstractLayout, such as VariableLayout.'.
	error := self capture: [ MCPImageLookup traitNamed: 'MCPToolGetMethodTestTarget' details: #(  ) ].
	self assert: error errorCode equals: #InvalidTrait.
	self assert: error messageText equals: 'MCPToolGetMethodTestTarget is not a trait.'.
	error := self capture: [ MCPImageLookup classNamed: 'Object' role: #critiqueRule details: #(  ) ].
	self assert: error errorCode equals: #InvalidCritiqueRule.
	error := self capture: [ MCPImageLookup classNamed: 'Object' role: #rewriteRule details: #(  ) ].
	self assert: error errorCode equals: #RewriteRuleClassHasNoPatterns
]

{ #category : 'tests' }
MCPImageLookupTest >> testAGlobalThatIsNotAClassIsSaidSo [

	| error |
	error := self capture: [ MCPImageLookup classNamed: 'Transcript' ].
	self assert: error errorCode equals: #NotAClass.
	self assert: error messageText equals: 'Transcript is a global variable, not a class.'.
	self assert: (error structuredDetails at: #class) equals: 'Transcript'.
	error := self capture: [ MCPImageLookup traitNamed: 'Transcript' details: #(  ) ].
	self assert: error errorCode equals: #NotAClass.
	self assert: error messageText equals: 'Transcript is a global variable, not a trait.'.
	self assert: (error structuredDetails at: #trait) equals: 'Transcript'.
	error := self capture: [ MCPImageLookup classNamed: 'Transcript class' role: #superclass details: { (#class -> 'MCPNewClass') } ].
	self assert: error messageText equals: 'Transcript is a global variable, not a class.'.
	self assert: (error structuredDetails at: #superclass) equals: 'Transcript'.
	self assert: (error structuredDetails at: #class) equals: 'MCPNewClass'
]

{ #category : 'tests' }
MCPImageLookupTest >> testAGlobalThatIsNotAClassIsSaidSoInEachRolesWords [
	"A global variable given in a role says what the role needed instead, and keeps its name under the role's key."

	{
		#( #superclass 'a class' #superclass ).
		#( #sharedPool 'a shared pool' #sharedPool ).
		#( #layoutClass 'a layout class' #layout ).
		#( #critiqueRule 'a critique rule' #ruleClass ).
		#( #rewriteRule 'a rewrite rule' #ruleClass ) } do: [ :each |
			| error |
			error := self capture: [ MCPImageLookup classNamed: 'Transcript' role: each first details: #(  ) ].
			self assert: error errorCode equals: #NotAClass.
			self assert: error messageText equals: ('Transcript is a global variable, not {1}.' format: { each second }).
			self assert: (error structuredDetails at: each third) equals: 'Transcript' ]
]

{ #category : 'tests' }
MCPImageLookupTest >> testAListWrittenAsOneNameIsRefused [

	#( '["MCPImageLookup","MCPCommandError"]' '{"MCPImageLookup","MCPCommandError"}' ) do: [ :each |
			| error |
			error := self capture: [ MCPImageLookup classNamed: each ].
			self assert: error errorCode equals: #ClassNameIsAList.
			self
				assert: error messageText
				equals: each , ' is a list written as one string, not a class name. Pass several names as an array of strings.'.
			self assert: (error structuredDetails at: #name) equals: each ]
]

{ #category : 'tests' }
MCPImageLookupTest >> testAMethodToolReadsTheSideOnce [

	| error read |
	read := [ :name :side |
		        MCPImageLookup className: name side: side do: [ :baseName :classSide :sideGiven |
				        {
					        baseName.
					        classSide.
					        sideGiven } ] ].
	self assert: (read value: 'ZooLion class' value: nil) equals: #( 'ZooLion' true true ).
	self assert: (read value: 'ZooLion class' value: 'class') equals: #( 'ZooLion' true true ).
	self assert: (read value: 'TZooFeedable classTrait' value: nil) equals: #( 'TZooFeedable' true true ).
	self assert: (read value: 'ZooLion' value: nil) equals: #( 'ZooLion' false false ).
	self assert: (read value: 'ZooLion' value: 'instance') equals: #( 'ZooLion' false true ).
	self assert: (read value: 'ZooLion' value: 'class') equals: #( 'ZooLion' true true ).
	error := self capture: [ read value: 'ZooLion class' value: 'instance' ].
	self assert: error errorCode equals: #ClassSideConflict.
	self
		assert: error messageText
		equals: 'ZooLion class names the class side, but side is instance. Pass class ZooLion, with side class or instance.'.
	self assert: (error structuredDetails at: #class) equals: 'ZooLion'.
	self assert: (error structuredDetails at: #name) equals: 'ZooLion class'.
	self assert: (error structuredDetails at: #side) equals: 'instance'
]

{ #category : 'tests' }
MCPImageLookupTest >> testAMissingCompileTargetSaysHowToMakeIt [

	| error |
	error := self capture: [ MCPImageLookup compileTargetNamed: 'Zzqxw' classSide: false ].
	self assert: error errorCode equals: #ClassNotFound.
	self assert: error messageText equals: 'Class Zzqxw does not exist. Create it with class_create, then compile into it.'.
	error := self capture: [ MCPImageLookup compileTargetNamed: 'MCPToolGetMethodTestTargt class' classSide: false ].
	self assert: (error messageText beginsWith: 'Class MCPToolGetMethodTestTargt does not exist. Did you mean: ').
	self assert: (error messageText includesSubstring: 'MCPToolGetMethodTestTarget').
	self assert: (error messageText endsWith: '. If it is a new class, create it with class_create first.')
]

{ #category : 'tests' }
MCPImageLookupTest >> testAMisspeltNameSuggestsNamesOfItsKind [

	| error suggestions |
	error := self capture: [ MCPImageLookup classNamed: 'MCPToolGetMethodTestTargt' ].
	suggestions := error structuredDetails at: #suggestions.
	self assert: (error messageText beginsWith: 'Class MCPToolGetMethodTestTargt does not exist. Did you mean: ').
	self assert: (suggestions includes: 'MCPToolGetMethodTestTarget').
	self assert: (suggestions allSatisfy: [ :each | each isString ]).
	error := self capture: [ MCPImageLookup classNamed: 'TMCPToolMethodSearchFixtur' ].
	self assert: ((error structuredDetails at: #suggestions) includes: 'TMCPToolMethodSearchFixture').
	error := self capture: [ MCPImageLookup traitNamed: 'TMCPToolMethodSearchFixtur' details: #(  ) ].
	suggestions := error structuredDetails at: #suggestions.
	self assert: error errorCode equals: #TraitNotFound.
	self assert:
		(error messageText beginsWith: 'Trait TMCPToolMethodSearchFixtur does not exist. Did you mean: TMCPToolMethodSearchFixture').
	self assert: (suggestions allSatisfy: [ :each | (Smalltalk globals classNamed: each) isTrait ])
]

{ #category : 'tests' }
MCPImageLookupTest >> testANameIsReadWithoutItsSide [

	#( 'MCPImageLookup class' 'MCPImageLookup  class' 'MCPImageLookup CLASS' ' MCPImageLookup class ' ) do: [ :each |
			self assert: (MCPImageLookup baseNameOf: each) equals: 'MCPImageLookup'.
			self assert: (MCPImageLookup namesClassSide: each) ].
	self assert: (MCPImageLookup baseNameOf: 'TMCPMethodTool classTrait') equals: 'TMCPMethodTool'.
	self assert: (MCPImageLookup namesClassSide: 'TMCPMethodTool classTrait').
	#( 'MCPImageLookup' 'Metaclass' 'TraitedMetaclass' ) do: [ :each |
			self assert: (MCPImageLookup baseNameOf: each) equals: each.
			self deny: (MCPImageLookup namesClassSide: each) ]
]

{ #category : 'tests' }
MCPImageLookupTest >> testANameNothingResemblesIsMissing [

	#( 'Zzqxw' 'Zzqxw class' ) do: [ :each |
			| details error |
			error := self capture: [ MCPImageLookup classNamed: each ].
			details := error structuredDetails.
			self assert: error errorCode equals: #ClassNotFound.
			self assert: error messageText equals: 'Class Zzqxw does not exist.'.
			self assert: (details at: #class) equals: 'Zzqxw'.
			self assert: (details at: #suggestions) isEmpty.
			self deny: (details includesKey: #scope) ]
]

{ #category : 'tests' }
MCPImageLookupTest >> testANewClassNameMustBeFree [

	| error |
	self assert: (MCPImageLookup newClassName: 'MCPImageLookupTestNeverMade') equals: 'MCPImageLookupTestNeverMade'.
	error := self capture: [ MCPImageLookup newClassName: '["ZooAnimal","ZooLion"]' ].
	self assert: error errorCode equals: #ClassNameIsAList.
	error := self capture: [ MCPImageLookup newClassName: 'ZooLion class' ].
	self assert: error errorCode equals: #ClassSideNamed.
	self
		assert: error messageText
		equals:
		'ZooLion class is the class side of ZooLion, which class_create makes with the class. Name ZooLion, and give class-side slots in classSlots.'.
	error := self capture: [ MCPImageLookup newClassName: 'Transcript' ].
	self assert: error errorCode equals: #GlobalAlreadyExists.
	self assert: error messageText equals: 'Transcript already names a global variable. Choose another class name.'.
	error := self capture: [ MCPImageLookup newClassName: 'MCPImageLookup' ].
	self assert: error errorCode equals: #ClassAlreadyExists
]

{ #category : 'tests' }
MCPImageLookupTest >> testAPackageIsNamedLikeAClass [

	| error warning |
	error := self capture: [ MCPImageLookup packageNamed: 'Zzqxw-Package' ].
	self assert: error errorCode equals: #PackageNotFound.
	self assert: error messageText equals: 'Package Zzqxw-Package does not exist.'.
	self deny: (error structuredDetails includesKey: #scope).
	error := self capture: [ MCPImageLookup packageNamed: 'Zzqxw-Package' inScope: 'scope.packages' ].
	self assert: error messageText equals: 'Package Zzqxw-Package, in scope.packages, does not exist.'.
	self assert: (error structuredDetails at: #scope) equals: 'scope.packages'.
	MCPImageLookup packageNamed: 'Zzqxw-Package' inScope: 'scope.packages' ifSkipped: [ :text | warning := text ].
	self assert: warning equals: 'Package Zzqxw-Package does not exist, so scope.packages skipped it.'.
	self assert: (MCPImageLookup packageNamed: 'MCP-Tests') name asString equals: 'MCP-Tests'
]

{ #category : 'tests' }
MCPImageLookupTest >> testAScopeEntryNamesItsKey [

	| answer error warning |
	error := self capture: [ MCPImageLookup classNamed: 'Zzqxw' inScope: 'scope.hierarchyOf' ].
	self assert: error errorCode equals: #ClassNotFound.
	self assert: error messageText equals: 'Class Zzqxw, in scope.hierarchyOf, does not exist.'.
	self assert: (error structuredDetails at: #scope) equals: 'scope.hierarchyOf'.
	answer := MCPImageLookup classNamed: 'Zzqxw' inScope: 'scope.classes' ifSkipped: [ :text |
			          warning := text.
			          nil ].
	self assert: answer isNil.
	self assert: warning equals: 'Class Zzqxw does not exist, so scope.classes skipped it.'.
	MCPImageLookup classNamed: 'Transcript' inScope: 'scope.classes' ifSkipped: [ :text | warning := text ].
	self assert: warning equals: 'Transcript is a global variable, not a class, so scope.classes skipped it.'.
	MCPImageLookup classNamed: '["A","B"]' inScope: 'scope.classes' ifSkipped: [ :text | warning := text ].
	self
		assert: warning
		equals:
		'["A","B"] is a list written as one string, not a class name, so scope.classes skipped it. Pass several names as an array of strings.'.
	self
		assert:
		(MCPImageLookup classNamed: 'MCPToolGetMethodTestTarget class' inScope: 'scope.classes' ifSkipped: [ :text | self fail: text ])
		equals: (self classNamed: 'MCPToolGetMethodTestTarget')
]

{ #category : 'tests' }
MCPImageLookupTest >> testAWholeClassToolRefusesAClassSide [

	| error |
	self assert: (MCPImageLookup wholeClassName: 'ZooAnimal' for: 'class_remove') equals: 'ZooAnimal'.
	error := self capture: [ MCPImageLookup wholeClassName: 'ZooAnimal class' for: 'class_remove' ].
	self assert: error errorCode equals: #ClassSideNamed.
	self
		assert: error messageText
		equals:
		'ZooAnimal class is the class side of ZooAnimal, and goes only with its class. Name ZooAnimal to remove the class, or use method_remove with side class to remove class-side methods.'.
	error := self capture: [ MCPImageLookup wholeClassName: 'ZooLion class' for: 'class_update' ].
	self
		assert: error messageText
		equals:
		'ZooLion class is the class side of ZooLion. class_update changes the whole class: name ZooLion, and use classSlots for class-side slots.'
]

{ #category : 'tests' }
MCPImageLookupTest >> testBehaviorNamedAnswersTheSideAskedFor [

	| target |
	target := self classNamed: 'MCPToolGetMethodTestTarget'.
	self assert: (MCPImageLookup behaviorNamed: 'MCPToolGetMethodTestTarget' classSide: false) equals: target.
	self assert: (MCPImageLookup behaviorNamed: 'MCPToolGetMethodTestTarget' classSide: true) equals: target classSide.
	self assert: (MCPImageLookup behaviorNamed: 'MCPToolGetMethodTestTarget class' classSide: false) equals: target classSide.
	self assert: (MCPImageLookup compileTargetNamed: 'MCPToolGetMethodTestTarget' classSide: false) equals: target.
	self assert: (MCPImageLookup compileTargetNamed: 'MCPToolGetMethodTestTarget' classSide: true) equals: target classSide
]

{ #category : 'tests' }
MCPImageLookupTest >> testClassNamedAnswersTheClassWhicheverSideTheNameSays [

	#( 'MCPToolGetMethodTestTarget' 'MCPToolGetMethodTestTarget class' 'MCPToolGetMethodTestTarget  class' ) do: [ :each |
		self assert: (MCPImageLookup classNamed: each) equals: (self classNamed: 'MCPToolGetMethodTestTarget') ].
	self
		assert: (MCPImageLookup classNamed: 'TMCPToolMethodSearchFixture classTrait')
		equals: (self classNamed: 'TMCPToolMethodSearchFixture')
]

{ #category : 'tests' }
MCPImageLookupTest >> testEachRoleAnswersItsCodeUnderItsKey [
	"A missing name answers the code of the role it was given in and holds the name, without its side, under that role's key. It is no scope entry, so it has no scope."

	{
		#( #class #ClassNotFound #class ).
		#( #superclass #SuperclassNotFound #superclass ).
		#( #trait #TraitNotFound #trait ).
		#( #sharedPool #SharedPoolNotFound #sharedPool ).
		#( #layoutClass #LayoutClassNotFound #layout ).
		#( #critiqueRule #CritiqueRuleNotFound #ruleClass ).
		#( #rewriteRule #RewriteRuleNotFound #ruleClass ) } do: [ :each |
			| details error |
			error := self capture: [ MCPImageLookup classNamed: 'Zzqxw class' role: each first details: #(  ) ].
			details := error structuredDetails.
			self assert: error errorCode equals: each second.
			self assert: (details at: each third) equals: 'Zzqxw'.
			self assert: (details at: #suggestions) isEmpty.
			self deny: (details includesKey: #scope) ]
]

{ #category : 'tests' }
MCPImageLookupTest >> testEachRoleOpensWithItsNoun [

	{
		(#superclass -> 'Superclass').
		(#trait -> 'Trait').
		(#sharedPool -> 'Shared pool').
		(#layoutClass -> 'Layout class').
		(#critiqueRule -> 'Critique rule').
		(#rewriteRule -> 'Rewrite rule') } do: [ :each |
			| error |
			error := self capture: [ MCPImageLookup classNamed: 'Zzqxw' role: each key details: #(  ) ].
			self assert: error messageText equals: each value , ' Zzqxw does not exist.' ]
]

{ #category : 'tests' }
MCPImageLookupTest >> testEachRoleSuggestsNamesOfItsKind [
	"A misspelt name is matched only against what its role could have meant: a misspelt layout suggests layouts, and a superclass never suggests a trait, though Pharo counts traits among its classes."

	{
		{
			#superclass.
			'TMCPToolMethodSearchFixtur'.
			nil.
			[ :each | each isTrait not ] }.
		{
			#sharedPool.
			'ChronologyConstant'.
			'ChronologyConstants'.
			[ :each | each inheritsFrom: SharedPool ] }.
		{
			#layoutClass.
			'Varible'.
			'VariableLayout'.
			[ :each | each inheritsFrom: AbstractLayout ] }.
		{
			#critiqueRule.
			'MCPRespondsToUsageRul'.
			'MCPRespondsToUsageRule'.
			[ :each | ReRuleManager visibleRuleClasses includes: each ] }.
		{
			#rewriteRule.
			'MCPIsNotNilRul'.
			'MCPIsNotNilRule'.
			[ :each | each inheritsFrom: ReNodeRewriteRule ] } } do: [ :each |
			| error suggestions |
			error := self capture: [ MCPImageLookup classNamed: each second role: each first details: #(  ) ].
			suggestions := error structuredDetails at: #suggestions.
			self deny: suggestions isEmpty description: each first.
			each third ifNotNil: [ :expected | self assert: (suggestions includes: expected) description: each first ].
			self
				assert: (suggestions allSatisfy: [ :name | each fourth value: (self classNamed: name) ])
				description: ('{1} suggested {2}' format: {
							 each first.
							 (', ' join: suggestions) }) ]
]
