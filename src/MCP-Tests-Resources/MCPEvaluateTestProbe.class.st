"
What code a test evaluates reaches while its evaluation is stopped: whether an ensure block ran, an ensure block that holds its process until the test releases it, to stand for one that takes long, and a critical section the test can hold. Code may also compute until the test releases it.
"
Class {
	#name : 'MCPEvaluateTestProbe',
	#superclass : 'Object',
	#classInstVars : [
		'ensureRan',
		'holder',
		'semaphore',
		'mutex',
		'released'
	],
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'probing' }
MCPEvaluateTestProbe class >> computeUntilReleased [
	"Compute, never waiting, until the test releases the probe, recording the process that computes."

	holder := Processor activeProcess.
	[ released ] whileFalse
]

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
	"The process that waits or computes until the test releases the probe."

	^ holder
]

{ #category : 'accessing' }
MCPEvaluateTestProbe class >> mutex [
	"A critical section the test holds while the evaluated code waits to enter it."

	^ mutex
]

{ #category : 'probing' }
MCPEvaluateTestProbe class >> noteEnsureRan [

	ensureRan := true
]

{ #category : 'probing' }
MCPEvaluateTestProbe class >> release [

	released := true.
	semaphore signal
]

{ #category : 'initialization' }
MCPEvaluateTestProbe class >> reset [

	ensureRan := false.
	released := false.
	semaphore := Semaphore new.
	mutex := Semaphore forMutualExclusion.
	holder := nil
]
