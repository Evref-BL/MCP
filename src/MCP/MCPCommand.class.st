"
Abstract base for command objects that perform one image-side action through #execute.

Subclasses keep the command-specific state and implement #execute.
"
Class {
	#name : 'MCPCommand',
	#superclass : 'Object',
	#category : 'MCP-Commands',
	#package : 'MCP',
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
