module CBM
  module Job
    class ImportLinkedinConnections
      include Sidekiq::Worker

      def perform(uid, connection)
        @neo = Neography::Rest.new
        user = CBM::User.find_by_uid(uid)
        friend = User.create_from_linkedin(connection)

        # Make them friends
        commands = []
        commands << [:create_unique_relationship, "connected_index", "ids",  "#{user.uid}-#{friend.uid}", "is_connected", user, friend]
        commands << [:create_unique_relationship, "connected_index", "ids",  "#{friend.uid}-#{user.uid}", "is_connected", friend, user]
        batch_result = @neo.batch *commands

        # Import friend skills
        if connection["skills"] && connection["skills"]["all"]
          commands = []
          connection["skills"]["all"].each do |skill|
            commands << [:create_unique_node, "skill_index", "name", skill["skill"]["name"], {"name" => skill["skill"]["name"] }]
          end
          batch_result = @neo.batch *commands

          # Connect the friend to these skills
          commands = []
          batch_result.each do |b|
            commands << [:create_unique_relationship, "has_index", "user_value",  "#{friend.uid}-#{b["body"]["data"]["name"]}", "has", friend, b["body"]["self"].split("/").last]
          end
          @neo.batch *commands
        end

      end

    end
  end
end