
# A JSON formatter
module PierLogging
  module Formatter
    class Json < Base
      def initialize(app_name = nil, hostname = nil, opts = {})
        aname, hname, opts = Ougai::Formatters::Base.parse_new_params([app_name, hostname, opts])
        super(aname, hname, opts)
        init_opts_for_json(opts)
      end
    end
  end
end