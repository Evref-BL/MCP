"
Evaluation context for a parsed where predicate. It groups the current tool, entity kind, query entry, domain object, and per-query cache so predicate evaluation does not grow long argument lists.
"
Class {
	#name : 'MCPWhereEvaluation',
	#superclass : 'Object',
	#instVars : [
		'tool',
		'entityKind',
		'entry',
		'object',
		'context'
	],
	#category : 'MCP-Queries',
	#package : 'MCP',
	#tag : 'Queries'
}

{ #category : 'accessing' }
MCPWhereEvaluation >> context [

	^ context ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
MCPWhereEvaluation >> context: anObject [

	context := anObject
]

{ #category : 'accessing' }
MCPWhereEvaluation >> entityKind [

	^ entityKind
]

{ #category : 'accessing' }
MCPWhereEvaluation >> entityKind: anObject [

	entityKind := anObject
]

{ #category : 'accessing' }
MCPWhereEvaluation >> entry [

	^ entry
]

{ #category : 'accessing' }
MCPWhereEvaluation >> entry: anObject [

	entry := anObject
]

{ #category : 'evaluating' }
MCPWhereEvaluation >> forEntityKind: anEntityKind entry: anEntry object: anObject [

	^ self class new
		  tool: self tool;
		  entityKind: anEntityKind;
		  entry: anEntry;
		  object: anObject;
		  context: self context;
		  yourself
]

{ #category : 'accessing' }
MCPWhereEvaluation >> object [

	^ object
]

{ #category : 'accessing' }
MCPWhereEvaluation >> object: anObject [

	object := anObject
]

{ #category : 'accessing' }
MCPWhereEvaluation >> tool [

	^ tool
]

{ #category : 'accessing' }
MCPWhereEvaluation >> tool: anObject [

	tool := anObject
]
