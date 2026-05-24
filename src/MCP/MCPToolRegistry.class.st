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
MCPToolRegistry class >> defaultStaticToolNames [

	^ self staticToolClasses collect: [ :each | each toolName ]
]

{ #category : 'tools' }
MCPToolRegistry class >> examplesForTool: aTool [

	^ #(  )
]

{ #category : 'tools' }
MCPToolRegistry class >> exposureForTool: aTool [

	^ self exposureForTool: aTool usingPolicy: aTool toolExposurePolicy
]

{ #category : 'tools' }
MCPToolRegistry class >> exposureForTool: aTool usingPolicy: aToolExposurePolicy [

	^ aToolExposurePolicy exposureForTool: aTool
]

{ #category : 'tools' }
MCPToolRegistry class >> groupNameForToolClass: aToolClass [

	self publicToolGroups do: [ :group |
		(group value includes: aToolClass) ifTrue: [ ^ group key ] ].
	^ 'other'
]

{ #category : 'testing' }
MCPToolRegistry class >> includesToolNamed: aToolName [

	^ self publicToolNames includes: aToolName asString
]

{ #category : 'tools' }
MCPToolRegistry class >> inspectionForTool: aTool [

	^ self inspectionForTool: aTool usingPolicy: aTool toolExposurePolicy
]

{ #category : 'tools' }
MCPToolRegistry class >> inspectionForTool: aTool usingPolicy: aToolExposurePolicy [

	| data |
	data := (self metadataForTool: aTool usingPolicy: aToolExposurePolicy)
		        copy.
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

	^ self
		  isStaticTool: aToolOrName
		  usingPolicy: MCPToolExposurePolicy default
]

{ #category : 'testing' }
MCPToolRegistry class >> isStaticTool: aToolOrName usingPolicy: aToolExposurePolicy [

	^ aToolExposurePolicy isStaticTool: aToolOrName
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

	^ self metadataForTool: aTool usingPolicy: aTool toolExposurePolicy
]

{ #category : 'tools' }
MCPToolRegistry class >> metadataForTool: aTool usingPolicy: aToolExposurePolicy [

	^ {
		  (#name -> aTool name).
		  (#title -> aTool title).
		  (#description -> aTool description).
		  (#group -> (self groupNameForToolClass: aTool class)).
		  (#exposure
		   -> (self exposureForTool: aTool usingPolicy: aToolExposurePolicy)).
		  (#mutability -> (self mutabilityForTool: aTool)).
		  (#risk -> (self riskForTool: aTool)).
		  (#keywords -> (self keywordsForTool: aTool)).
		  (#schemaInspectionRequired -> (self
			    schemaInspectionRequiredForTool: aTool
			    usingPolicy: aToolExposurePolicy)) } asDictionary
]

{ #category : 'tools' }
MCPToolRegistry class >> mutabilityForTool: aTool [

	| executeTools readTools toolName |
	toolName := aTool name.
	readTools := #( 'discover-tools' 'inspect-tool' 'find-repositories'
	                'find-packages' 'find-classes' 'inspect-class'
	                'find-methods' 'inspect-method' 'capture-screenshot'
	                'debug-state' 'debug-variables' ).
	executeTools := #( 'call-tool' 'run-tests' 'evaluate' 'debug-evaluate'
	                   'debug-capture' ).
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
		  ('debugging' -> {
			   MCPToolDebugSessions.
			   MCPToolDebugState.
			   MCPToolDebugVariables.
			   MCPToolDebugEvaluate.
			   MCPToolDebugControl.
			   MCPToolDebugBreakpoints.
			   MCPToolDebugCapture }).
		  ('image-runtime' -> { MCPToolEvaluate }) }
]

{ #category : 'tools' }
MCPToolRegistry class >> publicToolNames [

	^ self publicToolClasses collect: [ :each | each toolName ]
]

{ #category : 'tools' }
MCPToolRegistry class >> publicTools [

	^ self publicToolsUsingPolicy: MCPToolExposurePolicy default
]

{ #category : 'tools' }
MCPToolRegistry class >> publicToolsUsingPolicy: aToolExposurePolicy [

	^ self publicToolClasses collect: [ :each |
			  each new
				  toolExposurePolicy: aToolExposurePolicy;
				  yourself ]
]

{ #category : 'tools' }
MCPToolRegistry class >> riskForTool: aTool [

	| lowRisk mediumRisk toolName |
	toolName := aTool name.
	lowRisk := #( 'discover-tools' 'inspect-tool' 'find-repositories'
	              'find-packages' 'find-classes' 'inspect-class'
	              'find-methods' 'inspect-method' 'capture-screenshot'
	              'debug-state' 'debug-variables' ).
	mediumRisk := #( 'call-tool' 'load-repository' 'run-tests'
	                 'evaluate' 'debug-evaluate' 'debug-capture' ).
	(lowRisk includes: toolName) ifTrue: [ ^ 'low' ].
	(mediumRisk includes: toolName) ifTrue: [ ^ 'medium' ].
	^ 'high'
]

{ #category : 'tools' }
MCPToolRegistry class >> schemaInspectionRequiredForTool: aTool [

	^ self
		  schemaInspectionRequiredForTool: aTool
		  usingPolicy: aTool toolExposurePolicy
]

{ #category : 'tools' }
MCPToolRegistry class >> schemaInspectionRequiredForTool: aTool usingPolicy: aToolExposurePolicy [

	^ (self isStaticTool: aTool usingPolicy: aToolExposurePolicy) not
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

	^ self defaultStaticToolNames
]

{ #category : 'tools' }
MCPToolRegistry class >> staticTools [

	^ self staticToolsUsingPolicy: MCPToolExposurePolicy default
]

{ #category : 'tools' }
MCPToolRegistry class >> staticToolsDictionary [

	^ self staticToolsDictionaryUsingPolicy:
		  MCPToolExposurePolicy default
]

{ #category : 'tools' }
MCPToolRegistry class >> staticToolsDictionaryUsingPolicy: aToolExposurePolicy [

	| dictionary |
	dictionary := Dictionary new.
	(self staticToolsUsingPolicy: aToolExposurePolicy) do: [ :tool |
		dictionary at: tool name put: tool ].
	^ dictionary
]

{ #category : 'tools' }
MCPToolRegistry class >> staticToolsUsingPolicy: aToolExposurePolicy [

	^ ((self publicToolClasses select: [ :toolClass |
		    aToolExposurePolicy isStaticTool: toolClass ]) collect: [
			   :toolClass |
			   toolClass new
				   toolExposurePolicy: aToolExposurePolicy;
				   yourself ]) asArray
]

{ #category : 'tools' }
MCPToolRegistry class >> tool: aTool matchesQuery: queryString group: groupString includeStatic: includeStatic [

	^ self
		  tool: aTool
		  matchesQuery: queryString
		  group: groupString
		  includeStatic: includeStatic
		  usingPolicy: aTool toolExposurePolicy
]

{ #category : 'tools' }
MCPToolRegistry class >> tool: aTool matchesQuery: queryString group: groupString includeStatic: includeStatic usingPolicy: aToolExposurePolicy [

	| group normalizedQuery |
	(includeStatic not and: [ aToolExposurePolicy isStaticTool: aTool ])
		ifTrue: [ ^ false ].
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

	^ self
		  toolNamed: aToolName
		  ifAbsent: absentBlock
		  usingPolicy: MCPToolExposurePolicy default
]

{ #category : 'tools' }
MCPToolRegistry class >> toolNamed: aToolName ifAbsent: absentBlock usingPolicy: aToolExposurePolicy [

	self publicToolClasses do: [ :toolClass |
			toolClass toolName = aToolName ifTrue: [
					^ toolClass new
						  toolExposurePolicy: aToolExposurePolicy;
						  yourself ] ].
	^ absentBlock value
]

{ #category : 'tools' }
MCPToolRegistry class >> toolsMatchingQuery: queryString group: groupString includeStatic: includeStatic limit: anInteger [

	^ self
		  toolsMatchingQuery: queryString
		  group: groupString
		  includeStatic: includeStatic
		  limit: anInteger
		  usingPolicy: MCPToolExposurePolicy default
]

{ #category : 'tools' }
MCPToolRegistry class >> toolsMatchingQuery: queryString group: groupString includeStatic: includeStatic limit: anInteger usingPolicy: aToolExposurePolicy [

	| limit matches |
	matches := (self publicToolsUsingPolicy: aToolExposurePolicy)
		           select: [ :tool |
				           self
					           tool: tool
					           matchesQuery: queryString
					           group: groupString
					           includeStatic: includeStatic
					           usingPolicy: aToolExposurePolicy ].
	limit := anInteger ifNil: [ 100 ].
	(limit > 0 and: [ matches size > limit ]) ifTrue: [
		^ (matches first: limit) asArray ].
	^ matches asArray
]
