"
Parsed create-repository request derived from one MCPToolRequest.

It describes the repository to register in the image and the initial package names to attach to its working copy.
"
Class {
	#name : 'MCPRepositoryCreateRequest',
	#superclass : 'Object',
	#instVars : [
		'name',
		'location',
		'subdirectory',
		'packageNames'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPRepositoryCreateRequest class >> fromRequest: request tool: aTool [

	^ self new initializeFromRequest: request
]

{ #category : 'initialization' }
MCPRepositoryCreateRequest >> initializeFromRequest: request [

	name := request stringArgumentNamed: 'name'.
	location := request stringArgumentNamed: 'location'.
	subdirectory := request stringArgumentNamed: 'subdirectory'.
	packageNames := request stringCollectionArgumentNamed: 'packageNames'.
	^ self
]

{ #category : 'accessing' }
MCPRepositoryCreateRequest >> location [

	^ location
]

{ #category : 'accessing' }
MCPRepositoryCreateRequest >> name [

	^ name
]

{ #category : 'accessing' }
MCPRepositoryCreateRequest >> operation [

	^ 'create'
]

{ #category : 'accessing' }
MCPRepositoryCreateRequest >> packageNames [

	^ packageNames ifNil: [ #(  ) ]
]

{ #category : 'converting' }
MCPRepositoryCreateRequest >> requestedContext [

	^ {
		  (#name -> self name).
		  (#location -> self location).
		  (#subdirectory -> (self subdirectory ifNil: [ '' ])).
		  (#packageNames -> self packageNames) } asDictionary
]

{ #category : 'accessing' }
MCPRepositoryCreateRequest >> subdirectory [

	^ subdirectory
]
