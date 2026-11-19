"
Aggregated observability metrics for one MCP tool. It tracks call counts, success/error counts, timing totals, min/max/last duration, output-size totals and maxima, output-budget overruns, and the last outlier explanation.
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
		'lastFinishedAt',
		'lastOutlierExplanation',
		'totalOutputBytes',
		'maxOutputBytes',
		'lastOutputBytes',
		'lastApproximateOutputTokens',
		'outputBudgetExceededCount',
		'errorCountsByClass',
		'errorCountsByKind',
		'errorCountsByCode'
	],
	#category : 'MCP-Observability',
	#package : 'MCP',
	#tag : 'Observability'
}

{ #category : 'instance creation' }
MCPToolCallStats class >> forToolNamed: aToolName [

	^ self new
		  toolName: aToolName;
		  yourself
]

{ #category : 'converting' }
MCPToolCallStats >> asMetricsDictionary [

	| dictionary |
	dictionary := {
		              (#tool -> self toolName).
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
			dictionary at: #errorCountsByClass put: self errorCountsByClass copy.
			dictionary at: #errorCountsByKind put: self errorCountsByKind copy.
			dictionary at: #errorCountsByCode put: self errorCountsByCode copy ].
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

	^ callCount
]

{ #category : 'displaying' }
MCPToolCallStats >> displayAverageMilliseconds [

	^ self averageMilliseconds asFloat printShowingDecimalPlaces: 1
]

{ #category : 'displaying' }
MCPToolCallStats >> displayLastMilliseconds [

	^ (self lastMilliseconds ifNil: [ 0 ]) asString
]

{ #category : 'displaying' }
MCPToolCallStats >> displayMaxMilliseconds [

	^ (self maxMilliseconds ifNil: [ 0 ]) asString
]

{ #category : 'displaying' }
MCPToolCallStats >> displayMinMilliseconds [

	^ (self minMilliseconds ifNil: [ 0 ]) asString
]

{ #category : 'accessing' }
MCPToolCallStats >> errorCount [

	^ errorCount
]

{ #category : 'accessing' }
MCPToolCallStats >> errorCountsByClass [

	^ errorCountsByClass
]

{ #category : 'accessing' }
MCPToolCallStats >> errorCountsByCode [

	^ errorCountsByCode
]

{ #category : 'accessing' }
MCPToolCallStats >> errorCountsByKind [

	^ errorCountsByKind
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
	errorCountsByClass := Dictionary new.
	errorCountsByKind := Dictionary new.
	errorCountsByCode := Dictionary new
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

	^ outputBudgetExceededCount
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
	lastFinishedAt := aRecord finishedAt.
	lastOutlierExplanation := aRecord outlierExplanation
]

{ #category : 'recording' }
MCPToolCallStats >> recordErrorCountIn: aDictionary named: aString [

	aDictionary at: aString put: (aDictionary at: aString ifAbsent: [ 0 ]) + 1
]

{ #category : 'recording' }
MCPToolCallStats >> recordErrorFor: aRecord [

	errorCount := self errorCount + 1.
	aRecord errorClass ifNotEmpty: [ :className | self recordErrorCountIn: self errorCountsByClass named: className ].
	aRecord errorKind ifNotEmpty: [ :kind | self recordErrorCountIn: self errorCountsByKind named: kind ].
	aRecord errorCode ifNotEmpty: [ :code | self recordErrorCountIn: self errorCountsByCode named: code ]
]

{ #category : 'accessing' }
MCPToolCallStats >> successCount [

	^ successCount
]

{ #category : 'private' }
MCPToolCallStats >> timestampStringFor: aTimestamp [

	^ aTimestamp ifNil: [ '' ] ifNotNil: [ :timestamp | timestamp asString ]
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

	^ totalMilliseconds
]

{ #category : 'accessing' }
MCPToolCallStats >> totalOutputBytes [

	^ totalOutputBytes
]
