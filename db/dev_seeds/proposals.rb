def add_image_to_proposal(proposal)
  image_files = %w[
    firdouss-ross-414668-unsplash_846x475.jpg
    nathan-dumlao-496190-unsplash_713x475.jpg
    steve-harvey-597760-unsplash_713x475.jpg
    tim-mossholder-302931-unsplash_713x475.jpg
  ].map do |filename|
    Rails.root.join("db",
                    "dev_seeds",
                    "images",
                    "proposals", filename)
  end

  add_image_to(proposal, image_files)
end

section "Creating Proposals" do
  tags = Faker::Lorem.words(number: 25)
  30.times do
    title = Faker::Lorem.sentence(word_count: 3).truncate(60)
    summary = Faker::Lorem.sentence(word_count: 3)
    author = User.sample
    description = "<p>#{Faker::Lorem.paragraphs.join("</p><p>")}</p>"

    proposal = Proposal.create!(author: author,
                                title: title,
                                summary: summary,
                                responsible_name: Faker::Name.name,
                                description: description,
                                created_at: rand((1.week.ago)..Time.current),
                                tag_list: tags.sample(3).join(","),
                                geozone: Geozone.sample,
                                terms_of_service: "1",
                                published_at: Time.current)
    random_locales.map do |locale|
      Globalize.with_locale(locale) do
        proposal.title = "Title for locale #{locale}"
        proposal.summary = "Summary for locale #{locale}"
        proposal.description = "<p>Description for locale #{locale}</p>"
        proposal.save!
      end
    end
    add_image_to_proposal proposal
  end
end

section "Creating Archived Proposals" do
  tags = Faker::Lorem.words(number: 25)
  5.times do
    author = User.sample
    description = "<p>#{Faker::Lorem.paragraphs.join("</p><p>")}</p>"
    proposal = Proposal.create!(author: author,
                                title: Faker::Lorem.sentence(word_count: 3).truncate(60),
                                summary: Faker::Lorem.sentence(word_count: 3),
                                responsible_name: Faker::Name.name,
                                description: description,
                                tag_list: tags.sample(3).join(","),
                                geozone: Geozone.sample,
                                terms_of_service: "1",
                                created_at: Setting.archived_proposals_date_limit,
                                published_at: Setting.archived_proposals_date_limit)
    random_locales.map do |locale|
      Globalize.with_locale(locale) do
        proposal.title = "Archived proposal title for locale #{locale}"
        proposal.summary = "Archived proposal title summary for locale #{locale}"
        proposal.description = "<p>Archived proposal description for locale #{locale}</p>"
        proposal.save!
      end
    end
    add_image_to_proposal proposal
  end
end

section "Creating Successful Proposals" do
  tags = Faker::Lorem.words(number: 25)
  10.times do
    author = User.sample
    description = "<p>#{Faker::Lorem.paragraphs.join("</p><p>")}</p>"
    proposal = Proposal.create!(author: author,
                                title: Faker::Lorem.sentence(word_count: 3).truncate(60),
                                summary: Faker::Lorem.sentence(word_count: 3),
                                responsible_name: Faker::Name.name,
                                description: description,
                                created_at: rand((1.week.ago)..Time.current),
                                tag_list: tags.sample(3).join(","),
                                geozone: Geozone.sample,
                                terms_of_service: "1",
                                cached_votes_up: Setting["votes_for_proposal_success"],
                                published_at: Time.current)
    random_locales.map do |locale|
      Globalize.with_locale(locale) do
        proposal.title = "Successful proposal title for locale #{locale}"
        proposal.summary = "Successful proposal title summary for locale #{locale}"
        proposal.description = "<p>Successful proposal description for locale #{locale}</p>"
        proposal.save!
      end
    end
    add_image_to_proposal proposal
  end

  tags = Tag.where(kind: "category")
  30.times do
    author = User.sample
    description = "<p>#{Faker::Lorem.paragraphs.join("</p><p>")}</p>"
    proposal = Proposal.create!(author: author,
                                title: Faker::Lorem.sentence(word_count: 4).truncate(60),
                                summary: Faker::Lorem.sentence(word_count: 3),
                                responsible_name: Faker::Name.name,
                                description: description,
                                created_at: rand((1.week.ago)..Time.current),
                                tag_list: tags.sample(3).join(","),
                                geozone: Geozone.sample,
                                terms_of_service: "1",
                                published_at: Time.current)
    random_locales.map do |locale|
      Globalize.with_locale(locale) do
        proposal.title = "Tagged proposal title for locale #{locale}"
        proposal.summary = "Tagged proposal title summary for locale #{locale}"
        proposal.description = "<p>Tagged proposal description for locale #{locale}</p>"
        proposal.save!
      end
    end
    add_image_to_proposal proposal
  end
end

section "Creating proposal notifications" do
  100.times do |i|
    ProposalNotification.create!(title: "Proposal notification title #{i}",
                                 body: "Proposal notification body #{i}",
                                 author: User.sample,
                                 proposal: Proposal.sample)
  end
end
