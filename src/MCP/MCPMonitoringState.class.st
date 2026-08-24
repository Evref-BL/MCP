"
Runtime observability state for an MCP server. When enabled, it records local log lines, per-tool timing and output-size metrics, recent completed calls, and compact trace records for errors, timing outliers, or output-budget overruns. MCP server instances enable observability and configure a default export directory; standalone state objects can still be configured explicitly.
"
Class {
	#name : 'MCPMonitoringState',
	#superclass : 'MCPObservabilityBackend',
	#instVars : [
		'enabled',
		'logEntries',
		'statsByTool',
		'recentCalls',
		'nextCallId',
		'maxRecentCalls',
		'maxLogEntries',
		'outlierFactor',
		'minimumOutlierMilliseconds',
		'outputBudgetBytes',
		'lastActivityAt',
		'exportDirectory',
		'exportInstanceDirectory',
		'resourceMetadata'
	],
	#category : 'MCP-Monitoring',
	#package : 'MCP',
	#tag : 'Monitoring'
}

{ #category : 'defaults' }
MCPMonitoringState class >> defaultExportDirectory [

	^ Smalltalk imageFile asFileReference parent / 'pharo-local' / 'mcp' / 'observability'
]

{ #category : 'private' }
MCPMonitoringState >> addRecentCall: aRecord [

	self recentCalls addFirst: aRecord.
	[ self recentCalls size > self maxRecentCalls ] whileTrue: [ self recentCalls removeLast ]
]

{ #category : 'private - budgets' }
MCPMonitoringState >> approximateOutputBytesForObject: anObject [

	| jsonString |
	jsonString := [ STONJSON toString: anObject ]
		              on: Error
		              do: [ :ignored | anObject asString ].
	^ jsonString utf8Encoded size
]

{ #category : 'private - budgets' }
MCPMonitoringState >> approximateOutputBytesForResult: aToolResult error: anError [

	aToolResult ifNotNil: [ ^ self approximateOutputBytesForObject: aToolResult asJRPCJSON ].
	anError ifNil: [ ^ 0 ].
	^ self approximateOutputBytesForObject: {
			  (#errorClass -> anError class name asString).
			  (#message -> (anError messageText ifNil: [ anError asString ])) } asDictionary
]

{ #category : 'private - budgets' }
MCPMonitoringState >> approximateOutputTokensForBytes: byteCount [

	^ byteCount + 3 // 4
]

{ #category : 'private - tracing' }
MCPMonitoringState >> captureTraceSnapshotsFor: aRecord result: aToolResult error: anError [

	[
		[
			aRecord isTraceWorthy
				ifTrue: [
						aRecord inputSnapshot: (self traceSnapshotFor: aRecord inputObject).
						aRecord outputSnapshot: (self traceSnapshotForResult: aToolResult error: anError) ]
				ifFalse: [
						aRecord inputSnapshot: nil.
						aRecord outputSnapshot: nil ] ]
			on: Error
			do: [ :snapshotError |
					aRecord inputSnapshot: nil.
					aRecord outputSnapshot: (self traceSnapshotFor: {
								 (#errorClass -> snapshotError class name asString).
								 (#message -> (snapshotError messageText ifNil: [ snapshotError asString ])).
								 (#during -> 'trace snapshot creation') } asDictionary) ] ] ensure: [ aRecord inputObject: nil ]
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

	self logEntries removeAll
]

{ #category : 'private - defaults' }
MCPMonitoringState >> defaultOutputBudgetBytes [
	"32 KiB is about 8k tokens with the monitoring estimate of four bytes per token. It is only the default trace threshold; callers can override it with outputBudgetBytes:."

	^ 32 * 1024
]

{ #category : 'activation' }
MCPMonitoringState >> disable [

	self enabled ifTrue: [ self recordLog: 'Observability disabled' ].
	enabled := false
]

{ #category : 'activation' }
MCPMonitoringState >> enable [

	self enabled ifTrue: [ ^ self ].
	enabled := true.
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

{ #category : 'private' }
MCPMonitoringState >> errorClassNameFor: anError [

	anError ifNil: [ ^ '' ].
	^ anError class name asString
]

{ #category : 'private - tracing' }
MCPMonitoringState >> eventKindsForRecord: aRecord [

	^ Array streamContents: [ :stream |
			  aRecord status = 'error' ifTrue: [ stream nextPut: 'error' ].
			  aRecord outputBudgetExceeded ifTrue: [ stream nextPut: 'output_budget_exceeded' ].
			  aRecord outlierExplanation ifNotEmpty: [ :ignored | stream nextPut: 'duration_outlier' ] ]
]

{ #category : 'accessing' }
MCPMonitoringState >> exportDirectory [

	^ exportDirectory
]

{ #category : 'accessing' }
MCPMonitoringState >> exportDirectory: aPath [

	exportDirectory := aPath ifNotNil: [ :path | path asFileReference ].
	exportInstanceDirectory := nil
]

{ #category : 'testing' }
MCPMonitoringState >> exportEnabled [

	^ self exportDirectory notNil
]

{ #category : 'accessing' }
MCPMonitoringState >> exportInstanceDirectory [

	| directory |
	self exportEnabled ifFalse: [ ^ nil ].
	exportInstanceDirectory ifNil: [
			directory := self exportDirectory / self exportInstanceDirectoryName.
			directory ensureCreateDirectory.
			exportInstanceDirectory := directory.
			self writeResourceMetadata ].
	^ exportInstanceDirectory
]

{ #category : 'private - exporting' }
MCPMonitoringState >> exportInstanceDirectoryName [

	| instanceId metadata port suffix version |
	metadata := self resourceMetadata.
	version := metadata at: #'pharo.majorVersion' ifAbsent: [ 'unknown' ].
	port := metadata at: #'mcp.port' ifAbsent: [ 'unknown' ].
	instanceId := (metadata at: #'service.instance.id') asString.
	suffix := instanceId first: (8 min: instanceId size).
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'pharo-';
				  nextPutAll: version asString;
				  nextPut: $-;
				  nextPutAll: port asString;
				  nextPut: $-;
				  nextPutAll: suffix ]
]

{ #category : 'private - exporting' }
MCPMonitoringState >> exportLogMessage: aString timestamp: timestamp [

	self exportEnabled ifFalse: [ ^ self ].
	[ self writeJSONLine: (self logRecordJSONFor: aString timestamp: timestamp) to: self logFileReference ]
		on: Error
		do: [ :ignored | nil ]
]

{ #category : 'private - exporting' }
MCPMonitoringState >> exportMetrics [

	self exportEnabled ifFalse: [ ^ self ].
	[ self writeMetricsSnapshot ]
		on: Error
		do: [ :ignored | nil ]
]

{ #category : 'private - tracing' }
MCPMonitoringState >> exportTraceRecord: aRecord [

	(self exportEnabled and: [ aRecord isTraceWorthy ]) ifFalse: [ ^ self ].
	[ self writeJSONLine: (self traceRecordJSONFor: aRecord) to: self traceFileReference ]
		on: Error
		do: [ :error | self recordLog: 'Trace export failed: ' , error class name asString ]
]

{ #category : 'actions' }
MCPMonitoringState >> forceFlush [

	self exportMetrics
]

{ #category : 'initialization' }
MCPMonitoringState >> initialize [

	super initialize.
	enabled := true.
	statsByTool := Dictionary new.
	recentCalls := OrderedCollection new.
	nextCallId := 0.
	maxRecentCalls := 100.
	maxLogEntries := 200.
	outlierFactor := 3.
	minimumOutlierMilliseconds := 250.
	outputBudgetBytes := self defaultOutputBudgetBytes
]

{ #category : 'testing' }
MCPMonitoringState >> isNoop [

	^ false
]

{ #category : 'private - tracing' }
MCPMonitoringState >> isSensitiveTraceKey: aKey [

	| lowerKey |
	lowerKey := aKey asString asLowercase.
	^ #( 'password' 'passphrase' 'token' 'secret' 'credential' 'authorization' 'apikey' 'api_key' ) anySatisfy: [ :term |
		  lowerKey includesSubstring: term ]
]

{ #category : 'private - tracing' }
MCPMonitoringState >> isVerboseTraceKey: aKey [

	^ #( 'stackTrace' 'signalerContext' ) includes: aKey asString
]

{ #category : 'private - logging' }
MCPMonitoringState >> logEntries [

	^ logEntries ifNil: [ logEntries := OrderedCollection new ]
]

{ #category : 'private - logging' }
MCPMonitoringState >> logEntry: aString [

	self logEntries add: aString.
	[ self logEntries size > self maxLogEntries ] whileTrue: [ self logEntries removeFirst ]
]

{ #category : 'accessing' }
MCPMonitoringState >> logFileReference [

	^ self exportInstanceDirectory ifNotNil: [ :directory | directory / 'logs.jsonl' ]
]

{ #category : 'private' }
MCPMonitoringState >> logMessageForRecord: aRecord [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: (self logStatusLabelForStatus: aRecord status);
				  nextPutAll: ' tool ';
				  nextPutAll: aRecord toolName;
				  nextPutAll: ' #';
				  print: aRecord id;
				  nextPutAll: ' in ';
				  print: aRecord durationMilliseconds;
				  nextPutAll: ' ms';
				  nextPutAll: ' | out ';
				  print: aRecord outputByteCount;
				  nextPutAll: ' bytes'.
			  aRecord displaySummary isEmpty ifFalse: [
					  stream
						  nextPutAll: ' - ';
						  nextPutAll: aRecord displaySummary ] ]
]

{ #category : 'private - exporting' }
MCPMonitoringState >> logRecordDictionaryFor: aString timestamp: timestamp [

	^ {
		  (#schemaVersion -> 1).
		  (#'event.name' -> 'mcp.log').
		  (#timestamp -> timestamp asString).
		  (#message -> aString) } asDictionary
]

{ #category : 'private - exporting' }
MCPMonitoringState >> logRecordJSONFor: aString timestamp: timestamp [

	^ STONJSON toString: (self logRecordDictionaryFor: aString timestamp: timestamp)
]

{ #category : 'private' }
MCPMonitoringState >> logStatusLabelForStatus: statusString [

	statusString = 'ok' ifTrue: [ ^ 'OK' ].
	statusString = 'error' ifTrue: [ ^ 'Error' ].
	^ statusString capitalized
]

{ #category : 'logging' }
MCPMonitoringState >> logs [

	^ self logEntries asArray
]

{ #category : 'accessing' }
MCPMonitoringState >> maxLogEntries [

	^ maxLogEntries ifNil: [ 200 ]
]

{ #category : 'accessing' }
MCPMonitoringState >> maxLogEntries: anInteger [

	maxLogEntries := anInteger
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

	^ 20
]

{ #category : 'accessing' }
MCPMonitoringState >> maxTraceDepth [

	^ 4
]

{ #category : 'accessing' }
MCPMonitoringState >> maxTraceStringLength [

	^ 1000
]

{ #category : 'accessing' }
MCPMonitoringState >> metrics [

	^ self statsByTool values asSortedCollection: [ :left :right | left toolName <= right toolName ]
]

{ #category : 'accessing' }
MCPMonitoringState >> metricsFileReference [

	^ self exportInstanceDirectory ifNotNil: [ :directory | directory / 'metrics.json' ]
]

{ #category : 'private - exporting' }
MCPMonitoringState >> metricsSnapshotDictionary [

	^ {
		  (#schemaVersion -> 1).
		  (#updatedAt -> DateAndTime now asString).
		  (#totalCallCount -> self totalCallCount).
		  (#totalErrorCount -> self totalErrorCount).
		  (#totalOutputBudgetExceededCount -> self totalOutputBudgetExceededCount).
		  (#tools -> (self metrics collect: [ :each | each asMetricsDictionary ] as: Array)) } asDictionary
]

{ #category : 'accessing' }
MCPMonitoringState >> minimumOutlierMilliseconds [

	^ minimumOutlierMilliseconds ifNil: [ 250 ]
]

{ #category : 'accessing' }
MCPMonitoringState >> minimumOutlierMilliseconds: anInteger [

	minimumOutlierMilliseconds := anInteger
]

{ #category : 'private - exporting' }
MCPMonitoringState >> newResourceMetadata [

	^ {
		  (#schemaVersion -> 1).
		  (#'service.name' -> 'mcp-pharo').
		  (#'service.instance.id' -> UUID new asString).
		  (#createdAt -> DateAndTime now asString) } asDictionary
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
MCPMonitoringState >> outputBudgetBytes [

	^ outputBudgetBytes ifNil: [ self defaultOutputBudgetBytes ]
]

{ #category : 'accessing' }
MCPMonitoringState >> outputBudgetBytes: anInteger [

	outputBudgetBytes := anInteger
]

{ #category : 'private - budgets' }
MCPMonitoringState >> outputBudgetDataForResult: aToolResult error: anError [

	| byteCount explanation |
	byteCount := self approximateOutputBytesForResult: aToolResult error: anError.
	explanation := self outputBudgetExplanationForByteCount: byteCount.
	^ {
		  (#outputBytes -> byteCount).
		  (#approximateOutputTokens -> (self approximateOutputTokensForBytes: byteCount)).
		  (#outputBudgetBytes -> self outputBudgetBytes).
		  (#outputBudgetExceeded -> explanation isNotEmpty).
		  (#outputBudgetExplanation -> explanation) } asDictionary
]

{ #category : 'private - budgets' }
MCPMonitoringState >> outputBudgetExplanationForByteCount: byteCount [

	byteCount <= self outputBudgetBytes ifTrue: [ ^ '' ].
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Output ';
				  print: byteCount;
				  nextPutAll: ' bytes exceeds budget ';
				  print: self outputBudgetBytes;
				  nextPutAll: ' bytes; consider pagination, handles, or summary-first output' ]
]

{ #category : 'displaying' }
MCPMonitoringState >> outputBudgetGuidance [

	| attentionStats displayedCount |
	attentionStats := self statsNeedingOutputBudgetAttention.
	attentionStats isEmpty ifTrue: [ ^ '' ].
	displayedCount := 0.
	^ String streamContents: [ :stream |
			  stream nextPutAll: 'Output budget: '.
			  attentionStats do: [ :stats |
					  displayedCount < 3 ifTrue: [
							  displayedCount > 0 ifTrue: [ stream nextPutAll: ' | ' ].
							  stream nextPutAll: stats outputBudgetGuidance.
							  displayedCount := displayedCount + 1 ] ] ]
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

	| timestamp |
	self enabled ifFalse: [ ^ self ].
	timestamp := DateAndTime now.
	self logEntry: aString.
	self exportLogMessage: aString timestamp: timestamp
]

{ #category : 'private - budgets' }
MCPMonitoringState >> recordOutputBudgetFor: aRecord result: aToolResult error: anError [

	aRecord recordOutputBudget: (self outputBudgetDataForResult: aToolResult error: anError)
]

{ #category : 'recording' }
MCPMonitoringState >> recordSessionEndFor: anMCP [

	self resourceMetadata at: #sessionEndedAt put: DateAndTime now asString.
	self exportEnabled ifTrue: [ self writeResourceMetadata ].
	self forceFlush
]

{ #category : 'recording' }
MCPMonitoringState >> recordSessionStartFor: anMCP [

	self resourceMetadata at: #sessionStartedAt put: DateAndTime now asString.
	self resourceMetadata removeKey: #sessionEndedAt ifAbsent: [ nil ].
	self exportEnabled ifTrue: [ self writeResourceMetadata ]
]

{ #category : 'recording' }
MCPMonitoringState >> recordToolCallFinish: aRecord result: aToolResult error: anError [

	| explanation finishTimestamp stats statusString duration |
	aRecord ifNil: [ ^ self ].
	self enabled ifFalse: [ ^ self ].
	finishTimestamp := DateAndTime now.
	duration := (finishTimestamp - aRecord startedAt) asMilliSeconds.
	statusString := self statusForResult: aToolResult error: anError.
	stats := self statsForToolNamed: aRecord toolName.
	explanation := self outlierExplanationForDurationMilliseconds: duration stats: stats.
	aRecord finishAt: finishTimestamp durationMilliseconds: duration status: statusString.
	aRecord errorClass: (self errorClassNameFor: anError).
	aRecord summary: (self summaryForResult: aToolResult).
	aRecord outlierExplanation: explanation.
	self recordOutputBudgetFor: aRecord result: aToolResult error: anError.
	aRecord eventKinds: (self eventKindsForRecord: aRecord).
	self captureTraceSnapshotsFor: aRecord result: aToolResult error: anError.
	self exportTraceRecord: aRecord.
	stats recordCall: aRecord.
	self addRecentCall: aRecord.
	lastActivityAt := finishTimestamp.
	self exportMetrics.
	self recordLog: (self logMessageForRecord: aRecord).
	^ aRecord
]

{ #category : 'recording' }
MCPMonitoringState >> recordToolCallStart: aToolName input: inputObject dispatchPath: dispatchPath context: contextDictionary [

	| record startTimestamp |
	self enabled ifFalse: [ ^ nil ].
	nextCallId := self nextCallId + 1.
	startTimestamp := DateAndTime now.
	record := MCPToolCallRecord id: self nextCallId toolName: aToolName asString startedAt: startTimestamp.
	record inputObject: inputObject.
	record inputByteCount: (inputObject ifNil: [ 0 ] ifNotNil: [ self approximateOutputBytesForObject: inputObject ]).
	record dispatchPath: dispatchPath asString.
	lastActivityAt := startTimestamp.
	self recordLog: 'Begin tool ' , aToolName asString , ' #' , record id asString.
	^ record
]

{ #category : 'accessing' }
MCPMonitoringState >> resourceFileReference [

	^ self exportInstanceDirectory ifNotNil: [ :directory | directory / 'resource.json' ]
]

{ #category : 'accessing' }
MCPMonitoringState >> resourceMetadata [

	^ resourceMetadata ifNil: [ resourceMetadata := self newResourceMetadata ]
]

{ #category : 'accessing' }
MCPMonitoringState >> resourceMetadata: aDictionary [

	| metadata |
	metadata := self resourceMetadata copy.
	aDictionary ifNotNil: [ aDictionary keysAndValuesDo: [ :key :value | metadata at: key put: value ] ].
	resourceMetadata := metadata.
	exportInstanceDirectory := nil
]

{ #category : 'private - tracing' }
MCPMonitoringState >> shouldIncludeTraceAssociation: anAssociation [

	| value |
	(self isVerboseTraceKey: anAssociation key) ifTrue: [ ^ false ].
	value := anAssociation value.
	value ifNil: [ ^ false ].
	(value isString and: [ value isEmpty ]) ifTrue: [ ^ false ].
	(value isCollection and: [ value isString not and: [ value isEmpty ] ]) ifTrue: [ ^ false ].
	^ true
]

{ #category : 'actions' }
MCPMonitoringState >> shutdown [

	self recordSessionEndFor: nil
]

{ #category : 'accessing' }
MCPMonitoringState >> statsByTool [

	^ statsByTool ifNil: [ statsByTool := Dictionary new ]
]

{ #category : 'accessing' }
MCPMonitoringState >> statsForToolNamed: aToolName [

	^ self statsByTool at: aToolName asString ifAbsentPut: [ MCPToolCallStats forToolNamed: aToolName asString ]
]

{ #category : 'private - budgets' }
MCPMonitoringState >> statsNeedingOutputBudgetAttention [

	^ (self metrics select: [ :each | each outputBudgetExceededCount > 0 ]) asArray sort: [ :left :right |
			  left outputBudgetExceededCount = right outputBudgetExceededCount
				  ifTrue: [ left maxOutputBytes >= right maxOutputBytes ]
				  ifFalse: [ left outputBudgetExceededCount > right outputBudgetExceededCount ] ]
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

	| guidance |
	self enabled ifFalse: [ ^ 'Observability disabled' ].
	guidance := self outputBudgetGuidance.
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Observability enabled. Calls: ';
				  print: self totalCallCount;
				  nextPutAll: ' | Errors: ';
				  print: self totalErrorCount;
				  nextPutAll: ' | Output overruns: ';
				  print: self totalOutputBudgetExceededCount.
			  guidance isEmpty ifFalse: [
					  stream
						  nextPutAll: ' | ';
						  nextPutAll: guidance ] ]
]

{ #category : 'private' }
MCPMonitoringState >> summaryForResult: aToolResult [

	| structuredContent |
	aToolResult ifNil: [ ^ '' ].
	structuredContent := aToolResult structuredContent.
	structuredContent ifNil: [ ^ '' ].
	^ (structuredContent at: #summary ifAbsent: [ structuredContent at: 'summary' ifAbsent: [ '' ] ]) asString
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
MCPMonitoringState >> totalOutputBudgetExceededCount [

	^ self metrics inject: 0 into: [ :sum :each | sum + each outputBudgetExceededCount ]
]

{ #category : 'private - tracing' }
MCPMonitoringState >> traceEventNameForRecord: aRecord [

	aRecord status = 'error' ifTrue: [ ^ 'mcp.tool_call.error' ].
	aRecord outputBudgetExceeded ifTrue: [ ^ 'mcp.tool_call.output_budget_exceeded' ].
	aRecord outlierExplanation ifNotEmpty: [ ^ 'mcp.tool_call.duration_outlier' ].
	^ 'mcp.tool_call.completed'
]

{ #category : 'accessing' }
MCPMonitoringState >> traceFileReference [

	^ self exportInstanceDirectory ifNotNil: [ :directory | directory / 'traces.jsonl' ]
]

{ #category : 'private - tracing' }
MCPMonitoringState >> traceRecordDictionaryFor: aRecord [

	| dictionary |
	dictionary := Dictionary new.
	dictionary at: #schemaVersion put: 1.
	dictionary at: #'event.name' put: (self traceEventNameForRecord: aRecord).
	dictionary at: #'event.kinds' put: aRecord eventKinds.
	dictionary at: #id put: aRecord id.
	dictionary at: #toolName put: aRecord toolName.
	dictionary at: #dispatchPath put: aRecord dispatchPath.
	dictionary at: #startedAt put: aRecord displayStartedAt.
	dictionary at: #durationMilliseconds put: aRecord durationMilliseconds.
	dictionary at: #status put: aRecord status.
	aRecord errorClass ifNotEmpty: [ :errorClass | dictionary at: #errorClass put: errorClass ].
	aRecord inputByteCount > 0 ifTrue: [ dictionary at: #inputBytes put: aRecord inputByteCount ].
	aRecord outputByteCount > 0 ifTrue: [
			dictionary at: #outputBytes put: aRecord outputByteCount.
			dictionary at: #approximateOutputTokens put: aRecord approximateOutputTokenCount ].
	aRecord outputBudgetExceeded ifTrue: [
			dictionary at: #outputBudgetBytes put: aRecord outputBudgetBytes.
			aRecord outputBudgetExplanation ifNotEmpty: [ :explanation | dictionary at: #outputBudgetExplanation put: explanation ] ].
	aRecord outlierExplanation ifNotEmpty: [ :explanation | dictionary at: #outlierExplanation put: explanation ].
	aRecord inputSnapshot ifNotNil: [ :snapshot | dictionary at: #input put: snapshot ].
	aRecord outputSnapshot ifNotNil: [ :snapshot | dictionary at: #output put: snapshot ].
	^ dictionary
]

{ #category : 'private - tracing' }
MCPMonitoringState >> traceRecordJSONFor: aRecord [

	^ STONJSON toString: (self traceRecordDictionaryFor: aRecord)
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
	(anObject isString or: [ anObject isSymbol ]) ifTrue: [ ^ self traceStringSnapshotFor: anObject ].
	(anObject isNumber or: [ anObject == true or: [ anObject == false ] ]) ifTrue: [ ^ anObject ].
	anObject isCharacter ifTrue: [ ^ anObject asString ].
	depth >= self maxTraceDepth ifTrue: [ ^ self traceStringSnapshotFor: anObject printString ].
	anObject isAssociation ifTrue: [ ^ self traceSnapshotForAssociation: anObject depth: depth ].
	anObject isDictionary ifTrue: [ ^ self traceSnapshotForDictionary: anObject depth: depth ].
	(anObject isCollection and: [ anObject isString not ]) ifTrue: [ ^ self traceSnapshotForCollection: anObject depth: depth ].
	^ self traceStringSnapshotFor: anObject printString
]

{ #category : 'private - tracing' }
MCPMonitoringState >> traceSnapshotForAssociation: anAssociation depth: depth [

	(self isSensitiveTraceKey: anAssociation key) ifTrue: [ ^ anAssociation key -> '<redacted>' ].
	^ anAssociation key -> (self traceSnapshotFor: anAssociation value depth: depth + 1)
]

{ #category : 'private - tracing' }
MCPMonitoringState >> traceSnapshotForCollection: aCollection depth: depth [

	| array limit overflow snapshot |
	array := aCollection asArray.
	limit := array size min: self maxTraceCollectionItems.
	overflow := array size - limit.
	snapshot := (1 to: limit) collect: [ :index | self traceSnapshotFor: (array at: index) depth: depth + 1 ].
	overflow positive ifTrue: [ snapshot := snapshot copyWith: 'truncated ' , overflow asString , ' items omitted' ].
	^ snapshot asArray
]

{ #category : 'private - tracing' }
MCPMonitoringState >> traceSnapshotForDictionary: aDictionary depth: depth [

	| snapshot |
	snapshot := Dictionary new.
	aDictionary associationsDo: [ :association |
			(snapshot size < self maxTraceCollectionItems and: [ self shouldIncludeTraceAssociation: association ]) ifTrue: [
					| sanitized |
					sanitized := self traceSnapshotForAssociation: association depth: depth.
					snapshot at: sanitized key put: sanitized value ] ].
	aDictionary size > self maxTraceCollectionItems ifTrue: [
		snapshot at: #__truncated__ put: aDictionary size - self maxTraceCollectionItems ].
	^ snapshot
]

{ #category : 'private - tracing' }
MCPMonitoringState >> traceSnapshotForResult: aToolResult error: anError [

	aToolResult ifNotNil: [ ^ self traceSnapshotFor: aToolResult structuredContent ].
	anError ifNil: [ ^ nil ].
	^ self traceSnapshotFor: {
			  (#errorClass -> anError class name asString).
			  (#message -> (anError messageText ifNil: [ anError asString ])) } asDictionary
]

{ #category : 'private - tracing' }
MCPMonitoringState >> traceStringSnapshotFor: aString [

	| text |
	text := aString asString.
	text size <= self maxTraceStringLength ifTrue: [ ^ text ].
	^ (text first: self maxTraceStringLength) , '... <truncated>'
]

{ #category : 'private - exporting' }
MCPMonitoringState >> writeJSON: aDictionary to: aFileReference [

	| temporaryFile |
	aFileReference parent ensureCreateDirectory.
	temporaryFile := aFileReference parent / (aFileReference basename , '.' , UUID new asString , '.tmp').
	[
		temporaryFile writeStreamDo: [ :stream | stream nextPutAll: (STONJSON toString: aDictionary) ].
		aFileReference exists ifTrue: [ aFileReference delete ].
		temporaryFile renameTo: aFileReference basename.
		temporaryFile := nil.
		aFileReference ] ensure: [ temporaryFile ifNotNil: [ temporaryFile exists ifTrue: [ temporaryFile delete ] ] ]
]

{ #category : 'private - exporting' }
MCPMonitoringState >> writeJSONLine: aString to: aFileReference [

	aFileReference parent ensureCreateDirectory.
	aFileReference writeStreamDo: [ :stream |
			stream
				setToEnd;
				nextPutAll: aString;
				lf ]
]

{ #category : 'private - exporting' }
MCPMonitoringState >> writeMetricsSnapshot [

	self writeJSON: self metricsSnapshotDictionary to: self metricsFileReference
]

{ #category : 'private - exporting' }
MCPMonitoringState >> writeResourceMetadata [

	self writeJSON: self resourceMetadata to: self resourceFileReference
]
