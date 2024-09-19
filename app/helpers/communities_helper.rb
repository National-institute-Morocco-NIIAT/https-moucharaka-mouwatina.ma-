module CommunitiesHelper
  def community_title(community)
    community.from_proposal? ? community.proposal.title : community.investment.title
  end

  def community_text(community)
    community.from_proposal? ? t("community.show.title.proposal") : t("community.show.title.investment")
  end

  def community_description(community)
    if community.from_proposal?
      t("community.show.description.proposal")
    else
      t("community.show.description.investment")
    end
  end

  def author?(community, participant)
    if community.from_proposal?
      community.proposal.author_id == participant.id
    else
      community.investment.author_id == participant.id
    end
  end

  def community_back_link_path(community)
    if community.from_proposal?
      proposal_path(community.proposal)
    else
      budget_investment_path(community.investment.budget_id, community.investment)
    end
  end

  def community_access_text(community)
    if community.from_proposal?
      t("community.sidebar.description.proposal")
    else
      t("community.sidebar.description.investment")
    end
  end

  def create_topic_link(community)
    current_user.present? ? new_community_topic_path(community.id) : new_user_session_path
  end
end
