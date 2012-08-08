module CBM
  class Skill < Neography::Node

    def self.get_by_id(ids)
      cypher = "START me = node({ids})
                WHERE has(me.name)
                RETURN ID(me), me.name"
      results = $neo_server.execute_query(cypher, :ids =>ids)

      if results
        results["data"]
      else
        []
      end
    end

    def self.find_by_name(name)
      skill = $neo_server.get_node_index("skill_index", "name", name)

      if skill
        self.new(skill.first)
      else
        nil
      end
    end

    def self.available
      cypher = "START users = node:user_index('uid:*')
                MATCH users -[:has]-> skill
                RETURN DISTINCT ID(skill), skill.name, COUNT(skill) AS user_count
                ORDER BY user_count DESC"
      results = $neo_server.execute_query(cypher)

      if results
        results["data"]
      else
        []
      end
    end

    def users
      cypher = "START me = node(#{self.neo_id})
                MATCH me <-[:has]- users
                RETURN users.uid, users.name, users.image_url"
      results = $neo_server.execute_query(cypher)
      results["data"]
    end

    def users_count
      cypher = "START me = node(#{self.neo_id})
                MATCH me <-[:has]-> users
                RETURN COUNT(users)"
      results = $neo_server.execute_query(cypher)
      results["data"][0][0]
    end

  end
end
