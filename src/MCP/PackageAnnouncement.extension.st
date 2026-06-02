Extension { #name : 'PackageAnnouncement' }

{ #category : '*MCP' }
PackageAnnouncement >> mcpAffectedPackages [

	^ self package
		  ifNil: [ #(  ) ]
		  ifNotNil: [ :packageObject | { packageObject } ]
]
