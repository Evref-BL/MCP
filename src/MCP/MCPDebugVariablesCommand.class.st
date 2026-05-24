Class {
	#name : 'MCPDebugVariablesCommand',
	#superclass : 'MCPDebugCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'private - children' }
MCPDebugVariablesCommand >> addIndexedEntriesOf: anObject parentReference: parentReference to: entries [

	| size maxIndex |
	anObject ifNil: [ ^ self ].
	(self isAtomicObject: anObject) ifTrue: [ ^ self ].
	((anObject respondsTo: #size) and: [ anObject respondsTo: #at: ])
		ifFalse: [ ^ self ].
	size := [ anObject size ]
		        on: Error
		        do: [ :error | ^ self ].
	maxIndex := size min: request variableLimit.
	1 to: maxIndex do: [ :index |
			entries size >= request variableLimit ifTrue: [ ^ self ].
			entries add: (self
					 variableEntryNamed: '[' , index asString , ']'
					 kind: 'indexed'
					 value: ([ anObject at: index ]
							  on: Error
							  do: [ :error | nil ])
					 reference: parentReference , '/index-' , index asString) ]
]

{ #category : 'private - children' }
MCPDebugVariablesCommand >> addInstanceVariableEntriesOf: anObject parentReference: parentReference to: entries [

	| names |
	anObject ifNil: [ ^ self ].
	(self isAtomicObject: anObject) ifTrue: [ ^ self ].
	names := anObject class allInstVarNames collect: [ :each |
		         each asString ].
	names withIndexDo: [ :name :index |
			entries size >= request variableLimit ifTrue: [ ^ self ].
			entries add: (self
					 variableEntryNamed: name
					 kind: 'instVar'
					 value: ([ anObject instVarAt: index ]
							  on: Error
							  do: [ :error | nil ])
					 reference: parentReference , '/ivar-' , name) ]
]

{ #category : 'private - data' }
MCPDebugVariablesCommand >> capabilities [

	^ {
		  (#scopeExpansion -> true).
		  (#objectExpansion -> true).
		  (#indexedExpansion -> request includeIndexed).
		  (#instanceVariableExpansion -> request includeInstanceVariables) }
		  asDictionary
]

{ #category : 'private - children' }
MCPDebugVariablesCommand >> childEntriesFor: anObject parentReference: parentReference [

	| entries |
	entries := OrderedCollection new.
	request includeInstanceVariables ifTrue: [
			self
				addInstanceVariableEntriesOf: anObject
				parentReference: parentReference
				to: entries ].
	request includeIndexed ifTrue: [
			self
				addIndexedEntriesOf: anObject
				parentReference: parentReference
				to: entries ].
	^ entries asArray
]

{ #category : 'private - state' }
MCPDebugVariablesCommand >> contextForReference: aReference stateInfo: stateInfo [

	| contexts |
	contexts := stateInfo rawContexts.
	^ contexts
		  at: aReference frameIndex + 1
		  ifAbsent: [ self signalMissingFrameForReference: aReference ]
]

{ #category : 'private - data' }
MCPDebugVariablesCommand >> dataForScopeReference: aReference context: aContext stateInfo: stateInfo [

	| variables |
	variables := self
		             variablesForScopeReference: aReference
		             context: aContext
		             stateInfo: stateInfo.
	^ {
		  (#sessionId -> aReference sessionId).
		  (#stateId -> aReference stateId).
		  (#variableRef -> aReference rawReference).
		  (#kind -> 'scope').
		  (#name -> aReference scopeName).
		  (#className -> nil).
		  (#printString -> nil).
		  (#hasChildren -> variables notEmpty).
		  (#variables -> variables).
		  (#totalCount -> variables size).
		  (#truncated -> false).
		  (#warnings -> #(  )).
		  (#capabilities -> self capabilities) } asDictionary
]

{ #category : 'private - data' }
MCPDebugVariablesCommand >> dataForVariableReference: aReference context: aContext stateInfo: stateInfo [

	| value children truncated |
	value := self valueForVariableReference: aReference context: aContext.
	children := request variableDepth = 0
		            ifTrue: [ #(  ) ]
		            ifFalse: [
			            self
				            childEntriesFor: value
				            parentReference: aReference rawReference ].
	truncated := (self potentialChildCountOf: value) > children size.
	^ {
		  (#sessionId -> aReference sessionId).
		  (#stateId -> aReference stateId).
		  (#variableRef -> aReference rawReference).
		  (#kind -> 'variable').
		  (#name -> aReference variableName).
		  (#className -> (value
			    ifNil: [ 'UndefinedObject' ]
			    ifNotNil: [ value class name asString ])).
		  (#printString -> (self limitedPrintStringOf: value)).
		  (#hasChildren -> (self objectHasChildren: value)).
		  (#variables -> children).
		  (#totalCount -> children size).
		  (#truncated -> truncated).
		  (#warnings -> #(  )).
		  (#capabilities -> self capabilities) } asDictionary
]

{ #category : 'executing' }
MCPDebugVariablesCommand >> execute [

	| record reference stateInfo context data |
	record := self sessionRecordWithMatchingState.
	reference := request variableReference.
	stateInfo := self stateInfoForRecord: record.
	context := self contextForReference: reference stateInfo: stateInfo.
	data := reference isScopeReference
		        ifTrue: [
				        self
					        dataForScopeReference: reference
					        context: context
					        stateInfo: stateInfo ]
		        ifFalse: [
				        self
					        dataForVariableReference: reference
					        context: context
					        stateInfo: stateInfo ].
	^ MCPDebugToolResult
		  okSummary:
		  'Debug variables expanded for ' , reference rawReference , '.'
		  data: data
		  warnings: (data at: #warnings ifAbsent: [ #(  ) ])
]

{ #category : 'private - children' }
MCPDebugVariablesCommand >> isAtomicObject: anObject [

	anObject ifNil: [ ^ true ].
	(anObject isString or: [ anObject isSymbol ]) ifTrue: [ ^ true ].
	(anObject isNumber or: [ anObject isCharacter ]) ifTrue: [ ^ true ].
	(anObject == true or: [ anObject == false ]) ifTrue: [ ^ true ].
	^ false
]

{ #category : 'private - printing' }
MCPDebugVariablesCommand >> limitedPrintStringOf: anObject [

	anObject ifNil: [ ^ 'nil' ].
	^ [ anObject printStringLimitedTo: 500 ]
		  on: Error
		  do: [ :error | anObject class name asString ]
]

{ #category : 'private - children' }
MCPDebugVariablesCommand >> objectHasChildren: anObject [

	^ (self potentialChildCountOf: anObject) > 0
]

{ #category : 'private - children' }
MCPDebugVariablesCommand >> potentialChildCountOf: anObject [

	| count |
	anObject ifNil: [ ^ 0 ].
	(self isAtomicObject: anObject) ifTrue: [ ^ 0 ].
	count := 0.
	request includeInstanceVariables ifTrue: [
		count := count + anObject class allInstVarNames size ].
	(request includeIndexed and: [
		 (anObject respondsTo: #size) and: [ anObject respondsTo: #at: ] ])
		ifTrue: [
				count := count + ([ anObject size ]
					          on: Error
					          do: [ :error | 0 ]) ].
	^ count
]

{ #category : 'private - variables' }
MCPDebugVariablesCommand >> resolveIndexedSlot: indexString from: anObject reference: aReference [

	| index |
	index := [ indexString asInteger ]
		         on: Error
		         do: [ :error |
				         ^ self
					           signalInvalidChildSegment: 'index-' , indexString
					           forReference: aReference ].
	^ [ anObject at: index ]
		  on: Error
		  do: [ :error | self signalMissingVariableForReference: aReference ]
]

{ #category : 'private - variables' }
MCPDebugVariablesCommand >> resolveInstanceVariableNamed: variableName from: anObject reference: aReference [

	| index names |
	anObject ifNil: [
		^ self signalMissingVariableForReference: aReference ].
	names := anObject class allInstVarNames collect: [ :each |
		         each asString ].
	index := names indexOf: variableName ifAbsent: [ 0 ].
	index = 0 ifTrue: [
		^ self signalMissingVariableForReference: aReference ].
	^ anObject instVarAt: index
]

{ #category : 'private - variables' }
MCPDebugVariablesCommand >> resolvePathSegments: segmentArray from: anObject reference: aReference [

	| current |
	current := anObject.
	segmentArray do: [ :segment |
			current := self
				           resolveSegment: segment
				           from: current
				           reference: aReference ].
	^ current
]

{ #category : 'private - variables' }
MCPDebugVariablesCommand >> resolveSegment: segmentString from: anObject reference: aReference [

	(segmentString beginsWith: 'ivar-') ifTrue: [
			^ self
				  resolveInstanceVariableNamed: (segmentString allButFirst: 5)
				  from: anObject
				  reference: aReference ].
	(segmentString beginsWith: 'index-') ifTrue: [
			^ self
				  resolveIndexedSlot: (segmentString allButFirst: 6)
				  from: anObject
				  reference: aReference ].
	^ self
		  signalInvalidChildSegment: segmentString
		  forReference: aReference
]

{ #category : 'private - variables' }
MCPDebugVariablesCommand >> rootValueForVariableReference: aReference context: aContext [

	| names index |
	aReference variableName ifNil: [
		^ self signalMissingVariableForReference: aReference ].
	aReference scopeName = 'receiver' ifTrue: [
			aReference variableName = 'self' ifTrue: [ ^ aContext receiver ].
			^ self signalMissingVariableForReference: aReference ].
	aReference scopeName = 'temporaries' ifTrue: [
			names := aContext tempNames collect: [ :each | each asString ].
			index := names indexOf: aReference variableName ifAbsent: [ 0 ].
			index = 0 ifTrue: [
				^ self signalMissingVariableForReference: aReference ].
			^ aContext tempAt: index ].
	^ self
		  signalMissingScopeNamed: aReference scopeName
		  forReference: aReference
]

{ #category : 'private - errors' }
MCPDebugVariablesCommand >> signalInvalidChildSegment: segmentString forReference: aReference [

	^ MCPCommandError
		  signalErrorCode: #DebugVariableReferenceInvalid
		  message:
			  'Invalid debug variable child segment: ' , segmentString asString
			  , '.'
		  details: {
				  (#segment -> segmentString).
				  (#variableRef -> aReference rawReference) } asDictionary
]

{ #category : 'private - errors' }
MCPDebugVariablesCommand >> signalMissingFrameForReference: aReference [

	^ MCPCommandError
		  signalErrorCode: #DebugFrameNotFound
		  message: 'Debug frame ' , aReference frameIndex asString
			  , ' was not found for session ' , aReference sessionId , '.'
		  details: {
				  (#sessionId -> aReference sessionId).
				  (#stateId -> aReference stateId).
				  (#frameIndex -> aReference frameIndex).
				  (#variableRef -> aReference rawReference) } asDictionary
]

{ #category : 'private - errors' }
MCPDebugVariablesCommand >> signalMissingScopeNamed: scopeString forReference: aReference [

	^ MCPCommandError
		  signalErrorCode: #DebugScopeNotFound
		  message: 'Debug scope ' , scopeString asString , ' was not found.'
		  details: {
				  (#scopeName -> scopeString).
				  (#variableRef -> aReference rawReference) } asDictionary
]

{ #category : 'private - errors' }
MCPDebugVariablesCommand >> signalMissingVariableForReference: aReference [

	^ MCPCommandError
		  signalErrorCode: #DebugVariableNotFound
		  message: 'Debug variable ' , aReference variableName asString
			  , ' was not found.'
		  details: {
				  (#variableName -> aReference variableName).
				  (#scopeName -> aReference scopeName).
				  (#variableRef -> aReference rawReference) } asDictionary
]

{ #category : 'private - state' }
MCPDebugVariablesCommand >> stateInfoForRecord: aRecord [

	^ MCPDebugStateInfo fromRecord: aRecord request: request
]

{ #category : 'private - variables' }
MCPDebugVariablesCommand >> valueForVariableReference: aReference context: aContext [

	| value |
	value := self
		         rootValueForVariableReference: aReference
		         context: aContext.
	^ self
		  resolvePathSegments: aReference pathSegments
		  from: value
		  reference: aReference
]

{ #category : 'private - children' }
MCPDebugVariablesCommand >> variableEntryNamed: variableName kind: kindString value: value reference: referenceString [

	^ {
		  (#name -> variableName asString).
		  (#kind -> kindString).
		  (#className -> (value
			    ifNil: [ 'UndefinedObject' ]
			    ifNotNil: [ value class name asString ])).
		  (#printString -> (self limitedPrintStringOf: value)).
		  (#variableRef -> referenceString).
		  (#hasChildren -> (self objectHasChildren: value)).
		  (#childrenCount -> (self potentialChildCountOf: value)) }
		  asDictionary
]

{ #category : 'private - scopes' }
MCPDebugVariablesCommand >> variablesForScopeReference: aReference context: aContext stateInfo: stateInfo [

	aReference scopeName = 'receiver' ifTrue: [
			^ stateInfo
				  receiverVariablesForContext: aContext
				  frameIndex: aReference frameIndex ].
	aReference scopeName = 'temporaries' ifTrue: [
			^ stateInfo
				  temporaryVariablesForContext: aContext
				  frameIndex: aReference frameIndex ].
	^ self
		  signalMissingScopeNamed: aReference scopeName
		  forReference: aReference
]
