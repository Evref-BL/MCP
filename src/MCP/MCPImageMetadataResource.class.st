"
The facts about the image this server runs in, as a JSON document.

An agent that knows which Pharo it is talking to writes different code for it, and asking through image_evaluate costs a tool call and a round trip. As a resource the host can pull it once and keep it in front of the model.

It answers the image's basename rather than its full path: the name identifies which image is answering, and the path would add the home directory for nothing.
"
Class {
	#name : 'MCPImageMetadataResource',
	#superclass : 'MCPResource',
	#category : 'MCP-Resources',
	#package : 'MCP',
	#tag : 'Resources'
}

{ #category : 'metadata' }
MCPImageMetadataResource class >> resourceName [

	^ 'image-metadata'
]

{ #category : 'metadata' }
MCPImageMetadataResource class >> resourceUri [

	^ 'pharo://image/metadata'
]

{ #category : 'metadata' }
MCPImageMetadataResource >> description [

	^ 'Pharo version, virtual machine and image name of the running image.'
]

{ #category : 'reading' }
MCPImageMetadataResource >> imageBasename [

	^ [ Smalltalk image imageFile basename ] on: Error do: [ :error | error return: 'unknown' ]
]

{ #category : 'metadata' }
MCPImageMetadataResource >> mimeType [

	^ 'application/json'
]

{ #category : 'reading' }
MCPImageMetadataResource >> readContents [

	^ self textContents: (STONJSON toStringPretty: {
				   (#runtimeVersion -> SystemVersion current version).
				   (#majorVersion -> SystemVersion current major).
				   (#minorVersion -> SystemVersion current minor).
				   (#virtualMachine -> self virtualMachineVersion).
				   (#imageName -> self imageBasename) } asDictionary)
]

{ #category : 'metadata' }
MCPImageMetadataResource >> title [

	^ 'Pharo Image Metadata'
]

{ #category : 'reading' }
MCPImageMetadataResource >> virtualMachineVersion [
	"Some virtual machines answer the version only through an optional primitive and raise a Warning instead."

	^ [ Smalltalk vm version ] on: Error , Warning do: [ :error | error return: 'unavailable' ]
]
