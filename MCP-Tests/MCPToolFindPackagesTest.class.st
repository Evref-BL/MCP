Class {
	#name : 'MCPToolFindPackagesTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Tests',
	#package : 'MCP-Tests',
	#tag : 'Tests'
}

{ #category : 'private' }
MCPToolFindPackagesTest >> callToolWith: someArguments [

	^ MCP new
		  rpcToolCall: 'find-packages'
		  withParams: someArguments
]

{ #category : 'private' }
MCPToolFindPackagesTest >> dataFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #data
]

{ #category : 'private' }
MCPToolFindPackagesTest >> entryNamed: aPackageName in: packageEntries [

	^ packageEntries
		  detect: [ :each | (each at: #packageName) = aPackageName ]
		  ifNone: [ self fail: 'Missing package entry ' , aPackageName ]
]

{ #category : 'private' }
MCPToolFindPackagesTest >> errorFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #error
]

{ #category : 'private' }
MCPToolFindPackagesTest >> mcpProject [

	^ ProjectManager new projects
		  detect: [ :each | each name asString = 'MCP' ]
		  ifNone: [ self fail: 'Missing MCP project fixture in image.' ]
]

{ #category : 'private' }
MCPToolFindPackagesTest >> mcpProjectPackageNames [

	^ (self mcpProject packages collect: [ :each | each name asString ])
		  asArray asSortedCollection asArray
]

{ #category : 'private' }
MCPToolFindPackagesTest >> structuredContentFrom: aResult [

	^ aResult at: #structuredContent
]

{ #category : 'tests' }
MCPToolFindPackagesTest >> testImageScopeCanPaginateFilteredPackages [

	| data packageNames result expected |
	result := self callToolWith: {
			          (#filter -> 'MCP-').
			          (#filterMode -> 'prefix').
			          (#limit -> 2).
			          (#offset -> 1) } asDictionary.
	data := self dataFrom: result.
	packageNames := (data at: #packages) collect: [ :each |
		                each at: #packageName ].
	expected := ((PackageOrganizer default packages select: [ :each |
		              each name asString beginsWith: 'MCP-' ])
		             collect: [ :each | each name asString ]
		             as: Array) asSortedCollection asArray.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #scope) equals: 'image'.
	self assert: (data at: #totalCount) equals: expected size.
	self
		assert: packageNames
		equals: (expected copyFrom: 2 to: 3) asArray
]

{ #category : 'tests' }
MCPToolFindPackagesTest >> testImageScopeFindsExactPackageNameMatch [

	| data packageNames result |
	result := self callToolWith: {
			          (#filter -> 'MCP-Tests').
			          (#filterMode -> 'exact') } asDictionary.
	data := self dataFrom: result.
	packageNames := (data at: #packages) collect: [ :each |
		                each at: #packageName ].

	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #scope) equals: 'image'.
	self assert: (data at: #totalCount) equals: 1.
	self assert: packageNames equals: #( 'MCP-Tests' )
]

{ #category : 'tests' }
MCPToolFindPackagesTest >> testImageScopeFindsStructuredPackages [

	| data entry result |
	result := self callToolWith: {
			          (#filter -> '^MCP\s').
			          (#filterMode -> 'regex') } asDictionary.
	data := self dataFrom: result.
	entry := self entryNamed: 'MCP' in: (data at: #packages).
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #scope) equals: 'image'.
	self assert: (data at: #totalCount) equals: 1.
	self assert: (entry at: #projectNames) equals: #( 'MCP' ).
	self assert: (entry at: #definedClassCount) > 0.
	self assert: ((entry at: #tagNames) includes: 'Tools')
]

{ #category : 'tests' }
MCPToolFindPackagesTest >> testProjectScopeCanFilterByTagNames [

	| data result |
	result := self callToolWith: {
			          (#scope -> 'project').
			          (#projectNames -> #( 'MCP' )).
			          (#filter -> 'Tools') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self entryNamed: 'MCP' in: (data at: #packages)
]

{ #category : 'tests' }
MCPToolFindPackagesTest >> testProjectScopeFindsPackagesForNamedProject [

	| data packageNames result |
	result := self callToolWith: {
			          (#scope -> 'project').
			          (#projectNames -> #( 'MCP' )) } asDictionary.
	data := self dataFrom: result.
	packageNames := (data at: #packages) collect: [ :each |
		                each at: #packageName ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #scope) equals: 'project'.
	self assert: (data at: #projectNames) equals: #( 'MCP' ).
	self assert: packageNames equals: self mcpProjectPackageNames
]

{ #category : 'tests' }
MCPToolFindPackagesTest >> testProjectScopeReturnsStructuredErrorWhenProjectIsMissing [

	| error result structured |
	result := self callToolWith: {
			          (#scope -> 'project').
			          (#projectNames -> #( 'DefinitelyMissingProject' )) }
			          asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'. self assert: (error at: #errorCode) equals: 'ProjectNotFound'.
	self
		assert: (error at: #projectName)
		equals: 'DefinitelyMissingProject'.
	self assert: (error at: #scope) equals: 'project'
]
