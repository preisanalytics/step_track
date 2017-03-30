# frozen_string_literal: true

module StepTrack
  extend self

  REF = "step_track/%{track}"

  def init(track)
    raise ArgumentError, "callback block required" unless block_given?
    Thread.current[ref(track)] = {
      steps: [],
      callback: Proc.new,
      time: Time.now
    }
  end

  def push(track, name, payload={})
    require_init!(track)
    track_ref = Thread.current[ref(track)]
    last_step = track_ref[:steps].last
    track_ref[:steps] << {
      split: Time.now - (last_step&.[](:time) || track_ref[:time]),
      duration: Time.now - track_ref[:time],
      time: Time.now,
      caller: caller[0],
      name: name
    }.merge(payload)
  end

  def done(track)
    require_init!(track)
    track_ref = Thread.current[ref(track)]
    Thread.current[ref(track)] = nil
    steps = track_ref.delete(:steps)
    steps.each { |step| step.delete(:time) }
    result = {step_count: steps.count}
    result.merge!(steps.last || {})
    steps.each_with_index do |step, i|
      result.merge!(step.map { |k, v| ["step_#{i}_#{k}".to_sym, v] }.to_h)
    end
    return track_ref[:callback].call(result)
  end

  private

  def ref(track)
    (REF % {track: track}).to_sym
  end

  def initialized?(track)
    !Thread.current[ref(track)].nil?
  end

  def require_init!(track)
    raise ArgumentError, "track not initialized" unless initialized?(track)
  end
end
