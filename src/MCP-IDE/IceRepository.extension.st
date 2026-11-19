Extension { #name : 'IceRepository' }

{ #category : '*MCP-IDE' }
IceRepository >> mcpLocationString [
	"Where the repository is, as the repository tools name it: empty for one registered without a location."

	^ self location ifNil: [ '' ] ifNotNil: [ :aReference | aReference pathString ]
]
