module FeatureFlags
  extend ActiveSupport::Concern

  class_methods do
    def feature_flag(name, *)
      before_action(*) do
        check_feature_flag(name)
      end
    end
  end

  def check_feature_flag(name)
    raise FeatureDisabled, name unless Setting["feature.#{name}"] || Setting["process.#{name}"]
  end

  class FeatureDisabled < Exception
    def initialize(name)
      @name = name
    end

    def message
      "Feature disabled: #{@name}"
    end
  end
end
