"
I am raised when an MCP tool call argument payload does not match the tool input JSON Schema. A tool call answers me as a tool result marked as an error, not as a JSON-RPC error: my text names each violation in words, so the model reading it can correct its call, and the violations travel beside it as structured data.
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
MCPInvalidToolInput class >> signalBlankArgumentNamed: anArgumentName forTool: aTool [
	"An argument sent with nothing in it but blanks. Its schema may accept it, but there is nothing to act on, and the argument is not missing either."

	^ self signalForTool: aTool violations: { (MCPJSONSchemaViolation
			   path: { anArgumentName asString }
			   keyword: #notBlank
			   message: 'Argument is blank.'
			   expected: nil
			   actual: nil) }
]

{ #category : 'instance creation' }
MCPInvalidToolInput class >> signalEmptyArgumentNamed: anArgumentName forTool: aTool [
	"A list of targets that names none once blank values are dropped. The caller may have sent items, so this says nothing about how many."

	^ self signalForTool: aTool violations: { (MCPJSONSchemaViolation
			   path: { anArgumentName asString }
			   keyword: #notEmpty
			   message: 'Argument names nothing to act on.'
			   expected: nil
			   actual: nil) }
]

{ #category : 'instance creation' }
MCPInvalidToolInput class >> signalForTool: aTool violations: aCollection [

	| error |
	error := self new
		         toolName: aTool name;
		         violations: aCollection;
		         yourself.
	^ error signal: error describeViolations
]

{ #category : 'instance creation' }
MCPInvalidToolInput class >> signalMissingRequiredArgumentNamed: anArgumentName forTool: aTool [

	^ self signalForTool: aTool violations: { (self missingRequiredArgumentViolationNamed: anArgumentName) }
]

{ #category : 'converting' }
MCPInvalidToolInput >> asJRPCErrorData [

	^ {
		  ('tool' -> self toolName).
		  ('violations' -> (self violations collect: [ :each | each asDictionary ])) } asDictionary
]

{ #category : 'converting' }
MCPInvalidToolInput >> asJRPCResponseWithId: anInteger [

	| response |
	response := super asJRPCResponseWithId: anInteger.
	response error data: self asJRPCErrorData.
	^ response
]

{ #category : 'printing' }
MCPInvalidToolInput >> describeViolations [
	"Every violation in words, since a client may give the model this text and drop the structured violations. Some refusals come after the schema has passed, so the text does not claim a schema mismatch."

	^ String streamContents: [ :stream |
			  stream << 'Invalid arguments for ' << self toolName << '.'.
			  self violations do: [ :each |
					  stream space.
					  each printSentenceOn: stream ] ]
]

{ #category : 'initialization' }
MCPInvalidToolInput >> initialize [

	super initialize.
	violations := #(  )
]

{ #category : 'dispatching' }
MCPInvalidToolInput >> mcpAddToolErrorDetailsTo: aDictionary [

	aDictionary at: #tool put: self toolName.
	self violations ifNotEmpty: [ aDictionary at: #violations put: (self violations collect: [ :each | each asDictionary ]) ]
]

{ #category : 'dispatching' }
MCPInvalidToolInput >> mcpCommandErrorDo: commandBlock otherwise: fallbackBlock [
	"The violations say all there is to say; the stack that found them would only bury them."

	^ commandBlock cull: self
]

{ #category : 'testing' }
MCPInvalidToolInput >> mcpIsProtocolError [
	"Arguments a tool's schema refuses are the caller's to correct, so they answer as a tool result, which a client passes to the model, and not as a protocol error, which it may keep to itself. The 2025-11-25 specification counts input validation among tool execution errors."

	^ false
]

{ #category : 'converting' }
MCPInvalidToolInput >> structuredDetails [

	| details |
	details := Dictionary new
		           at: #errorClass put: self class name;
		           yourself.
	self mcpAddToolErrorDetailsTo: details.
	^ details
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

	violations := aCollection ifNil: [ #(  ) ] ifNotNil: [ aCollection asArray ]
]
