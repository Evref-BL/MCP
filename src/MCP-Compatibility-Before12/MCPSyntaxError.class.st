"
A syntax error, signalled as an Error. Before Pharo 12 the parser signals SyntaxErrorNotification, which is a Notification: the handlers MCP writes for the CodeError of later versions do not catch it, and its default action in a headless image is to quit. MCP signals me in its place, with the message and the position in the source it names.
"
Class {
	#name : 'MCPSyntaxError',
	#superclass : 'Error',
	#instVars : [
		'position'
	],
	#category : 'MCP-Compatibility-Before12',
	#package : 'MCP-Compatibility-Before12'
}

{ #category : 'instance creation' }
MCPSyntaxError class >> messageText: aString position: anInteger [

	^ self new
		  messageText: aString;
		  position: anInteger;
		  yourself
]

{ #category : 'accessing' }
MCPSyntaxError >> position [
	"The index in the source where the parser stopped."

	^ position
]

{ #category : 'accessing' }
MCPSyntaxError >> position: anInteger [

	position := anInteger
]
