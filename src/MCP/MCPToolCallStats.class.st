"
Aggregated monitoring metrics for one MCP tool. It tracks call counts, success/error counts, timing totals, min/max/last duration, output-size totals and maxima, output-budget overruns, and the last outlier explanation.
"
Class {
	#name : 'MCPToolCallStats',
	#superclass : 'Object',
	#instVars : [
		'toolName',
		'callCount',
		'successCount',
		'errorCount',
		'totalMilliseconds',
		'minMilliseconds',
		'maxMilliseconds',
		'lastMilliseconds',
		'firstStartedAt',
		'lastStartedAt',
		'lastFinishedAt',
		'lastOutlierExplanation',
		'totalOutputBytes',
		'maxOutputBytes',
		'lastOutputBytes',
		'lastApproximateOutputTokens',
		'outputBudgetExceededCount',
		'errorCountsByClass'
	],
	#category : 'MCP-Monitoring',
	#package : 'MCP',
	#tag : 'Monitoring'
}

{ #category : 'instance creation' }
MCPToolCallStats class >> forToolNamed: aToolName [

	^ self new
		  toolName: aToolName;
		  yourself
]

{ #category : 'converting' }
MCPToolCallStats >> asDictionary [

	^ {
		  (#toolName -> self toolName).
		  (#callCount -> self callCount).
		  (#successCount -> self successCount).
		  (#errorCount -> self errorCount).
		  (#errorCountsByClass -> self errorCountsByClass copy).
		  (#averageMilliseconds -> self averageMilliseconds asFloat).
		  (#minMilliseconds -> (self minMilliseconds ifNil: [ 0 ])).
		  (#maxMilliseconds -> (self maxMilliseconds ifNil: [ 0 ])).
		  (#lastMilliseconds -> (self lastMilliseconds ifNil: [ 0 ])).
		  (#firstCallAt -> self firstCallAt).
		  (#lastCallAt -> self lastCallAt).
		  (#averageOutputBytes -> self averageOutputBytes asFloat).
		  (#maxOutputBytes -> self maxOutputBytes).
		  (#lastOutputBytes -> self lastOutputBytes).
		  (#lastApproximateOutputTokens -> self lastApproximateOutputTokens).
		  (#outputBudgetExceededCount -> self outputBudgetExceededCount).
		  (#outputBudgetGuidance -> self outputBudgetGuidance).
		  (#lastOutlierExplanation -> (self lastOutlierExplanation ifNil: [ '' ])) } asDictionary
]

{ #category : 'converting' }
MCPToolCallStats >> asMetricsDictionary [

	| dictionary |
	dictionary := {
		              (#toolName -> self toolName).
		              (#callCount -> self callCount).
		              (#successCount -> self successCount).
		              (#averageMilliseconds -> self averageMilliseconds asFloat).
		              (#minMilliseconds -> (self minMilliseconds ifNil: [ 0 ])).
		              (#maxMilliseconds -> (self maxMilliseconds ifNil: [ 0 ])).
		              (#lastMilliseconds -> (self lastMilliseconds ifNil: [ 0 ])).
		              (#firstCallAt -> self firstCallAt).
		              (#lastCallAt -> self lastCallAt).
		              (#averageOutputBytes -> self averageOutputBytes asFloat).
		              (#maxOutputBytes -> self maxOutputBytes).
		              (#lastOutputBytes -> self lastOutputBytes).
		              (#lastApproximateOutputTokens -> self lastApproximateOutputTokens) } asDictionary.
	self errorCount positive ifTrue: [
			dictionary at: #errorCount put: self errorCount.
			dictionary at: #errorCountsByClass put: self errorCountsByClass copy ].
	self outputBudgetExceededCount positive ifTrue: [ dictionary at: #outputBudgetExceededCount put: self outputBudgetExceededCount ].
	self lastOutlierExplanation ifNotNil: [ :explanation |
		explanation isEmpty ifFalse: [ dictionary at: #lastOutlierExplanation put: explanation ] ].
	^ dictionary
]

{ #category : 'accessing' }
MCPToolCallStats >> averageMilliseconds [

	self callCount = 0 ifTrue: [ ^ 0 ].
	^ self totalMilliseconds / self callCount
]

{ #category : 'accessing' }
MCPToolCallStats >> averageOutputBytes [

	self callCount = 0 ifTrue: [ ^ 0 ].
	^ self totalOutputBytes / self callCount
]

{ #category : 'accessing' }
MCPToolCallStats >> callCount [

	^ callCount ifNil: [ 0 ]
]

{ #category : 'displaying' }
MCPToolCallStats >> displayAverageMilliseconds [

	^ self averageMilliseconds asFloat printShowingDecimalPlaces: 1
]

{ #category : 'displaying' }
MCPToolCallStats >> displayAverageOutputBytes [

	^ self averageOutputBytes asFloat printShowingDecimalPlaces: 1
]

{ #category : 'displaying' }
MCPToolCallStats >> displayLastMilliseconds [

	^ (self lastMilliseconds ifNil: [ 0 ]) asString
]

{ #category : 'displaying' }
MCPToolCallStats >> displayLastOutputBytes [

	^ self lastOutputBytes asString
]

{ #category : 'displaying' }
MCPToolCallStats >> displayMaxMilliseconds [

	^ (self maxMilliseconds ifNil: [ 0 ]) asString
]

{ #category : 'displaying' }
MCPToolCallStats >> displayMaxOutputBytes [

	^ self maxOutputBytes asString
]

{ #category : 'displaying' }
MCPToolCallStats >> displayMinMilliseconds [

	^ (self minMilliseconds ifNil: [ 0 ]) asString
]

{ #category : 'displaying' }
MCPToolCallStats >> displayOutlierExplanation [

	^ self lastOutlierExplanation ifNil: [ '' ]
]

{ #category : 'displaying' }
MCPToolCallStats >> displayOutputBudgetExceededCount [

	^ self outputBudgetExceededCount asString
]

{ #category : 'accessing' }
MCPToolCallStats >> errorCount [

	^ errorCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
MCPToolCallStats >> errorCountsByClass [

	^ errorCountsByClass ifNil: [ errorCountsByClass := Dictionary new ]
]

{ #category : 'accessing' }
MCPToolCallStats >> errorRate [

	self callCount = 0 ifTrue: [ ^ 0 ].
	^ self errorCount / self callCount
]

{ #category : 'accessing' }
MCPToolCallStats >> firstCallAt [

	^ self timestampStringFor: firstStartedAt
]

{ #category : 'initialization' }
MCPToolCallStats >> initialize [

	super initialize.
	callCount := 0.
	successCount := 0.
	errorCount := 0.
	totalMilliseconds := 0.
	totalOutputBytes := 0.
	outputBudgetExceededCount := 0.
	errorCountsByClass := Dictionary new
]

{ #category : 'accessing' }
MCPToolCallStats >> lastApproximateOutputTokens [

	^ lastApproximateOutputTokens ifNil: [ 0 ]
]

{ #category : 'accessing' }
MCPToolCallStats >> lastCallAt [

	^ self timestampStringFor: lastFinishedAt
]

{ #category : 'accessing' }
MCPToolCallStats >> lastMilliseconds [

	^ lastMilliseconds
]

{ #category : 'accessing' }
MCPToolCallStats >> lastOutlierExplanation [

	^ lastOutlierExplanation
]

{ #category : 'accessing' }
MCPToolCallStats >> lastOutputBytes [

	^ lastOutputBytes ifNil: [ 0 ]
]

{ #category : 'accessing' }
MCPToolCallStats >> maxMilliseconds [

	^ maxMilliseconds
]

{ #category : 'accessing' }
MCPToolCallStats >> maxOutputBytes [

	^ maxOutputBytes ifNil: [ 0 ]
]

{ #category : 'accessing' }
MCPToolCallStats >> minMilliseconds [

	^ minMilliseconds
]

{ #category : 'accessing' }
MCPToolCallStats >> outputBudgetExceededCount [

	^ outputBudgetExceededCount ifNil: [ 0 ]
]

{ #category : 'displaying' }
MCPToolCallStats >> outputBudgetGuidance [

	self outputBudgetExceededCount = 0 ifTrue: [ ^ '' ].
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: self toolName;
				  nextPutAll: ' exceeded output budget ';
				  print: self outputBudgetExceededCount;
				  nextPutAll: ' time'.
			  self outputBudgetExceededCount = 1 ifFalse: [ stream nextPut: $s ].
			  stream
				  nextPutAll: ' (max ';
				  print: self maxOutputBytes;
				  nextPutAll:
					  ' bytes). Prefer pagination, handles, or summary-first output.' ]
]

{ #category : 'recording' }
MCPToolCallStats >> recordCall: aRecord [

	| duration outputBytes statusString |
	duration := aRecord durationMilliseconds.
	statusString := aRecord status.
	outputBytes := aRecord outputByteCount.
	callCount := self callCount + 1.
	statusString = 'ok'
		ifTrue: [ successCount := self successCount + 1 ]
		ifFalse: [ self recordErrorFor: aRecord ].
	totalMilliseconds := self totalMilliseconds + duration.
	minMilliseconds := self minMilliseconds ifNil: [ duration ] ifNotNil: [ :current | current min: duration ].
	maxMilliseconds := self maxMilliseconds ifNil: [ duration ] ifNotNil: [ :current | current max: duration ].
	totalOutputBytes := self totalOutputBytes + outputBytes.
	maxOutputBytes := self maxOutputBytes max: outputBytes.
	lastOutputBytes := outputBytes.
	lastApproximateOutputTokens := aRecord approximateOutputTokenCount.
	aRecord outputBudgetExceeded ifTrue: [ outputBudgetExceededCount := self outputBudgetExceededCount + 1 ].
	firstStartedAt ifNil: [ firstStartedAt := aRecord startedAt ].
	lastMilliseconds := duration.
	lastStartedAt := aRecord startedAt.
	lastFinishedAt := aRecord finishedAt.
	lastOutlierExplanation := aRecord outlierExplanation
]

{ #category : 'recording' }
MCPToolCallStats >> recordErrorFor: aRecord [

	errorCount := self errorCount + 1.
	aRecord errorClass ifNotEmpty: [ :className |
		self errorCountsByClass at: className put: (self errorCountsByClass at: className ifAbsent: [ 0 ]) + 1 ]
]

{ #category : 'accessing' }
MCPToolCallStats >> successCount [

	^ successCount ifNil: [ 0 ]
]

{ #category : 'private' }
MCPToolCallStats >> timestampStringFor: aTimestamp [

	^ aTimestamp
		  ifNil: [ '' ]
		  ifNotNil: [ :timestamp | timestamp asString ]
]

{ #category : 'accessing' }
MCPToolCallStats >> toolName [

	^ toolName
]

{ #category : 'accessing' }
MCPToolCallStats >> toolName: aString [

	toolName := aString
]

{ #category : 'accessing' }
MCPToolCallStats >> totalMilliseconds [

	^ totalMilliseconds ifNil: [ 0 ]
]

{ #category : 'accessing' }
MCPToolCallStats >> totalOutputBytes [

	^ totalOutputBytes ifNil: [ 0 ]
]
