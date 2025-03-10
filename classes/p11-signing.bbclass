DEPENDS += "libp11-native opensc-native p11-kit-native openssl-native softhsm-native gnutls-native"

def get_pkcs11_module_path(d):
    backend = d.getVar('PKCS11_BACKEND')
    if backend == "opensc":
        return "${RECIPE_SYSROOT_NATIVE}/usr/lib/opensc-pkcs11.so"
    elif backend == "softhsm":
        return "${RECIPE_SYSROOT_NATIVE}/usr/lib/softhsm/libsofthsm2.so"
    else:
        import bb
        bb.fatal(f"PKCS#11 backend \"{backend}\" not set or unsupported.")

# PKCS#11 backend
PKCS11_BACKEND ?= "opensc"
PKCS11_MODULE_PATH = "${@get_pkcs11_module_path(d)}"

# sbsign and evmctl can't handle certificates passed as PKCS#11 URIs.
# This command provides measures to extract a certificate from a PKCS#11 token.
extract_cert () {
        p11tool --provider ${PKCS11_MODULE_PATH} --export-chain $1 > $2
}

is_pkcs11_uri () {
	if [ "${1#pkcs11:}" != "${1}" ]; then
	    return 0 # this is TRUE in shell script. trust|me i know
	else
	    return 1
	fi
}

# variables passed to OpenSSL
export OPENSSL_ENGINES = "${RECIPE_SYSROOT_NATIVE}/usr/lib/engines-3"
export PKCS11_MODULE_PATH
export SOFTHSM2_CONF = "${RECIPE_SYSROOT_NATIVE}/etc/softhsm2.conf"

# default key overrides
# if no dedicated certificate is specified, default to the key file/URI
GUESTOS_SIG_CERT ?= "${GUESTOS_SIG_KEY}"
KERNEL_IMA_SIG_CERT ?= "${GUESTOS_SIG_KEY}"
SECURE_BOOT_SIG_CERT ?= "${SECURE_BOOT_SIG_KEY}"
