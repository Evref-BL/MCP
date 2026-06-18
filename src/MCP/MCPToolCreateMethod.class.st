"
Tool that creates or replaces one method from source without exposing a combined method-mutation selector.
"
Class {
	#name : 'MCPToolCreateMethod',
	#superclass : 'MCPToolMethodMutation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolCreateMethod class >> toolName [

	^ 'method_create'
]

{ #category : 'private - specs' }
MCPToolCreateMethod >> methodToolSpec [

	^ {
		  (#title -> 'Create Method').
		  (#description
		   ->
		   'Create or replace one method on the instance side or class side of a class.').
		  (#action -> 'create').
		  (#inputProperties -> {
			   (MCPStructureProperties new
				    name: 'className';
				    type: 'string';
				    description:
					    'The class whose method will be created or replaced.';
				    yourself).
			   (MCPStructureProperties new
				    name: 'classSide';
				    type: 'boolean';
				    description: 'Whether the target method is on the class side.';
				    default: false;
				    yourself).
			   self forceSchemaProperty.
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
		  (#requiredProperties -> #( 'className' 'source'
		      'protocol' )) } asDictionary
]
