"
Command that calculates and optionally applies method rewrite changes.

It resolves the method scope, delegates pattern matching to the NewTools rewrite backend through an MCPSettlingRewriter, so each method is rewritten until nothing more matches, enforces apply guardrails, and returns an MCPMethodRewriteReport.
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

	| appliedCount changeInfos changes methods report |
	self request apply ifTrue: [ self validateExplicitApplyScope ].
	methods := self request scopeQuery methods.
	changes := self sortedChanges: (self rewriteChangesFor: (self rewritableMethodsIn: methods)).
	changeInfos := self changeInfosForChanges: changes.
	appliedCount := 0.
	self request apply ifTrue: [
			self applyChanges: changes.
			appliedCount := changes size ].
	report := (MCPMethodRewriteReport request: self request changeInfos: changeInfos appliedCount: appliedCount)
		          skippedTraitMethods: (self skippedTraitMethodReferencesFor: methods);
		          yourself.
	^ self tool successResultText: (self successSummaryForReport: report) data: report asDictionary
]

{ #category : 'private - rewriting' }
MCPRewriteMethodsCommand >> refactoringChangeManager [

	^ ReChangeManager instance
]

{ #category : 'private - rewriting' }
MCPRewriteMethodsCommand >> rewritableMethodsIn: methods [
	"A trait's method is installed in every class that uses the trait, so a scope naming those classes holds the copies too. Rewriting a copy would write a changed method into that class alone, shadowing the trait, so the copies are left out and the method is rewritten where it is defined."

	^ methods reject: [ :each | each isFromTrait ]
]

{ #category : 'private - rewriting' }
MCPRewriteMethodsCommand >> rewriteChangesFor: methods [

	| transformationRule |
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
	^ MCPSettlingRewriter on: (StRewriterRBApplier rewriter: self ruleHolders)
]

{ #category : 'private - rewriting' }
MCPRewriteMethodsCommand >> ruleHolders [

	^ self request rules collect: [ :each | each asStRewriterRuleHolder ] as: Array
]

{ #category : 'private - rewriting' }
MCPRewriteMethodsCommand >> skippedTraitMethodReferencesFor: methods [
	"What this rewrite would have changed had the copies in scope been theirs to change, named by the trait that defines it. A scope naming the users of a trait and not the trait itself reports no change at all otherwise, and nothing would say where the method lives. Only the methods the rules actually match are named, since every traited class carries copies of Pharo's own trait methods and they are nobody's business here."

	^ ((self rewriteChangesFor: (self traitOriginMethodsFor: methods))
		   collect: [ :each | self tool methodReferenceForBehavior: each changeClass selector: each selector ]
		   as: Set) asArray sort
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
			  stream nextPut: $..
			  report skippedTraitMethods ifNotEmpty: [ :skipped |
					  skipped size = 1
						  ifTrue: [ stream nextPutAll: ' Skipped 1 method installed from a trait.' ]
						  ifFalse: [
								  stream
									  nextPutAll: ' Skipped ';
									  print: skipped size;
									  nextPutAll: ' methods installed from traits.' ] ] ]
]

{ #category : 'private - rewriting' }
MCPRewriteMethodsCommand >> traitOriginMethodsFor: methods [
	"The trait methods behind the copies in scope, less the ones the scope holds anyway: those are rewritten like any other method. An alias installs a copy under a selector its trait does not answer, so it has no origin to name here."

	| inScope |
	inScope := methods asIdentitySet.
	^ ((methods
		    select: [ :each | each isFromTrait and: [ each origin includesSelector: each selector ] ]
		    thenCollect: [ :each | each origin >> each selector ]) asIdentitySet reject: [ :each | inScope includes: each ]) asArray
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
