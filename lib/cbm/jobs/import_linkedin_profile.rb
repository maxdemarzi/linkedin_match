module CBM
  module Job
    class ImportLinkedinProfile
      include Sidekiq::Worker

      def perform(uid)
        @neo = Neography::Rest.new
        user = CBM::User.find_by_uid(uid)

        commands = []

        # I'll want to grab certifications, education, position, etc.
        profile = user.client.profile(:fields => %w(skills))

        profile.skills.all.each do |skill|
          commands << [:create_unique_node, "skill_index", "name", skill.skill.name, {"name" => skill.skill.name }]
        end

        batch_result = @neo.batch *commands

        commands = []

        # Connect the user to these skills

        batch_result.each do |b|
          commands << [:create_unique_relationship, "has_index", "user_value",  "#{uid}-#{b["body"]["data"]["name"]}", "has", user, b["body"]["self"].split("/").last]
        end
        @neo.batch *commands

      end

    end
  end
end