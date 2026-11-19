"
An evaluate command that waits briefly rather than the command's bound for stopped code to unwind, so that a test whose stopped code unwinds slowly gets its answer that much sooner.
"
Class {
	#name : 'MCPEvaluateCommandUnwindingBriefly',
	#superclass : 'MCPEvaluateCommandWaitingForTheCode',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'private' }
MCPEvaluateCommandUnwindingBriefly >> unwindingSeconds [

	^ 0.1
]
