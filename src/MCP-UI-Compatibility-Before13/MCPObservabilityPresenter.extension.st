Extension { #name : 'MCPObservabilityPresenter' }

{ #category : '*MCP-UI-Compatibility-Before13' }
MCPObservabilityPresenter >> initialExtent [
	"Before Pharo 13, Spec sizes a window from its presenter's initialExtent; later versions read defaultPreferredExtent and remember a resize."

	^ self class defaultPreferredExtent
]
