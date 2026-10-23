"
Instance-scoped catalog of MCP tools.

A registry owns one reusable instance of each tool, keyed by tool name and kept in the order the tools were discovered or added, and decides which of them are advertised. Intrinsic metadata belongs to the tools themselves.

Two words, consistently. A *registered* tool is in the catalog and reachable through tool_search, tool_get and tool_call. An *advertised* tool is also in tools/list. advertisedToolNames carries that choice in three states: nil leaves it to each tool's own default exposure, #all advertises everything, and a set of names advertises exactly those.

A registry built with #default discovers tool classes and keeps doing so: it outlives the classes it found, so it rediscovers them whenever the set of auto-registering tool classes changes. Tools added by hand survive that rediscovery as long as their class does. A registry built with #empty is curated rather than discovered, holds exactly what was added to it, and never rediscovers.
"
Class {
	#name : 'MCPToolRegistry',
	#superclass : 'Object',
	#instVars : [
		'tools',
		'advertisedToolNames',
		'discoversToolClasses',
		'discoveredToolClasses'
	],
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'instance creation' }
MCPToolRegistry class >> default [

	^ self new
		  resetTools;
		  yourself
]

{ #category : 'instance creation' }
MCPToolRegistry class >> empty [

	^ self new
]

{ #category : 'tools' }
MCPToolRegistry >> addTool: aToolOrToolClass [
	"Add a tool to the catalog, as a class or as a ready instance, and answer it."

	| tool |
	tool := aToolOrToolClass isBehavior
		        ifTrue: [ aToolOrToolClass newForRegistry: self ]
		        ifFalse: [ aToolOrToolClass ].
	(self includesToolNamed: tool name) ifTrue: [ Error signal: 'MCP tool already registered: ' , tool name ].
	self toolsByName at: tool name put: tool.
	^ tool
]

{ #category : 'tools' }
MCPToolRegistry >> addTools: toolsOrToolClasses [

	^ (toolsOrToolClasses collect: [ :each | self addTool: each ]) asArray
]

{ #category : 'advertising' }
MCPToolRegistry >> advertiseAllTools [

	advertisedToolNames := #all
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
		Error signal: 'Unknown MCP tool(s): ' , unknown asArray printString , '. Known tools: ' , self toolNames printString ].
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

	^ (self advertisedTools collect: [ :each | each name ]) asArray
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
MCPToolRegistry >> autoRegisteringToolClasses [

	^ (MCPTool concreteSubclasses select: [ :toolClass | toolClass shouldAutoRegister ]) asSet
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

{ #category : 'tools' }
MCPToolRegistry >> defaultTools [

	| discovered |
	discovered := (self autoRegisteringToolClasses collect: [ :toolClass | toolClass newForRegistry: self ]) asArray.
	discovered sort: [ :left :right |
			left groupName = right groupName
				ifTrue: [ left name <= right name ]
				ifFalse: [ left groupName <= right groupName ] ].
	^ discovered
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

	^ self toolsByName includesKey: aToolName asString
]

{ #category : 'initialization' }
MCPToolRegistry >> initialize [

	super initialize.
	self removeAllTools
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

{ #category : 'tools' }
MCPToolRegistry >> isTool: aTool rankedBefore: anotherTool [
	"Break a score tie in favor of the more general tool: fewer name segments first, then alphabetically."

	| segments otherSegments |
	segments := (aTool name findTokens: '-_') size.
	otherSegments := (anotherTool name findTokens: '-_') size.
	segments = otherSegments ifTrue: [ ^ aTool name <= anotherTool name ].
	^ segments < otherSegments
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

{ #category : 'tools' }
MCPToolRegistry >> rediscoverToolClassesIfChanged [
	"A discovering registry outlives the tool classes it found. Loading or removing tool classes in a running image left it answering its old catalog until someone reset it by hand, so it notices here instead.

	It takes in what appeared and drops what vanished, rather than rebuilding. Rebuilding would undo every hand edit the catalog has had: a tool added by hand, and a tool deliberately removed, which would come back the next time any tool class was loaded."

	| discovered appeared vanished |
	discoversToolClasses ifFalse: [ ^ self ].
	discovered := self autoRegisteringToolClasses.
	discovered = discoveredToolClasses ifTrue: [ ^ self ].
	vanished := discoveredToolClasses difference: discovered.
	appeared := (discovered difference: discoveredToolClasses) asSortedCollection: [ :left :right | left toolName <= right toolName ].
	discoveredToolClasses := discovered.
	(tools keys select: [ :each | vanished includes: (tools at: each) class ]) do: [ :each | tools removeKey: each ].
	appeared do: [ :toolClass |
		(self includesToolNamed: toolClass toolName) ifFalse: [ tools at: toolClass toolName put: (toolClass newForRegistry: self) ] ]
]

{ #category : 'tools' }
MCPToolRegistry >> removeAllTools [

	discoversToolClasses := false.
	discoveredToolClasses := nil.
	tools := OrderedDictionary new
]

{ #category : 'tools' }
MCPToolRegistry >> removeToolNamed: aToolName [

	self toolsByName removeKey: aToolName asString ifAbsent: [ nil ]
]

{ #category : 'tools' }
MCPToolRegistry >> resetTools [

	discoversToolClasses := true.
	discoveredToolClasses := self autoRegisteringToolClasses.
	tools := OrderedDictionary new.
	self defaultTools do: [ :each | tools at: each name put: each ]
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

	^ (self tools collect: [ :each | each class ]) asArray
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
	^ (groups collect: [ :each | each key -> each value asArray ]) asArray
]

{ #category : 'tools' }
MCPToolRegistry >> toolNamed: aToolName ifAbsent: absentBlock [

	^ self toolsByName at: aToolName asString ifAbsent: absentBlock
]

{ #category : 'tools' }
MCPToolRegistry >> toolNames [

	^ (self tools collect: [ :each | each name ]) asArray
]

{ #category : 'tools' }
MCPToolRegistry >> tools [

	^ self toolsByName values asArray
]

{ #category : 'private' }
MCPToolRegistry >> toolsByName [

	self rediscoverToolClassesIfChanged.
	^ tools
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
	^ (scoredTools collect: [ :each | each value ]) asArray
]
