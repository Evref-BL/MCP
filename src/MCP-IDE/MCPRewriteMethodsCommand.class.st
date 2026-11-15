"
Calculates and optionally applies the method rewrite changes some rules make in a method scope.

It delegates pattern matching to the NewTools rewrite backend through an MCPSettlingRewriter, so each method is rewritten until nothing more matches, and answers an MCPMethodRewriteReport. A method a class got from a trait is left out, since a changed copy would shadow the trait in that class alone; skippedTraitChanges says what the rules would change in the trait instead.
"
Class {
	#name : 'MCPRewriteMethodsCommand',
	#superclass : 'MCPCommand',
	#instVars : [
		'rules',
		'scopeQuery',
		'apply',
		'methods'
	],
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPRewriteMethodsCommand class >> rules: someRuleSpecs scopeQuery: aScopeQuery apply: aBoolean [

	^ self new initializeRules: someRuleSpecs scopeQuery: aScopeQuery apply: aBoolean
]

{ #category : 'accessing' }
MCPRewriteMethodsCommand >> apply [
	"Whether the changes are applied, or only previewed."

	^ apply
]

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
	"A preview exists to show what would change, so it carries the sources; an apply has already changed them."

	^ changes collect: [ :each | MCPMethodRewriteChangeInfo fromChange: each includeSources: apply not ] as: Array
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
	"Compute the changes the rules make to the methods in scope, sorted, apply them when asked, and answer a report of them. They are described before they are applied, while the methods still hold the sources they replace."

	| appliedCount changeInfos changes |
	methods := scopeQuery methods.
	changes := self sortedChanges: (self rewriteChangesFor: (self rewritableMethodsIn: methods)).
	changeInfos := self changeInfosForChanges: changes.
	appliedCount := 0.
	apply ifTrue: [
			self applyChanges: changes.
			appliedCount := changes size ].
	^ MCPMethodRewriteReport request: self changeInfos: changeInfos appliedCount: appliedCount
]

{ #category : 'initialization' }
MCPRewriteMethodsCommand >> initializeRules: someRuleSpecs scopeQuery: aScopeQuery apply: aBoolean [

	rules := someRuleSpecs.
	scopeQuery := aScopeQuery.
	apply := aBoolean
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

{ #category : 'accessing' }
MCPRewriteMethodsCommand >> scopeQuery [

	^ scopeQuery
]

{ #category : 'private - rewriting' }
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
