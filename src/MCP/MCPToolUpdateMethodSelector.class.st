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

{ #category : 'defaults' }
MCPToolUpdateMethodSelector class >> toolName [

	^ 'method_selector_update'
]

{ #category : 'private - specs' }
MCPToolUpdateMethodSelector >> methodToolSpec [

	^ {
		  (#title -> 'Update Method Selector').
		  (#description
		   ->
		   'Rename, reorder, add, or remove method selector arguments using the Pharo refactoring engine.').
		  (#action -> 'update').
		  (#inputProperties -> {
			   (MCPStructureProperties new
				    name: 'className';
				    type: 'string';
				    description:
					    'The class whose method selector will be updated.';
				    yourself).
			   (MCPStructureProperties new
				    name: 'classSide';
				    type: 'boolean';
				    description: 'Whether the target method is on the class side.';
				    default: false;
				    yourself).
			   self forceSchemaProperty.
			   (MCPStructureProperties new
				    name: 'selector';
				    type: 'string';
				    description: 'The existing selector to update.';
				    yourself).
			   (MCPStructureProperties new
				    name: 'newSelector';
				    type: 'string';
				    description:
					    'The target selector. Same arity renames or reorders arguments; higher arity adds arguments; lower arity removes arguments.';
				    yourself).
			   ((MCPStructureProperties new
				     name: 'permutation';
				     type: 'array';
				     description:
					     'Optional target-argument map for newSelector. Positive entries are 1-based indexes into old selector arguments. Negative entries mark newly added argument positions. For removal, list the kept old argument indexes.')
				    items: (MCPStructureProperties new
						     type: 'integer';
						     description:
							     'An old argument index, or a negative placeholder for an added argument.';
						     yourself);
				    yourself).
			   ((MCPStructureProperties new
				     name: 'argumentNames';
				     type: 'array';
				     description:
					     'Target selector argument names in order. Required when newSelector adds arguments. Existing argument positions can reuse their current names.')
				    items: (MCPStructureProperties new
						     type: 'string';
						     description: 'An argument name in target selector order.';
						     yourself);
				    yourself).
			   ((MCPStructureProperties new
				     name: 'argumentValueExpressions';
				     type: 'array';
				     description:
					     'Default call expressions for newly added arguments, in the order the added arguments appear in newSelector. Omit to use nil for each added argument.')
				    items: (MCPStructureProperties new
						     type: 'string';
						     description:
							     'A Smalltalk expression inserted at sender call sites for a newly added argument.';
						     yourself);
				    yourself).
			   self refactoringScopePackageNamesSchemaProperty.
			   self refactoringScopeClassNamesSchemaProperty.
			   self refactoringScopeHierarchyClassNamesSchemaProperty }).
		  (#requiredProperties -> #( 'className' 'selector' 'newSelector' )) }
		  asDictionary
]
