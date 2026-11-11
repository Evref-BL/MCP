"
Tool that compiles one method source into a class.

The compile operation creates the method when its selector is absent and replaces the existing method when the selector is already defined.
"
Class {
	#name : 'MCPToolCompileMethod',
	#superclass : 'MCPToolMethodMutation',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolCompileMethod class >> toolName [

	^ 'method_compile'
]

{ #category : 'metadata' }
MCPToolCompileMethod >> batchArgumentName [

	^ 'source'
]

{ #category : 'metadata' }
MCPToolCompileMethod >> batchSummaryNoun [

	^ 'methods'
]

{ #category : 'metadata' }
MCPToolCompileMethod >> batchSummaryVerb [

	^ 'Compiled'
]

{ #category : 'private - results' }
MCPToolCompileMethod >> contentTextForStructuredContent: structuredContent [
	"The summary already names the change and its kind. A critique's description is its rule's generic explanation, the same text on every hit, while the title names the problem actually found."

	| data |
	data := structuredContent at: #data ifAbsent: [ ^ super contentTextForStructuredContent: structuredContent ].
	^ String streamContents: [ :stream |
			  self summaryAndWarningsOn: stream for: structuredContent.
			  (data at: #critiques ifAbsent: [ #(  ) ]) do: [ :critique |
					  stream
						  nextPut: Character lf;
						  nextPutAll: (critique at: #ruleClass);
						  nextPutAll: ' '.
					  critique at: #start ifPresent: [ :start |
							  stream
								  print: start;
								  nextPut: $-;
								  print: (critique at: #stop ifAbsent: [ start ]);
								  nextPutAll: ' ' ].
					  stream nextPutAll: (critique at: #title) ] ]
]

{ #category : 'metadata' }
MCPToolCompileMethod >> defaultExposure [

	^ 'static'
]

{ #category : 'private - schema' }
MCPToolCompileMethod >> forceSchemaProperty [
	"Compiling has one more thing to force than the other mutations: a method the class got from a trait. Overriding one is Pharo's own move, and the override lands in the source of the class, so the caller is allowed it once they say so."

	^ self
		  booleanSchemaPropertyNamed: 'force'
		  description: 'Continue through refactoring warnings instead of stopping, and override a method the class gets from a trait.'
		  default: false
]

{ #category : 'private - specs' }
MCPToolCompileMethod >> methodToolSpec [

	^ {
		  (#title -> 'Compile Method').
		  (#description -> 'Add or replace methods in a class from their full source, selector line included.').
		  (#action -> 'compile').
		  (#inputProperties -> {
			   (MCPStructureProperties new
				    name: 'class';
				    type: 'string';
				    description: 'The class to compile into.';
				    yourself).
			   (self targetSideSchemaPropertyDescribedAs: 'Which side to compile into.').
			   (MCPStructureProperties new
				    name: 'source';
				    type: #( 'string' 'array' );
				    description: 'Full method source, selector line included, or several for the same class.';
				    items: (MCPStructureProperties new
						     type: 'string';
						     yourself);
				    yourself).
			   (MCPStructureProperties new
				    name: 'protocol';
				    type: 'string';
				    description:
					    'Protocol for the method; a replaced method keeps its own when omitted. Extension methods take *Package-Name.';
				    yourself).
			   self forceSchemaProperty }).
		  (#requiredProperties -> #( 'class' 'source' )) } asDictionary
]
