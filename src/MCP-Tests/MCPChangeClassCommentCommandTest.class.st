Class {
	#name : 'MCPChangeClassCommentCommandTest',
	#superclass : 'MCPCommandTestCase',
	#category : 'MCP-Tests-Internal',
	#package : 'MCP-Tests',
	#tag : 'Internal'
}

{ #category : 'private' }
MCPChangeClassCommentCommandTest >> commentTargetClassName [

	^ 'MCPChangeClassCommentCommandTestTarget'
]

{ #category : 'private' }
MCPChangeClassCommentCommandTest >> ensureTargetClass [

	self removeTargetClass.
	self
		createClassNamed: self commentTargetClassName
		superclassName: 'Object'
		slots: #(  )
		classSlots: #(  ).
	self withoutEpiceaDuring: [
		(self classNamed: self commentTargetClassName) comment:
			'original comment' ]
]

{ #category : 'private' }
MCPChangeClassCommentCommandTest >> removeTargetClass [

	self removeClassNamed: self commentTargetClassName
]

{ #category : 'running' }
MCPChangeClassCommentCommandTest >> setUp [

	super setUp.
	self ensureTargetClass
]

{ #category : 'running' }
MCPChangeClassCommentCommandTest >> tearDown [

	self removeTargetClass.
	super tearDown
]

{ #category : 'tests' }
MCPChangeClassCommentCommandTest >> testCanClearClassComment [

	| result target |
	result := self executeCommand: (MCPChangeClassCommentCommand
			           className: self commentTargetClassName
			           classComment: '').
	target := self classNamed: self commentTargetClassName.
	self assert: target comment equals: ''.
	self assert: result oldClassComment equals: 'original comment'.
	self assert: result newClassComment equals: ''
]

{ #category : 'tests' }
MCPChangeClassCommentCommandTest >> testMissingClassSignalsCommandError [

	| error |
	error := self captureCommandError: [
		         (MCPChangeClassCommentCommand
			          className: 'MCPChangeClassCommentCommandTestMissing'
			          classComment: 'ignored') execute ].
	self assert: error errorCode equals: #ClassNotFound.
	self
		assert: (error structuredDetails at: #className)
		equals: 'MCPChangeClassCommentCommandTestMissing'
]

{ #category : 'tests' }
MCPChangeClassCommentCommandTest >> testUpdatesClassCommentAndReturnsResultObject [

	| result target |
	result := self executeCommand: (MCPChangeClassCommentCommand
			           className: self commentTargetClassName
			           classComment: 'updated comment').
	target := self classNamed: self commentTargetClassName.
	self assert: target comment equals: 'updated comment'.
	self assert: result oldClassComment equals: 'original comment'.
	self assert: result newClassComment equals: 'updated comment'.
	self
		assert: result classInfo className
		equals: self commentTargetClassName
]
