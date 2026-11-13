Extension { #name : 'MCPRunTestsCommand' }

{ #category : '*MCP-IDE-Compatibility-Before12' }
MCPRunTestsCommand >> coverageCollectorClass [
	"Pharo 11 has CoverageCollector. Pharo 10 has no collector, so it cannot report coverage."

	^ self class environment at: #CoverageCollector ifAbsent: [
		  MCPCommandError
			  signalErrorCode: #CoverageUnavailable
			  message: 'Collecting coverage needs CoverageCollector, which this Pharo version does not have.'
			  details: Dictionary new ]
]
