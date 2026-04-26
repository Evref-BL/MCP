"
Runtime observability state for an MCP server. Observability is disabled by default; when enabled it records TinyLogger-backed log lines, per-tool timing metrics, recent completed calls, and trace-worthy call records for errors and outliers.
"
Class {
	#name : 'MCPMonitoringState',
	#superclass : 'Object',
	#instVars : [
		'enabled',
		'logger',
		'memoryLogger',
		'statsByTool',
		'recentCalls',
		'nextCallId',
		'maxRecentCalls',
		'outlierFactor',
		'minimumOutlierMilliseconds',
		'lastActivityAt'
	],
	#category : 'MCP-Monitoring',
	#package : 'MCP',
	#tag : 'Monitoring'
}

{ #category : 'private' }
MCPMonitoringState >> addRecentCall: aRecord [

	self recentCalls addFirst: aRecord.
	[ self recentCalls size > self maxRecentCalls ] whileTrue: [
		self recentCalls removeLast ]
]

{ #category : 'private - tracing' }
MCPMonitoringState >> captureTraceSnapshotsFor: aRecord result: aToolResult error: anError [

	[
	[
	aRecord isTraceWorthy
		ifTrue: [
			aRecord inputSnapshot: (self traceSnapshotFor: aRecord inputObject).
			aRecord outputSnapshot:
				(self traceSnapshotForResult: aToolResult error: anError) ]
		ifFalse: [
			aRecord inputSnapshot: nil.
			aRecord outputSnapshot: nil ] ]
		on: Error
		do: [ :snapshotError |
			aRecord inputSnapshot: nil.
			aRecord outputSnapshot: (self traceSnapshotFor: {
						 (#errorClass -> snapshotError class name asString).
						 (#message
						  ->
						  (snapshotError messageText ifNil: [ snapshotError asString ])).
						 (#during -> 'trace snapshot creation') } asDictionary) ] ]
		ensure: [ aRecord inputObject: nil ]
]

{ #category : 'clearing' }
MCPMonitoringState >> clear [

	self statsByTool removeAll.
	self recentCalls removeAll.
	nextCallId := 0.
	lastActivityAt := nil.
	self clearLogs.
	self recordLog: 'Observability cleared'
]

{ #category : 'logging' }
MCPMonitoringState >> clearLogs [

	memoryLogger ifNotNil: [ memoryLogger clearLog ]
]

{ #category : 'activation' }
MCPMonitoringState >> disable [

	self enabled ifTrue: [ self recordLog: 'Observability disabled' ].
	enabled := false
]

{ #category : 'activation' }
MCPMonitoringState >> enable [

	enabled := true.
	self ensureLogger.
	lastActivityAt := DateAndTime now.
	self recordLog: 'Observability enabled'
]

{ #category : 'accessing' }
MCPMonitoringState >> enabled [

	^ enabled ifNil: [ false ]
]

{ #category : 'accessing' }
MCPMonitoringState >> enabled: aBoolean [

	aBoolean
		ifTrue: [ self enable ]
		ifFalse: [ self disable ]
]

{ #category : 'logging' }
MCPMonitoringState >> ensureLogger [

	logger ifNil: [ logger := TinyLogger new ].
	memoryLogger ifNil: [
		memoryLogger := MCPMemoryTinyLogger new.
		logger addLogger: memoryLogger ].
	^ logger
]

{ #category : 'private' }
MCPMonitoringState >> errorClassNameFor: anError [

	anError ifNil: [ ^ '' ].
	^ anError class name asString
]

{ #category : 'initialization' }
MCPMonitoringState >> initialize [

	super initialize.
	enabled := false.
	statsByTool := Dictionary new.
	recentCalls := OrderedCollection new.
	nextCallId := 0.
	maxRecentCalls := 100.
	outlierFactor := 3.
	minimumOutlierMilliseconds := 250
]

{ #category : 'private - tracing' }
MCPMonitoringState >> isSensitiveTraceKey: aKey [

	| lowerKey |
	lowerKey := aKey asString asLowercase.
	^ #( 'password' 'passphrase' 'token' 'secret' 'credential'
	     'authorization' 'apikey' 'api_key' ) anySatisfy: [ :term |
		  lowerKey includesSubstring: term ]
]

{ #category : 'private' }
MCPMonitoringState >> logMessageForRecord: aRecord [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: aRecord status;
			  nextPutAll: ' tool ';
			  nextPutAll: aRecord toolName;
			  nextPutAll: ' #';
			  print: aRecord id;
			  nextPutAll: ' in ';
			  print: aRecord durationMilliseconds;
			  nextPutAll: ' ms'.
		  aRecord displaySummary isEmpty ifFalse: [
			  stream
				  nextPutAll: ' - ';
				  nextPutAll: aRecord displaySummary ] ]
]

{ #category : 'accessing' }
MCPMonitoringState >> logger [

	^ logger
]

{ #category : 'logging' }
MCPMonitoringState >> logs [

	memoryLogger ifNil: [ ^ #(  ) ].
	^ memoryLogger recentEntries
]

{ #category : 'accessing' }
MCPMonitoringState >> maxRecentCalls [

	^ maxRecentCalls ifNil: [ 100 ]
]

{ #category : 'accessing' }
MCPMonitoringState >> maxRecentCalls: anInteger [

	maxRecentCalls := anInteger
]

{ #category : 'accessing' }
MCPMonitoringState >> maxTraceCollectionItems [

	^ 50
]

{ #category : 'accessing' }
MCPMonitoringState >> maxTraceDepth [

	^ 6
]

{ #category : 'accessing' }
MCPMonitoringState >> maxTraceStringLength [

	^ 4000
]

{ #category : 'accessing' }
MCPMonitoringState >> memoryLogger [

	^ memoryLogger
]

{ #category : 'accessing' }
MCPMonitoringState >> metrics [

	^ self statsByTool values asSortedCollection: [ :left :right |
		  left toolName <= right toolName ]
]

{ #category : 'accessing' }
MCPMonitoringState >> minimumOutlierMilliseconds [

	^ minimumOutlierMilliseconds ifNil: [ 250 ]
]

{ #category : 'accessing' }
MCPMonitoringState >> minimumOutlierMilliseconds: anInteger [

	minimumOutlierMilliseconds := anInteger
]

{ #category : 'accessing' }
MCPMonitoringState >> nextCallId [

	^ nextCallId ifNil: [ 0 ]
]

{ #category : 'private' }
MCPMonitoringState >> outlierExplanationForDurationMilliseconds: duration stats: stats [

	| average ratio |
	stats callCount < 3 ifTrue: [ ^ '' ].
	average := stats averageMilliseconds.
	average <= 0 ifTrue: [ ^ '' ].
	duration < self minimumOutlierMilliseconds ifTrue: [ ^ '' ].
	ratio := duration / average.
	ratio < self outlierFactor ifTrue: [ ^ '' ].
	^ String streamContents: [ :stream |
		  stream
			  print: duration;
			  nextPutAll: ' ms is ';
			  nextPutAll: (ratio asFloat printShowingDecimalPlaces: 1);
			  nextPutAll: 'x the prior average of ';
			  nextPutAll: (average asFloat printShowingDecimalPlaces: 1);
			  nextPutAll: ' ms' ]
]

{ #category : 'accessing' }
MCPMonitoringState >> outlierFactor [

	^ outlierFactor ifNil: [ 3 ]
]

{ #category : 'accessing' }
MCPMonitoringState >> outlierFactor: aNumber [

	outlierFactor := aNumber
]

{ #category : 'accessing' }
MCPMonitoringState >> recentCallRecords [

	^ self recentCalls asArray
]

{ #category : 'accessing' }
MCPMonitoringState >> recentCalls [

	^ recentCalls ifNil: [ recentCalls := OrderedCollection new ]
]

{ #category : 'logging' }
MCPMonitoringState >> recordLog: aString [

	self enabled ifFalse: [ ^ self ].
	self ensureLogger record: aString
]

{ #category : 'recording' }
MCPMonitoringState >> recordToolCallFinish: aRecord result: aToolResult error: anError [

	| finishTimestamp duration statusString stats explanation |
	aRecord ifNil: [ ^ self ].
	self enabled ifFalse: [ ^ self ].
	finishTimestamp := DateAndTime now.
	duration := (finishTimestamp - aRecord startedAt) asMilliSeconds.
	statusString := self statusForResult: aToolResult error: anError.
	stats := self statsForToolNamed: aRecord toolName.
	explanation := self
		               outlierExplanationForDurationMilliseconds: duration
		               stats: stats.
	aRecord
		finishAt: finishTimestamp
		durationMilliseconds: duration
		status: statusString.
	aRecord errorClass: (self errorClassNameFor: anError).
	aRecord summary: (self summaryForResult: aToolResult).
	aRecord outlierExplanation: explanation.
	self
		captureTraceSnapshotsFor: aRecord
		result: aToolResult
		error: anError.
	stats recordCall: aRecord.
	self addRecentCall: aRecord.
	lastActivityAt := finishTimestamp.
	self recordLog: (self logMessageForRecord: aRecord).
	^ aRecord
]

{ #category : 'recording' }
MCPMonitoringState >> recordToolCallStart: aToolName [

	^ self recordToolCallStart: aToolName input: nil
]

{ #category : 'recording' }
MCPMonitoringState >> recordToolCallStart: aToolName input: inputObject [

	| record startTimestamp |
	self enabled ifFalse: [ ^ nil ].
	nextCallId := self nextCallId + 1.
	startTimestamp := DateAndTime now.
	record := MCPToolCallRecord
		          id: self nextCallId
		          toolName: aToolName asString
		          startedAt: startTimestamp.
	record inputObject: inputObject.
	lastActivityAt := startTimestamp.
	self recordLog:
		'Begin tool ' , aToolName asString , ' #' , record id asString.
	^ record
]

{ #category : 'accessing' }
MCPMonitoringState >> statsByTool [

	^ statsByTool ifNil: [ statsByTool := Dictionary new ]
]

{ #category : 'accessing' }
MCPMonitoringState >> statsForToolNamed: aToolName [

	^ self statsByTool
		  at: aToolName asString
		  ifAbsentPut: [ MCPToolCallStats forToolNamed: aToolName asString ]
]

{ #category : 'private' }
MCPMonitoringState >> statusForResult: aToolResult error: anError [

	anError ifNotNil: [ ^ 'error' ].
	aToolResult ifNil: [ ^ 'error' ].
	^ aToolResult isError
		  ifTrue: [ 'error' ]
		  ifFalse: [ 'ok' ]
]

{ #category : 'displaying' }
MCPMonitoringState >> statusText [

	self enabled ifFalse: [ ^ 'Observability disabled' ].
	^ 'Observability enabled. Calls: ' , self totalCallCount asString
	  , ' | Errors: ' , self totalErrorCount asString
]

{ #category : 'private' }
MCPMonitoringState >> summaryForResult: aToolResult [

	| structuredContent |
	aToolResult ifNil: [ ^ '' ].
	(aToolResult respondsTo: #structuredContent) ifFalse: [ ^ '' ].
	structuredContent := aToolResult structuredContent.
	structuredContent ifNil: [ ^ '' ].
	(structuredContent respondsTo: #at:ifAbsent:) ifFalse: [ ^ '' ].
	^ (structuredContent
		   at: #summary
		   ifAbsent: [ structuredContent at: 'summary' ifAbsent: [ '' ] ])
		  asString
]

{ #category : 'accessing' }
MCPMonitoringState >> totalCallCount [

	^ self metrics inject: 0 into: [ :sum :each | sum + each callCount ]
]

{ #category : 'accessing' }
MCPMonitoringState >> totalErrorCount [

	^ self metrics inject: 0 into: [ :sum :each | sum + each errorCount ]
]

{ #category : 'accessing' }
MCPMonitoringState >> traceRecords [

	^ self recentCallRecords select: [ :each | each isTraceWorthy ]
]

{ #category : 'private - tracing' }
MCPMonitoringState >> traceSnapshotFor: anObject [

	^ self traceSnapshotFor: anObject depth: 0
]

{ #category : 'private - tracing' }
MCPMonitoringState >> traceSnapshotFor: anObject depth: depth [

	anObject ifNil: [ ^ nil ].
	(anObject isString or: [ anObject isSymbol ]) ifTrue: [
		^ self traceStringSnapshotFor: anObject ].
	(anObject isNumber or: [ anObject == true or: [ anObject == false ] ])
		ifTrue: [ ^ anObject ].
	anObject isCharacter ifTrue: [ ^ anObject asString ].
	depth >= self maxTraceDepth ifTrue: [
		^ self traceStringSnapshotFor: anObject printString ].
	(anObject isKindOf: Association) ifTrue: [
		^ self traceSnapshotForAssociation: anObject depth: depth ].
	(anObject isKindOf: Dictionary) ifTrue: [
		^ self traceSnapshotForDictionary: anObject depth: depth ].
	(anObject isCollection and: [ anObject isString not ]) ifTrue: [
		^ self traceSnapshotForCollection: anObject depth: depth ].
	(anObject respondsTo: #asDictionary) ifTrue: [
		[ ^ self traceSnapshotFor: anObject asDictionary depth: depth + 1 ]
			on: Error
			do: [ :ignored | nil ] ].
	^ self traceStringSnapshotFor: anObject printString
]

{ #category : 'private - tracing' }
MCPMonitoringState >> traceSnapshotForAssociation: anAssociation depth: depth [

	(self isSensitiveTraceKey: anAssociation key) ifTrue: [
		^ anAssociation key -> '<redacted>' ].
	^ anAssociation key
	  -> (self traceSnapshotFor: anAssociation value depth: depth + 1)
]

{ #category : 'private - tracing' }
MCPMonitoringState >> traceSnapshotForCollection: aCollection depth: depth [

	| array limit snapshot |
	array := aCollection asArray.
	limit := array size min: self maxTraceCollectionItems.
	snapshot := (1 to: limit) collect: [ :index |
		            self
			            traceSnapshotFor: (array at: index)
			            depth: depth + 1 ].
	array size > limit ifTrue: [
		snapshot := snapshot copyWith:
			            '<truncated ' , (array size - limit) asString
			            , ' more items>' ].
	^ snapshot asArray
]

{ #category : 'private - tracing' }
MCPMonitoringState >> traceSnapshotForDictionary: aDictionary depth: depth [

	| snapshot |
	snapshot := Dictionary new.
	aDictionary associationsDo: [ :association |
		snapshot size < self maxTraceCollectionItems ifTrue: [
			| sanitized |
			sanitized := self
				             traceSnapshotForAssociation: association
				             depth: depth.
			snapshot at: sanitized key put: sanitized value ] ].
	aDictionary size > self maxTraceCollectionItems ifTrue: [
		snapshot
			at: #__truncated__
			put: aDictionary size - self maxTraceCollectionItems ].
	^ snapshot
]

{ #category : 'private - tracing' }
MCPMonitoringState >> traceSnapshotForResult: aToolResult error: anError [

	aToolResult ifNotNil: [
		^ self traceSnapshotFor: ([ aToolResult asJRPCJSON ]
				   on: Error
				   do: [ :ignored | aToolResult asString ]) ].
	anError ifNil: [ ^ nil ].
	^ self traceSnapshotFor: {
			  (#errorClass -> anError class name asString).
			  (#message -> (anError messageText ifNil: [ anError asString ])) }
			  asDictionary
]

{ #category : 'private - tracing' }
MCPMonitoringState >> traceStringSnapshotFor: aString [

	| text |
	text := aString asString.
	text size <= self maxTraceStringLength ifTrue: [ ^ text ].
	^ (text first: self maxTraceStringLength) , '... <truncated>'
]
