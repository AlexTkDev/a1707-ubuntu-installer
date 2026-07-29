# Platform definition for MacBookPro14,3 (15-inch, 2017)
# Used by the modular installer and doctor framework.

PLATFORM_ID="macbookpro14-3"
PLATFORM_VERSION="1"
PLATFORM_NAME="MacBookPro14,3"
BOARD_ID="Mac-551B86E5744E2388"
SUPPORTED_KERNEL_MIN="6.8"

WIFI_CHIP="BCM43602"
WIFI_FIRMWARE_DIR="/lib/firmware/brcm"
WIFI_FIRMWARE_BIN="brcmfmac43602-pcie.bin"
WIFI_BOARD_FILE="brcmfmac43602-pcie.txt"
WIFI_OPTIONAL_FILES=("brcmfmac43602-pcie.clm_blob" "brcmfmac43602-pcie.txcap_blob")

TOUCHBAR_SUPPORTED=1
AUDIO_DRIVER="snd_hda_macbookpro"
CAMERA_DRIVER="facetimehd"
