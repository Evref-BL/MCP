"
Tests that a tool naming several targets in one call runs every one of them.
"
Class {
	#name : 'MCPToolBatchTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'tests' }
MCPToolBatchTest >> testBatchFailsOnlyWhenEveryTargetFails [

	| result |
	result := self callToolWith: {
			          (#class -> 'MCPToolBatchTestTarget').
			          (#selector -> #( 'absentOne' 'absentTwo' )) } asDictionary.
	self assert: (result at: #isError).
	self assert: (self summaryFrom: result) equals: 'Got 0 of 2 methods. 2 failed.'.
	self assert: (((self structuredContentFrom: result) at: #data) at: #results) size equals: 2
]

{ #category : 'tests' }
MCPToolBatchTest >> testBatchKeepsGoingPastAFailingTarget [

	| entries result |
	result := self callToolWith: {
			          (#class -> 'MCPToolBatchTestTarget').
			          (#selector -> #( 'absentSelector' 'readFirst' )) } asDictionary.
	entries := (self dataFrom: result) at: #results.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (self summaryFrom: result) equals: 'Got 1 of 2 methods. 1 failed.'.
	self assert: ((entries first at: #error) at: #selector) equals: 'absentSelector'.
	self assert: ((entries second at: #source) includesSubstring: 'readFirst')
]

{ #category : 'tests' }
MCPToolBatchTest >> testBatchReadsAsOneBlockPerTarget [

	| contentText result |
	result := self callToolWith: {
			          (#class -> 'MCPToolBatchTestTarget').
			          (#selector -> #( 'readFirst' 'readSecond' )) } asDictionary.
	contentText := (result at: #content) first at: #text.
	self assert: (contentText beginsWith: 'Got 2 of 2 methods.').
	self assert: (contentText includesSubstring: 'Got method MCPToolBatchTestTarget>>readFirst').
	self assert: (contentText includesSubstring: 'Got method MCPToolBatchTestTarget>>readSecond').
	self assert: (contentText allRangesOfSubstring: 'protocol: reading') size equals: 2
]

{ #category : 'tests' }
MCPToolBatchTest >> testBatchReturnsOneEntryPerTargetInRequestOrder [

	| entries result |
	result := self callToolWith: {
			          (#class -> 'MCPToolBatchTestTarget').
			          (#selector -> #( 'readSecond' 'readFirst' )) } asDictionary.
	entries := (self dataFrom: result) at: #results.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (self summaryFrom: result) equals: 'Got 2 of 2 methods.'.
	self assert: entries size equals: 2.
	self assert: ((entries first at: #summary) includesSubstring: 'readSecond').
	self assert: ((entries second at: #summary) includesSubstring: 'readFirst')
]

{ #category : 'tests' }
MCPToolBatchTest >> testClassGetNamesSeveralClasses [

	| entries result |
	result := self
		          callToolNamed: 'class_get'
		          withArguments: { (#name -> #( 'MCPToolBatchTestTarget' 'MCPTool' )) } asDictionary.
	entries := (self dataFrom: result) at: #results.
	self assert: (self summaryFrom: result) equals: 'Got 2 of 2 classes.'.
	self assert: (entries first at: #class) equals: 'MCPToolBatchTestTarget'.
	self assert: (entries second at: #class) equals: 'MCPTool'
]

{ #category : 'tests' }
MCPToolBatchTest >> testMethodsAreReadAcrossClassesAndSides [

	| entries result |
	result := self callToolWith: { (#selector -> #( 'MCPToolBatchTestTarget>>readFirst' 'MCPTool class#toolName' 'MCPTool>>' )) } asDictionary.
	entries := (self dataFrom: result) at: #results.
	self assert: (self summaryFrom: result) equals: 'Got 2 of 3 methods. 1 failed.'.
	self assert: ((entries first at: #summary) includesSubstring: 'MCPToolBatchTestTarget>>readFirst').
	self assert: ((entries second at: #summary) includesSubstring: 'MCPTool class>>toolName').
	self assert: (((entries third at: #error) at: #errorCode)) equals: 'MethodReferenceUnreadable'
]

{ #category : 'tests' }
MCPToolBatchTest >> testOneTargetInAListReadsAsASingleCall [

	| data result |
	result := self callToolWith: {
		          (#class -> 'MCPToolBatchTestTarget').
		          (#selector -> #( 'readFirst' )) } asDictionary.
	data := self dataFrom: result.
	self deny: (data includesKey: #results).
	self assert: (self summaryFrom: result) equals: 'Got method MCPToolBatchTestTarget>>readFirst.'.
	self assert: ((data at: #source) includesSubstring: 'readFirst')
]

{ #category : 'accessing' }
MCPToolBatchTest >> toolName [

	^ 'method_get'
]
