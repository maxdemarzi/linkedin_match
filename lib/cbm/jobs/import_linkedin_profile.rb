module CBM
  module Job
    class ImportLinkedinProfile
      include Sidekiq::Worker

      def perform(uid)
        @neo = Neography::Rest.new
        user = CBM::User.find_by_uid(uid)

        # I'll want to grab certifications, education, position, etc.
        profile = user.client.profile(:fields => %w(skills))

        # Import user skills
        commands = []
        profile.skills.all.each do |skill|
          commands << [:create_unique_node, "skill_index", "name", skill.skill.name, {"name" => skill.skill.name }]
        end
        batch_result = @neo.batch *commands

        # Connect the user to these skills
        commands = []
        batch_result.each do |b|
          commands << [:create_unique_relationship, "has_index", "user_value",  "#{uid}-#{b["body"]["data"]["name"]}", "has", user, b["body"]["self"].split("/").last]
        end
        @neo.batch *commands

        # Import Friends
        friends = user.client.connections
        friends.all.each do |friend|
          Sidekiq::Client.enqueue(CBM::Job::ImportLinkedinConnections, user.uid, friend.to_hash)
        end

      end

    end
  end
end