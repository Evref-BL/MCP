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

{ #category : 'private - specs' }
MCPToolCompileMethod >> methodToolSpec [

	^ {
		  (#title -> 'Compile Method').
		  (#description
		   ->
		   'Compile method source into a class. Creates the method when absent and replaces it when the selector already exists. Several sources can be compiled into the same class in one call.').
		  (#action -> 'compile').
		  (#inputProperties -> {
			   (MCPStructureProperties new
				    name: 'class';
				    type: 'string';
				    description: 'The class to compile the method into.';
				    yourself).
			   (self targetSideSchemaPropertyDescribedAs: 'Which side to compile into.').
			   (MCPStructureProperties new
				    name: 'source';
				    type: #( 'string' 'array' );
				    description: 'The full method source to compile, selector line included, or several method sources for the same class.';
				    items: (MCPStructureProperties new
						     type: 'string';
						     description: 'The full source of one method.';
						     yourself);
				    yourself).
			   (MCPStructureProperties new
				    name: 'protocol';
				    type: 'string';
				    description:
					    'The protocol to file the method under. For an extension method, name an extension protocol such as *Package-Name.';
				    yourself) }).
		  (#requiredProperties -> #( 'class' 'source' 'protocol' )) } asDictionary
]
