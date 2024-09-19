section "Creating collaborative legislation" do
  9.times do |i|
    Legislation::Process.create!(title: Faker::Lorem.sentence(word_count: 3).truncate(60),
                                 description: Faker::Lorem.paragraphs.join("\n\n"),
                                 summary: Faker::Lorem.paragraph,
                                 additional_info: Faker::Lorem.paragraphs.join("\n\n"),
                                 proposals_description: Faker::Lorem.paragraph,
                                 start_date: Date.current + (i - 7).days,
                                 end_date: Date.current + (i - 1).days,
                                 debate_start_date: Date.current + (i - 7).days,
                                 debate_end_date: Date.current + (i - 5).days,
                                 proposals_phase_start_date: Date.current + (i - 7).days,
                                 proposals_phase_end_date: Date.current + (i - 5).days,
                                 draft_publication_date: Date.current + (i - 3).days,
                                 allegations_start_date: Date.current + (i - 2).days,
                                 allegations_end_date: Date.current + (i - 1).days,
                                 result_publication_date: Date.current + i.days,
                                 debate_phase_enabled: true,
                                 allegations_phase_enabled: true,
                                 draft_publication_enabled: true,
                                 result_publication_enabled: true,
                                 proposals_phase_enabled: true,
                                 published: true)
  end

  Legislation::Process.find_each do |process|
    (1..3).each do |i|
      process.draft_versions.create!(random_locales_attributes(
        title: -> { I18n.t("seeds.legislation.draft_versions.title", number: i) },
        body: -> do
          [
            I18n.t("seeds.legislation.draft_versions.body", language: I18n.t("i18n.language.name")),
            *Faker::Lorem.paragraphs
          ].join("\n\n")
        end
      ))
    end
  end
end
