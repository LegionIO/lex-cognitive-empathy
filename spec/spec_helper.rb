# frozen_string_literal: true

require 'legion/extensions/cognitive_empathy/version'
require 'legion/extensions/cognitive_empathy/helpers/constants'
require 'legion/extensions/cognitive_empathy/helpers/perspective'
require 'legion/extensions/cognitive_empathy/helpers/empathy_engine'
require 'legion/extensions/cognitive_empathy/runners/cognitive_empathy'
require 'legion/extensions/cognitive_empathy/client'

module Legion
  module Extensions
    module Helpers
      module Lex; end
    end
  end
end

module Legion
  module Logging
    def self.method_missing(*); end
    def self.respond_to_missing?(*) = true
  end
end
