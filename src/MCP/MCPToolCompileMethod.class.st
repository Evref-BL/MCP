"
Tool that compiles one method source into a class.

The compile operation creates the method when its selector is absent and replaces the existing method when the selector is already defined.
"
Class {
	#name : 'MCPToolCompileMethod',
	#superclass : 'MCPToolMethodMutation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolCompileMethod class >> toolName [

	^ 'method_compile'
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
		   'Compile method source into a class. Creates the method when absent and replaces it when the selector already exists.').
		  (#action -> 'compile').
		  (#inputProperties -> {
			   (MCPStructureProperties new
				    name: 'className';
				    type: 'string';
				    description: 'The class to compile the method into.';
				    yourself).
			   (MCPStructureProperties new
				    name: 'classSide';
				    type: 'boolean';
				    description: 'Whether to compile on the class side.';
				    default: false;
				    yourself).
			   (MCPStructureProperties new
				    name: 'source';
				    type: 'string';
				    description: 'The full method source to compile.';
				    yourself).
			   (MCPStructureProperties new
				    name: 'protocol';
				    type: 'string';
				    description:
					    'The target protocol. For extension methods, use an extension protocol such as *Package-Name.';
				    yourself) }).
		  (#requiredProperties -> #( 'className' 'source' 'protocol' )) }
		  asDictionary
]
