"
DTO for one completed test_run selection.

It records the selected test class or method, the number of executed tests, and structured issue dictionaries captured during the run.
"
Class {
	#name : 'MCPTestRunInfo',
	#superclass : 'MCPDataTransferObject',
	#instVars : [
		'className',
		'testMethodName',
		'selectedTestCount',
		'runCount',
		'passedCount',
		'skippedCount',
		'failureCount',
		'errorCount',
		'issues'
	],
	#category : 'MCP-DTOs',
	#package : 'MCP',
	#tag : 'DTOs'
}

{ #category : 'instance creation' }
MCPTestRunInfo class >> validatedRequest: validatedRequest selectedTestCount: selectedCount result: aResult issues: issueCollection [

	^ self new
		  initializeValidatedRequest: validatedRequest
		  selectedTestCount: selectedCount
		  result: aResult
		  issues: issueCollection
]

{ #category : 'converting' }
MCPTestRunInfo >> asDictionary [

	| data |
	data := Dictionary new.
	data at: #className put: self className.
	self testMethodName ifNotNil: [ :methodName |
		data at: #testMethodName put: methodName ].
	data at: #selectedTestCount put: self selectedTestCount.
	data at: #runCount put: self runCount.
	data at: #passedCount put: self passedCount.
	data at: #skippedCount put: self skippedCount.
	data at: #failureCount put: self failureCount.
	data at: #errorCount put: self errorCount.
	self issues ifNotEmpty: [ :issueDetails |
		data at: #issues put: issueDetails ].
	^ data
]

{ #category : 'accessing' }
MCPTestRunInfo >> className [

	^ className
]

{ #category : 'accessing' }
MCPTestRunInfo >> errorCount [

	^ errorCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
MCPTestRunInfo >> failureCount [

	^ failureCount ifNil: [ 0 ]
]

{ #category : 'initialization' }
MCPTestRunInfo >> initializeValidatedRequest: validatedRequest selectedTestCount: selectedCount result: aResult issues: issueCollection [

	className := validatedRequest className.
	testMethodName := validatedRequest testMethodName.
	selectedTestCount := selectedCount.
	runCount := aResult runCount.
	passedCount := aResult passedCount.
	skippedCount := aResult skippedCount.
	failureCount := aResult failureCount.
	errorCount := aResult errorCount.
	issues := issueCollection ifNil: [ #(  ) ].
	^ self
]

{ #category : 'accessing' }
MCPTestRunInfo >> issues [

	^ issues ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPTestRunInfo >> passedCount [

	^ passedCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
MCPTestRunInfo >> runCount [

	^ runCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
MCPTestRunInfo >> selectedTestCount [

	^ selectedTestCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
MCPTestRunInfo >> skippedCount [

	^ skippedCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
MCPTestRunInfo >> testMethodName [

	^ testMethodName
]
