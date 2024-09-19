namespace :files do
  desc "Removes cached attachments which weren't deleted for some reason"
  task remove_old_cached_attachments: :environment do
    Tenant.run_on_each do
      ActiveStorage::Blob.unattached.where(created_at: ..1.day.ago).find_each(&:purge_later)
    end
  end
end
