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
	#category : 'MCP-Queries',
	#package : 'MCP',
	#tag : 'Queries'
}

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
MCPScopeQuery >> recordMissingClassNamed: className inScope: scopeName [

	| suggestions |
	suggestions := MCPScopeNameSuggester classSuggestionsFor: className.
	self requiresCompleteScope ifTrue: [
			^ MCPCommandError
				  signalMissingClassNamed: className
				  scopeName: scopeName ].
	warnings ifNil: [ self resetWarnings ].
	warnings add: (MCPScopeNameSuggester
			 missingNameWarningForKind: 'Class'
			 name: className
			 scope: scopeName
			 suggestions: suggestions).
	^ nil
]

{ #category : 'private - resolution' }
MCPScopeQuery >> recordMissingPackageNamed: packageName inScope: scopeName [

	| suggestions |
	suggestions := MCPScopeNameSuggester packageSuggestionsFor:
		               packageName.
	self requiresCompleteScope ifTrue: [
			^ MCPCommandError
				  signalMissingPackageNamed: packageName
				  scopeName: scopeName ].
	warnings ifNil: [ self resetWarnings ].
	warnings add: (MCPScopeNameSuggester
			 missingNameWarningForKind: 'Package'
			 name: packageName
			 scope: scopeName
			 suggestions: suggestions).
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
					  self hierarchyClassNames isEmpty and: [
						  self subclassClassNames isEmpty and: [
							  self parentClassNames isEmpty ] ] ] ]
]

{ #category : 'accessing' }
MCPScopeQuery >> warnings [

	^ warnings ifNil: [ #(  ) ]
]
