"
Instance-scoped catalog of MCP tools.

A registry discovers built-in concrete MCPTool subclasses, owns one reusable instance of each registered tool, owns the exposure policy applied to those registrations, and provides lookup, grouping, static-surface selection, contract composition, and catalog search. Intrinsic metadata belongs to tools; visibility overrides belong to MCPToolExposurePolicy.
"
Class {
	#name : 'MCPToolRegistry',
	#superclass : 'Object',
	#instVars : [
		'registrations',
		'exposurePolicy'
	],
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'instance creation' }
MCPToolRegistry class >> default [

	^ self new
		  resetRegistrations;
		  yourself
]

{ #category : 'instance creation' }
MCPToolRegistry class >> empty [

	^ self new
]

{ #category : 'tools' }
MCPToolRegistry >> contractForTool: aTool includeOutputSchema: includeOutputSchema [

	| contract |
	contract := aTool contractIncludingOutputSchema: includeOutputSchema.
	contract at: #exposure put: (self exposureForTool: aTool).
	^ contract
]

{ #category : 'tools' }
MCPToolRegistry >> contractForToolNamed: aToolName includeOutputSchema: includeOutputSchema [

	| tool |
	tool := self toolNamed: aToolName ifAbsent: [ Error signal: 'Unknown MCP tool: ' , aToolName asString ].
	^ self contractForTool: tool includeOutputSchema: includeOutputSchema
]

{ #category : 'registrations' }
MCPToolRegistry >> defaultRegistrations [

	| tools |
	tools := (MCPTool concreteSubclasses
		          select: [ :toolClass | toolClass shouldAutoRegister ]
		          thenCollect: [ :toolClass | toolClass newForRegistry: self ]) asArray.
	tools sort: [ :left :right |
			left groupName = right groupName
				ifTrue: [ left name <= right name ]
				ifFalse: [ left groupName <= right groupName ] ].
	^ tools collect: [ :tool | MCPToolRegistration tool: tool ]
]

{ #category : 'tools' }
MCPToolRegistry >> exposureForTool: aTool [

	| registration |
	registration := self registrationForTool: aTool ifAbsent: [ Error signal: 'MCP tool is not registered: ' , aTool name ].
	^ self exposurePolicy exposureForToolRegistration: registration
]

{ #category : 'accessing' }
MCPToolRegistry >> exposurePolicy [

	^ exposurePolicy
]

{ #category : 'accessing' }
MCPToolRegistry >> exposurePolicy: aToolExposurePolicy [

	self validateExposurePolicy: aToolExposurePolicy.
	exposurePolicy := aToolExposurePolicy
]

{ #category : 'testing' }
MCPToolRegistry >> includesToolNamed: aToolName [

	^ self publicToolNames includes: aToolName asString
]

{ #category : 'initialization' }
MCPToolRegistry >> initialize [

	super initialize.
	exposurePolicy := MCPToolExposurePolicy default.
	self removeAllTools
]

{ #category : 'testing' }
MCPToolRegistry >> isStaticToolNamed: aToolName [

	| registration |
	registration := self registrationNamed: aToolName ifAbsent: [ ^ false ].
	^ self exposurePolicy isStaticToolRegistration: registration
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

	^ self registerTool: (aToolClass newForRegistry: self)
]

{ #category : 'registrations' }
MCPToolRegistry >> registerToolClasses: toolClasses [

	^ toolClasses collect: [ :eachToolClass | self registerToolClass: eachToolClass ]
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
MCPToolRegistry >> removeAllTools [

	registrations := #(  )
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

	^ (self staticTools collect: [ :each | each name ]) asArray
]

{ #category : 'configuration' }
MCPToolRegistry >> staticToolNames: aCollection [

	self exposurePolicy: (MCPToolExposurePolicy staticToolNames: aCollection)
]

{ #category : 'tools' }
MCPToolRegistry >> staticTools [

	^ (self registrations select: [ :each | self exposurePolicy isStaticToolRegistration: each ] thenCollect: [ :each | each tool ])
		  asArray
]

{ #category : 'tools' }
MCPToolRegistry >> staticToolsDictionary [

	| dictionary |
	dictionary := Dictionary new.
	self staticTools do: [ :tool | dictionary at: tool name put: tool ].
	^ dictionary
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

{ #category : 'private - exposure' }
MCPToolRegistry >> validateExposurePolicy: aToolExposurePolicy [

	| staticNames unknown |
	staticNames := aToolExposurePolicy explicitStaticToolNames.
	staticNames ifNil: [ ^ self ].
	unknown := staticNames reject: [ :each | self includesToolNamed: each ].
	unknown ifNotEmpty: [ Error signal: 'Unknown MCP tool(s) in exposure policy: ' , unknown printString ]
]
