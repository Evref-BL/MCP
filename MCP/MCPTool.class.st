Class {
	#name : 'MCPTool',
	#superclass : 'Object',
	#instVars : [
		'name',
		'title',
		'description',
		'icons',
		'inputSchema',
		'handler',
		'outputSchema'
	],
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'accessing' }
MCPTool >> asJRPCJSON [

	| dic |
	dic := Dictionary new.
	self description ifNotNil: [
		dic at: #description put: self description asJRPCJSON ].
	self icons ifNotNil: [ dic at: #icons put: self icons asJRPCJSON ].
	self inputSchema ifNotNil: [
		dic at: #inputSchema put: self inputSchema asJRPCJSON ].
	self name ifNotNil: [ dic at: #name put: self name asJRPCJSON ].
	self title ifNotNil: [ dic at: #title put: self title asJRPCJSON ].
	^ dic
]

{ #category : 'accessing' }
MCPTool >> description [

	^ description
]

{ #category : 'accessing' }
MCPTool >> description: anObject [

	description := anObject
]

{ #category : 'executing' }
MCPTool >> executeWithArguments: anArgument [
	"You can also overide me to make things easier to manage"

	^ handler value: anArgument
]

{ #category : 'error handling' }
MCPTool >> failureMessageFor: anError [

	| message |
	message := anError messageText
		           ifNil: [ '' ]
		           ifNotNil: [ :text | text asString ].
	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Tool ';
			  nextPutAll: self name;
			  nextPutAll: ' failed (';
			  nextPutAll: anError class name;
			  nextPutAll: ')'.
		  message isEmpty ifFalse: [
			  stream
				  nextPutAll: ': ';
				  nextPutAll: message ] ]
]

{ #category : 'accessing' }
MCPTool >> handler [

	^ handler
]

{ #category : 'accessing' }
MCPTool >> handler: anObject [

	handler := anObject
]

{ #category : 'accessing' }
MCPTool >> icons [

	^ icons
]

{ #category : 'accessing' }
MCPTool >> icons: anObject [

	icons := anObject
]

{ #category : 'initialization' }
MCPTool >> initialize [

	super initialize.
	handler := [ :args |  ]
]

{ #category : 'accessing' }
MCPTool >> inputSchema [

	^ inputSchema
]

{ #category : 'accessing' }
MCPTool >> inputSchema: anObject [

	inputSchema := anObject
]

{ #category : 'accessing' }
MCPTool >> name [

	^ name
]

{ #category : 'accessing' }
MCPTool >> name: anObject [

	name := anObject
]

{ #category : 'accessing' }
MCPTool >> title [

	^ title
]

{ #category : 'accessing' }
MCPTool >> title: anObject [

	title := anObject
]
