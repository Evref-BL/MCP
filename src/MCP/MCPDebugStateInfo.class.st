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
	selectedIndex := self selectedFrameIndex.
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
	selectedFrame := selectedContext ifNotNil: [
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
	exception := record debugSession exception.
	exception ifNil: [ ^ nil ].
	message := exception messageText.
	^ {
		  (#className -> exception class name asString).
		  (#message
		   -> (message ifNil: [ '' ] ifNotNil: [ message asString ])).
		  (#printString -> (self limitedPrintStringOf: exception)) }
		  asDictionary
]

{ #category : 'private - stack' }
MCPDebugStateInfo >> frameInfoFor: aContext index: frameIndex [

	^ {
		  (#frameRef -> (self frameRefForIndex: frameIndex)).
		  (#index -> frameIndex).
		  (#displayString -> (self limitedPrintStringOf: aContext)).
		  (#method -> (self methodInfoForContext: aContext)).
		  (#pc -> aContext pc).
		  (#receiverClassName -> aContext receiver class name asString) }
		  asDictionary
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
		  (#pc -> aContext pc) } asDictionary
]

{ #category : 'private - stack' }
MCPDebugStateInfo >> methodInfoForContext: aContext [

	| method methodClass selector |
	method := aContext method.
	method ifNil: [ ^ Dictionary new ].
	methodClass := method methodClass.
	selector := method selector.
	^ {
		  (#className -> methodClass name asString).
		  (#selector -> selector asString) } asDictionary
]

{ #category : 'private - stack' }
MCPDebugStateInfo >> rawContexts [

	| contexts debugSession |
	debugSession := record debugSession.
	debugSession ifNil: [ ^ #(  ) ].
	contexts := debugSession stackOfSize:
		            request stackStart + request stackLimit + 1.
	^ contexts asArray
]

{ #category : 'private - variables' }
MCPDebugStateInfo >> receiverVariablesForContext: aContext frameIndex: frameIndex [

	aContext ifNil: [ ^ #(  ) ].
	^ { (self
		   variableInfoNamed: 'self'
		   value: aContext receiver
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

{ #category : 'private - stack' }
MCPDebugStateInfo >> selectedCodeRangeForContext: aContext [

	| debugSession |
	debugSession := record debugSession.
	debugSession ifNil: [ ^ nil ].
	^ debugSession selectedCodeRangeForContext: aContext
]

{ #category : 'private - refs' }
MCPDebugStateInfo >> selectedFrameIndex [

	| frameRef suffix |
	frameRef := request frameRef.
	frameRef ifNil: [ ^ 0 ].
	suffix := frameRef copyAfterLast: $-.
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

	| range |
	aContext ifNil: [ ^ nil ].
	range := self selectedCodeRangeForContext: aContext.
	^ {
		  (#sourceCode -> aContext sourceCode).
		  (#selectedRange -> (range ifNil: [ #(  ) ] ifNotNil: [
				    {
					    range first.
					    range last } ])) } asDictionary
]

{ #category : 'private - variables' }
MCPDebugStateInfo >> temporaryVariablesForContext: aContext frameIndex: frameIndex [

	| limit names variables |
	aContext ifNil: [ ^ #(  ) ].
	names := aContext tempNames.
	limit := names size min: request variableLimit.
	variables := OrderedCollection new.
	1 to: limit do: [ :index |
			variables add: (self
					 variableInfoNamed: (names at: index)
					 value: (aContext tempAt: index)
					 frameIndex: frameIndex
					 scopeName: 'temporaries') ].
	^ variables asArray
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
