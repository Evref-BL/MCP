"
I am raised when an MCP tool call argument payload does not match the tool input JSON Schema. I carry the schema violations so JSON-RPC clients can receive actionable invalid-params error data.
"
Class {
	#name : 'MCPInvalidToolInput',
	#superclass : 'JRPCInvalidParameters',
	#instVars : [
		'toolName',
		'violations'
	],
	#category : 'MCP-Errors',
	#package : 'MCP',
	#tag : 'Errors'
}

{ #category : 'instance creation' }
MCPInvalidToolInput class >> missingRequiredArgumentViolationNamed: anArgumentName [

	^ MCPJSONSchemaViolation
		  path: #(  )
		  keyword: #required
		  message: 'Object is missing a required property.'
		  expected: anArgumentName asString
		  actual: nil
]

{ #category : 'instance creation' }
MCPInvalidToolInput class >> signalForTool: aTool violations: aCollection [

	^ self new
		  toolName: aTool name;
		  violations: aCollection;
		  messageText: 'Tool input does not match the input schema.';
		  signal
]

{ #category : 'instance creation' }
MCPInvalidToolInput class >> signalMissingRequiredArgumentNamed: anArgumentName forTool: aTool [

	^ self
		  signalForTool: aTool
		  violations:
		  { (self missingRequiredArgumentViolationNamed: anArgumentName) }
]

{ #category : 'converting' }
MCPInvalidToolInput >> asJRPCErrorData [

	^ {
		  ('toolName' -> self toolName).
		  ('violations'
		   -> (self violations collect: [ :each | each asDictionary ])) }
		  asDictionary
]

{ #category : 'converting' }
MCPInvalidToolInput >> asJRPCResponseWithId: anInteger [

	| response |
	response := super asJRPCResponseWithId: anInteger.
	response error data: self asJRPCErrorData.
	^ response
]

{ #category : 'initialization' }
MCPInvalidToolInput >> initialize [

	super initialize.
	violations := #(  )
]

{ #category : 'accessing' }
MCPInvalidToolInput >> toolName [

	^ toolName
]

{ #category : 'accessing' }
MCPInvalidToolInput >> toolName: aString [

	toolName := aString
]

{ #category : 'accessing' }
MCPInvalidToolInput >> violations [

	^ violations
]

{ #category : 'accessing' }
MCPInvalidToolInput >> violations: aCollection [

	violations := aCollection
		              ifNil: [ #(  ) ]
		              ifNotNil: [ aCollection asArray ]
]
