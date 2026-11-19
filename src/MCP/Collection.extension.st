Extension { #name : 'Collection' }

{ #category : '*MCP' }
Collection >> mcpAt: aKey ifAbsent: absentBlock [
	"The value at aKey, held under a String as in JSON read from the wire or under a Symbol as in dictionaries built in the image. On Collection, the closest superclass Dictionary and OrderedDictionary share."

	^ self at: aKey asString ifAbsent: [ self at: aKey asSymbol ifAbsent: absentBlock ]
]
