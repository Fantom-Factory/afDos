using [java] java.nio.file::Files
using [java] java.nio.file::LinkOption
using [java] fanx.interop::Interop
using [java] java.io::File as JFile

using concurrent::AtomicRef

** (Service) - 
** A stateless class of basic DOS operations.
const class DosOps {

	@NoDoc
	const Duration	osRootsCacheTimeout	:= 2sec

	@NoDoc
	const Str[] 	exeExts := "bat cmd com exe".split

	** Standard it-block ctor.
	new make(|This|? f := null) { f?.call(this) }

	** Creates a sub-directory.
	** Returns the directory created.
	** 
	** Throws IOErr is the given file is not a directory or if there is a error creating the new directory. 
	File createDir(File dir) {
		if (!dir.isDir)
			throw IOErr("Not a directory: ${dir.normalize.uri}")
		return dir.parent.createDir(dir.name)
	}
	
	** Deletes the given file 
	** If the file represents a directory, then recursively delete it. 
	** If the file does not exist, then it does nothing.
	** Returns 'true' if the file was deleted.
	** 
	** The given 'areYouSure' function is invoked if the file is a system file or a top level file.
	** 
	** Throws IOErr on error.
	Bool delete(File path, |File, Str->Bool|? areYouSure := null) {
		if (!path.exists) return false
		areYouSure = areYouSure ?: |->Bool| { true }

		if (isSystem(path))
			if (!areYouSure(path, "Is a system file"))
				return false

		if (path.normalize.uri.path.size <= 2)
			if (!areYouSure(path, "Is a top level file"))
				return false
		
		path.delete
		return true
	}

	** Renames the given file.
	** Returns the renamed file.
	Void rename(File path, Str newName) {
		if (newName != path.name) {
			
			// can't rename a file to the same (case insensitive) name
			// so, rename it twice
			if (newName.equalsIgnoreCase(path.name)) {
				tmpName := newName + Int.random(0..9999).toStr
				path = path.rename(tmpName)
			}

			path.rename(newName)
		}
	}

	** Returns the root directories of the operating system's local file system.
	** The OS roots are cached for a small amount of time (~2sec) due to the potential overhead of 
	** checking removable drives.
	File[] osRoots() {
		// should we have a "Bool force" param? Or pass in the cache duration like DateTime.now()?
		if (_osRootsLastUpdated == null || Duration.now - _osRootsLastUpdated > osRootsCacheTimeout) {
			_osRootsCached 		= File.osRoots.map |r->File| { r.normalize }
			_osRootsLastUpdated = Duration.now
		}
		return _osRootsCached
	}
	
	** Returns a list of root drive letters for the file system.
	** 
	**   syntax: fantom
	**   ctx.driveLetters  // --> ['C', 'D', 'X']
	** 
	** Returns an empty list on non-windows systems.
	** 
	** Drive letters are cached for a small amount of time (~2sec) due to the potential overhead of 
	** checking removable drives.
	Int[] driveLetters() {
		Env.cur.os == "win32"
			? osRoots.map { it.path.first.upper[0] }
			: Int#.emptyList
	}
	
	
	** Returns 'true' if the file has the 'system' attribute.
	** Always returns 'false' on posix systems.
	Bool isSystem(File file) {
		if (Env.cur.os != "win32")
			return false
		
		path := ((JFile) Interop.toJava(file)).toPath
		attr := Files.readAttributes(path, "dos:system", (LinkOption[]) LinkOption#.emptyList)
		return attr.get("system") == true 
	}
	
	** Returns 'true' if the file name starts with a dot ( '.' ).
	** On 'win32' systems, 'true' is also returned if the file has 'hidden' or 'system' attribute.
	Bool isHidden(File file) {
		if (file.name.chars.getSafe(0) == '.')
			return true
		if (Env.cur.os != "win32")
			return false
		
		path := ((JFile) Interop.toJava(file)).toPath
		attr := Files.readAttributes(path, "dos:hidden,system", (LinkOption[]) LinkOption#.emptyList)
		return attr.get("hidden") == true || attr.get("system") == true 
	}

	** Returns 'true' if the application can execute the given file.
	** 
	** On 'win32' the file extension is checked against known extensions (see XXXX service).
	** On 'posix' systems, the file's execute permission for the current user is checked.
	Bool isExecutable(File file) {
		if (Env.cur.os == "win32")
			return file.ext != null && exeExts.contains(file.ext)

		path := ((JFile) Interop.toJava(file)).toPath
		return Files.isExecutable(path)
	}	

	** Returns 'true' if the application has read permissions for the given file.
	** Always returns 'true' on 'win32' systems.
	Bool isReadable(File file) {
		if (Env.cur.os == "win32") return true
		path := ((JFile) Interop.toJava(file)).toPath
		return Files.isReadable(path)
	}	

	** Returns 'true' if the application has write permissions for the current user.
	** On 'win32' systems, the *Read Only* attribute is checked.
	Bool isWritable(File file) {
		if (Env.cur.os == "win32")
			return ((JFile) Interop.toJava(file)).canWrite

		path := ((JFile) Interop.toJava(file)).toPath
		return Files.isWritable(path)
	}	

	** Sets the hidden attribute for the given file on 'win32' systems.
	** Does nothing on 'posix' systems.
	Void setHidden(File file, Bool hidden := true) {
		if (Env.cur.os != "win32") return
		path := ((JFile) Interop.toJava(file)).toPath
		Files.setAttribute(path, "dos:hidden", hidden, (LinkOption[]) LinkOption#.emptyList)
	}
	
	** Sets everybody's read permission for the given file on 'posix' systems.
	** Does nothing on 'win32' systems.
	Void setReadable(File file, Bool readable := true) {
		if (Env.cur.os == "win32") return
		success := ((JFile) Interop.toJava(file)).setReadable(readable, false)
		if (!success)
			throw IOErr("setReadable() did not succeed for $file.normalize.osPath")
	}

	** Sets everybody's write permission for the given file on 'posix' systems.
	** On 'win32' systems, the read only attribute is set.
	Void setWritable(File file, Bool writable := true) {
		if (Env.cur.os == "win32") {
			path := ((JFile) Interop.toJava(file)).toPath
			Files.setAttribute(path, "dos:readonly", !writable, (LinkOption[]) LinkOption#.emptyList)
			return
		}
		success := ((JFile) Interop.toJava(file)).setWritable(writable, false)		
		if (!success)
			throw IOErr("setWritable() did not succeed for $file.normalize.osPath")
	}

	** Sets everybody's execute permission for the given file on 'posix' systems.
	** Does nothing on 'win32' systems.
	Void setExecutable(File file, Bool executable := true) {
		if (Env.cur.os == "win32") return
		success := ((JFile) Interop.toJava(file)).setExecutable(executable, false)
		if (!success)
			throw IOErr("setExecutable() did not succeed for $file.normalize.osPath")
	}
	
	** List the files contained by the given directory.
	** The list includes both child sub-directories and normal files.
	** 
	** Throws IOErr is the given file is not a directory.
	**  
	** If 'filterGlob' is non-null then only files with matching filenames are returned.
	File[] list(File dir, Str? filterGlob := null, Bool showHiddenFiles := true) {
		if (!dir.isDir)
			throw IOErr("Not a directory: ${dir.normalize.uri}")
		
		regex := null as Regex
		if (filterGlob != null) {
			if (!filterGlob.endsWith("*"))
				filterGlob += "*"
			regex = "(?i)${Regex.glob(filterGlob)}".toRegex
		}
		files := dir.list(regex)
		if (showHiddenFiles == false)
			files = files.exclude { this.isHidden(it) }

		// fixme sort on dirs / and numeric extensions
//		dirs  := dir.listDirs (regex).sort |f1, f2| { f1.name.compareIgnoreCase(f2.name) }		
//		files := dir.listFiles(regex).sort |f1, f2| { f1.name.compareIgnoreCase(f2.name) }

		return files
	}

	** Copies the given file to the destination. 
	** Both 'from' and 'to' must either be directories, or not.
	Void copyTo(File from, File to, Obj? overwrite := null) {
		if (from.isDir.xor(to.isDir))
			throw IOErr("Both 'from' and 'to' must either be directories, or not.")
		from.copyTo(to, ["overwrite":overwrite])
	}

	** Copies the given file into the destination directory 
	Void copyInto(File from, File toDir, Obj? overwrite := null) {
		if (!toDir.isDir)
			throw IOErr("Not a directory: ${toDir.normalize.uri}")
		from.copyInto(toDir, ["overwrite":overwrite])
	}

	** Copies the given file to the destination. 
	** Both 'from' and 'to' must either be directories, or not.
	Void moveTo(File from, File to) {
		if (from.isDir.xor(to.isDir))
			throw IOErr("Both 'from' and 'to' must either be directories, or not.")
		from.moveTo(to)
	}

	** Copies the given file into the destination directory 
	Void moveInto(File from, File toDir) {
		if (!toDir.isDir)
			throw IOErr("Not a directory: ${toDir.normalize.uri}")
		from.moveInto(toDir)
	}

	** Returns a unique, non-existing file based on the one given.
	** If a directory is given, then a directory is returned.
	File uniqueFile(File file) {
		if (file.isDir)
			throw IOErr("Is a directory: ${file.normalize.uri}")
		destFile := file.normalize		// .normalize so we always have a parent  
		destName := destFile.name
		fileIndex := 0
		while (destFile.exists) { 
			fileIndex++
			destName = "${file.basename}(${fileIndex})"
			if (destFile.ext != null)
				destName += ".${file.ext}"
			destFile = destFile.parent.plus(destName.toUri, false)
		}
		if (file.isDir)
			destFile = destFile.uri.plusSlash.toFile
		return destFile
	}

	** Zips up the given file (or directory) and returns the compressed .zip file.
	** 
	** If 'destFile' is null, it defaults to '${toCompress.basename}.zip' 
	** 
	** The options map may contain:
	**  - bufferSize: an 'Int' that defines the stream buffer size. Defaults to 16Kb.
	**  - pathPrefix: a 'Uri' to prefix all files in the zip with. Must be a dir.
	**  - onProgress: '|Float percent, Uri path|' callback to show progress
	**  - onWarn    : '|Err err|' callback when a src file cannot be read - these files are skipped
	File zip(File toCompress, File? destFile := null, [Str:Obj]? options := null) {
		if (destFile != null && destFile.isDir)
			throw ArgErr("Destination can not be a directory - ${destFile}")
		
		pathPrefix := `/`
		if (options != null) 
			pathPrefix = ((Uri?) options["pathPrefix"]) ?: `/`
		
		if (!pathPrefix.isDir)
			throw IOErr("Not a directory: ${pathPrefix}")
		
		onProgress	:= (|Float, Uri|?) options?.get("onProgress")
		onWarn		:= (|Err|?) options?.get("onWarn")
		toIgnore	:= null as Str[]
		ignore		:= options?.get("ignore")
		if (ignore is Str)
			toIgnore = Str[ignore] 
		if (ignore is Obj[])
			toIgnore = ((Obj[]) ignore).map |t->Str| { t.toStr } 
		noOfFiles 	:= 0
		noOfBytes 	:= 0
		toCompress.walk |src| {
			if (!src.isDir) {
				noOfFiles++
				noOfBytes += src.size
			}
		}

		bufferSize	:= options?.get("bufferSize") ?: 16*1024
		dstFile		:= uniqueFile(destFile ?: toCompress.parent + `${toCompress.basename}.zip`) 
		zip			:= Zip.write(dstFile.out(false, bufferSize))		
		buf	 		:= Buf(bufferSize)
		parentUri 	:= toCompress.isDir ? toCompress.uri : toCompress.parent.uri

		try {
			bytesWritten := 0

			toCompress.walk |src| {
				if (src.isDir) return
				
				if (toIgnore != null) {
					rel := src.uri.relTo(toCompress.uri)
					// todo use globs
					if (toIgnore.contains(rel.path.first))
						return
				}

				path := pathPrefix + src.uri.relTo(parentUri)
				// don't append path to detail path, cause Java Heap Space probs with big dirs ~ 24,000 files
				onProgress?.call(bytesWritten / noOfBytes.toFloat, path)

				out := zip.writeNext(path)
				try {
					// this is the easy way to compress the file - but we do it the hard way
					// so we can show progress when zipping large files
//					src.in(bufferSize).pipe(out)
					
					in			:= src.in 
					error 		:= null as Err
					bytesRead	:= 0 as Int
					while (error == null && bytesRead != null) {
						bytesRead = 0

						try {
							bytesRead = in.readBuf(buf.clear, bufferSize)
						} catch (IOErr ioe) {
							error = IOErr("Problems reading: ${src.osPath}\n  ${ioe.msg}\n")
						} finally {
							in.close
						}
						
						if (error == null && bytesRead != null) {
							out.writeBuf(buf.flip)
							bytesWritten += bytesRead
							onProgress?.call(bytesWritten / noOfBytes.toFloat, path)
						}
					}
					
					if (error != null)
						onWarn?.call(error)
					
				} finally
					out.close
			}
			
		} finally
			zip.close

		return dstFile
	}
	
	** Gzips up the given file and returns the compressed .gzip file.
	** 
	** If 'destFile' is null, it defaults to '${toCompress.name}.gz'
	**  
	** The options map may contain:
	**  - bufferSize: an 'Int' that defines the stream buffer size. Defaults to 16Kb.
	**  - onProgress: '|Float percent, Uri path|' callback to show progress
	File gzip(File toCompress, File? destFile := null, [Str:Obj]? options := null) {
		if (toCompress.isDir)
			throw ArgErr("Cannot gzip directories: $toCompress")
		if (destFile != null && destFile.isDir)
			throw ArgErr("Destination can not be a directory - ${destFile}")

		onProgress	:= (|Float, Uri|?) options?.get("onProgress")
		bufferSize	:= options?.get("bufferSize") ?: 16*1024
		dstFile		:= uniqueFile(destFile ?: toCompress.uri.plusName(toCompress.name + ".gz").toFile) 

		bTotal	:= toCompress.size
		bRead	:= 0
		zipIn	:= toCompress.in(bufferSize)
		zipOut	:= Zip.gzipOutStream(dstFile.out(false, bufferSize))

		try {
			buf	 := Buf(bufferSize)
			piping := true
			
			while (piping) {
				i := zipIn.readBuf(buf.seek(0), bufferSize)
				if (i == null) {
					piping = false
					continue
				}
				bRead += i
				zipOut.writeBuf(buf.seek(0), i)
				onProgress?.call(bRead / bTotal.toFloat, `/${dstFile.name}`)
			}
			
		} finally {
			zipIn.close
			zipOut.close
		}

		return dstFile
	}
	
	** Unzips the given file and returns the directory it was unzipped to.
	** 
	** The options map may contain:
	**  - bufferSize: an 'Int' that defines the stream buffer size. Defaults to 16Kb.
	**  - overwrite: an 'Obj' passed to 'File.copy()'. Defaults to 'true'.
	File unzip(File toDecompress, File? destDir := null, [Str:Obj]? options := null) {
		if (toDecompress.isDir)
			throw ArgErr("Destination can not be a directory - ${toDecompress}")
		if (destDir != null && !destDir.isDir)
			throw ArgErr("Destination must be a directory - ${destDir}")
		
		// todo read zip file first, then give unzip progress
		
		overwrite	:= options?.get("overwrite") ?: true
		bufferSize	:= options?.get("bufferSize") ?: 16*1024
		dstDir		:= destDir ?: toDecompress.parent
		zip			:= Zip.read(toDecompress.in(bufferSize))
		try {
			File? entry
			while ((entry = zip.readNext) != null) {
				if (entry.isDir)
					dstDir.plus(entry.uri.relTo(`/`), false).create
				else
					entry.copyTo(dstDir + entry.uri.relTo(`/`), ["overwrite":overwrite])
			}
		} finally {
			zip.close
		}
		
		return dstDir
	}
	
	** Un-gzips the given file and returns the file it was unzipped to.
	** 
	** The options map may contain:
	**  - bufferSize: an 'Int' that defines the stream buffer size. Defaults to 16Kb.
	**  - overwrite: an 'Obj' passed to 'File.copy()'. Defaults to 'true'.
	File ungzip(File toDecompress, File? destFile := null, [Str:Obj]? options := null) {
		if (toDecompress.isDir)
			throw ArgErr("Destination can not be a directory - ${toDecompress}")
		if (destFile != null && destFile.isDir)
			throw ArgErr("Destination must NOT be a directory - ${destFile}")
		
		overwrite	:= options?.get("overwrite") ?: true
		// fixme use overwrite
		if (overwrite!= null)
			throw UnsupportedErr("overwrite")

		bufferSize	:= options?.get("bufferSize") ?: 16*1024
		dstFile		:= destFile ?: toDecompress.parent + toDecompress.basename.toUri
		if (dstFile == toDecompress)
			throw IOErr("Output file cannot be the same as the input file: $toDecompress.normalize.osPath")

		out	:= dstFile.out(false, bufferSize)
		zip	:= Zip.gzipOutStream(out)
		in 	:= toDecompress.in(bufferSize)
		try {
			in.pipe(zip)
			in.close
		} finally {
			in.close
			zip.close
			out.close
		}
		
		return dstFile
	}
	
	** Create a temporary directory which is guaranteed to be a new, empty
	** directory with a unique name.  The dir name will be generated using
	** the specified prefix and suffix.  
	** 
	** If dir is non-null then it is used as the file's parent directory,
	** otherwise the system's default temporary directory is used.
	** 
	** Examples:
	**   File.createTemp("x", "-etc") => `/tmp/x67392-etc/`
	**   File.createTemp.deleteOnExit => `/tmp/fan-5284/`
	**
	** See the Fantom forum topic [File.createTempDir()]`http://fantom.org/forum/topic/2424`.
	File createTempDir(Str prefix := "fan-", Str suffix := "", File? dir := null) {
		tempFile := File.createTemp(prefix, suffix, dir ?: Env.cur.tempDir)
		dirName  := tempFile.name
		tempFile.delete
		tempDir  := tempFile.parent.createDir(dirName)
		return tempDir
	}

	** Create a temporary file which is guaranteed to be a new, empty
	** file with a unique name.  The file name will be generated using
	** the specified prefix and suffix.
	** 
	** If dir is non-null then it is used as the file's parent directory,
	** otherwise the system's default temporary directory is used.
	**
	** Examples:
	**   File.createTemp("x", ".txt") => `/tmp/x67392.txt`
	**   File.createTemp.deleteOnExit => `/tmp/fan5284.tmp`
	File createTempFile(Str prefix := "fan-", Str suffix := "", File? dir := null) {
		File.createTemp(prefix, suffix, dir ?: Env.cur.tempDir)
	}
	
	private const AtomicRef	_osRootsCachedRef		:= AtomicRef()
	private const AtomicRef	_osRootsLastUpdatedRef	:= AtomicRef()

	private File[]?	_osRootsCached {
		get { _osRootsCachedRef.val }
		set { _osRootsCachedRef.val = it.toImmutable }
	}

	private Duration? _osRootsLastUpdated {
		get { _osRootsLastUpdatedRef.val }
		set { _osRootsLastUpdatedRef.val = it }		
	}
}
