"
Analyzes a paused debug session for repair actions.

It recognizes repairable states such as missing methods and subclass-responsibility style exceptions, then produces debug-edit action payloads tied to the current state.
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

	^ self valueOrNil: [ aContext receiver class ]
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

	^ aBehavior notNil and: [ aBehavior isMeta ]
]

{ #category : 'private - actions' }
MCPDebugRepairAnalyzer >> debugEditArgumentsForFrameRef: frameRef [

	^ {
		  (#sessionId -> record sessionId).
		  (#stateId -> record stateId).
		  (#frameRef -> frameRef) } asDictionary
]

{ #category : 'private' }
MCPDebugRepairAnalyzer >> debugSession [

	^ record ifNil: [ nil ] ifNotNil: [ record debugSession ]
]

{ #category : 'private - methods' }
MCPDebugRepairAnalyzer >> defaultSourceForMessage: aMessage behavior: aBehavior [

	(aMessage isNil or: [ aBehavior isNil ]) ifTrue: [ ^ nil ].
	^ self valueOrNil: [
		  (DynamicMessageImplementor for: aMessage in: aBehavior) value ]
]

{ #category : 'private - actions' }
MCPDebugRepairAnalyzer >> descriptionForKind: kind behavior: aBehavior selector: aSelector [

	| targetName |
	targetName := self classNameForBehavior: aBehavior.
	(aBehavior notNil and: [ aBehavior isMeta ]) ifTrue: [
		targetName := targetName , ' class' ].
	^ String streamContents: [ :stream |
			  kind = 'missingMethod'
				  ifTrue: [ stream nextPutAll: 'Create missing method ' ]
				  ifFalse: [
						  kind = 'subclassResponsibility'
							  ifTrue: [
							  stream nextPutAll: 'Implement subclass responsibility ' ]
							  ifFalse: [ stream nextPutAll: 'Edit method ' ] ].
			  stream
				  nextPutAll: targetName asString;
				  nextPutAll: '>>';
				  nextPutAll: aSelector asString ]
]

{ #category : 'private' }
MCPDebugRepairAnalyzer >> exception [

	^ self valueOrNil: [ self debugSession exception ]
]

{ #category : 'private - contexts' }
MCPDebugRepairAnalyzer >> fallbackTargetContextForException: anException [

	| context contexts |
	context := self valueOrNil: [ self debugSession interruptedContext ].
	context ifNotNil: [ ^ context ].
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

{ #category : 'private - testing' }
MCPDebugRepairAnalyzer >> isMissingMethodException: anException [

	^ anException isKindOf: MessageNotUnderstood
]

{ #category : 'private - testing' }
MCPDebugRepairAnalyzer >> isNotYetImplementedException: anException [

	^ anException isKindOf: NotYetImplemented
]

{ #category : 'private - testing' }
MCPDebugRepairAnalyzer >> isShouldBeImplementedException: anException [

	^ anException isKindOf: ShouldBeImplemented
]

{ #category : 'private - testing' }
MCPDebugRepairAnalyzer >> isSubclassResponsibilityException: anException [

	^ anException isKindOf: SubclassResponsibility
]

{ #category : 'private - messages' }
MCPDebugRepairAnalyzer >> messageForException: anException context: aContext [

	| message |
	(anException respondsTo: #messageToImplementInContext:) ifTrue: [
			message := self valueOrNil: [
				           anException messageToImplementInContext: aContext ].
			message ifNotNil: [ ^ message ] ].
	(anException respondsTo: #message) ifTrue: [
			message := self valueOrNil: [ anException message ].
			message ifNotNil: [ ^ message ] ].
	(anException respondsTo: #selector) ifTrue: [
		^ Message
			  selector: anException selector
			  arguments: aContext arguments ].
	^ nil
]

{ #category : 'private - methods' }
MCPDebugRepairAnalyzer >> methodBehaviorForContext: aContext [

	^ self valueOrNil: [ aContext method methodClass ]
]

{ #category : 'private - contexts' }
MCPDebugRepairAnalyzer >> methodImplementor [

	self debugSession ifNil: [ ^ nil ].
	^ self valueOrNil: [
		  StDebuggerMethodImplementor forSession: self debugSession ]
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

	record := aRecord.
	^ self
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
		  (#toolName -> 'debug-edit').
		  (#sessionId -> record sessionId).
		  (#stateId -> record stateId).
		  (#frameRef -> frameRef).
		  (#selector -> aSelector asString).
		  (#targetClassName -> (self classNameForBehavior: aBehavior)).
		  (#classSide -> (self classSideForBehavior: aBehavior)).
		  (#arguments -> (self debugEditArgumentsForFrameRef: frameRef)) }
		  asDictionary
]

{ #category : 'repairing' }
MCPDebugRepairAnalyzer >> repairActions [

	| action exception |
	exception := self exception.
	exception ifNil: [ ^ #(  ) ].
	(self isMissingMethodException: exception) ifTrue: [
			action := self missingMethodActionFor: exception.
			^ action ifNil: [ #(  ) ] ifNotNil: [ { action } ] ].
	(self isSubclassResponsibilityException: exception) ifTrue: [
			action := self subclassResponsibilityActionFor: exception.
			^ action ifNil: [ #(  ) ] ifNotNil: [ { action } ] ].
	(self isShouldBeImplementedException: exception) ifTrue: [
			action := self stubActionFor: exception kind: 'shouldBeImplemented'.
			^ action ifNil: [ #(  ) ] ifNotNil: [ { action } ] ].
	(self isNotYetImplementedException: exception) ifTrue: [
			action := self stubActionFor: exception kind: 'notYetImplemented'.
			^ action ifNil: [ #(  ) ] ifNotNil: [ { action } ] ].
	^ #(  )
]

{ #category : 'accessing' }
MCPDebugRepairAnalyzer >> request [

	^ request
]

{ #category : 'accessing' }
MCPDebugRepairAnalyzer >> request: aRequest [

	request := aRequest.
	^ self
]

{ #category : 'private - contexts' }
MCPDebugRepairAnalyzer >> selectorContextForException: anException [

	| selector |
	(anException respondsTo: #selector) ifFalse: [ ^ nil ].
	selector := anException selector.
	^ self rawContexts
		  detect: [ :context |
			  (self valueOrNil: [ context selector = selector ]) = true ]
		  ifNone: [ nil ]
]

{ #category : 'private - methods' }
MCPDebugRepairAnalyzer >> sourceForContext: aContext [

	^ self valueOrNil: [ aContext sourceCode ]
]

{ #category : 'private - actions' }
MCPDebugRepairAnalyzer >> stubActionFor: anException kind: kind [

	| action behavior context selector source |
	context := self selectorContextForException: anException.
	context ifNil: [ ^ nil ].
	selector := self valueOrNil: [ anException selector ].
	selector ifNil: [ ^ nil ].
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
	(anException respondsTo: #contextForMethodImplementation:) ifTrue: [
			methodImplementor := self methodImplementor.
			methodImplementor ifNotNil: [
					context := self valueOrNil: [
						           anException contextForMethodImplementation:
							           methodImplementor ].
					context ifNotNil: [ ^ context ] ] ].
	^ self fallbackTargetContextForException: anException
]

{ #category : 'private' }
MCPDebugRepairAnalyzer >> valueOrNil: aBlock [

	^ [ aBlock value ]
		  on: Error
		  do: [ :error | nil ]
]
