"
Instance-scoped catalog of MCP tools.

Two words, consistently. A *registered* tool is in the catalog and reachable through tool_search, tool_get and tool_call. An *advertised* tool is also in tools/list. advertisedToolNames carries that choice in three states: nil leaves it to each tool's own default exposure, #all advertises everything, and a set of names advertises exactly those.

Holding, discovery and rediscovery come from MCPRegistry. What lives here is the advertising split, which the other registries have no equivalent of, and the ranking tool_search uses.
"
Class {
	#name : 'MCPToolRegistry',
	#superclass : 'MCPRegistry',
	#instVars : [
		'advertisedToolNames'
	],
	#category : 'MCP-Registries',
	#package : 'MCP',
	#tag : 'Registries'
}

{ #category : 'tools' }
MCPToolRegistry >> addTool: aToolOrToolClass [
	"Add a tool to the catalog, as a class or as a ready instance, and answer it."

	^ self add: aToolOrToolClass
]

{ #category : 'tools' }
MCPToolRegistry >> addTools: toolsOrToolClasses [

	^ self addAll: toolsOrToolClasses
]

{ #category : 'advertising' }
MCPToolRegistry >> advertiseAllTools [

	advertisedToolNames := #all
]

{ #category : 'advertising' }
MCPToolRegistry >> advertiseTool: aToolOrToolClassOrName [
	"Show one more tool in tools/list. The advertised set can be implicit, meaning each tool's own default or all of them, so it is materialized before one name is added to it."

	self advertiseTools: (self advertisedToolNames copyWith: (self advertisedNameFor: aToolOrToolClassOrName))
]

{ #category : 'advertising' }
MCPToolRegistry >> advertiseToolDefaults [

	advertisedToolNames := nil
]

{ #category : 'advertising' }
MCPToolRegistry >> advertiseTools: toolsOrToolClassesOrNames [
	"Say which tools tools/list should show, as classes, tool instances or names. Anything not in the catalog yet is added, so the order of configuration does not matter for a class. A bare name matching nothing is a typo, and the error says what is known."

	| names unknown |
	names := toolsOrToolClassesOrNames collect: [ :each | self advertisedNameFor: each ].
	unknown := names reject: [ :each | self includesToolNamed: each ].
	unknown ifNotEmpty: [
			Error signal: (String streamContents: [ :stream |
					 stream << 'Unknown MCP tool(s): ' << unknown asArray printString << '. Known tools: ' << self toolNames printString ]) ].
	advertisedToolNames := names asSet
]

{ #category : 'private - advertising' }
MCPToolRegistry >> advertisedNameFor: aToolOrToolClassOrName [
	"Answer the tool name this stands for, adding it to the catalog when it is a tool we do not have yet. Symbols answer a String, because a Symbol never equals the String a tool answers for its name."

	| toolName |
	aToolOrToolClassOrName isString ifTrue: [ ^ aToolOrToolClassOrName asString ].
	toolName := aToolOrToolClassOrName isBehavior
		            ifTrue: [ aToolOrToolClassOrName toolName ]
		            ifFalse: [ aToolOrToolClassOrName name ].
	(self includesToolNamed: toolName) ifFalse: [ self addTool: aToolOrToolClassOrName ].
	^ toolName
]

{ #category : 'advertising' }
MCPToolRegistry >> advertisedToolNames [

	^ self advertisedTools collect: [ :each | each name ] as: Array
]

{ #category : 'advertising' }
MCPToolRegistry >> advertisedTools [

	^ (self tools select: [ :each | self isToolAdvertised: each ]) asArray
]

{ #category : 'advertising' }
MCPToolRegistry >> advertisedToolsDictionary [
	"Keyed by tool name for lookup, ordered so tools/list keeps the order the catalog ranked them in. Clients cache that list and feed it to a model, so a surface that reshuffles between calls costs cache hits for no reason."

	| dictionary |
	dictionary := OrderedDictionary new.
	self advertisedTools do: [ :tool | dictionary at: tool name put: tool ].
	^ dictionary
]

{ #category : 'tools' }
MCPToolRegistry >> contractForTool: aTool [

	| contract |
	contract := aTool contract.
	contract at: #exposure put: (self exposureForTool: aTool).
	^ contract
]

{ #category : 'tools' }
MCPToolRegistry >> contractForToolNamed: aToolName [

	| tool |
	tool := self toolNamed: aToolName ifAbsent: [ Error signal: 'Unknown MCP tool: ' , aToolName asString ].
	^ self contractForTool: tool
]

{ #category : 'discovery' }
MCPToolRegistry >> defaultEntries [
	"Grouped, then alphabetical within a group, which is how the catalog reads to someone scanning it."

	^ (self autoRegisteringClasses collect: [ :each | self newEntryFrom: each ]) asSortedCollection: [ :left :right |
		  left groupName = right groupName
			  ifTrue: [ left name <= right name ]
			  ifFalse: [ left groupName <= right groupName ] ]
]

{ #category : 'tools' }
MCPToolRegistry >> descriptionWeightForTool: aTool queryTerm: aTerm [
	"Descriptions are prose, so common words like 'the' appear in most of them. A term found only here refines the ranking of a tool that already matches; it never makes one a match."

	^ ((self queryTermAlternativesFor: aTerm) anySatisfy: [ :each |
		   each size >= 3 and: [ aTool description asLowercase includesSubstring: each ] ])
		  ifTrue: [ 2 ]
		  ifFalse: [ 0 ]
]

{ #category : 'advertising' }
MCPToolRegistry >> exposureForTool: aTool [

	^ (self isToolAdvertised: aTool)
		  ifTrue: [ 'static' ]
		  ifFalse: [ 'discoverable' ]
]

{ #category : 'tools' }
MCPToolRegistry >> identityWeightForTool: aTool queryTerm: aTerm [
	"Answer how strongly aTerm identifies aTool through its name, keywords, or title. Terms shorter than three characters only count as an exact name segment or keyword: matching them as substrings would make every tool a match."

	| alternatives substringTerms toolName |
	alternatives := self queryTermAlternativesFor: aTerm.
	toolName := aTool name asLowercase.
	(alternatives anySatisfy: [ :each | (toolName findTokens: '-_') includes: each ]) ifTrue: [ ^ 10 ].
	(alternatives anySatisfy: [ :each | aTool keywords includes: each ]) ifTrue: [ ^ 6 ].
	substringTerms := alternatives select: [ :each | each size >= 3 ].
	(substringTerms anySatisfy: [ :each | toolName includesSubstring: each ]) ifTrue: [ ^ 5 ].
	(substringTerms anySatisfy: [ :each | aTool title asLowercase includesSubstring: each ]) ifTrue: [ ^ 3 ].
	^ 0
]

{ #category : 'testing' }
MCPToolRegistry >> includesToolNamed: aToolName [

	^ self includesKey: aToolName
]

{ #category : 'tools' }
MCPToolRegistry >> isTool: aTool rankedBefore: anotherTool [
	"Break a score tie in favor of the more general tool: fewer name segments first, then alphabetically."

	| segments otherSegments |
	segments := (aTool name findTokens: '-_') size.
	otherSegments := (anotherTool name findTokens: '-_') size.
	segments = otherSegments ifTrue: [ ^ aTool name <= anotherTool name ].
	^ segments < otherSegments
]

{ #category : 'advertising' }
MCPToolRegistry >> isToolAdvertised: aTool [

	advertisedToolNames ifNil: [ ^ aTool defaultExposure = 'static' ].
	advertisedToolNames = #all ifTrue: [ ^ true ].
	^ advertisedToolNames includes: aTool name
]

{ #category : 'testing' }
MCPToolRegistry >> isToolAdvertisedNamed: aToolName [

	^ self isToolAdvertised: (self toolNamed: aToolName ifAbsent: [ ^ false ])
]

{ #category : 'entries' }
MCPToolRegistry >> keyFor: aTool [

	^ aTool name
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

{ #category : 'entries' }
MCPToolRegistry >> registeredClass [

	^ MCPTool
]

{ #category : 'tools' }
MCPToolRegistry >> removeToolNamed: aToolName [

	self removeKey: aToolName
]

{ #category : 'tools' }
MCPToolRegistry >> scoreForTool: aTool queryTerms: queryTerms [
	"Term coverage dominates the score and the matched field breaks ties. Only a term identifying the tool counts as coverage, so a tool reached through its description alone scores zero and is not a match."

	| matchedTerms fieldWeight |
	matchedTerms := 0.
	fieldWeight := 0.
	queryTerms do: [ :term |
			| weight |
			weight := self identityWeightForTool: aTool queryTerm: term.
			weight > 0
				ifTrue: [
						matchedTerms := matchedTerms + 1.
						fieldWeight := fieldWeight + weight ]
				ifFalse: [ fieldWeight := fieldWeight + (self descriptionWeightForTool: aTool queryTerm: term) ] ].
	matchedTerms = 0 ifTrue: [ ^ 0 ].
	^ matchedTerms * 100 + fieldWeight
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
MCPToolRegistry >> toolClasses [

	^ self entryClasses
]

{ #category : 'tools' }
MCPToolRegistry >> toolGroups [

	| groups |
	groups := OrderedCollection new.
	self tools do: [ :tool |
			| group |
			group := groups detect: [ :each | each key = tool groupName ] ifNone: [
					         groups add: tool groupName -> OrderedCollection new.
					         groups last ].
			group value add: tool class ].
	^ groups collect: [ :each | each key -> each value asArray ] as: Array
]

{ #category : 'tools' }
MCPToolRegistry >> toolNamed: aToolName ifAbsent: absentBlock [

	^ self at: aToolName ifAbsent: absentBlock
]

{ #category : 'tools' }
MCPToolRegistry >> toolNames [

	^ self keys
]

{ #category : 'tools' }
MCPToolRegistry >> tools [

	^ self entries
]

{ #category : 'tools' }
MCPToolRegistry >> toolsMatchingQuery: queryString [
	"Answer the tools matching queryString, best match first. Query words rank tools instead of gating them, so a tool matching only some of the words is still answered. An empty query matches nothing."

	| queryTerms scoredTools |
	queryTerms := self queryTermsFrom: queryString.
	queryTerms ifEmpty: [ ^ #(  ) ].
	scoredTools := OrderedCollection new.
	self tools do: [ :tool |
			| score |
			score := self scoreForTool: tool queryTerms: queryTerms.
			score > 0 ifTrue: [ scoredTools add: score -> tool ] ].
	scoredTools sort: [ :left :right |
			left key = right key
				ifTrue: [ self isTool: left value rankedBefore: right value ]
				ifFalse: [ left key > right key ] ].
	^ scoredTools collect: [ :each | each value ] as: Array
]

{ #category : 'advertising' }
MCPToolRegistry >> unadvertiseTool: aToolOrToolClassOrName [
	"Stop showing one tool in tools/list. It stays in the catalog, so tool_search still finds it and tool_call still runs it."

	self advertiseTools: (self advertisedToolNames copyWithout: (self advertisedNameFor: aToolOrToolClassOrName))
]
