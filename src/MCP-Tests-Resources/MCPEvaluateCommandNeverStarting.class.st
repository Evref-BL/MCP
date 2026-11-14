"
An evaluate command that keeps its evaluator without starting it, as if other processes had kept the processor until the time limit, whatever the scheduler does with processes of one priority.
"
Class {
	#name : 'MCPEvaluateCommandNeverStarting',
	#superclass : 'MCPEvaluateCommand',
	#instVars : [
		'evaluator'
	],
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'accessing' }
MCPEvaluateCommandNeverStarting >> evaluator [

	^ evaluator
]

{ #category : 'private' }
MCPEvaluateCommandNeverStarting >> start: aProcess [

	evaluator := aProcess
]
