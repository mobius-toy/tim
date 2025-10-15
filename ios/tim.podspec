#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint tim.podspec` to validate before publishing.
#

env_file_path = File.join(__dir__, '..', 'tim_frb_version.env')
if File.exist?(env_file_path)
  env_content = File.read(env_file_path)
  version_match = env_content.match(/TIM_FRB_VERSION=(\d+\.\d+\.\d+)/)
  tim_frb_version = version_match ? version_match[1] : '0.0.1'
end

tim_frb_archive = "tim_frb-artifacts-v#{tim_frb_version}.zip"
tim_frb_url = "https://github.com/mobius-toy/tim_artifacts/releases/download/v#{tim_frb_version}/#{tim_frb_archive}"


Pod::Spec.new do |s|
  s.name             = 'tim'
  s.version          = tim_frb_version
  s.summary          = 'A new Flutter plugin project.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  s.script_phase = {
    :name => 'Fetch TIM FRB artifacts',
    :execution_position => :before_compile,
    :script => <<~SCRIPT,
      set -euo pipefail

      ARCHIVE_NAME="#{tim_frb_archive}"
      URL="#{tim_frb_url}"
      ARTIFACTS_DIR="${BUILT_PRODUCTS_DIR}"
      TARGET_LIB="${ARTIFACTS_DIR}/libtim_frb.a"
      TEMP_ZIP="${ARTIFACTS_DIR}/${ARCHIVE_NAME}"
      UNPACK_DIR="${ARTIFACTS_DIR}/tim_frb_unpack"

      if [ ! -f "${TARGET_LIB}" ]; then
        echo "Downloading TIM artifacts to ${TARGET_LIB}"
        mkdir -p "${ARTIFACTS_DIR}"
        curl -L -o "${TEMP_ZIP}" "${URL}"
        rm -rf "${UNPACK_DIR}"
        mkdir -p "${UNPACK_DIR}"
        unzip -o "${TEMP_ZIP}" -d "${UNPACK_DIR}"
        EXPECTED_LIB="${UNPACK_DIR}/artifacts/iphoneos/release/libtim_frb.a"
        if [ ! -f "${EXPECTED_LIB}" ]; then
          echo "Error: "${EXPECTED_LIB}" not found inside artifacts archive"
          exit 1
        fi
        cp "${EXPECTED_LIB}" "${TARGET_LIB}"
        rm -rf "${UNPACK_DIR}"
        rm -f "${TEMP_ZIP}"
      fi
    SCRIPT
    :output_files => ["${BUILT_PRODUCTS_DIR}/libtim_frb.a"],
  }

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'OTHER_LDFLAGS' => '-force_load ${BUILT_PRODUCTS_DIR}/libtim_frb.a',
  }

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'tim_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
