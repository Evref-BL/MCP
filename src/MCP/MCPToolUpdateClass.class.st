"
Tool that changes one class definition: any of its name, superclass, package, tag, comment, slots, traits, shared variables, shared pools and layout, in one call.
"
Class {
	#name : 'MCPToolUpdateClass',
	#superclass : 'MCPToolClassMutation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolUpdateClass class >> toolName [

	^ 'class_update'
]

{ #category : 'private - specs' }
MCPToolUpdateClass >> additionalKeywords [
	"This tool answers for everything the per-property update tools used to, so it has to be findable by the words that led to each of them."

	^ super additionalKeywords
	  , #( 'rename' 'superclass' 'reparent' 'package' 'tag' 'recategorize' 'comment' 'slot' 'definition' 'trait' 'side' 'metaclass'
		     'composition' 'variable' 'shared' 'classvar' 'binding' 'pool' 'pooldictionary' 'dictionary' 'layout' 'shape' 'format'
		     'fixed' 'weak' 'immediate' 'word' 'byte' )
]

{ #category : 'private - specs' }
MCPToolUpdateClass >> classToolSpec [

	^ {
		  (#title -> 'Update Class').
		  (#description
		   ->
		   'Change one class definition in one call: its name, superclass, package, tag, comment and layout are replaced by value, its slots are patched. The changes asked for are applied in dependency order, stopping at the first that fails.').
		  (#inputProperties -> {
			   self classNameSchemaProperty.
			   self renameNewClassNameSchemaProperty.
			   self superclassNameSchemaProperty.
			   self packageNameSchemaProperty.
			   self tagSchemaProperty.
			   self commentSchemaProperty.
			   (self slotDeltaSchemaPropertyNamed: 'slots' describedAs: 'Patch over the instance-side slots.').
			   (self slotDeltaSchemaPropertyNamed: 'classSlots' describedAs: 'Patch over the class-side slots.').
			   self traitsSchemaProperty.
			   self classTraitsSchemaProperty.
			   self sharedVariablesSchemaProperty.
			   self sharedPoolsSchemaProperty.
			   self layoutSchemaProperty.
			   self forceSchemaProperty }).
		  (#requiredProperties -> #( 'name' )).
		  (#atLeastOneProperties
		   -> #( 'newName' 'superclass' 'package' 'tag' 'comment' 'slots' 'classSlots' 'traits' 'classTraits' 'sharedVariables'
			      'sharedPools' 'layout' )) } asDictionary
]
