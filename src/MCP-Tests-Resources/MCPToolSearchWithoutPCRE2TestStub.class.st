"
Test tool that models an image with no PCRE2 engine loaded.

Up to pharo-pcre2 1.0.1 that meant the host was missing the native library; since 2.0 an engine written in Pharo is what a plain install gets, so what this stub models is the dependency being absent altogether, however it would have been provided.
"
Class {
	#name : 'MCPToolSearchWithoutPCRE2TestStub',
	#superclass : 'MCPToolSearchMethods',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'testing' }
MCPToolSearchWithoutPCRE2TestStub class >> isAbstract [

	^ true
]

{ #category : 'testing' }
MCPToolSearchWithoutPCRE2TestStub >> pcre2RegexLibraryAvailable [

	^ false
]
