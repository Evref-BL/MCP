"
Fixture class whose doesNotUnderstand: passes the message on to super, as nil's own does in Pharo 10 and 11, so a message it does not understand leaves two doesNotUnderstand: frames on the stack. The test of MCPNotUnderstoodNote class>>senderOf: sends it one.
"
Class {
	#name : 'MCPNotUnderstoodNotePassingOnTarget',
	#superclass : 'Object',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'error handling' }
MCPNotUnderstoodNotePassingOnTarget >> doesNotUnderstand: aMessage [
	"Passes the message on, as UndefinedObject>>doesNotUnderstand: does in Pharo 10 and 11 when no undeclared variable is named by it."

	^ super doesNotUnderstand: aMessage
]
