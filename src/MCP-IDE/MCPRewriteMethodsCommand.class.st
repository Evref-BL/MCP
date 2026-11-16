"
Calculates the method rewrite changes some rules make in a method scope, and applies them when asked.

It delegates pattern matching to the NewTools rewrite backend through an MCPSettlingRewriter, so each method is rewritten until nothing more matches. execute answers the changes, sorted, and applyChanges: performs them, so a caller can describe them first, while the methods still hold the sources they replace. A method a class got from a trait is left out, since a changed copy would shadow the trait in that class alone; skippedTraitChanges says what the rules would change in the trait instead.
"
Class {
	#name : 'MCPRewriteMethodsCommand',
	#superclass : 'MCPCommand',
	#instVars : [
		'rules',
		'scopeQuery',
		'methods'
	],
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPRewriteMethodsCommand class >> rules: someRuleSpecs scopeQuery: aScopeQuery [

	^ self new initializeRules: someRuleSpecs scopeQuery: aScopeQuery
]

{ #category : 'executing' }
MCPRewriteMethodsCommand >> applyChanges: changes [

	| changeManager |
	changeManager := self refactoringChangeManager.
	^ [ changes do: [ :change | changeManager performChange: change ] ]
		  on: Deprecation
		  do: [ :deprecation | deprecation resume ]
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
	"Answer the changes the rules make to the methods in scope, sorted by class, side and selector. Nothing changes until they are given to applyChanges:, so a caller can describe them first, while the methods still hold the sources they replace."

	methods := scopeQuery methods.
	^ self sortedChanges: (self rewriteChangesFor: (self rewritableMethodsIn: methods))
]

{ #category : 'initialization' }
MCPRewriteMethodsCommand >> initializeRules: someRuleSpecs scopeQuery: aScopeQuery [

	rules := someRuleSpecs.
	scopeQuery := aScopeQuery
]

{ #category : 'private - rewriting' }
MCPRewriteMethodsCommand >> parseTreeRewriter [
	"Every rule adds itself: a pattern pair the caller wrote, or the matchers a named rule already holds."

	| rewriter |
	rewriter := RBParseTreeRewriter new.
	rules do: [ :each | each addToRewriter: rewriter ].
	^ rewriter
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
	^ MCPSettlingRewriter on: self parseTreeRewriter
]

{ #category : 'executing' }
MCPRewriteMethodsCommand >> skippedTraitChanges [
	"Once executed, what the rules would change in the trait methods behind the copies in scope, which were left out: a changed copy would shadow the trait in that class alone. A scope naming the users of a trait and not the trait itself reports no change at all otherwise, and nothing would say where the method lives. Only the methods the rules actually match count, since every traited class carries copies of Pharo's own trait methods and they are nobody's business here."

	^ self rewriteChangesFor: (self traitOriginMethodsFor: methods)
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

{ #category : 'private - rewriting' }
MCPRewriteMethodsCommand >> traitOriginMethodsFor: methods [
	"The trait methods behind the copies in scope, less the ones the scope holds anyway: those are rewritten like any other method. An alias installs a copy under a selector its trait does not answer, so it has no origin to name here."

	| inScope |
	inScope := methods asIdentitySet.
	^ ((methods
		    select: [ :each | each isFromTrait and: [ each origin includesSelector: each selector ] ]
		    thenCollect: [ :each | each origin >> each selector ]) asIdentitySet reject: [ :each | inScope includes: each ]) asArray
]

{ #category : 'private - validating' }
MCPRewriteMethodsCommand >> validateRewriteRules [

	rules do: [ :each | each validatePatterns ]
]
