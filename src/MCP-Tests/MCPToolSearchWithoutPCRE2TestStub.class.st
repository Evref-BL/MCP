"
Test tool that models an image where the optional PCRE2 package or native library is unavailable.
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
