using afIoc
using afIocConfig

@NoDoc
const class DosModule {
	
	Void defineServices(RegistryBuilder bob) {
	}
	
	@Build
	DosTerminal buildDosTerminal(ConfigSource config) {
		DosTerminal {
			it.currentDirStackMaxSize = config.get("afDos.currentDirStackSize", Int#)
		}
	}
	
	@Build
	DosOps buildDosOps(ConfigSource config) {
		DosOps {
			// TODO make exeExts a contributable service
			it.exeExts = ["exe", "bat", "cmd", "com"]
			it.osRootsCacheTimeout = config.get("afDos.osRootsCacheTimeout", Duration#)
		}
	}

	@Contribute { serviceType=FactoryDefaults# }
	Void contributeFactoryDefaults(Configuration config) {
		config["afDos.currentDirStackSize"] = 25
		config["afDos.osRootsCacheTimeout"] = 2sec
	}
}
