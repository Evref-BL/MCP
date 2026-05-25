Class {
	#name : 'MCPToolRegistry',
	#superclass : 'Object',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'tools' }
MCPToolRegistry class >> activationRequirementsForTool: aTool [

	^ #(  )
]

{ #category : 'tools' }
MCPToolRegistry class >> examplesForTool: aTool [

	^ #(  )
]

{ #category : 'tools' }
MCPToolRegistry class >> exposureForTool: aTool [

	^ (self isStaticTool: aTool)
		  ifTrue: [ 'static' ]
		  ifFalse: [ 'discoverable' ]
]

{ #category : 'tools' }
MCPToolRegistry class >> groupNameForToolClass: aToolClass [

	self publicToolGroups do: [ :group |
		(group value includes: aToolClass) ifTrue: [ ^ group key ] ].
	^ 'other'
]

{ #category : 'tools' }
MCPToolRegistry class >> inspectionForTool: aTool [

	| data |
	data := (self metadataForTool: aTool) copy.
	data at: #inputSchema put: aTool inputSchema asJRPCJSON.
	data at: #outputSchema put: aTool outputSchema asJRPCJSON.
	data at: #examples put: (self examplesForTool: aTool).
	data
		at: #activationRequirements
		put: (self activationRequirementsForTool: aTool).
	^ data
]

{ #category : 'testing' }
MCPToolRegistry class >> isStaticTool: aToolOrName [

	| toolName |
	toolName := (aToolOrName isString or: [ aToolOrName isSymbol ])
		            ifTrue: [ aToolOrName asString ]
		            ifFalse: [ aToolOrName name ].
	^ self staticToolNames includes: toolName
]

{ #category : 'tools' }
MCPToolRegistry class >> keywordsForTool: aTool [

	| keywords |
	keywords := OrderedCollection new.
	keywords addAll: (aTool name findTokens: '-').
	keywords addAll: (aTool title findTokens: ' -').
	keywords add: (self groupNameForToolClass: aTool class).
	^ (keywords collect: [ :each | each asString asLowercase ]) asSet
		  asArray
]

{ #category : 'tools' }
MCPToolRegistry class >> metadataForTool: aTool [

	^ {
		  (#name -> aTool name).
		  (#title -> aTool title).
		  (#description -> aTool description).
		  (#group -> (self groupNameForToolClass: aTool class)).
		  (#exposure -> (self exposureForTool: aTool)).
		  (#mutability -> (self mutabilityForTool: aTool)).
		  (#risk -> (self riskForTool: aTool)).
		  (#keywords -> (self keywordsForTool: aTool)).
		  (#schemaInspectionRequired
		   -> (self schemaInspectionRequiredForTool: aTool)) } asDictionary
]

{ #category : 'tools' }
MCPToolRegistry class >> mutabilityForTool: aTool [

	| executeTools readTools toolName |
	toolName := aTool name.
	readTools := #( 'discover-tools' 'inspect-tool' 'find-repositories'
	                'find-packages' 'find-classes' 'inspect-class'
	                'find-methods' 'inspect-method' 'capture-screenshot' ).
	executeTools := #( 'call-tool' 'run-tests' 'evaluate' ).
	(readTools includes: toolName) ifTrue: [ ^ 'read' ].
	(executeTools includes: toolName) ifTrue: [ ^ 'execute' ].
	^ 'write'
]

{ #category : 'tools' }
MCPToolRegistry class >> publicToolClasses [

	| classes |
	classes := OrderedCollection new.
	self publicToolGroups do: [ :group | classes addAll: group value ].
	^ classes asArray
]

{ #category : 'tools' }
MCPToolRegistry class >> publicToolGroups [

	^ {
		  ('tool-catalog' -> {
			   MCPToolDiscoverTools.
			   MCPToolInspectTool.
			   MCPToolCallTool }).
		  ('repositories' -> {
			   MCPToolFindRepositories.
			   MCPToolEditRepository.
			   MCPToolLoadRepository }).
		  ('packages' -> { MCPToolFindPackages }).
		  ('classes' -> {
			   MCPToolFindClasses.
			   MCPToolInspectClass.
			   MCPToolEditClass.
			   MCPToolRemoveClasses }).
		  ('methods' -> {
			   MCPToolFindMethods.
			   MCPToolInspectMethod.
			   MCPToolEditMethod.
			   MCPToolRewriteMethods.
			   MCPToolRemoveMethods }).
		  ('history' -> { MCPToolManageChangeHistory }).
		  ('tests' -> { MCPToolRunTests }).
		  ('ui' -> { MCPToolCaptureScreenshot }).
		  ('image-runtime' -> { MCPToolEvaluate }) }
]

{ #category : 'tools' }
MCPToolRegistry class >> publicTools [

	^ self publicToolClasses collect: [ :each | each new ]
]

{ #category : 'tools' }
MCPToolRegistry class >> riskForTool: aTool [

	| lowRisk mediumRisk toolName |
	toolName := aTool name.
	lowRisk := #( 'discover-tools' 'inspect-tool' 'find-repositories'
	              'find-packages' 'find-classes' 'inspect-class'
	              'find-methods' 'inspect-method' 'capture-screenshot' ).
	mediumRisk := #( 'call-tool' 'load-repository' 'run-tests'
	                 'evaluate' ).
	(lowRisk includes: toolName) ifTrue: [ ^ 'low' ].
	(mediumRisk includes: toolName) ifTrue: [ ^ 'medium' ].
	^ 'high'
]

{ #category : 'tools' }
MCPToolRegistry class >> schemaInspectionRequiredForTool: aTool [

	^ (self isStaticTool: aTool) not
]

{ #category : 'tools' }
MCPToolRegistry class >> searchableTextForTool: aTool [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: aTool name;
				  space;
				  nextPutAll: aTool title;
				  space;
				  nextPutAll: aTool description;
				  space;
				  nextPutAll: (self groupNameForToolClass: aTool class).
			  (self keywordsForTool: aTool) do: [ :keyword |
					  stream
						  space;
						  nextPutAll: keyword ] ]
]

{ #category : 'tools' }
MCPToolRegistry class >> staticToolClasses [

	^ {
		  MCPToolDiscoverTools.
		  MCPToolInspectTool.
		  MCPToolCallTool.
		  MCPToolFindPackages.
		  MCPToolFindClasses.
		  MCPToolInspectClass.
		  MCPToolEditClass.
		  MCPToolFindMethods.
		  MCPToolInspectMethod.
		  MCPToolEditMethod.
		  MCPToolEvaluate.
		  MCPToolRunTests }
]

{ #category : 'tools' }
MCPToolRegistry class >> staticToolNames [

	^ self staticTools collect: [ :each | each name ]
]

{ #category : 'tools' }
MCPToolRegistry class >> staticTools [

	^ self staticToolClasses collect: [ :each | each new ]
]

{ #category : 'tools' }
MCPToolRegistry class >> staticToolsDictionary [

	| dictionary |
	dictionary := Dictionary new.
	self staticTools do: [ :tool | dictionary at: tool name put: tool ].
	^ dictionary
]

{ #category : 'tools' }
MCPToolRegistry class >> tool: aTool matchesQuery: queryString group: groupString includeStatic: includeStatic [

	| group normalizedQuery |
	(includeStatic not and: [ self isStaticTool: aTool ]) ifTrue: [
		^ false ].
	group := groupString
		         ifNil: [ nil ]
		         ifNotNil: [ :value | value asString trimBoth asLowercase ].
	(group notNil and: [ group isEmpty not ]) ifTrue: [
		group = (self groupNameForToolClass: aTool class) ifFalse: [
			^ false ] ].
	normalizedQuery := queryString
		                   ifNil: [ nil ]
		                   ifNotNil: [ :value |
		                   value asString trimBoth asLowercase ].
	(normalizedQuery isNil or: [ normalizedQuery isEmpty ]) ifTrue: [
		^ true ].
	^ (self searchableTextForTool: aTool) asLowercase includesSubstring:
		  normalizedQuery
]

{ #category : 'tools' }
MCPToolRegistry class >> toolNamed: aToolName ifAbsent: absentBlock [

	self publicToolClasses do: [ :toolClass |
			| tool |
			tool := toolClass new.
			tool name = aToolName ifTrue: [ ^ tool ] ].
	^ absentBlock value
]

{ #category : 'tools' }
MCPToolRegistry class >> toolsMatchingQuery: queryString group: groupString includeStatic: includeStatic limit: anInteger [

	| matches limit |
	matches := self publicTools select: [ :tool |
			           self
				           tool: tool
				           matchesQuery: queryString
				           group: groupString
				           includeStatic: includeStatic ].
	limit := anInteger ifNil: [ 100 ].
	(limit > 0 and: [ matches size > limit ]) ifTrue: [
		^ (matches first: limit) asArray ].
	^ matches asArray
]
