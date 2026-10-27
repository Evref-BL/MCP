"
Abstract MCP resource: a document a client can list and read by URI.

A resource is context a client pulls rather than an action it calls. Where a tool answers a question the model asked, a resource is material the host can put in front of the model on its own, so the two serve different halves of the protocol and a server is free to have either, both or neither.

Subclasses answer a stable `uri`, which is also their key in the registry, and build their contents in `readContents`. Only `uri` and `name` are required of a resource; `title`, `description` and `mimeType` are there for clients that display a picker.

A resource is served because its package is loaded, the way a tool is: a concrete subclass that can already answer its URI is in the catalog. One that must stay out answers false to `shouldAutoRegister`.
"
Class {
	#name : 'MCPResource',
	#superclass : 'Object',
	#category : 'MCP-Resources',
	#package : 'MCP',
	#tag : 'Resources'
}

{ #category : 'querying' }
MCPResource class >> concreteSubclasses [

	^ self allSubclasses reject: [ :each | each isAbstract ]
]

{ #category : 'testing' }
MCPResource class >> isAbstract [

	^ self = MCPResource
]

{ #category : 'instance creation' }
MCPResource class >> newForRegistry: aRegistry [

	^ self new
]

{ #category : 'metadata' }
MCPResource class >> resourceName [
	"The name clients file this resource under. Defaults to the URI, which every resource has."

	^ self resourceUri
]

{ #category : 'metadata' }
MCPResource class >> resourceUri [

	^ self subclassResponsibility
]

{ #category : 'testing' }
MCPResource class >> shouldAutoRegister [
	"A resource names itself with its URI, and naming itself is what gets it served, the way it is for tools. One that must stay out of every catalog answers false.

	Its own URI, not an inherited one: a subclass would otherwise claim the key its superclass already holds, and a class being compiled in a live image has its methods added after it exists."

	^ self class includesSelector: #resourceUri
]

{ #category : 'converting' }
MCPResource >> asJRPCJSON [
	"The descriptor resources/list answers. Optional fields are left out rather than sent as null."

	| dictionary |
	dictionary := Dictionary new
		              at: #uri put: self uri asJRPCJSON;
		              at: #name put: self name asJRPCJSON;
		              yourself.
	self title ifNotNil: [ :value | dictionary at: #title put: value asJRPCJSON ].
	self description ifNotNil: [ :value | dictionary at: #description put: value asJRPCJSON ].
	self mimeType ifNotNil: [ :value | dictionary at: #mimeType put: value asJRPCJSON ].
	^ dictionary
]

{ #category : 'metadata' }
MCPResource >> description [

	^ nil
]

{ #category : 'testing' }
MCPResource >> isResourceTemplate [
	"A template stands for a family of URIs rather than one document, so it lists through resources/templates/list instead."

	^ false
]

{ #category : 'metadata' }
MCPResource >> mimeType [

	^ nil
]

{ #category : 'metadata' }
MCPResource >> name [

	^ self class resourceName
]

{ #category : 'reading' }
MCPResource >> readContents [
	"Answer the contents resources/read answers, as an array of MCPStructureResourceContents."

	^ self subclassResponsibility
]

{ #category : 'reading' }
MCPResource >> textContents: aString [
	"The common case: one text document under this resource's own URI."

	^ { (MCPStructureResourceContents uri: self uri text: aString mimeType: self mimeType) }
]

{ #category : 'metadata' }
MCPResource >> title [

	^ nil
]

{ #category : 'metadata' }
MCPResource >> uri [

	^ self class resourceUri
]
