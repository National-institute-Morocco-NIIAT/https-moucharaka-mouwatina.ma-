FactoryBot.define do
  factory :debate do
    sequence(:title)     { |n| "Debate #{n} title" }
    description          { "Debate description" }
    terms_of_service     { "1" }
    author factory: :user

    trait :hidden do
      hidden_at { Time.current }
    end

    trait :with_ignored_flag do
      ignored_flag_at { Time.current }
    end

    trait :with_confirmed_hide do
      confirmed_hide_at { Time.current }
    end

    trait :flagged do
      after :create do |debate|
        Flag.flag(create(:user), debate)
      end
    end

    trait :with_hot_score do
      before(:save, &:calculate_hot_score)
    end

    trait :with_confidence_score do
      before(:save, &:calculate_confidence_score)
    end

    trait :conflictive do
      after :create do |debate|
        Flag.flag(create(:user), debate)
        4.times { create(:vote, votable: debate) }
      end
    end

    transient { voters { [] } }

    after(:create) do |debate, evaluator|
      evaluator.voters.each { |voter| create(:vote, votable: debate, voter: voter) }
    end
  end

  factory :flag do
    flaggable factory: :debate
    user
  end
end
