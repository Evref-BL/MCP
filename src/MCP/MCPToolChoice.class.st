"
A user's choice of advertised tools, which moves tools across MCP's defaults: those it advertises, which servers show in tools/list though their default is to be discovered, and those it unadvertises, which servers leave to discovery though their default is to be listed. It changes the defaults only, so a server whose code chose its tools keeps them.

Read from tools.json in MCP's folder of the user's configuration (MCPUserSettings), as
{ ""advertise"": [ ""test_coverage_run"" ], ""unadvertise"": [ ""critique_run"" ] }
A name no tool has changes nothing, and a name in both lists keeps its default.
"
Class {
	#name : 'MCPToolChoice',
	#superclass : 'Object',
	#instVars : [
		'advertised',
		'unadvertised'
	],
	#category : 'MCP-Registries',
	#package : 'MCP',
	#tag : 'Registries'
}

{ #category : 'instance creation' }
MCPToolChoice class >> advertise: someNames unadvertise: otherNames [

	^ self new setAdvertised: someNames unadvertised: otherNames
]

{ #category : 'private' }
MCPToolChoice class >> namesIn: aValue [
	"The tool names a list gives, or the one a lone name is; anything else gives none."

	| values |
	values := aValue isString
		          ifTrue: [ { aValue } ]
		          ifFalse: [
				          (aValue isKindOf: SequenceableCollection)
					          ifTrue: [ aValue ]
					          ifFalse: [ #(  ) ] ].
	^ (values select: [ :each | each isString ] thenCollect: [ :each | each trimBoth ]) reject: [ :each | each isEmpty ]
]

{ #category : 'instance creation' }
MCPToolChoice class >> none [
	"The choice of a user who made none: every tool keeps its default."

	^ self advertise: #(  ) unadvertise: #(  )
]

{ #category : 'instance creation' }
MCPToolChoice class >> of: someUserSettings [
	"The choice the user's tools.json gives, or none when there is no such file or it gives no list of names: a user's file never stops a server."

	| json |
	json := [ STONJSON fromString: ((someUserSettings textOfFileNamed: 'tools.json') ifNil: [ ^ self none ]) ]
		        on: Error
		        do: [ :error | ^ self none ].
	json isDictionary ifFalse: [ ^ self none ].
	^ self
		  advertise: (self namesIn: (json at: 'advertise' ifAbsent: [ nil ]))
		  unadvertise: (self namesIn: (json at: 'unadvertise' ifAbsent: [ nil ]))
]

{ #category : 'testing' }
MCPToolChoice >> advertisesToolNamed: aName byDefault: aBoolean [
	"Whether a server that leaves advertising to the defaults lists this tool, whose default is aBoolean. A name in both lists keeps its default."

	| up down |
	up := advertised includes: aName asString.
	down := unadvertised includes: aName asString.
	up = down ifTrue: [ ^ aBoolean ].
	^ up
]

{ #category : 'initialization' }
MCPToolChoice >> setAdvertised: someNames unadvertised: otherNames [

	advertised := someNames collect: [ :each | each asString ] as: Set.
	unadvertised := otherNames collect: [ :each | each asString ] as: Set
]
