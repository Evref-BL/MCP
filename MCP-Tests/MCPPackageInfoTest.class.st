Class {
	#name : 'MCPPackageInfoTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Tests',
	#package : 'MCP-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
MCPPackageInfoTest >> testBuildsPackageMetadataSnapshot [

	| info package |
	package := PackageOrganizer default packageNamed: #MCP.
	info := MCPPackageInfo
		        fromPackage: package
		        projectNames: #( 'ZProject' 'AProject' ).
	self assert: info packageName equals: 'MCP'.
	self assert: info projectNames equals: #( 'AProject' 'ZProject' ).
	self
		assert: info tagNames
		equals:
		(package tagNames collect: #asString) asSortedCollection asArray.
	self
		assert: info definedClassCount
		equals: package definedClasses size.
	self
		assert: info extensionMethodCount
		equals: package extensionMethods size.
	self assert: info isUndefined equals: package isUndefined
]
