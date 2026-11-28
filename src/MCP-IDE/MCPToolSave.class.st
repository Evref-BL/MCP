"
Saves the image in place and keeps it running, so that it starts again as it is now. Quitting, and saving under another name, are for whatever manages the image's process and files.
"
Class {
	#name : 'MCPToolSave',
	#superclass : 'MCPTool',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolSave class >> groupName [

	^ self runtimeGroupName
]

{ #category : 'metadata' }
MCPToolSave class >> toolName [

	^ 'save'
]

{ #category : 'metadata' }
MCPToolSave >> additionalKeywords [

	^ #( 'image' 'snapshot' 'session' 'keep' 'persist' )
]

{ #category : 'metadata' }
MCPToolSave >> buildInputSchema [

	^ MCPStructureInputSchema properties: #(  ) required: #(  )
]

{ #category : 'metadata' }
MCPToolSave >> changesCode [
	"A save waits for a code change in progress, as code changes wait for each other: the file would otherwise hold one half made, which an image started from it would finish with nobody to answer."

	^ true
]

{ #category : 'metadata' }
MCPToolSave >> description [

	^ 'Save the image in place and keep it running, so that it starts again as it is now. Answers how long the save took.'
]

{ #category : 'executing' }
MCPToolSave >> executeWithRequest: request [

	^ self executeRequest: request do: [
			  | milliseconds |
			  milliseconds := Time millisecondsToRun: [ self saveImage ].
			  self
				  successResultText: ('Saved the image in {1} ms.' format: { milliseconds })
				  data: { (#milliseconds -> milliseconds) } asDictionary ]
]

{ #category : 'metadata' }
MCPToolSave >> keysStatedInSummary [

	^ #( #milliseconds )
]

{ #category : 'private - saving' }
MCPToolSave >> saveImage [
	"Pharo signals a save that failed as unhandled, and only once the signal returns restarts, in this process, what the save stopped, MCP's listener among them. The call proceeds past it, as a debugger's Proceed would, although the error it wraps is not resumable, and then fails with that error."

	| failure |
	[ self snapshot ]
		on: UnhandledError
		do: [ :unhandled |
				failure := unhandled exception.
				unhandled resumeUnchecked: nil ].
	failure ifNotNil: [
			MCPCommandError
				signalErrorCode: #ImageNotSaved
				message: ('The image did not save: {1}. It still runs, with its changes unsaved.' format: { failure messageText })
				details: Dictionary new ]
]

{ #category : 'private - saving' }
MCPToolSave >> snapshot [
	"Save the image where it is, without quitting."

	^ Smalltalk saveSession
]

{ #category : 'metadata' }
MCPToolSave >> title [

	^ 'Save Image'
]
