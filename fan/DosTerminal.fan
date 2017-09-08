
class DosTerminal {
	
	Bool			showHiddenFiles

	Void copy(Str from, Str? to := null) {
		// if to is null, it just creates a copy! -> unique name
		
	}
	
	Void delete(Str path) {
		
	}
	
	File[] list(Str? pathGlob := null) {
		[,]
	}

	Void mkdir(Str dir) {
		
	}
	
	Void move(Str from, Str to) {
		
	}
	
//	File[] osRoots() {
//		[,]
//	}

	Void rename(Str path, Str newName) {
		
	}
	
	File uniqueFile(Str path) {
		File(``)
	}
	
	
	Bool shouldHide(File file) {
//		showHiddenFiles ? isSystem(file) : isHidden(file)
		false
	}

	** options to include "extraPath" or "pathPrefix" for dir name
	File? zip() {
		null
	}
	
	Void unzip() {
		
	}
}
