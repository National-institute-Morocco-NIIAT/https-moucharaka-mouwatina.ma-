section "Creating Settings" do
  Setting.reset_defaults

  {
    "facebook_handle": "Moucharaka Mouwatina",
    "feature.featured_proposals": "true",
    "feature.map": "true",
    "instagram_handle": "Moucharaka Mouwatina",
    "meta_description": "Citizen participation tool for an open, " \
                        "transparent and democratic government",
    "meta_keywords": "citizen participation, open government",
    "meta_title": "Moucharaka Mouwatina",
    "proposal_code_prefix": "MAD",
    "proposal_notification_minimum_interval_in_days": 0,
    "telegram_handle": "Moucharaka Mouwatina",
    "twitter_handle": "@consuldemocracy_dev",
    "twitter_hashtag": "#consuldemocracy_dev",
    "votes_for_proposal_success": "100",
    "youtube_handle": "Moucharaka Mouwatina"
  }.each do |name, value|
    Setting[name] = value
  end
end
