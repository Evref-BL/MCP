"
I am raised when prompts/get names a prompt the server does not have.

The spec answers an invalid prompt name as invalid params rather than giving it a code of its own.
"
Class {
	#name : 'MCPUnknownPrompt',
	#superclass : 'JRPCInvalidParameters',
	#instVars : [
		'promptName'
	],
	#category : 'MCP-Errors',
	#package : 'MCP',
	#tag : 'Errors'
}

{ #category : 'instance creation' }
MCPUnknownPrompt class >> signalNamed: aName known: knownNames [

	^ self new
		  promptName: aName;
		  signal: (String streamContents: [ :stream |
					   stream << 'Unknown MCP prompt: ' << aName asString << '. Known prompts: ' << knownNames asArray printString ])
]

{ #category : 'converting' }
MCPUnknownPrompt >> asJRPCResponseWithId: anInteger [

	| response |
	response := super asJRPCResponseWithId: anInteger.
	response error data: { (#prompt -> self promptName asString) } asDictionary.
	^ response
]

{ #category : 'accessing' }
MCPUnknownPrompt >> promptName [

	^ promptName
]

{ #category : 'accessing' }
MCPUnknownPrompt >> promptName: anObject [

	promptName := anObject
]
