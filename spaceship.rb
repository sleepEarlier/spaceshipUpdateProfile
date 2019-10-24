require "spaceship"
# require 'io/console'
require 'Open3'
require 'fileutils'

puts "Enter Your Account:"
account = gets.chomp

# get password from keychain
service = account + "_DeveloperService"
cmd = "security find-generic-password -a $USER -s #{service} -w"
# puts cmd
$pwd = ''
# puts $pwd
Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
    while line = stdout.gets
        line = line.strip
        if line && line.length > 0
            # puts "line: #{line}"
            $pwd = line
        end
    end
end

if not $pwd
    $pwd = ''
end

if $pwd.length > 0
    puts "Use Keychain Password?(y/n)"
    use = gets.chomp
    if use.downcase != 'y' and use.downcase != 'yes'
        $pwd = ''
    end
end

if $pwd.length == 0
    puts "Enter Your Password:"
    $pwd = STDIN.noecho(&:gets).chomp
end

Spaceship.login(account, $pwd)

# save password to keychain
# puts "Updating Keychain"
cmd = "security add-generic-password -U -a $USER -s #{service} -w #$pwd"
# puts cmd
system(cmd)

# 更新设备
fileDir = File.dirname(__FILE__)
deviceFile = File.join(fileDir, "multiple-device-upload-ios.txt")
file = File.open(deviceFile) #文本文件里录入的udid和设备名用tab分隔
puts "\n-ADDING DEVICES"
file.each do |line|
    # puts "line:#{line}"
    arr = line.strip.split(" ")
    # puts "arr=#{arr}"
    udid = arr[0]
    name = arr[1]
    puts "\t-DeviceName:#{name}, udid:#{udid}"
    device = Spaceship.device.create!(name: arr[1], udid: arr[0])
    puts "\t-add device: #{device.name} #{device.udid} #{device.model}"
end

devices = Spaceship.device.all

profiles = Array.new
profiles += Spaceship.provisioning_profile.development.all 
profiles += Spaceship.provisioning_profile.ad_hoc.all

puts "\n-UPDATING PROFILES"
profiles.each do |p|
    puts "\t-Updating #{p.name}"
    p.devices = devices
    p.update!
end


downloadProfiles = Array.new
downloadProfiles += Spaceship.provisioning_profile.development.all 
downloadProfiles += Spaceship.provisioning_profile.ad_hoc.all

puts "\n-DOWNLOADING PROFILES"
downloadProfiles.each do |p|
    puts "\t-Downloading #{p.name}"
    fileName = p.name
    # save to Downloads floder
    downloadPath = File.expand_path("~/Downloads/#{fileName}.mobileprovision")
    File.write(downloadPath, p.download)
    puts "\t-File at: #{downloadPath}"
    # rename and copy to Provisioning Profiles floder
    dest = File.expand_path("~/Library/MobileDevice/Provisioning Profiles/#{p.uuid}.mobileprovision")
    FileUtils.copy(downloadPath, dest)
    puts "\t-Replace #{p.name} in Provisioning Profiles"
end