"
Aggregated monitoring metrics for one MCP tool. It tracks call counts, success/error counts, timing totals, min/max/last duration, and the last outlier explanation.
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
		'lastStartedAt',
		'lastFinishedAt',
		'lastOutlierExplanation'
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
		  (#averageMilliseconds -> self averageMilliseconds asFloat).
		  (#minMilliseconds -> (self minMilliseconds ifNil: [ 0 ])).
		  (#maxMilliseconds -> (self maxMilliseconds ifNil: [ 0 ])).
		  (#lastMilliseconds -> (self lastMilliseconds ifNil: [ 0 ])).
		  (#lastOutlierExplanation
		   -> (self lastOutlierExplanation ifNil: [ '' ])) } asDictionary
]

{ #category : 'accessing' }
MCPToolCallStats >> averageMilliseconds [

	self callCount = 0 ifTrue: [ ^ 0 ].
	^ self totalMilliseconds / self callCount
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

{ #category : 'displaying' }
MCPToolCallStats >> displayOutlierExplanation [

	^ self lastOutlierExplanation ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPToolCallStats >> errorCount [

	^ errorCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
MCPToolCallStats >> errorRate [

	self callCount = 0 ifTrue: [ ^ 0 ].
	^ self errorCount / self callCount
]

{ #category : 'initialization' }
MCPToolCallStats >> initialize [

	super initialize.
	callCount := 0.
	successCount := 0.
	errorCount := 0.
	totalMilliseconds := 0
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
MCPToolCallStats >> maxMilliseconds [

	^ maxMilliseconds
]

{ #category : 'accessing' }
MCPToolCallStats >> minMilliseconds [

	^ minMilliseconds
]

{ #category : 'recording' }
MCPToolCallStats >> recordCall: aRecord [

	| duration statusString |
	duration := aRecord durationMilliseconds.
	statusString := aRecord status.
	callCount := self callCount + 1.
	statusString = 'ok'
		ifTrue: [ successCount := self successCount + 1 ]
		ifFalse: [ errorCount := self errorCount + 1 ].
	totalMilliseconds := self totalMilliseconds + duration.
	minMilliseconds := self minMilliseconds
		                   ifNil: [ duration ]
		                   ifNotNil: [ :current | current min: duration ].
	maxMilliseconds := self maxMilliseconds
		                   ifNil: [ duration ]
		                   ifNotNil: [ :current | current max: duration ].
	lastMilliseconds := duration.
	lastStartedAt := aRecord startedAt.
	lastFinishedAt := aRecord finishedAt.
	lastOutlierExplanation := aRecord outlierExplanation
]

{ #category : 'accessing' }
MCPToolCallStats >> successCount [

	^ successCount ifNil: [ 0 ]
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
