Extension { #name : 'MCPTranscriptRecorder' }

{ #category : '*MCP-IDE-Compatibility-Before12' }
MCPTranscriptRecorder >> stepGlobal [
	"Before Pharo 12, the world loop steps the Transcript global, which I am while an evaluation runs."

	replaced stepGlobal
]
