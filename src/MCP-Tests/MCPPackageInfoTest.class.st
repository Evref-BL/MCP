"
Tests package metadata snapshots returned by MCPPackageInfo.
"
Class {
	#name : 'MCPPackageInfoTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'tests' }
MCPPackageInfoTest >> testBuildsPackageMetadataSnapshot [

	| info package |
	package := self packageOrganizer packageNamed: #MCP.
	info := MCPPackageInfo fromPackage: package projectNames: #( 'ZProject' 'AProject' ).
	self assert: info packageName equals: 'MCP'.
	self assert: info projectNames equals: #( 'AProject' 'ZProject' ).
	self assert: info tagNames equals: (package tagNames collect: #asString as: Array) sort
]
