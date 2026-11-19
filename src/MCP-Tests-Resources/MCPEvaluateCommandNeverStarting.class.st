"
An evaluate command that keeps its evaluator without starting it, as if other processes had kept the processor until the time limit, whatever the scheduler does with processes of one priority. It looks every 10 ms rather than 100, so it answers soon after a short limit.
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

{ #category : 'private' }
MCPEvaluateCommandNeverStarting >> watchMilliseconds [

	^ 10
]
