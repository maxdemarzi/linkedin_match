module CBM
  class Location < Neography::Node

    def self.countries(name="*")
      cypher = "START me = node:country_index('name:*#{name}*')
                RETURN ID(me), me.name"
      results = $neo_server.execute_query(cypher)

      if results
        results["data"]
      else
        []
      end

    end
  end
end