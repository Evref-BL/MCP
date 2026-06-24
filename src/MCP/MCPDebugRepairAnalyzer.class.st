"
Analyzes a captured debug session state and derives debugger-driven method update actions.

It recognizes repairable states such as missing methods and subclass-responsibility style exceptions, then produces debug_method_update action payloads tied to the current state.
"
Class {
	#name : 'MCPDebugRepairAnalyzer',
	#superclass : 'Object',
	#instVars : [
		'record',
		'request'
	],
	#category : 'MCP-Debugging',
	#package : 'MCP',
	#tag : 'Debugging'
}

{ #category : 'instance creation' }
MCPDebugRepairAnalyzer class >> fromRecord: aRecord request: aRequest [

	^ self new
		  record: aRecord;
		  request: aRequest;
		  yourself
]

{ #category : 'private - actions' }
MCPDebugRepairAnalyzer >> addDefaultSource: sourceString requiresMethodSource: requiresMethodSource toAction: action [

	action
		at: #requiresMethodSource put: requiresMethodSource;
		at: #defaultMethodSource put: sourceString.
	^ action
]

{ #category : 'private - methods' }
MCPDebugRepairAnalyzer >> behaviorForContext: aContext [

	^ aContext receiver class
]

{ #category : 'private - actions' }
MCPDebugRepairAnalyzer >> classNameForBehavior: aBehavior [

	aBehavior ifNil: [ ^ nil ].
	^ aBehavior isMeta
		  ifTrue: [ aBehavior instanceSide name asString ]
		  ifFalse: [ aBehavior name asString ]
]

{ #category : 'private - actions' }
MCPDebugRepairAnalyzer >> classSideForBehavior: aBehavior [

	aBehavior ifNil: [ ^ false ].
	^ aBehavior isMeta
]

{ #category : 'private - actions' }
MCPDebugRepairAnalyzer >> debugMethodUpdateArgumentsForFrameRef: frameRef [

	^ {
		  (#sessionId -> record sessionId).
		  (#stateId -> record stateId).
		  (#frameRef -> frameRef) } asDictionary
]

{ #category : 'private' }
MCPDebugRepairAnalyzer >> debugSession [

	^ record ifNotNil: [ record debugSession ]
]

{ #category : 'private - methods' }
MCPDebugRepairAnalyzer >> defaultSourceForMessage: aMessage behavior: aBehavior [

	aMessage ifNil: [ ^ nil ].
	aBehavior ifNil: [ ^ nil ].
	^ self generatedDefaultSourceForMessage: aMessage behavior: aBehavior
]

{ #category : 'private - actions' }
MCPDebugRepairAnalyzer >> descriptionForKind: kind behavior: aBehavior selector: aSelector [

	| targetName |
	targetName := self classNameForBehavior: aBehavior.
	(self classSideForBehavior: aBehavior) ifTrue: [
		targetName := targetName , ' class' ].
	^ String streamContents: [ :stream |
			  kind = 'missingMethod'
				  ifTrue: [ stream nextPutAll: 'Create missing method ' ]
				  ifFalse: [
						  kind = 'subclassResponsibility'
							  ifTrue: [
							  stream nextPutAll: 'Implement subclass responsibility ' ]
							  ifFalse: [ stream nextPutAll: 'Update method ' ] ].
			  stream
				  nextPutAll: targetName asString;
				  nextPutAll: '>>';
				  nextPutAll: aSelector asString ]
]

{ #category : 'private' }
MCPDebugRepairAnalyzer >> exception [

	^ self debugSession ifNotNil: [ :session | session exception ]
]

{ #category : 'private - contexts' }
MCPDebugRepairAnalyzer >> fallbackTargetContextForException: anException [

	| contexts session |
	session := self debugSession.
	session ifNotNil: [
		session interruptedContext ifNotNil: [ :context | ^ context ] ].
	contexts := self rawContexts.
	contexts isEmpty ifTrue: [ ^ nil ].
	^ contexts first
]

{ #category : 'private - actions' }
MCPDebugRepairAnalyzer >> frameRefForContext: aContext [

	| frameIndex rawContexts |
	rawContexts := self rawContexts.
	frameIndex := (rawContexts indexOf: aContext ifAbsent: [ 1 ]) - 1.
	^ record sessionId , '/' , record stateId , '/frame-'
	  , frameIndex asString
]

{ #category : 'private - methods' }
MCPDebugRepairAnalyzer >> generatedDefaultSourceForMessage: aMessage behavior: aBehavior [

	^ [ (DynamicMessageImplementor for: aMessage in: aBehavior) value ]
		  on: Error
		  do: [ nil ]
]

{ #category : 'private - messages' }
MCPDebugRepairAnalyzer >> messageForException: anException context: aContext [

	^ anException mcpRepairMessageForContext: aContext
]

{ #category : 'private - methods' }
MCPDebugRepairAnalyzer >> methodBehaviorForContext: aContext [

	^ aContext method methodClass
]

{ #category : 'private - contexts' }
MCPDebugRepairAnalyzer >> methodImplementor [

	| implementorClass session |
	session := self debugSession.
	session ifNil: [ ^ nil ].
	implementorClass := Smalltalk globals
		                    at: #StDebuggerMethodImplementor
		                    ifAbsent: [ ^ nil ].
	^ implementorClass forSession: session
]

{ #category : 'private - actions' }
MCPDebugRepairAnalyzer >> missingMethodActionFor: anException [

	| action behavior context defaultSource message |
	context := self targetContextForException: anException.
	context ifNil: [ ^ nil ].
	message := self messageForException: anException context: context.
	message ifNil: [ ^ nil ].
	behavior := self behaviorForContext: context.
	defaultSource := self
		                 defaultSourceForMessage: message
		                 behavior: behavior.
	action := self
		          repairActionForContext: context
		          behavior: behavior
		          selector: message selector
		          kind: 'missingMethod'.
	^ self
		  addDefaultSource: defaultSource
		  requiresMethodSource: false
		  toAction: action
]

{ #category : 'private' }
MCPDebugRepairAnalyzer >> rawContexts [

	self debugSession ifNil: [ ^ #(  ) ].
	request ifNil: [ ^ #(  ) ].
	^ (MCPDebugStateInfo fromRecord: record request: request) rawContexts
]

{ #category : 'accessing' }
MCPDebugRepairAnalyzer >> record [

	^ record
]

{ #category : 'accessing' }
MCPDebugRepairAnalyzer >> record: aRecord [

	record := aRecord
]

{ #category : 'private - actions' }
MCPDebugRepairAnalyzer >> repairActionForContext: aContext behavior: aBehavior selector: aSelector kind: kind [

	| frameRef |
	frameRef := self frameRefForContext: aContext.
	^ {
		  (#repairActionId -> kind).
		  (#kind -> kind).
		  (#description
		   ->
		   (self
			    descriptionForKind: kind
			    behavior: aBehavior
			    selector: aSelector)).
		  (#toolName -> 'debug_method_update').
		  (#sessionId -> record sessionId).
		  (#stateId -> record stateId).
		  (#frameRef -> frameRef).
		  (#selector -> aSelector asString).
		  (#targetClassName -> (self classNameForBehavior: aBehavior)).
		  (#classSide -> (self classSideForBehavior: aBehavior)).
		  (#arguments -> (self debugMethodUpdateArgumentsForFrameRef: frameRef)) }
		  asDictionary
]

{ #category : 'repairing' }
MCPDebugRepairAnalyzer >> repairActions [

	^ self exception
		  ifNil: [ #(  ) ]
		  ifNotNil: [ :anException |
		  anException mcpDebugRepairActionsFor: self ]
]

{ #category : 'accessing' }
MCPDebugRepairAnalyzer >> request [

	^ request
]

{ #category : 'accessing' }
MCPDebugRepairAnalyzer >> request: aRequest [

	request := aRequest
]

{ #category : 'private - contexts' }
MCPDebugRepairAnalyzer >> selectorContextForException: anException [

	| selector |
	selector := anException mcpSelectorForContextLookup.
	selector ifNil: [ ^ nil ].
	^ self rawContexts
		  detect: [ :context | context selector = selector ]
		  ifNone: [ nil ]
]

{ #category : 'private - methods' }
MCPDebugRepairAnalyzer >> sourceForContext: aContext [

	^ aContext sourceCode
]

{ #category : 'private - actions' }
MCPDebugRepairAnalyzer >> stubActionFor: anException kind: kind [

	| action behavior context selector source |
	context := self selectorContextForException: anException.
	context ifNil: [ ^ nil ].
	selector := anException selector.
	behavior := self methodBehaviorForContext: context.
	source := self sourceForContext: context.
	action := self
		          repairActionForContext: context
		          behavior: behavior
		          selector: selector
		          kind: kind.
	^ self
		  addDefaultSource: source
		  requiresMethodSource: true
		  toAction: action
]

{ #category : 'private - actions' }
MCPDebugRepairAnalyzer >> subclassResponsibilityActionFor: anException [

	| action behavior context defaultSource message |
	context := self targetContextForException: anException.
	context ifNil: [ ^ nil ].
	message := self messageForException: anException context: context.
	message ifNil: [ ^ nil ].
	behavior := self behaviorForContext: context.
	defaultSource := self
		                 defaultSourceForMessage: message
		                 behavior: behavior.
	action := self
		          repairActionForContext: context
		          behavior: behavior
		          selector: message selector
		          kind: 'subclassResponsibility'.
	^ self
		  addDefaultSource: defaultSource
		  requiresMethodSource: false
		  toAction: action
]

{ #category : 'private - contexts' }
MCPDebugRepairAnalyzer >> targetContextForException: anException [

	| context methodImplementor |
	methodImplementor := self methodImplementor.
	methodImplementor ifNotNil: [
			context := anException mcpRepairContextForMethodImplementation:
				           methodImplementor.
			context ifNotNil: [ ^ context ] ].
	^ self fallbackTargetContextForException: anException
]
