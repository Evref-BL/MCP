"
Parsed attach-repository request derived from one MCPToolRequest.

It describes an existing Git checkout to register in the image and the initial package names to attach to its working copy.
"
Class {
	#name : 'MCPRepositoryAttachRequest',
	#superclass : 'MCPRepositoryCreateRequest',
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'accessing' }
MCPRepositoryAttachRequest >> operation [

	^ 'attach'
]
