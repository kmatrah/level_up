require 'test_helper'

module LevelUp
  class GraphTestJob < Job
    job do
      task :start, transitions: :first_node
      task :first_node, transitions: [:second_node, :end]
      task :second_node, transitions: [:end]
    end
  end

  class GraphBuilderTest < ActiveSupport::TestCase
    def setup
      @job = GraphTestJob.create
    end

    test "should return the default configuration" do
      builder = GraphBuilder.new(@job)
      assert_equal(GraphBuilder.default_configuration, builder.configuration)
    end

    test "should return the configuration with a custom background color" do
      builder = GraphBuilder.new(@job, bgcolor: '#ff0000')
      custom_configuration = GraphBuilder.default_configuration
      custom_configuration[:bgcolor] = '#ff0000'

      assert_equal(custom_configuration, builder.configuration)
    end

    test "should return the configuration with a custom node font color" do
      builder = GraphBuilder.new(@job, node: {fontcolor: '#000000'})
      custom_configuration = GraphBuilder.default_configuration
      custom_configuration[:node][:fontcolor] = '#000000'

      assert_equal(custom_configuration, builder.configuration)
    end

    test "should return the configuration with a custom node fillcolor for 'first_node'" do
      builder = GraphBuilder.new(@job, node: {first_node: {fillcolor: '#00ff00'}})
      custom_configuration = GraphBuilder.default_configuration
      custom_configuration[:node][:first_node] = {fillcolor: '#00ff00'}

      assert_equal(custom_configuration, builder.configuration)
    end

    test "should have the correct number of nodes" do
      builder = GraphBuilder.new(@job)
      graph = builder.graph

      assert_equal(@job.tasks.size, graph.node_count)
    end

    test "should have the correct number of edges" do
      builder = GraphBuilder.new(@job)
      graph = builder.graph

      assert_equal(@job.schema.values.flatten.size, graph.edge_count)
    end

    test "should have the same schema that the job" do
      builder = GraphBuilder.new(@job)
      graph = builder.graph

      assert_equal(@job.transitions(:start).size, graph.find_node("start").neighbors.size)
      assert_equal(@job.transitions(:start)[0].to_s.humanize.downcase, graph.find_node("start").neighbors[0].id)

      assert_equal(@job.transitions(:first_node).size, graph.find_node("first node").neighbors.size)
      assert_equal(@job.transitions(:first_node)[0].to_s.humanize.downcase, graph.find_node("first node").neighbors[0].id)
      assert_equal(@job.transitions(:first_node)[1].to_s.humanize.downcase, graph.find_node("first node").neighbors[1].id)

      assert_equal(@job.transitions(:second_node).size, graph.find_node("second node").neighbors.size)
      assert_equal(@job.transitions(:second_node)[0].to_s.humanize.downcase, graph.find_node("second node").neighbors[0].id)

      assert_equal(@job.transitions(:end).size, graph.find_node("end").neighbors.size)
    end
  end
end
