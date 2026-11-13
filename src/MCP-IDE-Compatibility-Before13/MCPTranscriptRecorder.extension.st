Extension { #name : 'MCPTranscriptRecorder' }

{ #category : '*MCP-IDE-Compatibility-Before13' }
MCPTranscriptRecorder >> stepGlobal [
	"Before Pharo 13, the world loop steps the Transcript, which I am while an evaluation runs."

	replaced stepGlobal
]
