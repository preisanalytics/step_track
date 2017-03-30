describe "StepTrack" do
  after do
    Thread.current[StepTrack.send(:ref, "test")] = nil
  end

  describe ".init" do
    it "raises when no block is given" do
      begin
        rescued = false
        StepTrack.init("test")
      rescue ArgumentError
        rescued = true
      end
      assert rescued
    end

    it "stores the initialized data into thread context" do
      StepTrack.init("test") { }
      data = Thread.current[StepTrack.send(:ref, "test")]
      assert_equal [], data[:steps],
        "steps is no empty array #{data[:steps].inspect}"
      assert data[:callback].is_a?(Proc),
        "callback is no proc #{data[:callback].inspect}"
      assert data[:time] <= Time.now,
        "time #{data[:time].inspect} > #{Time.now.inspect}"
    end
  end

  describe ".push" do
    before do
      StepTrack.init("test") { }
    end

    it "requires initialization" do
      begin
        rescued = false
        StepTrack.push("no_init", "step")
      rescue ArgumentError
        rescued = true
      end
      assert rescued
    end

    it "pushes a step including payload into data" do
      StepTrack.push("test", "step", moo: "bar")
      data = Thread.current[StepTrack.send(:ref, "test")]
      step = data[:steps].first
      assert_equal 1, data[:steps].size
      assert_equal "step", step[:name]
      assert_equal "bar", step[:moo]
      expected_keys = [:name, :split, :duration, :time, :caller]
      assert_equal expected_keys, expected_keys & step.keys
    end
  end

  describe ".done" do
    before do
      StepTrack.init("test") { |result| result }
      StepTrack.push("test", "step", moo: "bar")
      StepTrack.push("test", "last", gnu: "blu")
    end

    it "requires initialization" do
      begin
        rescued = false
        StepTrack.done("no_init")
      rescue ArgumentError
        rescued = true
      end
      assert rescued
    end

    it "returns the callback result" do
      result = StepTrack.done("test")
      assert result.is_a?(Hash), "result is no hash #{result.inspect}"
    end

    it "sets a step count" do
      result = StepTrack.done("test")
      assert_equal 2, result[:step_count]
    end

    it "merges the last step into result" do
      result = StepTrack.done("test")
      assert_equal "last", result[:name]
      expected_keys = [:name, :split, :duration, :caller]
      assert_equal expected_keys, expected_keys & result.keys
    end

    it "enumerates every step into result" do
      result = StepTrack.done("test")
      expected_key_parts = [:name, :split, :duration, :caller]
      2.times do |i|
        expected_keys = expected_key_parts.map { |k| "step_#{i}_#{k}".to_sym }
        assert_equal expected_keys, expected_keys & result.keys
      end
    end
  end
end
