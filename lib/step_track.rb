# frozen_string_literal: true

require "date"

# Tracks data fragments across the application
module StepTrack
  extend self

  REF = "step_track/%<track>s"
  DEFAULT_CONFIG = { merge_key: :merge, error_key: :error }.freeze

  def first_caller
    @first_caller ||= -> { caller[1].sub("#{Dir.pwd}/", "") }
  end

  def set_first_caller(&blk)
    @first_caller = blk
  end

  def init(track, config = {}, &block)
    raise ArgumentError, "callback block required" unless block_given?

    Thread.current[ref(track)] = {
      track_id: config[:track_id] || Thread.current.object_id.to_s,
      steps: [],
      callback: Proc.new(&block),
      time: DateTime.now,
      caller: config&.[](:caller) || first_caller.call
    }.merge(DEFAULT_CONFIG).merge(config)
  end

  def push(track, name, payload = {})
    require_init!(track)
    track_ref = Thread.current[ref(track)]
    merge_step = track_ref[:steps].pop if payload.delete(track_ref[:merge_key])
    last_step = track_ref[:steps].last
    track_ref[:steps] << (merge_step || {}).merge(
      split: Time.now.to_f - (last_step&.[](:time) || track_ref[:time]).to_time.to_f,
      duration: Time.now.to_f - track_ref[:time].to_time.to_f,
      time: DateTime.now,
      caller: merge_step&.[](:caller) || first_caller.call,
      step_name: merge_step&.[](:step_name) || name
    ).merge(payload)
  end

  def done(track)
    require_init!(track)
    track_ref = Thread.current[ref(track)]
    Thread.current[ref(track)] = nil
    steps = track_ref.delete(:steps)
    steps.each { |s| s[:timestamp] = s.delete(:time).iso8601 }
    result = {
      step_count: steps.count,
      caller: track_ref[:caller],
      duration: Time.now.to_f - track_ref[:time].to_time.to_f,
      timestamp: track_ref[:time].iso8601,
      track_id: track_ref[:track_id]
    }
    last_step = if (err = steps.detect { |s| s.key?(track_ref[:error_key]) })
                  err.dup
                else
                  steps.last&.dup || {}
                end
    result[:final_step_name] = last_step.delete(:step_name)
    merge_down_steps!(result, steps)
    track_ref[:callback].call(result)
  end

  def track_id(track)
    require_init!(track)
    Thread.current[ref(track)][:track_id]
  end

  def partition_into(payload, name)
    payload, other = payload.partition do |k, _v|
      k.to_s !~ /^step_#{name}_/
    end.map(&:to_h)
    prev_pattern = /^step_#{name}_([^\d].*)$/
    other = other.reduce([{}]) do |acc, (k, v)|
      match = k.to_s.match(prev_pattern)
      unless match
        acc << {}
        digit = k.to_s.match(/^step_#{name}_(\d+)/).captures.first
        prev_pattern = /^step_#{name}_#{digit}_(.*)$/
        match = k.to_s.match(prev_pattern)
      end
      acc.last[match.captures.first.to_sym] = v
      next acc
    end.reject(&:empty?)
    [payload, other]
  end

  private

  def ref(track)
    format(REF, track: track).to_sym
  end

  def initialized?(track)
    !Thread.current[ref(track)].nil?
  end

  def require_init!(track)
    raise ArgumentError, "track not initialized" unless initialized?(track)
  end

  def merge_down_steps!(result, steps)
    steps.each_with_index do |step, i|
      name = name_dupe = step.delete(:step_name)
      j = 0
      while result.key?("step_#{name_dupe}_i".to_sym)
        j += 1
        name_dupe = "#{name}_#{j}"
      end
      name = name_dupe
      result.merge!(step.merge(i: i + 1)
        .transform_keys { |k| "step_#{name}_#{k}".to_sym })
    end
  end
end
