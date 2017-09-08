using afIoc::Inject
using afIoc::RegistryBuilder
using afIoc::Configuration
using afIocConfig::ApplicationDefaults
using concurrent::Actor
using afConcurrent::AtomicList

class TestDosOps : DosTests {
	
	@Inject	private DosOps?	dosOps
	
	override Void setup() {
		super.setup
	}

	Void ctor() {
		// can we just create a DosOps?
		ops := DosOps()
	}
	
	override Void bobReg(RegistryBuilder bob) {
		bob.contributeToServiceType(ApplicationDefaults#) |Configuration config| {
			config["afDos.osRootsCacheTimeout"] = 10ms
		}
	}
}
