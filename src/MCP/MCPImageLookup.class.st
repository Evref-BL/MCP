"
Resolves required image objects for MCP tools and commands.

Use this for strict lookups where a missing class or package should stop the operation and return the shared missing-name suggestion payload. Search scope objects keep their own permissive lookup path because they can return partial results.
"
Class {
	#name : 'MCPImageLookup',
	#superclass : 'Object',
	#category : 'MCP-Utilities',
	#package : 'MCP',
	#tag : 'Utilities'
}

{ #category : 'resolving' }
MCPImageLookup class >> classNamed: aClassName [

	^ self classNamed: aClassName scopeName: 'className'
]

{ #category : 'resolving' }
MCPImageLookup class >> classNamed: aClassName scopeName: scopeName [

	^ Smalltalk globals at: aClassName asSymbol ifAbsent: [
			  MCPCommandError
				  signalMissingClassNamed: aClassName
				  scopeName: scopeName ]
]

{ #category : 'resolving' }
MCPImageLookup class >> packageNamed: aPackageName [

	^ self packageNamed: aPackageName scopeName: 'packageName'
]

{ #category : 'resolving' }
MCPImageLookup class >> packageNamed: aPackageName scopeName: scopeName [

	^ PackageOrganizer default
		  packageNamed: aPackageName asSymbol
		  ifAbsent: [
				  MCPCommandError
					  signalMissingPackageNamed: aPackageName
					  scopeName: scopeName ]
]
