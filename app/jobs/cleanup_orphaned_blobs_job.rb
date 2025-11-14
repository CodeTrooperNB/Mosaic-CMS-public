class CleanupOrphanedBlobsJob < ApplicationJob
  queue_as :low_priority

  def perform
    # Find blobs that are older than 1 hour and not attached to anything
    cutoff_time = 1.hour.ago

    orphaned_blobs = ActiveStorage::Blob.left_joins(:attachments)
                                        .where(active_storage_attachments: { id: nil })
                                        .where("active_storage_blobs.created_at < ?", cutoff_time)

    Rails.logger.info "Found #{orphaned_blobs.count} orphaned blobs to clean up"

    orphaned_blobs.find_each do |blob|
      Rails.logger.info "Purging orphaned blob: #{blob.id} (#{blob.filename})"
      blob.purge
    end
  end
end