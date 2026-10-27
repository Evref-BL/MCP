"
Command that calculates and optionally applies method rewrite changes.

It resolves the method scope, delegates pattern matching to the NewTools rewrite backend, enforces apply guardrails, and returns an MCPMethodRewriteReport.
"
Class {
	#name : 'MCPRewriteMethodsCommand',
	#superclass : 'MCPToolRequestCommand',
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'private - rewriting' }
MCPRewriteMethodsCommand >> applyChanges: changes [

	| changeManager |
	changeManager := self refactoringChangeManager.
	^ [ changes do: [ :change | changeManager performChange: change ] ]
		  on: Deprecation
		  do: [ :deprecation | deprecation resume ]
]

{ #category : 'private - results' }
MCPRewriteMethodsCommand >> changeInfosForChanges: changes [

	^ changes collect: [ :each | MCPMethodRewriteChangeInfo fromChange: each includeSources: self request includeSources ] as: Array
]

{ #category : 'private - rewriting' }
MCPRewriteMethodsCommand >> classNameForChange: aChange [

	| behavior |
	behavior := aChange changeClass.
	^ behavior isMeta
		  ifTrue: [ behavior instanceSide name asString ]
		  ifFalse: [ behavior name asString ]
]

{ #category : 'executing' }
MCPRewriteMethodsCommand >> execute [

	| appliedCount changeInfos changes report |
	self request apply ifTrue: [ self validateExplicitApplyScope ].
	changes := self sortedChanges: self rewriteChanges.
	changeInfos := self changeInfosForChanges: changes.
	appliedCount := 0.
	self request apply ifTrue: [
			self applyChanges: changes.
			appliedCount := changes size ].
	report := MCPMethodRewriteReport request: self request changeInfos: changeInfos appliedCount: appliedCount.
	^ self tool successResultText: (self successSummaryForReport: report) data: report asDictionary
]

{ #category : 'private - rewriting' }
MCPRewriteMethodsCommand >> refactoringChangeManager [

	^ ReChangeManager instance
]

{ #category : 'private - rewriting' }
MCPRewriteMethodsCommand >> rewriteChanges [

	| methods transformationRule |
	methods := self request scopeQuery methods.
	methods ifEmpty: [ ^ #(  ) ].
	transformationRule := RBTransformationRule new
		                      rewriteRule: self rewriteRule;
		                      yourself.
	methods do: [ :eachMethod | transformationRule checkMethod: eachMethod ].
	^ transformationRule changes asArray
]

{ #category : 'private - rewriting' }
MCPRewriteMethodsCommand >> rewriteRule [

	self validateRewriteRules.
	^ StRewriterRBApplier rewriter: self ruleHolders
]

{ #category : 'private - rewriting' }
MCPRewriteMethodsCommand >> ruleHolders [

	^ self request rules collect: [ :each | each asStRewriterRuleHolder ] as: Array
]

{ #category : 'private - rewriting' }
MCPRewriteMethodsCommand >> sortedChanges: changes [

	^ changes asArray sort: [ :left :right | self sortsChange: left before: right ]
]

{ #category : 'private - rewriting' }
MCPRewriteMethodsCommand >> sortsChange: leftChange before: rightChange [

	| leftClassName leftClassSide rightClassName rightClassSide |
	leftClassName := self classNameForChange: leftChange.
	rightClassName := self classNameForChange: rightChange.
	leftClassName = rightClassName ifFalse: [ ^ leftClassName < rightClassName ].
	leftClassSide := leftChange changeClass isMeta.
	rightClassSide := rightChange changeClass isMeta.
	leftClassSide = rightClassSide ifFalse: [ ^ leftClassSide not and: [ rightClassSide ] ].
	^ leftChange selector asString < rightChange selector asString
]

{ #category : 'private - results' }
MCPRewriteMethodsCommand >> successSummaryForReport: report [

	| count |
	count := report apply
		         ifTrue: [ report appliedCount ]
		         ifFalse: [ report changeCount ].
	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: (report apply
					   ifTrue: [ 'Applied ' ]
					   ifFalse: [ 'Previewed ' ]);
			  print: count;
			  nextPutAll: ' method rewrite change'.
		  count = 1 ifFalse: [ stream nextPut: $s ].
		  stream nextPut: $. ]
]

{ #category : 'private - validation' }
MCPRewriteMethodsCommand >> validateExplicitApplyScope [
	"Rewriting every method in the image is not something a caller should be able to ask for by
	leaving an argument out. Naming the packages says it on purpose."

	self request scopeQuery usesImplicitImageScope ifTrue: [
			MCPCommandError
				signalErrorCode: #RewriteApplyRequiresExplicitScope
				message: 'Applying method_rewrite needs a scope. Name packages, classes, subclassesOf or superclassesOf.'
				details: self request requestedContext ]
]

{ #category : 'private - validating' }
MCPRewriteMethodsCommand >> validateRewriteRules [

	self request rules do: [ :each | each validatePatterns ]
]
