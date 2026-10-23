"
Tool that updates a method selector or signature using the Pharo refactoring engine.
"
Class {
	#name : 'MCPToolUpdateMethodSelector',
	#superclass : 'MCPToolMethodMutation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolUpdateMethodSelector class >> toolName [

	^ 'method_selector_update'
]

{ #category : 'private - specs' }
MCPToolUpdateMethodSelector >> methodToolSpec [

	^ {
		  (#title -> 'Update Method Selector').
		  (#description -> 'Rename or reshape a method selector and update senders.').
		  (#action -> 'update').
		  (#inputProperties -> {
			   (MCPStructureProperties new
				    name: 'class';
				    type: 'string';
				    description: 'Class name.';
				    yourself).
			   (MCPStructureProperties new
				    name: 'side';
				    type: 'string';
				    enum: #( 'instance' 'class' );
				    description: 'Class-side method.';
				    default: 'instance';
				    yourself).
			   self forceSchemaProperty.
			   (MCPStructureProperties new
				    name: 'selector';
				    type: 'string';
				    description: 'Old selector.';
				    yourself).
			   (MCPStructureProperties new
				    name: 'newSelector';
				    type: 'string';
				    description: 'New selector.';
				    yourself).
			   ((MCPStructureProperties new
				     name: 'permutation';
				     type: 'array';
				     description: 'Target argument map; old indexes positive, new args negative.')
				    items: (MCPStructureProperties new
						     type: 'integer';
						     description: 'Argument index.';
						     yourself);
				    yourself).
			   ((MCPStructureProperties new
				     name: 'arguments';
				     type: 'array';
				     description: 'Names for target arguments.')
				    items: (MCPStructureProperties new
						     type: 'string';
						     yourself);
				    yourself).
			   ((MCPStructureProperties new
				     name: 'argumentValueExpressions';
				     type: 'array';
				     description: 'Expressions for added arguments.')
				    items: (MCPStructureProperties new
						     type: 'string';
						     description: 'Smalltalk expression.';
						     yourself);
				    yourself).
			   self methodSearchScopeSchemaProperty }).
		  (#requiredProperties -> #( 'class' 'selector' 'newSelector' )) } asDictionary
]
