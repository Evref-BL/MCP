"
A watch debug point that debug_watch installs from Pharo 12 on, whose hit never fails. Its probe sits in a method any process may run, a server's worker among them, where a failure reaches no handler and quits a headless image. So a hit runs its behaviors and keeps its value without announcing itself, and drops what fails. The hit announcement asks the source node of the frame it fires in, which Pharo does not always find: a process still in the method when the probe is removed runs into it afterwards.
"
Class {
	#name : 'MCPWatchDebugPoint',
	#superclass : 'WatchDebugPoint',
	#category : 'MCP-IDE-Compatibility-From12',
	#package : 'MCP-IDE-Compatibility-From12'
}

{ #category : 'evaluating' }
MCPWatchDebugPoint >> hitWithContext: aContext value: aValue [
	"As a watch debug point, without the announcements, and dropping what fails."

	<debuggerCompleteToSender>
	[
		self enabled ifFalse: [ ^ self ].
		self saveContext: aContext.
		(self checkBehaviors allSatisfy: [ :behavior | behavior execute ]) ifFalse: [ ^ self ].
		self sideEffectBehaviors do: [ :behavior | behavior execute ].
		self addValue: aValue ]
		on: Error
		do: [ :error | error return: nil ]
]
