section "Creating Debates" do
  tags = Faker::Lorem.words(number: 25)
  30.times do
    author = User.sample
    description = "<p>#{Faker::Lorem.paragraphs.join("</p><p>")}</p>"
    debate = Debate.create!(author: author,
                            title: Faker::Lorem.sentence(word_count: 3).truncate(60),
                            created_at: rand((1.week.ago)..Time.current),
                            description: description,
                            tag_list: tags.sample(3).join(","),
                            geozone: Geozone.sample,
                            terms_of_service: "1")
    random_locales.map do |locale|
      Globalize.with_locale(locale) do
        debate.title = "Title for locale #{locale}"
        debate.description = "<p>Description for locale #{locale}</p>"
        debate.save!
      end
    end
  end

  tags = Tag.where(kind: "category")
  30.times do
    author = User.sample
    description = "<p>#{Faker::Lorem.paragraphs.join("</p><p>")}</p>"

    debate = Debate.create!(author: author,
                            title: Faker::Lorem.sentence(word_count: 3).truncate(60),
                            created_at: rand((1.week.ago)..Time.current),
                            description: description,
                            tag_list: tags.sample(3).join(","),
                            geozone: Geozone.sample,
                            terms_of_service: "1")
    random_locales.map do |locale|
      Globalize.with_locale(locale) do
        debate.title = "Title for locale #{locale}"
        debate.description = "<p>Description for locale #{locale}</p>"
        debate.save!
      end
    end
  end
end
