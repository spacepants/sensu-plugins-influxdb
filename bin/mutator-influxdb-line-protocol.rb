#! /usr/bin/env ruby
#
#   mutator-influxdb-line-protocol
#
# DESCRIPTION:
#   Mutates check results to conform to InfluxDB's line protocol format
#
# Place this file in /etc/sensu/extensions and modify your handlers JSON config
#
# handlers.json
# {
#   "influxdb_udp": {
#      "type": "udp",
#      "mutator": "influxdb_line_protocol",
#      "socket": {
#        "host": "mgt-monitor-db1",
#        "port": 8090
#      }
#    }
# }

require 'sensu/extension'

module Sensu
  module Extension
    class InfluxDBLineProtocol < Mutator
      def name
        'influxdb_line_protocol'
      end

      def description
        "returns check output formatted for InfluxDB's line protocol"
      end

      def run(event)
        tags = event[:check][:tags]
        host = event[:client][:name]
        metric = event[:check][:name]
        output = event[:check][:output]

        data = []
        output.split("\n").each do |result|
          m = result.split
          next unless m.count == 3
          key = m[0].split('.', 4)
          series = "#{key[0]}_#{key[1]}_#{key[2]}.#{key[3]}"
          value = m[1].to_f
          time = m[2].ljust(19, '0')
          linedata = "#{series},host=#{host},metric=#{metric}"
          if tags
            tags.each do |tagname, tagvalue|
              linedata << ",#{tagname}=#{tagvalue}"
            end
          end
          data << "#{linedata} value=#{value} #{time}"
        end

        yield data.join("\n"), 0
      end
    end
  end
end
