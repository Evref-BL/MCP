"
Abstract icon specification used by MCP tools.

Subclasses describe how an icon should be rendered without forcing MCPTool instances to eagerly render PNG data URIs.
"
Class {
	#name : 'MCPToolIconSpec',
	#superclass : 'Object',
	#category : 'MCP-Structure',
	#package : 'MCP',
	#tag : 'Structure'
}

{ #category : 'private - mapping' }
MCPToolIconSpec class >> actionIconForToolNameParts: parts [

	(parts size = 2 and: [
		 parts first = 'screenshot' and: [ parts last = 'capture' ] ])
		ifTrue: [ ^ #smallScreenshot ].
	^ self iconNameForAction: parts last
]

{ #category : 'private - mapping' }
MCPToolIconSpec class >> actionIconMap [

	^ Dictionary newFrom: {
			  ('search' -> #search).
			  ('get' -> #inspect).
			  ('call' -> #go).
			  ('verify' -> #accept).
			  ('list' -> #browse).
			  ('create' -> #add).
			  ('attach' -> #publish).
			  ('update' -> #edit).
			  ('export' -> #saveToUrl).
			  ('commit' -> #save).
			  ('fetch' -> #remote).
			  ('pull' -> #down).
			  ('push' -> #up).
			  ('switch' -> #refreshCircling).
			  ('checkout' -> #openFromUrl).
			  ('adopt' -> #accept).
			  ('load' -> #openFromUrl).
			  ('remove' -> #delete).
			  ('add' -> #add).
			  ('up' -> #up).
			  ('down' -> #down).
			  ('apply' -> #accept).
			  ('revert' -> #undo).
			  ('run' -> #play).
			  ('capture' -> #image).
			  ('set' -> #add).
			  ('enable' -> #enable).
			  ('disable' -> #disable).
			  ('clear' -> #clearField).
			  ('evaluate' -> #go).
			  ('into' -> #into).
			  ('over' -> #over).
			  ('through' -> #through).
			  ('restart' -> #restart).
			  ('resume' -> #play).
			  ('terminate' -> #stop).
			  ('repair' -> #repair).
			  ('rewrite' -> #refreshCircling) }
]

{ #category : 'instance creation' }
MCPToolIconSpec class >> baseIconNamed: aBaseIconSymbol badgeIconNamed: aBadgeIconSymbol [

	^ MCPCompositeToolIconSpec
		  baseIconNamed: aBaseIconSymbol
		  badgeIconNamed: aBadgeIconSymbol
]

{ #category : 'instance creation' }
MCPToolIconSpec class >> baseIconNamed: aBaseIconSymbol leftBadgeIconNamed: aLeftBadgeIconSymbol rightBadgeIconNamed: aRightBadgeIconSymbol [

	^ MCPCompositeToolIconSpec
		  baseIconNamed: aBaseIconSymbol
		  leftBadgeIconNamed: aLeftBadgeIconSymbol
		  rightBadgeIconNamed: aRightBadgeIconSymbol
]

{ #category : 'private - mapping' }
MCPToolIconSpec class >> domainIconMap [

	^ Dictionary newFrom: {
			  ('tool' -> #tools).
			  ('repository' -> #git).
			  ('baseline' -> #configuration).
			  ('package' -> #package).
			  ('class' -> #class).
			  ('method' -> #page).
			  ('history' -> #history).
			  ('test' -> #testRunner).
			  ('screenshot' -> #window).
			  ('debug' -> #bug).
			  ('image' -> #pharoHalfScale) }
]

{ #category : 'instance creation' }
MCPToolIconSpec class >> forToolName: toolNameString [

	| actionIcon baseIcon objectIcon parts |
	parts := toolNameString asString substrings: '_'.
	parts ifEmpty: [ ^ self named: #tools ].
	baseIcon := self iconNameForDomain: parts first.
	actionIcon := self actionIconForToolNameParts: parts.
	objectIcon := self objectIconForToolNameParts: parts.
	objectIcon ifNil: [
		^ self baseIconNamed: baseIcon badgeIconNamed: actionIcon ].
	^ self
		  baseIconNamed: baseIcon
		  leftBadgeIconNamed: objectIcon
		  rightBadgeIconNamed: actionIcon
]

{ #category : 'private - mapping' }
MCPToolIconSpec class >> iconNameForAction: actionString [

	^ self actionIconMap at: actionString asString ifAbsent: [ #go ]
]

{ #category : 'private - mapping' }
MCPToolIconSpec class >> iconNameForDomain: domainString [

	^ self domainIconMap at: domainString asString ifAbsent: [ #tools ]
]

{ #category : 'private - mapping' }
MCPToolIconSpec class >> iconNameForObject: objectString [

	^ self objectIconMap at: objectString asString ifAbsent: [ #info ]
]

{ #category : 'instance creation' }
MCPToolIconSpec class >> named: anIconSymbol [

	^ MCPNamedToolIconSpec iconNamed: anIconSymbol
]

{ #category : 'private - mapping' }
MCPToolIconSpec class >> objectIconForToolNameParts: parts [

	| objectWord |
	objectWord := self objectWordForToolNameParts: parts.
	objectWord ifNil: [ ^ nil ].
	^ self iconNameForObject: objectWord
]

{ #category : 'private - mapping' }
MCPToolIconSpec class >> objectIconMap [

	^ Dictionary newFrom: {
			  ('identity' -> #info).
			  ('change' -> #changeUpdate).
			  ('branch' -> #branch).
			  ('head' -> #up).
			  ('metadata' -> #info).
			  ('source' -> #workspace).
			  ('equivalent' -> #diff).
			  ('implementor' -> #referencesUpsideDown).
			  ('sender' -> #references).
			  ('class' -> #class).
			  ('variable' -> #instVarsSelected).
			  ('classVariable' -> #classVarsSelected).
			  ('reference' -> #references).
			  ('selector' -> #keymapBrowser).
			  ('protocol' -> #protocolProtected).
			  ('file' -> #folder).
			  ('entry' -> #changeUpdate).
			  ('coverage' -> #processBrowser).
			  ('name' -> #string).
			  ('superclass' -> #hierarchy).
			  ('package' -> #package).
			  ('comment' -> #comments).
			  ('slot' -> #instVarsSelected).
			  ('trait' -> #trait).
			  ('pool' -> #database).
			  ('layout' -> #objects).
			  ('session' -> #announcement).
			  ('candidate' -> #question).
			  ('state' -> #info).
			  ('expression' -> #workspace).
			  ('breakpoint' -> #breakpoint).
			  ('method' -> #page).
			  ('test' -> #testRunner) }
]

{ #category : 'private - mapping' }
MCPToolIconSpec class >> objectWordForToolNameParts: parts [

	| domain middle |
	parts size < 3 ifTrue: [ ^ nil ].
	domain := parts first.
	middle := parts copyFrom: 2 to: parts size - 1.
	domain = 'class' ifTrue: [
			(middle includes: 'slot') ifTrue: [ ^ 'slot' ].
			(middle includes: 'slots') ifTrue: [ ^ 'slot' ].
			(middle includes: 'traits') ifTrue: [ ^ 'trait' ].
			(middle includes: 'variables') ifTrue: [ ^ 'classVariable' ].
			(middle includes: 'pools') ifTrue: [ ^ 'pool' ].
			^ middle last ].
	domain = 'method' ifTrue: [
			(middle includes: 'class') ifTrue: [ ^ 'class' ].
			(middle includes: 'variable') ifTrue: [ ^ 'variable' ].
			(middle includes: 'reference') ifTrue: [ ^ 'reference' ].
			^ middle first ].
	^ middle first
]

{ #category : 'comparing' }
MCPToolIconSpec >> cacheKey [

	self subclassResponsibility
]

{ #category : 'rendering' }
MCPToolIconSpec >> renderUsing: anIconFactory [

	self subclassResponsibility
]
