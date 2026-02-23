#!/usr/bin/env ruby
# iOS Flavor Configuration Script
# This script automatically configures Xcode project for dev/prod flavors

require 'xcodeproj'

# Open the Xcode project
project_path = 'Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the Runner target
runner_target = project.targets.find { |t| t.name == 'Runner' }

unless runner_target
  puts "❌ Error: Runner target not found"
  exit 1
end

puts "📱 iOS Flavor Configuration Script"
puts "🎯 Target: #{runner_target.name}"

# Get existing build configurations
existing_configs = project.build_configurations.map(&:name)
puts "📋 Existing configurations: #{existing_configs.join(', ')}"

# Define new build configurations
new_configs = {
  'Debug-dev' => 'Debug',
  'Debug-prod' => 'Debug',
  'Release-dev' => 'Release',
  'Release-prod' => 'Release',
  'Profile-dev' => 'Profile',
  'Profile-prod' => 'Profile'
}

# Add new build configurations
new_configs.each do |config_name, base_config|
  # Check if configuration already exists
  if project.build_configurations.any? { |c| c.name == config_name }
    puts "⏭️  Skip: #{config_name} already exists"
    next
  end

  # Find base configuration
  base = project.build_configurations.find { |c| c.name == base_config }

  unless base
    puts "❌ Error: Base configuration '#{base_config}' not found"
    next
  end

  # Create new configuration
  new_config = project.new(Xcodeproj::Project::Object::XCBuildConfiguration)
  new_config.name = config_name
  new_config.build_settings = base.build_settings.dup

  # Set xcconfig file reference
  xcconfig_filename = "#{config_name}.xcconfig"
  xcconfig_file = project.files.find { |f| f.path&.include?(xcconfig_filename) }

  unless xcconfig_file
    # Add xcconfig file reference
    flutter_group = project.main_group.find_subpath('Flutter', true)
    xcconfig_file = flutter_group.new_file("Flutter/#{xcconfig_filename}")
  end

  new_config.base_configuration_reference = xcconfig_file if xcconfig_file

  # Add to project build configuration list
  project.build_configuration_list.build_configurations << new_config

  # Add to target build configuration list
  target_config = runner_target.build_configurations.find { |c| c.name == base_config }
  if target_config
    new_target_config = project.new(Xcodeproj::Project::Object::XCBuildConfiguration)
    new_target_config.name = config_name
    new_target_config.build_settings = target_config.build_settings.dup
    new_target_config.base_configuration_reference = xcconfig_file if xcconfig_file

    runner_target.build_configuration_list.build_configurations << new_target_config
  end

  puts "✅ Created: #{config_name} (based on #{base_config})"
end

# Add Run Script Phase for GoogleService-Info.plist copy
run_script_name = 'Copy GoogleService-Info.plist'
existing_script = runner_target.shell_script_build_phases.find { |phase| phase.name == run_script_name }

unless existing_script
  run_script_phase = runner_target.new_shell_script_build_phase(run_script_name)
  run_script_phase.shell_script = '"${PROJECT_DIR}/Runner/copy-googleservice-info.sh"'

  # Move the phase to before Compile Sources
  compile_sources_phase = runner_target.source_build_phase
  if compile_sources_phase
    phases = runner_target.build_phases
    script_index = phases.index(run_script_phase)
    compile_index = phases.index(compile_sources_phase)

    if script_index && compile_index && script_index > compile_index
      phases.delete_at(script_index)
      phases.insert(compile_index, run_script_phase)
    end
  end

  puts "✅ Added: Run Script Phase '#{run_script_name}'"
else
  puts "⏭️  Skip: Run Script Phase '#{run_script_name}' already exists"
end

# Save the project
project.save

# Create Xcode Schemes
puts ""
puts "📝 Creating Xcode Schemes..."

schemes_dir = "Runner.xcodeproj/xcshareddata/xcschemes"
Dir.mkdir(schemes_dir) unless Dir.exist?(schemes_dir)

base_scheme_path = "#{schemes_dir}/Runner.xcscheme"

unless File.exist?(base_scheme_path)
  puts "❌ Error: Base scheme file not found: #{base_scheme_path}"
  exit 1
end

# Read base scheme template
base_scheme_content = File.read(base_scheme_path)

# Define scheme configurations
schemes = {
  'Runner-dev' => {
    'Debug' => 'Debug-dev',
    'Release' => 'Release-dev',
    'Profile' => 'Profile-dev'
  },
  'Runner-prod' => {
    'Debug' => 'Debug-prod',
    'Release' => 'Release-prod',
    'Profile' => 'Profile-prod'
  }
}

# Generate schemes
schemes.each do |scheme_name, config_map|
  scheme_path = "#{schemes_dir}/#{scheme_name}.xcscheme"

  if File.exist?(scheme_path)
    puts "⏭️  Skip: Scheme '#{scheme_name}' already exists"
    next
  end

  # Replace build configurations
  scheme_content = base_scheme_content.dup

  # TestAction: Debug → Debug-dev/Debug-prod
  scheme_content.gsub!(/<TestAction[^>]*buildConfiguration\s*=\s*"Debug"/) do |match|
    match.gsub('"Debug"', "\"#{config_map['Debug']}\"")
  end

  # LaunchAction: Debug → Debug-dev/Debug-prod
  scheme_content.gsub!(/<LaunchAction[^>]*buildConfiguration\s*=\s*"Debug"/) do |match|
    match.gsub('"Debug"', "\"#{config_map['Debug']}\"")
  end

  # ProfileAction: Profile → Profile-dev/Profile-prod
  scheme_content.gsub!(/<ProfileAction[^>]*buildConfiguration\s*=\s*"Profile"/) do |match|
    match.gsub('"Profile"', "\"#{config_map['Profile']}\"")
  end

  # AnalyzeAction: Debug → Debug-dev/Debug-prod
  scheme_content.gsub!(/<AnalyzeAction[^>]*buildConfiguration\s*=\s*"Debug"/) do |match|
    match.gsub('"Debug"', "\"#{config_map['Debug']}\"")
  end

  # ArchiveAction: Release → Release-dev/Release-prod
  scheme_content.gsub!(/<ArchiveAction[^>]*buildConfiguration\s*=\s*"Release"/) do |match|
    match.gsub('"Release"', "\"#{config_map['Release']}\"")
  end

  # Write scheme file
  File.write(scheme_path, scheme_content)
  puts "✅ Created: Scheme '#{scheme_name}'"
end

puts "🎉 Configuration complete!"
puts ""
puts "Next steps:"
puts "1. Place Firebase config files:"
puts "   - ios/GoogleService-Info-dev.plist"
puts "   - ios/GoogleService-Info-prod.plist"
puts "2. Build & Run:"
puts "   flutter run --flavor dev -d <iOS-device-id>"
puts "   flutter run --flavor prod -d <iOS-device-id>"
puts "3. Release Build:"
puts "   flutter build ios --release --flavor prod"

