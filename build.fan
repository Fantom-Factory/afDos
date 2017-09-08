using build

class Build : BuildPod {

	new make() {
		podName = "afDos"
		summary = "Disk Operating System"
		version = Version("0.0.1")

		meta = [
			"pod.dis"		: "Dos",
			"repo.tags"		: "system",
			"repo.public"	: "true",

			"afIoc.module"	: "afDos::DosModule"
		]

		depends = [
			"sys          1.0.69 - 1.0",
			"concurrent   1.0.69 - 1.0",
			
			"afIoc        3.0.6  - 3.0",
			"afIocConfig  1.1.0  - 1.1",
			
			// ---- Test ----
			"afConcurrent 1.0.20 - 1.0"
		]

		srcDirs = [`fan/`, `test/`]
		resDirs = [`doc/`]
		
		meta["afBuild.testPods"]	= "afConcurrent"
	}
}
