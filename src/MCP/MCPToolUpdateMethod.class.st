"
Tool that changes one method's protocol, its selector, or both in one call.
"
Class {
	#name : 'MCPToolUpdateMethod',
	#superclass : 'MCPToolMethodMutation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolUpdateMethod class >> toolName [

	^ 'method_update'
]

{ #category : 'private - specs' }
MCPToolUpdateMethod >> additionalKeywords [
	"The name no longer carries protocol or selector, which are the words that led to the two tools this replaces."

	^ super additionalKeywords , #( 'protocol' 'selector' 'rename' 'recategorize' 'signature' 'argument' 'extension' )
]

{ #category : 'private - specs' }
MCPToolUpdateMethod >> methodToolSpec [

	^ {
		  (#title -> 'Update Method').
		  (#description
		   ->
		   'Change one method: its protocol, its selector, or both in one call. A selector change is classified by arity, so the same argument renames, adds or removes arguments, and senders are updated.').
		  (#action -> 'update').
		  (#inputProperties -> {
			   (MCPStructureProperties new
				    name: 'class';
				    type: 'string';
				    description: 'The class defining the method.';
				    yourself).
			   (self targetSideSchemaPropertyDescribedAs: 'Which side the method is on.').
			   self forceSchemaProperty.
			   (MCPStructureProperties new
				    name: 'selector';
				    type: 'string';
				    description: 'The method selector to update.';
				    yourself).
			   (MCPStructureProperties new
				    name: 'protocol';
				    type: 'string';
				    description:
					    'Refile the method under this protocol. For an extension method, name an extension protocol such as *Package-Name.';
				    yourself).
			   (MCPStructureProperties new
				    name: 'newSelector';
				    type: 'string';
				    description: 'Rename the method to this selector, updating its senders.';
				    yourself).
			   ((MCPStructureProperties new
				     name: 'arguments';
				     type: 'array';
				     description:
					     'Names of the arguments the new selector takes, in order. Names matching the current ones are kept, new names are added arguments, and current ones left out are removed.')
				    items: (MCPStructureProperties new
						     type: 'string';
						     description: 'Argument name.';
						     yourself);
				    yourself).
			   ((MCPStructureProperties new
				     name: 'argumentValueExpressions';
				     type: 'array';
				     description: 'Expressions senders pass for each added argument, in order.')
				    items: (MCPStructureProperties new
						     type: 'string';
						     description: 'Smalltalk expression.';
						     yourself);
				    yourself).
			   ((MCPStructureProperties new
				     name: 'permutation';
				     type: 'array';
				     description:
					     'Only to reorder arguments, which names cannot express: one entry per new argument, holding the index of the current argument it takes, or 0 for an added one. Inferred from arguments when omitted.')
				    items: (MCPStructureProperties new
						     type: 'integer';
						     description: 'Current argument index, or 0.';
						     yourself);
				    yourself).
			   self methodSearchScopeSchemaProperty }).
		  (#requiredProperties -> #( 'class' 'selector' )).
		  (#atLeastOneProperties -> #( 'protocol' 'newSelector' )) } asDictionary
]
