require 'open3'

module FastlaneCore
  class Devices
    class << self
      def all(requested_os_type)
        all_devices = simulators(requested_os_type)
        if requested_os_type == "iOS"
          all_devices += connected_devices
        end

        return all_devices
      end

      def simulators(requested_os_type)
        Helper.log.info "Fetching available simulator devices" if $verbose

        @devices = []
        os_type = 'unknown'
        os_version = 'unknown'
        output = ''
        Open3.popen3('xcrun simctl list devices') do |stdin, stdout, stderr, wait_thr|
          output = stdout.read
        end

        unless output.include?("== Devices ==")
          Helper.log.error "xcrun simctl CLI broken, run `xcrun simctl list devices` and make sure it works".red
          raise "xcrun simctl not working.".red
        end

        output.split(/\n/).each do |line|
          next if line.match(/^== /)
          if line.match(/^-- /)
            (os_type, os_version) = line.gsub(/-- (.*) --/, '\1').split
          else
            # iPad 2 (0EDE6AFC-3767-425A-9658-AAA30A60F212) (Shutdown)
            # iPad Air 2 (4F3B8059-03FD-4D72-99C0-6E9BBEE2A9CE) (Shutdown) (unavailable, device type profile not found)
            match = line.match(/\s+([^\(]+) \(([-0-9A-F]+)\) \((?:[^\(]+)\)(.*unavailable.*)?/)
            if match && !match[3] && os_type == requested_os_type
              @devices << Device.new(name: match[1], ios_version: os_version, udid: match[2], is_simulator: true)
            end
          end
        end

        return @devices
      end

      def connected_devices
        Helper.log.info "Fetching available connected devices" if $verbose
        @devices = []
        usb_devices_output = ''

        Open3.popen3("system_profiler SPUSBDataType |
                      sed -n -e '/iPad/,/Serial/p' -e '/iPhone/,/Serial/p' |
                      grep 'Serial Number:' |
                      awk -F ': ' '{print $2}'") do |stdin, stdout, stderr, wait_thr|
          usb_devices_output = stdout.read
        end

        instruments_devices_output = ''
        Open3.popen3("instruments -s devices") do |stdin, stdout, stderr, wait_thr|
          instruments_devices_output = stdout.read
        end

        usb_devices_output.split(/\n/).each do |device_uuid|
          instruments_devices_output.split(/\n/).each do |instruments_device|
            match = instruments_device.match(/(.+) \(([0-9.]+)\) \[([0-9a-f]+)\]?/)
            if match && match[3] == device_uuid
              @devices << Device.new(name: match[1], ios_version: match[2], udid: match[3], is_simulator: false)
              Helper.log.info "Usb Deice Found - " + match[1] + " (" + match[2] + ") UUID:" + match[3] if $verbose
            end
          end
        end

        return @devices
      end

      def clear_cache
        @devices = nil
      end

      # The code below works from Xcode 7 on
      # def all
      #   Helper.log.info "Fetching available devices" if $verbose

      #   @devices = []
      #   output = ''
      #   Open3.popen3('xcrun simctl list devices --json') do |stdin, stdout, stderr, wait_thr|
      #     output = stdout.read
      #   end

      #   begin
      #     data = JSON.parse(output)
      #   rescue => ex
      #     Helper.log.error ex
      #     Helper.log.error "xcrun simctl CLI broken, run `xcrun simctl list devices` and make sure it works".red
      #     raise "xcrun simctl not working.".red
      #   end

      #   data["devices"].each do |os_version, l|
      #     l.each do |device|
      #       next if device['availability'].include?("unavailable")
      #       next unless os_version.include?(requested_os_type)

      #       os = os_version.gsub(requested_os_type + " ", "").strip
      #       @devices << Device.new(name: device['name'], ios_version: os, udid: device['udid'])
      #     end
      #   end

      #   return @devices
      # end
    end

    # Use the UDID for the given device when setting the destination
    # Why? Because we might get this error message
    # > The requested device could not be found because multiple devices matched the request.
    #
    # This happens when you have multiple simulators for a given device type / iOS combination
    #   { platform:iOS Simulator, id:1685B071-AFB2-4DC1-BE29-8370BA4A6EBD, OS:9.0, name:iPhone 5 }
    #   { platform:iOS Simulator, id:A141F23B-96B3-491A-8949-813B376C28A7, OS:9.0, name:iPhone 5 }
    #
    # We don't want to deal with that, so we just use the UDID

    class Device
      attr_accessor :name

      attr_accessor :udid

      attr_accessor :ios_version

      attr_accessor :is_simulator

      def initialize(name: nil, udid: nil, ios_version: nil, is_simulator: nil)
        self.name = name
        self.udid = udid
        self.ios_version = ios_version
        self.is_simulator = is_simulator
      end

      def to_s
        self.name
      end
    end
  end

  class Simulator < Devices
    class << self
      def all
        return Devices.simulators('iOS')
      end
    end
  end

  class SimulatorTV < Devices
    class << self
      def all
        return Devices.simulators('tvOS')
      end
    end
  end
end
