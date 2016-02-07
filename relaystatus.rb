#!/usr/bin/env ruby
`screen -S #{ARGV[0]}.webrelay -p 0 -X stuff 'tv_status'`
`screen -S #{ARGV[0]}.webrelay -p 0 -X hardcopy /tmp/#{ARGV[0]}.status`
