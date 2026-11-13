"
What the manifest of a package says about the rules run on its code: the false positives marked for an entity, its class or the package, the rules and classes the package rejects, and the rules it forces.

Renraku's live critiques read the false positives and the forced rules, and the critique browser the rejected rules and classes too. MCP applies all of them, so a person's exclusions hold whichever tool reports a critique.
"
Class {
	#name : 'MCPManifestRules',
	#superclass : 'Object',
	#instVars : [
		'builder'
	],
	#category : 'MCP-IDE-Critiques',
	#package : 'MCP-IDE',
	#tag : 'Critiques'
}

{ #category : 'instance creation' }
MCPManifestRules class >> for: anEntity [
	"The rules of the package anEntity belongs to."

	^ self new setPackage: anEntity package
]

{ #category : 'testing' }
MCPManifestRules >> excludes: aRule on: anEntity [
	"Whether the manifest keeps aRule off anEntity, as the critique browser decides it for each level a ban can be put on: the entity, its class and its package."

	builder manifest ifNil: [ ^ false ].
	^ (anEntity banChecksForValidation copyWith: anEntity package) anySatisfy: [ :each |
		  builder isFalsePositive: each onRule: aRule class uniqueIdentifierName version: aRule class identifierMinorVersionNumber ]
]

{ #category : 'testing' }
MCPManifestRules >> forces: aRuleClass [
	"Whether the manifest runs aRuleClass on its package though the image has it off."

	builder manifest ifNil: [ ^ false ].
	^ builder manifest forcedRules anySatisfy: [ :each | each asSymbol = aRuleClass name ]
]

{ #category : 'initialization' }
MCPManifestRules >> setPackage: aPackage [

	builder := TheManifestBuilder new.
	builder manifestOf: aPackage
]
