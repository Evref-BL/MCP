"
Runtime observability state for an MCP server. It records local log lines, per-tool timing and output-size metrics, recent completed calls, and compact trace records for errors, timing outliers, or output-budget overruns. A server's own exports to the default directory; one made alone exports nowhere until it is given a directory.
"
Class {
	#name : 'MCPLocalObservabilityBackend',
	#superclass : 'MCPRecordingObservabilityBackend',
	#instVars : [
		'logEntries',
		'statsByTool',
		'recentCalls',
		'exportDirectory',
		'exportInstanceDirectory',
		'resourceMetadata',
		'lastMetricsExportAt',
		'metricsExportPending',
		'metricsExportIntervalMilliseconds',
		'sessionImageSession'
	],
	#category : 'MCP-Observability',
	#package : 'MCP',
	#tag : 'Observability'
}

{ #category : 'defaults' }
MCPLocalObservabilityBackend class >> defaultExportDirectory [

	^ Smalltalk imageFile asFileReference parent / 'pharo-local' / 'mcp' / 'observability'
]

{ #category : 'class initialization' }
MCPLocalObservabilityBackend class >> initialize [
	"The backends made before their sessions recorded the image session they started in take this one, which is the one their running servers started in or a later one: a save carries them into later starts, which end them silently."

	self allSubInstancesDo: [ :each | each sessionImageSession ifNil: [ each sessionImageSession: Smalltalk session ] ]
]

{ #category : 'private' }
MCPLocalObservabilityBackend >> addRecentCall: aRecord [

	self critical: [
			self recentCalls addFirst: aRecord.
			[ self recentCalls size > self maxRecentCalls ] whileTrue: [ self recentCalls removeLast ] ]
]

{ #category : 'private - tracing' }
MCPLocalObservabilityBackend >> captureTraceSnapshotsFor: aRecord result: aToolResult error: anError [

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
					aRecord outputSnapshot: (self traceSnapshotFor: ((self errorSummaryFor: snapshotError)
								  at: #during put: 'trace snapshot creation';
								  yourself)) ] ] ensure: [ aRecord inputObject: nil ]
]

{ #category : 'clearing' }
MCPLocalObservabilityBackend >> clear [

	self critical: [
			self statsByTool removeAll.
			self recentCalls removeAll.
			lastCallId := 0.
			self clearLogs ].
	self recordLog: 'Observability cleared'
]

{ #category : 'logging' }
MCPLocalObservabilityBackend >> clearLogs [

	self critical: [ self logEntries removeAll ]
]

{ #category : 'accessing' }
MCPLocalObservabilityBackend >> exportDirectory [

	^ exportDirectory
]

{ #category : 'accessing' }
MCPLocalObservabilityBackend >> exportDirectory: aPath [

	exportDirectory := aPath ifNotNil: [ :path | path asFileReference ].
	exportInstanceDirectory := nil
]

{ #category : 'testing' }
MCPLocalObservabilityBackend >> exportEnabled [

	^ self exportDirectory isNotNil
]

{ #category : 'accessing' }
MCPLocalObservabilityBackend >> exportInstanceDirectory [

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
MCPLocalObservabilityBackend >> exportInstanceDirectoryName [

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
MCPLocalObservabilityBackend >> exportLogMessage: aString timestamp: timestamp [

	self exportEnabled ifFalse: [ ^ self ].
	[ self writeJSONLine: (self logRecordJSONFor: aString timestamp: timestamp) to: self logFileReference ]
		on: Error
		do: [ :ignored | nil ]
]

{ #category : 'private - exporting' }
MCPLocalObservabilityBackend >> exportMetrics [
	"The metrics file is a snapshot of every call so far, so rewriting it after each call only repeats itself: it is written at once when the last write is older than the interval, and otherwise once, when the interval has passed, however many calls end in between."

	| elapsed |
	self exportEnabled ifFalse: [ ^ self ].
	(metricsExportPending ifNil: [ false ]) ifTrue: [ ^ self ].
	elapsed := lastMetricsExportAt ifNil: [ self metricsExportIntervalMilliseconds ] ifNotNil: [ :at | Time millisecondsSince: at ].
	elapsed >= self metricsExportIntervalMilliseconds ifTrue: [ ^ self exportMetricsNow ].
	metricsExportPending := true.
	[
		(Delay forMilliseconds: self metricsExportIntervalMilliseconds - elapsed) wait.
		metricsExportPending := false.
		self exportMetricsNow ] forkAt: Processor userBackgroundPriority named: 'MCP metrics export'
]

{ #category : 'private - exporting' }
MCPLocalObservabilityBackend >> exportMetricsNow [

	self exportEnabled ifFalse: [ ^ self ].
	lastMetricsExportAt := Time millisecondClockValue.
	[ self writeMetricsSnapshot ]
		on: Error
		do: [ :ignored | nil ]
]

{ #category : 'private - tracing' }
MCPLocalObservabilityBackend >> exportTraceRecord: aRecord [

	(self exportEnabled and: [ aRecord isTraceWorthy ]) ifFalse: [ ^ self ].
	[ self writeJSONLine: (self traceRecordJSONFor: aRecord) to: self traceFileReference ]
		on: Error
		do: [ :error | self recordLog: 'Trace export failed: ' , error class name asString ]
]

{ #category : 'actions' }
MCPLocalObservabilityBackend >> forceFlush [

	self exportMetricsNow
]

{ #category : 'initialization' }
MCPLocalObservabilityBackend >> initialize [

	super initialize.
	statsByTool := Dictionary new.
	recentCalls := OrderedCollection new.
	metricsExportIntervalMilliseconds := 5000.
	metricsExportPending := false
]

{ #category : 'private - tracing' }
MCPLocalObservabilityBackend >> isSensitiveTraceKey: aKey [

	| lowerKey |
	lowerKey := aKey asString asLowercase.
	^ #( 'password' 'passphrase' 'token' 'secret' 'credential' 'authorization' 'apikey' 'api_key' ) anySatisfy: [ :term |
		  lowerKey includesSubstring: term ]
]

{ #category : 'private - tracing' }
MCPLocalObservabilityBackend >> isVerboseTraceKey: aKey [

	^ #( 'stackTrace' 'signalerContext' ) includes: aKey asString
]

{ #category : 'private - exporting' }
MCPLocalObservabilityBackend >> jsonStringFor: anObject [
	"JSON for a file read outside the image, so written like an answer: every line of its text ended by a line feed."

	^ STONJSON toString: (MCPLineEndings leaving: anObject)
]

{ #category : 'private - logging' }
MCPLocalObservabilityBackend >> logEntries [

	^ logEntries ifNil: [ logEntries := OrderedCollection new ]
]

{ #category : 'private - logging' }
MCPLocalObservabilityBackend >> logEntry: aString [

	self critical: [
			self logEntries add: aString.
			[ self logEntries size > self maxLogEntries ] whileTrue: [ self logEntries removeFirst ] ]
]

{ #category : 'accessing' }
MCPLocalObservabilityBackend >> logFileReference [

	^ self exportInstanceDirectory ifNotNil: [ :directory | directory / 'logs.jsonl' ]
]

{ #category : 'private' }
MCPLocalObservabilityBackend >> logMessageForRecord: aRecord [

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
MCPLocalObservabilityBackend >> logRecordDictionaryFor: aString timestamp: timestamp [

	^ {
		  (#schemaVersion -> 1).
		  (#'event.name' -> 'mcp.log').
		  (#timestamp -> timestamp asString).
		  (#message -> aString) } asDictionary
]

{ #category : 'private - exporting' }
MCPLocalObservabilityBackend >> logRecordJSONFor: aString timestamp: timestamp [

	^ self jsonStringFor: (self logRecordDictionaryFor: aString timestamp: timestamp)
]

{ #category : 'private' }
MCPLocalObservabilityBackend >> logStatusLabelForStatus: statusString [

	statusString = 'ok' ifTrue: [ ^ 'OK' ].
	statusString = 'error' ifTrue: [ ^ 'Error' ].
	^ statusString capitalized
]

{ #category : 'logging' }
MCPLocalObservabilityBackend >> logs [

	^ self critical: [ self logEntries asArray ]
]

{ #category : 'accessing' }
MCPLocalObservabilityBackend >> maxLogEntries [

	^ 200
]

{ #category : 'accessing' }
MCPLocalObservabilityBackend >> maxRecentCalls [

	^ 100
]

{ #category : 'accessing' }
MCPLocalObservabilityBackend >> maxTraceCollectionItems [

	^ 20
]

{ #category : 'accessing' }
MCPLocalObservabilityBackend >> maxTraceDepth [

	^ 4
]

{ #category : 'accessing' }
MCPLocalObservabilityBackend >> maxTraceStringLength [

	^ 1000
]

{ #category : 'accessing' }
MCPLocalObservabilityBackend >> metrics [

	^ (self critical: [ self statsByTool values ]) asSortedCollection: [ :left :right | left toolName <= right toolName ]
]

{ #category : 'accessing' }
MCPLocalObservabilityBackend >> metricsExportIntervalMilliseconds [
	"The least time between two writes of the metrics file."

	^ metricsExportIntervalMilliseconds ifNil: [ 5000 ]
]

{ #category : 'accessing' }
MCPLocalObservabilityBackend >> metricsExportIntervalMilliseconds: anInteger [

	metricsExportIntervalMilliseconds := anInteger
]

{ #category : 'accessing' }
MCPLocalObservabilityBackend >> metricsFileReference [

	^ self exportInstanceDirectory ifNotNil: [ :directory | directory / 'metrics.json' ]
]

{ #category : 'private - exporting' }
MCPLocalObservabilityBackend >> metricsSnapshotDictionary [

	^ {
		  (#schemaVersion -> 1).
		  (#updatedAt -> DateAndTime now asString).
		  (#totalCallCount -> self totalCallCount).
		  (#totalErrorCount -> self totalErrorCount).
		  (#totalOutputBudgetExceededCount -> self totalOutputBudgetExceededCount).
		  (#tools -> (self metrics collect: [ :each | each asMetricsDictionary ] as: Array)) } asDictionary
]

{ #category : 'accessing' }
MCPLocalObservabilityBackend >> minimumOutlierMilliseconds [

	^ 250
]

{ #category : 'private - exporting' }
MCPLocalObservabilityBackend >> newResourceMetadata [

	^ {
		  (#schemaVersion -> 1).
		  (#'service.name' -> 'mcp-pharo').
		  (#'service.instance.id' -> UUID new asString).
		  (#createdAt -> DateAndTime now asString) } asDictionary
]

{ #category : 'private' }
MCPLocalObservabilityBackend >> outlierExplanationForDurationMilliseconds: duration stats: stats [

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
MCPLocalObservabilityBackend >> outlierFactor [

	^ 3
]

{ #category : 'accessing' }
MCPLocalObservabilityBackend >> recentCallRecords [

	^ self critical: [ self recentCalls asArray ]
]

{ #category : 'accessing' }
MCPLocalObservabilityBackend >> recentCalls [

	^ recentCalls
]

{ #category : 'logging' }
MCPLocalObservabilityBackend >> recordLog: aString [

	self logEntry: aString.
	self exportLogMessage: aString timestamp: DateAndTime now
]

{ #category : 'recording' }
MCPLocalObservabilityBackend >> recordSessionEnd [
	"A session that started before the image last started, which a save carried into this start, ends without its end being recorded, as a call does: the session that started it is the one it belongs to, and the time it lasted would count the time the image was not running."

	self sessionStartedInAnEarlierImageSession ifFalse: [
			self resourceMetadata at: #sessionEndedAt put: DateAndTime now asString.
			self exportEnabled ifTrue: [ self writeResourceMetadata ] ].
	self forceFlush
]

{ #category : 'recording' }
MCPLocalObservabilityBackend >> recordSessionStart [
	"A session starts now, in this image session."

	sessionImageSession := Smalltalk session.
	self resourceMetadata at: #sessionStartedAt put: DateAndTime now asString.
	self resourceMetadata removeKey: #sessionEndedAt ifAbsent: [ nil ].
	self exportEnabled ifTrue: [ self writeResourceMetadata ]
]

{ #category : 'recording' }
MCPLocalObservabilityBackend >> recordToolCallFinish: aRecord result: aToolResult error: anError [
	"A call that started before the image last started, which a save carried into this start, is not recorded: not counted, logged or traced, since the time it took is the time the image was not running, and the session that started it is the one it belongs to."

	| stats |
	aRecord ifNil: [ ^ self ].
	aRecord startedInAnEarlierImageSession ifTrue: [ ^ aRecord ].
	self
		finishRecord: aRecord
		result: aToolResult
		error: anError
		at: DateAndTime now.
	stats := self statsForToolNamed: aRecord toolName.
	aRecord summary: (self summaryForResult: aToolResult).
	aRecord outlierExplanation:
		(self critical: [ self outlierExplanationForDurationMilliseconds: aRecord durationMilliseconds stats: stats ]).
	self captureTraceSnapshotsFor: aRecord result: aToolResult error: anError.
	self exportTraceRecord: aRecord.
	self critical: [ stats recordCall: aRecord ].
	self addRecentCall: aRecord.
	self exportMetrics.
	self recordLog: (self logMessageForRecord: aRecord).
	^ aRecord
]

{ #category : 'recording' }
MCPLocalObservabilityBackend >> recordToolCallStart: aToolName input: inputObject dispatchPath: dispatchPath context: contextDictionary [
	"A call is logged once, when it ends, with everything known about it then; until then it is in the record this answers."

	^ self newRecordFor: aToolName input: inputObject dispatchPath: dispatchPath
]

{ #category : 'accessing' }
MCPLocalObservabilityBackend >> resourceFileReference [

	^ self exportInstanceDirectory ifNotNil: [ :directory | directory / 'resource.json' ]
]

{ #category : 'accessing' }
MCPLocalObservabilityBackend >> resourceMetadata [

	^ resourceMetadata ifNil: [ resourceMetadata := self newResourceMetadata ]
]

{ #category : 'accessing' }
MCPLocalObservabilityBackend >> resourceMetadata: aDictionary [

	| metadata |
	metadata := self resourceMetadata copy.
	aDictionary ifNotNil: [ aDictionary keysAndValuesDo: [ :key :value | metadata at: key put: value ] ].
	resourceMetadata := metadata.
	exportInstanceDirectory := nil
]

{ #category : 'accessing' }
MCPLocalObservabilityBackend >> sessionImageSession [
	"The image session the server's session started in, or nil before it starts."

	^ sessionImageSession
]

{ #category : 'accessing' }
MCPLocalObservabilityBackend >> sessionImageSession: aSession [

	sessionImageSession := aSession
]

{ #category : 'testing' }
MCPLocalObservabilityBackend >> sessionStartedInAnEarlierImageSession [
	"Whether the server's session started before the image last started: the image was saved while the server ran, and this start of the saved image goes on with it until the server stops. A session with no recorded start counts as started in this image session."

	^ sessionImageSession isNotNil and: [ sessionImageSession ~~ Smalltalk session ]
]

{ #category : 'private - tracing' }
MCPLocalObservabilityBackend >> shouldIncludeTraceAssociation: anAssociation [

	| value |
	(self isVerboseTraceKey: anAssociation key) ifTrue: [ ^ false ].
	value := anAssociation value.
	value ifNil: [ ^ false ].
	(value isString and: [ value isEmpty ]) ifTrue: [ ^ false ].
	(value isCollection and: [ value isString not and: [ value isEmpty ] ]) ifTrue: [ ^ false ].
	^ true
]

{ #category : 'actions' }
MCPLocalObservabilityBackend >> shutdown [

	self recordSessionEnd
]

{ #category : 'accessing' }
MCPLocalObservabilityBackend >> statsByTool [

	^ statsByTool
]

{ #category : 'accessing' }
MCPLocalObservabilityBackend >> statsForToolNamed: aToolName [

	^ self critical: [ self statsByTool at: aToolName asString ifAbsentPut: [ MCPToolCallStats forToolNamed: aToolName asString ] ]
]

{ #category : 'private' }
MCPLocalObservabilityBackend >> summaryForResult: aToolResult [

	| structuredContent |
	aToolResult ifNil: [ ^ '' ].
	structuredContent := aToolResult structuredContent.
	structuredContent ifNil: [ ^ '' ].
	^ (structuredContent at: #summary ifAbsent: [ structuredContent at: 'summary' ifAbsent: [ '' ] ]) asString
]

{ #category : 'accessing' }
MCPLocalObservabilityBackend >> totalCallCount [

	^ self metrics inject: 0 into: [ :sum :each | sum + each callCount ]
]

{ #category : 'accessing' }
MCPLocalObservabilityBackend >> totalErrorCount [

	^ self metrics inject: 0 into: [ :sum :each | sum + each errorCount ]
]

{ #category : 'accessing' }
MCPLocalObservabilityBackend >> totalOutputBudgetExceededCount [

	^ self metrics inject: 0 into: [ :sum :each | sum + each outputBudgetExceededCount ]
]

{ #category : 'private - tracing' }
MCPLocalObservabilityBackend >> traceEventNameForRecord: aRecord [

	^ 'mcp.tool_call.' , (aRecord eventKinds ifEmpty: [ 'completed' ] ifNotEmpty: [ :kinds | kinds first ])
]

{ #category : 'accessing' }
MCPLocalObservabilityBackend >> traceFileReference [

	^ self exportInstanceDirectory ifNotNil: [ :directory | directory / 'traces.jsonl' ]
]

{ #category : 'private - tracing' }
MCPLocalObservabilityBackend >> traceRecordDictionaryFor: aRecord [

	| dictionary |
	dictionary := Dictionary new.
	dictionary at: #schemaVersion put: 1.
	dictionary at: #'event.name' put: (self traceEventNameForRecord: aRecord).
	dictionary at: #'event.kinds' put: aRecord eventKinds.
	dictionary at: #id put: aRecord id.
	dictionary at: #tool put: aRecord toolName.
	dictionary at: #dispatchPath put: aRecord dispatchPath.
	dictionary at: #startedAt put: aRecord displayStartedAt.
	dictionary at: #durationMilliseconds put: aRecord durationMilliseconds.
	dictionary at: #status put: aRecord status.
	aRecord errorClass ifNotEmpty: [ :errorClass | dictionary at: #errorClass put: errorClass ].
	aRecord errorKind ifNotEmpty: [ :errorKind | dictionary at: #errorKind put: errorKind ].
	aRecord errorCode ifNotEmpty: [ :errorCode | dictionary at: #errorCode put: errorCode ].
	aRecord causeClass ifNotEmpty: [ :causeClass | dictionary at: #causeClass put: causeClass ].
	aRecord schemaViolationKeywords ifNotEmpty: [ :keywords | dictionary at: #schemaViolationKeywords put: keywords ].
	aRecord schemaViolationCount > 0 ifTrue: [ dictionary at: #schemaViolationCount put: aRecord schemaViolationCount ].
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
MCPLocalObservabilityBackend >> traceRecordJSONFor: aRecord [

	^ self jsonStringFor: (self traceRecordDictionaryFor: aRecord)
]

{ #category : 'accessing' }
MCPLocalObservabilityBackend >> traceRecords [

	^ self recentCallRecords select: [ :each | each isTraceWorthy ]
]

{ #category : 'private - tracing' }
MCPLocalObservabilityBackend >> traceSnapshotFor: anObject [

	^ self traceSnapshotFor: anObject depth: 0
]

{ #category : 'private - tracing' }
MCPLocalObservabilityBackend >> traceSnapshotFor: anObject depth: depth [

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
MCPLocalObservabilityBackend >> traceSnapshotForAssociation: anAssociation depth: depth [

	(self isSensitiveTraceKey: anAssociation key) ifTrue: [ ^ anAssociation key -> '<redacted>' ].
	^ anAssociation key -> (self traceSnapshotFor: anAssociation value depth: depth + 1)
]

{ #category : 'private - tracing' }
MCPLocalObservabilityBackend >> traceSnapshotForCollection: aCollection depth: depth [

	| array limit overflow snapshot |
	array := aCollection asArray.
	limit := array size min: self maxTraceCollectionItems.
	overflow := array size - limit.
	snapshot := (1 to: limit) collect: [ :index | self traceSnapshotFor: (array at: index) depth: depth + 1 ].
	overflow positive ifTrue: [
			snapshot := snapshot copyWith:
				            (String streamContents: [ :stream | stream << 'truncated ' << overflow asString << ' items omitted' ]) ].
	^ snapshot asArray
]

{ #category : 'private - tracing' }
MCPLocalObservabilityBackend >> traceSnapshotForDictionary: aDictionary depth: depth [

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
MCPLocalObservabilityBackend >> traceSnapshotForResult: aToolResult error: anError [

	aToolResult ifNotNil: [ ^ self traceSnapshotFor: aToolResult structuredContent ].
	anError ifNil: [ ^ nil ].
	^ self traceSnapshotFor: (self errorSummaryFor: anError)
]

{ #category : 'private - tracing' }
MCPLocalObservabilityBackend >> traceStringSnapshotFor: aString [

	| text |
	text := aString asString.
	text size <= self maxTraceStringLength ifTrue: [ ^ text ].
	^ (text first: self maxTraceStringLength) , '... <truncated>'
]

{ #category : 'private - exporting' }
MCPLocalObservabilityBackend >> writeJSON: aDictionary to: aFileReference [

	| temporaryFile |
	aFileReference parent ensureCreateDirectory.
	temporaryFile := aFileReference parent
	                 / (String streamContents: [ :stream | stream << aFileReference basename << '.' << UUID new asString << '.tmp' ]).
	[
		temporaryFile writeStreamDo: [ :stream | stream nextPutAll: (self jsonStringFor: aDictionary) ].
		aFileReference exists ifTrue: [ aFileReference delete ].
		temporaryFile renameTo: aFileReference basename.
		temporaryFile := nil.
		aFileReference ] ensure: [ temporaryFile ifNotNil: [ temporaryFile exists ifTrue: [ temporaryFile delete ] ] ]
]

{ #category : 'private - exporting' }
MCPLocalObservabilityBackend >> writeJSONLine: aString to: aFileReference [

	aFileReference parent ensureCreateDirectory.
	aFileReference writeStreamDo: [ :stream |
			stream
				setToEnd;
				nextPutAll: aString;
				lf ]
]

{ #category : 'private - exporting' }
MCPLocalObservabilityBackend >> writeMetricsSnapshot [

	self writeJSON: self metricsSnapshotDictionary to: self metricsFileReference
]

{ #category : 'private - exporting' }
MCPLocalObservabilityBackend >> writeResourceMetadata [

	self writeJSON: self resourceMetadata to: self resourceFileReference
]
