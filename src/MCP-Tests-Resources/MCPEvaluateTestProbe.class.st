"
What code a test evaluates reaches while its evaluation is stopped: whether an ensure block ran, and an ensure block that holds its process until the test releases it, to stand for one that takes long.
"
Class {
	#name : 'MCPEvaluateTestProbe',
	#superclass : 'Object',
	#classInstVars : [
		'ensureRan',
		'holder',
		'semaphore'
	],
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'accessing' }
MCPEvaluateTestProbe class >> ensureRan [

	^ ensureRan == true
]

{ #category : 'probing' }
MCPEvaluateTestProbe class >> holdUntilReleased [
	"Wait until the test releases the probe, recording the process that waits, which is the one running the ensure block."

	holder := Processor activeProcess.
	semaphore wait
]

{ #category : 'accessing' }
MCPEvaluateTestProbe class >> holder [

	^ holder
]

{ #category : 'probing' }
MCPEvaluateTestProbe class >> noteEnsureRan [

	ensureRan := true
]

{ #category : 'probing' }
MCPEvaluateTestProbe class >> release [

	semaphore signal
]

{ #category : 'initialization' }
MCPEvaluateTestProbe class >> reset [

	ensureRan := false.
	semaphore := Semaphore new.
	holder := nil
]
