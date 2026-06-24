"
Tool that recategorizes one method into a protocol without exposing a combined method-mutation selector.
"
Class {
	#name : 'MCPToolUpdateMethodProtocol',
	#superclass : 'MCPToolMethodMutation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolUpdateMethodProtocol class >> toolName [

	^ 'method_protocol_update'
]

{ #category : 'private - specs' }
MCPToolUpdateMethodProtocol >> methodToolSpec [

	^ {
		  (#title -> 'Update Method Protocol').
		  (#description
		   -> 'Move one method to another protocol or extension protocol.').
		  (#action -> 'update').
		  (#inputProperties -> {
			   (MCPStructureProperties new
				    name: 'className';
				    type: 'string';
				    description:
					    'The class whose method protocol will be updated.';
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
				    description: 'The method selector to recategorize.';
				    yourself).
			   (MCPStructureProperties new
				    name: 'protocol';
				    type: 'string';
				    description:
					    'The target protocol. For extension methods, use an extension protocol such as *Package-Name.';
				    yourself) }).
		  (#requiredProperties -> #( 'className' 'selector' 'protocol' )) }
		  asDictionary
]
