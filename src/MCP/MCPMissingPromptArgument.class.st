"
I am raised when prompts/get omits an argument the prompt declares as required.

The spec answers a missing required argument as invalid params, the same as an unknown prompt name.
"
Class {
	#name : 'MCPMissingPromptArgument',
	#superclass : 'JRPCInvalidParameters',
	#instVars : [
		'promptName',
		'missingArguments'
	],
	#category : 'MCP-Errors',
	#package : 'MCP',
	#tag : 'Errors'
}

{ #category : 'instance creation' }
MCPMissingPromptArgument class >> signalForPrompt: aPrompt named: argumentNames [

	^ self new
		  promptName: aPrompt name;
		  missingArguments: argumentNames asArray;
		  signal: 'Prompt ' , aPrompt name , ' is missing required argument(s): ' , argumentNames asArray printString
]

{ #category : 'converting' }
MCPMissingPromptArgument >> asJRPCResponseWithId: anInteger [

	| response |
	response := super asJRPCResponseWithId: anInteger.
	response error data: {
			(#prompt -> self promptName asString).
			(#missingArguments -> self missingArguments) } asDictionary.
	^ response
]

{ #category : 'accessing' }
MCPMissingPromptArgument >> missingArguments [

	^ missingArguments
]

{ #category : 'accessing' }
MCPMissingPromptArgument >> missingArguments: anObject [

	missingArguments := anObject
]

{ #category : 'accessing' }
MCPMissingPromptArgument >> promptName [

	^ promptName
]

{ #category : 'accessing' }
MCPMissingPromptArgument >> promptName: anObject [

	promptName := anObject
]
