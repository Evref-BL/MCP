"
A probe that debug_watch installs before Pharo 12, which has no debug points: a metalink that evaluates a script after its node runs, in the frame of the method, the way a watch debug point with a script behavior does from Pharo 12 on. I answer remove, as a debug point does.
"
Class {
	#name : 'MCPWatchProbe',
	#superclass : 'Object',
	#instVars : [
		'link',
		'script'
	],
	#category : 'MCP-IDE-Compatibility-Before12',
	#package : 'MCP-IDE-Compatibility-Before12'
}

{ #category : 'instance creation' }
MCPWatchProbe class >> installOn: aNode script: aString [

	^ self new
		  script: aString;
		  installOn: aNode;
		  yourself
]

{ #category : 'evaluating' }
MCPWatchProbe >> hitWithContext: aContext [
	"Evaluated as ScriptBehavior evaluates the script of a debug point from Pharo 12 on."

	^ Smalltalk compiler
		  source: script;
		  context: aContext;
		  receiver: aContext receiver;
		  bindings: { (#thisContext -> aContext) };
		  evaluate
]

{ #category : 'installing' }
MCPWatchProbe >> installOn: aNode [

	link := MetaLink new
		        metaObject: self;
		        selector: #hitWithContext:;
		        arguments: #( #context );
		        control: #after;
		        options: #( #+ #optionCompileOnLinkInstallation );
		        yourself.
	aNode link: link
]

{ #category : 'installing' }
MCPWatchProbe >> remove [

	link ifNotNil: [ link uninstall ]
]

{ #category : 'accessing' }
MCPWatchProbe >> script: aString [

	script := aString
]
