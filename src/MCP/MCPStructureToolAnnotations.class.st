"
MCP protocol structure for optional tool behavior hints. Tool annotations are advisory metadata; clients must not treat them as trusted authorization decisions.
"
Class {
	#name : 'MCPStructureToolAnnotations',
	#superclass : 'Object',
	#instVars : [
		'readOnlyHint',
		'destructiveHint',
		'idempotentHint',
		'openWorldHint',
		'title'
	],
	#category : 'MCP-Structure',
	#package : 'MCP',
	#tag : 'Structure'
}

{ #category : 'instance creation' }
MCPStructureToolAnnotations class >> mayModify [

	^ self new
		  readOnlyHint: false;
		  yourself
]

{ #category : 'instance creation' }
MCPStructureToolAnnotations class >> readOnly [

	^ self new
		  readOnlyHint: true;
		  yourself
]

{ #category : 'converting' }
MCPStructureToolAnnotations >> asJRPCJSON [

	| dictionary |
	dictionary := Dictionary new.
	self title ifNotNil: [ :annotationTitle | dictionary at: #title put: annotationTitle ].
	self readOnlyHint ifNotNil: [ :hint | dictionary at: #readOnlyHint put: hint ].
	self destructiveHint ifNotNil: [ :hint | dictionary at: #destructiveHint put: hint ].
	self idempotentHint ifNotNil: [ :hint | dictionary at: #idempotentHint put: hint ].
	self openWorldHint ifNotNil: [ :hint | dictionary at: #openWorldHint put: hint ].
	^ dictionary
]

{ #category : 'accessing' }
MCPStructureToolAnnotations >> destructiveHint [

	^ destructiveHint
]

{ #category : 'accessing' }
MCPStructureToolAnnotations >> destructiveHint: aBoolean [

	destructiveHint := aBoolean
]

{ #category : 'accessing' }
MCPStructureToolAnnotations >> idempotentHint [

	^ idempotentHint
]

{ #category : 'accessing' }
MCPStructureToolAnnotations >> idempotentHint: aBoolean [

	idempotentHint := aBoolean
]

{ #category : 'accessing' }
MCPStructureToolAnnotations >> openWorldHint [

	^ openWorldHint
]

{ #category : 'accessing' }
MCPStructureToolAnnotations >> openWorldHint: aBoolean [

	openWorldHint := aBoolean
]

{ #category : 'accessing' }
MCPStructureToolAnnotations >> readOnlyHint [

	^ readOnlyHint
]

{ #category : 'accessing' }
MCPStructureToolAnnotations >> readOnlyHint: aBoolean [

	readOnlyHint := aBoolean
]

{ #category : 'accessing' }
MCPStructureToolAnnotations >> title [

	^ title
]

{ #category : 'accessing' }
MCPStructureToolAnnotations >> title: aString [

	title := aString
]
