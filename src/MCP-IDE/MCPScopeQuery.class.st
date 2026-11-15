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
		'requiresCompleteScope',
		'missingNames'
	],
	#category : 'MCP-IDE-Queries',
	#package : 'MCP-IDE',
	#tag : 'Queries'
}

{ #category : 'phrasing' }
MCPScopeQuery class >> distinctNamesAmong: someNames [
	"Each name once, as a string, in the order given."

	| names |
	names := OrderedCollection new.
	someNames do: [ :each | (names includes: each asString) ifFalse: [ names add: each asString ] ].
	^ names asArray
]

{ #category : 'phrasing' }
MCPScopeQuery class >> listPhraseFor: someNames [
	"A, A and B, A, B and C."

	^ String streamContents: [ :stream |
			  someNames withIndexDo: [ :each :index |
					  index > 1 ifTrue: [
							  stream nextPutAll: (index = someNames size
									   ifTrue: [ ' and ' ]
									   ifFalse: [ ', ' ]) ].
					  stream nextPutAll: each asString ] ]
]

{ #category : 'phrasing' }
MCPScopeQuery class >> phraseForNames: someNames one: oneLead several: severalLead many: aCountTemplate [
	"How a scope names one kind of entry: one by its name, two or three listed, and from four on by their count, which aCountTemplate words with {1}, since a longer list only reads the request back. Nil for no names."

	someNames isEmpty ifTrue: [ ^ nil ].
	someNames size > 3 ifTrue: [ ^ aCountTemplate format: { someNames size } ].
	^ String streamContents: [ :stream |
			  someNames size = 1
				  ifTrue: [
						  stream
							  nextPutAll: oneLead;
							  nextPutAll: someNames first asString ]
				  ifFalse: [
						  stream
							  nextPutAll: severalLead;
							  nextPutAll: (self listPhraseFor: someNames) ] ]
]

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

{ #category : 'phrasing' }
MCPScopeQuery >> existingNamesAmong: someNames inScope: scopeName [
	"The names of someNames, given as scopeName, that the last run resolved, once each, in the order given."

	| missing |
	missing := self missingNamesInScope: scopeName.
	^ (self class distinctNamesAmong: someNames) reject: [ :each | missing includes: each ]
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
MCPScopeQuery >> missingNamesInScope: scopeName [
	"The names given as scopeName that the last run could not resolve."

	missingNames ifNil: [ ^ #(  ) ].
	^ missingNames at: scopeName ifAbsent: [ #(  ) ]
]

{ #category : 'phrasing' }
MCPScopeQuery >> namesNothingThatExists [
	"Whether the scope was given names and none of them exists, so the query looked nowhere."

	self usesImplicitImageScope ifTrue: [ ^ false ].
	^ self scopePhraseParts isEmpty
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
MCPScopeQuery >> recordMissingName: aName inScope: scopeName [
	"A name the scope was given as scopeName and could not resolve. Its warning names it; the phrase for where the query looked leaves it out of that kind of entry only, since the same name may exist as another kind: a class that is no package."

	missingNames ifNil: [ missingNames := Dictionary new ].
	(missingNames at: scopeName ifAbsentPut: [ Set new ]) add: aName asString
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

	warnings := OrderedCollection new.
	missingNames := Dictionary new
]

{ #category : 'phrasing' }
MCPScopeQuery >> scopePhrase [
	"Where the query looks, in words: the image when it was given no name, otherwise the names it was given that exist. Nil when it was given names and none exists, since it then looks nowhere (namesNothingThatExists)."

	| parts |
	self usesImplicitImageScope ifTrue: [ ^ 'the image' ].
	parts := self scopePhraseParts.
	parts ifEmpty: [ ^ nil ].
	^ ' and ' join: parts
]

{ #category : 'phrasing' }
MCPScopeQuery >> scopePhraseParts [
	"One phrase per kind of name the scope was given, in a fixed order, each naming only the names that exist as that kind."

	| parts |
	parts := OrderedCollection new.
	{
		(self class
			 phraseForNames: (self existingNamesAmong: self packageNames inScope: 'packages')
			 one: 'package '
			 several: 'packages '
			 many: '{1} packages').
		(self class
			 phraseForNames: (self existingNamesAmong: self classNames inScope: 'classes')
			 one: ''
			 several: ''
			 many: '{1} classes').
		(self class
			 phraseForNames: (self existingNamesAmong: self hierarchyClassNames inScope: 'hierarchyClasses')
			 one: 'the hierarchy of '
			 several: 'the hierarchies of '
			 many: 'the hierarchies of {1} classes').
		(self class
			 phraseForNames: (self existingNamesAmong: self subclassClassNames inScope: 'subclassClasses')
			 one: 'the subclasses of '
			 several: 'the subclasses of '
			 many: 'the subclasses of {1} classes').
		(self class
			 phraseForNames: (self existingNamesAmong: self parentClassNames inScope: 'parentClasses')
			 one: 'the superclasses of '
			 several: 'the superclasses of '
			 many: 'the superclasses of {1} classes') } do: [ :each | each ifNotNil: [ parts add: each ] ].
	^ parts asArray
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
