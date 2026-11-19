"
An evaluate command whose stack and memory bounds a test sets, low enough for the code it evaluates to pass them without growing the image by much. It looks at the code every 10 ms rather than 100, so the code is stopped soon after it passes them.
"
Class {
	#name : 'MCPEvaluateCommandStoppingEarly',
	#superclass : 'MCPEvaluateCommand',
	#instVars : [
		'stackDepthLimit',
		'memoryGrowthLimit'
	],
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'private' }
MCPEvaluateCommandStoppingEarly >> memoryGrowthLimit [

	^ memoryGrowthLimit ifNil: [ super memoryGrowthLimit ]
]

{ #category : 'initialization' }
MCPEvaluateCommandStoppingEarly >> memoryGrowthLimit: anInteger [

	memoryGrowthLimit := anInteger
]

{ #category : 'private' }
MCPEvaluateCommandStoppingEarly >> stackDepthLimit [

	^ stackDepthLimit ifNil: [ super stackDepthLimit ]
]

{ #category : 'initialization' }
MCPEvaluateCommandStoppingEarly >> stackDepthLimit: anInteger [

	stackDepthLimit := anInteger
]

{ #category : 'private' }
MCPEvaluateCommandStoppingEarly >> watchMilliseconds [

	^ 10
]
