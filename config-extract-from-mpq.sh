#!/usr/bin/env bash

set -e

# See: cygpath command to convert between Windows/Cygwin paths

# For convenience, path to folder with game archives
folderPrefixClassic="/cygdrive/c/WC3/gamearchives"
# The main work folder
tempRootFolder="/cygdrive/c/temp/war3extract/"
# Temporary tar extraction folder, don't need to change
flatDir="./extracted-tar-archive/"
tarExtractFolder="${tempRootFolder:-/tmp/mpqinvalidpath}/${flatDir}"

# Path to MPQEditor EXE
mpqeditor="/cygdrive/c/Program Files/mpqeditor_en/x64/MPQEditor.exe"
# Path to Macro EXE
mpqeditor_gui_extract="/cygdrive/c/git/wc3-jass-history-scripts/mpqeditor-gui-extract-macro.exe"

function makeList() {
ClassicArchivePath=()

ClassicArchivePath+=("${folderPrefixClassic}/Beta-ROC-v1.00.tar")
ClassicArchivePath+=("${folderPrefixClassic}/Beta-ROC-v1.03.tar")
ClassicArchivePath+=("${folderPrefixClassic}/Beta-ROC-v1.10.tar")
ClassicArchivePath+=("${folderPrefixClassic}/Beta-ROC-v1.11.tar")
ClassicArchivePath+=("${folderPrefixClassic}/Beta-ROC-v1.12.tar")
ClassicArchivePath+=("${folderPrefixClassic}/Beta-ROC-v1.13.tar")
ClassicArchivePath+=("${folderPrefixClassic}/Beta-ROC-v1.20.tar")
ClassicArchivePath+=("${folderPrefixClassic}/Beta-ROC-v1.21.tar")
ClassicArchivePath+=("${folderPrefixClassic}/Beta-ROC-v1.30.tar")
ClassicArchivePath+=("${folderPrefixClassic}/Beta-ROC-v1.31.tar")
ClassicArchivePath+=("${folderPrefixClassic}/Beta-ROC-v1.32.tar")
ClassicArchivePath+=("${folderPrefixClassic}/Beta-ROC-v1.33.tar")
ClassicArchivePath+=("${folderPrefixClassic}/Beta-ROC-v1.34.tar")

ClassicArchivePath+=("${folderPrefixClassic}/ROC-v1.01-ru.tar")
ClassicArchivePath+=("${folderPrefixClassic}/ROC-v1.01b-ru.tar")
ClassicArchivePath+=("${folderPrefixClassic}/ROC-v1.02-ru.tar")
ClassicArchivePath+=("${folderPrefixClassic}/ROC-v1.02a-ru.tar")
ClassicArchivePath+=("${folderPrefixClassic}/ROC-v1.03-ru.tar")
ClassicArchivePath+=("${folderPrefixClassic}/ROC-v1.04-ru.tar")
ClassicArchivePath+=("${folderPrefixClassic}/ROC-v1.05-ru.tar")
ClassicArchivePath+=("${folderPrefixClassic}/ROC-v1.06-ru.tar")
ClassicArchivePath+=("${folderPrefixClassic}/ROC-v1.11-ru.tar")

# Bnet Stub only has ui/miscdata.txt and installed TFT .exe files
#ClassicArchivePath+=("${folderPrefixClassic}/Beta-TFT-bnetStub.tar")
ClassicArchivePath+=("${folderPrefixClassic}/Beta-TFT-v300.tar")
ClassicArchivePath+=("${folderPrefixClassic}/Beta-TFT-v301.tar")
ClassicArchivePath+=("${folderPrefixClassic}/Beta-TFT-v302.tar")
ClassicArchivePath+=("${folderPrefixClassic}/Beta-TFT-v303.tar")
ClassicArchivePath+=("${folderPrefixClassic}/Beta-TFT-v304.tar")
ClassicArchivePath+=("${folderPrefixClassic}/Beta-TFT-v304a.tar")
ClassicArchivePath+=("${folderPrefixClassic}/Beta-TFT-v305.tar")
ClassicArchivePath+=("${folderPrefixClassic}/Beta-TFT-v305a.tar")
ClassicArchivePath+=("${folderPrefixClassic}/Beta-TFT-v306.tar")
ClassicArchivePath+=("${folderPrefixClassic}/Beta-TFT-v307.tar")
ClassicArchivePath+=("${folderPrefixClassic}/Beta-TFT-v308.tar")
ClassicArchivePath+=("${folderPrefixClassic}/Beta-TFT-v309.tar")
ClassicArchivePath+=("${folderPrefixClassic}/Beta-TFT-v310.tar")
ClassicArchivePath+=("${folderPrefixClassic}/Beta-TFT-v311.tar")
ClassicArchivePath+=("${folderPrefixClassic}/Beta-TFT-v312.tar")
ClassicArchivePath+=("${folderPrefixClassic}/Beta-TFT-v313.tar")
ClassicArchivePath+=("${folderPrefixClassic}/Beta-TFT-v314.tar")
ClassicArchivePath+=("${folderPrefixClassic}/Beta-TFT-v314a.tar")
ClassicArchivePath+=("${folderPrefixClassic}/Beta-TFT-v315.tar")

ClassicArchivePath+=("${folderPrefixClassic}/TFT-v1.07-ru.tar")
ClassicArchivePath+=("${folderPrefixClassic}/TFT-v1.11-ru.tar")
ClassicArchivePath+=("${folderPrefixClassic}/TFT-v1.12-ru.tar")
ClassicArchivePath+=("${folderPrefixClassic}/TFT-v1.13-ru.tar")
ClassicArchivePath+=("${folderPrefixClassic}/TFT-v1.13b-ru.tar")
ClassicArchivePath+=("${folderPrefixClassic}/TFT-v1.14-ru.tar")
ClassicArchivePath+=("${folderPrefixClassic}/TFT-v1.14b-ru.tar")
ClassicArchivePath+=("${folderPrefixClassic}/TFT-v1.15-ru.tar")
ClassicArchivePath+=("${folderPrefixClassic}/TFT-v1.16a-ru.tar")
ClassicArchivePath+=("${folderPrefixClassic}/TFT-v1.17a-ru.tar")
ClassicArchivePath+=("${folderPrefixClassic}/TFT-v1.18a-ru.tar")
ClassicArchivePath+=("${folderPrefixClassic}/TFT-v1.19a-ru.tar")
ClassicArchivePath+=("${folderPrefixClassic}/TFT-v1.19b-ru.tar")
ClassicArchivePath+=("${folderPrefixClassic}/TFT-v1.20a-ru.tar")
ClassicArchivePath+=("${folderPrefixClassic}/TFT-v1.20b-ru.tar")
ClassicArchivePath+=("${folderPrefixClassic}/TFT-v1.20c-ru.tar")
ClassicArchivePath+=("${folderPrefixClassic}/TFT-v1.20d-ru.tar")
ClassicArchivePath+=("${folderPrefixClassic}/TFT-v1.20e-ru.tar")
ClassicArchivePath+=("${folderPrefixClassic}/TFT-v1.21a-ru.tar")
ClassicArchivePath+=("${folderPrefixClassic}/TFT-v1.21b-ru.tar")
ClassicArchivePath+=("${folderPrefixClassic}/TFT-v1.22a-ru.tar")
ClassicArchivePath+=("${folderPrefixClassic}/TFT-v1.23a-ru.tar")
ClassicArchivePath+=("${folderPrefixClassic}/TFT-v1.24a-ru.tar")
ClassicArchivePath+=("${folderPrefixClassic}/TFT-v1.24b-ru.tar")
ClassicArchivePath+=("${folderPrefixClassic}/TFT-v1.24c-ru.tar")
ClassicArchivePath+=("${folderPrefixClassic}/TFT-v1.24d-ru.tar")
ClassicArchivePath+=("${folderPrefixClassic}/TFT-v1.24e-ru.tar")
ClassicArchivePath+=("${folderPrefixClassic}/TFT-v1.25b-ru.tar")
ClassicArchivePath+=("${folderPrefixClassic}/TFT-v1.26a-ru.tar")
ClassicArchivePath+=("${folderPrefixClassic}/TFT-v1.27a-ru.tar")
ClassicArchivePath+=("${folderPrefixClassic}/TFT-v1.27b-ru.tar")

# /v1.28.2.7395-EN-test-6dd6892e9be524e226b58fe8dcf356b4
# /v1.29.0.8803-EN-test-10e02ee17ca62075417a723c1022e7fb
# /v1.29.2.9231-EN-test-0836dab8d1f4bdb2cf61fe155de1ae7d
# /v1.30.0.9655-EN-blizzget
# /v1.30.1.10211
# /v1.30.4-simplified_chinese
# /v1.31.1.12173-luashine-last_ptr-russian
# /v1.32.7.15572-EN-test-5e544b4bf1dcf1dd0a1b7f6095f0d3f3
# /v1.32.8.15801-EN-test-7f875d686448ef229cc746f65b506edc
# /v1.32.9.16589-EN-test-32fe4e3b250bc2bdd1b8dd74274f3d6f
# /v1.32.10-ru-luashine
# /v1.33.0-ru-luashine
}
makeList; # I just wanna collapse this monstrosity in my editor ok?