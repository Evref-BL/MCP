Extension { #name : 'MCPDashboardPresenter' }

{ #category : '*MCP-UI-Compatibility-Before13' }
MCPDashboardPresenter >> initialExtent [
	"Before Pharo 13, Spec sizes a window from its presenter's initialExtent; later versions read defaultPreferredExtent and remember a resize."

	^ self class defaultPreferredExtent
]
