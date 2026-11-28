"
Tests the save tool through MCPSaveRecordingTestTool, which counts its saves instead of saving: a real save would write the image under test.
"
Class {
	#name : 'MCPToolSaveTest',
	#superclass : 'MCPToolAPITestCase',
	#instVars : [
		'mcp',
		'tool'
	],
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private - calling' }
MCPToolSaveTest >> callSave [

	^ mcp rpcToolCall: 'tool_call' withParams: {
			  (#name -> tool name).
			  (#arguments -> Dictionary new) } asDictionary
]

{ #category : 'running' }
MCPToolSaveTest >> setUp [

	super setUp.
	tool := MCPSaveRecordingTestTool new.
	mcp := self mcpWithoutObservabilityExport.
	mcp addTool: tool
]

{ #category : 'tests' }
MCPToolSaveTest >> testASaveAnswersHowLongItTook [
	"The caller knows which image it called, so how long the save took is all there is to say, and the text says it once."

	| milliseconds result |
	result := self callSave.
	self assert: tool saves equals: 1.
	milliseconds := (self dataFrom: result) at: #milliseconds.
	self assert: milliseconds isInteger.
	self assert: (self summaryFrom: result) equals: ('Saved the image in {1} ms.' format: { milliseconds }).
	self assert: (self textFrom: result) equals: (self summaryFrom: result)
]

{ #category : 'tests' }
MCPToolSaveTest >> testASaveThatFailsSaysWhy [
	"Pharo signals a failed save as unhandled, and restarts what the save stopped only once the signal returns: unwound there, the image would run on without MCP's listener. The answer gives the error it wraps, and that the image runs on without having saved."

	| result |
	tool failWith: (Error new messageText: 'Unknown Error while executing snapshot primitive').
	result := self callSave.
	self assert: tool restartedAfterFailing.
	self assert: (self resultIndicatesError: result).
	self assert: tool saves equals: 0.
	self
		assert: (self summaryFrom: result)
		equals: 'The image did not save: Unknown Error while executing snapshot primitive. It still runs, with its changes unsaved.'.
	self assert: ((self errorFrom: result) at: #errorCode) equals: 'ImageNotSaved'
]

{ #category : 'tests' }
MCPToolSaveTest >> testASaveWaitsForACodeChangeInProgress [
	"Saved in the middle of a code change, the file would hold it half made, and an image started from it would finish it with nobody to answer."

	| changing saved |
	changing := Semaphore new.
	saved := Semaphore new.
	[ MCP codeChanges critical: [ changing wait ] ] forkAt: Processor activePriority + 1.
	[
		self callSave.
		saved signal ] forkAt: Processor activePriority + 1.
	[ self assert: tool saves equals: 0 ] ensure: [ changing signal ].
	self deny: (saved waitTimeoutSeconds: 5).
	self assert: tool saves equals: 1
]

{ #category : 'tests' }
MCPToolSaveTest >> testSaveIsFoundBySearchingAndNotListed [
	"#451's agent searched the tools with these words and found nothing. Saving is occasional, so the tool list does not carry it, and it takes no arguments for a model to fill in."

	| registry save |
	registry := self toolRegistry.
	save := registry toolNamed: 'save' ifAbsent: [ self fail: 'Missing save tool' ].
	self assert: (registry toolsMatchingQuery: 'save image snapshot') first equals: save.
	self deny: (registry isToolAdvertisedNamed: 'save').
	self assertEmpty: (self inputPropertyNamesFor: save)
]

{ #category : 'tests' }
MCPToolSaveTest >> testSaveShowsTheSaveIcon [
	"save names no domain, so it shows its action's icon alone, as evaluate does."

	self assert: MCPToolSave toolIconSpec cacheKey equals: (MCPToolIconSpec named: #save) cacheKey
]
