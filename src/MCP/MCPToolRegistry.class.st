"
Instance-scoped catalog of MCP tools.

A registry discovers built-in concrete MCPTool subclasses, owns one reusable instance of each registered tool, and provides lookup, grouping, static-surface selection, and catalog search. Intrinsic metadata belongs to the tools. Visibility overrides belong to MCPToolExposurePolicy.
"
Class {
	#name : 'MCPToolRegistry',
	#superclass : 'Object',
	#instVars : [
		'registrations'
	],
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'registrations' }
MCPToolRegistry >> defaultRegistrations [

	| tools |
	tools := (MCPTool concreteSubclasses select: [ :toolClass | toolClass isBuiltIn ] thenCollect: [ :toolClass | toolClass new ])
		         asArray.
	tools sort: [ :left :right |
			left groupName = right groupName
				ifTrue: [ left name <= right name ]
				ifFalse: [ left groupName <= right groupName ] ].
	^ tools collect: [ :tool | MCPToolRegistration tool: tool ]
]

{ #category : 'testing' }
MCPToolRegistry >> includesToolNamed: aToolName [

	^ self publicToolNames includes: aToolName asString
]

{ #category : 'initialization' }
MCPToolRegistry >> initialize [

	super initialize.
	self resetRegistrations
]

{ #category : 'tools' }
MCPToolRegistry >> publicToolClasses [

	^ (self registrations collect: [ :each | each toolClass ]) asArray
]

{ #category : 'tools' }
MCPToolRegistry >> publicToolGroups [

	| groups |
	groups := OrderedCollection new.
	self registrations do: [ :registration |
			| group |
			group := groups detect: [ :each | each key = registration groupName ] ifNone: [
					         groups add: registration groupName -> OrderedCollection new.
					         groups last ].
			group value add: registration toolClass ].
	^ (groups collect: [ :each | each key -> each value asArray ]) asArray
]

{ #category : 'tools' }
MCPToolRegistry >> publicToolNames [

	^ (self registrations collect: [ :each | each name ]) asArray
]

{ #category : 'tools' }
MCPToolRegistry >> publicTools [

	^ self registrations collect: [ :each | each tool ]
]

{ #category : 'tools' }
MCPToolRegistry >> queryTermAlternativesFor: aTerm [

	| alternatives singular term |
	term := aTerm asString asLowercase.
	alternatives := OrderedCollection with: term.
	singular := self singularSearchTermFor: term.
	singular = term ifFalse: [ alternatives add: singular ].
	^ alternatives asSet asArray
]

{ #category : 'tools' }
MCPToolRegistry >> queryTermsFrom: queryString [

	| normalized |
	normalized := queryString ifNil: [ ^ #(  ) ] ifNotNil: [ :value | value asString trimBoth asLowercase ].
	normalized isEmpty ifTrue: [ ^ #(  ) ].
	^ normalized findTokens: ' -_'
]

{ #category : 'registrations' }
MCPToolRegistry >> registerTool: aTool [

	| registration |
	registration := MCPToolRegistration tool: aTool.
	(self includesToolNamed: registration name) ifTrue: [ Error signal: 'MCP tool already registered: ' , registration name ].
	registrations := self registrations copyWith: registration.
	^ registration
]

{ #category : 'registrations' }
MCPToolRegistry >> registerToolClass: aToolClass [

	^ self registerTool: aToolClass new
]

{ #category : 'registrations' }
MCPToolRegistry >> registrationForTool: aTool ifAbsent: absentBlock [

	^ self registrationNamed: aTool name ifAbsent: absentBlock
]

{ #category : 'registrations' }
MCPToolRegistry >> registrationForToolClass: aToolClass ifAbsent: absentBlock [

	^ self registrations detect: [ :each | each toolClass = aToolClass ] ifNone: absentBlock
]

{ #category : 'registrations' }
MCPToolRegistry >> registrationNamed: aToolName ifAbsent: absentBlock [

	| toolName |
	toolName := aToolName asString.
	^ self registrations detect: [ :each | each name = toolName ] ifNone: absentBlock
]

{ #category : 'registrations' }
MCPToolRegistry >> registrations [

	^ registrations
]

{ #category : 'registrations' }
MCPToolRegistry >> resetRegistrations [

	registrations := self defaultRegistrations
]

{ #category : 'tools' }
MCPToolRegistry >> singularSearchTermFor: aTerm [

	| term |
	term := aTerm asString asLowercase.
	(term endsWith: 'ies') ifTrue: [ ^ (term allButLast: 3) , 'y' ].
	(term endsWith: 'ses') ifTrue: [ ^ term allButLast: 2 ].
	((term endsWith: 's') and: [ (term endsWith: 'ss') not ]) ifTrue: [ ^ term allButLast ].
	^ term
]

{ #category : 'tools' }
MCPToolRegistry >> staticToolNames [

	^ (self registrations select: [ :each | each isStaticByDefault ] thenCollect: [ :each | each name ]) asArray
]

{ #category : 'tools' }
MCPToolRegistry >> staticTools [

	^ self staticToolsUsingPolicy: (MCPToolExposurePolicy forRegistry: self)
]

{ #category : 'tools' }
MCPToolRegistry >> staticToolsDictionary [

	^ self staticToolsDictionaryUsingPolicy: (MCPToolExposurePolicy forRegistry: self)
]

{ #category : 'tools' }
MCPToolRegistry >> staticToolsDictionaryUsingPolicy: aToolExposurePolicy [

	| dictionary |
	dictionary := Dictionary new.
	(self staticToolsUsingPolicy: aToolExposurePolicy) do: [ :tool | dictionary at: tool name put: tool ].
	^ dictionary
]

{ #category : 'tools' }
MCPToolRegistry >> staticToolsUsingPolicy: aToolExposurePolicy [

	^ (self registrations select: [ :each | aToolExposurePolicy isStaticToolRegistration: each ] thenCollect: [ :each | each tool ])
		  asArray
]

{ #category : 'tools' }
MCPToolRegistry >> tool: aTool matchesQuery: queryString group: groupString [

	| group queryTerms searchableText |
	group := groupString ifNotNil: [ :value | value asString trimBoth asLowercase ].
	(group isNotNil and: [ group isNotEmpty and: [ group ~= aTool groupName ] ]) ifTrue: [ ^ false ].
	queryTerms := self queryTermsFrom: queryString.
	queryTerms ifEmpty: [ ^ true ].
	searchableText := aTool searchableText asLowercase.
	^ queryTerms anySatisfy: [ :each |
		  (self queryTermAlternativesFor: each) anySatisfy: [ :alternative | searchableText includesSubstring: alternative ] ]
]

{ #category : 'tools' }
MCPToolRegistry >> toolNamed: aToolName ifAbsent: absentBlock [

	^ (self registrationNamed: aToolName ifAbsent: [ ^ absentBlock value ]) tool
]

{ #category : 'tools' }
MCPToolRegistry >> toolsMatchingQuery: queryString group: groupString [

	^ (self publicTools select: [ :tool | self tool: tool matchesQuery: queryString group: groupString ]) asArray
]

{ #category : 'registrations' }
MCPToolRegistry >> unregisterToolNamed: aToolName [

	| toolName |
	toolName := aToolName asString.
	registrations := self registrations reject: [ :each | each name = toolName ]
]
