"
Runtime monitoring state for an MCP server. Extended monitoring is disabled by default; when enabled it records active calls, recent calls, TinyLogger-backed log lines, per-tool timing metrics, and outlier explanations.
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
		'activeCalls',
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

{ #category : 'accessing' }
MCPMonitoringState >> activeCallRecords [

	^ self activeCalls values asArray
]

{ #category : 'accessing' }
MCPMonitoringState >> activeCalls [

	^ activeCalls ifNil: [ activeCalls := Dictionary new ]
]

{ #category : 'displaying' }
MCPMonitoringState >> activeToolNamesText [

	| names |
	names := self activeCallRecords collect: [ :each | each toolName ].
	^ String streamContents: [ :stream |
		  names withIndexDo: [ :name :index |
			  index > 1 ifTrue: [ stream nextPutAll: ', ' ].
			  stream nextPutAll: name ] ]
]

{ #category : 'private' }
MCPMonitoringState >> addRecentCall: aRecord [

	self recentCalls addFirst: aRecord.
	[ self recentCalls size > self maxRecentCalls ] whileTrue: [
		self recentCalls removeLast ]
]

{ #category : 'clearing' }
MCPMonitoringState >> clear [

	self statsByTool removeAll.
	self recentCalls removeAll.
	self activeCalls removeAll.
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
	enabled := false.
	self activeCalls removeAll
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
	activeCalls := Dictionary new.
	nextCallId := 0.
	maxRecentCalls := 100.
	outlierFactor := 3.
	minimumOutlierMilliseconds := 250
]

{ #category : 'testing' }
MCPMonitoringState >> isIdle [

	^ self enabled and: [ self activeCalls isEmpty ]
]

{ #category : 'testing' }
MCPMonitoringState >> isRunning [

	^ self enabled and: [ self activeCalls notEmpty ]
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
			  nextPutAll: 'Outlier: ';
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
	stats recordCall: aRecord.
	self activeCalls removeKey: aRecord id ifAbsent: [  ].
	self addRecentCall: aRecord.
	lastActivityAt := finishTimestamp.
	self recordLog: (self logMessageForRecord: aRecord).
	^ aRecord
]

{ #category : 'recording' }
MCPMonitoringState >> recordToolCallStart: aToolName [

	| record startTimestamp |
	self enabled ifFalse: [ ^ nil ].
	nextCallId := self nextCallId + 1.
	startTimestamp := DateAndTime now.
	record := MCPToolCallRecord
		          id: self nextCallId
		          toolName: aToolName asString
		          startedAt: startTimestamp.
	self activeCalls at: record id put: record.
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
	self activeCalls isEmpty ifTrue: [
		^ 'Observability enabled, idle. Calls: '
		  , self totalCallCount asString , ' | Errors: '
		  , self totalErrorCount asString ].
	^ 'Observability enabled, running ' , self activeCalls size asString
	  , ' call(s): ' , self activeToolNamesText
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
