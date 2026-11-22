"
Abstract base for command objects that perform one image-side action through #execute.

Subclasses keep the command-specific state and implement #execute.
"
Class {
	#name : 'MCPCommand',
	#superclass : 'Object',
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'testing' }
MCPCommand class >> isAbstract [

	^ self == MCPCommand
]

{ #category : 'executing' }
MCPCommand >> execute [

	self subclassResponsibility
]

{ #category : 'private' }
MCPCommand >> removePackageIfEmptyNamed: aPackageName [
	"Whether the package named aPackageName was removed: only while it defines no class, and never the one Pharo keeps for classes in no package."

	aPackageName = '_UnpackagedPackage' ifTrue: [ ^ false ].
	self packageOrganizer packageNamed: aPackageName ifPresent: [ :package |
			package definedClasses ifEmpty: [
					self packageOrganizer removePackage: package.
					^ true ] ].
	^ false
]

{ #category : 'private' }
MCPCommand >> resumingEveryNotificationDuring: aBlock [
	"Runs aBlock, code a tool runs for its caller, a test or an expression, whose notifications are its own: each it leaves unhandled resumes with what the image would have done had no tool called it. The boundary around a call refuses a refactoring warning so that a change the tool makes stops there unless forced, and the caller's code is no change of the tool's."

	^ aBlock
		  on: Notification
		  do: [ :notification | notification mcpResume ]
]
