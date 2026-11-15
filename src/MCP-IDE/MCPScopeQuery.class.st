"
Abstract query over named class/package scopes.

Subclasses add the concrete entity lookup, but common scope names, completeness handling, and missing-name warnings live here.
"
Class {
	#name : 'MCPScopeQuery',
	#superclass : 'Object',
	#instVars : [
		'packageNames',
		'classNames',
		'hierarchyClassNames',
		'subclassClassNames',
		'parentClassNames',
		'warnings',
		'requiresCompleteScope'
	],
	#category : 'MCP-IDE-Queries',
	#package : 'MCP-IDE',
	#tag : 'Queries'
}

{ #category : 'private - resolution' }
MCPScopeQuery >> classNamed: className inScope: aScopeKey [
	"A scope entry, read as every class name is, so Foo class selects Foo. What names no class, a scope that must be complete refuses, and any other scope skips with a warning. aScopeKey is the entry's key as the schema spells it, such as scope.classes."

	^ self requiresCompleteScope
		  ifTrue: [ MCPImageLookup classNamed: className inScope: aScopeKey ]
		  ifFalse: [ MCPImageLookup classNamed: className inScope: aScopeKey ifSkipped: [ :warning | self recordWarning: warning ] ]
]

{ #category : 'accessing' }
MCPScopeQuery >> classNames [

	^ classNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPScopeQuery >> classNames: aCollection [

	classNames := aCollection
]

{ #category : 'accessing' }
MCPScopeQuery >> hierarchyClassNames [

	^ hierarchyClassNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPScopeQuery >> hierarchyClassNames: aCollection [

	hierarchyClassNames := aCollection
]

{ #category : 'private - resolution' }
MCPScopeQuery >> packageNamed: packageName inScope: aScopeKey [
	"A scope entry naming a package. A scope that must be complete refuses a missing one; any other scope skips it with a warning. aScopeKey is the entry's key as the schema spells it, such as scope.packages."

	^ self requiresCompleteScope
		  ifTrue: [ MCPImageLookup packageNamed: packageName inScope: aScopeKey ]
		  ifFalse: [ MCPImageLookup packageNamed: packageName inScope: aScopeKey ifSkipped: [ :warning | self recordWarning: warning ] ]
]

{ #category : 'accessing' }
MCPScopeQuery >> packageNames [

	^ packageNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPScopeQuery >> packageNames: aCollection [

	packageNames := aCollection
]

{ #category : 'accessing' }
MCPScopeQuery >> parentClassNames [

	^ parentClassNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPScopeQuery >> parentClassNames: aCollection [

	parentClassNames := aCollection
]

{ #category : 'private - resolution' }
MCPScopeQuery >> recordWarning: aWarning [
	"Keep aWarning for the answer, and answer nil: the entry it is about selects nothing."

	warnings ifNil: [ self resetWarnings ].
	warnings add: aWarning.
	^ nil
]

{ #category : 'configuring' }
MCPScopeQuery >> requireCompleteScope [

	self requiresCompleteScope: true
]

{ #category : 'accessing' }
MCPScopeQuery >> requiresCompleteScope [

	^ requiresCompleteScope ifNil: [ false ]
]

{ #category : 'accessing' }
MCPScopeQuery >> requiresCompleteScope: aBoolean [

	requiresCompleteScope := aBoolean
]

{ #category : 'private - resolution' }
MCPScopeQuery >> resetWarnings [

	warnings := OrderedCollection new
]

{ #category : 'accessing' }
MCPScopeQuery >> subclassClassNames [

	^ subclassClassNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPScopeQuery >> subclassClassNames: aCollection [

	subclassClassNames := aCollection
]

{ #category : 'private - source' }
MCPScopeQuery >> usesImplicitImageScope [

	^ self packageNames isEmpty and: [
			  self classNames isEmpty and: [
				  self hierarchyClassNames isEmpty and: [ self subclassClassNames isEmpty and: [ self parentClassNames isEmpty ] ] ] ]
]

{ #category : 'accessing' }
MCPScopeQuery >> warnings [

	^ warnings ifNil: [ #(  ) ]
]
