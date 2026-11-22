Extension { #name : 'STONReaderError' }

{ #category : '*MCP' }
STONReaderError >> mcpJRPCResponseWithId: anId [
	"Text that is not JSON is a parse error."

	^ JRPCErrorResponseObject id: anId error: JRPCErrorObject parseError
]
