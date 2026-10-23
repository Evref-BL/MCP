"
The concrete resource a greeting template resolves to.

It is built per URI rather than registered, so it carries its own name and never auto-registers.
"
Class {
	#name : 'MCPGreetingTestResource',
	#superclass : 'MCPResource',
	#instVars : [
		'greetedName'
	],
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'instance creation' }
MCPGreetingTestResource class >> name: aName [

	^ self new
		  greetedName: aName;
		  yourself
]

{ #category : 'metadata' }
MCPGreetingTestResource class >> resourceUri [

	^ 'pharo://greeting/'
]

{ #category : 'accessing' }
MCPGreetingTestResource >> greetedName [

	^ greetedName
]

{ #category : 'accessing' }
MCPGreetingTestResource >> greetedName: anObject [

	greetedName := anObject
]

{ #category : 'metadata' }
MCPGreetingTestResource >> mimeType [

	^ 'text/plain'
]

{ #category : 'metadata' }
MCPGreetingTestResource >> name [

	^ self greetedName
]

{ #category : 'reading' }
MCPGreetingTestResource >> readContents [

	^ self textContents: 'Hello, ' , self greetedName , '!'
]

{ #category : 'metadata' }
MCPGreetingTestResource >> uri [

	^ self class resourceUri , self greetedName
]
