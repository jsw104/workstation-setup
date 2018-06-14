#!/usr/bin/env ruby

require_relative './base.rb'

class ConfigureOSXTracker < TrackerConfigurationBase
  include ProcessHelper

  def run
    # Update the system clock
    # See http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Format_Patterns
    process('defaults write com.apple.menuextra.clock "DateFormat" "MMM d h:mm:ss a"')
    process('killall SystemUIServer')

    # Wait for the dock process to restart
    dock_down = true
    while dock_down
      output = process('pgrep Dock', expected_exit_status: [0, 1])
      dock_down = output.empty?
      puts 'dock is down, retrying...' if dock_down
      sleep 1
    end

    # Modify appearance of dock
    # remove existing icons
    process_dockutil('--remove spacer-tiles --no-restart')
    process_dockutil('--list').split("\n").each do |line|
      application = line.split("\t")[0]
      process_dockutil("--remove \"#{application}\" --no-restart")
    end

    # add desired applications
    apps = [
      'Launchpad',
      'iTerm',
      'Google Chrome',
      'Google Chrome Canary',
      'Safari',
      'Firefox',
      'RubyMine',
      'Sublime Text',
      'Atom',
      'System Preferences',
      'zoom.us',
    ]
    apps.each do |app|
      process_dockutil("--add \"/Applications/#{app}.app\" --no-restart")
    end

    # add spacers after each of these apps
    ['iTerm', 'Firefox'].each do |app|
      process_dockutil("--add '' --type spacer --section apps --after '#{app}' --no-restart")
    end

    process('defaults write com.apple.dock orientation -string bottom')
    process('defaults write com.apple.dock magnification -bool false')
    process('defaults write com.apple.dock tilesize -int 50')

    # Restart the dock
    process('killall Dock')
  end

  def process_dockutil(command)
    process_without_output("dockutil #{command}")
  end
end

ConfigureOSXTracker.new.run
