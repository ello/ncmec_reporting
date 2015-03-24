module NcmecReporting
  class XmlBuilder
    def self.create(type, attrs = {}, &block)
      new.create(type, attrs, &block)
    end

    def initialize
      @builder = Builder::XmlMarkup.new
      @builder.instruct!(:xml, encoding: 'UTF-8')

      yield @builder if block_given?
    end

    def create(type, attrs = {}, &block)
      attrs = namespace.merge(attrs)

      # Have to use eval here because the Builder library
      # overrides #send. OMG.
      eval("@builder.#{type}(attrs, &block)")
    end

    private

    def namespace
      {
        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
        'xsi:noNamespaceSchemaLocation' => 'https://report.cybertip.org/ispws/xsd'
      }
    end
  end
end
