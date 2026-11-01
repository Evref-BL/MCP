Extension { #name : 'MCPServersPresenter' }

{ #category : '*MCP-UI-Compatibility-Before13' }
MCPServersPresenter >> initialExtent [
	"Before Pharo 13, Spec sizes a window from its presenter's initialExtent; later versions read defaultPreferredExtent and remember a resize."

	^ self class defaultPreferredExtent
]
