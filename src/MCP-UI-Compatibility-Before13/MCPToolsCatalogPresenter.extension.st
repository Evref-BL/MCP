Extension { #name : 'MCPToolsCatalogPresenter' }

{ #category : '*MCP-UI-Compatibility-Before13' }
MCPToolsCatalogPresenter >> initialExtent [
	"Before Pharo 13, Spec sizes a window from its presenter's initialExtent; later versions read defaultPreferredExtent and remember a resize."

	^ self class defaultPreferredExtent
]
