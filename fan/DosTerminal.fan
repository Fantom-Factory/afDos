
class DosTerminal {

	private	File[]	currentDirStack		:= File[,]

	@NoDoc
	Int			currentDirStackMaxSize	:= 25
	
	@NoDoc
	Int			zipBufferSize			:= 16*1024
	
	|Float, Uri|?	onZipProgess		:= null
	|Err|?			onZipWarn			:= null
	|File, Str->Bool|?	onConfirmDelete	:= null
	Obj?		onCopyOverwrite			:= null
	
	Bool		showHiddenFiles
	
	DosOps		fileOps

	** Gets / sets the current directory that all commands are run from.
	File currentDir {
		get { currentDirStack.first ?: `./`.toFile }
		set {
			if (!it.isDir)
				throw ArgErr("${it.osPath} is not a directory")
			if (!it.exists)
				throw ArgErr("Does not exist: ${it.normalize.osPath}")
			normed := it.normalize
			stack  := currentDirStack
			if (stack.first != normed)
				stack.insert(0, normed)
			while (stack.size > currentDirStackMaxSize)
				stack.removeAt(-1)
		}
	}
	
	** Standard it-block ctor.
	new make(|This|? f := null) {
		f?.call(this)
		
		if (currentDirStackMaxSize < 1)
			throw Err("Invalid afDos.currentDirStackMaxSize = ${currentDirStackMaxSize}, must be >= 1")
		if (fileOps == null)
			fileOps = DosOps()
	}
	
	** Change directory.
	File cd(Str dir) {
		currentDir = toFile(dir)
	}
	
	** Returns dest file - so you can check if its different.
	File copy(Str from, Str? to := null) {
		copyTo	 := false
		fromFile := toFile(from)
		toFile	 := null as File
		if (to == null) {
			// if to is null, it just creates a copy! -> unique name
			toFile = fromFile.parent.plus("Copy of ${fromFile.name}".toUri, false)
			if (fromFile.isDir) {
				toFile = toFile.uri.plusSlash.toFile
				copyTo = true
			}

		} else {
			toFile = this.toFile(to)
		}
		toFile = fileOps.uniqueFile(toFile)
		
		if (toFile.isDir && !copyTo)
			fileOps.copyInto(fromFile, toFile, onCopyOverwrite)
		else
			fileOps.copyTo(fromFile, toFile, onCopyOverwrite)
		
		return toFile
	}

	Bool delete(Str path) {
		fileOps.delete(toFile(path), onConfirmDelete)
	}
	
	File[] list(Str? pathGlob := null) {
		path := toFile(pathGlob)
		return path.isDir
			? fileOps.list(path, null, showHiddenFiles)
			: fileOps.list(path.parent, path.name, showHiddenFiles)
	}

	Void createDir(Str dir) {
		dir = dir.endsWith(File.sep) ? dir : dir + File.sep
		fileOps.createDir(toFile(dir))
	}
	
	Void move(Str from, Str to) {
		fromFile := toFile(from)
		toFile	 := toFile(to)
		if (toFile.isDir)
			fileOps.moveInto(fromFile, toFile)
		else
			fileOps.moveTo(fromFile, toFile)		
	}
	
	File[] osRoots() {
		fileOps.osRoots
	}

	Int[] driveLetters() {
		fileOps.driveLetters
	}

	Void rename(Str path, Str newName) {
		fileOps.rename(toFile(path), newName)
	}
	
	File uniqueFile(Str path) {
		fileOps.uniqueFile(toFile(path))
	}
	
	Bool shouldHide(File file) {
		showHiddenFiles ? fileOps.isSystem(file) : fileOps.isHidden(file)
	}

	File zip(Str toCompress, Str? destFile := null, Str? pathPrefix := null) {
		fileOps.zip(toFile(toCompress), toFile(destFile), [
			"bufferSize"	: zipBufferSize,
			"pathPrefix"	: pathPrefix?.toUri,
			"onProgress"	: onZipProgess,
			"onWarn"		: onZipWarn
		])
	}
	
	File gzip(Str toCompress, Str? destFile := null) {
		fileOps.gzip(toFile(toCompress), toFile(destFile), [
			"bufferSize"	: zipBufferSize,
			"onProgress"	: onZipProgess
		])
	}
	
	File unzip(Str toDecompress, Str? destDir := null, [Str:Obj]? options := null) {
		srcFile := toFile(toDecompress)
		return srcFile.ext == "gz"
			 ? fileOps.ungzip(srcFile, toFile(destDir), [
				"bufferSize"	: zipBufferSize,
				"overwrite"		: onCopyOverwrite
			])
			: fileOps.unzip(srcFile, toFile(destDir), [
				"bufferSize"	: zipBufferSize,
				"overwrite"		: onCopyOverwrite
			])
	}
	
	
	// ---- Attributes ----
	
	File toFile(Str? path) {
		if (path == null) return currentDir
		uri := DosUtils.toFileUri(path) ?: throw Err("Invalid file path: $path")
		fil := currentDir.plus(uri, false)
		
		// re-normalise to take on board the casing of the dir name
		return fil.name.contains("*") || fil.name.contains("?") 
			? fil.parent.normalize.plus(fil.name.toUri)
			: fil.normalize
	}
}
