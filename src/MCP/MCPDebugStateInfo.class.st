"
DTO that renders the current state of a registered DebugSession.

It builds state-scoped frame and variable references, stack summaries, source context, shallow scopes, exception details, and repair actions for agent consumption.
"
Class {
	#name : 'MCPDebugStateInfo',
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
MCPDebugStateInfo class >> fromRecord: aRecord request: aRequest [

	^ self new
		  record: aRecord;
		  request: aRequest;
		  yourself
]

{ #category : 'converting' }
MCPDebugStateInfo >> asDictionary [

	| callStack rawContexts repairActions selectedContext selectedFrame selectedIndex visibleContexts warnings |
	rawContexts := self rawContexts.
	visibleContexts := self slicedContextsFrom: rawContexts.
	selectedIndex := self selectedFrameIndexFrom: rawContexts.
	selectedContext := rawContexts
		                   at: selectedIndex + 1
		                   ifAbsent: [ nil ].
	warnings := OrderedCollection new.
	record debugSession ifNil: [
			warnings add:
				'No DebugSession object is attached to this debug session record.' ].
	selectedContext ifNil: [
		warnings add:
			'No stack context was available for the selected frame.' ].
	callStack := OrderedCollection new.
	visibleContexts withIndexDo: [ :context :index |
			callStack add:
				(self frameInfoFor: context index: request stackStart + index - 1) ].
	selectedFrame := selectedContext
		                 ifNil: [ nil ]
		                 ifNotNil: [
		                 self
			                 frameInfoFor: selectedContext
			                 index: selectedIndex ].
	repairActions := (MCPDebugRepairAnalyzer
		                  fromRecord: record
		                  request: request) repairActions.
	^ {
		  (#sessionId -> record sessionId).
		  (#stateId -> record stateId).
		  (#status -> record status).
		  (#reason -> record reason).
		  (#exception -> self exceptionInfo).
		  (#location -> (self
			    locationInfoForContext: selectedContext
			    frameIndex: selectedIndex)).
		  (#source -> (self sourceInfoForContext: selectedContext)).
		  (#selectedFrame -> selectedFrame).
		  (#scopes
		   ->
		   (self scopesForContext: selectedContext frameIndex: selectedIndex)).
		  (#callStack -> callStack asArray).
		  (#repairActions -> repairActions).
		  (#stackStart -> request stackStart).
		  (#stackLimit -> request stackLimit).
		  (#totalFrames -> rawContexts size).
		  (#capabilities -> record capabilities).
		  (#warnings -> warnings asArray) } asDictionary
]

{ #category : 'private' }
MCPDebugStateInfo >> exceptionInfo [

	| exception message |
	exception := self valueOrNil: [ record debugSession exception ].
	exception ifNil: [ ^ nil ].
	message := (exception respondsTo: #messageText)
		           ifTrue: [ exception messageText ]
		           ifFalse: [ nil ].
	^ {
		  (#className -> exception class name asString).
		  (#message
		   -> (message ifNil: [ '' ] ifNotNil: [ message asString ])).
		  (#printString -> (self limitedPrintStringOf: exception)) }
		  asDictionary
]

{ #category : 'private - stack' }
MCPDebugStateInfo >> frameInfoFor: aContext index: frameIndex [

	| receiverClass |
	receiverClass := self valueOrNil: [
		                 aContext receiver class name asString ].
	^ {
		  (#frameRef -> (self frameRefForIndex: frameIndex)).
		  (#index -> frameIndex).
		  (#displayString -> (self limitedPrintStringOf: aContext)).
		  (#method -> (self methodInfoForContext: aContext)).
		  (#pc -> (self valueOrNil: [ aContext pc ])).
		  (#receiverClassName -> receiverClass) } asDictionary
]

{ #category : 'private - refs' }
MCPDebugStateInfo >> frameRefForIndex: anInteger [

	^ record sessionId , '/' , record stateId , '/frame-'
	  , anInteger asString
]

{ #category : 'private' }
MCPDebugStateInfo >> limitedPrintStringOf: anObject [

	anObject ifNil: [ ^ 'nil' ].
	^ [ anObject printStringLimitedTo: 500 ]
		  on: Error
		  do: [ :error | anObject class name asString ]
]

{ #category : 'private - stack' }
MCPDebugStateInfo >> locationInfoForContext: aContext frameIndex: frameIndex [

	aContext ifNil: [ ^ nil ].
	^ {
		  (#frameRef -> (self frameRefForIndex: frameIndex)).
		  (#method -> (self methodInfoForContext: aContext)).
		  (#pc -> (self valueOrNil: [ aContext pc ])) } asDictionary
]

{ #category : 'private - stack' }
MCPDebugStateInfo >> methodInfoForContext: aContext [

	| method methodClass selector |
	method := self valueOrNil: [ aContext method ].
	method ifNil: [ ^ Dictionary new ].
	methodClass := self valueOrNil: [ method methodClass ].
	selector := self valueOrNil: [ method selector ].
	^ {
		  (#className
		   ->
		   (methodClass
			    ifNil: [ nil ]
			    ifNotNil: [ methodClass name asString ])).
		  (#selector
		   -> (selector ifNil: [ nil ] ifNotNil: [ selector asString ])) }
		  asDictionary
]

{ #category : 'private - stack' }
MCPDebugStateInfo >> rawContexts [

	| debugSession contexts |
	debugSession := record debugSession.
	debugSession ifNil: [ ^ #(  ) ].
	contexts := (debugSession respondsTo: #stackOfSize:)
		            ifTrue: [
				            self valueOrNil: [
					            debugSession stackOfSize:
						            request stackStart + request stackLimit + 1 ] ]
		            ifFalse: [ nil ].
	contexts ifNil: [
			(debugSession respondsTo: #stack) ifTrue: [
				contexts := self valueOrNil: [ debugSession stack ] ] ].
	^ contexts ifNil: [ #(  ) ] ifNotNil: [ contexts asArray ]
]

{ #category : 'private - variables' }
MCPDebugStateInfo >> receiverVariablesForContext: aContext frameIndex: frameIndex [

	aContext ifNil: [ ^ #(  ) ].
	^ { (self
		   variableInfoNamed: 'self'
		   value: (self valueOrNil: [ aContext receiver ])
		   frameIndex: frameIndex
		   scopeName: 'receiver') }
]

{ #category : 'accessing' }
MCPDebugStateInfo >> record [

	^ record
]

{ #category : 'accessing' }
MCPDebugStateInfo >> record: aRecord [

	record := aRecord.
	^ self
]

{ #category : 'accessing' }
MCPDebugStateInfo >> request [

	^ request
]

{ #category : 'accessing' }
MCPDebugStateInfo >> request: aRequest [

	request := aRequest
]

{ #category : 'private - refs' }
MCPDebugStateInfo >> scopeRefFor: scopeName frameIndex: frameIndex [

	^ (self frameRefForIndex: frameIndex) , '/scope-' , scopeName
]

{ #category : 'private - variables' }
MCPDebugStateInfo >> scopesForContext: aContext frameIndex: frameIndex [

	| scopes temporaryVariables |
	aContext ifNil: [ ^ #(  ) ].
	scopes := OrderedCollection new.
	request includeReceiver ifTrue: [
			scopes add: {
					(#name -> 'Receiver').
					(#kind -> 'receiver').
					(#variableRef
					 -> (self scopeRefFor: 'receiver' frameIndex: frameIndex)).
					(#variables
					 ->
					 (self
						  receiverVariablesForContext: aContext
						  frameIndex: frameIndex)) } asDictionary ].
	temporaryVariables := self
		                      temporaryVariablesForContext: aContext
		                      frameIndex: frameIndex.
	scopes add: {
			(#name -> 'Temporaries').
			(#kind -> 'temporaries').
			(#variableRef
			 -> (self scopeRefFor: 'temporaries' frameIndex: frameIndex)).
			(#variables -> temporaryVariables) } asDictionary.
	^ scopes asArray
]

{ #category : 'private - refs' }
MCPDebugStateInfo >> selectedFrameIndexFrom: contextArray [

	| suffix |
	request frameRef ifNil: [ ^ 0 ].
	suffix := request frameRef copyAfterLast: $-.
	^ [ suffix asInteger ]
		  on: Error
		  do: [ :error | 0 ]
]

{ #category : 'private - stack' }
MCPDebugStateInfo >> slicedContextsFrom: contextArray [

	| first last |
	contextArray isEmpty ifTrue: [ ^ #(  ) ].
	request stackLimit = 0 ifTrue: [ ^ #(  ) ].
	first := request stackStart + 1.
	first > contextArray size ifTrue: [ ^ #(  ) ].
	last := request stackStart + request stackLimit min:
		        contextArray size.
	^ contextArray copyFrom: first to: last
]

{ #category : 'private - stack' }
MCPDebugStateInfo >> sourceInfoForContext: aContext [

	| source range |
	aContext ifNil: [ ^ nil ].
	source := self valueOrNil: [ aContext sourceCode ].
	range := self valueOrNil: [
		         record debugSession selectedCodeRangeForContext: aContext ].
	^ {
		  (#sourceCode -> source).
		  (#selectedRange -> (range ifNil: [ #(  ) ] ifNotNil: [
				    {
					    range first.
					    range last } ])) } asDictionary
]

{ #category : 'private - variables' }
MCPDebugStateInfo >> temporaryVariablesForContext: aContext frameIndex: frameIndex [

	| names variables limit |
	aContext ifNil: [ ^ #(  ) ].
	names := self valueOrNil: [ aContext tempNames ].
	names ifNil: [ ^ #(  ) ].
	limit := names size min: request variableLimit.
	variables := OrderedCollection new.
	1 to: limit do: [ :index |
			variables add: (self
					 variableInfoNamed: (names at: index)
					 value: (self valueOrNil: [ aContext tempAt: index ])
					 frameIndex: frameIndex
					 scopeName: 'temporaries') ].
	^ variables asArray
]

{ #category : 'private' }
MCPDebugStateInfo >> valueOrNil: aBlock [

	^ [ aBlock value ]
		  on: Error
		  do: [ :error | nil ]
]

{ #category : 'private - variables' }
MCPDebugStateInfo >> variableInfoNamed: variableName value: anObject frameIndex: frameIndex scopeName: scopeName [

	^ {
		  (#name -> variableName asString).
		  (#className -> (anObject
			    ifNil: [ 'UndefinedObject' ]
			    ifNotNil: [ anObject class name asString ])).
		  (#printString -> (self limitedPrintStringOf: anObject)).
		  (#variableRef -> (self
			    variableRefFor: variableName
			    frameIndex: frameIndex
			    scopeName: scopeName)) } asDictionary
]

{ #category : 'private - refs' }
MCPDebugStateInfo >> variableRefFor: variableName frameIndex: frameIndex scopeName: scopeName [

	^ (self scopeRefFor: scopeName frameIndex: frameIndex) , '/var-'
	  , variableName asString
]
