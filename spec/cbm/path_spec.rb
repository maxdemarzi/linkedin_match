# encoding: utf-8
require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe "CBM::Path" do

  describe "Path.order_path" do
    it "can return right results if ordered" do
      CBM::Path.order_path("17&87").should == "17&87"
    end

    it "can return right results if not in order" do
      CBM::Path.order_path("87&17").should == "17&87"
      CBM::Path.order_path("35&17").should == "17&35"
    end

    it "can return right results with nots" do
      CBM::Path.order_path("87&17&!20").should == "17&!20&87"
      CBM::Path.order_path("35&17&!40").should == "17&35&!40"
    end

    it "should raise error if first item is a not" do
      lambda{ CBM::Path.order_path("87&!17&!20") }.should raise_error(ArgumentError)
    end

  end

  describe "Path.get_paths" do
    it "can return right results" do
      criteria = double("criteria", :formula => "(17 and 87) or (17 and 35)")
      CBM::Path.get_paths(criteria).should == ["17&87", "17&35"]
    end

    it "can return right results in order" do
      criteria = double("criteria", :formula => "(87 and 17) or (35 and 17)")
      CBM::Path.get_paths(criteria).should == ["17&87", "17&35"]
    end
  end

  describe "Path.get_rels" do
    it "can return right results with a single and path" do
      node = 1
      description = "17&87"
      rels = [[:create_unique_relationship, "in_path_index", "from_c_to", "17_&_87", "in_path", 17, 87],
              [:create_unique_relationship, "in_path_index", "from_c_to", "87_&_1", "in_path", 87, 1]]
      CBM::Path.get_rels(description,node).should == rels
    end

    it "can return right results with a single not path" do
      node = 1
      description = "17&!87"
      rels = [[:create_unique_relationship, "in_path_index", "from_c_to", "17_&!_87", "in_path_excluded", 17, 87],
              [:create_unique_relationship, "in_path_index", "from_c_to", "87_&_1", "in_path", 87, 1]]
      CBM::Path.get_rels(description,node).should == rels
    end

    it "can return right results with two and paths" do
      node = 1
      description = "17&87&89"
      rels = [[:create_unique_relationship, "in_path_index", "from_c_to", "17_&_87", "in_path", 17, 87],
              [:create_unique_relationship, "in_path_index", "from_c_to", "87_&_89", "in_path", 87, 89],
              [:create_unique_relationship, "in_path_index", "from_c_to", "89_&_1", "in_path", 89, 1]]
      CBM::Path.get_rels(description,node).should == rels
    end

    it "can return right results with two not paths" do
      node = 1
      description = "17&!87&!89"
      rels = [[:create_unique_relationship, "in_path_index", "from_c_to", "17_&!_87", "in_path_excluded", 17, 87],
              [:create_unique_relationship, "in_path_index", "from_c_to", "87_&!_89", "in_path_excluded", 87, 89],
              [:create_unique_relationship, "in_path_index", "from_c_to", "89_&_1", "in_path", 89, 1]]
      CBM::Path.get_rels(description,node).should == rels
    end

    it "can return right results with one and path and one not path" do
      node = 1
      description = "17&87&!89"
      rels = [[:create_unique_relationship, "in_path_index", "from_c_to", "17_&_87", "in_path", 17, 87],
              [:create_unique_relationship, "in_path_index", "from_c_to", "87_&!_89", "in_path_excluded", 87, 89],
              [:create_unique_relationship, "in_path_index", "from_c_to", "89_&_1", "in_path", 89, 1]]
      CBM::Path.get_rels(description,node).should == rels
    end

    it "can return right results with one and path and one not path and another and path" do
      node = 1
      description = "17&87&!89&93"
      rels = [[:create_unique_relationship, "in_path_index", "from_c_to", "17_&_87", "in_path", 17, 87],
              [:create_unique_relationship, "in_path_index", "from_c_to", "87_&!_89", "in_path_excluded", 87, 89],
              [:create_unique_relationship, "in_path_index", "from_c_to", "89_&_93", "in_path", 89, 93],
              [:create_unique_relationship, "in_path_index", "from_c_to", "93_&_1", "in_path", 93, 1]]
      CBM::Path.get_rels(description,node).should == rels
    end

    it "can return right results with an and path between two not paths" do
      node = 1
      description = "17&!87&89&!93"
      rels = [[:create_unique_relationship, "in_path_index", "from_c_to", "17_&!_87", "in_path_excluded", 17, 87],
              [:create_unique_relationship, "in_path_index", "from_c_to", "87_&_89", "in_path", 87, 89],
              [:create_unique_relationship, "in_path_index", "from_c_to", "89_&!_93", "in_path_excluded", 89, 93],
              [:create_unique_relationship, "in_path_index", "from_c_to", "93_&_1", "in_path", 93, 1]]
      CBM::Path.get_rels(description,node).should == rels
    end

  end

end