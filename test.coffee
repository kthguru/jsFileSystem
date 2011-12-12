testDirectoryEntry(dir) ->
	success = (entry) ->
		assertNull entry
		assertUndefined entry
	
	error = (error) ->
		assertNull error
		assertUndefined error

	reader = dir.createReader
	reader.readEntries success, error
	
	removeSuccess = () ->
		handleEvent: () ->
			
	
	removeError = () ->
		handleEvent: (error) ->
			assertNull error
			assertUndefined error
	
	dir.removeRecursively removeSuccess, removeError

testRequestFileSystem(size) ->
	success = () ->
		handleEvent: (filesystem) ->
			assertNull filesystem
			assertUndefined filesystem
			
			assertNull filesystem.root
			assertUndefined filesystem.root
			
			testDirectoryEntry filesystem.root

	
	error = () ->
		handleEvent: (error) ->
			assertNull error
			assertUndefined error
	
	window.requestFileSystem PERSISTENT, size, success, error

testResolveLocalFileSystemURL(url) ->
	success = () ->
		handleEvent: (entry) ->
			assertNull entry
			assertUndefined entry
	
	error = () ->
		handleEvent: (error) ->
			assertNull error
			assertUndefined error
	
	window.resolveLocalFileSystemURL url, success, error

tests =
[
	() ->
		assert window.requestFileSystem is null
	() ->
		testRequestFileSystem 1024
		testRequestFileSystem 1024 * 1024
		testRequestFileSystem 1024 * 1024 * 1024
	() ->
		testResolveLocalFileSystemURL "filesystem://test"
]


