#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint tim.podspec` to validate before publishing.
#
tim_frb_version = ENV['TIM_FRB_VERSION'] || '0.0.1'
tim_frb_archive = "tim_frb-artifacts-v#{tim_frb_version}.zip"
tim_frb_url = "https://github.com/mobius-toy/tim_artifacts/releases/download/v#{tim_frb_version}/#{tim_frb_archive}"
artifacts_dir = '${PODS_TARGET_SRCROOT}/Frameworks'

Pod::Spec.new do |s|
  s.name             = 'tim'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter plugin project.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'

  # If your plugin requires a privacy manifest, for example if it collects user
  # data, update the PrivacyInfo.xcprivacy file to describe your plugin's
  # privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'tim_privacy' => ['Resources/PrivacyInfo.xcprivacy']}

  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'

  s.prepare_command = <<-CMD
    set -e
    ARTIFACTS_DIR="#{artifacts_dir}"
    ARCHIVE_NAME="#{tim_frb_archive}"
    URL="#{tim_frb_url}"

    rm -rf "${ARTIFACTS_DIR}"
    mkdir -p "${ARTIFACTS_DIR}"

    curl -L -o "${ARTIFACTS_DIR}/${ARCHIVE_NAME}" "${URL}"
    unzip -o "${ARTIFACTS_DIR}/${ARCHIVE_NAME}" "macosx/release/libtim_frb.a" -d "${ARTIFACTS_DIR}"
    mv "${ARTIFACTS_DIR}/macosx/release/libtim_frb.a" "${ARTIFACTS_DIR}/libtim_frb.a"

    rm -rf "${ARTIFACTS_DIR}/macosx"
    rm -f "${ARTIFACTS_DIR}/${ARCHIVE_NAME}"
  CMD

  s.vendored_libraries = 'Frameworks/libtim_frb.a'
end
