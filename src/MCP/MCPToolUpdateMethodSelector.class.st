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
		   -> 'Rename or reshape a method selector and update senders.').
		  (#action -> 'update').
		  (#inputProperties -> {
			   (MCPStructureProperties new
				    name: 'className';
				    type: 'string';
				    description: 'Class defining the method.';
				    yourself).
			   (MCPStructureProperties new
				    name: 'classSide';
				    type: 'boolean';
				    description: 'Whether target is class-side.';
				    default: false;
				    yourself).
			   self forceSchemaProperty.
			   (MCPStructureProperties new
				    name: 'selector';
				    type: 'string';
				    description: 'Existing selector.';
				    yourself).
			   (MCPStructureProperties new
				    name: 'newSelector';
				    type: 'string';
				    description: 'Target selector.';
				    yourself).
			   ((MCPStructureProperties new
				     name: 'permutation';
				     type: 'array';
				     description:
					     'Optional map from target arguments to old 1-based indexes; negative values are new arguments.')
				    items: (MCPStructureProperties new
						     type: 'integer';
						     description: 'Old index or negative new slot.';
						     yourself);
				    yourself).
			   ((MCPStructureProperties new
				     name: 'argumentNames';
				     type: 'array';
				     description:
					     'Argument names in target selector order; required when adding.')
				    items: (MCPStructureProperties new
						     type: 'string';
						     description: 'Argument name.';
						     yourself);
				    yourself).
			   ((MCPStructureProperties new
				     name: 'argumentValueExpressions';
				     type: 'array';
				     description:
					     'Call-site expressions for added arguments; defaults to nil.')
				    items: (MCPStructureProperties new
						     type: 'string';
						     description: 'Smalltalk expression.';
						     yourself);
				    yourself).
			   self refactoringScopePackageNamesSchemaProperty.
			   self refactoringScopeClassNamesSchemaProperty.
			   self refactoringScopeHierarchyClassNamesSchemaProperty }).
		  (#requiredProperties -> #( 'className' 'selector' 'newSelector' )) }
		  asDictionary
]
