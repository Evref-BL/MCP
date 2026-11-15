"
An evaluate command that waits 1 s rather than 5 for stopped code to unwind, so that a test whose stopped code unwinds slowly gets its answer 4 s sooner.
"
Class {
	#name : 'MCPEvaluateCommandUnwindingBriefly',
	#superclass : 'MCPEvaluateCommand',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'private' }
MCPEvaluateCommandUnwindingBriefly >> unwindingSeconds [

	^ 0.3
]
