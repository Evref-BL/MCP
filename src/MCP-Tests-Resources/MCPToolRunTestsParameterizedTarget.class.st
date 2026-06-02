"
Fixture test case used by parameterized test-running tool tests.
"
Class {
	#name : 'MCPToolRunTestsParameterizedTarget',
	#superclass : 'ParametrizedTestCase',
	#instVars : [
		'encoding'
	],
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'building suites' }
MCPToolRunTestsParameterizedTarget class >> testParameters [

	^ ParametrizedTestMatrix new
		  addCase: { (#encoding -> 'UTF-8') };
		  addCase: { (#encoding -> 'UTF-16') };
		  addCase: { (#encoding -> 'UTF-32') };
		  yourself
]

{ #category : 'accessing' }
MCPToolRunTestsParameterizedTarget >> encoding [

	^ encoding
]

{ #category : 'accessing' }
MCPToolRunTestsParameterizedTarget >> encoding: aString [

	encoding := aString
]

{ #category : 'tests' }
MCPToolRunTestsParameterizedTarget >> testFailsOnlyForUTF16 [

	self deny: encoding = 'UTF-16' description: 'UTF-16 probe failure'
]
