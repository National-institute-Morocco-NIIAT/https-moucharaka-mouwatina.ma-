section "Creating Communities" do
  Proposal.find_each { |proposal| proposal.update(community: Community.create) }
  Budget::Investment.find_each { |investment| investment.update(community: Community.create) }
end

section "Creating Communities Topics" do
  Community.find_each do |community|
    Topic.create(community: community, author: User.sample,
                 title: Faker::Lorem.sentence(word_count: 3).truncate(60), description: Faker::Lorem.sentence)
  end
end

section "Commenting Community Topics" do
  30.times do
    author = User.sample
    topic = Topic.sample
    Comment.create!(user: author,
                    created_at: rand(topic.created_at..Time.current),
                    commentable: topic,
                    body: Faker::Lorem.sentence)
  end
end
