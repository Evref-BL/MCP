"
Test tool that models an unavailable native PCRE2 library.
"
Class {
	#name : 'MCPToolSearchWithoutPCRE2TestStub',
	#superclass : 'MCPToolSearchMethodMetadata',
	#category : 'MCP-Tests-Support',
	#package : 'MCP-Tests',
	#tag : 'Support'
}

{ #category : 'testing' }
MCPToolSearchWithoutPCRE2TestStub class >> isAbstract [

	^ true
]

{ #category : 'testing' }
MCPToolSearchWithoutPCRE2TestStub >> pcre2RegexLibraryAvailable [

	^ false
]
