"
DTO for compiled method metadata.

It reads, from the method it keeps, its selector, declaring class, class-side flag, protocol, package, extension status, the trait it was installed from when there is one, and its source text, each when asked.
"
Class {
	#name : 'MCPCompiledMethodInfo',
	#superclass : 'Object',
	#instVars : [
		'method'
	],
	#category : 'MCP-IDE-DTOs',
	#package : 'MCP-IDE',
	#tag : 'DTOs'
}

{ #category : 'instance creation' }
MCPCompiledMethodInfo class >> fromMethod: aCompiledMethod [

	^ self new initializeFromMethod: aCompiledMethod
]

{ #category : 'converting' }
MCPCompiledMethodInfo >> asDictionary [

	| data |
	data := {
		        (#selector -> self selector).
		        (#class -> self className).
		        (#package -> self packageName).
		        (#protocol -> self protocol) } asDictionary.
	self classSide ifTrue: [ data at: #side put: 'class' ].
	self traitName ifNotNil: [ :aTraitName | data at: #trait put: aTraitName ].
	self isExtension ifTrue: [ data at: #isExtension put: true ].
	^ data
]

{ #category : 'introspection' }
MCPCompiledMethodInfo >> className [

	^ method methodClass instanceSide name asString
]

{ #category : 'private' }
MCPCompiledMethodInfo >> classPackageName [

	^ method methodClass instanceSide package name asString
]

{ #category : 'accessing' }
MCPCompiledMethodInfo >> classSide [

	^ method methodClass isMeta
]

{ #category : 'initialization' }
MCPCompiledMethodInfo >> initializeFromMethod: aCompiledMethod [

	method := aCompiledMethod
]

{ #category : 'accessing' }
MCPCompiledMethodInfo >> isExtension [

	^ self packageName ~= self classPackageName
]

{ #category : 'accessing' }
MCPCompiledMethodInfo >> packageName [

	^ method package ifNil: [ self classPackageName ] ifNotNil: [ :aPackage | aPackage name asString ]
]

{ #category : 'accessing' }
MCPCompiledMethodInfo >> protocol [

	^ method protocolName ifNil: [ '' ] ifNotNil: [ :aProtocol | aProtocol asString ]
]

{ #category : 'accessing' }
MCPCompiledMethodInfo >> selector [

	^ method selector asString
]

{ #category : 'accessing' }
MCPCompiledMethodInfo >> source [
	"Read from the method's source when asked, since only a search of source text needs it."

	^ method sourceCode ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPCompiledMethodInfo >> traitName [
	"The trait that defines this method, when the class only carries a copy installed from one."

	^ method isFromTrait ifTrue: [ method origin instanceSide name asString ]
]
